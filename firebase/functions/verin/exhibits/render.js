// Verin Legal — turning each received item into exhibit pages, with
// redactions burned in.
//
// A redaction drawn over a PDF is not a redaction: the text is still there
// underneath. So every page that has a redaction is rendered to pixels, the
// boxes are painted black into those pixels, and only the picture goes into
// the exhibit. Pages without redactions are copied untouched (text stays
// selectable). Photos and screenshots are always pixels; text documents and
// emails are typeset with redacted strings replaced by solid blocks.
//
// The received original is never modified — exhibits are new files, and the
// index records the SHA-256 of both.

const path = require('path');

const LETTER = { w: 612, h: 792 };
const MARGIN = 36;
const STAMP_BAND = 34; // keep the bottom clear for the Bates stamp
const RASTER_SCALE = 200 / 72; // 200 dpi for redacted PDF pages

let _canvas = null;
function canvasLib() {
  if (!_canvas) _canvas = require('@napi-rs/canvas');
  return _canvas;
}

let _pdfjs = null;
async function pdfjsLib() {
  if (!_pdfjs) _pdfjs = await import('pdfjs-dist/legacy/build/pdf.mjs');
  return _pdfjs;
}

function pdfLib() {
  return require('pdf-lib');
}

/// Paints normalized boxes black on a 2D context of size (w, h). A little
/// padding so anti-aliased edges of glyphs don't peek out.
function paintBoxes(ctx, boxes, w, h) {
  ctx.fillStyle = '#000000';
  for (const b of boxes || []) {
    const pad = Math.max(2, Math.round(Math.min(w, h) * 0.003));
    const x = Math.max(0, Math.floor(b.x * w) - pad);
    const y = Math.max(0, Math.floor(b.y * h) - pad);
    const bw = Math.min(w - x, Math.ceil(b.w * w) + pad * 2);
    const bh = Math.min(h - y, Math.ceil(b.h * h) + pad * 2);
    if (bw > 0 && bh > 0) ctx.fillRect(x, y, bw, bh);
  }
}

/// Fits (w, h) inside the page's printable area, keeping aspect.
function fit(w, h, page) {
  const maxW = page.w - MARGIN * 2;
  const maxH = page.h - MARGIN - STAMP_BAND - MARGIN;
  const s = Math.min(maxW / w, maxH / h, 1.5);
  return { w: w * s, h: h * s, x: (page.w - w * s) / 2, y: STAMP_BAND + MARGIN + (maxH - h * s) / 2 };
}

/// Draws an image with its EXIF orientation applied, then the redactions.
/// Returns { png|jpeg bytes, width, height }.
async function rasterImage(bytes, { boxes = [], orientation = 1, photo = false } = {}) {
  const { createCanvas, loadImage } = canvasLib();
  const img = await loadImage(bytes);
  const swap = orientation >= 5 && orientation <= 8;
  const w = swap ? img.height : img.width;
  const h = swap ? img.width : img.height;
  const cv = createCanvas(w, h);
  const ctx = cv.getContext('2d');
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, w, h);
  ctx.save();
  switch (orientation) {
    case 2: ctx.transform(-1, 0, 0, 1, w, 0); break;
    case 3: ctx.transform(-1, 0, 0, -1, w, h); break;
    case 4: ctx.transform(1, 0, 0, -1, 0, h); break;
    case 5: ctx.transform(0, 1, 1, 0, 0, 0); break;
    case 6: ctx.transform(0, 1, -1, 0, w, 0); break;
    case 7: ctx.transform(0, -1, -1, 0, w, h); break;
    case 8: ctx.transform(0, -1, 1, 0, 0, h); break;
    default: break;
  }
  ctx.drawImage(img, 0, 0);
  ctx.restore();
  paintBoxes(ctx, boxes, w, h);
  // Photos as JPEG keep productions small; screenshots stay lossless.
  const out = photo ? cv.toBuffer('image/jpeg', 90) : cv.toBuffer('image/png');
  return { bytes: out, width: w, height: h, format: photo ? 'jpg' : 'png' };
}

/// One-page PDF holding an image (redactions burned in).
async function imageToPdf(bytes, opts = {}) {
  const { PDFDocument } = pdfLib();
  const r = await rasterImage(bytes, opts);
  const doc = await PDFDocument.create();
  const landscape = r.width > r.height * 1.15;
  const page = landscape ? { w: LETTER.h, h: LETTER.w } : LETTER;
  const p = doc.addPage([page.w, page.h]);
  const img = r.format === 'jpg' ? await doc.embedJpg(r.bytes) : await doc.embedPng(r.bytes);
  const f = fit(r.width, r.height, page);
  p.drawImage(img, { x: f.x, y: f.y, width: f.w, height: f.h });
  return { bytes: Buffer.from(await doc.save()), pages: 1, rasterizedPages: 1 };
}

class NodeCanvasFactory {
  create(w, h) {
    const cv = canvasLib().createCanvas(Math.max(1, Math.ceil(w)), Math.max(1, Math.ceil(h)));
    return { canvas: cv, context: cv.getContext('2d') };
  }
  reset(cc, w, h) {
    cc.canvas.width = Math.max(1, Math.ceil(w));
    cc.canvas.height = Math.max(1, Math.ceil(h));
  }
  destroy(cc) {
    cc.canvas.width = 0;
    cc.canvas.height = 0;
  }
}

async function openPdfjs(bytes) {
  const pdfjs = await pdfjsLib();
  const fontDir = path.join(path.dirname(require.resolve('pdfjs-dist/package.json')), 'standard_fonts') + path.sep;
  return pdfjs.getDocument({
    data: new Uint8Array(bytes),
    canvasFactory: new NodeCanvasFactory(),
    standardFontDataUrl: fontDir,
    useSystemFonts: false,
    disableFontFace: true,
    isEvalSupported: false,
    verbosity: 0,
  }).promise;
}

function normText(s) {
  return String(s || '').toLowerCase().replace(/\s+/g, ' ');
}

/// Boxes (normalized to each page) around every occurrence of the given
/// strings, from the PDF's own text positions. Returns { [page]: [box] }.
async function findTextBoxes(pdf, needles) {
  const want = (needles || []).map(normText).filter((n) => n.trim().length >= 2);
  const out = {};
  if (!want.length) return out;
  for (let p = 1; p <= pdf.numPages; p++) {
    const page = await pdf.getPage(p);
    const vp = page.getViewport({ scale: 1 });
    const tc = await page.getTextContent();
    for (const it of tc.items) {
      const str = normText(it.str);
      if (!str.trim()) continue;
      for (const n of want) {
        let from = 0;
        let at;
        while ((at = str.indexOf(n, from)) >= 0) {
          // Position along the run by character share (good enough to cover glyphs with padding).
          const [, b, , d, e, f] = it.transform;
          const fontH = Math.hypot(b, d) || Math.abs(d) || 10;
          const runW = it.width || fontH * str.length * 0.5;
          const x0 = e + (runW * at) / str.length;
          const x1 = e + (runW * (at + n.length)) / str.length;
          const [vx0, vy0] = vp.convertToViewportPoint(x0, f - fontH * 0.25);
          const [vx1, vy1] = vp.convertToViewportPoint(x1, f + fontH * 0.95);
          const box = {
            x: Math.min(vx0, vx1) / vp.width,
            y: Math.min(vy0, vy1) / vp.height,
            w: Math.abs(vx1 - vx0) / vp.width,
            h: Math.abs(vy1 - vy0) / vp.height,
          };
          (out[p] = out[p] || []).push(box);
          from = at + n.length;
        }
      }
    }
  }
  return out;
}

/// A PDF exhibit. Redacted pages are rasterized with the boxes burned in;
/// the rest are copied as they are.
///   pageBoxes: { [page]: [normalized box] }, textRedactions: [string]
async function pdfToExhibit(bytes, { pageBoxes = {}, textRedactions = [] } = {}) {
  const { PDFDocument } = pdfLib();
  const pdf = await openPdfjs(bytes);
  const boxes = {};
  for (const [p, list] of Object.entries(pageBoxes || {})) if (Array.isArray(list) && list.length) boxes[Number(p)] = [...list];
  const found = await findTextBoxes(pdf, textRedactions);
  for (const [p, list] of Object.entries(found)) boxes[Number(p)] = [...(boxes[Number(p)] || []), ...list];

  let src = null;
  try {
    src = await PDFDocument.load(bytes, { ignoreEncryption: true, updateMetadata: false });
  } catch (_) {
    src = null; // unreadable structure: rasterize every page instead
  }
  const out = await PDFDocument.create();
  let rasterized = 0;
  for (let p = 1; p <= pdf.numPages; p++) {
    const mustRaster = !src || (boxes[p] && boxes[p].length);
    if (!mustRaster) {
      const [copied] = await out.copyPages(src, [p - 1]);
      out.addPage(copied);
      continue;
    }
    const page = await pdf.getPage(p);
    const vp1 = page.getViewport({ scale: 1 });
    const vp = page.getViewport({ scale: RASTER_SCALE });
    const f = new NodeCanvasFactory().create(vp.width, vp.height);
    f.context.fillStyle = '#ffffff';
    f.context.fillRect(0, 0, f.canvas.width, f.canvas.height);
    await page.render({ canvasContext: f.context, viewport: vp }).promise;
    paintBoxes(f.context, boxes[p] || [], f.canvas.width, f.canvas.height);
    const png = f.canvas.toBuffer('image/png');
    const img = await out.embedPng(png);
    const np = out.addPage([vp1.width, vp1.height]);
    np.drawImage(img, { x: 0, y: 0, width: vp1.width, height: vp1.height });
    rasterized++;
  }
  await pdf.destroy();
  return { bytes: Buffer.from(await out.save()), pages: out.getPageCount(), rasterizedPages: rasterized };
}

function fontPath() {
  try {
    return require.resolve('dejavu-fonts-ttf/ttf/DejaVuSans.ttf');
  } catch (_) {
    return null;
  }
}

/// Replaces each redacted string (case-insensitive) with a solid block of
/// the same length, so nothing of it survives in the text.
function redactText(text, strings) {
  let out = String(text || '');
  for (const s of strings || []) {
    const t = String(s || '').trim();
    if (t.length < 2) continue;
    const re = new RegExp(t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+'), 'gi');
    out = out.replace(re, (m) => '█'.repeat(Math.max(3, m.replace(/\s/g, '').length)));
  }
  return out;
}

/// Typesets a text document or email as exhibit pages.
async function textToPdf(text, { title = '', textRedactions = [] } = {}) {
  const PDFKit = require('pdfkit');
  const body = redactText(text, textRedactions);
  const doc = new PDFKit({ size: 'LETTER', margins: { top: 54, bottom: 54 + STAMP_BAND, left: 60, right: 60 }, autoFirstPage: true, compress: true });
  const fp = fontPath();
  if (fp) doc.font(fp);
  const chunks = [];
  doc.on('data', (c) => chunks.push(c));
  const done = new Promise((resolve) => doc.on('end', resolve));
  if (title) {
    doc.fontSize(9).fillColor('#555555').text(title, { width: 492 });
    doc.moveDown(0.8);
  }
  doc.fontSize(10.5).fillColor('#111111').text(body, { width: 492, lineGap: 2 });
  doc.end();
  await done;
  const bytes = Buffer.concat(chunks);
  const { PDFDocument } = pdfLib();
  const pages = (await PDFDocument.load(bytes)).getPageCount();
  return { bytes, pages, rasterizedPages: 0 };
}

module.exports = {
  LETTER,
  MARGIN,
  STAMP_BAND,
  paintBoxes,
  fit,
  rasterImage,
  imageToPdf,
  openPdfjs,
  findTextBoxes,
  pdfToExhibit,
  redactText,
  textToPdf,
};
