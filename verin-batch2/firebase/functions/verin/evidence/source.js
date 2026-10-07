// Verin Legal — where in the original each extracted statement came from.
//
// The reading returns, for every message and every key passage, the page it is
// on (PDFs) and a box around it on the image (normalized 0..1 to the image's
// width and height). The verification view draws that box over the original
// so a reviewer checks the words against the pixels they came from.
//
// Locations are reading aids. A missing or implausible box is dropped, never
// guessed at, and the statement still links to its source item.

const STATEMENT_KINDS = ['date', 'amount', 'person', 'place', 'event', 'other'];
// What court rules commonly require redacting in filings (e.g. Fed. R. Civ. P.
// 5.2 and state equivalents), plus contact details family courts often protect.
const SENSITIVE_CATEGORIES = ['ssn', 'tax_id', 'account', 'birth_date', 'minor_name', 'address', 'phone', 'email', 'other'];
const MAX_SENSITIVE = 60;
const MAX_STATEMENTS = 25;

const BOX_SCHEMA = {
  type: 'object',
  description:
    'Box around this text on the image, as fractions of the image width/height from the top-left corner (0.0 to 1.0). All zeros when the item is not an image or the position is unclear.',
  properties: {
    x: { type: 'number' },
    y: { type: 'number' },
    w: { type: 'number' },
    h: { type: 'number' },
  },
  required: ['x', 'y', 'w', 'h'],
  additionalProperties: false,
};

const STATEMENT_SCHEMA = {
  type: 'object',
  properties: {
    text: { type: 'string', description: 'The passage, copied verbatim from the item.' },
    kind: { type: 'string', enum: STATEMENT_KINDS },
    page: { type: 'integer', description: '1-based page number in a PDF; 0 otherwise.' },
    box: BOX_SCHEMA,
  },
  required: ['text', 'kind', 'page', 'box'],
  additionalProperties: false,
};

const SENSITIVE_SCHEMA = {
  type: 'object',
  properties: {
    text: { type: 'string', description: 'The exact characters to redact, copied verbatim.' },
    category: { type: 'string', enum: SENSITIVE_CATEGORIES },
    page: { type: 'integer', description: '1-based PDF page; 0 otherwise.' },
    box: BOX_SCHEMA,
  },
  required: ['text', 'category', 'page', 'box'],
  additionalProperties: false,
};

const num = (v) => typeof v === 'number' && Number.isFinite(v);

/// A plausible normalized box, or null. Tolerates tiny overshoot from rounding.
function cleanBox(b) {
  if (!b || typeof b !== 'object') return null;
  const { x, y, w, h } = b;
  if (![x, y, w, h].every(num)) return null;
  if (w <= 0 || h <= 0) return null;
  if (x < -0.01 || y < -0.01 || x + w > 1.01 || y + h > 1.01) return null;
  if (w * h < 0.00002) return null; // a speck — not a real location
  const r = (v) => Math.round(Math.min(1, Math.max(0, v)) * 10000) / 10000;
  return { x: r(x), y: r(y), w: r(w), h: r(h) };
}

function cleanPage(p) {
  return Number.isInteger(p) && p > 0 && p < 100000 ? p : 0;
}

/// Location fields to store with a message: { senderName, page, box }.
function messageSource(m) {
  const out = {};
  if (m && typeof m.senderName === 'string' && m.senderName.trim()) out.senderName = m.senderName.trim().slice(0, 120);
  const page = cleanPage(m && m.page);
  if (page) out.page = page;
  const box = cleanBox(m && m.box);
  if (box) out.box = box;
  if (m && num(m.atSeconds) && m.atSeconds >= 0) out.atSeconds = Math.round(m.atSeconds);
  return out;
}

/// Key passages from documents, emails and photos. Invalid entries are
/// skipped (and counted), never repaired.
function cleanStatements(list) {
  if (!Array.isArray(list)) return { statements: [], skipped: 0 };
  const statements = [];
  let skipped = 0;
  for (const s of list) {
    if (!s || typeof s.text !== 'string' || !s.text.trim() || !STATEMENT_KINDS.includes(s.kind)) {
      skipped++;
      continue;
    }
    const st = { text: s.text.trim().slice(0, 1200), kind: s.kind };
    const page = cleanPage(s.page);
    if (page) st.page = page;
    const box = cleanBox(s.box);
    if (box) st.box = box;
    statements.push(st);
    if (statements.length >= MAX_STATEMENTS) break;
  }
  return { statements, skipped };
}

/// Redaction suggestions: same shape rules as statements.
function cleanSensitive(list) {
  if (!Array.isArray(list)) return [];
  const out = [];
  for (const s of list) {
    if (!s || typeof s.text !== 'string' || !s.text.trim() || !SENSITIVE_CATEGORIES.includes(s.category)) continue;
    const it = { text: s.text.trim().slice(0, 300), category: s.category };
    const page = cleanPage(s.page);
    if (page) it.page = page;
    const box = cleanBox(s.box);
    if (box) it.box = box;
    out.push(it);
    if (out.length >= MAX_SENSITIVE) break;
  }
  return out;
}

/// Pixel size of a PNG, JPEG, GIF or WebP from its bytes, or null.
function imageSize(buf) {
  if (!buf || buf.length < 30) return null;
  // PNG: IHDR width/height at 16/20.
  if (buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47) {
    return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
  }
  // GIF: logical screen size, little-endian.
  if (buf.toString('ascii', 0, 4) === 'GIF8') {
    return { width: buf.readUInt16LE(6), height: buf.readUInt16LE(8) };
  }
  // WebP: VP8 / VP8L / VP8X.
  if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WEBP') {
    const chunk = buf.toString('ascii', 12, 16);
    if (chunk === 'VP8 ' && buf.length >= 30) return { width: buf.readUInt16LE(26) & 0x3fff, height: buf.readUInt16LE(28) & 0x3fff };
    if (chunk === 'VP8L' && buf.length >= 25) {
      const b = buf.readUInt32LE(21);
      return { width: (b & 0x3fff) + 1, height: ((b >> 14) & 0x3fff) + 1 };
    }
    if (chunk === 'VP8X' && buf.length >= 30) {
      return { width: (buf.readUIntLE(24, 3) & 0xffffff) + 1, height: (buf.readUIntLE(27, 3) & 0xffffff) + 1 };
    }
    return null;
  }
  // JPEG: walk segments to the first SOFn marker.
  if (buf[0] === 0xff && buf[1] === 0xd8) {
    let i = 2;
    while (i + 9 < buf.length) {
      if (buf[i] !== 0xff) {
        i++;
        continue;
      }
      const marker = buf[i + 1];
      if (marker === 0xd8 || marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) {
        i += 2;
        continue;
      }
      const len = buf.readUInt16BE(i + 2);
      const isSof = marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker);
      if (isSof) {
        const height = buf.readUInt16BE(i + 5);
        const width = buf.readUInt16BE(i + 7);
        let orient = jpegOrientation(buf);
        // EXIF orientations 5–8 rotate by 90°: browsers display swapped.
        return orient >= 5 && orient <= 8 ? { width: height, height: width } : { width, height };
      }
      i += 2 + len;
    }
  }
  return null;
}

/// EXIF orientation tag (1–8) of a JPEG, or 1.
function jpegOrientation(buf) {
  let i = 2;
  while (i + 4 < buf.length) {
    if (buf[i] !== 0xff) return 1;
    const marker = buf[i + 1];
    const len = buf.readUInt16BE(i + 2);
    if (marker === 0xe1 && buf.toString('ascii', i + 4, i + 8) === 'Exif') {
      const t = i + 10; // TIFF header
      const le = buf.toString('ascii', t, t + 2) === 'II';
      const r16 = (o) => (le ? buf.readUInt16LE(o) : buf.readUInt16BE(o));
      const r32 = (o) => (le ? buf.readUInt32LE(o) : buf.readUInt32BE(o));
      try {
        const ifd = t + r32(t + 4);
        const n = r16(ifd);
        for (let k = 0; k < n; k++) {
          const e = ifd + 2 + k * 12;
          if (r16(e) === 0x0112) return r16(e + 8) || 1;
        }
      } catch (_) {
        return 1;
      }
      return 1;
    }
    if (marker === 0xda) return 1; // start of scan: no EXIF before image data
    i += 2 + len;
  }
  return 1;
}

module.exports = {
  SENSITIVE_CATEGORIES,
  SENSITIVE_SCHEMA,
  cleanSensitive,
  STATEMENT_KINDS,
  MAX_STATEMENTS,
  BOX_SCHEMA,
  STATEMENT_SCHEMA,
  cleanBox,
  cleanPage,
  messageSource,
  cleanStatements,
  imageSize,
  jpegOrientation,
};
