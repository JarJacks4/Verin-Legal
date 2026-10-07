const test = require('node:test');
const assert = require('node:assert');
const { buildSummaryRequest, validateSummary, cannedSummary, parseJson } = require('../thread/summary')._internal;

const entries = [
  { kind: 'header', key: 'h1', text: 'Mon' },
  { kind: 'msg', key: 'r1#1', date: '2026-09-01', time: '16:12', speaker: 'other', person: 'Marcus', text: "I'm picking Lily up at 5" },
  { kind: 'msg', key: 'r1#2', date: '2026-09-01', time: '16:13', speaker: 'client', text: 'The order says 6.' },
  { kind: 'gap', key: 'g1' },
  { kind: 'msg', key: 'r2#1', date: '2026-09-04', speaker: 'other', person: 'Marcus', text: 'Keeping her Sunday.' },
];

test('summary lines without a real citation are dropped', () => {
  const out = validateSummary(
    {
      lines: [
        { text: 'Marcus said he would pick Lily up at 5.', cites: ['r1#1', 'nope'] },
        { text: 'Uncited claim.', cites: [] },
        { text: 'Cites a header only.', cites: ['h1'] },
        { text: '', cites: ['r1#2'] },
      ],
    },
    entries,
  );
  assert.deepStrictEqual(out, [{ text: 'Marcus said he would pick Lily up at 5.', cites: ['r1#1'] }]);
});

test('request lists every message with its key', () => {
  const req = buildSummaryRequest({ model: 'm', entries, topic: 'pickup', clientName: 'Dana' });
  const body = req.messages[0].content;
  assert.ok(body.includes('[r1#1]') && body.includes('[r2#1]') && !body.includes('[h1]'));
  assert.ok(body.includes('pickup'));
});

test('demo summary cites each day it describes, and follows a topic', () => {
  const all = cannedSummary(entries, '');
  assert.strictEqual(all.length, 2);
  assert.deepStrictEqual(all[0].cites, ['r1#1', 'r1#2']);
  const sunday = cannedSummary(entries, 'sunday');
  assert.strictEqual(sunday.length, 1);
  assert.deepStrictEqual(sunday[0].cites, ['r2#1']);
});

test('parses JSON wrapped in prose', () => {
  assert.deepStrictEqual(parseJson('Here you go: {"lines":[]} done'), { lines: [] });
  assert.strictEqual(parseJson('no json'), null);
});
