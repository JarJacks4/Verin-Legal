// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const access = require('../common/access');
const { inviteIsOpen } = require('../account/setup');

// Minimal stand-in for the Admin SDK's Firestore: collection(name).doc(id).get().
function fakeDb(data) {
  return {
    collection: (c) => ({
      doc: (id) => ({
        id,
        path: `${c}/${id}`,
        get: async () => {
          const d = (data[c] || {})[id];
          return { exists: !!d, get: (k) => (d ? d[k] : undefined) };
        },
      }),
    }),
  };
}

const db = fakeDb({
  users: {
    a: { firmID: 'f_one', role: 'Paralegal' },
    b: { firmID: 'f_two', role: 'Admin' },
    nofirm: { role: 'Attorney' },
  },
  Matters: {
    m1: { firmID: 'f_one', title: 'One' },
    legacy: { title: 'No firm' },
  },
});

test('a user can open a matter of their own firm', async () => {
  const r = await access.loadMatterForUser(db, 'a', 'm1');
  assert.equal(r.firmId, 'f_one');
});

test('another firm\'s matter looks like it does not exist', async () => {
  await assert.rejects(access.loadMatterForUser(db, 'b', 'm1'), (e) => e.code === 'not-found');
});

test('a matter without a firm is not open to anyone', async () => {
  await assert.rejects(access.loadMatterForUser(db, 'a', 'legacy'), (e) => e.code === 'not-found');
});

test('an account without a firm never falls back to a default firm', async () => {
  await assert.rejects(access.firmIdForUser(db, 'nofirm', 'harbow-law'), (e) => e.code === 'failed-precondition');
  await assert.rejects(access.loadMatterForUser(db, 'nofirm', 'm1'), (e) => e.code === 'failed-precondition');
});

test('only admins pass requireAdmin', async () => {
  await assert.rejects(access.requireAdmin(db, 'a'), (e) => e.code === 'permission-denied');
  const r = await access.requireAdmin(db, 'b');
  assert.equal(r.firmId, 'f_two');
});

test('admin roles', () => {
  for (const r of ['Admin', 'admin', ' Owner ', 'Administrator']) assert.equal(access.isAdminRole(r), true, r);
  for (const r of ['Paralegal', 'Attorney', '', 'Case Manager', 'administratorx']) assert.equal(access.isAdminRole(r), false, r);
});

function snap(d) {
  return { exists: true, get: (k) => d[k] };
}
const later = { toMillis: () => Date.now() + 60000 };
const earlier = { toMillis: () => Date.now() - 60000 };

test('invitations: open only for the invited email, unexpired, with a firm', () => {
  const ok = { status: 'invited', firmID: 'f_one', email: 'Jane@Firm.com', expiresAt: later };
  assert.equal(inviteIsOpen(snap(ok), 'jane@firm.com', Date.now()), true);
  assert.equal(inviteIsOpen(snap(ok), 'other@firm.com', Date.now()), false);
  assert.equal(inviteIsOpen(snap({ ...ok, expiresAt: earlier }), 'jane@firm.com', Date.now()), false);
  assert.equal(inviteIsOpen(snap({ ...ok, status: 'active' }), 'jane@firm.com', Date.now()), false);
  assert.equal(inviteIsOpen(snap({ ...ok, firmID: '' }), 'jane@firm.com', Date.now()), false);
  assert.equal(inviteIsOpen({ exists: false }, 'jane@firm.com', Date.now()), false);
});
