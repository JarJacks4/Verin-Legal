// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const D = require('../thread/dates');
const T = require('../thread/reconstruct');

test('labels: what apps print', () => {
  assert.deepEqual(D.parseLabel('2:14 PM').time, { h: 14, min: 14 });
  assert.deepEqual(D.parseLabel('12:05 am').time, { h: 0, min: 5 });
  assert.deepEqual(D.parseLabel('17:40').time, { h: 17, min: 40 });
  assert.deepEqual(D.parseLabel('Tue, Mar 3, 2026 at 9:01 AM').date, { y: 2026, m: 3, d: 3 });
  assert.deepEqual(D.parseLabel('March 3').date, { y: null, m: 3, d: 3 });
  assert.deepEqual(D.parseLabel('3 March 2026').date, { y: 2026, m: 3, d: 3 });
  assert.equal(D.parseLabel('Yesterday 9:03 AM').rel, 'yesterday');
  assert.equal(D.parseLabel('Today').rel, 'today');
  assert.equal(D.parseLabel('Tuesday 4:10 PM').weekday, 2);
  assert.equal(D.parseLabel('3/14/26').date.y, 2026);
  assert.equal(D.parseLabel('3/4/26').date.ambiguous, true);
  assert.equal(D.parseLabel('market 3').date, null);
  assert.equal(D.parseLabel('').time, null);
});

test('dates resolve only as far as the label allows', () => {
  const anchor = { date: '2026-03-10', conf: 'low' }; // a Tuesday
  assert.deepEqual(D.resolveDate(D.parseLabel('Mar 3, 2026'), anchor), { date: '2026-03-03', basis: 'explicit', confidence: 'high' });
  assert.deepEqual(D.resolveDate(D.parseLabel('Yesterday'), anchor), { date: '2026-03-09', basis: 'relative', confidence: 'low' });
  assert.deepEqual(D.resolveDate(D.parseLabel('Friday 8:00 PM'), anchor), { date: '2026-03-06', basis: 'relative', confidence: 'low' });
  // No year printed: the most recent such day, never the future.
  assert.deepEqual(D.resolveDate(D.parseLabel('Dec 30'), anchor), { date: '2025-12-30', basis: 'year_inferred', confidence: 'low' });
  assert.deepEqual(D.resolveDate(D.parseLabel('Mar 1'), { date: '2026-03-10', conf: 'high' }), { date: '2026-03-01', basis: 'year_inferred', confidence: 'medium' });
  assert.equal(D.resolveDate(D.parseLabel('Yesterday'), null), null);
  assert.equal(D.resolveDate(D.parseLabel('3/4/26'), null).confidence, 'medium'); // M/D vs D/M
});

const msg = (speaker, text, extra = {}) => ({ speaker, text, timestampLabel: '', isGap: false, confidence: 0.95, isHeader: false, ...extra });
const hdr = (label) => ({ speaker: 'other', text: label, timestampLabel: label, isGap: false, confidence: 1, isHeader: true });
const rec = (id, receivedAt, threadMessages, extra = {}) => ({ id, receivedAt: new Date(receivedAt), threadMessages, ...extra });

test('overlapping screenshots join into one thread, in either upload order', () => {
  const a = rec('A', '2026-03-10T12:00:00Z', [hdr('Mar 3, 2026'), msg('other', 'Can you take the kids Friday?'), msg('client', 'I have work until 6'), msg('other', 'Then I will keep them all weekend')]);
  const b = rec('B', '2026-03-10T11:00:00Z', [msg('client', 'I have work until 6'), msg('other', 'Then I will keep them all weekend'), msg('client', 'That is not what the order says')]);
  const t = T.reconstruct([b, a]); // B arrived first but continues A
  const texts = t.entries.filter((e) => e.kind === 'msg').map((e) => e.text);
  assert.deepEqual(texts, ['Can you take the kids Friday?', 'I have work until 6', 'Then I will keep them all weekend', 'That is not what the order says']);
  assert.equal(t.gaps.length, 0);
  // B arrived first, so its copy is the one kept (ids stay stable for notes).
  const kept = t.entries.find((e) => e.text === 'I have work until 6');
  assert.equal(kept.key, 'B#0');
  assert.deepEqual(kept.alsoIn, ['A#2']);
  assert.equal(kept.date, '2026-03-03'); // A showed the date B lacked
  // B's last message has no label of its own; the join proves it follows Mar 3.
  const last = t.entries.find((e) => e.text === 'That is not what the order says');
  assert.equal(last.date, '2026-03-03');
  assert.equal(last.dateBasis, 'carried');
  assert.equal(t.stats.repeatsFolded, 2);
});

test('a single short shared message does not join strangers', () => {
  const a = rec('A', '2026-03-10T10:00:00Z', [msg('other', 'where are you'), msg('client', 'ok')]);
  const b = rec('B', '2026-03-11T10:00:00Z', [msg('client', 'ok'), msg('other', 'see you then')]);
  const t = T.reconstruct([a, b]);
  assert.equal(t.gaps.length, 1);
  assert.equal(t.gaps[0].reason, 'not_proven');
});

test('unconnected runs are ordered by printed date and separated by a gap', () => {
  const late = rec('L', '2026-03-10T09:00:00Z', [hdr('Mar 9, 2026'), msg('other', 'You are late again'), msg('client', 'Traffic')]);
  const early = rec('E', '2026-03-10T10:00:00Z', [hdr('Feb 2, 2026'), msg('other', 'Here is the schedule'), msg('client', 'Thanks')]);
  const t = T.reconstruct([late, early]);
  const texts = t.entries.map((e) => e.text || `[${e.reason}]`);
  assert.deepEqual(texts, ['Feb 2, 2026', 'Here is the schedule', 'Thanks', '[not_proven]', 'Mar 9, 2026', 'You are late again', 'Traffic']);
  assert.equal(t.entries.find((e) => e.text === 'Thanks').orderBasis, 'date');
});

test('a screenshot wholly inside another adds references, not copies', () => {
  const a = rec('A', '2026-03-10T10:00:00Z', [msg('other', 'Pick them up at the school at 3:15 please'), msg('client', 'Will do'), msg('other', 'Thanks')]);
  const b = rec('B', '2026-03-10T11:00:00Z', [msg('other', 'Pick them up at the school at 3:15 please'), msg('client', 'Will do')]);
  const t = T.reconstruct([a, b]);
  assert.equal(t.entries.filter((e) => e.kind === 'msg').length, 3);
  assert.deepEqual(t.entries[0].alsoIn, ['B#0']);
});

test('exact duplicates (same file hash) are left out of the thread', () => {
  const a = rec('A', '2026-03-10T10:00:00Z', [msg('other', 'hello there, this is a long message')]);
  const b = rec('B', '2026-03-10T11:00:00Z', [msg('other', 'hello there, this is a long message')], { isDuplicate: true });
  assert.equal(T.reconstruct([a, b]).stats.items, 1);
});

test('relative dates are flagged, cut-offs become gaps, unreadable lines are flagged', () => {
  const r = rec('A', '2026-03-10T15:00:00Z', [
    hdr('Yesterday 9:03 AM'),
    msg('other', 'Why did you not answer'),
    msg('client', '[illegible] the kids', { confidence: 0.4 }),
    msg('other', 'Answer me', { isGap: true }),
  ]);
  const t = T.reconstruct([r]);
  const m = t.entries.filter((e) => e.kind === 'msg');
  assert.equal(m[0].date, '2026-03-09');
  assert.ok(m[0].flags.includes('date_uncertain'));
  assert.ok(m[1].flags.includes('hard_to_read'));
  assert.equal(t.gaps.length, 1);
  assert.equal(t.gaps[0].reason, 'cut_off');
});

test('names: every name the other side appears under is listed until confirmed', () => {
  const r1 = rec('A', '2026-03-10T10:00:00Z', [msg('other', 'first message here', { senderName: 'Mike' })]);
  const r2 = rec('B', '2026-03-11T10:00:00Z', [msg('other', 'second message here', { senderName: '+1 (555) 201-3344' })]);
  const t = T.reconstruct([r1, r2]);
  assert.deepEqual(t.participants.other.map((p) => p.key), ['mike', 'tel:5552013344']);
  assert.ok(t.entries.find((e) => e.text === 'first message here').flags.includes('name_unconfirmed'));
  const t2 = T.reconstruct([r1, r2], { aliases: { mike: 'Michael Reyes', 'tel:5552013344': 'Michael Reyes' } });
  const e = t2.entries.find((x) => x.text === 'second message here');
  assert.equal(e.person, 'Michael Reyes');
  assert.ok(!e.flags.includes('name_unconfirmed'));
});

test('a later screenshot showing a date fills it in for the overlap', () => {
  const a = rec('A', '2026-03-10T10:00:00Z', [msg('other', 'Bring the passports on Saturday'), msg('client', 'I will bring them both')]);
  const b = rec('B', '2026-03-10T11:00:00Z', [msg('other', 'Bring the passports on Saturday', { timestampLabel: 'Feb 27, 2026 6:02 PM' }), msg('client', 'I will bring them both'), msg('other', 'Good')]);
  const t = T.reconstruct([a, b]);
  const first = t.entries.find((e) => e.text === 'Bring the passports on Saturday');
  assert.equal(first.date, '2026-02-27');
  assert.equal(first.dateConfidence, 'high');
});

const U = require('../thread/updates');

test('arrivals: new, overlapping, earlier in the chronology, closing a gap', () => {
  const a = rec('A', '2026-03-10T10:00:00Z', [hdr('Mar 9, 2026'), msg('other', 'You are late again tonight'), msg('client', 'Traffic was bad on 65')]);
  const c = rec('C', '2026-03-10T12:00:00Z', [hdr('Mar 1, 2026'), msg('other', 'New schedule starts this week'), msg('client', 'Fine by me')]);
  const before = T.reconstruct([a]);
  const after = T.reconstruct([a, c]);
  const r = U.classifyArrival({ receipt: c, before, after });
  assert.deepEqual(r.kinds, ['new', 'earlier_in_chronology']);
  assert.equal(r.newMessages, 2);
  assert.equal(r.placedBefore, 2);
  assert.match(r.summary, /2 new messages · lands before 2 existing messages/);

  // A screenshot that bridges C and A closes the gap between them.
  const bridge = rec('B', '2026-03-11T09:00:00Z', [msg('other', 'New schedule starts this week'), msg('client', 'Fine by me'), msg('other', 'Then pick up is Monday at 5'), msg('other', 'You are late again tonight'), msg('client', 'Traffic was bad on 65')]);
  const r2 = U.classifyArrival({ receipt: bridge, before: after, after: T.reconstruct([a, c, bridge]) });
  assert.ok(r2.kinds.includes('overlaps'));
  assert.ok(r2.kinds.includes('fills_gap'));
  assert.ok(!r2.kinds.includes('earlier_in_chronology'));
  assert.equal(r2.newMessages, 1);
  assert.equal(r2.repeatedMessages, 4);
  // The earlier items keep their ids; the bridge only adds its one new message.
  const t3 = T.reconstruct([a, c, bridge]);
  assert.deepEqual(t3.entries.map((e) => e.key), ['C#0', 'C#1', 'C#2', 'B#2', 'A#0', 'A#1', 'A#2']);
  assert.equal(t3.gaps.length, 0);
});

test('arrivals: exact duplicates and already-recorded screenshots', () => {
  const a = rec('A', '2026-03-10T10:00:00Z', [msg('other', 'Pick them up at the school at 3:15 please'), msg('client', 'Will do')]);
  const dup = rec('D', '2026-03-10T11:00:00Z', a.threadMessages, { isDuplicate: true });
  assert.deepEqual(U.classifyArrival({ receipt: dup, before: T.reconstruct([a]), after: T.reconstruct([a, dup]) }).kinds, ['duplicate']);
  const again = rec('E', '2026-03-10T12:00:00Z', [msg('other', 'Pick them up at the school at 3:15 please'), msg('client', 'Will do')]);
  const r = U.classifyArrival({ receipt: again, before: T.reconstruct([a]), after: T.reconstruct([a, again]) });
  assert.deepEqual(r.kinds, ['already_in_record']);
  assert.equal(r.repeatedMessages, 2);
});

test('arrivals: a dated document that lands mid-chronology', () => {
  const d1 = { id: 'X', resolvedDate: new Date('2026-04-01T12:00:00Z'), dateConfidence: 'high' };
  const doc = { id: 'Y', resolvedDate: new Date('2026-02-01T12:00:00Z'), dateConfidence: 'high' };
  const r = U.classifyArrival({ receipt: doc, before: null, after: null, others: [d1, doc] });
  assert.deepEqual(r.kinds, ['new', 'earlier_in_chronology']);
  assert.match(r.summary, /lands before 1 later-dated item/);
});

test('follow-ups: specific requests for gaps, dates, clarity and identity', () => {
  const a = rec('A', '2026-03-10T10:00:00Z', [hdr('Mar 9, 2026'), msg('other', 'You are late again tonight', { senderName: 'Mike' })], { originalFileName: 'IMG_1.png' });
  const b = rec('B', '2026-03-11T10:00:00Z', [msg('other', 'Answer your phone', { senderName: '+1 555 201 3344', confidence: 0.5 })], { originalFileName: 'IMG_2.png' });
  const thread = T.reconstruct([a, b]);
  const s = U.suggestFollowUps({ thread, receipts: [a, b] });
  const kinds = s.map((x) => x.kind).sort();
  assert.deepEqual(kinds, ['clarity', 'date', 'gap', 'identity']);
  assert.match(s.find((x) => x.kind === 'identity').request, /"Mike" and "\+1 555 201 3344"/);
  const gap = s.find((x) => x.kind === 'gap');
  assert.match(gap.request, /between "You are late again tonight" and "Answer your phone" after Mar 9, 2026/);
  const keys = new Set(s.map((x) => x.key));
  assert.equal(keys.size, s.length); // stable, unique keys
});

const RB = require('../thread/rebuild');

test('rebuild: only reading changes trigger a rebuild', () => {
  const base = { threadMessages: [msg('other', 'hi')], extractionState: 'extracted', classificationLabel: 'Processed' };
  assert.equal(RB.signature(base), RB.signature({ ...base, classificationLabel: 'Uncertain', reviewedAt: new Date() }));
  assert.notEqual(RB.signature(base), RB.signature({ ...base, threadMessages: [msg('other', 'hello')] }));
});

test('rebuild: an oversized thread is trimmed to fit one document', () => {
  const big = { entries: Array.from({ length: 600 }, (_, i) => ({ kind: 'msg', key: `A#${i}`, text: 'x'.repeat(3000) })) };
  const out = RB.fitThread(big);
  assert.ok(JSON.stringify(out).length <= 900000);
  assert.equal(out.truncated, true);
});

test('email senders: the client by name, others by confirmed side, keys by address', () => {
  const r = rec('E', '2026-03-10T10:00:00Z', [
    msg('other', 'Of course. I want your views.', { senderName: 'Ben miller <bmiller2005@gmail.com>' }),
    msg('other', 'Sure, we can wipe the slate clean.', { senderName: 'Courtney Miller <curtis.courtney@gmail.com>' }),
  ]);
  assert.equal(T.personKey('Ben miller <bmiller2005@gmail.com>'), 'mail:bmiller2005@gmail.com');
  assert.equal(T.displayName('Ben miller <bmiller2005@gmail.com>'), 'Ben miller');
  assert.equal(T.namesClient('Courtney Miller <curtis.courtney@gmail.com>', 'Courtney Curtis Miller'), true);
  assert.equal(T.namesClient('Ben miller <b@x.com>', 'Courtney Curtis Miller'), false);
  assert.equal(T.namesClient('Courtney', 'Courtney Curtis Miller'), false); // one name never matches

  const t = T.reconstruct([r], { clientName: 'Courtney Curtis Miller' });
  const [ben, courtney] = t.entries.filter((e) => e.kind === 'msg');
  assert.equal(ben.speaker, 'other');
  assert.equal(ben.person, 'Ben miller');
  assert.equal(courtney.speaker, 'client');
  assert.equal(courtney.sideBasis, 'client_name');

  // Staff can put any name on either side.
  const t2 = T.reconstruct([r], { sides: { 'mail:bmiller2005@gmail.com': 'client', 'mail:curtis.courtney@gmail.com': 'other' } });
  const [b2, c2] = t2.entries.filter((e) => e.kind === 'msg');
  assert.equal(b2.speaker, 'client');
  assert.equal(c2.speaker, 'other');
  assert.equal(b2.sideBasis, 'confirmed');
});
