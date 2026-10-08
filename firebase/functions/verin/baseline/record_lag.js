// Verin Legal — the firm's own pre-Verin Record Lag (checklist #23).
//
// Captured once, when the firm connects its practice management system and
// before Verin starts receiving, then locked: without it the before-and-after
// comparison is lost for good.
//
//   From Clio:  documents added in the last 12 months, each one's "received"
//               date against the date it was added to the matter file. That is
//               the part of Record Lag a firm's system can show; Verin's own
//               Record Lag runs from the date the material was created, so the
//               method is stored with the number and shown next to it.
//   By hand:    an admin enters dated sample items (date the material was
//               created → date it entered the file) when the system has too few
//               dated documents. Same lock.

const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { requireAuth, requireAdmin } = require('../common/access');

if (!getApps().length) initializeApp();

const DAY = 86400000;
const MIN_SAMPLE = 20;

function quantile(sorted, q) {
  if (!sorted.length) return null;
  const pos = (sorted.length - 1) * q;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

/// pairs: [{ fromMs, toMs }] → { medianDays, p75Days, sample } (days, 1 decimal).
function summarize(pairs) {
  const days = pairs
    .filter((p) => Number.isFinite(p.fromMs) && Number.isFinite(p.toMs) && p.toMs >= p.fromMs)
    .map((p) => (p.toMs - p.fromMs) / DAY)
    .sort((a, b) => a - b);
  const r1 = (x) => (x === null ? null : Math.round(x * 10) / 10);
  return { medianDays: r1(quantile(days, 0.5)), p75Days: r1(quantile(days, 0.75)), sample: days.length };
}

/// Clio documents → pairs. Only documents whose received date was actually
/// set earlier than the upload (same-moment uploads say nothing about lag)
/// count toward the sample; the rest are reported as undated.
function clioPairs(docs) {
  const pairs = [];
  let undated = 0;
  for (const d of docs || []) {
    const added = Date.parse(d.created_at);
    const received = Date.parse(d.received_at);
    if (!Number.isFinite(added) || !Number.isFinite(received) || added - received < 60 * 60 * 1000) {
      undated++;
      continue;
    }
    pairs.push({ fromMs: received, toMs: added });
  }
  return { pairs, undated };
}

async function firmRef(db, firmId) {
  const s = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  return s.empty ? db.collection('firmAccount').doc(firmId) : s.docs[0].ref;
}

async function firstItemAt(db, firmId) {
  const s = await db.collection('Receipts').where('firmID', '==', firmId).orderBy('receivedAt', 'asc').limit(1).get().catch(() => null);
  if (!s || s.empty) return null;
  const v = s.docs[0].get('receivedAt');
  return v && v.toDate ? v.toDate() : null;
}

/// Writes the baseline once. Returns the stored value, or the existing one.
async function lockBaseline(db, firmId, value) {
  const ref = await firmRef(db, firmId);
  const first = await firstItemAt(db, firmId);
  return db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    const existing = cur.exists ? cur.get('baselineRecordLag') : null;
    if (existing && existing.medianDays !== null && existing.medianDays !== undefined) return { stored: false, baseline: existing };
    const baseline = {
      ...value,
      capturedAt: new Date().toISOString(),
      capturedBeforeFirstItem: !first,
      firstItemAt: first ? first.toISOString() : null,
    };
    tx.set(ref, { baselineRecordLag: baseline, baselineRecordLagLockedAt: FieldValue.serverTimestamp() }, { merge: true });
    return { stored: true, baseline };
  });
}

/// Called right after Clio connects. Never throws (connecting must not fail
/// because the baseline could not be read).
async function captureClioBaseline(db, session, firmId) {
  try {
    const since = new Date(Date.now() - 365 * DAY).toISOString();
    const docs = [];
    let pageToken = null;
    for (let page = 0; page < 10; page++) {
      const res = await session.request({
        path: '/documents.json',
        query: { fields: 'id,created_at,received_at', created_since: since, limit: 200, order: 'id(asc)', ...(pageToken ? { page_token: pageToken } : {}) },
      });
      docs.push(...((res && res.data) || []));
      const next = res && res.meta && res.meta.paging && res.meta.paging.next;
      const m = next ? /[?&]page_token=([^&]+)/.exec(next) : null;
      if (!m) break;
      pageToken = decodeURIComponent(m[1]);
    }
    const { pairs, undated } = clioPairs(docs);
    const s = summarize(pairs);
    const value = {
      source: 'clio',
      method: 'Clio documents added in the 12 months before connecting: date received → date added to the matter file.',
      documentsSeen: docs.length,
      undatedDocuments: undated,
      ...s,
      sufficient: s.sample >= MIN_SAMPLE,
    };
    if (!value.sufficient) {
      // Too few dated documents to stand on: kept as a note, not locked, so an
      // admin can enter a baseline by hand.
      const ref = await firmRef(db, firmId);
      await ref.set({ baselineRecordLagAttempt: { ...value, attemptedAt: new Date().toISOString() } }, { merge: true });
      return { stored: false, value };
    }
    return lockBaseline(db, firmId, value);
  } catch (e) {
    console.warn('baseline capture failed', firmId, e.message);
    return { stored: false, error: e.message };
  }
}

/// Admin, by hand: items: [{ createdOn: 'YYYY-MM-DD', enteredOn: 'YYYY-MM-DD' }].
exports.setBaselineRecordLag = onCall(async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { firmId } = await requireAdmin(db, uid);
  const items = Array.isArray((request.data || {}).items) ? request.data.items.slice(0, 500) : [];
  const pairs = items.map((i) => ({ fromMs: Date.parse(i.createdOn), toMs: Date.parse(i.enteredOn) }));
  const s = summarize(pairs);
  if (s.sample < 10) throw new HttpsError('invalid-argument', 'Enter at least 10 dated items (date created and date it entered your file).');
  const note = String((request.data || {}).note || '').slice(0, 500);
  return lockBaseline(db, firmId, {
    source: 'manual',
    method: `Entered by an admin from ${s.sample} sample items: date the material was created → date it entered the firm's file.${note ? ` ${note}` : ''}`,
    ...s,
    sufficient: true,
    enteredByUid: uid,
  });
});

exports._internal = { summarize, clioPairs, quantile, lockBaseline, MIN_SAMPLE };
exports.captureClioBaseline = captureClioBaseline;
