// Verin Legal — reading the dates and times that message apps print.
//
// Apps print free text: "2:14 PM", "Yesterday 9:03 AM", "Tue, Mar 3 at 9:01",
// "3/3/26", "Today". This turns a label into what it actually says, and
// resolves it against an anchor date only as far as the label allows. Every
// resolved date carries how it was obtained (basis) and how far it can be
// trusted (confidence), so the record never states more than the evidence.
//
// Dates are wall-clock values with no time zone ("YYYY-MM-DD", "HH:MM"):
// a screenshot shows the phone's local time and nothing else.

const MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
const WEEKDAYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const LEVELS = ['none', 'low', 'medium', 'high'];

const MONTH_RE = '(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\.?';
const WEEKDAY_RE = /\b(sun|mon|tue|wed|thu|fri|sat)(?:day|s|sday|nesday|rsday|urday)?\b\.?/i;

const pad = (n) => String(n).padStart(2, '0');
const ymd = (y, m, d) => `${y}-${pad(m)}-${pad(d)}`;

function rank(c) {
  return LEVELS.indexOf(c || 'none');
}
function minConf(a, b) {
  return rank(a) <= rank(b) ? a : b;
}

function validDay(y, m, d) {
  if (!(m >= 1 && m <= 12 && d >= 1 && d <= 31 && y >= 1990 && y <= 2100)) return false;
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCMonth() === m - 1;
}

/// What a label says, before any anchoring:
/// { date: {y|null, m, d} | null, rel: 'today'|'yesterday'|null, weekday: 0-6|null, time: {h, min} | null }
function parseLabel(label) {
  const s = String(label || '').trim();
  const out = { date: null, rel: null, weekday: null, time: null };
  if (!s) return out;
  const low = s.toLowerCase();

  // Time: 2:14 PM, 2:14pm, 14:05, 2:14 p.m.
  let m = low.match(/\b(\d{1,2}):(\d{2})(?::\d{2})?\s*([ap])\.?\s*m\b\.?/);
  if (m) {
    let h = +m[1] % 12;
    if (m[3] === 'p') h += 12;
    if (+m[1] <= 12 && +m[2] < 60) out.time = { h, min: +m[2] };
  } else {
    m = low.match(/\b([01]?\d|2[0-3]):([0-5]\d)\b/);
    if (m) out.time = { h: +m[1], min: +m[2] };
  }

  // ISO 2026-03-03
  m = low.match(/\b(\d{4})-(\d{1,2})-(\d{1,2})\b/);
  if (m && validDay(+m[1], +m[2], +m[3])) {
    out.date = { y: +m[1], m: +m[2], d: +m[3] };
    return out;
  }
  // US numeric 3/3/2026, 03/03/26 (family-law clients are US-based; the
  // ambiguity with D/M/Y is real, so callers keep these at medium at most).
  m = low.match(/\b(\d{1,2})\/(\d{1,2})\/(\d{2}|\d{4})\b/);
  if (m) {
    let y = +m[3];
    if (y < 100) y += 2000;
    if (validDay(y, +m[1], +m[2])) {
      out.date = { y, m: +m[1], d: +m[2], numeric: true, ambiguous: +m[1] <= 12 && +m[2] <= 12 && m[1] !== m[2] };
      return out;
    }
  }
  // Mar 3, 2026 · March 3 · Tue, Mar 3 at 9:01 AM
  m = low.match(new RegExp(`\\b${MONTH_RE}\\s+(\\d{1,2})(?:st|nd|rd|th)?\\b(?:,?\\s+(\\d{4}))?`, 'i'));
  if (m) {
    const mo = MONTHS.indexOf(m[1].slice(0, 3)) + 1;
    const y = m[3] ? +m[3] : null;
    if (validDay(y || 2024, mo, +m[2])) {
      out.date = { y, m: mo, d: +m[2] };
      return out;
    }
  }
  // 3 March 2026 · 3 Mar
  m = low.match(new RegExp(`\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+${MONTH_RE}(?:,?\\s+(\\d{4}))?`, 'i'));
  if (m) {
    const mo = MONTHS.indexOf(m[2].slice(0, 3)) + 1;
    const y = m[3] ? +m[3] : null;
    if (validDay(y || 2024, mo, +m[1])) {
      out.date = { y, m: mo, d: +m[1] };
      return out;
    }
  }
  if (/\btoday\b/.test(low)) out.rel = 'today';
  else if (/\byesterday\b/.test(low)) out.rel = 'yesterday';
  else {
    const w = low.match(WEEKDAY_RE);
    if (w) out.weekday = WEEKDAYS.indexOf(w[1].slice(0, 3));
  }
  return out;
}

function addDays(dateStr, n) {
  const [y, m, d] = dateStr.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + n));
  return ymd(dt.getUTCFullYear(), dt.getUTCMonth() + 1, dt.getUTCDate());
}

function weekdayOf(dateStr) {
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}

/**
 * Resolves what a label says to a calendar date.
 *   parsed:  parseLabel() output
 *   anchor:  { date: 'YYYY-MM-DD', conf } — the day the screenshot was most
 *            likely taken (for "Today", "Yesterday", weekdays and missing years)
 * Returns { date: 'YYYY-MM-DD', basis, confidence } or null.
 */
function resolveDate(parsed, anchor) {
  const a = anchor && anchor.date ? anchor : null;
  if (parsed.date) {
    const { y, m, d, numeric, ambiguous } = parsed.date;
    if (y) {
      return { date: ymd(y, m, d), basis: 'explicit', confidence: ambiguous ? 'medium' : numeric ? 'high' : 'high' };
    }
    if (!a) return null;
    // No year printed: the most recent such day on or before the anchor.
    const ay = Number(a.date.slice(0, 4));
    let year = ay;
    if (ymd(ay, m, d) > addDays(a.date, 1)) year = ay - 1;
    if (!validDay(year, m, d)) return null;
    return { date: ymd(year, m, d), basis: 'year_inferred', confidence: minConf('medium', a.conf) };
  }
  if (!a) return null;
  if (parsed.rel === 'today') return { date: a.date, basis: 'relative', confidence: minConf('low', a.conf) };
  if (parsed.rel === 'yesterday') return { date: addDays(a.date, -1), basis: 'relative', confidence: minConf('low', a.conf) };
  if (parsed.weekday !== null && parsed.weekday !== undefined) {
    // Apps show a weekday for the past week; take the most recent one before the anchor.
    for (let k = 1; k <= 7; k++) {
      const c = addDays(a.date, -k);
      if (weekdayOf(c) === parsed.weekday) return { date: c, basis: 'relative', confidence: minConf('low', a.conf) };
    }
  }
  return null;
}

function timeStr(t) {
  return t ? `${pad(t.h)}:${pad(t.min)}` : '';
}

/// "YYYY-MM-DD" from a JS Date / Firestore Timestamp, in UTC, or ''.
function dayOf(v) {
  if (!v) return '';
  const d = typeof v.toDate === 'function' ? v.toDate() : v instanceof Date ? v : new Date(v);
  if (Number.isNaN(d.getTime())) return '';
  return ymd(d.getUTCFullYear(), d.getUTCMonth() + 1, d.getUTCDate());
}

module.exports = { LEVELS, rank, minConf, parseLabel, resolveDate, addDays, weekdayOf, timeStr, dayOf, validDay };
