// Verin Legal — video redaction: the filter string is the whole security
// boundary, so it is tested on its own, without ffmpeg.

const test = require('node:test');
const assert = require('node:assert');

const V = (() => {
  const Module = require('module');
  const realLoad = Module._load;
  Module._load = function (req) {
    if (req === 'firebase-admin/firestore') return { getFirestore: () => null, FieldValue: {} };
    if (req === 'firebase-admin/storage') return { getStorage: () => null };
    if (req === 'firebase-admin/app') return { initializeApp: () => null, getApps: () => [1] };
    return realLoad.apply(this, arguments);
  };
  try {
    return require('../evidence/video_redact')._internal;
  } finally {
    Module._load = realLoad;
  }
})();

test('a whole-clip box draws with no enable clause', () => {
  const { vf } = V.buildFilters([{ x: 0.1, y: 0.2, w: 0.3, h: 0.25 }], [], 20);
  assert.equal(vf.length, 1);
  assert.match(vf[0], /drawbox=x=0\.1\*iw:y=0\.2\*ih:w=0\.3\*iw:h=0\.25\*ih:color=black@1\.0:t=fill$/);
  assert.doesNotMatch(vf[0], /enable/);
});

test('a timed box is gated to its span', () => {
  const { vf } = V.buildFilters([{ x: 0, y: 0, w: 0.5, h: 0.5, start: 2, end: 8 }], [], 20);
  assert.match(vf[0], /enable='between\(t,2,8\)'/);
});

test('boxes with no area are dropped', () => {
  const { vf } = V.buildFilters([{ x: 0.1, y: 0.1, w: 0, h: 0.2 }, { x: 0, y: 0, w: 0.2, h: 0 }], [], 10);
  assert.equal(vf.length, 0);
});

test('coordinates are clamped into the frame, so a drag past the edge still works', () => {
  const { vf } = V.buildFilters([{ x: -0.5, y: 2, w: 3, h: 0.4 }], [], 10);
  assert.match(vf[0], /x=0\*iw/);
  assert.match(vf[0], /y=1\*ih/);
  assert.match(vf[0], /w=1\*iw/);
});

test('nothing a user typed can reach the filter string', () => {
  const { vf } = V.buildFilters([{ x: "0.1'; rm -rf /", y: 0.1, w: 0.2, h: 0.2 }], [], 10);
  // A non-numeric coordinate is not finite, so the box is dropped entirely.
  assert.equal(vf.length, 0);
});

test('a mute silences rather than lowers, and is gated to its span', () => {
  const { af } = V.buildFilters([], [{ start: 3, end: 5 }], 20);
  assert.equal(af.length, 1);
  assert.equal(af[0], "volume=0:enable='between(t,3,5)'");
});

test('a mute with no span covers the whole track', () => {
  const { af } = V.buildFilters([], [{}], 20);
  assert.equal(af[0], 'volume=0');
});

test('a span covering the whole clip needs no gate', () => {
  assert.equal(V.timeSpan({ start: 0, end: 20 }, 20), null);
});

test('a backwards span is put the right way round', () => {
  assert.deepEqual(V.timeSpan({ start: 9, end: 4 }, 20), { start: 4, end: 9 });
});

test('a span past the end is brought back to the end', () => {
  assert.deepEqual(V.timeSpan({ start: 5, end: 999 }, 20), { start: 5, end: 20 });
});

test('progress is read from ffmpeg output', () => {
  assert.equal(V.progressFrom('frame= 120 fps=30 time=00:00:10.00 bitrate=1000', 20), 0.5);
  assert.equal(V.progressFrom('no time here', 20), null);
  assert.equal(V.progressFrom('time=00:00:10.00', 0), null);
});
