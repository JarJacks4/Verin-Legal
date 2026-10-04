// Verin Legal — append-only hash chain per matter (chainEntries collection).
//
// Formula (confirmed on screen in the Receipt Detail drawer, guide §1c):
//   entry_hash = SHA256( prev_hash || item_hash || received_at || origin_digest )
//
// Concretely, as implemented here (and what an independent verifier must do):
//   prev_hash     hex entryHash of the previous entry for this matter, or 64 "0"s
//                 for the first entry (the chain root)
//   item_hash     hex SHA-256 of the exact received bytes
//   received_at   ISO-8601 UTC timestamp, millisecond precision, e.g.
//                 2026-10-03T17:20:11.123Z
//   origin_digest hex SHA-256 of canonical JSON {"channel":..,"source":..}
//                 (keys sorted, no whitespace) describing where the item came from
//   entry_hash    hex SHA-256 of the four strings joined with "|"
//
// Entries are appended inside a Firestore transaction, so two receipts landing
// at the same moment can't both claim the same seq or the same prev_hash.

const crypto = require('crypto');

const GENESIS = '0'.repeat(64);

function sha256Hex(input) {
  return crypto.createHash('sha256').update(input).digest('hex');
}

function canonicalJson(obj) {
  const keys = Object.keys(obj).sort();
  return '{' + keys.map((k) => JSON.stringify(k) + ':' + JSON.stringify(obj[k] == null ? '' : String(obj[k]))).join(',') + '}';
}

function originDigest({ channel, source }) {
  return sha256Hex(canonicalJson({ channel: channel || '', source: source || '' }));
}

function computeEntryHash({ prevHash, itemHash, receivedAtIso, originDigest: od }) {
  return sha256Hex([prevHash || GENESIS, itemHash, receivedAtIso, od].join('|'));
}

// Recompute a matter's chain from its entries (any order; sorted by seq here)
// and report the first break, if any.
//
// Entries written before server-side chaining existed (seeded/demo rows) don't
// carry their inputs (prevHash/itemHash/receivedAtIso/originDigest), so they
// can't be recomputed. They're counted as `legacy` and skipped; verification
// starts at the first entry that does carry its inputs, taking that entry's
// stored prevHash as given.
function verifyEntries(entries) {
  const sorted = [...entries].sort((a, b) => (a.seq || 0) - (b.seq || 0));
  const hasInputs = (e) =>
    typeof e.itemHash === 'string' && typeof e.prevHash === 'string' &&
    typeof e.receivedAtIso === 'string' && typeof e.originDigest === 'string';
  const start = sorted.findIndex(hasInputs);
  const legacy = start === -1 ? sorted.length : start;
  if (start === -1) return { ok: true, total: sorted.length, legacy, verified: 0, head: null };

  let prev = sorted[start].prevHash;
  let prevSeq = sorted[start].seq - 1;
  for (let i = start; i < sorted.length; i++) {
    const e = sorted[i];
    const fail = (reason) => ({ ok: false, total: sorted.length, legacy, verified: i - start, head: null, brokenAt: e.seq, reason });
    if (!hasInputs(e)) return fail('entry is missing its hash inputs');
    if (e.seq !== prevSeq + 1) return fail(`expected seq ${prevSeq + 1}, found ${e.seq}`);
    if (e.prevHash !== prev) return fail('prevHash does not match the previous entry');
    const expected = computeEntryHash({ prevHash: prev, itemHash: e.itemHash, receivedAtIso: e.receivedAtIso, originDigest: e.originDigest });
    if (expected !== e.entryHash) return fail('entryHash does not match its inputs');
    prev = e.entryHash;
    prevSeq = e.seq;
  }
  return { ok: true, total: sorted.length, legacy, verified: sorted.length - start, head: prev };
}

// Append one entry for `matterRef` inside transaction `tx`.
//
// The chain head (hash + length) is kept on the Matters document itself
// (chainHeadHash / chainLength) and updated in the same transaction. Two
// receipts landing at once both write that one document, so Firestore
// serializes them and neither can reuse the other's seq or prev_hash.
//
// Firestore transactions need every read before any write: do the caller's
// own reads first, then call this (it reads, then writes), then do the
// caller's remaining writes.
async function appendInTransaction(tx, db, { matterRef, receiptRef, itemHash, receivedAt, channel, source, serverTimestamp }) {
  const matterSnap = await tx.get(matterRef);
  if (!matterSnap.exists) throw new Error('matter not found');

  let prevHash = matterSnap.get('chainHeadHash');
  let length = matterSnap.get('chainLength');
  if (typeof prevHash !== 'string' || !prevHash || typeof length !== 'number') {
    // First append since this field was introduced: pick up any entries that
    // already exist (seeded/demo data) so seq keeps counting from there.
    const last = await tx.get(
      db.collection('chainEntries').where('matterID', '==', matterRef).orderBy('seq', 'desc').limit(1),
    );
    prevHash = last.empty ? GENESIS : last.docs[0].get('entryHash') || GENESIS;
    length = last.empty ? 0 : Number(last.docs[0].get('seq') || 0);
  }

  const seq = length + 1;
  const receivedAtIso = new Date(receivedAt).toISOString();
  const od = originDigest({ channel, source });
  const entryHash = computeEntryHash({ prevHash, itemHash, receivedAtIso, originDigest: od });

  const entryRef = db.collection('chainEntries').doc();
  const entry = {
    matterID: matterRef,
    receiptRef: receiptRef || null,
    seq,
    prevHash,
    itemHash,
    receivedAtIso,
    originDigest: od,
    entryHash,
    verificationBadge: 'Verified',
    createdAt: serverTimestamp(),
  };
  tx.set(entryRef, entry);
  tx.set(matterRef, { chainHeadHash: entryHash, chainLength: seq, hasChainRoot: true }, { merge: true });
  return { entryRef, entry, isRoot: seq === 1 };
}

module.exports = { GENESIS, sha256Hex, canonicalJson, originDigest, computeEntryHash, verifyEntries, appendInTransaction };
