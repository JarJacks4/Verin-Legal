// Verin Legal — delivery, then removal (checklist #16, changed Oct 6, 2026).
//
// Verin does not keep client files. An item's file is held only until the
// firm's own system has it; after that only the hash, the RFC 3161 token,
// the hash chain and the audit log stay in Verin.
//
//   deliverMatterRecord  Builds the matter's record ZIP (files exactly as
//                        received + certificate + manifest + verify.py) and
//                        delivers it:
//                          target 'clio'      uploads to the linked Clio
//                                             matter; Clio confirms the upload
//                                             before anything is removed.
//                          target 'download'  returns a link; nothing is removed
//                                             until someone confirms the firm
//                                             has saved it (confirmDelivery).
//   confirmDelivery      "We've saved this record" for a download delivery.
//   autoDeliverToClio    Nightly: delivers new, finished items on every
//                        Clio-linked matter of firms that keep auto-delivery on.
//
// Removal applies only to items that have finished processing (not still
// being read, not held as unknown-sender items), only when the firm's
// "Remove files after delivery" setting is on (default on), and never in an
// NFR demo workspace. The removal itself is recorded on the item and in the
// delivery record.

const { getApps, initializeApp } = require('firebase-admin/app');
const { firmData } = require('../common/firm');
const { raiseAlert } = require('../common/alerts');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');

const { requireAuth, loadMatterForUser, assertDocId } = require('../common/access');

if (!getApps().length) initializeApp();

const NOT_FINISHED = new Set(['pending', 'running', 'quarantined', 'processing']);

/// Can this item's file be removed once delivered?
function removable(r) {
  if (!r || r.originalDeletedAt) return false;
  if (r.isQuarantined === true) return false;
  if (NOT_FINISHED.has(String(r.extractionState || '').toLowerCase())) return false;
  if (String(r.classificationLabel || '').toLowerCase() === 'processing') return false;
  return !!r.sourceStoragePath;
}

/// Firm setting, default on.
function removeAfterDelivery(firm) {
  return !(firm && firm.deleteAfterDelivery === false);
}

/// Files that belong to one item, except the RFC 3161 token (kept).
async function itemFiles(bucket, matterId, receiptId, r) {
  const keep = new Set([r.tsaTokenPath].filter(Boolean));
  const paths = new Set([r.sourceStoragePath, r.extractionSourcePath, r.probePath].filter(Boolean));
  try {
    const [files] = await bucket.getFiles({ prefix: `matters/${matterId}/receipts/${receiptId}` });
    for (const f of files) paths.add(f.name);
  } catch (_) {
    /* listing is best effort; the named paths are still removed */
  }
  return [...paths].filter((p) => !keep.has(p) && !/\.tsr$/i.test(p));
}

/**
 * Removes delivered files. Pure of HTTP; used by every delivery path.
 * Returns { removed: [receiptId], kept: [{ id, reason }] }.
 */
async function purgeDelivered({ db, bucket, matterRef, matter, firm, deliveryId, deliveredTo, receiptIds }) {
  const removed = [];
  const kept = [];
  const demo = matter && matter.demo === true;
  const allowed = removeAfterDelivery(firm) && !demo;
  for (const id of receiptIds) {
    const ref = db.collection('Receipts').doc(id);
    const snap = await ref.get();
    if (!snap.exists) continue;
    const r = snap.data();
    const base = { deliveredAt: FieldValue.serverTimestamp(), deliveredTo, deliveryId };
    if (!allowed) {
      // Delivered; the firm (or the demo) keeps Verin's copy.
      kept.push({ id, reason: demo ? 'demo workspace' : 'firm keeps files' });
      await ref.set(base, { merge: true });
      continue;
    }
    if (!removable(r)) {
      // Not marked delivered, so the next delivery picks it up again.
      kept.push({ id, reason: 'not finished processing' });
      continue;
    }
    const paths = await itemFiles(bucket, matterRef.id, id, r);
    for (const p of paths) {
      await bucket.file(p).delete({ ignoreNotFound: true }).catch((e) => console.warn('delivery: delete failed', p, e.message));
    }
    await ref.set(
      {
        ...base,
        originalDeletedAt: FieldValue.serverTimestamp(),
        originalDeletedPaths: paths.length,
        sourceUrl: '',
      },
      { merge: true },
    );
    removed.push(id);
  }
  return { removed, kept };
}

async function deliver({ db, bucket, ref, md, firm, uid, exportedBy, target, clioSessionFor, firmId }) {
  const { buildMatterZip } = require('./archive');
  const exportedAt = new Date();
  const zipRes = await buildMatterZip({ db, bucket, ref, md, uid, exportedAt, exportedBy });
  const deliveryRef = ref.collection('deliveries').doc();
  const receiptIds = zipRes.included.map((x) => x.id);
  const record = {
    target,
    zipSha256: zipRes.sha256,
    zipFileName: zipRes.fileName,
    zipBytes: zipRes.bytes || null,
    items: receiptIds,
    itemHashes: zipRes.included.map((x) => x.itemHash),
    createdByUid: uid,
    createdAt: FieldValue.serverTimestamp(),
  };

  if (target === 'clio') {
    const clioMatterId = md.clioMatterID || md.providerMatterReference;
    if (!clioMatterId) throw new HttpsError('failed-precondition', 'Link this matter to a Clio matter first.');
    const file = bucket.file(zipRes.storagePath);
    const [bytes] = await file.download();
    const t0 = Date.now();
    let uploaded;
    const session = clioSessionFor(firmId);
    const prior = (md.clioDocIds || {}).record_zip || null;
    try {
      try {
        // Versioned, not duplicated (#22): each delivery is the next version.
        uploaded = await session.uploadDocument({ clioMatterId, name: zipRes.fileName, bytes, contentType: 'application/zip', versionOf: prior });
      } catch (e) {
        if (!prior) throw e;
        uploaded = await session.uploadDocument({ clioMatterId, name: zipRes.fileName, bytes, contentType: 'application/zip' });
        uploaded.fresh = true;
      }
      if (!prior || uploaded.fresh) await ref.set({ clioDocIds: { record_zip: uploaded.id } }, { merge: true });
    } catch (e) {
      await deliveryRef.set({ ...record, status: 'failed', error: String(e.message || e).slice(0, 500) });
      throw new HttpsError('unavailable', `Clio did not accept the record: ${e.message || e}. Nothing was removed from Verin.`);
    }
    const purge = await purgeDelivered({ db, bucket, matterRef: ref, matter: md, firm, deliveryId: deliveryRef.id, deliveredTo: 'Clio', receiptIds });
    // The ZIP holds the files too; it goes once Clio has it (unless files are kept).
    if (purge.removed.length) await file.delete({ ignoreNotFound: true }).catch(() => {});
    await deliveryRef.set({
      ...record,
      status: 'delivered',
      clioDocumentId: uploaded.id,
      writeBackMs: Date.now() - t0,
      confirmedAt: FieldValue.serverTimestamp(),
      removed: purge.removed,
      kept: purge.kept,
    });
    await db.collection('clioSyncLog').add({
      matterID: ref,
      documentName: zipRes.fileName,
      storagePath: zipRes.storagePath,
      pushedByUid: uid,
      pushedAt: FieldValue.serverTimestamp(),
      status: 'Synced',
      clioDocumentId: uploaded.id,
      sha256: zipRes.sha256,
      error: '',
      deliveryId: deliveryRef.id,
    });
    await ref.set({ clioSyncedAt: FieldValue.serverTimestamp(), providerSyncedAt: FieldValue.serverTimestamp(), lastDeliveryAt: FieldValue.serverTimestamp() }, { merge: true });
    return { status: 'delivered', deliveryId: deliveryRef.id, items: receiptIds.length, removed: purge.removed.length, kept: purge.kept.length, clioDocumentId: uploaded.id };
  }

  if (target === 'practicepanther' || target === 'filevine') {
    // Same delivery, to the firm's PracticePanther or Filevine matter: the
    // upload must succeed before anything is removed from Verin.
    const { pushToProvider } = require('../practice/functions')._practice;
    const file = bucket.file(zipRes.storagePath);
    const [bytes] = await file.download();
    const t0 = Date.now();
    let up;
    try {
      up = await pushToProvider({ firmId, provider: target, matterRef: ref, matter: md, name: zipRes.fileName, bytes, contentType: 'application/zip', uid, storagePath: zipRes.storagePath, deliveryId: deliveryRef.id });
    } catch (e) {
      await deliveryRef.set({ ...record, status: 'failed', error: String(e.message || e).slice(0, 500) });
      throw e instanceof HttpsError ? e : new HttpsError('unavailable', `The record was not accepted: ${e.message || e}. Nothing was removed from Verin.`);
    }
    const label = target === 'filevine' ? 'Filevine' : 'PracticePanther';
    const purge = await purgeDelivered({ db, bucket, matterRef: ref, matter: md, firm, deliveryId: deliveryRef.id, deliveredTo: label, receiptIds });
    if (purge.removed.length) await file.delete({ ignoreNotFound: true }).catch(() => {});
    await deliveryRef.set({ ...record, status: 'delivered', externalDocumentId: up.documentId, writeBackMs: Date.now() - t0, confirmedAt: FieldValue.serverTimestamp(), removed: purge.removed, kept: purge.kept });
    await ref.set({ lastDeliveryAt: FieldValue.serverTimestamp() }, { merge: true });
    return { status: 'delivered', deliveryId: deliveryRef.id, items: receiptIds.length, removed: purge.removed.length, kept: purge.kept.length, to: label };
  }

  await deliveryRef.set({ ...record, status: 'awaiting_confirmation', zipStoragePath: zipRes.storagePath });
  return { status: 'awaiting_confirmation', deliveryId: deliveryRef.id, items: receiptIds.length, downloadUrl: zipRes.downloadUrl, fileName: zipRes.fileName, sha256: zipRes.sha256 };
}

function clioDeps() {
  return require('../clio/functions')._clio;
}

exports.deliverMatterRecord = onCall({ secrets: [...clioDeps().CLIO_SECRETS, ...require('../practice/secrets').practiceSecrets()], timeoutSeconds: 540, memory: '2GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  const target = ['clio', 'practicepanther', 'filevine'].includes(data.target) ? data.target : 'download';
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, data.matterId);
  const firm = await firmData(db, firmId);
  const { generatedByName } = require('./archive');
  const exportedBy = await generatedByName(db, uid, request);
  return deliver({ db, bucket, ref, md: snap.data() || {}, firm, uid, exportedBy, target, clioSessionFor: clioDeps().sessionFor, firmId });
});

exports.confirmDelivery = onCall({ timeoutSeconds: 300 }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, data.matterId);
  assertDocId(data.deliveryId, 'deliveryId');
  const dRef = ref.collection('deliveries').doc(data.deliveryId);
  const d = await dRef.get();
  if (!d.exists) throw new HttpsError('not-found', 'Delivery not found');
  if (d.get('status') !== 'awaiting_confirmation') return { status: d.get('status') };
  const firm = await firmData(db, firmId);
  const purge = await purgeDelivered({ db, bucket, matterRef: ref, matter: snap.data() || {}, firm, deliveryId: dRef.id, deliveredTo: 'Firm download', receiptIds: d.get('items') || [] });
  if (purge.removed.length && d.get('zipStoragePath')) await bucket.file(d.get('zipStoragePath')).delete({ ignoreNotFound: true }).catch(() => {});
  await dRef.set({ status: 'delivered', confirmedAt: FieldValue.serverTimestamp(), confirmedByUid: uid, removed: purge.removed, kept: purge.kept }, { merge: true });
  await ref.set({ lastDeliveryAt: FieldValue.serverTimestamp() }, { merge: true });
  return { status: 'delivered', removed: purge.removed.length, kept: purge.kept.length };
});

exports.autoDeliverToClio = onSchedule(
  { schedule: 'every day 02:30', timeZone: 'America/Indiana/Indianapolis', secrets: clioDeps().CLIO_SECRETS, timeoutSeconds: 540, memory: '2GiB' },
  async () => {
    const db = getFirestore();
    const bucket = getStorage().bucket();
    const status = await db.collection('integrationStatus').where('clioConnected', '==', true).get();
    for (const s of status.docs) {
      const firmId = s.id;
      const firm = await firmData(db, firmId);
      if (firm.autoDeliver === false || firm.isDemo === true) continue;
      const matters = await db.collection('Matters').where('firmID', '==', firmId).get();
      for (const m of matters.docs) {
        const md = m.data() || {};
        if (!(md.clioMatterID || md.providerMatterReference) || md.demo === true) continue;
        const pending = await db.collection('Receipts').where('matterId', '==', m.ref).get();
        if (!pending.docs.some((d) => removable(d.data()) && !d.get('deliveredAt'))) continue;
        try {
          await deliver({ db, bucket, ref: m.ref, md, firm, uid: 'system', exportedBy: 'Verin (nightly delivery)', target: 'clio', clioSessionFor: clioDeps().sessionFor, firmId });
        } catch (e) {
          console.error('autoDeliverToClio failed', firmId, m.id, e.message);
          await raiseAlert(db, firmId, {
            kind: 'delivery_failed',
            matterId: m.id,
            dedupeKey: `delivery_${m.id}`,
            message: `Nightly delivery to Clio failed for ${md.matterName || m.id}: ${String(e.message || e).slice(0, 300)}. Files stay in Verin until it succeeds.`,
          });
        }
      }
    }
  },
);

exports._internal = { removable, removeAfterDelivery, purgeDelivered, itemFiles, deliver };
