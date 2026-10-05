// Verin Legal — files one item that arrived by email or text into a matter:
// stores the exact bytes, hashes them, appends to the matter's hash chain,
// creates the receipt and requests an RFC 3161 timestamp. The same steps the
// app's own upload takes (verin/evidence/ingest.js), for server-side arrivals.

const crypto = require('crypto');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');

const { appendInTransaction } = require('../chain/chain');
const { originFidelityFor } = require('../evidence/video');
const ingest = require('../evidence/ingest');

/**
 * @param {object} o
 * @param {FirebaseFirestore.Firestore} o.db
 * @param {*} o.bucket                 Storage bucket
 * @param {FirebaseFirestore.DocumentReference} o.matterRef
 * @param {Buffer} o.buffer            exact bytes received
 * @param {string} o.fileName
 * @param {string} o.contentType
 * @param {string} o.kind              photo | video | document | email
 * @param {string} o.channelKey        email | sms
 * @param {string} o.fromLabel         who sent it, as shown to staff
 * @param {string} o.senderKey         mail:<email> | tel:<e164> (sender matching)
 * @param {string} o.description
 * @param {string} o.source            chain origin (provider ids, addresses)
 * @param {boolean} o.quarantined      unknown sender: hold AI reading for approval
 * @param {string} [o.reviewReason]
 * @param {Date} [o.receivedAt]
 * @param {object} [o.extra]           more receipt fields (intakeEventId, parentReceiptId…)
 */
async function fileInboundItem(o) {
  const { db, bucket, matterRef } = o;
  const receiptRef = db.collection('Receipts').doc();
  const receivedAt = o.receivedAt || new Date();
  const fileName = ingest.cleanFileName(o.fileName);
  const contentType = String(o.contentType || 'application/octet-stream').slice(0, 120);
  const buffer = o.buffer;
  const itemHash = crypto.createHash('sha256').update(buffer).digest('hex');

  const storagePath = `matters/${matterRef.id}/receipts/${receiptRef.id}${ingest.extensionOf(fileName)}`;
  const token = crypto.randomUUID();
  await bucket.file(storagePath).save(buffer, {
    resumable: buffer.length > 8 * 1024 * 1024,
    contentType,
    metadata: {
      metadata: { firebaseStorageDownloadTokens: token, originalFileName: fileName, receiptId: receiptRef.id, sha256: itemHash, channel: o.channelKey },
    },
  });
  const sourceUrl = ingest.downloadUrl(bucket.name, storagePath, token);

  const dup = await db.collection('Receipts').where('matterId', '==', matterRef).where('item_hash', '==', itemHash).limit(1).get();
  const isDuplicate = !dup.empty;
  const isMedia = o.kind === 'video' || /^video\/|^audio\//.test(contentType);
  const headline = (o.description || fileName).split('\n')[0].slice(0, 160);
  const quarantined = !!o.quarantined;

  const entry = await db.runTransaction(async (tx) => {
    const appended = await appendInTransaction(tx, db, {
      matterRef,
      receiptRef,
      itemHash,
      receivedAt,
      channel: o.channelKey,
      source: o.source,
      serverTimestamp: () => FieldValue.serverTimestamp(),
    });
    tx.set(receiptRef, {
      matterId: matterRef,
      firmID: appended.firmId,
      itemKind: o.kind,
      receivedAt: Timestamp.fromDate(receivedAt),
      channel: ingest.CHANNELS[o.channelKey] || o.channelKey,
      channelKey: o.channelKey,
      content: headline,
      fromLabel: String(o.fromLabel || '').slice(0, 200),
      senderKey: o.senderKey || '',
      description: String(o.description || '').slice(0, 4000),
      custodyNotes: '',
      originalFileName: fileName,
      contentType,
      sizeBytes: buffer.length,
      item_hash: itemHash,
      isDuplicate,
      hasChronologyShift: false,
      isTranscribed: false,
      ...(isMedia ? { originFidelity: originFidelityFor(o.channelKey) } : {}),
      detectedPlatform: '',
      threadMessages: [],
      clientSide: 'right',
      sourceStoragePath: storagePath,
      sourceUrl,
      uploadedByUid: '',
      chainEntryRef: appended.entryRef,
      chainSeq: appended.entry.seq,
      entryHash: appended.entry.entryHash,
      isQuarantined: quarantined,
      classificationLabel: quarantined ? 'Quarantined' : 'Processing',
      extractionState: quarantined ? 'quarantined' : 'pending',
      reviewReason:
        o.reviewReason ||
        (isDuplicate ? 'Same bytes as an earlier item on this matter — kept as a second arrival.' : ''),
      ...(o.extra || {}),
    });
    return appended.entry;
  });

  try {
    await ingest.timestampReceipt({ db, bucket, matterRef, receiptRef, itemHash, basePath: storagePath });
  } catch (e) {
    console.warn('timestamp step failed', receiptRef.id, e.message);
  }
  return { receiptId: receiptRef.id, itemHash, chainSeq: entry.seq, isDuplicate };
}

module.exports = { fileInboundItem };
