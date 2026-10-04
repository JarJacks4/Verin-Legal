// Verin Legal — exportMatterRecord: build the matter's record PDF, store it,
// and return a download link. Used by the Certificate of Preparation's
// "Download PDF", the Integrity tab's "Export record", and the Practice tab's
// "Push record to Clio" (which uploads the stored PDF into Clio).

const crypto = require('crypto');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

const P = require('../common/params');
const { requireAuth, loadMatterForUser } = require('../common/access');
const { verifyEntries } = require('../chain/chain');
const { buildRecordPdf } = require('./record_pdf');

if (!getApps().length) initializeApp();

const toDate = (v) => (v && typeof v.toDate === 'function' ? v.toDate() : v instanceof Date ? v : null);

function headlineOf(r) {
  if (r.content) return r.content;
  const kind = r.itemKind ? r.itemKind.replace(/_/g, ' ') : 'Item';
  return r.channel ? `${kind} via ${r.channel}` : kind;
}

function slug(s) {
  return String(s || 'matter')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60) || 'matter';
}

exports.exportMatterRecord = onCall({ timeoutSeconds: 120, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref, snap } = await loadMatterForUser(db, uid, (request.data || {}).matterId);
  const md = snap.data() || {};

  const [receiptSnap, chainSnap] = await Promise.all([
    db.collection('Receipts').where('matterId', '==', ref).get(),
    db.collection('chainEntries').where('matterID', '==', ref).get(),
  ]);

  const receipts = receiptSnap.docs
    .map((d) => {
      const r = d.data();
      return {
        id: d.id,
        receivedAt: toDate(r.receivedAt),
        channel: r.channel || '',
        itemKind: r.itemKind || '',
        headline: headlineOf(r),
        itemHash: r.item_hash || '',
        entryHash: r.entryHash || '',
        chainSeq: r.chainSeq || 0,
        detectedPlatform: r.detectedPlatform || '',
        threadMessages: Array.isArray(r.threadMessages) ? r.threadMessages : [],
      };
    })
    .sort((a, b) => (a.receivedAt ? a.receivedAt.getTime() : 0) - (b.receivedAt ? b.receivedAt.getTime() : 0));

  const chain = chainSnap.docs.map((d) => d.data()).sort((a, b) => (a.seq || 0) - (b.seq || 0));
  const verification = verifyEntries(chain);

  const user = await db.collection('users').doc(uid).get();
  const generatedBy = (user.exists && (user.get('display_name') || user.get('email'))) || request.auth.token.email || uid;
  const generatedAt = new Date();
  const title = md.matterName || md.caseTitle || ref.id;

  let pdf;
  try {
    pdf = await buildRecordPdf({
      matter: {
        id: ref.id,
        title,
        clientName: md.clientName || '',
        caseNumber: md.caseNumber || '',
        assignedCounsel: md.assignedCounsel || '',
        practiceArea: md.practiceArea || '',
        openedAt: toDate(md.openedAt),
        redactionCount: md.redactionCount || 0,
        redactionCategories: md.redactionCategories || '',
        hashChainLastAnchoredAt: toDate(md.hashChainLastAnchoredAt),
        chainHeadHash: md.chainHeadHash || '',
      },
      receipts,
      chain: chain.map((e) => ({
        seq: e.seq,
        prevHash: e.prevHash || '',
        itemHash: e.itemHash || '',
        receivedAtIso: e.receivedAtIso || '',
        originDigest: e.originDigest || '',
        entryHash: e.entryHash || '',
      })),
      verification,
      generatedAt,
      generatedBy,
    });
  } catch (e) {
    console.error('exportMatterRecord: PDF build failed', e);
    throw new HttpsError('internal', 'Could not build the record PDF.');
  }

  const sha256 = crypto.createHash('sha256').update(pdf).digest('hex');
  const stamp = generatedAt.toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
  const fileName = `${slug(title)}-record-${stamp}.pdf`;
  const storagePath = `matters/${ref.id}/exports/${fileName}`;
  const token = crypto.randomUUID();
  const bucket = getStorage().bucket();
  await bucket.file(storagePath).save(pdf, {
    resumable: false,
    contentType: 'application/pdf',
    metadata: {
      contentDisposition: `inline; filename="${fileName}"`,
      metadata: { firebaseStorageDownloadTokens: token, sha256, generatedBy: uid },
    },
  });
  const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(storagePath)}?alt=media&token=${token}`;

  await Promise.all([
    ref.collection('exports').add({
      storagePath,
      fileName,
      sha256,
      bytes: pdf.length,
      items: receipts.length,
      chainEntries: chain.length,
      chainHead: verification.head || null,
      chainOk: verification.ok,
      generatedByUid: uid,
      generatedAt: FieldValue.serverTimestamp(),
    }),
    ref.set(
      { lastExportPath: storagePath, lastExportSha256: sha256, lastExportAt: FieldValue.serverTimestamp() },
      { merge: true },
    ),
  ]);

  return { storagePath, downloadUrl, sha256, fileName, generatedAt: generatedAt.toISOString(), chainOk: verification.ok };
});
