// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const src = require('../evidence/source');
const { validateAnalysis, ANALYSIS_SCHEMA, MESSAGE_SCHEMA } = require('../evidence/analyze');

const imgs = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures/images.json'), 'utf8'));
const buf = (k) => Buffer.from(imgs[k], 'base64');

test('image sizes from PNG, JPEG, GIF and WebP headers', () => {
  assert.deepEqual(src.imageSize(buf('PNG')), { width: 37, height: 21 });
  assert.deepEqual(src.imageSize(buf('JPEG')), { width: 64, height: 48 });
  assert.deepEqual(src.imageSize(buf('GIF')), { width: 5, height: 9 });
  assert.deepEqual(src.imageSize(buf('WEBP')), { width: 40, height: 30 });
  assert.equal(src.imageSize(Buffer.from('not an image at all, just text....')), null);
});

test('a rotated JPEG reports the size the browser displays', () => {
  assert.equal(src.jpegOrientation(buf('JPEG6')), 6);
  assert.deepEqual(src.imageSize(buf('JPEG6')), { width: 48, height: 64 });
});

test('boxes: plausible kept and clamped, impossible dropped', () => {
  assert.deepEqual(src.cleanBox({ x: 0.1, y: 0.2, w: 0.5, h: 0.1 }), { x: 0.1, y: 0.2, w: 0.5, h: 0.1 });
  assert.deepEqual(src.cleanBox({ x: -0.005, y: 0, w: 1.0, h: 0.2 }), { x: 0, y: 0, w: 1, h: 0.2 });
  assert.equal(src.cleanBox({ x: 0, y: 0, w: 0, h: 0 }), null); // "unknown"
  assert.equal(src.cleanBox({ x: 0.9, y: 0.1, w: 0.5, h: 0.1 }), null); // runs off the image
  assert.equal(src.cleanBox({ x: '0.1', y: 0, w: 0.2, h: 0.2 }), null);
  assert.equal(src.cleanBox(null), null);
});

test('message source keeps name, page, box and video time only when valid', () => {
  assert.deepEqual(src.messageSource({ senderName: ' Mike R. ', page: 0, box: { x: 0.1, y: 0.1, w: 0.3, h: 0.05 } }), {
    senderName: 'Mike R.',
    box: { x: 0.1, y: 0.1, w: 0.3, h: 0.05 },
  });
  assert.deepEqual(src.messageSource({ senderName: '', page: 3, box: { x: 0, y: 0, w: 0, h: 0 } }), { page: 3 });
  assert.deepEqual(src.messageSource({ atSeconds: 12.4 }), { atSeconds: 12 });
});

test('statements: invalid ones skipped and counted, capped at 25', () => {
  const r = src.cleanStatements([
    { text: 'Custody hearing set for March 3, 2026.', kind: 'date', page: 2, box: { x: 0, y: 0, w: 0, h: 0 } },
    { text: '', kind: 'date', page: 0, box: {} },
    { text: 'Pay $400 per month', kind: 'money', page: 0, box: {} },
  ]);
  assert.deepEqual(r.statements, [{ text: 'Custody hearing set for March 3, 2026.', kind: 'date', page: 2 }]);
  assert.equal(r.skipped, 2);
  const many = Array.from({ length: 40 }, (_, i) => ({ text: `line ${i}`, kind: 'other', page: 0, box: {} }));
  assert.equal(src.cleanStatements(many).statements.length, 25);
});

test('the analysis schema asks for locations, and validation carries them through', () => {
  assert.ok(MESSAGE_SCHEMA.required.includes('box'));
  assert.ok(ANALYSIS_SCHEMA.required.includes('statements'));
  const parsed = {
    evidenceType: 'conversation',
    summary: 'A text thread.',
    eventDate: '',
    eventDateSource: '',
    eventDateConfidence: 'none',
    containsConversation: true,
    platform: 'iMessage',
    messages: [
      { speaker: 'other', text: 'Pick up at 5', timestampLabel: '2:14 PM', isGap: false, confidence: 0.9, isHeader: false, senderName: 'Mike', page: 0, box: { x: 0.05, y: 0.3, w: 0.5, h: 0.06 } },
      { speaker: 'client', text: 'ok', timestampLabel: '', isGap: false, confidence: 0.95, isHeader: false, senderName: '', page: 0, box: { x: 0, y: 0, w: 0, h: 0 } },
    ],
    statements: [],
  };
  const v = validateAnalysis(parsed);
  assert.equal(v.ok, true);
  assert.deepEqual(v.value.messageSources, [{ senderName: 'Mike', box: { x: 0.05, y: 0.3, w: 0.5, h: 0.06 } }, {}]);
});
