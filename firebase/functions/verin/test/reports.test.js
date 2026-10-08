const test = require('node:test');
const assert = require('node:assert');
const zlib = require('zlib');

const D = 86400000;
const now = new Date('2026-10-08T12:00:00Z');
const rec = (o) => ({ receivedAt: new Date(now - (o.agoDays || 1) * D), resolvedDate: o.dated === false ? null : new Date(now - (o.agoDays || 1) * D - (o.lag || 0) * D), content: o.title || 'Item', classificationLabel: o.label || 'Processed', channel: 'SMS', channelKey: 'sms', item_hash: o.hash || Math.random().toString(16).slice(2), ...o });

test('metrics: Record Lag ignores duplicates and undated items', () => {
  const M = require('../reports/metrics');
  const lags = M.recordLagDays([rec({ lag: 10 }), rec({ lag: 20 }), rec({ lag: 99, isDuplicate: true }), rec({ dated: false })]);
  assert.deepStrictEqual(lags, [10, 20]);
  assert.strictEqual(M.median(lags), 15);
  assert.strictEqual(M.latestArriving([rec({ lag: 3, title: 'a' }), rec({ lag: 40, title: 'b' })]).content, 'b');
});

test('Record Lag Audit renders with headline, matter table and appendix', async () => {
  const { buildLagAuditPdf, auditFigures } = require('../reports/lag_audit')._internal;
  const matters = [{ id: 'm1', data: { matterName: 'Reyes v. Reyes' }, receipts: [rec({ lag: 5 }), rec({ lag: 45 }), rec({ dated: false })] }];
  const f = auditFigures(matters);
  assert.strictEqual(f.medianDays, 25);
  assert.strictEqual(f.undated, 1);
  assert.strictEqual(f.over30Share, 50);
  const { pdf } = await buildLagAuditPdf({ firmName: 'Doe Family Law', matters, generatedAt: now, baseline: { medianDays: 218, method: 'test' } });
  assert.ok(pdf.slice(0, 5).toString() === '%PDF-' && pdf.length > 3000);
});

test('packets: masks flagged values and covers immigration categories', async () => {
  const { masker, immigrationCoverage, buildPacketPdf, inWindow } = require('../reports/packets')._internal;
  const receipts = [
    rec({ _id: 'a', title: 'Passport scan', sensitive: [{ text: 'X1234567', category: 'account' }], aiSummary: 'Passport X1234567' }),
    rec({ _id: 'b', title: 'Joint lease 2025', aiSummary: 'Lease for both spouses' }),
  ];
  const mk = masker(receipts);
  assert.strictEqual(mk.count, 1);
  assert.ok(!mk.mask('Passport X1234567').includes('X1234567'));
  const cov = immigrationCoverage(receipts);
  assert.strictEqual(cov.find((c) => c.name.startsWith('Identity')).items.length, 1);
  assert.strictEqual(cov.find((c) => c.name === 'Residence').items.length, 1);
  const w = inWindow([{ kind: 'msg', date: '2026-10-07', time: '22:15', text: 'hi' }, { kind: 'msg', date: '2026-09-01', time: '10:00', text: 'old' }], receipts, new Date('2026-10-07T22:00:00'), 2);
  assert.strictEqual(w.msgs.length, 1);
  for (const kind of ['pi_treatment_chronology', 'immigration_checklist', 'civil_key_dates', 'criminal_mitigation']) {
    const { pdf } = await buildPacketPdf({ kind, matter: { matterName: 'M', hearings: [{ at: new Date(now.getTime() + 5 * D), title: 'Hearing' }] }, receipts, thread: { entries: [] }, annotations: [{ tag: 'key', receiptId: { id: 'a' }, text: 'Important' }], opts: {}, generatedAt: now, firmName: 'F' });
    assert.ok(pdf.length > 2000, kind);
  }
  const { pdf } = await buildPacketPdf({ kind: 'criminal_event_window', matter: { matterName: 'M' }, receipts, thread: { entries: [] }, annotations: [], opts: { eventAt: '2026-10-07T22:00:00Z', windowHours: 6 }, generatedAt: now, firmName: 'F' });
  assert.ok(pdf.length > 2000);
});

test('weekly digest figures and PDF', async () => {
  const { digestFigures, buildDigestPdf } = require('../reports/digest')._internal;
  const f = digestFigures({ matter: { hearings: [{ at: new Date(now.getTime() + 3 * D), title: 'Pretrial' }] }, receipts: [rec({ agoDays: 2, lag: 4 }), rec({ agoDays: 20, lag: 50, label: 'Uncertain' })], followUps: [{ status: 'sent', title: 'Send the school email' }], now });
  assert.strictEqual(f.recent.length, 1);
  assert.strictEqual(f.review.length, 1);
  assert.strictEqual(f.upcoming.length, 1);
  assert.strictEqual(f.openRequests.length, 1);
  const pdf = await buildDigestPdf({ matter: { matterName: 'Reyes' }, figures: f, generatedAt: now });
  assert.ok(pdf.length > 2000);
});

test('monthly firm figures: prior month, by practice, quiet matters, failures', async () => {
  const { monthBounds, monthFigures, buildMonthlyPdf } = require('../reports/firm_report')._internal;
  const b = monthBounds(2026, 8); // September 2026
  const inSep = (lag) => ({ receivedAt: new Date('2026-09-15T00:00:00Z'), resolvedDate: new Date(Date.parse('2026-09-15T00:00:00Z') - lag * D) });
  const inAug = (lag) => ({ receivedAt: new Date('2026-08-15T00:00:00Z'), resolvedDate: new Date(Date.parse('2026-08-15T00:00:00Z') - lag * D) });
  const f = monthFigures({
    matters: [{ id: 'a', data: { matterName: 'A', practiceArea: 'Child custody' } }, { id: 'b', data: { matterName: 'B', practiceArea: 'Civil' } }],
    receiptsByMatter: { a: [inSep(10), inSep(20), inAug(40)], b: [] },
    syncLog: [{ status: 'Failed', pushedAt: new Date('2026-09-20T00:00:00Z'), documentName: 'x.pdf', error: 'timeout' }],
    deliveries: [],
    baseline: { medianDays: 218 },
    ...b,
    now: new Date('2026-10-01T00:00:00Z'),
  });
  assert.strictEqual(f.median, 15);
  assert.strictEqual(f.prevMedian, 40);
  assert.strictEqual(f.byPractice.length, 1);
  assert.deepStrictEqual(f.quiet.map((q) => q.name), ['B']);
  assert.strictEqual(f.failures.length, 1);
  const pdf = await buildMonthlyPdf({ firmName: 'F', f, start: b.start, generatedAt: now });
  assert.ok(pdf.length > 2000);
});

test('Standing Record Word export is a real .docx', async () => {
  const { buildStandingDocx } = require('../reports/standing_docx')._internal;
  const buf = await buildStandingDocx({
    matter: { matterName: 'Reyes v. Reyes', clientName: 'Dana', chainHeadHash: 'ab' },
    receipts: [rec({ _id: 'r1', lag: 3 })],
    thread: { entries: [{ kind: 'msg', rid: 'r1', date: '2026-10-01', time: '10:00', text: 'hello', speaker: 'other' }, { kind: 'gap' }], stats: { messages: 1, gaps: 1 }, notes: ['Check a date'] },
    followUps: [],
    chain: [],
    generatedAt: now,
  });
  assert.strictEqual(buf.slice(0, 2).toString(), 'PK');
  const JSZip = require('jszip');
  const z = await JSZip.loadAsync(buf);
  const xml = await z.file('word/document.xml').async('string');
  assert.match(xml, /Reyes v\. Reyes/);
  assert.match(xml, /continuity not established/);
});

test('cost to serve: per active matter from the four levers', () => {
  const { costFigures } = require('../reports/demo_ops')._internal;
  const c = costFigures({
    receipts: [
      { ...rec({ agoDays: 1 }), matterId: { id: 'a' }, ai: { usage: { inputTokens: 1e6, outputTokens: 0 } }, sizeBytes: 1e9 },
      { ...rec({ agoDays: 2 }), matterId: { id: 'b' }, channelKey: 'email' },
      { ...rec({ agoDays: 30 }), matterId: { id: 'c' } },
    ],
    aiUsage: [],
    now,
  });
  assert.strictEqual(c.activeMatters, 2);
  assert.strictEqual(c.levers.ai, 3);
  assert.strictEqual(c.sms, 1);
  assert.strictEqual(c.emails, 1);
  assert.ok(c.perActiveMatter > 1.5);
});
