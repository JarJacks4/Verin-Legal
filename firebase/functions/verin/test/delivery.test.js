const test = require('node:test');
const assert = require('node:assert');
const { removable, removeAfterDelivery, purgeDelivered } = require('../export/delivery')._internal;

function fakeDb(receipts) {
  const docs = new Map(Object.entries(receipts));
  return {
    docs,
    collection: () => ({
      doc: (id) => ({
        get: async () => ({ exists: docs.has(id), data: () => docs.get(id) }),
        set: async (v) => {
          const clean = {};
          for (const [k, x] of Object.entries(v)) clean[k] = x && x.constructor && x.constructor.name.includes('Transform') ? 'TS' : x;
          docs.set(id, { ...(docs.get(id) || {}), ...clean });
        },
      }),
    }),
  };
}
function fakeBucket(names) {
  const files = new Set(names);
  return {
    files,
    getFiles: async ({ prefix }) => [[...files].filter((n) => n.startsWith(prefix)).map((name) => ({ name }))],
    file: (name) => ({ delete: async () => files.delete(name) }),
  };
}

test('only finished, unheld items with a file are removable', () => {
  assert.strictEqual(removable({ sourceStoragePath: 'a', extractionState: 'extracted', classificationLabel: 'Processed' }), true);
  assert.strictEqual(removable({ sourceStoragePath: 'a', extractionState: 'pending' }), false);
  assert.strictEqual(removable({ sourceStoragePath: 'a', isQuarantined: true, extractionState: 'quarantined' }), false);
  assert.strictEqual(removable({ extractionState: 'extracted' }), false);
  assert.strictEqual(removable({ sourceStoragePath: 'a', extractionState: 'extracted', originalDeletedAt: 1 }), false);
});

test('firm setting defaults to removing files', () => {
  assert.strictEqual(removeAfterDelivery({}), true);
  assert.strictEqual(removeAfterDelivery({ deleteAfterDelivery: false }), false);
});

test('purge removes files but keeps the RFC 3161 token, and skips unfinished items', async () => {
  const db = fakeDb({
    r1: { sourceStoragePath: 'matters/m/receipts/r1.png', tsaTokenPath: 'matters/m/receipts/r1.tsr', extractionState: 'extracted', classificationLabel: 'Processed' },
    r2: { sourceStoragePath: 'matters/m/receipts/r2.png', extractionState: 'running' },
  });
  const bucket = fakeBucket(['matters/m/receipts/r1.png', 'matters/m/receipts/r1.tsr', 'matters/m/receipts/r1-thumb.jpg', 'matters/m/receipts/r2.png']);
  const res = await purgeDelivered({ db, bucket, matterRef: { id: 'm' }, matter: {}, firm: {}, deliveryId: 'd1', deliveredTo: 'Clio', receiptIds: ['r1', 'r2'] });
  assert.deepStrictEqual(res.removed, ['r1']);
  assert.strictEqual(res.kept[0].reason, 'not finished processing');
  assert.deepStrictEqual([...bucket.files].sort(), ['matters/m/receipts/r1.tsr', 'matters/m/receipts/r2.png']);
  assert.strictEqual(db.docs.get('r1').sourceUrl, '');
  assert.strictEqual(db.docs.get('r1').deliveryId, 'd1');
  assert.strictEqual(db.docs.get('r2').deliveryId, undefined);
});

test('demo workspaces and firms that keep files never lose files', async () => {
  for (const [matter, firm] of [[{ demo: true }, {}], [{}, { deleteAfterDelivery: false }]]) {
    const db = fakeDb({ r1: { sourceStoragePath: 'matters/m/receipts/r1.png', extractionState: 'extracted' } });
    const bucket = fakeBucket(['matters/m/receipts/r1.png']);
    const res = await purgeDelivered({ db, bucket, matterRef: { id: 'm' }, matter, firm, deliveryId: 'd', deliveredTo: 'Clio', receiptIds: ['r1'] });
    assert.deepStrictEqual(res.removed, []);
    assert.strictEqual(bucket.files.size, 1);
    assert.strictEqual(db.docs.get('r1').deliveryId, 'd');
  }
});
