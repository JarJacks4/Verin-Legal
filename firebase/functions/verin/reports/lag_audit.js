// Verin Legal — Record Lag Audit report (C1, checklist #67).
//
// For a set of (usually closed) matters: the headline median Record Lag,
// three supporting figures, a matter table, the latest-arriving item, the
// method, and every item listed in an appendix.

const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { requireAuth, userAccess } = require('../common/access');
const M = require('./metrics');
const { createReport, DISCLAIMER, day } = require('./pdf');
const { saveReport, stampOf, slug } = require('./store');

const titleOf = (m) => m.matterName || m.caseTitle || 'Matter';
const headline = (r) => String(r.content || r.description || r.originalFileName || 'Item').split('\n')[0].slice(0, 120);

/// Pure: matters [{ id, data, receipts:[data] }] → figures used by the PDF.
function auditFigures(matters) {
  const all = matters.flatMap((m) => m.receipts.map((r) => ({ ...r, _matter: titleOf(m.data) })));
  const lags = M.recordLagDays(all);
  const undated = all.filter((r) => r.isDuplicate !== true && !r.resolvedDate).length;
  const over30 = lags.filter((d) => d > 30).length;
  const rows = matters.map((m) => {
    const l = M.recordLagDays(m.receipts);
    return { matter: titleOf(m.data), items: m.receipts.length, dated: l.length, median: M.median(l), longest: l.length ? l[l.length - 1] : null };
  });
  return {
    items: all.length,
    datedItems: lags.length,
    medianDays: M.median(lags),
    p75Days: M.percentile(lags, 0.75),
    over30Share: lags.length ? Math.round((over30 / lags.length) * 100) : null,
    undated,
    rows,
    latest: M.latestArriving(all),
    all,
  };
}

async function buildLagAuditPdf({ firmName, matters, generatedAt, generatedBy, baseline }) {
  const f = auditFigures(matters);
  const R = createReport({
    title: 'Record Lag Audit',
    subtitle: `${firmName || 'Your firm'} · ${matters.length} matter${matters.length === 1 ? '' : 's'} · ${day(generatedAt)}`,
    footer: `Verin Record Lag Audit · ${firmName || ''} · generated ${generatedAt.toISOString()}`,
  });
  R.label('Headline');
  R.para(
    f.medianDays === null
      ? 'No item in these matters carries a date of its own, so Record Lag could not be measured.'
      : `Half of the dated material in these matters reached the firm ${f.medianDays} day${f.medianDays === 1 ? '' : 's'} or more after it was created.`,
    { size: 12.5 },
  );
  R.tiles([
    { label: 'Median Record Lag', value: f.medianDays === null ? '—' : `${f.medianDays} d`, note: `${f.datedItems} dated items` },
    { label: '1 in 4 items', value: f.p75Days === null ? '—' : `${f.p75Days}+ d`, note: '75th percentile' },
    { label: 'Arrived 30+ days late', value: f.over30Share === null ? '—' : `${f.over30Share}%`, note: 'of dated items' },
    { label: 'No date in the item', value: String(f.undated), note: 'not counted above' },
  ]);
  if (baseline && baseline.medianDays !== null && baseline.medianDays !== undefined) {
    R.para(`For comparison, the firm's baseline captured when it connected its practice management system is ${baseline.medianDays} days (${baseline.method || 'method recorded with the baseline'}).`, { muted: true, size: 9 });
  }

  R.heading('By matter');
  R.table(
    [
      { title: 'Matter', w: 0.4 },
      { title: 'Items', w: 0.12 },
      { title: 'Dated', w: 0.12 },
      { title: 'Median lag', w: 0.18 },
      { title: 'Longest', w: 0.18 },
    ],
    f.rows.map((r) => [r.matter, r.items, r.dated, r.median === null ? '—' : `${r.median} d`, r.longest === null ? '—' : `${r.longest} d`]),
  );

  R.heading('Latest-arriving item');
  if (f.latest) {
    R.kv('Matter', f.latest._matter);
    R.kv('Item', headline(f.latest));
    R.kv('Dated', day(M.toDate(f.latest.resolvedDate)));
    R.kv('Reached the firm', day(M.toDate(f.latest.receivedAt)));
    R.kv('Record Lag', `${f.latest.lagDays} days`);
  } else {
    R.para('No dated items.', { muted: true });
  }

  R.heading('Method');
  R.para(
    "Record Lag is the number of days between the date an item carries itself (the date on a screenshot's messages, a document's date, an email's sent date) and the day it reached the firm through Verin. Each item's date and where it came from are shown in the appendix. Exact duplicates are counted once. Items with no date of their own are listed but not counted. The median is the middle value: half the items took longer.",
    { size: 9.5 },
  );
  R.para(DISCLAIMER, { muted: true, size: 8 });

  R.newPage();
  R.heading('Appendix — every item');
  R.table(
    [
      { title: 'Matter', w: 0.2 },
      { title: 'Item', w: 0.3 },
      { title: 'Item date (source)', w: 0.2 },
      { title: 'Received', w: 0.16 },
      { title: 'Lag', w: 0.14 },
    ],
    f.all
      .slice()
      .sort((a, b) => (M.toDate(a.receivedAt) || 0) - (M.toDate(b.receivedAt) || 0))
      .map((r) => {
        const d = M.toDate(r.resolvedDate);
        const rec = M.toDate(r.receivedAt);
        const lag = d && rec ? Math.round((rec - d) / M.DAY) : null;
        return [
          r._matter,
          `${headline(r)}${r.isDuplicate ? ' (duplicate)' : ''}`,
          d ? `${day(d)}${r.dateSource ? ` (${String(r.dateSource).replace(/_/g, ' ')})` : ''}` : 'no date in item',
          day(rec),
          lag === null || lag < 0 ? '—' : `${lag} d`,
        ];
      }),
    { size: 7.5 },
  );
  return { pdf: await R.finish(), figures: f };
}

exports.exportRecordLagAudit = onCall({ timeoutSeconds: 300, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { firmId } = await userAccess(db, uid);
  if (!firmId) throw new HttpsError('failed-precondition', 'Your account is not attached to a firm yet.');
  const ids = Array.isArray((request.data || {}).matterIds) ? request.data.matterIds.slice(0, 25).map(String) : [];
  if (!ids.length) throw new HttpsError('invalid-argument', 'Choose at least one matter.');
  const matters = [];
  for (const id of ids) {
    const snap = await db.collection('Matters').doc(id).get();
    if (!snap.exists || snap.get('firmID') !== firmId) continue;
    const rs = await db.collection('Receipts').where('matterId', '==', snap.ref).get();
    matters.push({ id, data: snap.data(), receipts: rs.docs.map((d) => d.data()) });
  }
  if (!matters.length) throw new HttpsError('not-found', 'None of those matters were found.');
  const firmSnap = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  const firm = firmSnap.empty ? {} : firmSnap.docs[0].data();
  const generatedAt = new Date();
  const { pdf, figures } = await buildLagAuditPdf({ firmName: firm.firmName, matters, generatedAt, generatedBy: uid, baseline: firm.baselineRecordLag });
  const fileName = `record-lag-audit-${stampOf(generatedAt)}.pdf`;
  const saved = await saveReport({ db, bucket: getStorage().bucket(), firmId, storagePath: `exports/${slug(firmId)}/reports/${fileName}`, bytes: pdf, contentType: 'application/pdf', fileName, uid, kind: 'record_lag_audit', extra: { matterIds: matters.map((m) => m.id), medianDays: figures.medianDays } });
  return { ...saved, medianDays: figures.medianDays, items: figures.items };
});

exports._internal = { auditFigures, buildLagAuditPdf };
