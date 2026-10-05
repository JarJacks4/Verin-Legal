// Verin Legal — draws the sample screenshots and documents for the NFR demo
// workspace, and reports where each message sits (so "Verify against the
// original" highlights the right bubble, exactly as for a real reading).

const { createCanvas, GlobalFonts } = require('@napi-rs/canvas');
const { PDFDocument, StandardFonts, rgb } = require('pdf-lib');

let fontsReady = false;
function fonts() {
  if (fontsReady) return;
  GlobalFonts.registerFromPath(require.resolve('dejavu-fonts-ttf/ttf/DejaVuSans.ttf'), 'DemoSans');
  GlobalFonts.registerFromPath(require.resolve('dejavu-fonts-ttf/ttf/DejaVuSans-Bold.ttf'), 'DemoSansBold');
  fontsReady = true;
}

const THEMES = {
  imessage: { bg: '#FFFFFF', bar: '#F6F6F6', mine: '#0A84FF', mineText: '#FFFFFF', theirs: '#E9E9EB', theirsText: '#000000', divider: '#8E8E93', platform: 'iMessage' },
  whatsapp: { bg: '#ECE5DD', bar: '#075E54', barText: '#FFFFFF', mine: '#DCF8C6', mineText: '#111B21', theirs: '#FFFFFF', theirsText: '#111B21', divider: '#54656F', platform: 'WhatsApp' },
};

function wrap(ctx, text, maxWidth) {
  const words = String(text).split(/\s+/);
  const lines = [];
  let line = '';
  for (const w of words) {
    const t = line ? `${line} ${w}` : w;
    if (ctx.measureText(t).width > maxWidth && line) {
      lines.push(line);
      line = w;
    } else {
      line = t;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

/**
 * items: [{ header: 'Sat, Sep 12 6:41 PM' } | { side: 'client'|'other', text }]
 * The client is on the right (their own phone). Returns { png, width, height, boxes }
 * with one normalized box per item, in order.
 */
function chatScreenshot({ contact, items, theme = 'imessage' }) {
  fonts();
  const T = THEMES[theme];
  const W = 750;
  const pad = 28;
  const maxBubble = W * 0.68;
  const font = 30;
  const lineH = 40;

  // First pass: measure.
  const probe = createCanvas(10, 10).getContext('2d');
  probe.font = `${font}px DemoSans`;
  const top = 200;
  let y = top;
  const placed = items.map((it) => {
    if (it.header) {
      const p = { kind: 'header', y: y + 18, h: 34, text: it.header };
      y += 74;
      return p;
    }
    const lines = wrap(probe, it.text, maxBubble - 48);
    const textW = Math.max(...lines.map((l) => probe.measureText(l).width));
    const bw = Math.min(maxBubble, textW + 48);
    const bh = lines.length * lineH + 28;
    const p = { kind: 'msg', side: it.side, lines, y, w: bw, h: bh };
    y += bh + 14;
    return p;
  });
  const H = Math.max(820, y + 140);

  const cv = createCanvas(W, H);
  const ctx = cv.getContext('2d');
  ctx.fillStyle = T.bg;
  ctx.fillRect(0, 0, W, H);

  // Status bar + contact header.
  ctx.fillStyle = theme === 'whatsapp' ? T.bar : T.bar;
  ctx.fillRect(0, 0, W, 170);
  const headText = theme === 'whatsapp' ? T.barText : '#000000';
  ctx.fillStyle = headText;
  ctx.font = '26px DemoSansBold';
  ctx.fillText('9:41', 40, 44);
  ctx.textAlign = 'right';
  ctx.fillText('100%', W - 40, 44);
  ctx.textAlign = 'center';
  ctx.fillStyle = theme === 'whatsapp' ? '#25D366' : '#A2A2A8';
  ctx.beginPath();
  ctx.arc(W / 2, 98, 30, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#FFFFFF';
  ctx.font = '28px DemoSansBold';
  ctx.fillText(contact.slice(0, 1).toUpperCase(), W / 2, 108);
  ctx.fillStyle = headText;
  ctx.font = '24px DemoSans';
  ctx.fillText(contact, W / 2, 156);
  ctx.textAlign = 'left';

  const boxes = [];
  for (const p of placed) {
    if (p.kind === 'header') {
      ctx.fillStyle = T.divider;
      ctx.font = '22px DemoSans';
      ctx.textAlign = 'center';
      ctx.fillText(p.text, W / 2, p.y + 26);
      ctx.textAlign = 'left';
      const tw = probe.measureText(p.text).width * (22 / font);
      boxes.push({ x: (W / 2 - tw / 2 - 8) / W, y: p.y / H, w: (tw + 16) / W, h: p.h / H });
      continue;
    }
    const mine = p.side === 'client';
    const x = mine ? W - pad - p.w : pad;
    ctx.fillStyle = mine ? T.mine : T.theirs;
    roundRect(ctx, x, p.y, p.w, p.h, 30);
    ctx.fill();
    ctx.fillStyle = mine ? T.mineText : T.theirsText;
    ctx.font = `${font}px DemoSans`;
    p.lines.forEach((l, i) => ctx.fillText(l, x + 24, p.y + 14 + (i + 1) * lineH - 10));
    boxes.push({ x: x / W, y: p.y / H, w: p.w / W, h: p.h / H });
  }

  const r4 = (v) => Math.round(v * 10000) / 10000;
  return {
    png: cv.toBuffer('image/png'),
    width: W,
    height: H,
    platform: T.platform,
    boxes: boxes.map((b) => ({ x: r4(b.x), y: r4(b.y), w: r4(b.w), h: r4(b.h) })),
  };
}

/// A one-page letter-size PDF. lines: [{ text, bold?, size? }]. Returns
/// { pdf, boxes } with a normalized box per line (page 1).
async function simplePdf(lines) {
  const doc = await PDFDocument.create();
  const page = doc.addPage([612, 792]);
  const regular = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  let y = 730;
  const boxes = [];
  for (const l of lines) {
    const size = l.size || 11;
    const f = l.bold ? bold : regular;
    if (l.text) {
      page.drawText(l.text, { x: 64, y, size, font: f, color: rgb(0.1, 0.12, 0.14) });
      const w = f.widthOfTextAtSize(l.text, size);
      boxes.push({ x: 60 / 612, y: (792 - y - size) / 792, w: (w + 8) / 612, h: (size + 6) / 792 });
    } else {
      boxes.push(null);
    }
    y -= size + (l.gap || 10);
  }
  return { pdf: Buffer.from(await doc.save()), boxes };
}

module.exports = { chatScreenshot, simplePdf };
