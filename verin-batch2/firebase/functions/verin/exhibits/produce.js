// Verin Legal — reviewable exhibit production (Differentiator 5).
//
// Staff assemble a production as a draft (Matters/{id}/productions/{pid}):
// which items, in what order, and the redactions they reviewed. Producing it:
//
//   1. builds each exhibit from the original in Storage — images and
//      redacted PDF pages as pixels with redactions burned in, text documents
//      and emails typeset, recordings and other files produced natively;
//   2. reserves a Bates range on the matter (numbers never reused);
//   3. adds slip sheets with source references and stamps every page;
//   4. writes production.pdf, one PDF per exhibit, the exhibit index (PDF and
//      CSV), natives, and a manifest with every hash into a versioned ZIP.
//
// A produced version is final and never changes. Re-producing makes a new
// version with new Bates numbers; earlier versions stay downloadable.

const crypto = require('crypto');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { initializeApp, getApps } = require('firebase-admin/app');

const { requireAuth, loadMatterForUser, assertDocId } = require('../common/access');
const { detectKind, extractText } = require('../evidence/docs');
const { jpegOrientation } = require('../evidence/source');
const { resolveTemplate, exhibitLabel, ascii } = require('./template');
const R = require('./render');
const S = require('./stamp');

if (!getApps().length) initializeApp();

const sha256 = (b) => crypto.createHash('sha256').update(b).digest('hex');
const MAX_RENDER_BYTES = 60 * 1024 * 1024;

function iso(ts) {
  if (!ts) return '';
  const d = typeof ts.toDate === 'function' ? ts.toDate() : new Date(ts);
  return Number.isNaN(d.getTime()) ? '' : d.toISOString();
}
function day(ts) {
  return iso(ts).slice(0, 10);
}

function tokenUrl(bucket, path, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

async function saveFile(bucket, path, bytes, contentType, fileName) {
  const token = crypto.randomUUID();
  await bucket.file(path).save(bytes, {
    resumable: false,
    contentType,
    metadata: { contentDisposition: `attachment; filename="${fileName}"`, metadata: { firebaseStorageDownloadTokens: token } },
  });
  return { path, url: tokenUrl(bucket, path, token), sha256: sha256(bytes), bytes: bytes.length };
}

function safeName(s) {
  return ascii(s, 80).replace(/[^A-Za-z0-9 ._-]/g, '_').trim() || 'file';
}

/// Normalizes the reviewed redactions stored on a draft item.
function itemRedactions(it) {
  const boxes = Array.isArray(it.redactions) ? it.redactions : [];
  const pageBoxes = {};
  const imageBoxes = [];
  for (const r of boxes) {
    const b = r && r.box;
    if (!b || ![b.x, b.y, b.w, b.h].every((v) => typeof v === 'number' && Number.isFinite(v)) || b.w <= 0 || b.h <= 0) continue;
    const page = Number.isInteger(r.page) && r.page > 0 ? r.page : 0;
    if (page) (pageBoxes[page] = pageBoxes[page] || []).push(b);
    else imageBoxes.push(b);
  }
  const textRedactions = (Array.isArray(it.textRedactions) ? it.textRedactions : []).filter((t) => typeof t === 'string' && t.trim().length >= 2).map((t) => t.trim());
  return { pageBoxes, imageBoxes, textRedactions, count: imageBoxes.length + Object.values(pageBoxes).reduce((n, l) => n + l.length, 0) + textRedactions.length };
}

/// Builds one exhibit's pages (unstamped) from its original.
async function buildExhibit(bucket, receipt, it) {
  const red = itemRedactions(it);
  const path = receipt.sourceStoragePath || '';
  if (!path) return { bytes: null, pages: 0, native: null, redactions: 0, note: 'physical item — slip sheet only' };
  const file = bucket.file(path);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError('failed-precondition', `The stored original for "${receipt.originalFileName || receipt.id}" is missing.`);
  const [meta] = await file.getMetadata();
  const size = Number(meta.size || 0);
  const name = receipt.originalFileName || path.split('/').pop();
  const native = { path, name, size };
  const head = await new Promise((resolve, reject) => {
    const chunks = [];
    file.createReadStream({ start: 0, end: 63 }).on('data', (c) => chunks.push(c)).on('error', reject).on('end', () => resolve(Buffer.concat(chunks)));
  });
  const kind = detectKind(head, name, receipt.contentType || meta.contentType);
  if (!['image', 'pdf', 'docx', 'odt', 'rtf', 'text', 'eml', 'msg'].includes(kind) || size > MAX_RENDER_BYTES) {
    return { bytes: null, pages: 0, native, redactions: 0, note: `produced in native format (${kind})`, nativeOnly: true, kind };
  }
  const [bytes] = await file.download();
  if (kind === 'image') {
    const orientation = head[0] === 0xff && head[1] === 0xd8 ? jpegOrientation(bytes) : 1;
    const out = await R.imageToPdf(bytes, { boxes: red.imageBoxes, orientation, photo: receipt.itemKind === 'photo' });
    return { ...out, native: null, redactions: red.imageBoxes.length, kind };
  }
  if (kind === 'pdf') {
    const out = await R.pdfToExhibit(bytes, { pageBoxes: red.pageBoxes, textRedactions: red.textRedactions });
    return { ...out, native: null, redactions: red.count, kind };
  }
  // Text documents and emails: typeset the full text with redactions applied.
  let text = typeof receipt.documentText === 'string' && !receipt.documentTextTruncated ? receipt.documentText : '';
  if (!text) {
    const t = await extractText(kind, bytes);
    if (!t.ok || t.truncated || !t.text.trim()) {
      return { bytes: null, pages: 0, native, redactions: 0, note: 'produced in native format (text could not be typeset in full)', nativeOnly: true, kind };
    }
    text = t.text;
  }
  const out = await R.textToPdf(text, { title: name, textRedactions: red.textRedactions });
  return { ...out, native: null, redactions: red.textRedactions.length, kind };
}

exports.produceExhibits = onCall({ timeoutSeconds: 540, memory: '4GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  const { ref: matterRef, snap: matterSnap, firmId } = await loadMatterForUser(db, uid, data.matterId);
  assertDocId(data.productionId, 'productionId');
  const prodRef = matterRef.collection('productions').doc(data.productionId);
  const prodSnap = await prodRef.get();
  if (!prodSnap.exists) throw new HttpsError('not-found', 'Production not found');
  const prod = prodSnap.data();
  if (prod.status !== 'draft') throw new HttpsError('failed-precondition', 'This production is already final. Start a new version to change it.');

  const acct = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  const template = resolveTemplate(acct.empty ? null : acct.docs[0].get('productionTemplate'));

  const items = (Array.isArray(prod.items) ? prod.items : []).filter((it) => it && it.include !== false && typeof it.receiptId === 'string');
  if (!items.length) throw new HttpsError('invalid-argument', 'Add at least one item to the production.');
  if (items.length > 500) throw new HttpsError('invalid-argument', 'A production is limited to 500 exhibits.');

  // Build every exhibit from its original.
  const built = [];
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    assertDocId(it.receiptId, 'receiptId');
    const rs = await db.collection('Receipts').doc(it.receiptId).get();
    if (!rs.exists) throw new HttpsError('not-found', `An item in the production no longer exists (${it.receiptId}).`);
    const receipt = { id: rs.id, ...rs.data() };
    if (!receipt.matterId || receipt.matterId.path !== matterRef.path) throw new HttpsError('permission-denied', 'An item in the production belongs to another matter.');
    const ex = await buildExhibit(bucket, receipt, it);
    built.push({
      n: i + 1,
      receipt,
      ex,
      item: {
        description: ascii(it.description || receipt.aiSummary || receipt.content || receipt.originalFileName || receipt.itemKind || 'Item', 300),
        fileName: receipt.originalFileName || '',
        receivedAt: iso(receipt.receivedAt).replace('T', ' ').slice(0, 16) + (receipt.receivedAt ? ' UTC' : ''),
        channel: receipt.channel || '',
        from: receipt.fromLabel || '',
        itemDate: day(receipt.resolvedDate),
        chainSeq: receipt.chainSeq || null,
        tsa: receipt.tsaName || '',
        sha256: receipt.item_hash || receipt.itemHash || '',
        redactions: ex.redactions || 0,
      },
    });
  }
  const exhibits = built.map((b) => ({ n: b.n, item: b.item, bytes: b.ex.bytes, pages: b.ex.pages }));
  const totalPages = exhibits.reduce((n, e) => n + S.pageCount(e, template), 0);

  // Reserve the Bates range and the version number together.
  const { start, version } = await db.runTransaction(async (tx) => {
    const m = await tx.get(matterRef);
    const s = Number(m.get('batesNext')) > 0 ? Number(m.get('batesNext')) : 1;
    const v = (Number(m.get('productionCount')) || 0) + 1;
    tx.update(matterRef, { batesNext: s + totalPages, productionCount: v });
    return { start: s, version: v };
  });

  const assembled = await S.assemble(exhibits, template, start);
  const producedAt = new Date();
  const matter = matterSnap.data();
  const matterTitle = matter.matterName || matter.caseTitle || matter.title || 'Matter';
  const by = (await db.collection('users').doc(uid).get()).get('display_name') || request.auth.token.email || uid;

  const rows = assembled.perExhibit.map((p, i) => ({
    label: p.label,
    firstBates: p.firstBates,
    lastBates: p.lastBates,
    pages: p.pages,
    ...built[i].item,
    source: [built[i].item.channel, built[i].item.receivedAt.slice(0, 10)].filter(Boolean).join(' · '),
    producedSha256: sha256(p.bytes),
    receiptId: built[i].receipt.id,
    native: built[i].ex.native ? built[i].ex.native.name : '',
    note: built[i].ex.note || '',
  }));
  const index = await S.indexPdf(rows, { title: template.indexTitle, matterTitle, producedAt: producedAt.toISOString().slice(0, 10), version, legend: template.legend });
  const csv = Buffer.from(S.indexCsv(rows), 'utf8');

  const base = `matters/${matterRef.id}/productions/${prodRef.id}/v${version}`;
  const stem = `${safeName(template.batesPrefix)}_production_v${version}`;
  const pdfFile = await saveFile(bucket, `${base}/${stem}.pdf`, assembled.combined, 'application/pdf', `${stem}.pdf`);
  const indexFile = await saveFile(bucket, `${base}/${stem}_index.pdf`, index, 'application/pdf', `${stem}_index.pdf`);

  const manifest = {
    format: 'verin-production/1',
    matter: { id: matterRef.id, title: matterTitle },
    production: { id: prodRef.id, name: prod.name || '', version, producedAt: producedAt.toISOString(), producedBy: by },
    template,
    bates: { first: assembled.perExhibit[0].firstBates, last: assembled.perExhibit[assembled.perExhibit.length - 1].lastBates, pages: totalPages },
    exhibits: rows.map((r) => ({
      label: r.label,
      receiptId: r.receiptId,
      bates: [r.firstBates, r.lastBates],
      pages: r.pages,
      originalFile: r.fileName,
      originalSha256: r.sha256,
      producedSha256: r.producedSha256,
      redactions: r.redactions,
      chainEntry: r.chainSeq,
      native: r.native || null,
      note: r.note || null,
    })),
    files: { production: { name: `${stem}.pdf`, sha256: pdfFile.sha256 }, index: { name: `${stem}_index.pdf`, sha256: indexFile.sha256 } },
  };
  const readme = [
    `${template.indexTitle} — ${matterTitle} — production v${version}`,
    '',
    `${stem}.pdf            every exhibit, slip sheets and Bates stamps, in order`,
    `${stem}_index.pdf      the exhibit index (Bates ranges, sources, hashes)`,
    'index.csv              the same index as a spreadsheet',
    'exhibits/              one PDF per exhibit',
    'natives/               files produced in their original format',
    'manifest.json          everything above with SHA-256 hashes',
    '',
    'originalSha256 is the hash of the item as received (it matches the matter\'s hash chain);',
    'producedSha256 is the hash of the produced exhibit PDF, which may include redactions.',
    '',
  ].join('\n');

  // ZIP: streamed to Storage; natives streamed straight from their originals.
  const archiver = require('archiver');
  const zip = archiver('zip', { zlib: { level: 6 } });
  zip.append(assembled.combined, { name: `${stem}.pdf` });
  zip.append(index, { name: `${stem}_index.pdf` });
  zip.append(csv, { name: 'index.csv' });
  zip.append(readme, { name: 'README.txt' });
  assembled.perExhibit.forEach((p) => zip.append(p.bytes, { name: `exhibits/${safeName(p.label)}.pdf` }));
  for (const b of built) {
    if (b.ex.native) {
      const label = exhibitLabel(b.n, template);
      zip.append(bucket.file(b.ex.native.path).createReadStream(), { name: `natives/${safeName(label)} - ${safeName(b.ex.native.name)}` });
    }
  }
  zip.append(JSON.stringify(manifest, null, 2), { name: 'manifest.json' });
  const token = crypto.randomUUID();
  const zipPath = `${base}/${stem}.zip`;
  const hash = crypto.createHash('sha256');
  let zipBytes = 0;
  zip.on('data', (c) => {
    hash.update(c);
    zipBytes += c.length;
  });
  const writing = new Promise((resolve, reject) => {
    zip.on('error', reject);
    zip
      .pipe(
        bucket.file(zipPath).createWriteStream({
          resumable: false,
          contentType: 'application/zip',
          metadata: { contentDisposition: `attachment; filename="${stem}.zip"`, metadata: { firebaseStorageDownloadTokens: token } },
        }),
      )
      .on('finish', resolve)
      .on('error', reject);
  });
  await zip.finalize();
  await writing;
  const zipFile = { path: zipPath, url: tokenUrl(bucket, zipPath, token), sha256: hash.digest('hex'), bytes: zipBytes };

  const out = {
    status: 'final',
    version,
    finalizedAt: FieldValue.serverTimestamp(),
    finalizedBy: uid,
    finalizedByName: by,
    batesStart: manifest.bates.first,
    batesEnd: manifest.bates.last,
    pageCount: totalPages,
    template,
    exhibits: rows.map((r) => ({
      label: r.label,
      receiptId: r.receiptId,
      firstBates: r.firstBates,
      lastBates: r.lastBates,
      pages: r.pages,
      redactions: r.redactions,
      producedSha256: r.producedSha256,
      note: r.note,
    })),
    files: { zip: zipFile, pdf: pdfFile, index: indexFile },
  };
  await prodRef.update(out);
  await db.collection('Activity').add({
    firmID: firmId,
    matterId: matterRef,
    uid,
    type: 'export',
    exportKind: 'production',
    exhibits: rows.length,
    pages: totalPages,
    redactions: rows.reduce((n, r) => n + (r.redactions || 0), 0),
    at: FieldValue.serverTimestamp(),
  });
  return { version, batesStart: out.batesStart, batesEnd: out.batesEnd, pages: totalPages, zipUrl: zipFile.url, pdfUrl: pdfFile.url, indexUrl: indexFile.url };
});

exports.buildExhibit = buildExhibit;
exports.itemRedactions = itemRedactions;
