const test = require('node:test');
const assert = require('node:assert');
const JSZip = require('jszip');
const { splitMbox, listEntries, countsFrom } = require('../archive/import')._internal;

test('mbox is split into one message per item, with >From unescaped', () => {
  const mbox = 'From a@b Mon Jan 1 00:00:00 2026\nSubject: one\n\nhi\n>From the start\n\nFrom c@d Tue Jan 2 00:00:00 2026\nSubject: two\n\nyo\n';
  const msgs = splitMbox(Buffer.from(mbox));
  assert.strictEqual(msgs.length, 2);
  assert.match(msgs[0].toString(), /Subject: one/);
  assert.match(msgs[0].toString(), /\nFrom the start/);
  assert.match(msgs[1].toString(), /Subject: two/);
});

test('zip entries skip OS clutter and expand mailboxes', async () => {
  const z = new JSZip();
  z.file('Reyes/texts/IMG_0001.png', Buffer.from([1, 2, 3]));
  z.file('Reyes/.DS_Store', 'x');
  z.file('__MACOSX/Reyes/._IMG_0001.png', 'x');
  z.file('Reyes/mail.mbox', 'From a Mon\nSubject: s\n\nb\n\nFrom c Tue\nSubject: t\n\nd\n');
  const buf = await z.generateAsync({ type: 'nodebuffer' });
  const entries = await listEntries(buf, 'reyes.zip');
  assert.deepStrictEqual(entries.map((e) => e.name), ['mail-0001.eml', 'mail-0002.eml', 'IMG_0001.png']);
  assert.deepStrictEqual([...(await entries[2].load())], [1, 2, 3]);
});

test('counts: dated items are distinct, duplicates do not double count', () => {
  const c = countsFrom(
    [
      { id: '1', item_hash: 'a', resolvedDate: 1, classificationLabel: 'Processed' },
      { id: '2', item_hash: 'a', resolvedDate: 1, isDuplicate: true, classificationLabel: 'Processed' },
      { id: '3', item_hash: 'b', classificationLabel: 'Uncertain' },
      { id: '4', item_hash: 'c', extractionState: 'pending', classificationLabel: 'Processing' },
    ],
    { stats: { messages: 12, runs: 2 } },
  );
  assert.deepStrictEqual(c, { itemsReceived: 4, distinctDatedItems: 1, conversationsRebuilt: 2, messagesRebuilt: 12, itemsFlagged: 1, stillReading: 1 });
});
