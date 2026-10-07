// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const T = require('../exhibits/template');
const R = require('../exhibits/render');
const S = require('../exhibits/stamp');

const imgs = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures/images.json'), 'utf8'));

test('template: safe defaults, firm overrides, labels', () => {
  const t = T.resolveTemplate({ batesPrefix: 'harbow law!', batesDigits: 7, exhibitStyle: 'letter', legend: 'CONFIDENTIAL — PO' });
  assert.equal(t.batesPrefix, 'HARBOWLAW');
  assert.equal(t.legend, 'CONFIDENTIAL - PO');
  assert.equal(T.batesLabel(42, t), 'HARBOWLAW-0000042');
  assert.equal(T.exhibitLabel(1, t), 'Exhibit A');
  assert.equal(T.exhibitLabel(28, t), 'Exhibit AB');
  const d = T.resolveTemplate(null);
  assert.equal(T.batesLabel(1, d), 'VERIN-000001');
  assert.equal(T.exhibitLabel(3, d), 'Exhibit 3');
  assert.equal(T.resolveTemplate({ batesDigits: 99 }).batesDigits, 10);
});

async function pdfText(bytes) {
  const pdf = await R.openPdfjs(bytes);
  let all = '';
  for (let p = 1; p <= pdf.numPages; p++) {
    const tc = await (await pdf.getPage(p)).getTextContent();
    all += tc.items.map((i) => i.str).join(' ') + '\n';
  }
  await pdf.destroy();
  return all;
}

async function samplePdf(lines) {
  const PDFKit = require('pdfkit');
  const doc = new PDFKit({ size: 'LETTER' });
  const chunks = [];
  doc.on('data', (c) => chunks.push(c));
  const done = new Promise((r) => doc.on('end', r));
  lines.forEach((l, i) => {
    if (i) doc.addPage();
    doc.fontSize(14).text(l);
  });
  doc.end();
  await done;
  return Buffer.concat(chunks);
}

test('redaction burns into pixels: the text is gone, not covered', async () => {
  const src = await samplePdf(['Name: Jane Doe. SSN 123-45-6789. Account 000111222.', 'Page two has nothing to hide.']);
  assert.match(await pdfText(src), /123-45-6789/);
  const out = await R.pdfToExhibit(src, { textRedactions: ['123-45-6789'] });
  assert.equal(out.pages, 2);
  assert.equal(out.rasterizedPages, 1);
  const text = await pdfText(out.bytes);
  assert.doesNotMatch(text, /123-45-6789/);
  assert.doesNotMatch(text, /Jane Doe/); // the whole redacted page is pixels now
  assert.match(text, /nothing to hide/); // untouched pages keep their text
});

test('image exhibits: one page, redaction painted into the pixels', async () => {
  const { loadImage } = require('@napi-rs/canvas');
  const png = Buffer.from(imgs.PNG, 'base64'); // 37x21 solid colour
  const r = await R.rasterImage(png, { boxes: [{ x: 0, y: 0, w: 0.5, h: 0.5 }] });
  const img = await loadImage(r.bytes);
  const { createCanvas } = require('@napi-rs/canvas');
  const cv = createCanvas(img.width, img.height);
  const ctx = cv.getContext('2d');
  ctx.drawImage(img, 0, 0);
  assert.deepEqual([...ctx.getImageData(2, 2, 1, 1).data].slice(0, 3), [0, 0, 0]); // redacted
  assert.notDeepEqual([...ctx.getImageData(34, 18, 1, 1).data].slice(0, 3), [0, 0, 0]); // untouched
  const pdf = await R.imageToPdf(png, {});
  assert.equal(pdf.pages, 1);
});

test('text documents: redacted strings are replaced, never just hidden', async () => {
  assert.equal(R.redactText('Call me at 555-201-3344 tomorrow', ['555-201-3344']), 'Call me at ████████████ tomorrow');
  const out = await R.textToPdf('Child: Emma Doe, born 01/02/2015.', { textRedactions: ['Emma Doe', '01/02/2015'] });
  const text = await pdfText(out.bytes);
  assert.doesNotMatch(text, /Emma|01\/02\/2015/);
});

test('assemble: slip sheets, continuous Bates, exhibit stamps, natives', async () => {
  const tpl = T.resolveTemplate({ batesPrefix: 'HARBOW', legend: 'CONFIDENTIAL' });
  const one = await R.textToPdf('First exhibit text.');
  const two = await samplePdf(['A', 'B']);
  const exhibits = [
    { n: 1, item: { description: 'Letter', sha256: 'a'.repeat(64) }, bytes: one.bytes, pages: one.pages },
    { n: 2, item: { description: 'Two pages', sha256: 'b'.repeat(64) }, bytes: two, pages: 2 },
    { n: 3, item: { description: 'Video', sha256: 'c'.repeat(64) }, bytes: null, pages: 0 },
  ];
  const total = exhibits.reduce((n, e) => n + S.pageCount(e, tpl), 0);
  const out = await S.assemble(exhibits, tpl, 101);
  assert.equal(out.perExhibit[0].firstBates, 'HARBOW-000101');
  assert.equal(out.perExhibit[1].firstBates, 'HARBOW-000103');
  assert.equal(out.perExhibit[1].lastBates, 'HARBOW-000105');
  assert.equal(out.perExhibit[2].pages, 1); // slip sheet for the native file
  assert.equal(out.nextBates, 101 + total);
  const text = await pdfText(out.combined);
  assert.match(text, /HARBOW-000101/);
  assert.match(text, /Exhibit 2/);
  assert.match(text, /CONFIDENTIAL/);
  const idx = await S.indexPdf(
    out.perExhibit.map((p, i) => ({ ...p, description: exhibits[i].item.description, sha256: exhibits[i].item.sha256, producedSha256: 'd'.repeat(64) })),
    { title: 'Exhibit Index', matterTitle: 'Doe v. Doe', producedAt: '2026-10-05', version: 1 },
  );
  assert.match(await pdfText(idx), /HARBOW-000103 - HARBOW-000105/);
  const csv = S.indexCsv([{ label: 'Exhibit 1', firstBates: 'X-1', lastBates: 'X-2', pages: 2, description: 'Has, a comma', sha256: 'a' }]);
  assert.match(csv, /"Has, a comma"/);
});

const { Readable } = require('stream');
function fakeBucket(files) {
  return {
    name: 'test-bucket',
    file: (p) => ({
      exists: async () => [p in files],
      getMetadata: async () => [{ size: files[p].bytes.length, contentType: files[p].type }],
      download: async () => [files[p].bytes],
      createReadStream: ({ start = 0, end } = {}) => Readable.from([files[p].bytes.subarray(start, end === undefined ? undefined : end + 1)]),
    }),
  };
}

test('buildExhibit: images and PDFs become pages, recordings are produced natively', async () => {
  // Loaded lazily so the firebase-admin import in produce.js isn't needed for the pure parts.
  const Module = require('module');
  const realLoad = Module._load;
  Module._load = function (req) {
    if (req === 'firebase-admin/firestore') return { getFirestore: () => null, FieldValue: {} };
    if (req === 'firebase-admin/storage') return { getStorage: () => null };
    if (req === 'firebase-admin/app') return { initializeApp: () => null, getApps: () => [1] };
    return realLoad.apply(this, arguments);
  };
  const P = require('../exhibits/produce');
  Module._load = realLoad;

  const pdf = await samplePdf(['SSN 123-45-6789']);
  const bucket = fakeBucket({
    'm/a.png': { bytes: Buffer.from(imgs.PNG, 'base64'), type: 'image/png' },
    'm/b.pdf': { bytes: pdf, type: 'application/pdf' },
    'm/c.mp4': { bytes: Buffer.concat([Buffer.from([0, 0, 0, 24]), Buffer.from('ftypmp42'), Buffer.alloc(64)]), type: 'video/mp4' },
  });
  const img = await P.buildExhibit(bucket, { id: 'A', sourceStoragePath: 'm/a.png', originalFileName: 'a.png' }, { redactions: [{ page: 0, box: { x: 0, y: 0, w: 0.3, h: 0.3 } }] });
  assert.equal(img.pages, 1);
  assert.equal(img.redactions, 1);
  const doc = await P.buildExhibit(bucket, { id: 'B', sourceStoragePath: 'm/b.pdf', originalFileName: 'b.pdf' }, { textRedactions: ['123-45-6789'] });
  assert.equal(doc.rasterizedPages, 1);
  assert.doesNotMatch(await pdfText(doc.bytes), /123-45-6789/);
  const vid = await P.buildExhibit(bucket, { id: 'C', sourceStoragePath: 'm/c.mp4', originalFileName: 'c.mp4' }, {});
  assert.equal(vid.bytes, null);
  assert.equal(vid.native.name, 'c.mp4');
  const phys = await P.buildExhibit(bucket, { id: 'D' }, {});
  assert.equal(phys.bytes, null);
  assert.equal(phys.native, null);

  const red = P.itemRedactions({ redactions: [{ page: 2, box: { x: 0.1, y: 0.1, w: 0.2, h: 0.05 } }, { box: { x: 0, y: 0, w: 0, h: 0 } }], textRedactions: ['ab', 'x'] });
  assert.deepEqual(Object.keys(red.pageBoxes), ['2']);
  assert.equal(red.count, 2);
});
