// Verin Legal — deleting your own account.
//
// Removes the person, not the firm's evidence: the sign-in, the users doc,
// their team-list entries and any half-finished uploads go; matters,
// receipts, the hash chain and annotations stay with the firm (they are the
// firm's records, kept under its retention policy).
//
// Guards: the caller must have signed in within the last few minutes (the
// app re-asks for the password first), and the only admin of a firm that
// still has other members can't leave it without an admin.

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const { initializeApp, getApps } = require('firebase-admin/app');

const { requireAuth, userAccess, isAdminRole } = require('../common/access');

if (!getApps().length) initializeApp();

const RECENT_SIGN_IN_SECONDS = 5 * 60;

// Pure decision, exported for tests: may this member leave the firm?
function blockingReason({ isAdmin, otherMembers, otherAdmins, firmName }) {
  if (isAdmin && otherMembers > 0 && otherAdmins === 0) {
    return `You're the only admin of ${firmName || 'your firm'}. Invite or make another admin before deleting your account, or remove the other members first.`;
  }
  return null;
}

exports.deleteAccount = onCall({ timeoutSeconds: 120 }, async (request) => {
  const uid = requireAuth(request);
  const authTime = Number(request.auth.token.auth_time || 0);
  if (!authTime || Date.now() / 1000 - authTime > RECENT_SIGN_IN_SECONDS) {
    throw new HttpsError('failed-precondition', 'For your security, confirm your password and try again.');
  }

  const db = getFirestore();
  const email = String(request.auth.token.email || '').trim().toLowerCase();
  const { firmId, isAdmin } = await userAccess(db, uid);

  if (firmId) {
    const members = await db.collection('users').where('firmID', '==', firmId).get();
    const others = members.docs.filter((d) => d.id !== uid);
    const otherAdmins = others.filter((d) => isAdminRole(d.get('role'))).length;
    const acct = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
    const reason = blockingReason({
      isAdmin,
      otherMembers: others.length,
      otherAdmins,
      firmName: acct.empty ? '' : acct.docs[0].get('firmName'),
    });
    if (reason) throw new HttpsError('failed-precondition', reason);

    // Their entries on the team list (and any invitation to their email).
    const [byUid, byEmail] = await Promise.all([
      db.collection('TeamMembers').where('uid', '==', uid).get(),
      email ? db.collection('TeamMembers').where('firmID', '==', firmId).where('email', '==', email).get() : null,
    ]);
    const batch = db.batch();
    for (const d of [...byUid.docs, ...(byEmail ? byEmail.docs : [])]) batch.delete(d.ref);
    await batch.commit();
  }

  // Uploads that never finished ingesting.
  try {
    await getStorage().bucket().deleteFiles({ prefix: `intake/${uid}/` });
  } catch (e) {
    console.warn('intake cleanup failed', uid, e.message);
  }

  await db.collection('users').doc(uid).delete();
  await getAuth().deleteUser(uid);
  return { ok: true };
});

exports.blockingReason = blockingReason;
