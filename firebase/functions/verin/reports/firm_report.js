// Verin Legal — monthly firm Record Lag and activity report (F1, checklist #74).
//
// Firm median Record Lag for the month against the prior month and the
// firm's baseline, by practice area, plus quiet matters (open, nothing new in
// 30 days) and write-back failures. Built on the 1st for the month before,
// or on demand by an admin.

const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { requireAuth, requireAdmin } = require('../common/access');
const M = require('./metrics');
const { createReport, DISCLAIMER, day } = require('./pdf');
const { saveReport, slug } = require('./store');

function monthBounds(year, month) {
  const start = new Date(Date.UTC(year, month, 1));
  const end = new Date(Date.UTC(year, month + 1, 1));
  const prevStart = new Date(Date.UTC(year, month - 1, 1));
  return { start, end, prevStart };
}

const inRange = (r, a, b) => {
  const t = M.toDate(r.receivedAt);
  return t && t >= a && t < b;
};

/// Pure: figures for one month.
function monthFigures({ matters, receiptsByMatter, syncLog, deliveries, baseline, start, end, prevStart, now = new Date() }) {
  const all = [];
  for (const m of matters) for (const r of receiptsByMatter[m.id] || []) all.push({ ...r, _practice: m.data.practiceArea || m.data.matterType || 'Unspecified' });
  const thisMonth = all.filter((r) => inRange(r, start, end));
  const prev = all.filter((r) => inRange(r, prevStart, start));
  const byPractice = {};
  for (const r of thisMonth) (byPractice[r._practice] = byPractice[r._practice] || []).push(r);
  const quiet = matters
    .filter((m) => String(m.data.status || 'Open') !== 'Closed')
    .map((m) => {
      const last = (receiptsByMatter[m.id] || []).map((r) => M.toDate(r.receivedAt)).filter(Boolean).sort((a, b) => b - a)[0] || null;
      return { name: m.data.matterName || m.data.caseTitle || m.id, last };
    })
    .filter((x) => !x.last || now - x.last > 30 * M.DAY);
  const failures = [
    ...syncLog.filter((s) => s.status === 'Failed').map((s) => ({ when: M.toDate(s.pushedAt), what: s.documentName || 'Record', error: s.error || '' })),
    ...deliveries.filter((d) => d.status === 'failed').map((d) => ({ when: M.toDate(d.createdAt), what: d.zipFileName || 'Record delivery', error: d.error || '' })),
  ].filter((x) => x.when && x.when >= start && x.when < end);
  return {
    items: thisMonth.length,
    median: M.median(M.recordLagDays(thisMonth)),
    prevMedian: M.median(M.recordLagDays(prev)),
    baseline: baseline && baseline.medianDays !== undefined ? baseline.medianDays : null,
    byPractice: Object.entries(byPractice).map(([p, rs]) => ({ practice: p, items: rs.length, median: M.median(M.recordLagDays(rs)) })),
    quiet,
    failures,
  };
}

async function buildMonthlyPdf({ firmName, f, start, generatedAt, baselineMethod }) {
  const label = start.toLocaleString('en-US', { month: 'long', year: 'numeric', timeZone: 'UTC' });
  const R = createReport({ title: 'Record Lag and activity', subtitle: `${firmName || 'Your firm'} · ${label}`, footer: `Verin monthly report · ${firmName || ''} · ${label}` });
  const d = (x) => (x === null || x === undefined ? '—' : `${x} d`);
  R.tiles([
    { label: 'Firm median', value: d(f.median), note: `${f.items} items this month` },
    { label: 'Prior month', value: d(f.prevMedian), note: f.median !== null && f.prevMedian !== null ? `${f.median - f.prevMedian >= 0 ? '+' : ''}${f.median - f.prevMedian} d change` : '' },
    { label: 'Your baseline', value: d(f.baseline), note: f.baseline === null ? 'not captured' : 'before Verin' },
  ]);
  if (baselineMethod) R.para(`Baseline method: ${baselineMethod}`, { muted: true, size: 8.5 });
  R.heading('By practice area');
  R.table([{ title: 'Practice', w: 0.5 }, { title: 'Items', w: 0.2 }, { title: 'Median lag', w: 0.3 }], f.byPractice.map((p) => [p.practice, p.items, d(p.median)]));
  R.heading('Quiet matters (open, nothing new in 30 days)');
  R.table([{ title: 'Matter', w: 0.65 }, { title: 'Last item', w: 0.35 }], f.quiet.map((q) => [q.name, q.last ? day(q.last) : 'nothing yet']));
  R.heading('Write-back failures');
  R.table([{ title: 'When', w: 0.2 }, { title: 'What', w: 0.35 }, { title: 'Error', w: 0.45 }], f.failures.map((x) => [day(x.when), x.what, x.error]));
  R.para(DISCLAIMER, { muted: true, size: 8 });
  return R.finish();
}

async function firmMonthly({ db, bucket, firmId, firm, year, month, uid }) {
  const { start, end, prevStart } = monthBounds(year, month);
  const ms = await db.collection('Matters').where('firmID', '==', firmId).get();
  const matters = ms.docs.map((d) => ({ id: d.id, ref: d.ref, data: d.data() }));
  const receiptsByMatter = {};
  const syncLog = [];
  const deliveries = [];
  for (const m of matters) {
    receiptsByMatter[m.id] = (await db.collection('Receipts').where('matterId', '==', m.ref).get()).docs.map((d) => d.data());
    syncLog.push(...(await db.collection('clioSyncLog').where('matterID', '==', m.ref).get()).docs.map((d) => d.data()));
    deliveries.push(...(await m.ref.collection('deliveries').get()).docs.map((d) => d.data()));
  }
  const f = monthFigures({ matters, receiptsByMatter, syncLog, deliveries, baseline: firm.baselineRecordLag, start, end, prevStart });
  const pdf = await buildMonthlyPdf({ firmName: firm.firmName, f, start, generatedAt: new Date(), baselineMethod: firm.baselineRecordLag && firm.baselineRecordLag.method });
  const fileName = `verin-monthly-${start.toISOString().slice(0, 7)}.pdf`;
  return saveReport({ db, bucket, firmId, storagePath: `exports/${slug(firmId)}/reports/${fileName}`, bytes: pdf, contentType: 'application/pdf', fileName, uid, kind: 'monthly_firm_report', extra: { month: start.toISOString().slice(0, 7), median: f.median } });
}

exports.exportFirmMonthlyReport = onCall({ timeoutSeconds: 300, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { firmId } = await requireAdmin(db, uid);
  const now = new Date();
  const ym = String((request.data || {}).month || '');
  const m = /^(\d{4})-(\d{2})$/.exec(ym);
  const year = m ? Number(m[1]) : now.getUTCMonth() === 0 ? now.getUTCFullYear() - 1 : now.getUTCFullYear();
  const month = m ? Number(m[2]) - 1 : (now.getUTCMonth() + 11) % 12;
  const fs = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  if (fs.empty) throw new HttpsError('not-found', 'Firm not found');
  return firmMonthly({ db, bucket: getStorage().bucket(), firmId, firm: fs.docs[0].data(), year, month, uid });
});

exports.monthlyFirmReports = onSchedule({ schedule: '0 6 1 * *', timeZone: 'America/Indiana/Indianapolis', timeoutSeconds: 540, memory: '1GiB' }, async () => {
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const now = new Date();
  const year = now.getUTCMonth() === 0 ? now.getUTCFullYear() - 1 : now.getUTCFullYear();
  const month = (now.getUTCMonth() + 11) % 12;
  const firms = await db.collection('firmAccount').get();
  for (const f of firms.docs) {
    const firm = f.data() || {};
    if (!firm.firmID || firm.isDemo === true) continue;
    try {
      await firmMonthly({ db, bucket, firmId: firm.firmID, firm, year, month, uid: 'system' });
    } catch (e) {
      console.error('monthly report failed', firm.firmID, e.message);
    }
  }
});

exports._internal = { monthBounds, monthFigures, buildMonthlyPdf };
