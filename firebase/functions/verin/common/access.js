// Verin Legal — who may act on which matter.
//
// Every user belongs to exactly one firm: users/{uid}.firmID, written only
// by the setupAccount function (security rules stop clients from setting it
// or their own role). Every matter carries the firmID it was opened under,
// and a user may only touch matters of their own firm.

const { HttpsError } = require('firebase-functions/v2/https');

const ADMIN_ROLES = ['admin', 'owner', 'administrator'];

function requireAuth(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  return request.auth.uid;
}

function isAdminRole(role) {
  return ADMIN_ROLES.includes(String(role || '').trim().toLowerCase());
}

async function userAccess(db, uid) {
  const snap = await db.collection('users').doc(uid).get();
  const v = snap.exists ? snap.get('firmID') : null;
  const firmId = typeof v === 'string' ? v.trim() : '';
  const role = snap.exists ? String(snap.get('role') || '') : '';
  return { firmId, role, isAdmin: isAdminRole(role) };
}

// The caller's firm. The legacy third argument (a default firm) is ignored:
// an account without a firm has to finish setup, never borrow someone's.
async function firmIdForUser(db, uid) {
  const { firmId } = await userAccess(db, uid);
  if (!firmId) {
    throw new HttpsError('failed-precondition', 'Your account is not attached to a firm yet. Sign out and sign in again to finish setup.');
  }
  return firmId;
}

async function requireAdmin(db, uid) {
  const a = await userAccess(db, uid);
  if (!a.firmId) throw new HttpsError('failed-precondition', 'Your account is not attached to a firm yet.');
  if (!a.isAdmin) throw new HttpsError('permission-denied', 'Only a firm admin can do this.');
  return a;
}

function assertDocId(id, name = 'id') {
  if (typeof id !== 'string' || !id || id.includes('/') || id.length > 200) {
    throw new HttpsError('invalid-argument', `${name} is required`);
  }
}

async function loadMatterForUser(db, uid, matterId) {
  assertDocId(matterId, 'matterId');
  const ref = db.collection('Matters').doc(matterId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Matter not found');
  const firmId = await firmIdForUser(db, uid);
  if (snap.get('firmID') !== firmId) {
    // Same answer as a missing matter: don't reveal other firms' matter ids.
    throw new HttpsError('not-found', 'Matter not found');
  }
  return { ref, snap, firmId };
}

module.exports = { requireAuth, isAdminRole, userAccess, firmIdForUser, requireAdmin, loadMatterForUser, assertDocId };
