// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const chain = require('../chain/chain');

const sha = (s) => crypto.createHash('sha256').update(s).digest('hex');

function build(n, { startPrev = chain.GENESIS } = {}) {
  const out = [];
  let prev = startPrev;
  for (let i = 1; i <= n; i++) {
    const e = {
      seq: i,
      prevHash: prev,
      itemHash: sha(`item-${i}`),
      receivedAtIso: new Date(Date.UTC(2026, 9, i, 12)).toISOString(),
      originDigest: chain.originDigest({ channel: 'Upload', source: `uid:u|file:${i}.png` }),
    };
    e.entryHash = chain.computeEntryHash({ prevHash: e.prevHash, itemHash: e.itemHash, receivedAtIso: e.receivedAtIso, originDigest: e.originDigest });
    prev = e.entryHash;
    out.push(e);
  }
  return out;
}

test('entry hash matches the documented formula exactly', () => {
  const prev = chain.GENESIS;
  const item = sha('bytes');
  const at = '2026-10-03T17:20:11.123Z';
  const od = sha('{"channel":"Upload","source":"uid:u|file:a.png"}');
  assert.equal(chain.originDigest({ source: 'uid:u|file:a.png', channel: 'Upload' }), od, 'keys are sorted, no whitespace');
  assert.equal(chain.computeEntryHash({ prevHash: prev, itemHash: item, receivedAtIso: at, originDigest: od }), sha(`${prev}|${item}|${at}|${od}`));
});

test('an intact chain verifies and reports its head', () => {
  const entries = build(5);
  const r = chain.verifyEntries(entries.slice().reverse());
  assert.equal(r.ok, true);
  assert.equal(r.verified, 5);
  assert.equal(r.head, entries[4].entryHash);
});

test('editing any input breaks the chain at that entry', () => {
  const entries = build(5);
  entries[2].itemHash = sha('swapped evidence');
  const r = chain.verifyEntries(entries);
  assert.equal(r.ok, false);
  assert.equal(r.brokenAt, 3);
});

test('deleting an entry is detected', () => {
  const entries = build(5);
  entries.splice(2, 1);
  const r = chain.verifyEntries(entries);
  assert.equal(r.ok, false);
  assert.equal(r.brokenAt, 4);
});

test('legacy seeded rows without inputs are skipped, not called broken', () => {
  const legacy = [{ seq: 1, entryHash: 'abc' }, { seq: 2, entryHash: 'def' }];
  const real = build(2, { startPrev: 'def' }).map((e) => ({ ...e, seq: e.seq + 2 }));
  // recompute with shifted seq (seq isn't part of the hash)
  const r = chain.verifyEntries([...legacy, ...real]);
  assert.equal(r.ok, true);
  assert.equal(r.legacy, 2);
  assert.equal(r.verified, 2);
});

// Fake Firestore transaction to exercise appendInTransaction.
function fakeDb(matter, lastEntry) {
  const writes = [];
  const matterRef = { id: 'm1', path: 'Matters/m1' };
  const db = {
    collection: (name) => ({
      doc: () => ({ id: `${name}-new`, path: `${name}/new` }),
      where: () => ({ orderBy: () => ({ limit: () => ({ __q: true }) }) }),
    }),
  };
  const tx = {
    get: async (ref) => {
      if (ref === matterRef) return { exists: !!matter, get: (k) => (matter || {})[k] };
      return { empty: !lastEntry, docs: lastEntry ? [{ get: (k) => lastEntry[k] }] : [] };
    },
    set: (ref, data, opts) => writes.push({ ref, data, opts }),
  };
  return { db, tx, matterRef, writes };
}

test('first append on a new matter is the chain root (seq 1, genesis prev)', async () => {
  const { db, tx, matterRef, writes } = fakeDb({}, null);
  const r = await chain.appendInTransaction(tx, db, {
    matterRef, receiptRef: { id: 'r1' }, itemHash: sha('a'), receivedAt: new Date('2026-10-03T00:00:00Z'),
    channel: 'Upload', source: 's', serverTimestamp: () => 'TS',
  });
  assert.equal(r.isRoot, true);
  assert.equal(r.entry.seq, 1);
  assert.equal(r.entry.prevHash, chain.GENESIS);
  const matterWrite = writes.find((w) => w.ref === matterRef);
  assert.deepEqual(matterWrite.data, { chainHeadHash: r.entry.entryHash, chainLength: 1, hasChainRoot: true });
});

test('append continues from the head stored on the matter', async () => {
  const { db, tx, matterRef } = fakeDb({ chainHeadHash: 'h5', chainLength: 5 }, null);
  const r = await chain.appendInTransaction(tx, db, {
    matterRef, itemHash: sha('b'), receivedAt: Date.now(), channel: 'Upload', source: 's', serverTimestamp: () => 'TS',
  });
  assert.equal(r.entry.seq, 6);
  assert.equal(r.entry.prevHash, 'h5');
});

test('append picks up existing seeded entries when the matter has no head yet', async () => {
  const { db, tx, matterRef } = fakeDb({}, { seq: 4, entryHash: 'seeded4' });
  const r = await chain.appendInTransaction(tx, db, {
    matterRef, itemHash: sha('c'), receivedAt: Date.now(), channel: 'Upload', source: 's', serverTimestamp: () => 'TS',
  });
  assert.equal(r.entry.seq, 5);
  assert.equal(r.entry.prevHash, 'seeded4');
});
