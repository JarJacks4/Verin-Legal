// Verin Legal — keeps each matter's reconstructed record current.
//
//   onReceiptWritten   whenever an item's reading changes, rebuild the
//                      matter's thread (Matters/{id}/derived/thread). When an
//                      item finishes reading for the first time, record what
//                      it changed (Matters/{id}/updates/{receiptId}), close any
//                      sent follow-up it answers, and log it for value metrics.
//   onMatterNamesChanged  staff confirmed who's who: rebuild with the new names.
//
// Everything written here is derived and server-only; the evidence (receipts,
// files, hash chain) is never touched.

const crypto = require('crypto');
const { onDocumentWritten, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { initializeApp, getApps } = require('firebase-admin/app');

const { reconstruct } = require('./reconstruct');
const { classifyArrival, suggestFollowUps } = require('./updates');

if (!getApps().length) initializeApp();

const TERMINAL = ['extracted', 'no_conversation_detected', 'not_applicable', 'extraction_failed', 'deferred'];
const MAX_DOC_CHARS = 900000; // Firestore documents cap at 1 MiB

/// The parts of a receipt the record depends on; anything else changing
/// (review labels, Clio sync, notes) doesn't need a rebuild.
function signature(d) {
  if (!d) return '';
  const ms = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : v ? new Date(v).getTime() : 0);
  return crypto
    .createHash('sha1')
    .update(
      JSON.stringify({
        t: d.threadMessages || [],
        s: d.statements || [],
        rd: ms(d.resolvedDate),
        dc: d.dateConfidence || '',
        dup: !!d.isDuplicate,
        x: d.extractionState || '',
        m: d.matterId && d.matterId.path ? d.matterId.path : '',
      }),
    )
    .digest('hex');
}

function plain(doc) {
  return { id: doc.id, ...doc.data() };
}

/// Shrinks long message text until the thread fits in one document.
function fitThread(doc) {
  let json = JSON.stringify(doc);
  let limit = 2000;
  while (json.length > MAX_DOC_CHARS && limit >= 120) {
    for (const e of doc.entries) if (typeof e.text === 'string' && e.text.length > limit) e.text = `${e.text.slice(0, limit)}…`;
    doc.truncated = true;
    json = JSON.stringify(doc);
    limit = Math.floor(limit / 2);
  }
  return doc;
}

function aliasesOf(matter) {
  const a = matter && matter.participantAliases;
  return a && typeof a === 'object' ? a : {};
}

/**
 * Rebuilds a matter's thread. With arrivedId, also classifies that item's
 * arrival (once), resolves follow-ups it answers and logs it.
 */
async function rebuildMatter(db, matterRef, { arrivedId = null } = {}) {
  const matterSnap = await matterRef.get();
  if (!matterSnap.exists) return null;
  const matter = matterSnap.data();
  const firmId = matter.firmID || '';
  const aliases = aliasesOf(matter);

  const receipts = (await db.collection('Receipts').where('matterId', '==', matterRef).get()).docs.map(plain);
  const thread = reconstruct(receipts, { aliases });
  const suggestions = suggestFollowUps({ thread, receipts });

  const doc = fitThread({
    firmID: firmId,
    builtAt: FieldValue.serverTimestamp(),
    receiptCount: receipts.length,
    entries: thread.entries,
    gaps: thread.gaps,
    participants: thread.participants,
    stats: thread.stats,
    notes: thread.notes,
    suggestions,
  });
  await matterRef.collection('derived').doc('thread').set(doc);

  if (arrivedId) {
    const receipt = receipts.find((r) => r.id === arrivedId);
    if (receipt) {
      const updRef = matterRef.collection('updates').doc(arrivedId);
      const existing = await updRef.get();
      if (!existing.exists) {
        const before = reconstruct(
          receipts.filter((r) => r.id !== arrivedId),
          { aliases },
        );
        const c = classifyArrival({ receipt, before, after: thread, others: receipts });
        await updRef.set({
          firmID: firmId,
          receiptId: db.collection('Receipts').doc(arrivedId),
          headline: String(receipt.originalFileName || receipt.content || receipt.itemKind || 'Item').slice(0, 200),
          channel: receipt.channel || '',
          receivedAt: receipt.receivedAt || null,
          ...c,
          at: FieldValue.serverTimestamp(),
        });
      }

      // Follow-ups that were sent and no longer apply: the evidence arrived.
      const open = new Set(suggestions.map((s) => s.key));
      const sent = await db.collection('FollowUps').where('matterId', '==', matterRef).where('status', '==', 'sent').get();
      const batch = db.batch();
      let n = 0;
      for (const f of sent.docs) {
        if (!open.has(f.get('key'))) {
          batch.update(f.ref, { status: 'resolved', resolvedAt: FieldValue.serverTimestamp(), resolvedByReceipt: db.collection('Receipts').doc(arrivedId) });
          n++;
        }
      }
      if (n) await batch.commit();

      // Value metrics: one "read" event per item (idempotent id).
      const recv = receipt.receivedAt && receipt.receivedAt.toMillis ? receipt.receivedAt.toMillis() : null;
      const read = receipt.extractedAt && receipt.extractedAt.toMillis ? receipt.extractedAt.toMillis() : Date.now();
      const msgs = Array.isArray(receipt.threadMessages) ? receipt.threadMessages.filter((m) => !m.isHeader).length : 0;
      await db
        .collection('Activity')
        .doc(`read_${arrivedId}`)
        .set({
          firmID: firmId,
          matterId: matterRef,
          receiptId: db.collection('Receipts').doc(arrivedId),
          type: 'read',
          itemKind: receipt.itemKind || '',
          evidenceType: receipt.evidenceType || '',
          state: receipt.extractionState || '',
          messages: msgs,
          statements: Array.isArray(receipt.statements) ? receipt.statements.length : 0,
          transcriptLines: Array.isArray(receipt.transcript) ? receipt.transcript.length : 0,
          durationSeconds: Number(receipt.durationSeconds || 0),
          duplicate: !!receipt.isDuplicate,
          readMs: recv ? Math.max(0, read - recv) : null,
          at: FieldValue.serverTimestamp(),
        });
    }
  }
  return thread;
}

exports.onReceiptWritten = onDocumentWritten({ document: 'Receipts/{receiptId}', memory: '1GiB', timeoutSeconds: 300 }, async (event) => {
  const before = event.data && event.data.before && event.data.before.exists ? event.data.before.data() : null;
  const after = event.data && event.data.after && event.data.after.exists ? event.data.after.data() : null;
  const src = after || before;
  if (!src || !src.matterId) return;
  if (before && after && signature(before) === signature(after)) return;

  const db = getFirestore();
  const justFinished =
    after && TERMINAL.includes(after.extractionState) && (!before || before.extractionState !== after.extractionState);
  await rebuildMatter(db, src.matterId, { arrivedId: justFinished ? event.params.receiptId : null });
  // A receipt that moved between matters: rebuild the one it left too.
  if (before && after && before.matterId && after.matterId && before.matterId.path !== after.matterId.path) {
    await rebuildMatter(db, before.matterId);
  }
});

exports.onMatterNamesChanged = onDocumentUpdated({ document: 'Matters/{matterId}', memory: '1GiB', timeoutSeconds: 300 }, async (event) => {
  const b = event.data.before.data() || {};
  const a = event.data.after.data() || {};
  if (JSON.stringify(aliasesOf(b)) === JSON.stringify(aliasesOf(a))) return;
  await rebuildMatter(getFirestore(), event.data.after.ref);
});

/// For matters filed before reconstruction moved to the server (or on demand
/// from the Thread tab): rebuild now.
const { onCall } = require('firebase-functions/v2/https');
const { requireAuth, loadMatterForUser } = require('../common/access');
exports.refreshMatterRecord = onCall({ memory: '1GiB', timeoutSeconds: 300 }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref } = await loadMatterForUser(db, uid, (request.data || {}).matterId);
  const t = await rebuildMatter(db, ref);
  return { ok: true, messages: t ? t.stats.messages : 0 };
});

exports.rebuildMatter = rebuildMatter;
exports.signature = signature;
exports.fitThread = fitThread;
