// Verin Legal — video and audio redaction.
//
// A firm marks rectangles on the picture and spans of the sound; ffmpeg burns
// solid black boxes into the pixels and silences those spans, and the result
// is a new file with its own hash. The original is never touched: it keeps its
// place in the chain, so both can be verified.
//
// Solid black, not blur. A blur can sometimes be undone; a filled rectangle
// cannot, and the app already promises that nothing under a redaction
// survives. Audio is set to zero, not lowered.
//
// What this does NOT do: follow a moving subject. A redaction is a fixed
// rectangle over a time range. If someone crosses the frame, the box has to
// cover where they go, or the span is split into several boxes. Saying so
// plainly is the point — a firm must never believe a face was tracked.

const crypto = require('crypto');
const os = require('os');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { requireAuth, loadMatterForUser } = require('../common/access');

/// Beyond these a job is refused rather than left to time out. A doorbell clip
/// is seconds; a bodycam hand-off is a different kind of job and should be
/// told so clearly instead of failing after ten minutes of compute.
const MAX_SECONDS = 15 * 60;
const MAX_BYTES = 500 * 1024 * 1024;

const clamp01 = (v) => Math.min(Math.max(Number(v), 0), 1);

/// ffmpeg takes a filter string, and a filter string is the whole security
/// boundary here: everything in it is derived from numbers we have clamped,
/// never from text a user typed. Kept pure so it can be tested without ffmpeg.
function buildFilters(boxes = [], mutes = [], duration = 0) {
  const vf = [];
  for (const b of boxes) {
    const x = clamp01(b.x);
    const y = clamp01(b.y);
    const w = clamp01(b.w);
    const h = clamp01(b.h);
    if (!(w > 0 && h > 0)) continue;
    if (![x, y, w, h].every(Number.isFinite)) continue;
    const draw = `drawbox=x=${x}*iw:y=${y}*ih:w=${w}*iw:h=${h}*ih:color=black@1.0:t=fill`;
    const span = timeSpan(b, duration);
    vf.push(span ? `${draw}:enable='between(t,${span.start},${span.end})'` : draw);
  }
  const af = [];
  for (const m of mutes) {
    const span = timeSpan(m, duration);
    // A mute with no span means the whole track.
    af.push(span ? `volume=0:enable='between(t,${span.start},${span.end})'` : 'volume=0');
  }
  return { vf, af };
}

/// A start/end pair in seconds, or null for "the whole clip". Out-of-order or
/// out-of-range values are brought back inside rather than rejected: a box the
/// user dragged past the end should still cover to the end.
function timeSpan(o, duration) {
  const hasStart = Number.isFinite(Number(o.start));
  const hasEnd = Number.isFinite(Number(o.end));
  if (!hasStart && !hasEnd) return null;
  const cap = duration > 0 ? duration : Number.MAX_SAFE_INTEGER;
  let start = hasStart ? Math.max(0, Number(o.start)) : 0;
  let end = hasEnd ? Number(o.end) : cap;
  if (end < start) [start, end] = [end, start];
  start = Math.min(start, cap);
  end = Math.min(Math.max(end, start), cap);
  if (start <= 0 && end >= cap) return null;
  return { start: round3(start), end: round3(end) };
}

const round3 = (n) => Math.round(n * 1000) / 1000;

function ffmpegPath() {
  // ffmpeg-static ships a binary per platform; on a machine that already has
  // one on PATH (a container, a developer's laptop) that is used instead.
  try {
    const p = require('ffmpeg-static');
    if (p && fs.existsSync(p)) return p;
  } catch (_) {
    // not installed: fall through
  }
  return 'ffmpeg';
}

function ffprobePath() {
  try {
    const p = require('ffprobe-static');
    const bin = p && (p.path || p);
    if (bin && fs.existsSync(bin)) return bin;
  } catch (_) {
    // not installed: fall through
  }
  return 'ffprobe';
}

function run(bin, args, { onStderr } = {}) {
  return new Promise((resolve, reject) => {
    const p = spawn(bin, args);
    let err = '';
    p.stderr.on('data', (d) => {
      const s = String(d);
      err += s.length > 4000 ? '' : s;
      if (onStderr) onStderr(s);
    });
    p.on('error', reject);
    p.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`${path.basename(bin)} exited ${code}: ${err.slice(-500)}`))));
  });
}

async function probeDuration(file) {
  return new Promise((resolve) => {
    const p = spawn(ffprobePath(), ['-v', 'error', '-show_entries', 'format=duration', '-of', 'default=nw=1:nk=1', file]);
    let out = '';
    p.stdout.on('data', (d) => (out += String(d)));
    p.on('error', () => resolve(0));
    p.on('close', () => resolve(Number(String(out).trim()) || 0));
  });
}

/// Progress as a fraction, read from ffmpeg's running "time=" output.
function progressFrom(line, duration) {
  const m = /time=(\d+):(\d+):(\d+(?:\.\d+)?)/.exec(line);
  if (!m || !(duration > 0)) return null;
  const secs = Number(m[1]) * 3600 + Number(m[2]) * 60 + Number(m[3]);
  return Math.min(1, Math.max(0, secs / duration));
}

exports.redactVideo = onCall({ timeoutSeconds: 540, memory: '2GiB', cpu: 2 }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const data = request.data || {};
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, data.matterId);
  const receiptId = String(data.receiptId || '');
  if (!receiptId) throw new HttpsError('invalid-argument', 'receiptId is required.');

  const rSnap = await db.collection('Receipts').doc(receiptId).get();
  if (!rSnap.exists || rSnap.get('firmID') !== firmId) throw new HttpsError('not-found', 'Item not found');
  const receipt = rSnap.data() || {};
  const srcPath = receipt.sourceStoragePath || '';
  if (!srcPath) throw new HttpsError('failed-precondition', 'That item has no stored file.');

  const boxes = Array.isArray(data.boxes) ? data.boxes : [];
  const mutes = Array.isArray(data.mutes) ? data.mutes : [];
  if (!boxes.length && !mutes.length) throw new HttpsError('invalid-argument', 'Mark at least one area to black out or one span to silence.');

  const bucket = getStorage().bucket();
  const file = bucket.file(srcPath);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError('failed-precondition', 'The stored original is missing.');
  const [meta] = await file.getMetadata();
  const size = Number(meta.size || 0);
  if (size > MAX_BYTES) {
    throw new HttpsError('failed-precondition', `That file is ${Math.round(size / 1024 / 1024)}MB. Verin redacts videos up to ${MAX_BYTES / 1024 / 1024}MB; send a trimmed copy instead.`);
  }

  // The job document is what the screen watches: this runs for tens of
  // seconds and nobody should have to sit on a spinner with no detail.
  const jobRef = ref.collection('videoRedactions').doc();
  await jobRef.set({
    receiptId,
    status: 'running',
    progress: 0,
    boxes: boxes.length,
    mutes: mutes.length,
    startedAt: FieldValue.serverTimestamp(),
    startedByUid: uid,
  });

  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'verin-redact-'));
  const inFile = path.join(dir, 'in');
  const outFile = path.join(dir, 'out.mp4');
  const cleanup = () => {
    try {
      fs.rmSync(dir, { recursive: true, force: true });
    } catch (_) {
      // best effort
    }
  };

  try {
    await file.download({ destination: inFile });
    const duration = await probeDuration(inFile);
    if (duration > MAX_SECONDS) {
      throw new HttpsError('failed-precondition', `That clip is ${Math.round(duration / 60)} minutes. Verin redacts videos up to ${MAX_SECONDS / 60} minutes; trim it first.`);
    }

    const { vf, af } = buildFilters(boxes, mutes, duration);
    if (!vf.length && !af.length) throw new HttpsError('invalid-argument', 'Nothing to redact: the marked areas were empty.');

    const args = ['-y', '-i', inFile];
    if (vf.length) args.push('-vf', vf.join(','));
    else args.push('-c:v', 'copy');
    if (af.length) args.push('-af', af.join(','));
    if (vf.length) args.push('-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23', '-pix_fmt', 'yuv420p');
    args.push('-c:a', 'aac', '-movflags', '+faststart', outFile);

    let lastWrite = 0;
    await run(ffmpegPath(), args, {
      onStderr: (line) => {
        const p = progressFrom(line, duration);
        const now = Date.now();
        // Firestore writes are not free; once a second is plenty for a bar.
        if (p !== null && now - lastWrite > 1000) {
          lastWrite = now;
          jobRef.update({ progress: Math.round(p * 100) / 100 }).catch(() => {});
        }
      },
    });

    const bytes = fs.readFileSync(outFile);
    const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
    const token = crypto.randomUUID();
    const stamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
    const base = (receipt.originalFileName || 'video').replace(/\.[^.]+$/, '');
    const fileName = `${base}-redacted-${stamp}.mp4`;
    const storagePath = `matters/${ref.id}/redacted/${fileName}`;
    await bucket.file(storagePath).save(bytes, {
      resumable: false,
      contentType: 'video/mp4',
      metadata: {
        contentDisposition: `attachment; filename="${fileName}"`,
        metadata: { firebaseStorageDownloadTokens: token, sha256, redactedFrom: receiptId, generatedBy: uid },
      },
    });
    const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(storagePath)}?alt=media&token=${token}`;

    const result = {
      status: 'done',
      progress: 1,
      storagePath,
      fileName,
      sha256,
      bytes: bytes.length,
      downloadUrl,
      finishedAt: FieldValue.serverTimestamp(),
    };
    await jobRef.update(result);
    // The item now has a redacted version; the original stays exactly as it
    // arrived, hash and chain untouched.
    await rSnap.ref.set({ redactedVideo: { storagePath, fileName, sha256, bytes: bytes.length, at: FieldValue.serverTimestamp() } }, { merge: true });
    return { jobId: jobRef.id, storagePath, fileName, sha256, bytes: bytes.length, downloadUrl, seconds: Math.round(duration) };
  } catch (e) {
    const message = e instanceof HttpsError ? e.message : `The video could not be redacted: ${String(e && e.message ? e.message : e).slice(0, 300)}`;
    if (!(e instanceof HttpsError)) console.error('redactVideo failed', e);
    await jobRef.update({ status: 'failed', error: message, finishedAt: FieldValue.serverTimestamp() }).catch(() => {});
    throw e instanceof HttpsError ? e : new HttpsError('internal', message);
  } finally {
    cleanup();
  }
});

exports._internal = { buildFilters, timeSpan, progressFrom, MAX_SECONDS, MAX_BYTES };
