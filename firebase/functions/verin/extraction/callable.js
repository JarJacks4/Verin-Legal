// Verin Legal — screenshot intake + AI extraction callables (guide §14).
//
// This replaces FlutterFlow's in-app "AI Agent" for screenshot extraction.
// Running it as Cloud Functions keeps the Anthropic key in Secret Manager
// (never in the app or the repo), hashes the exact bytes server-side the
// moment they arrive, validates the model's output before anything is
// written (§14e), and records every run under <receipt>/extractionRuns.
//
//   ingestScreenshot       app sends the image bytes; the function stores
//                          them, creates the Receipt, appends it to the
//                          matter's hash chain, then extracts the thread.
//   extractThreadMessages  re-runs extraction for an existing Receipt
//                          ("Retry extraction").
//
// One-time setup:  firebase functions:secrets:set ANTHROPIC_API_KEY

const crypto = require('crypto');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

const P = require('../common/params');
const { requireAuth, loadMatterForUser } = require('../common/access');
const { appendInTransaction } = require('../chain/chain');
const { createExtractor, extractFromBytes, resultFields, InputError, MAX_IMAGE_BYTES, STATUS } = require('./extractor');
const { detectImageMediaType, looksLikeHeic } = require('./validate');

if (!getApps().length) initializeApp();

const EXTENSIONS = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/webp': 'webp', 'image/gif': 'gif' };

let cachedClient = null;
function anthropicClient() {
  if (!cachedClient) {
    const mod = require('@anthropic-ai/sdk');
    const Anthropic = mod.default || mod;
    cachedClient = new Anthropic({ apiKey: P.ANTHROPIC_API_KEY.value(), maxRetries: 2, timeout: 120000 });
  }
  return cachedClient;
}

function downloadUrl(bucketName, path, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

function cleanFileName(name) {
  const s = String(name || '').replace(/[\\/\u0000-\u001f]/g, ' ').trim();
  return (s || 'Screenshot').slice(0, 120);
}

exports.ingestScreenshot = onCall(
  { secrets: [P.ANTHROPIC_API_KEY], timeoutSeconds: 180, memory: '512MiB' },
  async (request) => {
    const uid = requireAuth(request);
    const db = getFirestore();
    const data = request.data || {};
    const { ref: matterRef } = await loadMatterForUser(db, uid, data.matterId, P.DEFAULT_FIRM_ID.value());

    if (typeof data.imageBase64 !== 'string' || !data.imageBase64) {
      throw new HttpsError('invalid-argument', 'imageBase64 is required');
    }
    const bytes = Buffer.from(data.imageBase64, 'base64');
    if (!bytes.length) throw new HttpsError('invalid-argument', 'image is empty');
    if (bytes.length > MAX_IMAGE_BYTES) {
      throw new HttpsError('invalid-argument', `Image is ${(bytes.length / 1048576).toFixed(1)} MB; the limit is 7 MB.`);
    }
    const mediaType = detectImageMediaType(bytes);
    if (!mediaType) {
      throw new HttpsError(
        'invalid-argument',
        looksLikeHeic(bytes) ? 'HEIC photos are not supported; upload a PNG or JPEG screenshot.' : 'Upload a PNG, JPEG, WebP or GIF image.',
      );
    }

    const fileName = cleanFileName(data.fileName);
    const clientSide = data.clientSide === 'left' ? 'left' : 'right';
    const itemHash = crypto.createHash('sha256').update(bytes).digest('hex');
    const receivedAt = new Date();

    // Same bytes already filed on this matter? Keep it (it's still evidence it
    // was sent again) but flag it so the Receipts tab and counts can filter it.
    const dup = await db
      .collection('Receipts')
      .where('matterId', '==', matterRef)
      .where('item_hash', '==', itemHash)
      .limit(1)
      .get();
    const isDuplicate = !dup.empty;

    // Store the original bytes first, under a server-chosen path.
    const bucket = getStorage().bucket();
    const receiptRef = db.collection('Receipts').doc();
    const storagePath = `matters/${matterRef.id}/receipts/${receiptRef.id}.${EXTENSIONS[mediaType]}`;
    const token = crypto.randomUUID();
    await bucket.file(storagePath).save(bytes, {
      resumable: false,
      contentType: mediaType,
      metadata: {
        metadata: {
          firebaseStorageDownloadTokens: token,
          sha256: itemHash,
          uploadedBy: uid,
          originalFileName: fileName,
        },
      },
    });
    const sourceUrl = downloadUrl(bucket.name, storagePath, token);

    // Create the receipt and its chain entry atomically.
    const chain = await db.runTransaction(async (tx) => {
      const appended = await appendInTransaction(tx, db, {
        matterRef,
        receiptRef,
        itemHash,
        receivedAt,
        channel: 'Upload',
        source: `uid:${uid}|file:${fileName}`,
        serverTimestamp: () => FieldValue.serverTimestamp(),
      });
      tx.set(receiptRef, {
        matterId: matterRef,
        itemKind: 'screenshot',
        receivedAt: Timestamp.fromDate(receivedAt),
        channel: 'Upload',
        content: fileName,
        classificationLabel: 'Processing',
        item_hash: itemHash,
        isDuplicate,
        hasChronologyShift: false,
        isTranscribed: false,
        originFidelity: 'as_sent',
        detectedPlatform: '',
        threadMessages: [],
        sourceStoragePath: storagePath,
        sourceUrl,
        uploadedByUid: uid,
        chainEntryRef: appended.entryRef,
        chainSeq: appended.entry.seq,
        entryHash: appended.entry.entryHash,
        extractionState: 'pending',
      });
      return appended.entry;
    });

    // Extract. Failures are recorded on the receipt, never thrown away.
    const model = P.EXTRACTION_MODEL.value();
    const result = await extractFromBytes({
      anthropic: anthropicClient(),
      model,
      maxTokens: P.EXTRACTION_MAX_TOKENS.value(),
      bytes,
      clientSide,
      sourceThumbnailUrl: sourceUrl,
    });
    const batch = db.batch();
    batch.set(
      receiptRef,
      resultFields(result, {
        extractionModel: model,
        extractionSourcePath: storagePath,
        extractionSourceSha256: itemHash,
        extractedAt: FieldValue.serverTimestamp(),
      }),
      { merge: true },
    );
    batch.set(receiptRef.collection('extractionRuns').doc(), {
      ...result.audit,
      uid,
      storagePath,
      sourceSha256: itemHash,
      status: result.status,
      errors: result.errors,
      messageCount: result.threadMessages ? result.threadMessages.length : 0,
      createdAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (result.status === STATUS.FAILED) console.warn('ingestScreenshot: extraction failed', receiptRef.id, result.errors);

    return {
      receiptId: receiptRef.id,
      status: result.status,
      messageCount: result.threadMessages ? result.threadMessages.length : 0,
      platform: result.platform || '',
      errors: result.errors,
      itemHash,
      entryHash: chain.entryHash,
      chainSeq: chain.seq,
      isDuplicate,
    };
  },
);

exports.extractThreadMessages = onCall(
  { secrets: [P.ANTHROPIC_API_KEY], timeoutSeconds: 180, memory: '512MiB' },
  async (request) => {
    const uid = requireAuth(request);
    const db = getFirestore();
    const data = request.data || {};
    const collection = data.collection || 'Receipts';

    // Make sure the caller may touch the matter this document belongs to.
    if (typeof data.docId === 'string' && data.docId && !data.docId.includes('/') && ['Receipts', 'Items'].includes(collection)) {
      const snap = await db.collection(collection).doc(data.docId).get();
      const matterRef = snap.exists ? snap.get('matterId') || snap.get('matterID') : null;
      if (matterRef && matterRef.id) {
        await loadMatterForUser(db, uid, matterRef.id, P.DEFAULT_FIRM_ID.value());
      }
    }

    const extractor = createExtractor({
      db,
      bucket: getStorage().bucket(),
      anthropic: anthropicClient(),
      model: P.EXTRACTION_MODEL.value(),
      maxTokens: P.EXTRACTION_MAX_TOKENS.value(),
      serverTimestamp: () => FieldValue.serverTimestamp(),
      allowedCollections: ['Receipts', 'Items'],
      log: console,
    });
    try {
      return await extractor.run({
        uid,
        collection,
        docId: data.docId,
        storagePath: data.storagePath,
        imageUrl: data.imageUrl,
        clientSide: data.clientSide === 'left' ? 'left' : 'right',
      });
    } catch (e) {
      if (e instanceof InputError) throw new HttpsError('invalid-argument', e.message);
      if (e instanceof HttpsError) throw e;
      console.error('extractThreadMessages crashed', e);
      throw new HttpsError('internal', 'Extraction failed unexpectedly. Check the function logs.');
    }
  },
);
