// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('module');

// FieldValue.serverTimestamp() needs no live Firestore; stub the module.
const realLoad = Module._load;
Module._load = function (req, parent, isMain) {
  if (req === 'firebase-admin/firestore') {
    return { getFirestore: () => null, FieldValue: { serverTimestamp: () => ({ _sentinel: true }) }, Timestamp: { now: () => new Date() } };
  }
  return realLoad.apply(this, arguments);
};
const { rebuildMatter } = require('../thread/rebuild');
Module._load = realLoad;
const { FakeDb } = require('./fakeDb');

const msg = (speaker, text, extra = {}) => ({ speaker, text, timestampLabel: '', isGap: false, confidence: 0.95, isHeader: false, ...extra });

test('rebuildMatter writes the thread, one update per arrival, resolves answered follow-ups, logs activity', async () => {
  const db = new FakeDb();
  const matter = db.doc('Matters/m1');
  await matter.set({ firmID: 'f_1', title: 'Doe' });
  const put = (id, at, msgs, extra = {}) =>
    db.doc(`Receipts/${id}`).set({ matterId: matter, firmID: 'f_1', receivedAt: new Date(at), threadMessages: msgs, extractionState: 'extracted', ...extra });
  await put('A', '2026-03-10T10:00:00Z', [{ ...msg('other', 'Mar 9, 2026'), isHeader: true, timestampLabel: 'Mar 9, 2026' }, msg('other', 'You are late again tonight'), msg('client', 'Traffic')]);
  await rebuildMatter(db, matter, { arrivedId: 'A' });
  await put('C', '2026-03-10T12:00:00Z', [msg('other', 'New schedule starts this week'), msg('client', 'Fine by me')]);
  await rebuildMatter(db, matter, { arrivedId: 'C' });

  let thread = (await matter.collection('derived').doc('thread').get()).data();
  assert.equal(thread.firmID, 'f_1');
  assert.equal(thread.gaps.length, 1);
  const gapKey = thread.gaps[0].key;
  assert.ok(thread.suggestions.some((s) => s.key === gapKey));

  // Staff sent the gap request.
  await db.doc('FollowUps/x').set({ matterId: matter, firmID: 'f_1', key: gapKey, status: 'sent' });

  // The client sends the bridging screenshot.
  await put('B', '2026-03-11T09:00:00Z', [msg('other', 'You are late again tonight'), msg('client', 'Traffic'), msg('other', 'New schedule starts this week'), msg('client', 'Fine by me')]);
  await rebuildMatter(db, matter, { arrivedId: 'B' });
  thread = (await matter.collection('derived').doc('thread').get()).data();
  assert.equal(thread.gaps.length, 0);
  assert.equal((await db.doc('FollowUps/x').get()).data().status, 'resolved');

  const upd = (await matter.collection('updates').doc('B').get()).data();
  assert.ok(upd.kinds.includes('fills_gap'));
  assert.equal(upd.firmID, 'f_1');

  // Classified once: a second pass for the same item doesn't overwrite it.
  await rebuildMatter(db, matter, { arrivedId: 'B' });
  assert.deepEqual((await matter.collection('updates').doc('B').get()).data().kinds, upd.kinds);

  const act = (await db.doc('Activity/read_B').get()).data();
  assert.equal(act.type, 'read');
  assert.equal(act.messages, 4);
});
