// Verin Legal — build the matter record PDF: Certificate of Preparation,
// itemized exhibit index, thread transcript, and the hash-chain appendix.
//
// Pure function of its input (plain objects in, PDF bytes out) so it can be
// tested without Firebase. Deterministic by design: no AI, no network — every
// value on the page comes straight from the stored record (guide §14g).
//
// Fonts are DejaVu (Unicode coverage for names and message text). Characters
// the font has no glyph for (most emoji) are printed as [U+XXXX] rather than
// as an empty box, so the transcript never silently drops content.

const path = require('path');
const PDFDocument = require('pdfkit');
const fontkit = require('fontkit');

const FONT_DIR = path.dirname(require.resolve('dejavu-fonts-ttf/ttf/DejaVuSans.ttf'));
const FONTS = {
  sans: path.join(FONT_DIR, 'DejaVuSans.ttf'),
  bold: path.join(FONT_DIR, 'DejaVuSans-Bold.ttf'),
  mono: path.join(FONT_DIR, 'DejaVuSansMono.ttf'),
  serif: path.join(FONT_DIR, 'DejaVuSerif.ttf'),
};

// Verin brand (Figma Make theme): deep teal, teal, ink, muted, hairline.
const NAVY = '#093F49';
const TEAL = '#0E6E7D';
const INK = '#172024';
const MUTED = '#5C6A6E';
const RULE = '#E2DED6';
const WARN = '#9A6A14';

let glyphFont = null;
function sansFont() {
  if (!glyphFont) glyphFont = fontkit.openSync(FONTS.sans);
  return glyphFont;
}

// Replace characters the PDF font can't draw with a visible code point.
function printable(s) {
  if (s === null || s === undefined) return '';
  const f = sansFont();
  let out = '';
  for (const ch of String(s)) {
    const cp = ch.codePointAt(0);
    if (cp === 0x0a || cp === 0x09) {
      out += ch;
    } else if (cp < 0x20) {
      continue;
    } else if (f.hasGlyphForCodePoint(cp)) {
      out += ch;
    } else {
      out += `[U+${cp.toString(16).toUpperCase().padStart(4, '0')}]`;
    }
  }
  return out;
}

function iso(d) {
  if (!d) return '';
  const date = d instanceof Date ? d : new Date(d);
  return Number.isNaN(date.getTime()) ? '' : date.toISOString();
}

function human(d) {
  if (!d) return '—';
  const date = d instanceof Date ? d : new Date(d);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString('en-US', {
    timeZone: 'UTC',
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }) + ' UTC';
}

function dash(s) {
  return s === null || s === undefined || String(s).trim() === '' ? '—' : String(s);
}

function buildRecordPdf(input) {
  const { matter, receipts, chain, verification, generatedAt, generatedBy } = input;
  const gen = generatedAt instanceof Date ? generatedAt : new Date(generatedAt);

  const doc = new PDFDocument({
    size: 'LETTER',
    margins: { top: 54, bottom: 64, left: 54, right: 54 },
    bufferPages: true,
    info: {
      Title: `Verin record — ${printable(matter.title || matter.id)}`,
      Author: 'Verin Legal',
      Subject: 'Certificate of Preparation and itemized exhibit record',
      CreationDate: gen,
    },
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
  const bottomLimit = () => doc.page.height - doc.page.margins.bottom;
  const ensure = (h) => {
    if (doc.y + h > bottomLimit()) doc.addPage();
  };

  const label = (s) => {
    doc.font('Bold').fontSize(8).fillColor(MUTED).text(printable(s).toUpperCase(), left, doc.y, { width, characterSpacing: 0.6 });
    doc.moveDown(0.4);
  };
  const rule = () => {
    doc.moveTo(left, doc.y).lineTo(left + width, doc.y).lineWidth(0.5).strokeColor(RULE).stroke();
    doc.moveDown(0.6);
  };
  const kv = (k, v, { mono = false } = {}) => {
    const keyW = 150;
    const valW = width - keyW;
    const val = printable(dash(v));
    doc.font(mono ? 'Mono' : 'Sans').fontSize(mono ? 8.5 : 10);
    const h = Math.max(doc.heightOfString(val, { width: valW }), 12);
    ensure(h + 4);
    const y = doc.y;
    doc.font('Sans').fontSize(9).fillColor(MUTED).text(printable(k), left, y, { width: keyW - 8 });
    doc.font(mono ? 'Mono' : 'Sans').fontSize(mono ? 8.5 : 10).fillColor(INK).text(val, left + keyW, y, { width: valW });
    doc.y = Math.max(doc.y, y + h) + 4;
  };

  // ------------------------------------------------------------ certificate
  doc.font('Bold').fontSize(9).fillColor(TEAL).text('VERIN', left, doc.y, { characterSpacing: 2 });
  doc.moveDown(0.2);
  doc.font('Serif').fontSize(22).fillColor(NAVY).text('Certificate of Preparation', left, doc.y, { width });
  doc.moveDown(0.2);
  doc.font('Sans').fontSize(12).fillColor(INK).text(printable(dash(matter.title)), { width });
  doc.moveDown(1);

  label('Matter overview');
  kv('Matter', matter.title);
  kv('Client', matter.clientName);
  kv('Case number', matter.caseNumber);
  kv('Assigned counsel', matter.assignedCounsel);
  kv('Practice area', matter.practiceArea);
  kv('Matter opened', matter.openedAt ? human(matter.openedAt) : '');
  doc.moveDown(0.6);

  label('Record');
  const gapCount = receipts.reduce((n, r) => n + (r.threadMessages || []).filter((m) => m.isGap).length, 0);
  kv('Items in record', String(receipts.length));
  kv('Hash-chain entries', String(chain.length));
  kv('Chain head', verification && verification.head ? verification.head : matter.chainHeadHash, { mono: true });
  kv('Last external anchor', matter.hashChainLastAnchoredAt ? human(matter.hashChainLastAnchoredAt) : 'Not anchored');
  kv('Continuity gaps detected', String(gapCount));
  kv(
    'Redactions',
    matter.redactionCount ? `${matter.redactionCount}${matter.redactionCategories ? ` (${matter.redactionCategories})` : ''}` : 'None recorded',
  );
  kv('Generated', `${human(gen)}  ·  ${iso(gen)}`);
  if (generatedBy) kv('Generated by', generatedBy);
  doc.moveDown(0.6);

  label('Chain verification');
  let verText;
  if (!verification) {
    verText = 'Not run.';
  } else if (verification.ok) {
    verText =
      verification.verified > 0
        ? `Intact. ${verification.verified} entr${verification.verified === 1 ? 'y was' : 'ies were'} recomputed from their stored inputs at the time of this export and every link matched.`
        : 'No verifiable entries yet.';
    if (verification.legacy > 0) {
      verText += ` ${verification.legacy} earlier entr${verification.legacy === 1 ? 'y predates' : 'ies predate'} server-side chaining and carr${verification.legacy === 1 ? 'ies' : 'y'} no inputs to recompute.`;
    }
  } else {
    verText = `BROKEN at entry #${verification.brokenAt}: ${verification.reason || 'an entry does not match its inputs'}.`;
  }
  doc.font('Sans').fontSize(10).fillColor(verification && !verification.ok ? '#B03A2E' : INK).text(printable(verText), left, doc.y, { width });
  doc.moveDown(0.6);
  doc.font('Mono').fontSize(8).fillColor(MUTED).text('entry_hash = SHA256( prev_hash | item_hash | received_at | origin_digest )', { width });
  doc.moveDown(1);

  doc
    .font('Sans')
    .fontSize(8.5)
    .fillColor(MUTED)
    .text(
      'This document was generated by software from the stored record without human editing. Each exhibit\'s ' +
        'item_hash is the SHA-256 of the file exactly as received. Verin does not practice law. No opinion on ' +
        'authenticity, completeness, or admissibility is offered or implied — those determinations belong to ' +
        'counsel and the Court.',
      left,
      doc.y,
      { width },
    );

  // ------------------------------------------------------------ exhibit index
  doc.addPage();
  doc.font('Serif').fontSize(16).fillColor(NAVY).text('Itemized Exhibit Index', left, doc.y, { width });
  doc.moveDown(0.6);

  const cols = [
    { title: '#', w: 28 },
    { title: 'Received (UTC)', w: 112 },
    { title: 'Channel · kind', w: 92 },
    { title: 'Description', w: width - 28 - 112 - 92 },
  ];
  const header = () => {
    let x = left;
    const y = doc.y;
    doc.font('Bold').fontSize(8).fillColor(MUTED);
    for (const c of cols) {
      doc.text(c.title.toUpperCase(), x, y, { width: c.w - 6 });
      x += c.w;
    }
    doc.y = y + 14;
    rule();
  };
  header();
  if (!receipts.length) {
    doc.font('Sans').fontSize(10).fillColor(MUTED).text('No items in this record.', left, doc.y, { width });
  }
  receipts.forEach((r, i) => {
    const desc = printable(dash(r.headline));
    const hashLine = `item_hash ${r.itemHash || '—'}`;
    const meta = [r.channel, (r.itemKind || '').replace(/_/g, ' ')].filter(Boolean).join(' · ') || '—';
    doc.font('Sans').fontSize(9);
    const descH = doc.heightOfString(desc, { width: cols[3].w - 6 });
    doc.font('Mono').fontSize(7);
    const hashH = doc.heightOfString(hashLine, { width: cols[3].w - 6 });
    const rowH = Math.max(descH + hashH + 4, 24);
    if (doc.y + rowH + 8 > bottomLimit()) {
      doc.addPage();
      header();
    }
    const y = doc.y;
    doc.font('Bold').fontSize(9).fillColor(INK).text(String(i + 1), left, y, { width: cols[0].w - 6 });
    doc.font('Sans').fontSize(8.5).fillColor(INK).text(human(r.receivedAt).replace(' UTC', ''), left + cols[0].w, y, { width: cols[1].w - 6 });
    doc.font('Sans').fontSize(8.5).fillColor(MUTED).text(printable(meta), left + cols[0].w + cols[1].w, y, { width: cols[2].w - 6 });
    const dx = left + cols[0].w + cols[1].w + cols[2].w;
    doc.font('Sans').fontSize(9).fillColor(INK).text(desc, dx, y, { width: cols[3].w - 6 });
    doc.font('Mono').fontSize(7).fillColor(MUTED).text(hashLine, dx, doc.y + 2, { width: cols[3].w - 6 });
    doc.y = Math.max(doc.y, y + rowH) + 4;
    rule();
  });

  // ------------------------------------------------------------ transcript
  const withMessages = receipts.filter((r) => (r.threadMessages || []).length);
  if (withMessages.length) {
    doc.addPage();
    doc.font('Serif').fontSize(16).fillColor(NAVY).text('Thread Transcript', left, doc.y, { width });
    doc.moveDown(0.3);
    doc
      .font('Sans')
      .fontSize(8.5)
      .fillColor(MUTED)
      .text(
        'Messages as read from each screenshot, in on-screen order. "Client" and "Other" reflect which side of ' +
          'the screen a message appeared on. Low-confidence readings are marked; the original images are the record.',
        { width },
      );
    doc.moveDown(0.8);

    receipts.forEach((r, i) => {
      const msgs = r.threadMessages || [];
      if (!msgs.length) return;
      ensure(40);
      doc
        .font('Bold')
        .fontSize(10)
        .fillColor(TEAL)
        .text(printable(`Exhibit ${i + 1} — ${dash(r.headline)}`), left, doc.y, { width });
      doc
        .font('Sans')
        .fontSize(8)
        .fillColor(MUTED)
        .text(printable([r.detectedPlatform, human(r.receivedAt)].filter(Boolean).join(' · ')), { width });
      doc.moveDown(0.4);
      for (const m of msgs) {
        if (m.isGap) {
          ensure(16);
          doc.font('Bold').fontSize(8).fillColor(WARN).text('— gap: continuity not established —', left, doc.y, { width, align: 'center' });
          doc.moveDown(0.2);
        }
        if (m.isHeader) {
          ensure(14);
          doc.font('Sans').fontSize(8).fillColor(MUTED).text(printable(m.text || m.timestampLabel), left, doc.y, { width, align: 'center' });
          doc.moveDown(0.2);
          continue;
        }
        const who = m.speaker === 'client' ? 'Client' : 'Other';
        const flag = typeof m.confidence === 'number' && m.confidence < 0.75 ? `  [low confidence ${Math.round(m.confidence * 100)}%]` : '';
        const stamp = m.timestampLabel ? `  (${m.timestampLabel})` : '';
        const body = printable(m.text || '');
        doc.font('Sans').fontSize(9);
        const h = doc.heightOfString(body, { width: width - 60 }) + 4;
        ensure(h + 10);
        const y = doc.y;
        doc.font('Bold').fontSize(8.5).fillColor(m.speaker === 'client' ? TEAL : NAVY).text(who, left, y, { width: 56 });
        doc.font('Sans').fontSize(9).fillColor(INK).text(body, left + 60, y, { width: width - 60 });
        if (stamp || flag) {
          doc.font('Sans').fontSize(7.5).fillColor(flag ? WARN : MUTED).text(printable(stamp + flag).trim(), left + 60, doc.y, { width: width - 60 });
        }
        doc.moveDown(0.35);
      }
      doc.moveDown(0.6);
    });
  }

  // ------------------------------------------------------------ chain appendix
  doc.addPage();
  doc.font('Serif').fontSize(16).fillColor(NAVY).text('Appendix A — Hash Chain', left, doc.y, { width });
  doc.moveDown(0.3);
  doc
    .font('Sans')
    .fontSize(8.5)
    .fillColor(MUTED)
    .text(
      'To verify independently: starting from prev_hash = 64 zeros, compute SHA-256 of the UTF-8 string ' +
        '"prev_hash|item_hash|received_at|origin_digest" for each entry in order. Each result must equal that ' +
        'entry\'s entry_hash and the next entry\'s prev_hash; the last must equal the chain head on page 1.',
      { width },
    );
  doc.moveDown(0.8);
  if (!chain.length) {
    doc.font('Sans').fontSize(10).fillColor(MUTED).text('No chain entries.', { width });
  }
  for (const e of chain) {
    const lines = [
      ['prev_hash', e.prevHash],
      ['item_hash', e.itemHash],
      ['received_at', e.receivedAtIso],
      ['origin_digest', e.originDigest],
      ['entry_hash', e.entryHash],
    ];
    ensure(lines.length * 11 + 22);
    doc.font('Bold').fontSize(9).fillColor(INK).text(`Entry #${e.seq}`, left, doc.y, { width });
    for (const [k, v] of lines) {
      const y = doc.y;
      doc.font('Mono').fontSize(7.5).fillColor(MUTED).text(k, left, y, { width: 80 });
      doc.font('Mono').fontSize(7.5).fillColor(INK).text(v ? String(v) : '— (not recorded)', left + 80, y, { width: width - 80 });
    }
    doc.moveDown(0.6);
  }

  // ------------------------------------------------------------ footers
  const range = doc.bufferedPageRange();
  const footer = printable(`Verin record · ${dash(matter.title)} · generated ${iso(gen)}`);
  for (let i = range.start; i < range.start + range.count; i++) {
    doc.switchToPage(i);
    const savedBottom = doc.page.margins.bottom;
    doc.page.margins.bottom = 0;
    const y = doc.page.height - 40;
    doc.font('Sans').fontSize(7.5).fillColor(MUTED);
    doc.text(footer, left, y, { width: width - 80, lineBreak: false, ellipsis: true });
    doc.text(`Page ${i - range.start + 1} of ${range.count}`, left + width - 80, y, { width: 80, align: 'right', lineBreak: false });
    doc.page.margins.bottom = savedBottom;
  }

  doc.end();
  return done;
}

module.exports = { buildRecordPdf, printable, human, dash, FONTS, COLORS: { NAVY, TEAL, INK, MUTED, RULE, WARN } };
