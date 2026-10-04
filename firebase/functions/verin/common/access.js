// Verin Legal — who may act on which matter.
//
// The app is single-tenant today: every matter carries a hardcoded firmID
// (the Matters list filters on it) and users docs have no firm field yet.
// So a user's firm is users/{uid}.firmID if present, otherwise the
// DEFAULT_FIRM_ID param. A matter is accessible when its firmID matches (or it
// has none). When multi-firm lands, add firmID to users docs and this keeps
// working unchanged.

const { HttpsError } = require('firebase-functions/v2/https');

function requireAuth(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  return request.auth.uid;
}

async function firmIdForUser(db, uid, defaultFirmId) {
  const snap = await db.collection('users').doc(uid).get();
  const v = snap.exists ? snap.get('firmID') || snap.get('firmId') : null;
  return (typeof v === 'string' && v.trim()) || defaultFirmId;
}

function assertDocId(id, name = 'id') {
  if (typeof id !== 'string' || !id || id.includes('/') || id.length > 200) {
    throw new HttpsError('invalid-argument', `${name} is required`);
  }
}

async function loadMatterForUser(db, uid, matterId, defaultFirmId) {
  assertDocId(matterId, 'matterId');
  const ref = db.collection('Matters').doc(matterId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Matter not found');
  const firmId = await firmIdForUser(db, uid, defaultFirmId);
  const matterFirm = snap.get('firmID');
  if (matterFirm && matterFirm !== firmId) {
    throw new HttpsError('permission-denied', 'This matter belongs to a different firm');
  }
  return { ref, snap, firmId };
}

module.exports = { requireAuth, firmIdForUser, loadMatterForUser, assertDocId };
