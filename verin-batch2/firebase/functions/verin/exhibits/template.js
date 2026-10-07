// Verin Legal — the firm's exhibit template and the labels it produces.
//
// Firms control how a production looks: Bates prefix and width, exhibit
// numbering (1, 2, 3 or A, B, C), the exhibit word, where stamps go, a
// confidentiality legend, slip sheets, and the index title. Stored on the
// firm account as productionTemplate; anything missing falls back to these.

const DEFAULTS = Object.freeze({
  batesPrefix: 'VERIN',
  batesDigits: 6,
  exhibitStyle: 'number', // number | letter
  exhibitWord: 'Exhibit',
  stampPosition: 'bottom-right', // bottom-right | bottom-center | bottom-left
  legend: '', // e.g. CONFIDENTIAL — SUBJECT TO PROTECTIVE ORDER
  slipSheets: true,
  indexTitle: 'Exhibit Index',
});

const POSITIONS = ['bottom-right', 'bottom-center', 'bottom-left'];

// Stamps are drawn with a standard PDF font, so keep them to printable ASCII.
function ascii(s, max) {
  return String(s == null ? '' : s)
    .replace(/[‘’]/g, "'")
    .replace(/[“”]/g, '"')
    .replace(/[–—]/g, '-')
    .replace(/[^\x20-\x7E]/g, '')
    .trim()
    .slice(0, max);
}

/// A complete, safe template from whatever is stored.
function resolveTemplate(stored) {
  const t = stored && typeof stored === 'object' ? stored : {};
  const digits = Number.isInteger(t.batesDigits) ? Math.min(10, Math.max(3, t.batesDigits)) : DEFAULTS.batesDigits;
  const prefix = ascii(t.batesPrefix, 24).toUpperCase().replace(/[^A-Z0-9_-]/g, '') || DEFAULTS.batesPrefix;
  return {
    batesPrefix: prefix,
    batesDigits: digits,
    exhibitStyle: t.exhibitStyle === 'letter' ? 'letter' : 'number',
    exhibitWord: ascii(t.exhibitWord, 20) || DEFAULTS.exhibitWord,
    stampPosition: POSITIONS.includes(t.stampPosition) ? t.stampPosition : DEFAULTS.stampPosition,
    legend: ascii(t.legend, 80),
    slipSheets: t.slipSheets !== false,
    indexTitle: ascii(t.indexTitle, 60) || DEFAULTS.indexTitle,
  };
}

/// 1 -> "A", 26 -> "Z", 27 -> "AA".
function letters(n) {
  let s = '';
  let k = n;
  while (k > 0) {
    const r = (k - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    k = Math.floor((k - 1) / 26);
  }
  return s;
}

function exhibitId(n, template) {
  return template.exhibitStyle === 'letter' ? letters(n) : String(n);
}

function exhibitLabel(n, template) {
  return `${template.exhibitWord} ${exhibitId(n, template)}`;
}

function batesLabel(n, template) {
  return `${template.batesPrefix}-${String(n).padStart(template.batesDigits, '0')}`;
}

module.exports = { DEFAULTS, POSITIONS, resolveTemplate, letters, exhibitId, exhibitLabel, batesLabel, ascii };
