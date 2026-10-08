// Firm-facing alerts (#15 provisioning, #29 oversize or unreadable sends,
// delivery failures). Shown to the firm's staff in the app until resolved.
// A dedupeKey keeps one open alert per problem instead of one per retry.
const { FieldValue } = require('firebase-admin/firestore');
const { firmDocRef } = require('./firm');

async function raiseAlert(db, firmId, { kind, message, matterId = '', dedupeKey = '', severity = 'warning', action = '' }) {
  if (!firmId) {
    console.warn('alert without firm', kind, message);
    return null;
  }
  const col = (await firmDocRef(db, firmId)).collection('alerts');
  const body = { kind, message: String(message).slice(0, 600), matterId, severity, action, resolved: false, updatedAt: FieldValue.serverTimestamp() };
  if (dedupeKey) {
    const ref = col.doc(dedupeKey.replace(/[^\w-]/g, '_').slice(0, 140));
    const cur = await ref.get();
    if (cur.exists && cur.get('resolved') === false) {
      await ref.set({ ...body, count: FieldValue.increment(1) }, { merge: true });
    } else {
      await ref.set({ ...body, count: 1, createdAt: FieldValue.serverTimestamp() });
    }
    return ref.id;
  }
  const ref = await col.add({ ...body, count: 1, createdAt: FieldValue.serverTimestamp() });
  return ref.id;
}

module.exports = { raiseAlert };
