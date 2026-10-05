// Verin Legal — client email and text intake.
//
//   inboundEmail       HTTPS webhook for SendGrid Inbound Parse (multipart) or
//                      Postmark inbound (JSON). The URL carries ?key=<secret>.
//   inboundSms         HTTPS webhook for Twilio messages (signature checked).
//                      Both only store the raw request (hashed) and queue it,
//                      so providers get a fast 200.
//   onInboundEvent     Files the queued request into the right matter: the
//                      message itself and every attachment / photo become
//                      receipts, hashed and chained like an upload. Senders the
//                      matter doesn't know are held in quarantine (stored and
//                      hashed, not read) until someone approves them.
//   onMatterIntake     Gives each matter its email address and texting
//                      number, and keeps its client phones / emails tidy.
//   provisionIntake    The same, on demand from the Intake tab.
//   approveQuarantined Approve an unknown sender: read their items (and
//                      optionally remember them for this matter).
//   assignUnrouted     File a text from an unknown number into a matter.
//
// Collections (server-only unless noted): InboundEvents, intakeAddresses,
// UnroutedIntake (read by the firm).

const crypto = require('crypto');
const Busboy = require('busboy');
const { simpleParser } = require('mailparser');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');

const P = require('../common/params');
const { requireAuth, loadMatterForUser, assertDocId, firmIdForUser } = require('../common/access');
const { processReceipt } = require('../evidence/process');
const ingest = require('../evidence/ingest');
const N = require('./normalize');
const { fileInboundItem } = require('./file');

if (!getApps().length) initializeApp();

const MAX_ATTACHMENTS = 40;

// ---------------------------------------------------------------------------
// Addresses and numbers
// ---------------------------------------------------------------------------

async function firmSmsNumber(db, firmId) {
  if (firmId) {
    const acct = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
    const n = acct.empty ? '' : N.normPhone(acct.docs[0].get('smsNumber'));
    if (n) return n;
  }
  return N.normPhone(P.TWILIO_SMS_NUMBER.value());
}

/// Reserves "<stem>-<4 digits>" for this matter (unique across Verin).
async function allocateLocalPart(db, matterRef, matter) {
  const stem = N.addressStem(matter);
  for (let i = 0; i < 8; i++) {
    const local = `${stem}-${crypto.randomInt(1000, 10000)}`;
    const ref = db.collection('intakeAddresses').doc(local);
    try {
      await ref.create({ matterRef, firmID: matter.firmID || '', createdAt: FieldValue.serverTimestamp() });
      return local;
    } catch (e) {
      if (e.code !== 6 && !/already exists/i.test(e.message || '')) throw e; // 6 = ALREADY_EXISTS
    }
  }
  throw new Error('could not allocate an intake address');
}

/// The intake fields this matter should have; only what changed is returned.
async function intakeUpdates(db, matterRef, m) {
  const out = {};
  const domain = String(P.INBOUND_EMAIL_DOMAIN.value() || '').toLowerCase().trim();
  if (domain && !m.emailAddress) {
    const local = await allocateLocalPart(db, matterRef, m);
    out.emailAddress = `${local}@${domain}`;
  }
  if (!m.smsNumber) {
    const n = await firmSmsNumber(db, m.firmID);
    if (n) out.smsNumber = n;
  }
  const phones = [...new Set([m.clientPhone, ...(Array.isArray(m.clientPhones) ? m.clientPhones : [])].map(N.normPhone).filter(Boolean))];
  if (JSON.stringify(phones) !== JSON.stringify(m.clientPhones || [])) out.clientPhones = phones;
  const emails = [...new Set([m.clientEmail, ...(Array.isArray(m.clientEmails) ? m.clientEmails : [])].map(N.normEmail).filter(Boolean))];
  if (JSON.stringify(emails) !== JSON.stringify(m.clientEmails || [])) out.clientEmails = emails;
  if ((out.emailAddress || out.smsNumber) && !m.intakeProvisionedAt) out.intakeProvisionedAt = FieldValue.serverTimestamp();
  return out;
}

exports.onMatterIntake = onDocumentWritten({ document: 'Matters/{matterId}' }, async (event) => {
  const after = event.data && event.data.after;
  if (!after || !after.exists) return;
  const m = after.data();
  const db = getFirestore();
  const upd = await intakeUpdates(db, after.ref, m);
  if (Object.keys(upd).length) await after.ref.set(upd, { merge: true });
});

exports.provisionIntake = onCall(async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref, snap } = await loadMatterForUser(db, uid, (request.data || {}).matterId);
  const upd = await intakeUpdates(db, ref, snap.data());
  if (Object.keys(upd).length) await ref.set(upd, { merge: true });
  const fresh = (await ref.get()).data();
  return {
    emailAddress: fresh.emailAddress || '',
    smsNumber: fresh.smsNumber || '',
    emailConfigured: !!P.INBOUND_EMAIL_DOMAIN.value(),
    smsConfigured: !!fresh.smsNumber,
  };
});

// ---------------------------------------------------------------------------
// Webhooks: store, hash, queue, answer fast
// ---------------------------------------------------------------------------

async function queueRaw({ kind, provider, body, contentType, fields }) {
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const ref = db.collection('InboundEvents').doc();
  const sha256 = crypto.createHash('sha256').update(body).digest('hex');
  const storagePath = `inbound/${kind}/${ref.id}.raw`;
  await bucket.file(storagePath).save(body, { resumable: false, contentType: contentType || 'application/octet-stream', metadata: { metadata: { sha256 } } });
  await ref.set({
    kind,
    provider,
    storagePath,
    contentType: contentType || '',
    sha256,
    bytes: body.length,
    ...(fields ? { fields } : {}),
    status: 'queued',
    receivedAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

exports.inboundEmail = onRequest(
  { secrets: [P.INBOUND_WEBHOOK_KEY], memory: '1GiB', timeoutSeconds: 120, cors: false },
  async (req, res) => {
    if (req.method !== 'POST') return res.status(405).send('POST only');
    if (!N.safeEqual(req.query.key, P.INBOUND_WEBHOOK_KEY.value())) return res.status(403).send('forbidden');
    const body = req.rawBody;
    if (!body || !body.length) return res.status(400).send('empty');
    const ct = String(req.headers['content-type'] || '');
    const provider = ct.includes('application/json') ? 'postmark' : 'sendgrid';
    try {
      await queueRaw({ kind: 'email', provider, body, contentType: ct });
      return res.status(200).send('ok');
    } catch (e) {
      console.error('inboundEmail: could not store', e);
      return res.status(500).send('retry'); // the provider retries
    }
  },
);

exports.inboundSms = onRequest(
  { secrets: [P.TWILIO_AUTH_TOKEN], memory: '512MiB', timeoutSeconds: 60, cors: false },
  async (req, res) => {
    if (req.method !== 'POST') return res.status(405).send('POST only');
    const params = req.body && typeof req.body === 'object' ? req.body : {};
    const url = P.TWILIO_WEBHOOK_URL.value() || `https://${req.headers.host}${req.originalUrl}`;
    const expected = N.twilioSignature(P.TWILIO_AUTH_TOKEN.value(), url, params);
    if (!N.safeEqual(req.headers['x-twilio-signature'], expected)) {
      console.warn('inboundSms: bad signature for', url);
      return res.status(403).send('forbidden');
    }
    const fields = {};
    for (const [k, v] of Object.entries(params)) if (typeof v === 'string') fields[k] = v.slice(0, 5000);
    try {
      await queueRaw({ kind: 'sms', provider: 'twilio', body: req.rawBody || Buffer.from(JSON.stringify(fields)), contentType: String(req.headers['content-type'] || ''), fields });
    } catch (e) {
      console.error('inboundSms: could not store', e);
      return res.status(500).send('retry');
    }
    const reply = P.SMS_AUTO_REPLY.value() === 'true' ? '<Message>Received — your attorney\'s office has it.</Message>' : '';
    res.set('Content-Type', 'text/xml');
    return res.status(200).send(`<?xml version="1.0" encoding="UTF-8"?><Response>${reply}</Response>`);
  },
);

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

/// SendGrid posts multipart/form-data: text fields plus attachment1..N files
/// (or the whole message as `email` when "POST the raw, full MIME" is on).
function parseMultipart(body, contentType) {
  return new Promise((resolve, reject) => {
    const fields = {};
    const files = [];
    const bb = Busboy({ headers: { 'content-type': contentType }, limits: { fileSize: 40 * 1024 * 1024, files: MAX_ATTACHMENTS, fieldSize: 40 * 1024 * 1024 } });
    bb.on('field', (name, val) => {
      fields[name] = val;
    });
    bb.on('file', (name, stream, info) => {
      const chunks = [];
      stream.on('data', (d) => chunks.push(d));
      stream.on('end', () => files.push({ field: name, filename: info.filename, contentType: info.mimeType, content: Buffer.concat(chunks) }));
    });
    bb.on('error', reject);
    bb.on('close', () => resolve({ fields, files }));
    bb.end(body);
  });
}

/// One shape for every provider:
/// { raw?: Buffer, from: {email,name}, recipients: [..], subject, text, date, messageId, attachments: [{filename, contentType, content, inline}] }
async function parseEmail(provider, body, contentType) {
  let raw = null;
  let base = {};
  if (provider === 'postmark') {
    const j = JSON.parse(body.toString('utf8'));
    const list = (arr) => (Array.isArray(arr) ? arr.map((x) => x && x.Email).filter(Boolean) : []);
    if (j.RawEmail) raw = Buffer.from(j.RawEmail, 'utf8');
    base = {
      from: { email: N.normEmail(j.FromFull ? j.FromFull.Email : j.From), name: (j.FromFull && j.FromFull.Name) || N.displayNameIn(j.From) },
      recipients: [j.OriginalRecipient, ...list(j.ToFull), ...list(j.CcFull), ...list(j.BccFull), ...N.emailsIn(j.To), ...N.emailsIn(j.Cc)].map(N.normEmail).filter(Boolean),
      subject: j.Subject || '',
      text: j.TextBody || j.StrippedTextReply || '',
      date: j.Date ? new Date(j.Date) : null,
      messageId: j.MessageID || '',
      headers: Array.isArray(j.Headers) ? j.Headers.map((h) => `${h.Name}: ${h.Value}`).join('\n') : '',
      attachments: (Array.isArray(j.Attachments) ? j.Attachments : []).map((a) => ({
        filename: a.Name,
        contentType: a.ContentType,
        content: Buffer.from(a.Content || '', 'base64'),
        inline: !!a.ContentID,
      })),
    };
  } else {
    const { fields, files } = await parseMultipart(body, contentType);
    if (fields.email) raw = Buffer.from(fields.email, 'utf8');
    let envelope = {};
    try {
      envelope = JSON.parse(fields.envelope || '{}');
    } catch (_) {}
    let info = {};
    try {
      info = JSON.parse(fields['attachment-info'] || '{}');
    } catch (_) {}
    base = {
      from: { email: N.normEmail(fields.from || envelope.from), name: N.displayNameIn(fields.from) },
      recipients: [...(Array.isArray(envelope.to) ? envelope.to : []), ...N.emailsIn(fields.to), ...N.emailsIn(fields.cc)].map(N.normEmail).filter(Boolean),
      subject: fields.subject || '',
      text: fields.text || '',
      date: null,
      messageId: '',
      headers: fields.headers || '',
      attachments: files.map((f) => ({
        filename: (info[f.field] && (info[f.field].filename || info[f.field].name)) || f.filename,
        contentType: (info[f.field] && info[f.field].type) || f.contentType,
        content: f.content,
        inline: !!(info[f.field] && info[f.field]['content-id']),
      })),
    };
  }

  // The full message, when we have it, is the better source for everything.
  if (raw) {
    const m = await simpleParser(raw);
    const addr = (v) => (v && v.value ? v.value.map((x) => x.address) : []);
    const fromV = m.from && m.from.value && m.from.value[0];
    return {
      raw,
      from: { email: N.normEmail(fromV ? fromV.address : base.from.email), name: (fromV && fromV.name) || base.from.name },
      recipients: [...new Set([...base.recipients, ...addr(m.to), ...addr(m.cc), ...addr(m.bcc)].map(N.normEmail).filter(Boolean))],
      subject: m.subject || base.subject,
      text: m.text || base.text,
      date: m.date || base.date,
      messageId: m.messageId || base.messageId,
      attachments: (m.attachments || []).map((a) => ({
        filename: a.filename,
        contentType: a.contentType,
        content: a.content,
        inline: a.contentDisposition === 'inline' || !!a.related,
        size: a.size,
      })),
    };
  }
  return { raw: null, ...base };
}

/// A readable .eml when the provider didn't give us the original message.
function synthesizeEml(e) {
  const lines = [
    `From: ${e.from.name ? `"${e.from.name}" ` : ''}<${e.from.email}>`,
    `To: ${e.recipients.join(', ')}`,
    `Subject: ${e.subject || ''}`,
    `Date: ${(e.date || new Date()).toUTCString()}`,
    ...(e.messageId ? [`Message-ID: ${e.messageId}`] : []),
    'X-Verin-Note: rebuilt from the provider\'s parsed fields (the original MIME was not supplied)',
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=utf-8',
    '',
    e.text || '',
  ];
  return Buffer.from(lines.join('\r\n'), 'utf8');
}

// ---------------------------------------------------------------------------
// Filing
// ---------------------------------------------------------------------------

async function senderKnown(db, matter, firmId, { email, phone }) {
  if (email) {
    const known = [...(matter.clientEmails || []), matter.clientEmail, ...(matter.knownSenders || [])].map(N.normEmail);
    if (known.includes(email)) return true;
    // Firm staff forwarding evidence.
    const staff = await db.collection('users').where('firmID', '==', firmId).where('email', '==', email).limit(1).get();
    if (!staff.empty) return true;
    const staffMixed = await db.collection('TeamMembers').where('firmID', '==', firmId).where('email', '==', email).limit(1).get();
    return !staffMixed.empty;
  }
  if (phone) {
    const known = [...(matter.clientPhones || []), matter.clientPhone, ...(matter.knownSenders || [])].map(N.normPhone);
    return known.includes(phone);
  }
  return false;
}

async function fileEmail(db, bucket, event, e) {
  const domain = String(P.INBOUND_EMAIL_DOMAIN.value() || '').toLowerCase();
  const locals = [...new Set(e.recipients.map((r) => N.intakeLocalPart(r, domain)).filter(Boolean))];
  const filed = [];
  const notes = [];
  for (const local of locals) {
    const a = await db.collection('intakeAddresses').doc(local).get();
    if (!a.exists) {
      notes.push(`no matter for ${local}@${domain}`);
      continue;
    }
    const matterRef = a.get('matterRef');
    const ms = await matterRef.get();
    if (!ms.exists) continue;
    const matter = ms.data();
    if (matter.intakeEnabled && matter.intakeEnabled.email === false) {
      notes.push(`email intake is off for ${matterRef.id}`);
      continue;
    }
    const known = await senderKnown(db, matter, matter.firmID, { email: e.from.email });
    const fromLabel = e.from.name ? `${e.from.name} <${e.from.email}>` : e.from.email || 'Unknown sender';
    const reason = known ? '' : `From ${e.from.email || 'an unknown sender'}, who isn't known on this matter. Approve to read it.`;
    const common = {
      db,
      bucket,
      matterRef,
      channelKey: 'email',
      fromLabel,
      senderKey: e.from.email ? `mail:${e.from.email}` : '',
      quarantined: !known,
      reviewReason: reason,
      receivedAt: new Date(),
    };
    const subject = e.subject || '(no subject)';
    const msg = await fileInboundItem({
      ...common,
      buffer: e.raw || synthesizeEml(e),
      fileName: `${subject.replace(/[^\w .,'()-]+/g, ' ').trim().slice(0, 80) || 'email'}.eml`,
      contentType: 'message/rfc822',
      kind: 'email',
      description: subject,
      source: `email|from:${e.from.email}|to:${local}@${domain}|id:${e.messageId || event.id}`,
      extra: { intakeEventId: event.id, emailSubject: subject, emailFrom: e.from.email, rawMimeSupplied: !!e.raw },
    });
    filed.push(msg.receiptId);
    const atts = e.attachments.filter((x) => x.content && x.content.length && !N.isDecorativeAttachment(x)).slice(0, MAX_ATTACHMENTS);
    for (let i = 0; i < atts.length; i++) {
      const x = atts[i];
      const name = x.filename || `attachment-${i + 1}${N.extFor(x.contentType)}`;
      const r = await fileInboundItem({
        ...common,
        buffer: x.content,
        fileName: name,
        contentType: x.contentType || 'application/octet-stream',
        kind: N.kindFor(x.contentType, name),
        description: `Attachment to “${subject}”`,
        source: `email-attachment|from:${e.from.email}|to:${local}@${domain}|id:${e.messageId || event.id}|n:${i + 1}`,
        extra: { intakeEventId: event.id, parentReceiptId: msg.receiptId },
      });
      filed.push(r.receiptId);
    }
  }
  return { filed, notes };
}

/// Matters this number belongs to (open first), limited to the firms whose
/// texting number received it when that is known.
async function mattersForPhone(db, phone, toNumber) {
  const snap = await db.collection('Matters').where('clientPhones', 'array-contains', phone).get();
  let docs = snap.docs;
  const firmsForTo = (await db.collection('firmAccount').where('smsNumber', '==', toNumber).get()).docs.map((d) => d.get('firmID'));
  if (firmsForTo.length) docs = docs.filter((d) => firmsForTo.includes(d.get('firmID')));
  const open = docs.filter((d) => String(d.get('status') || 'Open') !== 'Closed');
  const ms = (d) => {
    const v = d.get('lastReceiptAt') || d.get('openedAt');
    return v && v.toMillis ? v.toMillis() : 0;
  };
  return { list: (open.length ? open : docs).sort((a, b) => ms(b) - ms(a)), firmsForTo };
}

async function fetchTwilioMedia(url) {
  const sid = P.TWILIO_ACCOUNT_SID.value();
  const headers = sid ? { Authorization: `Basic ${Buffer.from(`${sid}:${P.TWILIO_AUTH_TOKEN.value()}`).toString('base64')}` } : {};
  const r = await fetch(url, { headers, redirect: 'follow' });
  if (!r.ok) throw new Error(`media ${r.status}`);
  return { content: Buffer.from(await r.arrayBuffer()), contentType: r.headers.get('content-type') || '' };
}

/// Copies a text's photos into our storage right away (Twilio's copies can be
/// deleted), hashed, so the record doesn't depend on theirs.
async function keepSmsMedia(bucket, event, f) {
  const n = Math.min(Number(f.NumMedia || 0), 10);
  const out = [];
  for (let i = 0; i < n; i++) {
    const url = f[`MediaUrl${i}`];
    if (!url) continue;
    try {
      const m = await fetchTwilioMedia(url);
      const ct = m.contentType || f[`MediaContentType${i}`] || 'application/octet-stream';
      const path = `inbound/sms/${event.id}/media${i}${N.extFor(ct)}`;
      const sha256 = crypto.createHash('sha256').update(m.content).digest('hex');
      await bucket.file(path).save(m.content, { resumable: false, contentType: ct, metadata: { metadata: { sha256 } } });
      out.push({ path, contentType: ct, sha256, bytes: m.content.length });
    } catch (e) {
      console.warn('sms media fetch failed', event.id, i, e.message);
      out.push({ error: e.message, url });
    }
  }
  return out;
}

async function fileSmsInto(db, bucket, { eventId, matterRef, from, to, body, sid, at, media, known }) {
  const filed = [];
  const fromLabel = `Text from ${from}`;
  const common = {
    db,
    bucket,
    matterRef,
    channelKey: 'sms',
    fromLabel,
    senderKey: `tel:${from}`,
    quarantined: !known,
    reviewReason: known ? '' : `From ${from}, a number that isn't known on this matter. Approve to read it.`,
    receivedAt: at,
  };
  let parent = null;
  if (String(body || '').trim()) {
    const r = await fileInboundItem({
      ...common,
      buffer: Buffer.from(N.smsRecordText({ from, to, body, at: at.toISOString(), sid }), 'utf8'),
      fileName: `Text ${at.toISOString().slice(0, 16).replace('T', ' ')}.txt`,
      contentType: 'text/plain',
      kind: 'document',
      description: String(body).trim().slice(0, 300),
      source: `sms|from:${from}|to:${to}|sid:${sid}`,
      extra: { intakeEventId: eventId, smsBody: String(body).slice(0, 5000) },
    });
    parent = r.receiptId;
    filed.push(r.receiptId);
  }
  const bucketRef = bucket;
  for (let i = 0; i < media.length; i++) {
    const m = media[i];
    if (!m.path) continue;
    const [buf] = await bucketRef.file(m.path).download();
    const name = `Text photo ${at.toISOString().slice(0, 10)} ${i + 1}${N.extFor(m.contentType)}`;
    const r = await fileInboundItem({
      ...common,
      buffer: buf,
      fileName: name,
      contentType: m.contentType,
      kind: N.kindFor(m.contentType, name),
      description: String(body || '').trim() ? `Sent with: “${String(body).trim().slice(0, 120)}”` : 'Picture message',
      source: `mms|from:${from}|to:${to}|sid:${sid}|n:${i + 1}`,
      extra: { intakeEventId: eventId, ...(parent ? { parentReceiptId: parent } : {}) },
    });
    filed.push(r.receiptId);
  }
  return filed;
}

async function fileSms(db, bucket, event) {
  const f = event.data.fields || {};
  const from = N.normPhone(f.From);
  const to = N.normPhone(f.To);
  const at = new Date();
  const media = await keepSmsMedia(bucket, event, f);
  if (!from) return { filed: [], notes: ['no sender number'], media };
  const { list, firmsForTo } = await mattersForPhone(db, from, to);
  const target = list.find((d) => !(d.get('intakeEnabled') && d.get('intakeEnabled').sms === false));
  if (!target) {
    // Nobody we know: hold it for the firm to file by hand.
    const firmID = firmsForTo.length === 1 ? firmsForTo[0] : list.length ? list[0].get('firmID') : await soleFirmFor(db, to);
    await db.collection('UnroutedIntake').doc(event.id).set({
      firmID: firmID || '',
      channel: 'sms',
      from,
      to,
      body: String(f.Body || '').slice(0, 5000),
      sid: f.MessageSid || '',
      media,
      status: 'open',
      at: Timestamp.fromDate(at),
    });
    return { filed: [], notes: ['unrouted'], media };
  }
  const filed = await fileSmsInto(db, bucket, {
    eventId: event.id,
    matterRef: target.ref,
    from,
    to,
    body: f.Body,
    sid: f.MessageSid || '',
    at,
    media,
    known: true, // matched on the matter's own client phone
  });
  const notes = list.length > 1 ? [`${list.length} matters share this number; filed to the most recent`] : [];
  if (list.length > 1) {
    await Promise.all(filed.map((id) => db.collection('Receipts').doc(id).set({ reviewReason: `This number is on ${list.length} matters — filed to the most recent. Check it belongs here.` }, { merge: true })));
  }
  return { filed, notes, media };
}

/// With one shared demo number, the firm is only known if exactly one firm uses it.
async function soleFirmFor(db, to) {
  if (!to || to !== N.normPhone(P.TWILIO_SMS_NUMBER.value())) return '';
  const firms = await db.collection('firmAccount').limit(2).get();
  return firms.size === 1 ? firms.docs[0].get('firmID') || '' : '';
}

exports.onInboundEvent = onDocumentCreated(
  { document: 'InboundEvents/{eventId}', secrets: [P.TWILIO_AUTH_TOKEN], memory: '2GiB', timeoutSeconds: 540 },
  async (ev) => {
    const snap = ev.data;
    if (!snap) return;
    const data = snap.data();
    if (data.status !== 'queued') return;
    const db = getFirestore();
    const bucket = getStorage().bucket();
    await snap.ref.set({ status: 'filing' }, { merge: true });
    try {
      let result;
      if (data.kind === 'email') {
        const [body] = await bucket.file(data.storagePath).download();
        const e = await parseEmail(data.provider, body, data.contentType);
        result = await fileEmail(db, bucket, { id: snap.id }, e);
        result.from = e.from.email;
      } else {
        result = await fileSms(db, bucket, { id: snap.id, data });
      }
      await snap.ref.set({ status: result.filed.length ? 'filed' : 'unfiled', receipts: result.filed, notes: result.notes || [], from: result.from || '', doneAt: FieldValue.serverTimestamp() }, { merge: true });
    } catch (e) {
      console.error('onInboundEvent failed', snap.id, e);
      await snap.ref.set({ status: 'failed', error: String(e.message || e).slice(0, 500) }, { merge: true });
    }
  },
);

// ---------------------------------------------------------------------------
// Staff actions
// ---------------------------------------------------------------------------

exports.approveQuarantined = onCall(
  { secrets: [P.ANTHROPIC_API_KEY], timeoutSeconds: 540, memory: '2GiB' },
  async (request) => {
    const uid = requireAuth(request);
    const db = getFirestore();
    const data = request.data || {};
    assertDocId(data.receiptId, 'receiptId');
    const ref = db.collection('Receipts').doc(data.receiptId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Receipt not found');
    const matterRef = snap.get('matterId');
    const { ref: mRef } = await loadMatterForUser(db, uid, matterRef && matterRef.id);
    const senderKey = snap.get('senderKey') || '';

    // Approving a sender approves everything they sent to this matter.
    let targets = [ref];
    if (senderKey) {
      const held = await db.collection('Receipts').where('matterId', '==', mRef).where('extractionState', '==', 'quarantined').get();
      targets = held.docs.filter((d) => d.get('senderKey') === senderKey).map((d) => d.ref);
      if (!targets.some((r) => r.id === ref.id)) targets.push(ref);
    }
    if (data.remember && senderKey) {
      const v = senderKey.replace(/^(mail|tel):/, '');
      const field = senderKey.startsWith('tel:') ? 'clientPhones' : 'knownSenders';
      await mRef.set({ [field]: FieldValue.arrayUnion(v) }, { merge: true });
    }
    const deps = ingest.processDeps();
    let read = 0;
    for (const r of targets) {
      await r.set(
        { isQuarantined: false, classificationLabel: 'Processing', extractionState: 'running', reviewReason: '', approvedBy: uid, approvedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      try {
        await processReceipt(deps, r, { uid });
        read++;
      } catch (e) {
        console.error('approveQuarantined: reading failed', r.id, e);
        await r.set({ extractionState: 'extraction_failed', classificationLabel: 'Uncertain', extractionErrors: [`reading crashed: ${e.message}`] }, { merge: true });
      }
    }
    return { approved: targets.length, read };
  },
);

exports.assignUnrouted = onCall({ timeoutSeconds: 300, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  assertDocId(data.id, 'id');
  const firmId = await firmIdForUser(db, uid);
  const uref = db.collection('UnroutedIntake').doc(data.id);
  const u = await uref.get();
  if (!u.exists || u.get('firmID') !== firmId) throw new HttpsError('not-found', 'Message not found');
  if (u.get('status') !== 'open') throw new HttpsError('failed-precondition', 'This message was already handled.');
  if (data.dismiss === true) {
    await uref.set({ status: 'dismissed', handledBy: uid, handledAt: FieldValue.serverTimestamp() }, { merge: true });
    return { ok: true };
  }
  const { ref: matterRef } = await loadMatterForUser(db, uid, data.matterId);
  const from = u.get('from');
  if (data.remember) await matterRef.set({ clientPhones: FieldValue.arrayUnion(from) }, { merge: true });
  const at = u.get('at') && u.get('at').toDate ? u.get('at').toDate() : new Date();
  const filed = await fileSmsInto(db, bucket, {
    eventId: data.id,
    matterRef,
    from,
    to: u.get('to'),
    body: u.get('body'),
    sid: u.get('sid'),
    at,
    media: u.get('media') || [],
    known: true, // a person chose the matter
  });
  await uref.set({ status: 'filed', matterId: matterRef, receipts: filed, handledBy: uid, handledAt: FieldValue.serverTimestamp() }, { merge: true });
  return { ok: true, receipts: filed.length };
});

// For tests.
exports._internal = { parseEmail, synthesizeEml, intakeUpdates, parseMultipart };
