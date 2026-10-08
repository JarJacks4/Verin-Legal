// Small PDF builder shared by Verin's reports: brand header, labelled values,
// paragraphs, tables that break across pages, and page footers. Same fonts
// and colours as the record certificate (export/record_pdf.js).
const { printable, human, dash, FONTS, COLORS } = require('../export/record_pdf');

const { NAVY, TEAL, INK, MUTED, RULE } = COLORS;

function createReport({ title, subtitle = '', kicker = 'VERIN', footer = '', info = {} }) {
  const PDFDocument = require('pdfkit');
  const doc = new PDFDocument({
    size: 'LETTER',
    margins: { top: 54, bottom: 64, left: 54, right: 54 },
    bufferPages: true,
    info: { Title: printable(title), Author: 'Verin Legal', ...info },
  });
  doc.registerFont('Sans', FONTS.sans);
  doc.registerFont('Bold', FONTS.bold);
  doc.registerFont('Mono', FONTS.mono);
  doc.registerFont('Serif', FONTS.serif);
  const chunks = [];
  doc.on('data', (c) => chunks.push(c));
  const done = new Promise((resolve, reject) => {
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });

  const left = doc.page.margins.left;
  const width = doc.page.width - doc.page.margins.left - doc.page.margins.right;
  const bottom = () => doc.page.height - doc.page.margins.bottom;
  const ensure = (h) => {
    if (doc.y + h > bottom()) doc.addPage();
  };

  const api = {
    doc,
    left,
    width,
    ensure,
    heading(text, size = 15) {
      ensure(40);
      doc.moveDown(0.4);
      doc.font('Serif').fontSize(size).fillColor(NAVY).text(printable(text), left, doc.y, { width });
      doc.moveDown(0.35);
    },
    label(text) {
      ensure(24);
      doc.font('Bold').fontSize(8).fillColor(MUTED).text(printable(text).toUpperCase(), left, doc.y, { width, characterSpacing: 0.6 });
      doc.moveDown(0.35);
    },
    para(text, { size = 10, color = INK, muted = false } = {}) {
      doc.font('Sans').fontSize(size);
      ensure(doc.heightOfString(printable(text), { width }) + 4);
      doc.fillColor(muted ? MUTED : color).text(printable(text), left, doc.y, { width });
      doc.moveDown(0.4);
    },
    bullet(text) {
      doc.font('Sans').fontSize(9.5);
      ensure(doc.heightOfString(printable(text), { width: width - 14 }) + 3);
      doc.fillColor(INK).text(`•  ${printable(text)}`, left + 6, doc.y, { width: width - 14 });
      doc.moveDown(0.15);
    },
    kv(k, v, { mono = false } = {}) {
      const keyW = 170;
      const val = printable(dash(v));
      doc.font(mono ? 'Mono' : 'Sans').fontSize(mono ? 8.5 : 10);
      const h = Math.max(doc.heightOfString(val, { width: width - keyW }), 12);
      ensure(h + 4);
      const y = doc.y;
      doc.font('Sans').fontSize(9).fillColor(MUTED).text(printable(k), left, y, { width: keyW - 8 });
      doc.font(mono ? 'Mono' : 'Sans').fontSize(mono ? 8.5 : 10).fillColor(INK).text(val, left + keyW, y, { width: width - keyW });
      doc.y = Math.max(doc.y, y + h) + 4;
    },
    /// Big number tiles in a row: [{ label, value, note }]
    tiles(items) {
      const gap = 10;
      const w = (width - gap * (items.length - 1)) / items.length;
      ensure(70);
      const y = doc.y;
      items.forEach((t, i) => {
        const x = left + i * (w + gap);
        doc.roundedRect(x, y, w, 62, 6).lineWidth(0.6).strokeColor(RULE).stroke();
        doc.font('Bold').fontSize(7.5).fillColor(MUTED).text(printable(t.label).toUpperCase(), x + 10, y + 8, { width: w - 20, characterSpacing: 0.4 });
        doc.font('Serif').fontSize(20).fillColor(NAVY).text(printable(dash(t.value)), x + 10, y + 22, { width: w - 20 });
        if (t.note) doc.font('Sans').fontSize(7.5).fillColor(MUTED).text(printable(t.note), x + 10, y + 46, { width: w - 20, lineBreak: false, ellipsis: true });
      });
      doc.y = y + 72;
    },
    /// cols: [{ title, w (fraction), mono? }], rows: [[...]]
    table(cols, rows, { size = 8.5 } = {}) {
      const ws = cols.map((c) => c.w * width);
      const header = () => {
        ensure(20);
        let x = left;
        const y = doc.y;
        doc.font('Bold').fontSize(7.5).fillColor(MUTED);
        cols.forEach((c, i) => {
          doc.text(printable(c.title).toUpperCase(), x, y, { width: ws[i] - 6 });
          x += ws[i];
        });
        doc.y = y + 13;
        doc.moveTo(left, doc.y).lineTo(left + width, doc.y).lineWidth(0.5).strokeColor(RULE).stroke();
        doc.y += 4;
      };
      header();
      if (!rows.length) {
        doc.font('Sans').fontSize(9).fillColor(MUTED).text('None.', left, doc.y, { width });
        doc.moveDown(0.4);
        return;
      }
      for (const row of rows) {
        const cells = row.map((v) => printable(dash(v)));
        const h = Math.max(
          ...cells.map((c, i) => {
            doc.font(cols[i].mono ? 'Mono' : 'Sans').fontSize(cols[i].mono ? size - 1 : size);
            return doc.heightOfString(c, { width: ws[i] - 6 });
          }),
          10,
        );
        if (doc.y + h + 6 > bottom()) {
          doc.addPage();
          header();
        }
        const y = doc.y;
        let x = left;
        cells.forEach((c, i) => {
          doc.font(cols[i].mono ? 'Mono' : 'Sans').fontSize(cols[i].mono ? size - 1 : size).fillColor(INK).text(c, x, y, { width: ws[i] - 6 });
          x += ws[i];
        });
        doc.y = y + h + 3;
        doc.moveTo(left, doc.y).lineTo(left + width, doc.y).lineWidth(0.3).strokeColor(RULE).stroke();
        doc.y += 3;
      }
      doc.moveDown(0.4);
    },
    newPage() {
      doc.addPage();
    },
    async finish() {
      const range = doc.bufferedPageRange();
      for (let i = range.start; i < range.start + range.count; i++) {
        doc.switchToPage(i);
        const saved = doc.page.margins.bottom;
        doc.page.margins.bottom = 0;
        const y = doc.page.height - 40;
        doc.font('Sans').fontSize(7.5).fillColor(MUTED);
        doc.text(printable(footer || title), left, y, { width: width - 80, lineBreak: false, ellipsis: true });
        doc.text(`Page ${i - range.start + 1} of ${range.count}`, left + width - 80, y, { width: 80, align: 'right', lineBreak: false });
        doc.page.margins.bottom = saved;
      }
      doc.end();
      return done;
    },
  };

  doc.font('Bold').fontSize(9).fillColor(TEAL).text(kicker, left, doc.y, { characterSpacing: 2 });
  doc.moveDown(0.2);
  doc.font('Serif').fontSize(22).fillColor(NAVY).text(printable(title), left, doc.y, { width });
  if (subtitle) {
    doc.moveDown(0.15);
    doc.font('Sans').fontSize(11.5).fillColor(INK).text(printable(subtitle), { width });
  }
  doc.moveDown(0.8);
  return api;
}

const DISCLAIMER =
  'Generated by software from the stored record. Verin does not practice law. No opinion on authenticity, completeness or admissibility is offered or implied; those determinations belong to counsel and the Court.';

const day = (d) => (d ? human(d).replace(/,? \d{1,2}:\d{2} [AP]M UTC$/, '').replace(' UTC', '') : '—');

module.exports = { createReport, DISCLAIMER, day, human, printable, dash };
