// Verin Legal — attaching a signed-in account to a firm.
//
// setupAccount is the only thing that ever writes users/{uid}.firmID and
// users/{uid}.role (security rules forbid clients from setting either).
// The app calls it right after sign-up and once per session after sign-in.
//
//   • Account already has a firm  → nothing changes (one-time data
//     migration for that firm runs the first time, see migrateFirm).
//   • An open invitation exists for this email (or inviteId is given)
//     → joins that firm with the invited role.
//   • Otherwise → a new firm is created and this account is its Admin.

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { initializeApp, getApps } = require('firebase-admin/app');

const P = require('../common/params');
const { requireAuth, assertDocId } = require('../common/access');

if (!getApps().length) initializeApp();

const clean = (v, max = 120) => (typeof v === 'string' ? v.trim().slice(0, max) : '');

function inviteIsOpen(snap, email, now) {
  if (!snap || !snap.exists) return false;
  if (String(snap.get('status') || '').toLowerCase() !== 'invited') return false;
  if (!clean(snap.get('firmID'))) return false;
  if (String(snap.get('email') || '').trim().toLowerCase() !== email) return false;
  const exp = snap.get('expiresAt');
  if (exp && typeof exp.toMillis === 'function' && exp.toMillis() < now) return false;
  return true;
}

async function commitInChunks(db, writes) {
  for (let i = 0; i < writes.length; i += 400) {
    const batch = db.batch();
    for (const [ref, data] of writes.slice(i, i + 400)) batch.set(ref, data, { merge: true });
    await batch.commit();
  }
}

// Stamps firmID on records created before firms were separated, so the
// security rules (which only allow reads of your own firm's records) keep
// showing them. Runs once per firm; safe to run again.
async function migrateFirm(db, firmId, firmName = '') {
  const marker = db.collection('firmScope').doc(firmId);
  if ((await marker.get()).exists) return { skipped: true };

  const writes = [];
  const matters = await db.collection('Matters').where('firmID', '==', firmId).get();
  for (const m of matters.docs) {
    const [receipts, chain, log] = await Promise.all([
      db.collection('Receipts').where('matterId', '==', m.ref).get(),
      db.collection('chainEntries').where('matterID', '==', m.ref).get(),
      db.collection('clioSyncLog').where('matterID', '==', m.ref).get(),
    ]);
    for (const d of [...receipts.docs, ...chain.docs, ...log.docs]) {
      if (d.get('firmID') !== firmId) writes.push([d.ref, { firmID: firmId }]);
    }
  }

  // Before separation there was one firm (DEFAULT_FIRM_ID); its firm
  // profile and team list carry no firmID yet.
  if (firmId === P.DEFAULT_FIRM_ID.value()) {
    const [accounts, team] = await Promise.all([db.collection('firmAccount').get(), db.collection('TeamMembers').get()]);
    for (const d of [...accounts.docs, ...team.docs]) {
      if (!d.get('firmID')) writes.push([d.ref, { firmID: firmId }]);
    }
    for (const d of team.docs) {
      const email = String(d.get('email') || '');
      if (email && email !== email.toLowerCase()) writes.push([d.ref, { email: email.trim().toLowerCase() }]);
    }
  }

  await commitInChunks(db, writes);

  // Every firm needs a profile record (Settings, Billing, Team read it).
  const hasProfile = !(await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get()).empty;
  if (!hasProfile) {
    await db.collection('firmAccount').doc(firmId).set({
      firmID: firmId,
      firmName: firmName || firmId,
      createdAt: FieldValue.serverTimestamp(),
      memberSince: Timestamp.now(),
    });
  }
  await marker.set({ migratedAt: FieldValue.serverTimestamp(), updated: writes.length });
  return { updated: writes.length };
}

exports.setupAccount = onCall({ timeoutSeconds: 120 }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const email = String(request.auth.token.email || '').trim().toLowerCase();
  const data = request.data || {};
  const firmName = clean(data.firmName);
  const fullName = clean(data.fullName);
  const title = clean(data.title, 60);
  const inviteId = data.inviteId ? String(data.inviteId) : '';
  if (inviteId) assertDocId(inviteId, 'inviteId');

  const userRef = db.collection('users').doc(uid);
  const now = Date.now();

  const result = await db.runTransaction(async (tx) => {
    const user = await tx.get(userRef);
    const existing = user.exists ? clean(user.get('firmID'), 200) : '';
    if (existing) {
      return { firmId: existing, role: String(user.get('role') || ''), created: false, joined: false, firmName: clean(user.get('lawFirm')) };
    }

    // Reads first (transaction rule), then writes.
    let invite = null;
    if (inviteId) {
      const s = await tx.get(db.collection('TeamMembers').doc(inviteId));
      if (s.exists && !inviteIsOpen(s, email, now)) {
        const sentTo = String(s.get('email') || '').trim().toLowerCase();
        if (sentTo && sentTo !== email) {
          throw new HttpsError('permission-denied', `This invitation was sent to ${sentTo}. Sign up with that email address.`);
        }
        throw new HttpsError('failed-precondition', 'This invitation has expired or was withdrawn. Ask your firm admin for a new one.');
      }
      if (s.exists) invite = s;
    }
    if (!invite && email) {
      const q = await tx.get(db.collection('TeamMembers').where('email', '==', email).where('status', '==', 'invited').limit(10));
      invite = q.docs.find((d) => inviteIsOpen(d, email, now)) || null;
    }

    const name = fullName || clean(user.exists ? user.get('display_name') : '') || email;
    const profile = {
      ...(title ? { title } : {}),
      ...(fullName ? { display_name: fullName } : {}),
      firmJoinedAt: FieldValue.serverTimestamp(),
    };

    if (invite) {
      const firmId = clean(invite.get('firmID'), 200);
      const role = clean(invite.get('role'), 40) || 'Paralegal';
      const acct = await tx.get(db.collection('firmAccount').where('firmID', '==', firmId).limit(1));
      const lawFirm = acct.empty ? '' : clean(acct.docs[0].get('firmName'));
      tx.set(userRef, { ...profile, firmID: firmId, role, ...(lawFirm ? { lawFirm: lawFirm } : {}) }, { merge: true });
      tx.set(invite.ref, { status: 'active', uid, name: invite.get('name') || name, joinedAt: FieldValue.serverTimestamp() }, { merge: true });
      return { firmId, role, created: false, joined: true };
    }

    const nameForFirm = firmName || clean(user.exists ? user.get('lawFirm') : '');
    if (!nameForFirm) {
      throw new HttpsError('invalid-argument', 'Enter your firm name to finish setting up your account.');
    }
    const firmId = `f_${db.collection('firmAccount').doc().id}`;
    tx.set(db.collection('firmAccount').doc(firmId), {
      firmID: firmId,
      firmName: nameForFirm,
      ownerUid: uid,
      createdAt: FieldValue.serverTimestamp(),
      memberSince: Timestamp.fromMillis(now),
    });
    tx.set(db.collection('TeamMembers').doc(), {
      firmID: firmId,
      name,
      email,
      role: 'Admin',
      status: 'active',
      uid,
      invitedAt: Timestamp.fromMillis(now),
      joinedAt: FieldValue.serverTimestamp(),
    });
    tx.set(userRef, { ...profile, firmID: firmId, role: 'Admin', lawFirm: nameForFirm }, { merge: true });
    // Nothing to migrate in a brand-new firm.
    tx.set(db.collection('firmScope').doc(firmId), { migratedAt: FieldValue.serverTimestamp(), updated: 0 });
    return { firmId, role: 'Admin', created: true, joined: false };
  });

  if (!result.created) {
    try {
      await migrateFirm(db, result.firmId, result.firmName);
    } catch (e) {
      console.error('firm migration failed', result.firmId, e);
    }
  }
  return result;
});

exports.migrateFirm = migrateFirm;
exports.inviteIsOpen = inviteIsOpen;
