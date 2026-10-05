const test = require('node:test');
const assert = require('node:assert');
const { screenshot, dayLabel } = require('../demo/seed')._internal;
const { simplePdf } = require('../demo/screens');

test('demo screenshot has a box per message, inside the image', () => {
  const s = screenshot({ contact: 'Marcus', items: [{ header: dayLabel(new Date()) }, { side: 'other', text: 'hello there' }, { side: 'client', text: 'hi' }] });
  assert.strictEqual(s.messages.length, 3);
  assert.ok(s.messages[0].isHeader);
  assert.strictEqual(s.messages[2].speaker, 'client');
  for (const m of s.messages) {
    assert.ok(m.box.x >= 0 && m.box.y >= 0 && m.box.x + m.box.w <= 1.001 && m.box.y + m.box.h <= 1.001);
  }
  assert.strictEqual(s.buffer.slice(1, 4).toString(), 'PNG');
});

test('demo pdf has a box per text line', async () => {
  const p = await simplePdf([{ text: 'Title', bold: true, size: 16 }, { text: 'Line two' }]);
  assert.strictEqual(p.boxes.length, 2);
  assert.strictEqual(p.pdf.slice(0, 4).toString(), '%PDF');
});
