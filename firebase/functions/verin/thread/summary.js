// Verin Legal — cited summaries of a matter's assembled thread.
//
//   summarizeThread  (callable) { matterId, topic? } → { lines: [{ text,
//                    cites: [entryKey] }], model, demo }
//
// Every line must cite at least one message of the thread by its key; lines
// that cite nothing, or cite a key that isn't in the thread, are dropped, so
// nothing in a summary stands without its source. Demo workspaces get a
// summary built from the thread itself, without calling a model.

const { getFirestore } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

const P = require('../common/params');
const { requireAuth, loadMatterForUser } = require('../common/access');

const MAX_MESSAGES = 600;

function messageLines(entries) {
  return entries
    .filter((e) => e.kind === 'msg' && e.key && e.text)
    .slice(-MAX_MESSAGES)
    .map((e) => `[${e.key}] ${e.date || 'undated'}${e.time ? ' ' + e.time : ''} ${e.speaker === 'client' ? 'CLIENT' : e.person || e.sender || 'OTHER'}: ${String(e.text).replace(/\s+/g, ' ').slice(0, 400)}`);
}

function buildSummaryRequest({ model, entries, topic, clientName }) {
  const focus = topic ? `Summarize only what concerns: ${topic}.` : 'Summarize the conversation as a whole.';
  return {
    model,
    max_tokens: 2000,
    system:
      'You summarize text-message evidence for attorneys. Write plain, neutral sentences of fact about what the messages say; ' +
      'never characterize motives, credibility or legal significance. Every sentence must cite the message keys it rests on. ' +
      'Reply with JSON only: {"lines":[{"text":"…","cites":["key", …]}]} — at most 12 lines, in date order.',
    messages: [
      {
        role: 'user',
        content: `${focus}\nCLIENT is ${clientName || 'the client'}. Messages, each with its key in brackets:\n\n${messageLines(entries).join('\n')}`,
      },
    ],
  };
}

/// Keeps only lines whose citations all exist in the thread.
function validateSummary(parsed, entries) {
  const keys = new Set(entries.filter((e) => e.kind === 'msg').map((e) => e.key));
  const lines = parsed && Array.isArray(parsed.lines) ? parsed.lines : [];
  const out = [];
  for (const l of lines) {
    const text = typeof l.text === 'string' ? l.text.trim() : '';
    const cites = Array.isArray(l.cites) ? [...new Set(l.cites.map(String))].filter((k) => keys.has(k)) : [];
    if (text && cites.length) out.push({ text: text.slice(0, 600), cites });
  }
  return out;
}

function parseJson(text) {
  const s = String(text || '');
  const a = s.indexOf('{');
  const b = s.lastIndexOf('}');
  if (a < 0 || b <= a) return null;
  try {
    return JSON.parse(s.slice(a, b + 1));
  } catch (_) {
    return null;
  }
}

/// Demo summary: one line per day of messages, citing them.
function cannedSummary(entries, topic) {
  const msgs = entries.filter((e) => e.kind === 'msg' && e.key && e.text);
  const words = String(topic || '').toLowerCase().split(/\W+/).filter((w) => w.length > 2);
  const pick = words.length ? msgs.filter((m) => words.some((w) => String(m.text).toLowerCase().includes(w))) : msgs;
  const byDay = new Map();
  for (const m of pick) {
    const d = m.date || 'undated';
    if (!byDay.has(d)) byDay.set(d, []);
    byDay.get(d).push(m);
  }
  const lines = [];
  for (const [day, ms] of byDay) {
    const who = (m) => (m.speaker === 'client' ? 'The client' : m.person || m.sender || 'The other party');
    const first = ms[0];
    const quote = String(first.text).replace(/\s+/g, ' ').slice(0, 120);
    const more = ms.length > 1 ? ` (${ms.length} messages that day)` : '';
    lines.push({ text: `${day === 'undated' ? 'Undated' : day}: ${who(first)} wrote "${quote}"${more}.`, cites: ms.slice(0, 6).map((m) => m.key) });
    if (lines.length >= 12) break;
  }
  return lines;
}

exports.summarizeThread = onCall({ secrets: [P.ANTHROPIC_API_KEY], timeoutSeconds: 120, memory: '512MiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const data = request.data || {};
  const { ref, snap } = await loadMatterForUser(db, uid, data.matterId);
  const topic = String(data.topic || '').trim().slice(0, 200);
  const t = await ref.collection('derived').doc('thread').get();
  const entries = t.exists && Array.isArray(t.get('entries')) ? t.get('entries') : [];
  if (!entries.some((e) => e.kind === 'msg')) throw new HttpsError('failed-precondition', 'There are no messages in this thread yet.');

  if (snap.get('demo') === true) return { lines: cannedSummary(entries, topic), model: 'demo', demo: true };

  const model = P.EXTRACTION_MODEL.value();
  const { anthropicClient } = require('../common/anthropic');
  const res = await anthropicClient({ timeout: 100000 }).messages.create(buildSummaryRequest({ model, entries, topic, clientName: snap.get('clientName') }));
  const text = (res.content || []).filter((b) => b.type === 'text').map((b) => b.text).join('');
  const lines = validateSummary(parseJson(text), entries);
  if (!lines.length) throw new HttpsError('internal', 'The summary could not be tied to specific messages. Try again or narrow the topic.');
  return { lines, model: res.model || model, demo: false };
});

exports._internal = { buildSummaryRequest, validateSummary, cannedSummary, parseJson };
