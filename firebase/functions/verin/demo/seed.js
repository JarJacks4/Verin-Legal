// Verin Legal — NFR demo workspace.
//
//   seedDemoWorkspace  (admin callable) Turns the caller's firm into a demo
//                      workspace, or resets one: everything in the firm's
//                      matters is deleted and replaced with fictional sample
//                      matters — real screenshots, an email, PDFs, a gap,
//                      a duplicate, an uncertain reading, a quarantined
//                      sender, an unmatched text, annotations, and three
//                      months of value-report history.
//
// Sample items go through the same hashing, chaining and RFC 3161 steps as
// real arrivals; only the AI reading is pre-written, so a demo costs nothing
// and always shows the same thing. A firm with real (non-demo) matters can't
// be turned into a demo — use a separate account for demos.

const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

const { requireAuth, requireAdmin } = require('../common/access');
const { fileInboundItem } = require('../intake/file');
const { chatScreenshot, simplePdf } = require('./screens');

if (!getApps().length) initializeApp();

const DAY = 86400000;
const TZ = 'America/Indiana/Indianapolis';

function at(daysAgo, h, m = 0) {
  const d = new Date(Date.now() - daysAgo * DAY);
  d.setUTCHours(h + 4, m, 0, 0); // ≈ Eastern time
  return d;
}

function dayLabel(d, withTime = true) {
  const day = d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', timeZone: TZ });
  if (!withTime) return day;
  const t = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', timeZone: TZ });
  return `${day} ${t}`;
}

const noonUtc = (d) => {
  const x = new Date(d);
  x.setUTCHours(12, 0, 0, 0);
  return x;
};

/// Receipt fields a finished reading would have written.
function readFields({ when, summary, platform = '', messages = [], evidenceType, statements = [], sensitive = [], label = 'Processed', reason = '', width, height, itemKind, extra = {} }) {
  return {
    aiSummary: summary,
    resolvedDate: Timestamp.fromDate(noonUtc(when)),
    dateConfidence: 'high',
    dateSource: messages.length ? 'on-screen timestamp' : 'document date line',
    threadMessages: messages,
    detectedPlatform: platform,
    evidenceType,
    statements,
    sensitive,
    classificationLabel: label,
    reviewReason: reason,
    extractionState: 'extracted',
    extractionErrors: [],
    extractedAt: Timestamp.fromDate(new Date(when.getTime() + 47000)),
    ...(width ? { imageWidth: width, imageHeight: height } : {}),
    ...(itemKind ? { itemKind } : {}),
    demo: true,
    ...extra,
  };
}

/// Draws a screenshot and returns the bytes + thread messages with boxes.
function screenshot({ contact, theme, items, sender }) {
  const s = chatScreenshot({ contact, theme, items });
  let lastHeader = '';
  const messages = items.map((it, i) => {
    if (it.header) lastHeader = it.header;
    return {
      speaker: it.header ? 'other' : it.side,
      text: it.header || it.text,
      timestampLabel: it.header ? it.header : '',
      isGap: !!it.gap,
      confidence: it.confidence == null ? (it.header ? 1 : 0.97) : it.confidence,
      sourceThumbnailUrl: '',
      platform: s.platform,
      isHeader: !!it.header,
      ...(it.header ? {} : { senderName: it.side === 'client' ? '' : sender || contact }),
      box: s.boxes[i],
    };
  });
  void lastHeader;
  return { buffer: s.png, messages, width: s.width, height: s.height, platform: s.platform };
}

// ---------------------------------------------------------------------------
// Wiping a demo firm
// ---------------------------------------------------------------------------

const DEMO_SMS_NUMBER = '+13175550000'; // 555-01xx/0000 numbers are reserved for fiction

/// "<lastname>-<4 digits>@<domain>", reserved like a real one so mail to it
/// would route here once intake is switched on.
async function demoAddress(db, matterRef, firmId, name) {
  const domain = String(process.env.INBOUND_EMAIL_DOMAIN || 'in.verinlegal.com').toLowerCase();
  const stem = String(name || 'matter').toLowerCase().split(/[^a-z]+/).filter((w) => w.length > 1).pop() || 'matter';
  for (let i = 0; i < 8; i++) {
    const local = `${stem.slice(0, 14)}-${1000 + Math.floor(Math.random() * 9000)}`;
    try {
      await db.collection('intakeAddresses').doc(local).create({ matterRef, firmID: firmId, demo: true, createdAt: FieldValue.serverTimestamp() });
      return `${local}@${domain}`;
    } catch (e) {
      if (e.code !== 6 && !/already exists/i.test(e.message || '')) throw e;
    }
  }
  return `${stem}-demo@${domain}`;
}

async function wipeFirm(db, bucket, firmId) {
  const writer = db.bulkWriter();
  const matters = await db.collection('Matters').where('firmID', '==', firmId).get();
  for (const m of matters.docs) {
    try {
      await bucket.deleteFiles({ prefix: `matters/${m.id}/` });
    } catch (e) {
      console.warn('demo wipe: storage', m.id, e.message);
    }
    const addrs = await db.collection('intakeAddresses').where('matterRef', '==', m.ref).get();
    addrs.docs.forEach((d) => writer.delete(d.ref));
  }
  for (const col of ['Receipts', 'chainEntries', 'Annotations', 'Corrections', 'FollowUps', 'Activity', 'UnroutedIntake', 'clioSyncLog']) {
    const snap = await db.collection(col).where('firmID', '==', firmId).get();
    for (const d of snap.docs) {
      if (col === 'Receipts') await db.recursiveDelete(d.ref, writer);
      else writer.delete(d.ref);
    }
  }
  for (const m of matters.docs) await db.recursiveDelete(m.ref, writer);
  await writer.close();
}

// ---------------------------------------------------------------------------
// The sample matters
// ---------------------------------------------------------------------------

async function seedFirm(db, bucket, firmId, user) {
  const made = { matters: 0, items: 0 };
  const newMatter = async (data) => {
    const ref = db.collection('Matters').doc();
    // A working-looking intake address and texting number, and a Clio match,
    // so the Intake and Practice mgmt tabs show the finished state.
    const emailAddress = await demoAddress(db, ref, firmId, data.clientName || data.matterName);
    const tail = String(data.caseNumber || '').replace(/\D/g, '').slice(-5) || '00001';
    const last = String(data.clientName || data.matterName || 'Matter').trim().split(/\s+/).pop();
    await ref.set({
      firmID: firmId,
      demo: true,
      matterType: 'Family law',
      isArchiveBuild: false,
      hasChronologyShift: false,
      intakeEnabled: { email: true, sms: true },
      emailAddress,
      smsNumber: DEMO_SMS_NUMBER,
      intakeProvisionedAt: data.openedAt || Timestamp.now(),
      clioMatterID: `9${tail}`,
      clioMatterDisplayNumber: `${tail}-${last}`,
      clioMatterUrl: '',
      clioSyncedAt: Timestamp.fromDate(at(1, 16, 40)),
      clioLastPushStatus: 'ok',
      ...data,
    });
    made.matters++;
    return ref;
  };
  const file = async (matterRef, o) => {
    const r = await fileInboundItem({ db, bucket, matterRef, ...o });
    made.items++;
    return r.receiptId;
  };

  // ---- Matter 1: Reyes v. Reyes — custody modification ----------------------
  const reyes = await newMatter({
    matterName: 'Reyes v. Reyes',
    caseTitle: 'Reyes v. Reyes',
    clientName: 'Dana Reyes',
    caseNumber: '49D08-2026-DR-004417',
    practiceArea: 'Child custody',
    status: 'Open',
    openedAt: Timestamp.fromDate(at(44, 10)),
    clientPhone: '+13175550142',
    clientPhones: ['+13175550142'],
    clientEmail: 'dana.reyes@example.com',
    clientEmails: ['dana.reyes@example.com'],
    participantAliases: {},
  });

  const d1 = at(31, 16, 12);
  const s1 = screenshot({
    contact: 'Marcus',
    items: [
      { header: dayLabel(d1) },
      { side: 'other', text: "I'm picking Lily up at 5 not 6 today" },
      { side: 'client', text: 'The order says 6. She has practice until 5:30.' },
      { side: 'other', text: "Then I'll get her from practice." },
      { side: 'client', text: "Please don't. Coach only releases her to me or Mom." },
      { side: 'other', text: "We'll see." },
    ],
  });
  const r1 = await file(reyes, {
    buffer: s1.buffer,
    fileName: 'IMG_4102.PNG',
    contentType: 'image/png',
    kind: 'photo',
    channelKey: 'sms',
    fromLabel: 'Text from (317) 555-0142',
    senderKey: 'tel:+13175550142',
    description: 'Screenshot of texts with Marcus about pickup time',
    source: 'demo|sms|IMG_4102',
    receivedAt: at(30, 21, 5),
    extra: readFields({
      when: d1,
      summary: 'Text exchange between Dana and Marcus about whether pickup is at 5 or 6 PM and who may collect Lily from practice.',
      platform: s1.platform,
      messages: s1.messages,
      evidenceType: 'screenshot',
      width: s1.width,
      height: s1.height,
      itemKind: 'screenshot',
    }),
  });

  const d2 = at(30, 9, 3);
  const s2 = screenshot({
    contact: 'Marcus',
    items: [
      { header: dayLabel(d2) },
      { side: 'other', text: "You didn't answer when I called last night." },
      { side: 'client', text: 'Lily was asleep. You can call her at 7 like we agreed.' },
      { side: 'other', text: "Then I'm keeping her Sunday." },
    ],
  });
  const r2 = await file(reyes, {
    buffer: s2.buffer,
    fileName: 'IMG_4107.PNG',
    contentType: 'image/png',
    kind: 'photo',
    channelKey: 'sms',
    fromLabel: 'Text from (317) 555-0142',
    senderKey: 'tel:+13175550142',
    description: 'Screenshot of texts with Marcus about a missed call',
    source: 'demo|sms|IMG_4107',
    receivedAt: at(29, 10, 40),
    extra: readFields({
      when: d2,
      summary: 'Marcus says Dana did not answer his call; Dana says Lily was asleep and refers to the agreed 7 PM call; Marcus says he will keep Lily on Sunday.',
      platform: s2.platform,
      messages: s2.messages,
      evidenceType: 'screenshot',
      width: s2.width,
      height: s2.height,
      itemKind: 'screenshot',
    }),
  });

  // Overlaps the last screenshot (the repeated line is recognised), then a gap.
  const d3 = at(25, 19, 48);
  const s3 = screenshot({
    contact: 'Marcus',
    items: [
      { header: dayLabel(d2) },
      { side: 'other', text: "Then I'm keeping her Sunday." },
      { header: dayLabel(d3) },
      { side: 'other', text: 'Did she get the shoes I sent?', gap: true },
      { side: 'client', text: 'Yes, thank you. She loves them.' },
      { side: 'other', text: 'Good. I want to switch my weekends to Thursdays.' },
      { side: 'client', text: "Let's put that through the attorneys." },
    ],
  });
  const r3 = await file(reyes, {
    buffer: s3.buffer,
    fileName: 'IMG_4131.PNG',
    contentType: 'image/png',
    kind: 'photo',
    channelKey: 'sms',
    fromLabel: 'Text from (317) 555-0142',
    senderKey: 'tel:+13175550142',
    description: 'Screenshot of texts with Marcus about shoes and a schedule change',
    source: 'demo|sms|IMG_4131',
    receivedAt: at(24, 8, 15),
    extra: readFields({
      when: d3,
      summary: 'Continues the thread: Marcus asks about shoes he sent and proposes switching weekends to Thursdays; Dana asks to go through the attorneys.',
      platform: s3.platform,
      messages: s3.messages,
      evidenceType: 'screenshot',
      width: s3.width,
      height: s3.height,
      itemKind: 'screenshot',
    }),
  });

  // An email the client forwarded.
  const d4 = at(19, 8, 15);
  const emailBody =
    'Dana,\r\n\r\nFor Thanksgiving I am taking Lily to my parents in Fort Wayne from Wednesday after school until Sunday at 6. ' +
    'My mom already bought the tickets for the parade.\r\n\r\nMarcus';
  const eml = Buffer.from(
    [
      'From: "Marcus Reyes" <marcus.reyes@example.com>',
      'To: "Dana Reyes" <dana.reyes@example.com>',
      'Subject: Thanksgiving',
      `Date: ${d4.toUTCString()}`,
      'MIME-Version: 1.0',
      'Content-Type: text/plain; charset=utf-8',
      '',
      emailBody,
    ].join('\r\n'),
    'utf8',
  );
  const r4 = await file(reyes, {
    buffer: eml,
    fileName: 'Fwd Thanksgiving.eml',
    contentType: 'message/rfc822',
    kind: 'email',
    channelKey: 'email',
    fromLabel: 'Dana Reyes <dana.reyes@example.com>',
    senderKey: 'mail:dana.reyes@example.com',
    description: 'Fwd: Thanksgiving',
    source: 'demo|email|thanksgiving',
    receivedAt: at(19, 9, 2),
    extra: readFields({
      when: d4,
      summary: 'Email from Marcus to Dana stating he will take Lily to Fort Wayne for Thanksgiving from Wednesday after school until Sunday at 6.',
      platform: 'Email',
      messages: [
        { speaker: 'other', text: emailBody.replace(/\r\n/g, '\n'), timestampLabel: dayLabel(d4), isGap: false, confidence: 0.99, sourceThumbnailUrl: '', platform: 'Email', isHeader: false, senderName: 'Marcus Reyes' },
      ],
      evidenceType: 'email',
      statements: [{ kind: 'date', text: 'Wednesday after school until Sunday at 6' }],
      extra: { emailSubject: 'Thanksgiving', emailFrom: 'marcus.reyes@example.com', attachmentCount: 0 },
    }),
  });

  // A school record (PDF) with dates and a child's name to redact.
  const d5 = at(14, 11);
  const pdfLines = [
    { text: 'Westfield Elementary School', bold: true, size: 16, gap: 6 },
    { text: 'Attendance Record — Grade 3', size: 12, gap: 18 },
    { text: 'Student: Lily M. Reyes' },
    { text: 'Student ID: 2209-4417', gap: 14 },
    { text: `Report date: ${dayLabel(d5, false)}`, gap: 18 },
    { text: 'Tardy arrivals this term: 6', bold: true },
    { text: 'Late pickups (after 3:30 PM) this term: 4', bold: true, gap: 18 },
    { text: 'Late pickups occurred on days the student was released to the father.' },
    { text: 'Office contact: (317) 555-0100' },
  ];
  const pdf = await simplePdf(pdfLines);
  const r5 = await file(reyes, {
    buffer: pdf.pdf,
    fileName: 'Attendance record.pdf',
    contentType: 'application/pdf',
    kind: 'document',
    channelKey: 'email',
    fromLabel: 'Dana Reyes <dana.reyes@example.com>',
    senderKey: 'mail:dana.reyes@example.com',
    description: 'School attendance record',
    source: 'demo|email|attendance',
    receivedAt: at(13, 14, 30),
    extra: readFields({
      when: d5,
      summary: 'School attendance record for Lily Reyes listing 6 tardy arrivals and 4 late pickups this term, noting the late pickups were on days she was released to her father.',
      evidenceType: 'document',
      statements: [
        { kind: 'amount', text: 'Tardy arrivals this term: 6', page: 1, box: pdf.boxes[5] },
        { kind: 'amount', text: 'Late pickups (after 3:30 PM) this term: 4', page: 1, box: pdf.boxes[6] },
        { kind: 'event', text: 'Late pickups occurred on days the student was released to the father.', page: 1, box: pdf.boxes[7] },
      ],
      sensitive: [
        { category: 'minor_name', text: 'Lily M. Reyes', page: 1, box: pdf.boxes[2] },
        { category: 'other', text: 'Student ID: 2209-4417', page: 1, box: pdf.boxes[3] },
        { category: 'phone', text: '(317) 555-0100', page: 1, box: pdf.boxes[8] },
      ],
      extra: { documentText: pdfLines.map((l) => l.text).join('\n'), pageCount: 1 },
    }),
  });

  // A hard-to-read screenshot: waits in the Review queue.
  const d6 = at(9, 20, 5);
  const s6 = screenshot({
    contact: 'Marcus',
    items: [
      { header: dayLabel(d6) },
      { side: 'other', text: "She's not going to the pool party with your sister." },
      { side: 'client', text: 'It was on the calendar you agreed to.' },
      { side: 'other', text: 'Not after what happened at the pool last time.', confidence: 0.46 },
    ],
  });
  await file(reyes, {
    buffer: s6.buffer,
    fileName: 'IMG_4188.PNG',
    contentType: 'image/png',
    kind: 'photo',
    channelKey: 'sms',
    fromLabel: 'Text from (317) 555-0142',
    senderKey: 'tel:+13175550142',
    description: 'Screenshot of texts about a pool party',
    source: 'demo|sms|IMG_4188',
    receivedAt: at(8, 7, 50),
    extra: readFields({
      when: d6,
      summary: 'Marcus says Lily will not attend a pool party with Dana\'s sister; Dana says it was on the agreed calendar.',
      platform: s6.platform,
      messages: s6.messages,
      evidenceType: 'screenshot',
      width: s6.width,
      height: s6.height,
      itemKind: 'screenshot',
      label: 'Uncertain',
      reason: '1 message was hard to read — check against the image.',
    }),
  });

  // An unknown sender: stored and hashed, held for approval.
  const qEml = Buffer.from(
    [
      'From: "Rosa Alvarez" <rosa.alvarez@example.com>',
      'To: reyes-demo@in.verinlegal.com',
      'Subject: Photos from Saturday exchange',
      `Date: ${at(3, 18).toUTCString()}`,
      'MIME-Version: 1.0',
      'Content-Type: text/plain; charset=utf-8',
      '',
      "Hi, I'm Dana's sister. I was at the exchange on Saturday and took these. Dana asked me to send them here.",
    ].join('\r\n'),
    'utf8',
  );
  await file(reyes, {
    buffer: qEml,
    fileName: 'Photos from Saturday exchange.eml',
    contentType: 'message/rfc822',
    kind: 'email',
    channelKey: 'email',
    fromLabel: 'Rosa Alvarez <rosa.alvarez@example.com>',
    senderKey: 'mail:rosa.alvarez@example.com',
    description: 'Photos from Saturday exchange',
    source: 'demo|email|quarantine',
    quarantined: true,
    reviewReason: "From rosa.alvarez@example.com, who isn't known on this matter. Approve to read it.",
    receivedAt: at(3, 18, 4),
    extra: { demo: true, emailSubject: 'Photos from Saturday exchange', emailFrom: 'rosa.alvarez@example.com' },
  });

  // ---- Matter 2: In re the Marriage of Carter — dissolution -----------------
  const carter = await newMatter({
    matterName: 'In re the Marriage of Carter',
    caseTitle: 'In re the Marriage of Carter',
    clientName: 'Morgan Carter',
    caseNumber: '49D12-2026-DR-002961',
    practiceArea: 'Divorce',
    status: 'Open',
    openedAt: Timestamp.fromDate(at(60, 9)),
    clientPhone: '+13175550177',
    clientPhones: ['+13175550177'],
    clientEmail: 'morgan.carter@example.com',
    clientEmails: ['morgan.carter@example.com'],
  });
  const c1d = at(40, 21, 17);
  const c1 = screenshot({
    contact: 'Jordan',
    theme: 'whatsapp',
    items: [
      { header: dayLabel(c1d) },
      { side: 'other', text: 'I moved the savings into my account. It was mine anyway.' },
      { side: 'client', text: 'That is joint money. We both put into it.' },
      { side: 'other', text: "Prove it. You haven't worked since 2023." },
      { side: 'client', text: 'My lawyer has the statements.' },
    ],
  });
  const cr1 = await file(carter, {
    buffer: c1.buffer,
    fileName: 'WhatsApp Image 1.jpg',
    contentType: 'image/png',
    kind: 'photo',
    channelKey: 'sms',
    fromLabel: 'Text from (317) 555-0177',
    senderKey: 'tel:+13175550177',
    description: 'WhatsApp screenshot about the savings account',
    source: 'demo|sms|carter1',
    receivedAt: at(39, 8, 30),
    extra: readFields({
      when: c1d,
      summary: 'Jordan says he moved the savings into his own account; Morgan says it is joint money and that her lawyer has the statements.',
      platform: c1.platform,
      messages: c1.messages,
      evidenceType: 'screenshot',
      width: c1.width,
      height: c1.height,
      itemKind: 'screenshot',
    }),
  });
  const c2d = at(41, 12);
  const stLines = [
    { text: 'First Hoosier Credit Union', bold: true, size: 16, gap: 6 },
    { text: 'Joint Savings — Monthly Statement', size: 12, gap: 18 },
    { text: 'Account holders: Jordan Carter, Morgan Carter' },
    { text: 'Account number: 4410 2291 0087 3315', gap: 18 },
    { text: `Statement closing date: ${dayLabel(c2d, false)}`, gap: 18 },
    { text: 'Opening balance: $48,212.67' },
    { text: 'Transfer to account ending 9902: -$47,500.00', bold: true },
    { text: 'Closing balance: $712.67', gap: 18 },
    { text: '1200 N Meridian St, Indianapolis, IN 46204' },
  ];
  const st = await simplePdf(stLines);
  await file(carter, {
    buffer: st.pdf,
    fileName: 'Joint savings statement.pdf',
    contentType: 'application/pdf',
    kind: 'document',
    channelKey: 'email',
    fromLabel: 'Morgan Carter <morgan.carter@example.com>',
    senderKey: 'mail:morgan.carter@example.com',
    description: 'Joint savings statement',
    source: 'demo|email|statement',
    receivedAt: at(38, 15, 10),
    extra: readFields({
      when: c2d,
      summary: 'Joint savings statement for Jordan and Morgan Carter showing a $47,500.00 transfer to an account ending 9902, leaving $712.67.',
      evidenceType: 'document',
      statements: [
        { kind: 'amount', text: 'Opening balance: $48,212.67', page: 1, box: st.boxes[5] },
        { kind: 'amount', text: 'Transfer to account ending 9902: -$47,500.00', page: 1, box: st.boxes[6] },
        { kind: 'amount', text: 'Closing balance: $712.67', page: 1, box: st.boxes[7] },
      ],
      sensitive: [
        { category: 'account', text: '4410 2291 0087 3315', page: 1, box: st.boxes[3] },
        { category: 'address', text: '1200 N Meridian St, Indianapolis, IN 46204', page: 1, box: st.boxes[8] },
      ],
      extra: { documentText: stLines.map((l) => l.text).join('\n'), pageCount: 1 },
    }),
  });

  // ---- Matter 3: a closed protective-order matter ---------------------------
  const patel = await newMatter({
    matterName: 'Patel — Protective order',
    caseTitle: 'Patel — Protective order',
    clientName: 'Priya Patel',
    caseNumber: '49D04-2026-PO-000318',
    practiceArea: 'Protective / restraining order',
    status: 'Closed',
    openedAt: Timestamp.fromDate(at(120, 9)),
    clientPhones: ['+13175550133'],
  });
  const p1d = at(110, 23, 2);
  const p1 = screenshot({
    contact: 'Unknown',
    items: [
      { header: dayLabel(p1d) },
      { side: 'other', text: 'I know where you park now.' },
      { side: 'other', text: 'Answer me.' },
      { side: 'client', text: 'Stop contacting me. I have a protective order.' },
    ],
  });
  await file(patel, {
    buffer: p1.buffer,
    fileName: 'IMG_0091.PNG',
    contentType: 'image/png',
    kind: 'photo',
    channelKey: 'sms',
    fromLabel: 'Text from (317) 555-0133',
    senderKey: 'tel:+13175550133',
    description: 'Screenshot of messages from an unknown number',
    source: 'demo|sms|patel',
    receivedAt: at(110, 23, 30),
    extra: readFields({
      when: p1d,
      summary: 'Messages from an unidentified number saying "I know where you park now" and "Answer me"; Priya replies that she has a protective order.',
      platform: p1.platform,
      messages: p1.messages,
      evidenceType: 'screenshot',
      width: p1.width,
      height: p1.height,
      itemKind: 'screenshot',
    }),
  });

  // ---- Annotations on the Reyes thread --------------------------------------
  const notes = [
    [r1, 4, 'key', "Matches the coach's release policy — request a copy from the club."],
    [r2, 3, 'followup', 'Was Sunday actually withheld? Ask Dana for texts from that weekend.'],
    [r3, 5, 'question', 'Proposed schedule change — has opposing counsel raised this formally?'],
    [r4, 0, 'key', 'Thanksgiving dates conflict with the holiday schedule in the decree (alternating years).'],
    [cr1, 1, 'key', 'Admission he moved joint funds — pairs with the 47,500 transfer on the statement.'],
  ];
  for (const [rid, i, tag, text] of notes) {
    const r = await db.collection('Receipts').doc(rid).get();
    const msgs = r.get('threadMessages') || [];
    await db.collection('Annotations').add({
      firmID: firmId,
      matterId: r.get('matterId'),
      receiptId: r.ref,
      messageKey: `${rid}#${i}`,
      messageIndex: i,
      messageText: String((msgs[i] && msgs[i].text) || '').slice(0, 500),
      text,
      tag,
      authorUid: user.uid,
      authorName: user.name,
      createdAt: Timestamp.fromDate(at(Math.max(1, 20 - notes.indexOf(notes.find((n) => n[0] === rid))), 15)),
      demo: true,
    });
  }

  // A text from a number no matter knows (Review queue → File to matter).
  await db.collection('UnroutedIntake').doc().set({
    firmID: firmId,
    channel: 'sms',
    from: '+13175550199',
    to: '+13175550000',
    body: "Hi, this is Dana Reyes's mom. Dana asked me to send you the pickup photos from Friday.",
    sid: 'SMdemo',
    media: [],
    status: 'open',
    at: Timestamp.fromDate(at(1, 17, 20)),
    demo: true,
  });

  // ---- Three months of value-report history ---------------------------------
  const hist = db.bulkWriter();
  const kinds = [
    ['screenshot', 'photo', 9],
    ['document', 'document', 0],
    ['email', 'email', 1],
    ['screenshot', 'photo', 14],
  ];
  for (let d = 90; d >= 2; d--) {
    const n = (d % 7 === 0 || d % 7 === 6) ? 1 : 2 + (d % 3);
    for (let k = 0; k < n; k++) {
      const [evidenceType, itemKind, messages] = kinds[(d + k) % kinds.length];
      hist.create(db.collection('Activity').doc(), {
        firmID: firmId,
        matterId: [reyes, carter, patel][(d + k) % 3],
        type: 'read',
        itemKind,
        evidenceType,
        state: 'extracted',
        messages,
        statements: evidenceType === 'document' ? 4 : 0,
        transcriptLines: 0,
        durationSeconds: 0,
        duplicate: (d + k) % 17 === 0,
        readMs: 38000 + ((d * 7919 + k * 104729) % 40000),
        at: Timestamp.fromDate(at(d, 9 + k * 2)),
        demo: true,
      });
    }
    if (d % 2 === 0) {
      hist.create(db.collection('Activity').doc(), {
        firmID: firmId,
        matterId: reyes,
        uid: user.uid,
        type: 'review',
        durationMs: 60000 + ((d * 31337) % 240000),
        itemsViewed: 3,
        itemsTotal: 4,
        at: Timestamp.fromDate(at(d, 14)),
        demo: true,
      });
    }
    if (d % 9 === 0) hist.create(db.collection('Activity').doc(), { firmID: firmId, matterId: reyes, uid: user.uid, type: 'correction', field: 'text', at: Timestamp.fromDate(at(d, 15)), demo: true });
    if (d % 11 === 0) hist.create(db.collection('Activity').doc(), { firmID: firmId, matterId: carter, uid: user.uid, type: 'follow_up_sent', requests: 1, at: Timestamp.fromDate(at(d, 16)), demo: true });
    if (d % 30 === 0) hist.create(db.collection('Activity').doc(), { firmID: firmId, matterId: carter, uid: user.uid, type: 'export', exhibits: 12, pages: 41, at: Timestamp.fromDate(at(d, 17)), demo: true });
  }
  await hist.close();

  void r5;
  return made;
}

exports.seedDemoWorkspace = onCall({ timeoutSeconds: 540, memory: '2GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const { firmId } = await requireAdmin(db, uid);

  const acctSnap = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  const acctRef = acctSnap.empty ? db.collection('firmAccount').doc(firmId) : acctSnap.docs[0].ref;
  const isDemo = !acctSnap.empty && acctSnap.docs[0].get('isDemo') === true;
  if (!isDemo) {
    const real = await db.collection('Matters').where('firmID', '==', firmId).get();
    const realCount = real.docs.filter((d) => d.get('demo') !== true).length;
    if (realCount > 0) {
      throw new HttpsError(
        'failed-precondition',
        `This workspace has ${realCount} real matter${realCount === 1 ? '' : 's'}. Sign up a separate account (e.g. demo@yourfirm.com) and make that the demo workspace.`,
      );
    }
  }

  const userSnap = await db.collection('users').doc(uid).get();
  const name = String(userSnap.get('display_name') || userSnap.get('displayName') || userSnap.get('full_name') || 'Demo attorney');

  await acctRef.set({ isDemo: true, demoResetting: true }, { merge: true });
  try {
    await wipeFirm(db, bucket, firmId);
    const made = await seedFirm(db, bucket, firmId, { uid, name });
    await db.collection('integrationStatus').doc(firmId).set(
      { firmID: firmId, clioConnected: true, clioUserName: 'Doe Family Law', clioRegion: 'us', clioConnectedAt: Timestamp.fromDate(at(40, 10)), demo: true },
      { merge: true },
    );
    await acctRef.set({ demoResetting: false, demoSeededAt: FieldValue.serverTimestamp(), demoSeededBy: uid }, { merge: true });
    return { ok: true, ...made };
  } catch (e) {
    console.error('seedDemoWorkspace failed', e);
    await acctRef.set({ demoResetting: false }, { merge: true });
    throw new HttpsError('internal', `The demo could not be prepared: ${e.message}`);
  }
});

// ---------------------------------------------------------------------------
// Live arrivals during a demo
// ---------------------------------------------------------------------------

/// The next thing a client "sends" to this demo matter.
function nextArrival(matter, n) {
  const client = String(matter.clientName || 'Client');
  const other = client.includes('Reyes') ? 'Marcus' : client.includes('Carter') ? 'Jordan' : 'Unknown';
  const yest = at(1, 18, 42);
  const today = at(0, 8, 5);
  const scripts = client.includes('Reyes')
    ? [
        {
          kind: 'text',
          contact: 'Marcus',
          file: 'IMG_4210.PNG',
          when: yest,
          items: [
            { header: dayLabel(yest) },
            { side: 'other', text: "Running late. I'll drop her at 7:30 instead of 6." },
            { side: 'client', text: 'The order says 6. She has school tomorrow.' },
            { side: 'other', text: 'Not my problem.' },
          ],
          summary: 'Marcus says he will return Lily at 7:30 instead of 6; Dana refers to the order and a school night.',
        },
        {
          kind: 'text',
          contact: 'Coach Ramirez',
          file: 'IMG_4214.PNG',
          when: today,
          items: [
            { header: dayLabel(today) },
            { side: 'other', text: 'Lily was picked up by her dad at 6:20 last night. We close at 6.' },
            { side: 'client', text: 'Thank you for letting me know.' },
          ],
          summary: 'The club coach tells Dana that Lily was collected by her father at 6:20, after the 6:00 closing time.',
        },
        {
          kind: 'email',
          from: 'Marcus Reyes <marcus.reyes@example.com>',
          subject: 'Re: this weekend',
          when: today,
          body: "Dana,\n\nI'm taking Lily to the lake house Saturday and Sunday. We'll be back Sunday night, probably late.\n\nMarcus",
          summary: 'Email from Marcus saying he will take Lily to the lake house for the weekend and return late Sunday night.',
        },
      ]
    : [
        {
          kind: 'text',
          contact: other,
          file: `IMG_${5000 + n}.PNG`,
          when: yest,
          items: [
            { header: dayLabel(yest) },
            { side: 'other', text: 'Can we talk about this without the lawyers?' },
            { side: 'client', text: 'Please send everything through my attorney.' },
          ],
          summary: `${other} asks to talk without the attorneys; ${client.split(' ')[0]} asks that everything go through counsel.`,
        },
      ];
  return scripts[n % scripts.length];
}

exports.demoSimulateArrival = onCall({ timeoutSeconds: 120, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const { firmId } = await requireAdmin(db, uid).catch(async () => {
    // Any member of a demo firm may run the demo.
    const u = await db.collection('users').doc(uid).get();
    return { firmId: String(u.get('firmID') || '') };
  });
  const matterId = String((request.data || {}).matterId || '');
  if (!matterId || matterId.includes('/')) throw new HttpsError('invalid-argument', 'matterId is required');
  const mRef = db.collection('Matters').doc(matterId);
  const m = await mRef.get();
  if (!m.exists || m.get('firmID') !== firmId) throw new HttpsError('not-found', 'Matter not found');
  const acct = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  if (acct.empty || acct.docs[0].get('isDemo') !== true) throw new HttpsError('failed-precondition', 'Only available in a demo workspace.');

  const n = Number(m.get('demoSimIndex') || 0);
  const sc = nextArrival(m.data(), n);
  const phone = (m.get('clientPhones') || [])[0] || DEMO_SMS_NUMBER;
  const email = (m.get('clientEmails') || [])[0] || 'client@example.com';
  let buffer;
  let fileName;
  let contentType;
  let kind;
  let channelKey;
  let fromLabel;
  let senderKey;
  let read;
  if (sc.kind === 'text') {
    const shot = screenshot({ contact: sc.contact, items: sc.items });
    buffer = shot.buffer;
    fileName = sc.file;
    contentType = 'image/png';
    kind = 'photo';
    channelKey = 'sms';
    fromLabel = `Text from ${phone}`;
    senderKey = `tel:${phone}`;
    read = readFields({ when: sc.when, summary: sc.summary, platform: shot.platform, messages: shot.messages, evidenceType: 'screenshot', width: shot.width, height: shot.height, itemKind: 'screenshot' });
  } else {
    buffer = Buffer.from(
      [`From: ${sc.from}`, `To: ${m.get('emailAddress') || 'intake@in.verinlegal.com'}`, `Subject: ${sc.subject}`, `Date: ${sc.when.toUTCString()}`, 'MIME-Version: 1.0', 'Content-Type: text/plain; charset=utf-8', '', sc.body.replace(/\n/g, '\r\n')].join('\r\n'),
      'utf8',
    );
    fileName = `${sc.subject}.eml`;
    contentType = 'message/rfc822';
    kind = 'email';
    channelKey = 'email';
    fromLabel = `${m.get('clientName') || 'Client'} <${email}>`;
    senderKey = `mail:${email}`;
    read = readFields({
      when: sc.when,
      summary: sc.summary,
      platform: 'Email',
      messages: [{ speaker: 'other', text: sc.body, timestampLabel: dayLabel(sc.when), isGap: false, confidence: 0.99, sourceThumbnailUrl: '', platform: 'Email', isHeader: false, senderName: sc.from.split(' <')[0] }],
      evidenceType: 'email',
      extra: { emailSubject: sc.subject, emailFrom: sc.from },
    });
  }

  // Arrives now, shows "Reading…", then the reading lands a few seconds later.
  const r = await fileInboundItem({
    db,
    bucket,
    matterRef: mRef,
    buffer,
    fileName,
    contentType,
    kind,
    channelKey,
    fromLabel,
    senderKey,
    description: sc.kind === 'text' ? `Screenshot of texts with ${sc.contact}` : sc.subject,
    source: `demo|live|${n}`,
    receivedAt: new Date(),
    extra: { demo: true, extractionState: 'running', classificationLabel: 'Processing' },
  });
  await mRef.set({ demoSimIndex: n + 1, lastReceiptAt: FieldValue.serverTimestamp() }, { merge: true });
  await new Promise((res) => setTimeout(res, 5000));
  await db.collection('Receipts').doc(r.receiptId).set({ ...read, extractedAt: Timestamp.now() }, { merge: true });
  return { ok: true, receiptId: r.receiptId, kind: sc.kind };
});

exports._internal = { screenshot, dayLabel, at, nextArrival };
