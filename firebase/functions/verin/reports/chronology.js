// Verin Legal — the chronology as a PDF.
//
// The chronology used to leave the app as a CSV for Excel. Every other thing
// Verin hands a firm is a branded PDF, and a spreadsheet of the record reads
// like working notes rather than something to file or send on. Same builder,
// same header and watermark as the packets and the audit.
//
// Each line cites the exhibit it was read from; gaps are printed as gaps
// rather than closed over.

const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { requireAuth, loadMatterForUser } = require('../common/access');
const M = require('./metrics');
const { createReport, DISCLAIMER, day } = require('./pdf');
const { saveReport, stampOf, slug } = require('./store');

const headline = (r) => String(r.content || r.description || r.originalFileName || 'Item').split('\n')[0].slice(0, 140);

/// Exhibit numbers follow the order items were received, so they match the
/// Standing Record and the exhibit set.
function exhibitOrder(receipts) {
  const order = new Map();
  receipts
    .slice()
    .sort((a, b) => {
      const x = M.toDate(a.receivedAt);
      const y = M.toDate(b.receivedAt);
      return (x ? x.getTime() : 0) - (y ? y.getTime() : 0);
    })
    .forEach((r, i) => order.set(r._id, i + 1));
  return order;
}

function buildChronologyPdfDoc({ matter, receipts, thread, corrections, generatedAt, firmName }) {
  const title = matter.matterName || matter.caseTitle || 'Matter';
  const order = exhibitOrder(receipts);
  const R = createReport({
    title: 'Chronology',
    subtitle: `${title}${matter.caseNumber ? ` · ${matter.caseNumber}` : ''}`,
    kicker: 'VERIN · CHRONOLOGY',
    footer: `Verin Chronology · ${title} · generated ${generatedAt.toISOString()}`,
    stamp: { when: generatedAt, label: 'CHRONOLOGY' },
  });

  R.kv('Client', matter.clientName);
  R.kv('Prepared for', firmName);
  R.kv('Items in the record', String(receipts.length));
  R.kv('Generated', generatedAt.toISOString());

  const entries = ((thread && thread.entries) || []).filter((e) => e.kind === 'msg' || e.kind === 'gap');

  R.heading('Chronology');
  R.para('Each line cites the exhibit it was read from. The originals are the record; this text is a reading aid.', { muted: true, size: 8.5 });
  R.table(
    [
      { title: 'Date', w: 0.13 },
      { title: 'Time', w: 0.09 },
      { title: 'Who', w: 0.16 },
      { title: 'Message', w: 0.52 },
      { title: 'Exhibit', w: 0.1 },
    ],
    entries.map((e) =>
      e.kind === 'gap'
        // Blank cells print as em-dashes, which reads like missing data rather
        // than a deliberate break; a space leaves the rest of the row quiet.
        ? [' ', ' ', ' ', '— continuity not established here —', ' ']
        : [
            e.date || 'undated',
            e.time || e.timeOnly || '',
            e.person || (e.speaker === 'client' ? 'Client' : 'Other'),
            e.text || '',
            e.rid && order.get(e.rid) ? `#${order.get(e.rid)}` : '',
          ],
    ),
  );

  const notes = (corrections || []).filter((c) => c && (c.note || c.text));
  if (notes.length) {
    R.heading('Reviewer notes', 12);
    for (const c of notes) R.bullet(`${c.field ? `${c.field}: ` : ''}${c.note || c.text}`);
  }

  R.heading('Exhibits', 12);
  R.table(
    [
      { title: '#', w: 0.07 },
      { title: 'Received', w: 0.17 },
      { title: 'Item', w: 0.46 },
      { title: 'Item date', w: 0.3 },
    ],
    receipts
      .slice()
      .sort((a, b) => (order.get(a._id) || 0) - (order.get(b._id) || 0))
      .map((r) => [
        String(order.get(r._id) || ''),
        day(M.toDate(r.receivedAt)),
        headline(r),
        M.toDate(r.resolvedDate)
          ? `${day(M.toDate(r.resolvedDate))}${r.dateSource ? ` (${String(r.dateSource).replace(/_/g, ' ')})` : ''}`
          : 'no date in item',
      ]),
  );

  R.para(DISCLAIMER, { muted: true, size: 8 });
  return R.finish();
}

function reportable(e) {
  if (e instanceof HttpsError) return e;
  console.error('exportChronologyPdf failed', e && e.stack ? e.stack : e);
  const msg = (e && e.message ? String(e.message) : String(e)).slice(0, 300);
  return new HttpsError('internal', `The chronology could not be built: ${msg}`);
}

exports.exportChronologyPdf = onCall({ timeoutSeconds: 180, memory: '1GiB' }, async (request) => {
  try {
    return await buildAndSaveChronology(request);
  } catch (e) {
    throw reportable(e);
  }
});

async function buildAndSaveChronology(request) {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, (request.data || {}).matterId);
  const [rs, t, corr, firmSnap] = await Promise.all([
    db.collection('Receipts').where('matterId', '==', ref).get(),
    ref.collection('derived').doc('thread').get(),
    db.collection('Corrections').where('matterId', '==', ref).get().catch(() => ({ docs: [] })),
    db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get(),
  ]);
  const generatedAt = new Date();
  const matter = snap.data() || {};
  const bytes = await buildChronologyPdfDoc({
    matter,
    receipts: rs.docs.map((d) => ({ _id: d.id, ...d.data() })),
    thread: t.exists ? t.data() : null,
    corrections: (corr.docs || []).map((d) => d.data()),
    generatedAt,
    firmName: firmSnap.empty ? '' : firmSnap.docs[0].get('firmName') || '',
  });
  const fileName = `${slug(matter.matterName || ref.id)}-chronology-${stampOf(generatedAt)}.pdf`;
  const saved = await saveReport({
    db,
    bucket: getStorage().bucket(),
    firmId,
    storagePath: `matters/${ref.id}/exports/${fileName}`,
    bytes,
    contentType: 'application/pdf',
    fileName,
    uid,
    kind: 'chronology_pdf',
    extra: { matterId: ref.id },
  });
  await ref.collection('exports').add({
    kind: 'chronology_pdf',
    storagePath: saved.storagePath,
    fileName,
    sha256: saved.sha256,
    bytes: bytes.length,
    generatedByUid: uid,
    generatedAt,
  });
  return saved;
}

exports._internal = { buildChronologyPdfDoc, exhibitOrder };
