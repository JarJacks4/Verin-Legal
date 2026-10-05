// Verin Legal — slip sheets, Bates and exhibit stamps, and the index.
//
// Every produced page carries its Bates number and its exhibit label. A slip
// sheet before each exhibit says what it is and where it came from (the
// source reference: when and how it was received, from whom, the original's
// SHA-256 and its place in the matter's hash chain). The index lists every
// exhibit with its Bates range and both hashes — original and produced.

const { exhibitLabel, batesLabel, ascii } = require('./template');

function pdfLib() {
  return require('pdf-lib');
}

const GREY = [0.36, 0.4, 0.42];

/// Wraps text to a width for a pdf-lib font.
function wrap(font, text, size, width) {
  const words = ascii(text, 4000).split(/\s+/).filter(Boolean);
  const lines = [];
  let line = '';
  for (const w of words) {
    const next = line ? `${line} ${w}` : w;
    if (font.widthOfTextAtSize(next, size) > width && line) {
      lines.push(line);
      line = w;
    } else line = next;
  }
  if (line) lines.push(line);
  return lines;
}

/// Adds a slip sheet page to doc for one exhibit.
async function addSlipSheet(doc, { label, item, template, native = false }) {
  const { StandardFonts, rgb } = pdfLib();
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const reg = await doc.embedFont(StandardFonts.Helvetica);
  const mono = await doc.embedFont(StandardFonts.Courier);
  const page = doc.addPage([612, 792]);
  const grey = rgb(...GREY);
  page.drawText(ascii(label, 40).toUpperCase(), { x: 72, y: 600, size: 40, font: bold, color: rgb(0.05, 0.09, 0.13) });
  let y = 560;
  for (const l of wrap(reg, item.description || item.fileName || 'Item', 13, 468).slice(0, 4)) {
    page.drawText(l, { x: 72, y, size: 13, font: reg });
    y -= 18;
  }
  y -= 18;
  const rows = [
    ['Received', item.receivedAt || '-'],
    ['Channel', item.channel || '-'],
    ['From', item.from || '-'],
    ['Original file', item.fileName || '-'],
    ['Item date', item.itemDate || 'not established'],
    ['Chain entry', item.chainSeq ? `#${item.chainSeq} in the matter's hash chain` : '-'],
    ['Timestamp', item.tsa ? `RFC 3161 token (${item.tsa})` : 'none'],
  ];
  if (native) rows.push(['Produced as', 'native file (see natives/ in this production)']);
  if (item.redactions) rows.push(['Redactions', `${item.redactions} area${item.redactions === 1 ? '' : 's'} redacted in this exhibit`]);
  for (const [k, v] of rows) {
    page.drawText(ascii(k, 30), { x: 72, y, size: 9.5, font: reg, color: grey });
    page.drawText(ascii(v, 90), { x: 180, y, size: 9.5, font: reg });
    y -= 16;
  }
  y -= 8;
  page.drawText('SHA-256 of the original as received', { x: 72, y, size: 9.5, font: reg, color: grey });
  y -= 14;
  page.drawText(ascii(item.sha256 || '-', 64), { x: 72, y, size: 8.5, font: mono });
  y -= 30;
  for (const l of wrap(reg, 'This slip sheet identifies the exhibit that follows. The original item is preserved unaltered in the evidence record; this exhibit is a copy prepared for production.', 8.5, 468)) {
    page.drawText(l, { x: 72, y, size: 8.5, font: reg, color: grey });
    y -= 12;
  }
  if (template.legend) page.drawText(template.legend, { x: 72, y: 90, size: 9, font: bold, color: rgb(0.48, 0.14, 0.2) });
  return page;
}

/// Bates number at the bottom, exhibit label at the top right, legend if set.
async function stampPage(doc, page, { bates, label, template, fonts }) {
  const { rgb } = pdfLib();
  const { width: W, height: H } = page.getSize();
  const size = 9;
  const bw = fonts.bold.widthOfTextAtSize(bates, size);
  const pad = 4;
  let x;
  if (template.stampPosition === 'bottom-center') x = (W - bw) / 2;
  else if (template.stampPosition === 'bottom-left') x = 24;
  else x = W - bw - 24;
  const y = 16;
  page.drawRectangle({ x: x - pad, y: y - 3, width: bw + pad * 2, height: size + 6, color: rgb(1, 1, 1), opacity: 0.9 });
  page.drawText(bates, { x, y, size, font: fonts.bold, color: rgb(0, 0, 0) });

  const lw = fonts.bold.widthOfTextAtSize(label, size);
  page.drawRectangle({ x: W - lw - 24 - pad, y: H - 26 - 3, width: lw + pad * 2, height: size + 6, color: rgb(1, 1, 1), opacity: 0.9 });
  page.drawText(label, { x: W - lw - 24, y: H - 26, size, font: fonts.bold, color: rgb(0, 0, 0) });

  if (template.legend) {
    const legSize = 7.5;
    const lgw = fonts.reg.widthOfTextAtSize(template.legend, legSize);
    const lx = template.stampPosition === 'bottom-left' ? W - lgw - 24 : 24;
    page.drawRectangle({ x: lx - pad, y: y - 3, width: lgw + pad * 2, height: legSize + 6, color: rgb(1, 1, 1), opacity: 0.9 });
    page.drawText(template.legend, { x: lx, y, size: legSize, font: fonts.reg, color: rgb(0.48, 0.14, 0.2) });
  }
}

/// How many pages an exhibit will take once its slip sheet is added.
function pageCount(ex, template) {
  return ex.pages + (template.slipSheets || !ex.bytes ? 1 : 0);
}

/**
 * Builds the stamped exhibits.
 *   exhibits: [{ n, item, bytes|null (exhibit PDF), pages, native }]
 *   batesStart: first Bates number for this production
 * Returns { combined: Buffer, perExhibit: [{ n, label, bytes, firstBates, lastBates, pages }], nextBates }
 */
async function assemble(exhibits, template, batesStart) {
  const { PDFDocument, StandardFonts } = pdfLib();
  const combined = await PDFDocument.create();
  let bates = batesStart;
  const perExhibit = [];
  for (const ex of exhibits) {
    const label = exhibitLabel(ex.n, template);
    const doc = await PDFDocument.create();
    const fonts = { bold: await doc.embedFont(StandardFonts.HelveticaBold), reg: await doc.embedFont(StandardFonts.Helvetica) };
    if (template.slipSheets || !ex.bytes) await addSlipSheet(doc, { label, item: ex.item, template, native: !ex.bytes });
    if (ex.bytes) {
      const src = await PDFDocument.load(ex.bytes, { ignoreEncryption: true });
      const copied = await doc.copyPages(src, src.getPageIndices());
      for (const p of copied) doc.addPage(p);
    }
    const first = bates;
    for (const p of doc.getPages()) {
      await stampPage(doc, p, { bates: batesLabel(bates, template), label, template, fonts });
      bates++;
    }
    const bytes = Buffer.from(await doc.save());
    const again = await PDFDocument.load(bytes);
    const pages = await combined.copyPages(again, again.getPageIndices());
    for (const p of pages) combined.addPage(p);
    perExhibit.push({ n: ex.n, label, bytes, firstBates: batesLabel(first, template), lastBates: batesLabel(bates - 1, template), first, last: bates - 1, pages: doc.getPageCount() });
  }
  return { combined: Buffer.from(await combined.save()), perExhibit, nextBates: bates };
}

/// Exhibit index as a PDF (landscape table).
async function indexPdf(rows, { title, matterTitle, producedAt, version, legend }) {
  const { PDFDocument, StandardFonts, rgb } = pdfLib();
  const doc = await PDFDocument.create();
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const reg = await doc.embedFont(StandardFonts.Helvetica);
  const mono = await doc.embedFont(StandardFonts.Courier);
  const W = 792;
  const H = 612;
  const cols = [
    ['Exhibit', 70],
    ['Bates range', 150],
    ['Pages', 38],
    ['Description', 220],
    ['Item date', 70],
    ['Source', 110],
    ['Redact.', 40],
  ];
  let page = null;
  let y = 0;
  const newPage = () => {
    page = doc.addPage([W, H]);
    page.drawText(ascii(title, 60), { x: 36, y: H - 50, size: 16, font: bold });
    page.drawText(ascii(`${matterTitle} - production v${version} - ${producedAt}`, 120), { x: 36, y: H - 68, size: 9, font: reg, color: rgb(...GREY) });
    if (legend) page.drawText(legend, { x: 36, y: 20, size: 8, font: bold, color: rgb(0.48, 0.14, 0.2) });
    y = H - 96;
    let x = 36;
    for (const [h, w] of cols) {
      page.drawText(h.toUpperCase(), { x, y, size: 7.5, font: bold, color: rgb(...GREY) });
      x += w;
    }
    y -= 8;
    page.drawLine({ start: { x: 36, y }, end: { x: W - 36, y }, thickness: 0.5, color: rgb(0.8, 0.8, 0.8) });
    y -= 14;
  };
  newPage();
  for (const r of rows) {
    const desc = wrap(reg, r.description, 8.5, cols[3][1] - 8).slice(0, 3);
    const need = Math.max(desc.length, 1) * 11 + 20;
    if (y - need < 40) newPage();
    let x = 36;
    const cells = [r.label, `${r.firstBates} - ${r.lastBates}`, String(r.pages), null, r.itemDate || '-', r.source || '-', String(r.redactions || 0)];
    cells.forEach((v, i) => {
      if (i === 3) desc.forEach((l, k) => page.drawText(l, { x, y: y - k * 11, size: 8.5, font: reg }));
      else page.drawText(ascii(v, 40), { x, y, size: 8.5, font: i === 0 ? bold : reg });
      x += cols[i][1];
    });
    y -= Math.max(desc.length, 1) * 11 + 2;
    page.drawText(ascii(`original SHA-256 ${r.sha256}`, 90), { x: 36 + cols[0][1], y, size: 6.5, font: mono, color: rgb(...GREY) });
    y -= 9;
    page.drawText(ascii(`produced SHA-256 ${r.producedSha256}`, 90), { x: 36 + cols[0][1], y, size: 6.5, font: mono, color: rgb(...GREY) });
    y -= 14;
  }
  return Buffer.from(await doc.save());
}

function csvCell(v) {
  const s = String(v == null ? '' : v);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function indexCsv(rows) {
  const head = ['exhibit', 'bates_first', 'bates_last', 'pages', 'description', 'item_date', 'received', 'channel', 'from', 'original_file', 'original_sha256', 'produced_sha256', 'redactions', 'chain_entry'];
  const lines = [head.join(',')];
  for (const r of rows) {
    lines.push(
      [r.label, r.firstBates, r.lastBates, r.pages, r.description, r.itemDate, r.receivedAt, r.channel, r.from, r.fileName, r.sha256, r.producedSha256, r.redactions || 0, r.chainSeq || '']
        .map(csvCell)
        .join(','),
    );
  }
  return `${lines.join('\n')}\n`;
}

module.exports = { wrap, addSlipSheet, stampPage, pageCount, assemble, indexPdf, indexCsv };
