// The firmAccount document for a firm. New firms use the firm id as the
// document id; older ones were created with another id, so look it up.
const cache = new Map();

async function firmDocRef(db, firmId) {
  if (!firmId) throw new Error('firmId required');
  if (cache.has(firmId)) return cache.get(firmId);
  const s = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  const ref = s.empty ? db.collection('firmAccount').doc(firmId) : s.docs[0].ref;
  cache.set(firmId, ref);
  return ref;
}

async function firmData(db, firmId) {
  const snap = await (await firmDocRef(db, firmId)).get();
  return snap.exists ? snap.data() : {};
}

module.exports = { firmDocRef, firmData };
