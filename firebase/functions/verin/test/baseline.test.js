const test = require('node:test');
const assert = require('node:assert');
const { summarize, clioPairs } = require('../baseline/record_lag')._internal;

test('summarize gives median and 75th percentile in days', () => {
  const D = 86400000;
  const s = summarize([1, 2, 3, 10].map((d) => ({ fromMs: 0, toMs: d * D })));
  assert.strictEqual(s.medianDays, 2.5);
  assert.strictEqual(s.p75Days, 4.8);
  assert.strictEqual(s.sample, 4);
  assert.strictEqual(summarize([{ fromMs: 5, toMs: 1 }]).sample, 0);
});

test('Clio documents uploaded the moment they were received do not count', () => {
  const { pairs, undated } = clioPairs([
    { created_at: '2026-03-10T00:00:00Z', received_at: '2026-03-01T00:00:00Z' },
    { created_at: '2026-03-10T00:00:00Z', received_at: '2026-03-10T00:00:00Z' },
    { created_at: '2026-03-10T00:00:00Z' },
  ]);
  assert.strictEqual(pairs.length, 1);
  assert.strictEqual(undated, 2);
});
