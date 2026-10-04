// Verin Legal — verifyMatterChain: recompute a matter's hash chain from its
// stored inputs and report whether it's intact (Standalone Verify Tool, §10).

const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onCall } = require('firebase-functions/v2/https');
const P = require('../common/params');
const { requireAuth, loadMatterForUser } = require('../common/access');
const { verifyEntries } = require('./chain');

if (!getApps().length) initializeApp();

exports.verifyMatterChain = onCall(async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref, snap } = await loadMatterForUser(db, uid, (request.data || {}).matterId);

  const entries = (await db.collection('chainEntries').where('matterID', '==', ref).get()).docs.map((d) => d.data());
  const r = verifyEntries(entries);
  const storedHead = snap.get('chainHeadHash') || null;
  const headMatches = !storedHead || !r.head || storedHead === r.head;
  return {
    ok: r.ok && headMatches,
    totalEntries: r.total,
    verifiedEntries: r.verified,
    legacyEntries: r.legacy,
    head: r.head,
    storedHead,
    headMatches,
    brokenAt: r.brokenAt || null,
    reason: r.reason || (headMatches ? null : 'the matter\'s stored chain head does not match the recomputed chain'),
  };
});
