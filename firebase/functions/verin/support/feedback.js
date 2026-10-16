// Verin Legal — in-app feedback (profile → Send feedback).
//
// What a firm sends us is a sentence and, if they choose it, a screenshot.
// What the app attaches on its own is deliberately narrow: ids, route, browser
// and screen. No matter name, no client name, no message text, no file names.
// A support report should never become a second copy of someone's evidence.
//
// The screenshot is the one place a firm can hand us client detail, so it is
// always their explicit choice, is stored beside their own firm's data, and is
// deleted with the feedback record.

const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const crypto = require('crypto');
const { requireAuth, userAccess } = require('../common/access');
const { sendMail } = require('../common/mailer');
const P = require('../common/params');

const KINDS = {
  broken: "Something's broken",
  confusing: 'This was confusing',
  wish: 'I wish it did',
  question: 'Question',
};
const IMPACTS = {
  blocked: 'Blocked me',
  slowed: 'Slowed me down',
  noting: 'Just noting it',
};

const MAX_TEXT = 4000;
const MAX_SHOT_BYTES = 4 * 1024 * 1024;

/// Only the fields we name, only the shapes we expect, and nothing longer than
/// it needs to be. Anything else the client sends is dropped rather than stored.
function safeContext(raw) {
  const c = raw && typeof raw === 'object' ? raw : {};
  const str = (v, n = 200) => (typeof v === 'string' ? v.slice(0, n) : '');
  const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? Math.round(v) : null);
  return {
    route: str(c.route, 300),
    tab: str(c.tab, 80),
    matterId: str(c.matterId, 200),
    receiptId: str(c.receiptId, 200),
    appVersion: str(c.appVersion, 60),
    browser: str(c.browser, 300),
    screenW: num(c.screenW),
    screenH: num(c.screenH),
    lastError: str(c.lastError, 500),
  };
}

async function saveShot({ bucket, firmId, id, base64, contentType }) {
  const bytes = Buffer.from(String(base64), 'base64');
  if (!bytes.length) return null;
  if (bytes.length > MAX_SHOT_BYTES) {
    throw new HttpsError('invalid-argument', 'That screenshot is larger than 4 MB. Crop it or send it to the help desk instead.');
  }
  const type = ['image/png', 'image/jpeg', 'image/webp'].includes(contentType) ? contentType : 'image/png';
  const ext = type === 'image/jpeg' ? 'jpg' : type === 'image/webp' ? 'webp' : 'png';
  const token = crypto.randomUUID();
  const path = `firms/${firmId}/feedback/${id}.${ext}`;
  await bucket.file(path).save(bytes, {
    resumable: false,
    contentType: type,
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  return {
    storagePath: path,
    url: `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`,
    bytes: bytes.length,
  };
}

async function submit(request) {
  const uid = requireAuth(request);
  const db = getFirestore();
  const data = request.data || {};

  const kind = KINDS[String(data.kind || '')] ? String(data.kind) : 'question';
  const impact = IMPACTS[String(data.impact || '')] ? String(data.impact) : 'noting';
  const text = String(data.text || '').trim().slice(0, MAX_TEXT);
  if (text.length < 3) throw new HttpsError('invalid-argument', 'Tell us what happened, in a sentence or two.');

  const { firmId, role } = await userAccess(db, uid);
  if (!firmId) throw new HttpsError('failed-precondition', 'Your account is not attached to a firm yet.');

  const ref = db.collection('feedback').doc();
  let shot = null;
  if (data.shotBase64) {
    shot = await saveShot({
      bucket: getStorage().bucket(),
      firmId,
      id: ref.id,
      base64: data.shotBase64,
      contentType: String(data.shotType || 'image/png'),
    });
  }

  const email = (request.auth.token && request.auth.token.email) || '';
  await ref.set({
    firmID: firmId,
    uid,
    email,
    role: role || '',
    kind,
    kindLabel: KINDS[kind],
    impact,
    impactLabel: IMPACTS[impact],
    text,
    context: safeContext(data.context),
    shot: shot || null,
    status: 'new',
    createdAt: FieldValue.serverTimestamp(),
  });

  // A copy to the help desk, so nothing lives only in the database. The body
  // carries the same narrow context the record does.
  const ctx = safeContext(data.context);
  const to = (P.SUPPORT_EMAIL && P.SUPPORT_EMAIL.value()) || 'help@verin-legal.on.spiceworks.com';
  const mail = await sendMail({
    to,
    replyTo: email || undefined,
    subject: `[${IMPACTS[impact]}] ${KINDS[kind]} — ${email || uid}`,
    text: [
      text,
      '',
      '--',
      `Firm: ${firmId}`,
      `From: ${email || uid}${role ? ` (${role})` : ''}`,
      `Where: ${ctx.route || 'unknown'}${ctx.tab ? ` · ${ctx.tab}` : ''}`,
      ctx.matterId ? `Matter: ${ctx.matterId}` : '',
      ctx.receiptId ? `Item: ${ctx.receiptId}` : '',
      `Browser: ${ctx.browser || 'unknown'} · ${ctx.screenW || '?'}x${ctx.screenH || '?'}`,
      ctx.appVersion ? `Build: ${ctx.appVersion}` : '',
      ctx.lastError ? `Last error seen: ${ctx.lastError}` : '',
      shot ? `Screenshot: ${shot.url}` : 'No screenshot attached.',
      `Record: feedback/${ref.id}`,
    ].filter(Boolean).join('\n'),
  }).catch((e) => ({ sent: false, reason: e.message }));

  if (!mail.sent) {
    await ref.set({ mail: { sent: false, reason: String(mail.reason || '').slice(0, 200) } }, { merge: true });
  }

  return { id: ref.id, emailed: mail.sent === true };
}

exports.submitFeedback = onCall({ timeoutSeconds: 60, memory: '512MiB' }, async (request) => {
  try {
    return await submit(request);
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error('submitFeedback failed', e && e.stack ? e.stack : e);
    throw new HttpsError('internal', `Feedback could not be sent: ${(e && e.message) || e}`);
  }
});

exports._internal = { KINDS, IMPACTS, safeContext };
