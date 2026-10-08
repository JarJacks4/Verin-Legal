// Shared numbers for Verin's reports, matching the app (lib/verin_app/data/model.dart).
const DAY = 86400000;
const toDate = (v) => (v && typeof v.toDate === 'function' ? v.toDate() : v instanceof Date ? v : v ? new Date(v) : null);

/// Days between an item's own date and the day it reached the firm (Record Lag).
function recordLagDays(receipts) {
  const out = [];
  for (const r of receipts) {
    if (r.isDuplicate === true) continue;
    const d = toDate(r.resolvedDate);
    const rec = toDate(r.receivedAt);
    if (!d || !rec || Number.isNaN(d.getTime()) || Number.isNaN(rec.getTime())) continue;
    const days = Math.round((rec - d) / DAY);
    if (days >= 0) out.push(days);
  }
  return out.sort((a, b) => a - b);
}

function median(sorted) {
  if (!sorted.length) return null;
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : Math.round((sorted[mid - 1] + sorted[mid]) / 2);
}

function percentile(sorted, q) {
  if (!sorted.length) return null;
  return sorted[Math.min(sorted.length - 1, Math.max(0, Math.ceil(q * sorted.length) - 1))];
}

/// The item that took longest to reach the firm.
function latestArriving(receipts) {
  let best = null;
  for (const r of receipts) {
    if (r.isDuplicate === true) continue;
    const d = toDate(r.resolvedDate);
    const rec = toDate(r.receivedAt);
    if (!d || !rec) continue;
    const lag = Math.round((rec - d) / DAY);
    if (lag >= 0 && (!best || lag > best.lagDays)) best = { ...r, lagDays: lag };
  }
  return best;
}

module.exports = { DAY, toDate, recordLagDays, median, percentile, latestArriving };
