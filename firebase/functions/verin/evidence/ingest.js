// Verin Legal — evidence intake for every file type (photos, screenshots,
// video, voice notes, PDFs, Word, text, email files) and physical items.
//
//   ingestEvidence     The app uploads the file to intake/{uid}/… in Storage,
//                      then calls this. In one pass the function streams the
//                      exact bytes into matters/{matterId}/receipts/… while
//                      hashing them (SHA-256 over the bytes as received),
//                      deletes the temporary upload, appends the receipt to
//                      the matter's hash chain in a transaction, and requests
//                      an RFC 3161 timestamp over the hash. AI reading is then
//                      queued (onReceiptCreated) so the app returns quickly.
//   onReceiptCreated   Firestore trigger: runs AI reading for receipts filed
//                      with extractionState "pending".
//   reprocessReceipt   "Run AI reading again" / "Request transcription".
//
// Secrets: ANTHROPIC_API_KEY. Video/audio reading uses Gemini on Vertex AI
// with the function's own service account (enable aiplatform.googleapis.com).

const crypto = require('crypto');
const { Transform } = require('stream');
const { pipeline } = require('stream/promises');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

const P = require('../common/params');
const { anthropicClient: sharedAnthropicClient } = require('../common/anthropic');
const { requireAuth, loadMatterForUser, assertDocId } = require('../common/access');
const { appendInTransaction } = require('../chain/chain');
const { requestTimestamp } = require('./tsa');
const { processReceipt } = require('./process');
const { originFidelityFor } = require('./video');

if (!getApps().length) initializeApp();

const KINDS = ['photo', 'video', 'document', 'email', 'physical'];
const CHANNELS = {
  email: 'Email',
  sms: 'SMS',
  whatsapp: 'WhatsApp',
  in_person: 'In person',
  mail: 'Mail',
  other: 'Other',
  upload: 'Upload',
};
const MAX_BYTES = 2 * 1024 * 1024 * 1024; // spec §3: up to 2 GB per item

function anthropicClient() {
  return sharedAnthropicClient({ timeout: 300000 });
}

function processDeps() {
  return {
    db: getFirestore(),
    bucket: getStorage().bucket(),
    anthropic: anthropicClient,
    claudeModel: P.EXTRACTION_MODEL.value(),
    maxTokens: P.EXTRACTION_MAX_TOKENS.value(),
    videoModel: P.VIDEO_MODEL.value(),
    project: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
    location: P.VERTEX_LOCATION.value(),
    serverTimestamp: () => FieldValue.serverTimestamp(),
    Timestamp,
    log: console,
  };
}

function cleanText(s, max = 2000) {
  return String(s == null ? '' : s)
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/g, '')
    .trim()
    .slice(0, max);
}

function cleanFileName(name) {
  const s = String(name || '').replace(/[\\/\u0000-\u001f]/g, ' ').trim();
  return (s || 'file').slice(0, 160);
}

function extensionOf(name) {
  const m = /\.([a-z0-9]{1,6})$/i.exec(name || '');
  return m ? `.${m[1].toLowerCase()}` : '';
}

function downloadUrl(bucketName, path, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

/// "2026-10-04" -> Timestamp at noon UTC (a calendar date, not an instant).
function dateOnly(s) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(s || ''));
  if (!m) return null;
  const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], 12));
  return Number.isNaN(d.getTime()) ? null : d;
}

/// Canonical bytes hashed for a physical item (no file exists).
function physicalRecordBytes({ description, custodyNotes, fromLabel, channel, dateReceived }) {
  const obj = { custodyNotes, dateReceived: dateReceived || '', description, fromLabel, kind: 'physical', channel };
  const keys = Object.keys(obj).sort();
  return Buffer.from('{' + keys.map((k) => JSON.stringify(k) + ':' + JSON.stringify(obj[k] || '')).join(',') + '}', 'utf8');
}

/// Streams src -> dest while hashing. Returns { sha256, bytes }.
async function copyAndHash(src, dest, { contentType, metadata, size = 0 }) {
  const hash = crypto.createHash('sha256');
  let bytes = 0;
  const tap = new Transform({
    transform(chunk, _enc, cb) {
      hash.update(chunk);
      bytes += chunk.length;
      cb(null, chunk);
    },
  });
  await pipeline(src.createReadStream(), tap, dest.createWriteStream({ resumable: size > 8 * 1024 * 1024, contentType, metadata: { metadata } }));
  return { sha256: hash.digest('hex'), bytes };
}

async function timestampReceipt({ db, bucket, matterRef, receiptRef, itemHash, basePath }) {
  const url = P.TSA_URL.value();
  if (!url) return;
  const r = await requestTimestamp(itemHash, { url, name: P.TSA_NAME.value() });
  if (!r.ok) {
    console.warn('RFC 3161 timestamp failed', receiptRef.id, r.error);
    await receiptRef.set({ tsaError: r.error }, { merge: true });
    return;
  }
  const tsrPath = `${basePath}.tsr`;
  await bucket.file(tsrPath).save(r.token, { resumable: false, contentType: 'application/timestamp-reply' });
  const tokenId = crypto.createHash('sha256').update(r.token).digest('hex').slice(0, 24);
  const genTime = r.genTime ? Timestamp.fromDate(r.genTime) : FieldValue.serverTimestamp();
  await Promise.all([
    receiptRef.set({ tsaName: r.tsaName, tsaUrl: r.tsaUrl, tsaGenTime: genTime, tsaTokenPath: tsrPath, tsaTokenId: `TSA:${tokenId}` }, { merge: true }),
    matterRef.set(
      {
        rfc3161TsaName: r.tsaName,
        rfc3161LastTimestampedAt: genTime,
        hashChainLastAnchoredAt: genTime,
        hashChainAnchorCount: FieldValue.increment(1),
      },
      { merge: true },
    ),
  ]);
}

exports.ingestEvidence = onCall({ timeoutSeconds: 540, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  const { ref: matterRef } = await loadMatterForUser(db, uid, data.matterId);

  const kind = String(data.kind || '').toLowerCase();
  if (!KINDS.includes(kind)) throw new HttpsError('invalid-argument', `kind must be one of ${KINDS.join(', ')}`);
  const channelKey = Object.prototype.hasOwnProperty.call(CHANNELS, data.channel) ? data.channel : 'upload';
  const channel = CHANNELS[channelKey];
  const fromLabel = cleanText(data.fromLabel, 200);
  const description = cleanText(data.description, 4000);
  const custodyNotes = cleanText(data.custodyNotes, 4000);
  const dateClaimed = dateOnly(data.dateReceived);
  const clientSide = data.clientSide === 'left' ? 'left' : 'right';
  const receivedAt = new Date();
  const receiptRef = db.collection('Receipts').doc();

  let itemHash;
  let storagePath = '';
  let sourceUrl = '';
  let sizeBytes = 0;
  let fileName = '';
  let contentType = '';

  if (kind === 'physical') {
    if (!description) throw new HttpsError('invalid-argument', 'Describe the physical item.');
    itemHash = crypto
      .createHash('sha256')
      .update(physicalRecordBytes({ description, custodyNotes, fromLabel, channel: channelKey, dateReceived: data.dateReceived }))
      .digest('hex');
  } else {
    const uploadPath = String(data.uploadPath || '');
    if (!uploadPath.startsWith(`intake/${uid}/`) || uploadPath.includes('..')) {
      throw new HttpsError('invalid-argument', 'uploadPath must be your own intake upload.');
    }
    const src = bucket.file(uploadPath);
    const [exists] = await src.exists();
    if (!exists) throw new HttpsError('not-found', 'The upload was not found. Try uploading again.');
    const [meta] = await src.getMetadata();
    sizeBytes = Number(meta.size || 0);
    if (!sizeBytes) throw new HttpsError('invalid-argument', 'The file is empty.');
    if (sizeBytes > MAX_BYTES) throw new HttpsError('invalid-argument', 'Files over 2 GB need an alternative transfer — contact Verin.');
    fileName = cleanFileName(data.fileName || uploadPath.split('/').pop());
    contentType = String(data.contentType || meta.contentType || 'application/octet-stream').slice(0, 120);

    storagePath = `matters/${matterRef.id}/receipts/${receiptRef.id}${extensionOf(fileName)}`;
    const token = crypto.randomUUID();
    const dest = bucket.file(storagePath);
    const res = await copyAndHash(src, dest, {
      size: sizeBytes,
      contentType,
      metadata: { firebaseStorageDownloadTokens: token, uploadedBy: uid, originalFileName: fileName, receiptId: receiptRef.id },
    });
    if (res.bytes !== sizeBytes) throw new HttpsError('internal', 'The upload changed while it was being filed. Try again.');
    itemHash = res.sha256;
    await dest.setMetadata({ metadata: { sha256: itemHash } });
    sourceUrl = downloadUrl(bucket.name, storagePath, token);
    try {
      await src.delete();
    } catch (e) {
      console.warn('could not delete intake upload', uploadPath, e.message);
    }
  }

  const dup = await db.collection('Receipts').where('matterId', '==', matterRef).where('item_hash', '==', itemHash).limit(1).get();
  const isDuplicate = !dup.empty;

  const isMedia = kind === 'video' || /^video\/|^audio\//.test(contentType);
  const headline = description ? description.split('\n')[0].slice(0, 160) : fileName || 'Physical item';

  const chain = await db.runTransaction(async (tx) => {
    const appended = await appendInTransaction(tx, db, {
      matterRef,
      receiptRef,
      itemHash,
      receivedAt,
      channel: channelKey,
      source: kind === 'physical' ? `uid:${uid}|physical|from:${fromLabel}` : `uid:${uid}|file:${fileName}|from:${fromLabel}`,
      serverTimestamp: () => FieldValue.serverTimestamp(),
    });
    tx.set(receiptRef, {
      matterId: matterRef,
      firmID: appended.firmId,
      itemKind: kind,
      receivedAt: Timestamp.fromDate(receivedAt),
      channel,
      channelKey,
      content: headline,
      fromLabel: fromLabel || 'Firm upload',
      description,
      custodyNotes,
      ...(dateClaimed ? { dateReceivedClaimed: Timestamp.fromDate(dateClaimed) } : {}),
      originalFileName: fileName,
      contentType,
      sizeBytes,
      item_hash: itemHash,
      isDuplicate,
      hasChronologyShift: false,
      isTranscribed: false,
      ...(isMedia ? { originFidelity: originFidelityFor(channelKey) } : {}),
      detectedPlatform: '',
      threadMessages: [],
      clientSide,
      sourceStoragePath: storagePath,
      sourceUrl,
      uploadedByUid: uid,
      chainEntryRef: appended.entryRef,
      chainSeq: appended.entry.seq,
      entryHash: appended.entry.entryHash,
      classificationLabel: kind === 'physical' ? 'Processed' : 'Processing',
      extractionState: kind === 'physical' ? 'not_applicable' : 'pending',
      reviewReason: isDuplicate ? 'Same bytes as an earlier item on this matter — kept as a second arrival.' : '',
    });
    return appended.entry;
  });

  // Independent timestamp over the item hash (never blocks the receipt).
  try {
    await timestampReceipt({
      db,
      bucket,
      matterRef,
      receiptRef,
      itemHash,
      basePath: storagePath || `matters/${matterRef.id}/receipts/${receiptRef.id}`,
    });
  } catch (e) {
    console.warn('timestamp step failed', e.message);
  }

  return {
    receiptId: receiptRef.id,
    itemHash,
    entryHash: chain.entryHash,
    chainSeq: chain.seq,
    isDuplicate,
    sizeBytes,
  };
});

exports.onReceiptCreated = onDocumentCreated(
  { document: 'Receipts/{receiptId}', secrets: [P.ANTHROPIC_API_KEY], timeoutSeconds: 540, memory: '2GiB' },
  async (event) => {
    const snap = event.data;
    if (!snap || snap.get('extractionState') !== 'pending') return;
    try {
      await processReceipt(processDeps(), snap.ref, { uid: snap.get('uploadedByUid') || null });
    } catch (e) {
      console.error('onReceiptCreated: reading crashed', snap.id, e);
      await snap.ref.set(
        {
          extractionState: 'extraction_failed',
          extractionErrors: [`reading crashed: ${e.message}`],
          classificationLabel: 'Uncertain',
          reviewReason: 'AI reading failed — open the file and review it by hand, or run AI reading again.',
        },
        { merge: true },
      );
    }
  },
);

exports.reprocessReceipt = onCall(
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
    if (!matterRef || !matterRef.id) throw new HttpsError('failed-precondition', 'Receipt has no matter');
    await loadMatterForUser(db, uid, matterRef.id);
    if (snap.get('originalDeletedAt')) {
      throw new HttpsError('failed-precondition', 'The original was delivered to your firm\'s system and removed from Verin, so it can\'t be read again here.');
    }
    if (data.clientSide === 'left' || data.clientSide === 'right') await ref.set({ clientSide: data.clientSide }, { merge: true });
    await ref.set({ extractionState: 'running' }, { merge: true });
    try {
      const r = await processReceipt(processDeps(), ref, { force: data.forceTranscription === true, uid });
      return { status: r.status, errors: r.errors };
    } catch (e) {
      console.error('reprocessReceipt crashed', ref.id, e);
      await ref.set({ extractionState: 'extraction_failed', extractionErrors: [`reading crashed: ${e.message}`] }, { merge: true });
      throw new HttpsError('internal', 'AI reading failed unexpectedly. Check the function logs.');
    }
  },
);

module.exports.physicalRecordBytes = physicalRecordBytes;
module.exports.dateOnly = dateOnly;
module.exports.copyAndHash = copyAndHash;
module.exports.timestampReceipt = timestampReceipt;
module.exports.downloadUrl = downloadUrl;
module.exports.extensionOf = extensionOf;
module.exports.cleanFileName = cleanFileName;
module.exports.cleanText = cleanText;
module.exports.CHANNELS = CHANNELS;
module.exports.processDeps = processDeps;
