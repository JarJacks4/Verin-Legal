// Verin Legal — one hearing/filing packet per practice (checklist #27, #71).
//
//   family_exhibit_packet   → Exhibits tab (Bates-stamped production + index);
//                             listed here so every practice has one entry point.
//   pi_treatment_chronology  Personal injury: dated chronology of records,
//                             bills and photos — the demand support set.
//   immigration_checklist    Immigration: what the record holds for each
//                             common evidence category (coverage, not sufficiency).
//   civil_key_dates          Civil litigation: key-date chronology with hearings
//                             and items marked Key evidence.
//   criminal_event_window    Criminal defense: every message and item inside a
//                             time window around an event, to the minute.
//   criminal_mitigation      Criminal defense: mitigation packet index — the
//                             documents and notes the team has marked.
//
// Redaction flags are confirmed before export: if any included item carries a
// suggested redaction, the caller must confirm (the flagged text is masked in
// the packet either way).

const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { requireAuth, loadMatterForUser } = require('../common/access');
const M = require('./metrics');
const { createReport, DISCLAIMER, day } = require('./pdf');
const { saveReport, stampOf, slug } = require('./store');

const KINDS = {
  pi_treatment_chronology: { title: 'Treatment Chronology', practice: 'Personal injury', sub: 'Demand support set' },
  immigration_checklist: { title: 'Evidence Checklist Coverage', practice: 'Immigration', sub: 'What the record holds, by category' },
  civil_key_dates: { title: 'Key-Date Chronology', practice: 'Civil litigation', sub: 'Dated items, hearings and key evidence' },
  criminal_event_window: { title: 'Event Window Report', practice: 'Criminal defense', sub: 'Everything inside the window, to the minute' },
  criminal_mitigation: { title: 'Mitigation Packet', practice: 'Criminal defense', sub: 'Marked documents and notes' },
};

const IMMIGRATION_CATEGORIES = [
  ['Identity and civil documents', /passport|birth cert|national id|identity card|driver'?s licen|cedula|visa\b/i],
  ['Status and immigration history', /\bi-94\b|\bi-797\b|\bi-130\b|\bi-485\b|\bi-765\b|\bead\b|green card|uscis|notice of action|parole|asylum|\ba-?number\b|alien registration/i],
  ['Relationship evidence', /marriage|wedding|spouse|husband|wife|together|joint (account|lease|tax)|engagement|family photo/i],
  ['Financial support', /\bi-864\b|tax return|w-?2\b|1099|pay ?stub|paystub|bank statement|employment letter|salary|income/i],
  ['Residence', /lease|rent|mortgage|utility|electric bill|water bill|address|residence/i],
  ['Police and court records', /police|arrest|court|disposition|conviction|record check|background check|fbi/i],
  ['Medical', /medical|vaccin|doctor|hospital|exam|\bi-693\b/i],
  ['Hardship and declarations', /declaration|affidavit|hardship|letter of support|statement of/i],
  ['Translations', /translat|certified translation/i],
];

const toD = M.toDate;
const headline = (r) => String(r.content || r.description || r.originalFileName || 'Item').split('\n')[0].slice(0, 140);
const textOf = (r) => [r.content, r.description, r.originalFileName, r.aiSummary, r.emailSubject].filter(Boolean).join(' ');

/// Every flagged string across the given items → masker.
function masker(receipts) {
  const items = [];
  for (const r of receipts) for (const s of r.sensitive || []) if (s && s.text && s.text.length >= 3) items.push(s.text);
  const uniq = [...new Set(items)].sort((a, b) => b.length - a.length);
  return {
    count: uniq.length,
    mask: (t) => uniq.reduce((acc, s) => acc.split(s).join('█'.repeat(Math.min(s.length, 12))), String(t || '')),
  };
}

function immigrationCoverage(receipts) {
  return IMMIGRATION_CATEGORIES.map(([name, re]) => ({ name, items: receipts.filter((r) => r.isDuplicate !== true && re.test(textOf(r))) }));
}

function inWindow(entries, receipts, eventAt, hours) {
  const t0 = eventAt.getTime() - hours * 3600000;
  const t1 = eventAt.getTime() + hours * 3600000;
  const msgs = (entries || [])
    .filter((e) => e.kind === 'msg' && e.date)
    .map((e) => ({ e, at: new Date(`${e.date}T${e.time || '00:00'}:00`) }))
    .filter((x) => !Number.isNaN(x.at.getTime()) && x.at.getTime() >= t0 && x.at.getTime() <= t1)
    .sort((a, b) => a.at - b.at);
  const items = receipts
    .filter((r) => r.isDuplicate !== true)
    .map((r) => ({ r, at: toD(r.resolvedDate) }))
    .filter((x) => x.at && x.at.getTime() >= t0 && x.at.getTime() <= t1)
    .sort((a, b) => a.at - b.at);
  return { msgs, items, t0: new Date(t0), t1: new Date(t1) };
}

async function buildPacketPdf({ kind, matter, receipts, thread, annotations, opts, generatedAt, firmName }) {
  const k = KINDS[kind];
  const mk = masker(receipts);
  const title = matter.matterName || matter.caseTitle || 'Matter';
  const R = createReport({
    title: k.title,
    subtitle: `${title}${matter.caseNumber ? ` · ${matter.caseNumber}` : ''} · ${k.sub}`,
    kicker: `VERIN · ${k.practice.toUpperCase()}`,
    footer: `Verin ${k.title} · ${title} · generated ${generatedAt.toISOString()}`,
  });
  R.kv('Client', matter.clientName);
  R.kv('Prepared for', firmName);
  R.kv('Items in the record', String(receipts.length));
  R.kv('Redaction flags', mk.count ? `${mk.count} flagged value${mk.count === 1 ? '' : 's'} masked in this packet (confirmed before export)` : 'None flagged');
  R.kv('Generated', generatedAt.toISOString());

  const dated = receipts.filter((r) => r.isDuplicate !== true).map((r) => ({ r, at: toD(r.resolvedDate) || null }));

  if (kind === 'pi_treatment_chronology') {
    R.heading('Chronology');
    R.table(
      [
        { title: 'Date', w: 0.15 },
        { title: 'From', w: 0.18 },
        { title: 'Item', w: 0.3 },
        { title: 'What it shows (reading aid)', w: 0.37 },
      ],
      dated
        .filter((x) => x.at)
        .sort((a, b) => a.at - b.at)
        .map(({ r, at }) => [day(at), mk.mask(r.fromLabel || ''), mk.mask(headline(r)), mk.mask(r.aiSummary || '')]),
    );
    const undated = dated.filter((x) => !x.at);
    if (undated.length) {
      R.heading('Items with no date of their own', 12);
      for (const { r } of undated) R.bullet(mk.mask(headline(r)));
    }
    R.heading('Demand support index', 12);
    const byType = {};
    for (const { r } of dated) byType[r.evidenceType || r.itemKind || 'other'] = (byType[r.evidenceType || r.itemKind || 'other'] || 0) + 1;
    R.table([{ title: 'Type', w: 0.6 }, { title: 'Items', w: 0.4 }], Object.entries(byType).map(([t, n]) => [t, n]));
  }

  if (kind === 'immigration_checklist') {
    R.para('Coverage shows which items in the record mention each category. It is a finding aid for the attorney, not a judgment that any requirement is met.', { muted: true, size: 9 });
    for (const c of immigrationCoverage(receipts)) {
      R.heading(`${c.name} — ${c.items.length ? `${c.items.length} item${c.items.length === 1 ? '' : 's'}` : 'nothing found in the record'}`, 11.5);
      for (const r of c.items) R.bullet(`${mk.mask(headline(r))}${toD(r.resolvedDate) ? ` (${day(toD(r.resolvedDate))})` : ''}`);
    }
  }

  if (kind === 'civil_key_dates') {
    const keyIds = new Set(annotations.filter((a) => a.tag === 'key').map((a) => a.receiptId && a.receiptId.id));
    const rows = [];
    for (const { r, at } of dated) if (at) rows.push([at, `${keyIds.has(r._id) ? '★ ' : ''}${mk.mask(headline(r))}`, mk.mask(r.aiSummary || '')]);
    for (const h of matter.hearings || []) {
      const at = toD(h.at);
      if (at) rows.push([at, `Hearing: ${h.title || 'Hearing'}`, h.notes || '']);
    }
    rows.sort((a, b) => a[0] - b[0]);
    R.heading('Chronology');
    R.para('★ marks items the team noted as Key evidence.', { muted: true, size: 8.5 });
    R.table([{ title: 'Date', w: 0.15 }, { title: 'Event / item', w: 0.4 }, { title: 'Detail (reading aid)', w: 0.45 }], rows.map((x) => [day(x[0]), x[1], x[2]]));
  }

  if (kind === 'criminal_event_window') {
    const eventAt = toD(opts.eventAt);
    if (!eventAt) throw new HttpsError('invalid-argument', 'Give the date and time of the event.');
    const hours = Math.min(Math.max(Number(opts.windowHours) || 24, 1), 24 * 14);
    const w = inWindow(thread && thread.entries, receipts, eventAt, hours);
    R.kv('Event', `${eventAt.toISOString().slice(0, 16).replace('T', ' ')}${opts.eventLabel ? ` — ${opts.eventLabel}` : ''}`);
    R.kv('Window', `${hours} hours either side: ${w.t0.toISOString().slice(0, 16).replace('T', ' ')} to ${w.t1.toISOString().slice(0, 16).replace('T', ' ')}`);
    R.heading('Messages inside the window');
    R.table(
      [{ title: 'When', w: 0.2 }, { title: 'Who', w: 0.16 }, { title: 'Message', w: 0.5 }, { title: 'Date basis', w: 0.14 }],
      w.msgs.map(({ e, at }) => [at.toISOString().slice(0, 16).replace('T', ' '), e.person || (e.speaker === 'client' ? 'Client' : 'Other'), mk.mask(e.text), `${String(e.dateBasis || '').replace(/_/g, ' ')} ${e.dateConfidence || ''}`.trim()]),
    );
    R.heading('Items dated inside the window');
    R.table([{ title: 'Date', w: 0.2 }, { title: 'Item', w: 0.8 }], w.items.map(({ r, at }) => [day(at), mk.mask(headline(r))]));
    R.para('Times come from what each screenshot or item shows; where a time could not be read it is not placed in the window.', { muted: true, size: 8.5 });
  }

  if (kind === 'criminal_mitigation') {
    const marked = new Map();
    for (const a of annotations) {
      const id = a.receiptId && a.receiptId.id;
      if (!id) continue;
      if (!marked.has(id)) marked.set(id, []);
      marked.get(id).push(a);
    }
    const docs = receipts.filter((r) => r.isDuplicate !== true && (marked.has(r._id) || ['document', 'email'].includes(r.evidenceType || r.itemKind)));
    R.heading('Index');
    R.table(
      [{ title: '#', w: 0.06 }, { title: 'Item', w: 0.38 }, { title: 'Date', w: 0.14 }, { title: 'Team notes', w: 0.42 }],
      docs.map((r, i) => [i + 1, mk.mask(headline(r)), day(toD(r.resolvedDate)), (marked.get(r._id) || []).map((a) => `${a.tag ? `[${a.tag}] ` : ''}${mk.mask(a.text || '')}`).join('\n')]),
    );
  }

  R.para(DISCLAIMER, { muted: true, size: 8 });
  return { pdf: await R.finish(), flags: mk.count };
}

exports.exportPracticePacket = onCall({ timeoutSeconds: 300, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const data = request.data || {};
  const kind = String(data.kind || '');
  if (!KINDS[kind]) throw new HttpsError('invalid-argument', `kind must be one of ${Object.keys(KINDS).join(', ')}`);
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, data.matterId);
  const [rs, t, ann, firmSnap] = await Promise.all([
    db.collection('Receipts').where('matterId', '==', ref).get(),
    ref.collection('derived').doc('thread').get(),
    db.collection('Annotations').where('matterId', '==', ref).get(),
    db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get(),
  ]);
  const receipts = rs.docs.map((d) => ({ _id: d.id, ...d.data() }));
  const flags = masker(receipts).count;
  if (flags && data.redactionsConfirmed !== true) {
    throw new HttpsError('failed-precondition', `This matter has ${flags} suggested redaction${flags === 1 ? '' : 's'}. Review them, then confirm to export (flagged text is masked in the packet).`, { redactionFlags: flags });
  }
  const generatedAt = new Date();
  const { pdf } = await buildPacketPdf({
    kind,
    matter: snap.data() || {},
    receipts,
    thread: t.exists ? t.data() : null,
    annotations: ann.docs.map((d) => d.data()),
    opts: data,
    generatedAt,
    firmName: firmSnap.empty ? '' : firmSnap.docs[0].get('firmName') || '',
  });
  const md = snap.data() || {};
  const fileName = `${slug(md.matterName || md.caseTitle || ref.id)}-${kind.replace(/_/g, '-')}-${stampOf(generatedAt)}.pdf`;
  const storagePath = `matters/${ref.id}/exports/${fileName}`;
  const saved = await saveReport({ db, bucket: getStorage().bucket(), firmId, storagePath, bytes: pdf, contentType: 'application/pdf', fileName, uid, kind, extra: { matterId: ref.id } });
  await ref.collection('exports').add({ kind, storagePath, fileName, sha256: saved.sha256, bytes: pdf.length, generatedByUid: uid, generatedAt: generatedAt });
  return saved;
});

exports._internal = { KINDS, masker, immigrationCoverage, inWindow, buildPacketPdf };
