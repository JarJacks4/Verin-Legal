// Verin Legal — closed-matter import ("Archive Build", checklist #4).
//
// A firm's closed matter goes in as one upload — a ZIP of a folder, an email
// export (.mbox), single emails (.eml) or any files — and every file inside
// becomes its own item, hashed, chained and timestamped on arrival exactly
// like client intake, then read by the same pipeline. Nothing is guessed:
// unreadable files are kept and flagged.
//
//   importClosedMatter   { matterId, uploadPath, fileName, offset? }
//                        → { found, filed, skipped, nextOffset, importId }
//                        Large archives continue from nextOffset.
//   standingRecordCounts { matterId } → the four demo counts:
//                        items received, distinct dated items, conversations
//                        rebuilt, items flagged (+ still reading).

const path = require('path');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

const { requireAuth, loadMatterForUser } = require('../common/access');
const { fileInboundItem } = require('../intake/file');
const N = require('../intake/normalize');

if (!getApps().length) initializeApp();

const MAX_ARCHIVE_BYTES = 1024 * 1024 * 1024; // 1 GB per upload
const BATCH = 400; // items per call; the app continues from nextOffset
const SKIP = [/(^|\/)__MACOSX\//, /(^|\/)\.DS_Store$/, /(^|\/)Thumbs\.db$/i, /(^|\/)desktop\.ini$/i, /(^|\/)\._/];

const CONTENT_TYPES = {
  '.pdf': 'application/pdf',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.heic': 'image/heic',
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.m4a': 'audio/mp4',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.eml': 'message/rfc822',
  '.msg': 'application/vnd.ms-outlook',
  '.txt': 'text/plain',
  '.csv': 'text/csv',
  '.doc': 'application/msword',
  '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};
const contentTypeFor = (name) => CONTENT_TYPES[path.extname(name || '').toLowerCase()] || 'application/octet-stream';

/// Splits an mbox file into individual RFC 822 messages.
function splitMbox(buf) {
  const text = buf.toString('latin1');
  const parts = text.split(/\r?\n(?=From [^\r\n]*\r?\n)/);
  return parts
    .map((p) => p.replace(/^From [^\r\n]*\r?\n/, ''))
    .filter((p) => p.trim().length)
    .map((p) => Buffer.from(p.replace(/^>(>*From )/gm, '$1'), 'latin1'));
}

/// Every evidence file inside an upload: [{ name, path, load: () => Buffer }].
async function listEntries(buffer, fileName) {
  const ext = path.extname(fileName || '').toLowerCase();
  if (ext === '.zip') {
    const JSZip = require('jszip');
    const zip = await JSZip.loadAsync(buffer);
    const out = [];
    const files = Object.values(zip.files).filter((f) => !f.dir && !SKIP.some((re) => re.test(f.name)));
    files.sort((a, b) => a.name.localeCompare(b.name));
    for (const f of files) {
      if (path.extname(f.name).toLowerCase() === '.mbox') {
        const msgs = splitMbox(await f.async('nodebuffer'));
        msgs.forEach((m, i) => out.push({ name: `${path.basename(f.name, '.mbox')}-${String(i + 1).padStart(4, '0')}.eml`, path: `${f.name}#${i + 1}`, load: async () => m }));
      } else {
        out.push({ name: path.basename(f.name), path: f.name, load: () => f.async('nodebuffer') });
      }
    }
    return out;
  }
  if (ext === '.mbox') {
    return splitMbox(buffer).map((m, i) => ({ name: `message-${String(i + 1).padStart(4, '0')}.eml`, path: `${fileName}#${i + 1}`, load: async () => m }));
  }
  return [{ name: fileName, path: fileName, load: async () => buffer }];
}

exports.importClosedMatter = onCall({ timeoutSeconds: 540, memory: '4GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  const { ref: matterRef, snap } = await loadMatterForUser(db, uid, data.matterId);
  const uploadPath = String(data.uploadPath || '');
  if (!uploadPath.startsWith(`intake/${uid}/`) || uploadPath.includes('..')) {
    throw new HttpsError('invalid-argument', 'uploadPath must be your own upload.');
  }
  const src = bucket.file(uploadPath);
  const [exists] = await src.exists();
  if (!exists) throw new HttpsError('not-found', 'The upload was not found. Try uploading again.');
  const [meta] = await src.getMetadata();
  if (Number(meta.size || 0) > MAX_ARCHIVE_BYTES) throw new HttpsError('invalid-argument', 'Archives over 1 GB: split the folder into parts and import each one.');
  const [buffer] = await src.download();
  const fileName = require('../evidence/ingest').cleanFileName(data.fileName || uploadPath.split('/').pop());

  let entries;
  try {
    entries = await listEntries(buffer, fileName);
  } catch (e) {
    throw new HttpsError('invalid-argument', `That file could not be opened as an archive: ${e.message}`);
  }
  const offset = Math.max(0, Number(data.offset) || 0);
  const importRef = data.importId ? matterRef.collection('archiveImports').doc(String(data.importId).slice(0, 60)) : matterRef.collection('archiveImports').doc();
  if (!offset) {
    await importRef.set({ fileName, uploadPath, found: entries.length, filed: 0, skipped: 0, startedAt: FieldValue.serverTimestamp(), startedByUid: uid, status: 'running' });
    await matterRef.set({ isArchiveBuild: true, archiveBuildStartedAt: snap.get('archiveBuildStartedAt') || FieldValue.serverTimestamp() }, { merge: true });
  }

  const slice = entries.slice(offset, offset + BATCH);
  let filed = 0;
  let skipped = 0;
  for (const e of slice) {
    try {
      const bytes = await e.load();
      if (!bytes || !bytes.length) {
        skipped++;
        continue;
      }
      const ct = contentTypeFor(e.name);
      await fileInboundItem({
        db,
        bucket,
        matterRef,
        buffer: bytes,
        fileName: e.name,
        contentType: ct,
        kind: N.kindFor(ct, e.name),
        channelKey: 'upload',
        fromLabel: 'Closed-matter import',
        senderKey: '',
        description: e.path,
        source: `archive|uid:${uid}|file:${fileName}|entry:${e.path}`,
        quarantined: false,
        extra: { archiveImportId: importRef.id, archivePath: e.path, uploadedByUid: uid },
      });
      filed++;
    } catch (err) {
      console.warn('archive entry failed', e.path, err.message);
      skipped++;
    }
  }
  const nextOffset = offset + slice.length < entries.length ? offset + slice.length : null;
  await importRef.set(
    {
      filed: FieldValue.increment(filed),
      skipped: FieldValue.increment(skipped),
      status: nextOffset === null ? 'filed' : 'running',
      ...(nextOffset === null ? { finishedAt: FieldValue.serverTimestamp() } : {}),
    },
    { merge: true },
  );
  if (nextOffset === null) await src.delete().catch(() => {});
  return { importId: importRef.id, found: entries.length, filed, skipped, nextOffset };
});

const FLAGGED = new Set(['uncertain', 'unreadable', 'quarantined']);

/// The four numbers shown at the end of a closed-matter demo.
function countsFrom(receipts, thread) {
  const items = receipts.length;
  const reading = receipts.filter((r) => ['pending', 'running'].includes(String(r.extractionState || '')) || String(r.classificationLabel || '') === 'Processing').length;
  const dated = new Set();
  for (const r of receipts) {
    if (r.isDuplicate === true) continue;
    if (r.resolvedDate || (Array.isArray(r.threadMessages) && r.threadMessages.some((m) => m && m.timestamp))) dated.add(r.item_hash || r.id);
  }
  const flagged = receipts.filter((r) => FLAGGED.has(String(r.classificationLabel || '').toLowerCase()) || r.isQuarantined === true || (r.reviewReason && !r.reviewResolvedAt)).length;
  const stats = (thread && thread.stats) || {};
  return {
    itemsReceived: items,
    distinctDatedItems: dated.size,
    conversationsRebuilt: stats.messages ? stats.runs || 1 : 0,
    messagesRebuilt: stats.messages || 0,
    itemsFlagged: flagged,
    stillReading: reading,
  };
}

exports.standingRecordCounts = onCall(async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref } = await loadMatterForUser(db, uid, (request.data || {}).matterId);
  const [rs, t] = await Promise.all([db.collection('Receipts').where('matterId', '==', ref).get(), ref.collection('derived').doc('thread').get()]);
  return countsFrom(rs.docs.map((d) => ({ id: d.id, ...d.data() })), t.exists ? t.data() : null);
});

exports._internal = { splitMbox, listEntries, countsFrom, contentTypeFor };
