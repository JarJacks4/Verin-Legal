// Verin Legal — one conversation from many screenshots (Differentiator 2).
//
// Clients send overlapping screenshots, the same messages twice, screenshots
// out of order, with "Yesterday" instead of a date and a contact saved as
// "Mike" on one phone and "+1 555…" on another. This rebuilds one thread:
//
//   1. Each item's messages are dated from what is printed (headers, labels),
//      anchored to the item where a label is relative ("Today", "Tue").
//   2. Items are woven together in the order they arrived: shared messages
//      are matched, the first copy keeps its place and id, and later copies
//      are kept as "also in" references, never dropped. An item can extend a
//      run at either end or bridge two runs into one.
//   3. Joined runs are ordered by their dates, else by when they arrived.
//   4. Wherever continuity can't be proved, a gap is shown — between runs,
//      and wherever the reading saw a cut-off.
//   5. Sender names seen on each side are collected so a person can confirm
//      which names are the same person; nothing is merged on a guess.
//
// Pure functions: no Firebase. Inputs are plain receipt objects.

const { parseLabel, resolveDate, timeStr, dayOf, rank, minConf } = require('./dates');

const LOW_READ = 0.75;
const MIN_OVERLAP_CHARS = 25; // one shared message only links items when it's this long

function norm(s) {
  return String(s || '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .replace(/^[\s"'“”‘’.,!?]+|[\s"'“”‘’.,!?]+$/g, '')
    .trim();
}

/// Normalized key for "the same person": letters/digits only; phone numbers
/// keep their last 10 digits.
function personKey(name) {
  const s = String(name || '').trim();
  if (!s) return '';
  // An email address is the most specific identity a sender line carries.
  const mail = s.match(/[^\s<>"'(),;:]+@[^\s<>"'(),;:]+\.[a-z]{2,}/i);
  if (mail) return `mail:${mail[0].toLowerCase()}`;
  const digits = s.replace(/\D/g, '');
  if (digits.length >= 7 && !/\p{L}/u.test(s)) return `tel:${digits.slice(-10)}`;
  return s.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
}

/// The display-name part of a sender line ("Ben Miller <b@x.com>" -> "Ben Miller").
function displayName(sender) {
  return String(sender || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/[^\s<>"'(),;:]+@[^\s<>"'(),;:]+/g, ' ')
    .replace(/["']/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function nameTokens(s) {
  return String(s || '')
    .toLowerCase()
    .split(/[^\p{L}]+/u)
    .filter((t) => t.length >= 2);
}

/// True when a sender line names the client: their first and last names both
/// appear (middle names and initials may differ). Never matches on one name.
function namesClient(sender, clientName) {
  const c = nameTokens(clientName);
  if (c.length < 2) return false;
  const s = new Set(nameTokens(displayName(sender)));
  return s.has(c[0]) && s.has(c[c.length - 1]);
}

function msgKey(m) {
  return `${m.speaker}\u0000${norm(m.text)}`;
}

/// The day an item's relative labels are measured from. A full date printed in
/// the item is the best anchor; otherwise the day it reached the firm, which
/// is on or after the day it was captured (so relative dates stay "low").
function anchorFor(r) {
  const printed = dayOf(r.resolvedDate);
  if (printed && (r.dateConfidence === 'high' || r.dateConfidence === 'medium')) {
    return { date: printed, conf: r.dateConfidence, basis: 'item_date' };
  }
  const recv = dayOf(r.receivedAt);
  return recv ? { date: recv, conf: 'low', basis: 'received' } : null;
}

/// Dates every message of one item from its own labels and headers.
function dateSegment(r) {
  const anchor = anchorFor(r);
  const msgs = Array.isArray(r.threadMessages) ? r.threadMessages : [];
  let ctx = null; // { date, conf, basis }
  return msgs.map((m, i) => {
    const label = String(m.timestampLabel || '');
    const p = parseLabel(label);
    const own = resolveDate(p, anchor);
    let date = '';
    let basis = 'none';
    let confidence = 'none';
    if (own) {
      ({ date, basis, confidence } = own);
      ctx = own;
    } else if (ctx) {
      date = ctx.date;
      basis = m.isHeader ? ctx.basis : 'carried';
      confidence = ctx.confidence;
    }
    const time = timeStr(p.time);
    return {
      rid: r.id,
      i,
      key: `${r.id}#${i}`,
      kind: m.isHeader ? 'header' : 'msg',
      speaker: m.speaker === 'client' ? 'client' : 'other',
      sender: typeof m.senderName === 'string' ? m.senderName : '',
      text: String(m.text || ''),
      label,
      date,
      time: date ? time : '',
      timeOnly: !date && time ? time : '',
      dateBasis: basis,
      dateConfidence: confidence,
      read: typeof m.confidence === 'number' ? m.confidence : 1,
      cutBefore: !!m.isGap && !m.isHeader,
      platform: m.platform || r.detectedPlatform || '',
      alsoIn: [],
      flags: [],
    };
  });
}

function receivedMs(r) {
  const v = r.receivedAt;
  if (!v) return 0;
  const d = typeof v.toDate === 'function' ? v.toDate() : new Date(v);
  return Number.isNaN(d.getTime()) ? 0 : d.getTime();
}

function snippet(text, n = 60) {
  const t = String(text || '').replace(/\s+/g, ' ').trim();
  return t.length > n ? `${t.slice(0, n - 1)}…` : t;
}

/// Inserts e at pos and returns the next position. A date divider already
/// shown right there (the same header from an overlapping screenshot) is not
/// repeated.
function place(list, pos, e) {
  if (e.kind === 'header') {
    const same = (x) => x && x.kind === 'header' && norm(x.text) === norm(e.text);
    for (let j = pos - 1; j >= 0 && list[j].kind === 'header'; j--) if (same(list[j])) return pos;
    for (let j = pos; j < list.length && list[j].kind === 'header'; j++) if (same(list[j])) return pos;
  }
  list.splice(pos, 0, e);
  return pos + 1;
}

/// Shared stretches between an item's entries and a run: maximal blocks of
/// consecutive messages (headers skipped) that match in the same order, kept
/// only if two or more messages long, or one long message. Blocks are
/// monotonic in both sequences.
function findBlocks(segEntries, runEntries) {
  const seg = [];
  segEntries.forEach((e, idx) => {
    if (e.kind === 'msg' && norm(e.text)) seg.push({ e, idx });
  });
  const run = runEntries.filter((e) => e.kind === 'msg' && norm(e.text));
  const cands = [];
  for (let si = 0; si < seg.length; si++) {
    for (let ri = 0; ri < run.length; ri++) {
      if (msgKey(seg[si].e) !== msgKey(run[ri])) continue;
      if (si > 0 && ri > 0 && msgKey(seg[si - 1].e) === msgKey(run[ri - 1])) continue; // not maximal start
      let len = 0;
      while (si + len < seg.length && ri + len < run.length && msgKey(seg[si + len].e) === msgKey(run[ri + len])) len++;
      if (len >= 2 || norm(seg[si].e.text).length >= MIN_OVERLAP_CHARS) cands.push({ si, ri, len });
    }
  }
  cands.sort((x, y) => y.len - x.len || x.si - y.si);
  const chosen = [];
  for (const c of cands) {
    const ok = chosen.every((d) => (c.si + c.len <= d.si && c.ri + c.len <= d.ri) || (d.si + d.len <= c.si && d.ri + d.len <= c.ri));
    if (ok) chosen.push(c);
  }
  chosen.sort((x, y) => x.si - y.si);
  return chosen.map((c) => ({
    si: seg[c.si].idx,
    len: c.len,
    segIdx: seg.slice(c.si, c.si + c.len).map((x) => x.idx),
    runEntries: run.slice(c.ri, c.ri + c.len),
  }));
}

/**
 * receipts: [{ id, receivedAt, resolvedDate, dateConfidence, isDuplicate,
 *              threadMessages: [...], detectedPlatform, originalFileName }]
 * aliases:  { [personKey]: 'Display name' } confirmed by staff (optional)
 * Returns { entries, gaps, participants, stats, notes }.
 */
function reconstruct(receipts, { aliases = {}, sides = {}, clientName = '' } = {}) {
  const sources = receipts
    .filter((r) => !r.isDuplicate && Array.isArray(r.threadMessages) && r.threadMessages.length)
    .sort((x, y) => receivedMs(x) - receivedMs(y) || String(x.id).localeCompare(String(y.id)));

  // Weave each item into the record in arrival order. Whatever arrived first
  // keeps its place (and its message ids, which notes and exhibits cite);
  // later items add what's new around the messages they share.
  const runs = []; // { entries, members: [receiptId] }
  for (const r of sources) {
    const entries = dateSegment(r);
    const matched = []; // { run, blocks }
    for (const run of runs) {
      const blocks = findBlocks(entries, run.entries);
      if (blocks.length) matched.push({ run, blocks, first: blocks[0].si });
    }
    if (!matched.length) {
      runs.push({ entries: entries.slice(), members: [r.id] });
      continue;
    }
    matched.sort((x, y) => x.first - y.first);
    // seg message index -> kept entry it repeats
    const repeatOf = new Map();
    for (const { blocks } of matched) {
      for (const bl of blocks) for (let j = 0; j < bl.len; j++) repeatOf.set(bl.segIdx[j], bl.runEntries[j]);
    }
    const target = matched[0].run;
    const result = target.entries; // grows in place
    const merged = new Set([target]);
    const runOf = new Map();
    for (const { run, blocks } of matched) for (const bl of blocks) for (const e of bl.runEntries) runOf.set(e, run);

    // Entries before the first shared message go just before it.
    let cursor = -1;
    const pending = [];
    for (let idx = 0; idx < entries.length; idx++) {
      const e = entries[idx];
      const kept = repeatOf.get(idx);
      if (!kept) {
        if (cursor < 0) pending.push(e);
        else cursor = place(result, cursor, e);
        continue;
      }
      const owner = runOf.get(kept);
      if (!merged.has(owner)) {
        // This item bridges into another run: splice that run in here.
        result.splice(cursor < 0 ? result.length : cursor, 0, ...owner.entries);
        merged.add(owner);
        target.members.push(...owner.members);
        runs.splice(runs.indexOf(owner), 1);
      }
      kept.alsoIn.push(e.key);
      // A later screenshot may show the date the earlier one lacked.
      if (rank(e.dateConfidence) > rank(kept.dateConfidence)) {
        Object.assign(kept, { date: e.date, time: e.time || kept.time, dateBasis: e.dateBasis, dateConfidence: e.dateConfidence });
      }
      const at = result.indexOf(kept);
      if (pending.length) {
        let p = at;
        for (const pe of pending) p = place(result, p, pe);
        cursor = result.indexOf(kept) + 1;
        pending.length = 0;
      } else {
        cursor = at + 1;
      }
    }
    for (const pe of pending) place(result, result.length, pe);
    target.members.push(r.id);
  }

  for (const run of runs) {
    // Messages before an item's first dated line inherit the date reached in
    // the run (the screenshots are proven contiguous there).
    let ctx = null;
    for (const e of run.entries) {
      if (e.kind !== 'msg' && e.kind !== 'header') continue;
      if (e.date && e.dateBasis !== 'carried') ctx = e;
      else if (ctx && !e.date) {
        e.date = ctx.date;
        e.dateBasis = 'carried';
        e.dateConfidence = minConf(ctx.dateConfidence, 'medium');
      }
    }
    const dated = run.entries.filter((e) => e.kind === 'msg' && e.date && rank(e.dateConfidence) >= rank('medium'));
    run.firstDate = dated.length ? dated.reduce((m, e) => (e.date < m ? e.date : m), dated[0].date) : '';
    run.firstReceived = Math.min(...run.members.map((id) => receivedMs(sources.find((x) => x.id === id))));
  }

  // Order runs: by printed date where there is one, else by arrival.
  runs.sort((x, y) => {
    if (x.firstDate && y.firstDate && x.firstDate !== y.firstDate) return x.firstDate < y.firstDate ? -1 : 1;
    if (x.firstDate && !y.firstDate) return -1;
    if (!x.firstDate && y.firstDate) return 1;
    return x.firstReceived - y.firstReceived;
  });

  // Flatten, with gaps wherever continuity isn't proved.
  const entries = [];
  const gaps = [];
  const lastMsg = () => {
    for (let j = entries.length - 1; j >= 0; j--) if (entries[j].kind === 'msg') return entries[j];
    return null;
  };
  runs.forEach((run, ri) => {
    run.entries.forEach((e, ei) => {
      const startsRun = ei === 0 && ri > 0;
      if ((startsRun || e.cutBefore) && e.kind === 'msg') {
        const before = lastMsg();
        if (before) {
          const g = {
            key: `gap:${before.key}|${e.key}`,
            kind: 'gap',
            reason: startsRun ? 'not_proven' : 'cut_off',
            after: before.key,
            before: e.key,
            afterText: snippet(before.text),
            beforeText: snippet(e.text),
            afterDate: before.date,
            beforeDate: e.date,
          };
          entries.push(g);
          gaps.push(g);
        }
      } else if (startsRun) {
        const before = lastMsg();
        if (before) {
          const next = run.entries.find((x) => x.kind === 'msg');
          if (next) {
            const g = {
              key: `gap:${before.key}|${next.key}`,
              kind: 'gap',
              reason: 'not_proven',
              after: before.key,
              before: next.key,
              afterText: snippet(before.text),
              beforeText: snippet(next.text),
              afterDate: before.date,
              beforeDate: next.date,
            };
            entries.push(g);
            gaps.push(g);
          }
        }
      }
      entries.push(e);
    });
    for (const e of run.entries) e.orderBasis = run.firstDate ? 'date' : 'received';
  });

  // Which side each sender is on. Screenshots say it by bubble side; emails
  // and documents don't, so a side staff set for a name wins, then a sender
  // line that names the matter's client; otherwise the reading's own call.
  for (const e of entries) {
    if (e.kind !== 'msg' || !e.sender) continue;
    const pk = personKey(e.sender);
    if (sides[pk] === 'client' || sides[pk] === 'other') {
      e.speaker = sides[pk];
      e.sideBasis = 'confirmed';
    } else if (clientName && namesClient(e.sender, clientName)) {
      e.speaker = 'client';
      e.sideBasis = 'client_name';
    }
  }

  // Who is who: every name each side appears under.
  const names = { client: new Map(), other: new Map() };
  for (const e of entries) {
    if (e.kind !== 'msg' || !e.sender) continue;
    const pk = personKey(e.sender);
    if (!pk) continue;
    const m = names[e.speaker];
    const cur = m.get(pk) || { name: e.sender, key: pk, count: 0 };
    cur.count++;
    m.set(pk, cur);
  }
  const participants = {};
  for (const side of ['client', 'other']) {
    participants[side] = [...names[side].values()]
      .sort((a, b) => b.count - a.count)
      .map((n) => ({ ...n, confirmedAs: aliases[n.key] || '', side: sides[n.key] || '' }));
  }
  const otherNames = participants.other.length;

  // Per-entry flags for review.
  let maxDate = '';
  for (const e of entries) {
    if (e.kind !== 'msg') continue;
    if (!e.date) e.flags.push('no_date');
    else if (e.dateConfidence === 'low') e.flags.push('date_uncertain');
    else if (e.dateBasis === 'year_inferred') e.flags.push('year_inferred');
    if (e.date && rank(e.dateConfidence) >= rank('medium')) {
      if (maxDate && e.date < maxDate) e.flags.push('out_of_order');
      if (e.date > maxDate) maxDate = e.date;
    }
    if (e.read < LOW_READ) e.flags.push('hard_to_read');
    const pk = personKey(e.sender);
    e.person = pk && aliases[pk] ? aliases[pk] : displayName(e.sender) || e.sender || '';
    if (e.speaker === 'other') {
      if (!e.sender) e.flags.push('sender_not_shown');
      else if (otherNames > 1 && !aliases[pk] && !sides[pk]) e.flags.push('name_unconfirmed');
    }
  }

  const msgs = entries.filter((e) => e.kind === 'msg');
  const stats = {
    messages: msgs.length,
    repeatsFolded: msgs.reduce((n, e) => n + e.alsoIn.length, 0),
    gaps: gaps.length,
    undated: msgs.filter((e) => !e.date).length,
    uncertainDates: msgs.filter((e) => e.flags.includes('date_uncertain') || e.flags.includes('year_inferred')).length,
    outOfOrder: msgs.filter((e) => e.flags.includes('out_of_order')).length,
    hardToRead: msgs.filter((e) => e.flags.includes('hard_to_read')).length,
    items: sources.length,
    runs: runs.length,
  };

  const notes = [];
  if (stats.repeatsFolded) notes.push(`${stats.repeatsFolded} repeated message${stats.repeatsFolded === 1 ? '' : 's'} from overlapping screenshots are shown once; each keeps a link to every screenshot it appears in.`);
  if (runs.length > 1) notes.push(`The messages come from ${runs.length} separate runs that can't be proved continuous; each break is shown as a gap.`);
  if (stats.undated) notes.push(`${stats.undated} message${stats.undated === 1 ? ' has' : 's have'} no date anywhere in its screenshot.`);
  if (stats.uncertainDates) notes.push(`${stats.uncertainDates} date${stats.uncertainDates === 1 ? ' is' : 's are'} worked out from a relative label ("Yesterday", a weekday) or a missing year — check them.`);
  if (stats.outOfOrder) notes.push(`${stats.outOfOrder} message${stats.outOfOrder === 1 ? ' is' : 's are'} dated earlier than messages before it — the screenshots may have been sent out of order.`);
  if (otherNames > 1) notes.push(`The other side appears under ${otherNames} names (${participants.other.map((n) => `"${n.name}"`).join(', ')}). Confirm which are the same person.`);

  return { entries, gaps, participants, stats, notes };
}

module.exports = { reconstruct, dateSegment, findBlocks, personKey, displayName, namesClient, msgKey, norm, snippet, anchorFor, LOW_READ };
