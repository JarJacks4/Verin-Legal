// Review-queue actions on what intake held back:
//
//   approveQuarantined  (callable) read an item from an unknown sender, and
//                       everything else that sender sent to the matter
//   assignUnrouted      (callable) file a text from an unknown number to a
//                       matter, or dismiss it
//
// Kept apart from ./functions.js, which defines the intake secrets: these
// don't need them, so they deploy (and work in the demo workspace) whether
// or not live email/SMS intake is switched on.

const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

const P = require('../common/params');
const { requireAuth, loadMatterForUser, assertDocId, firmIdForUser } = require('../common/access');
const { processReceipt } = require('../evidence/process');
const ingest = require('../evidence/ingest');
const { fileSmsInto } = require('./sms_file');

if (!getApps().length) initializeApp();

exports.approveQuarantined = onCall(
  { secrets: [P.ANTHROPIC_API_KEY], timeoutSeconds: 540, memory: '2GiB' },
  async (request) => {
    const uid = requireAuth(request);
    const db = getFirestore();
    const data = request.data || {};
    assertDocId(data.receiptId, 'receiptId');
    const ref = db.collection('Receipts').doc(data.receiptId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Receipt not found');
    const matterRef = snap.get('matterId');
    const { ref: mRef } = await loadMatterForUser(db, uid, matterRef && matterRef.id);
    const senderKey = snap.get('senderKey') || '';

    // Approving a sender approves everything they sent to this matter.
    let targets = [ref];
    if (senderKey) {
      const held = await db.collection('Receipts').where('matterId', '==', mRef).where('extractionState', '==', 'quarantined').get();
      targets = held.docs.filter((d) => d.get('senderKey') === senderKey).map((d) => d.ref);
      if (!targets.some((r) => r.id === ref.id)) targets.push(ref);
    }
    if (data.remember && senderKey) {
      const v = senderKey.replace(/^(mail|tel):/, '');
      const field = senderKey.startsWith('tel:') ? 'clientPhones' : 'knownSenders';
      await mRef.set({ [field]: FieldValue.arrayUnion(v) }, { merge: true });
    }
    const deps = ingest.processDeps();
    let read = 0;
    for (const r of targets) {
      await r.set(
        { isQuarantined: false, classificationLabel: 'Processing', extractionState: 'running', reviewReason: '', approvedBy: uid, approvedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      try {
        await processReceipt(deps, r, { uid });
        read++;
      } catch (e) {
        console.error('approveQuarantined: reading failed', r.id, e);
        await r.set({ extractionState: 'extraction_failed', classificationLabel: 'Uncertain', extractionErrors: [`reading crashed: ${e.message}`] }, { merge: true });
      }
    }
    return { approved: targets.length, read };
  },
);

exports.assignUnrouted = onCall({ timeoutSeconds: 300, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  assertDocId(data.id, 'id');
  const firmId = await firmIdForUser(db, uid);
  const uref = db.collection('UnroutedIntake').doc(data.id);
  const u = await uref.get();
  if (!u.exists || u.get('firmID') !== firmId) throw new HttpsError('not-found', 'Message not found');
  if (u.get('status') !== 'open') throw new HttpsError('failed-precondition', 'This message was already handled.');
  if (data.dismiss === true) {
    await uref.set({ status: 'dismissed', handledBy: uid, handledAt: FieldValue.serverTimestamp() }, { merge: true });
    return { ok: true };
  }
  const { ref: matterRef } = await loadMatterForUser(db, uid, data.matterId);
  const from = u.get('from');
  if (data.remember) await matterRef.set({ clientPhones: FieldValue.arrayUnion(from) }, { merge: true });
  const at = u.get('at') && u.get('at').toDate ? u.get('at').toDate() : new Date();
  const filed = await fileSmsInto(db, bucket, {
    eventId: data.id,
    matterRef,
    from,
    to: u.get('to'),
    body: u.get('body'),
    sid: u.get('sid'),
    at,
    media: u.get('media') || [],
    known: true, // a person chose the matter
  });
  await uref.set({ status: 'filed', matterId: matterRef, receipts: filed, handledBy: uid, handledAt: FieldValue.serverTimestamp() }, { merge: true });
  return { ok: true, receipts: filed.length };
});
