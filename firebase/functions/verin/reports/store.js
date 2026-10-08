// Saves a generated report to Storage with a download token and records it.
const crypto = require('crypto');
const { firmDocRef } = require('../common/firm');
const { FieldValue } = require('firebase-admin/firestore');

async function saveReport({ db, bucket, firmId, storagePath, bytes, contentType, fileName, uid, kind, extra = {} }) {
  const token = crypto.randomUUID();
  const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
  await bucket.file(storagePath).save(bytes, {
    resumable: false,
    contentType,
    metadata: { contentDisposition: `attachment; filename="${fileName}"`, metadata: { firebaseStorageDownloadTokens: token, sha256, generatedBy: uid || 'system' } },
  });
  const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(storagePath)}?alt=media&token=${token}`;
  if (db && firmId) {
    await (await firmDocRef(db, firmId))
      .collection('reports')
      .add({ kind, fileName, storagePath, sha256, bytes: bytes.length, contentType, generatedByUid: uid || 'system', generatedAt: FieldValue.serverTimestamp(), ...extra })
      .catch((e) => console.warn('report record failed', e.message));
  }
  return { downloadUrl, sha256, fileName, storagePath };
}

const stampOf = (d) => d.toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
const slug = (s) =>
  String(s || 'report')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 60) || 'report';

module.exports = { saveReport, stampOf, slug };
