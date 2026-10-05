// Verin Legal — what a new item changed, and what to ask the client for.
//
// classifyArrival (Differentiator 3): when an item finishes reading, compare
// the record before and after it: which messages are new, which were already
// there, which earlier entries it dates or re-dates, which gaps it closes, and
// whether it lands in the middle of the chronology rather than at the end.
//
// suggestFollowUps (Differentiator 4): specific requests for what's missing —
// the messages either side of a gap, a screenshot showing a date, a clearer
// copy of an unreadable one. Staff edit and approve every request; nothing is
// sent by Verin.

const { snippet, LOW_READ } = require('./reconstruct');
const { rank } = require('./dates');

function msgsOf(thread) {
  return thread ? thread.entries.filter((e) => e.kind === 'msg') : [];
}

function fmtDay(d) {
  if (!d) return '';
  const [y, m, day] = d.split('-').map(Number);
  const mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
  return `${mon} ${day}, ${y}`;
}

function dayOfTs(v) {
  if (!v) return '';
  const d = typeof v.toDate === 'function' ? v.toDate() : v instanceof Date ? v : new Date(v);
  return Number.isNaN(d.getTime()) ? '' : d.toISOString().slice(0, 10);
}

/**
 * receipt: the item that just finished reading ({ id, isDuplicate, resolvedDate,
 *          dateConfidence, threadMessages, headline })
 * before / after: reconstruct() results without and with it
 * others: the matter's other receipts (for non-conversation chronology)
 */
function classifyArrival({ receipt, before, after, others = [] }) {
  const kinds = [];
  const out = { kinds, newMessages: 0, repeatedMessages: 0, redated: 0, filledGaps: 0, placedBefore: 0, summary: '' };

  if (receipt.isDuplicate) {
    kinds.push('duplicate');
    out.summary = 'An exact copy of an item already in the record (same SHA-256). Kept and logged; nothing new added.';
    return out;
  }

  const mine = (e) => e.key.startsWith(`${receipt.id}#`);
  const own = Array.isArray(receipt.threadMessages) ? receipt.threadMessages.filter((m) => !m.isHeader && String(m.text || '').trim()) : [];

  if (own.length) {
    const afterMsgs = msgsOf(after);
    const kept = afterMsgs.filter(mine);
    out.newMessages = kept.length;
    // Messages already in the record: kept copies elsewhere that now also cite this item.
    out.repeatedMessages = afterMsgs.filter((e) => !mine(e) && e.alsoIn.some((k) => k.startsWith(`${receipt.id}#`))).length;

    // Where its new messages land: anything of before's after them?
    const beforeKeys = new Set(msgsOf(before).map((e) => e.key));
    if (kept.length && beforeKeys.size) {
      const lastNewIdx = Math.max(...kept.map((e) => afterMsgs.indexOf(e)));
      out.placedBefore = afterMsgs.slice(lastNewIdx + 1).filter((e) => beforeKeys.has(e.key)).length;
    }

    // Earlier entries it dates or re-dates (a fuller screenshot of the same messages).
    const prevByKey = new Map(msgsOf(before).map((e) => [e.key, e]));
    for (const e of afterMsgs) {
      const p = prevByKey.get(e.key);
      if (!p) continue;
      if (p.date !== e.date || rank(p.dateConfidence) !== rank(e.dateConfidence)) out.redated++;
    }

    // Gaps that existed before and are gone now.
    const afterGaps = new Set((after ? after.gaps : []).map((g) => g.key));
    out.filledGaps = (before ? before.gaps : []).filter((g) => !afterGaps.has(g.key)).length;

    if (out.newMessages === 0) kinds.push('already_in_record');
    else if (out.repeatedMessages > 0) kinds.push('overlaps');
    else kinds.push('new');
    // Filling a gap naturally puts messages before later ones; only flag
    // arrivals that go somewhere the record had no hole.
    if (out.placedBefore > 0 && out.filledGaps === 0) kinds.push('earlier_in_chronology');
    if (out.redated > 0) kinds.push('redates');
    if (out.filledGaps > 0) kinds.push('fills_gap');
  } else {
    // Documents, photos, emails, recordings: new, and where in time.
    kinds.push('new');
    const d = dayOfTs(receipt.resolvedDate);
    if (d && (receipt.dateConfidence === 'high' || receipt.dateConfidence === 'medium')) {
      out.placedBefore = others.filter((o) => !o.isDuplicate && o.id !== receipt.id && dayOfTs(o.resolvedDate) > d).length;
      if (out.placedBefore) kinds.push('earlier_in_chronology');
    }
  }

  const parts = [];
  if (kinds.includes('already_in_record')) parts.push(`Every message in it is already in the thread (${out.repeatedMessages} matched).`);
  else if (own.length) {
    parts.push(`${out.newMessages} new message${out.newMessages === 1 ? '' : 's'}`);
    if (out.repeatedMessages) parts.push(`${out.repeatedMessages} already in the record`);
  } else parts.push('New item');
  if (kinds.includes('earlier_in_chronology')) parts.push(`lands before ${out.placedBefore} ${own.length ? 'existing message' : 'later-dated item'}${out.placedBefore === 1 ? '' : 's'} in the chronology`);
  if (out.redated) parts.push(`dates or re-dates ${out.redated} earlier entr${out.redated === 1 ? 'y' : 'ies'}`);
  if (out.filledGaps) parts.push(`closes ${out.filledGaps} gap${out.filledGaps === 1 ? '' : 's'}`);
  out.summary = parts.join(' · ').replace(/\.$/, '') + '.';
  return out;
}

/**
 * Requests for missing evidence. Each has a stable key so a dismissed or sent
 * request doesn't come back when the thread is rebuilt.
 *   thread:   reconstruct() result
 *   receipts: the matter's receipts
 */
function suggestFollowUps({ thread, receipts = [] }) {
  const out = [];
  const label = (r) => r.originalFileName || r.headline || 'the item';

  for (const g of thread ? thread.gaps : []) {
    const when = g.afterDate && g.afterDate === g.beforeDate ? ` on ${fmtDay(g.afterDate)}` : g.afterDate ? ` after ${fmtDay(g.afterDate)}` : '';
    out.push({
      key: g.key,
      kind: g.reason === 'cut_off' ? 'cut_off' : 'gap',
      anchor: g.before,
      title: g.reason === 'cut_off' ? 'Messages cut off' : 'Missing messages between screenshots',
      request:
        `Please send screenshots of the messages between "${g.afterText}" and "${g.beforeText}"${when}. ` +
        'Scroll so each screenshot overlaps the previous one by a message or two, and include the date dividers.',
    });
  }

  // Items whose messages have no date at all.
  const undatedBy = new Map();
  for (const e of thread ? thread.entries : []) {
    if (e.kind !== 'msg' || e.date) continue;
    const rid = e.rid;
    if (!undatedBy.has(rid)) undatedBy.set(rid, e);
  }
  for (const [rid, e] of undatedBy) {
    const r = receipts.find((x) => x.id === rid);
    out.push({
      key: `date:${rid}`,
      kind: 'date',
      anchor: e.key,
      receiptId: rid,
      title: 'No date visible',
      request: `In ${r ? `"${label(r)}"` : 'one of your screenshots'}, no date is visible for the messages starting "${snippet(e.text)}". Please scroll up until a date appears above them and send that screenshot too.`,
    });
  }

  // Hard-to-read screenshots.
  for (const r of receipts) {
    if (r.isDuplicate) continue;
    const msgs = Array.isArray(r.threadMessages) ? r.threadMessages : [];
    const low = msgs.filter((m) => !m.isHeader && typeof m.confidence === 'number' && m.confidence < LOW_READ);
    if (low.length) {
      out.push({
        key: `clear:${r.id}`,
        kind: 'clarity',
        anchor: `${r.id}#${msgs.indexOf(low[0])}`,
        receiptId: r.id,
        title: 'Hard to read',
        request: `Part of "${label(r)}" is hard to read (for example "${snippet(low[0].text)}"). Please send it again as the original screenshot — not cropped, forwarded or photographed from another screen.`,
      });
    }
    if (r.extractionState === 'extraction_failed') {
      out.push({
        key: `resend:${r.id}`,
        kind: 'resend',
        receiptId: r.id,
        title: 'Could not be read',
        request: `We couldn't read "${label(r)}". If you can, please send it again as a PDF or a PNG/JPEG screenshot.`,
      });
    }
  }

  // Names the other side appears under that nobody has confirmed: one question.
  const others = thread ? thread.participants.other : [];
  const open = others.filter((x) => !x.confirmedAs);
  if (others.length > 1 && open.length) {
    const list = others.map((o) => `"${o.name}"`);
    const names = list.length === 2 ? list.join(' and ') : `${list.slice(0, -1).join(', ')} and ${list[list.length - 1]}`;
    out.push({
      key: `who:${open.map((o) => o.key).sort().join('|')}`,
      kind: 'identity',
      title: 'Who is this?',
      request: `The other side's messages appear under ${names}. Are these the same person? If not, who is each one?`,
    });
  }
  return out;
}

module.exports = { classifyArrival, suggestFollowUps, fmtDay };
