// Verin Legal — Clio integration Cloud Functions.
//
// Production Readiness Guide §2.2, built out:
//   clioAuthStart      callable  -> returns Clio's authorize URL (with a CSRF state)
//   clioOAuthCallback  HTTPS     -> Clio redirects here; exchanges the code for
//                                   tokens server-side, stores them encrypted
//   clioDisconnect     callable  -> revokes + deletes the stored tokens
//   clioSearchMatters  callable  -> search the firm's Clio matters (for linking)
//   clioLinkMatter     callable  -> link a Verin matter to a Clio matter, and
//                                   note the matter's intake email and text
//                                   number on it for support staff
//   clioPushDocument   callable  -> upload a file (e.g. the matter export PDF)
//                                   into the linked Clio matter's Documents and
//                                   write the clioSyncLog row from here, so a
//                                   dropped connection can't log a fake "Synced"
//
// The App Secret and tokens never reach the app. What the app can read:
//   integrationStatus/{firmId}  { clioConnected, clioUserName, clioRegion, clioConnectedAt }
//   Matters/{id}                { clioMatterID, clioConnected, clioSyncedAt, providerMatterReference, providerSyncedAt }
//   clioSyncLog/{id}            { matterID, documentName, status, pushedAt, clioDocumentId, error }
//
// One-time setup:
//   firebase functions:secrets:set CLIO_CLIENT_SECRET
//   firebase functions:secrets:set TOKEN_ENCRYPTION_KEY     (openssl rand -base64 32)
//   and set CLIO_CLIENT_ID / CLIO_REGION / CLIO_REDIRECT_URI / APP_URL in functions/.env
//   (all params are declared in ../common/params.js)

const crypto = require('crypto');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const P = require('../common/params');
const access = require('../common/access');
const clio = require('./clioApi');
const { seal, open } = require('./tokenCrypto');

if (!getApps().length) initializeApp();

const { CLIO_CLIENT_SECRET, TOKEN_ENCRYPTION_KEY, CLIO_CLIENT_ID, CLIO_REGION, CLIO_REDIRECT_URI, APP_URL, DEFAULT_FIRM_ID } = P;

const SYNC_LOG = 'clioSyncLog';
const SECRETS = 'integrationSecrets'; // server-only (rules deny all client access)
const STATES = 'oauthStates'; // server-only
const STATUS = 'integrationStatus'; // client-readable, server-written
const STATE_TTL_MS = 10 * 60 * 1000; // Clio auth codes are valid for 10 minutes too

const db = () => getFirestore();

const requireAuth = access.requireAuth;
const firmIdFor = (uid) => access.firmIdForUser(db(), uid, DEFAULT_FIRM_ID.value());
const loadMatterForUser = (uid, matterId) => access.loadMatterForUser(db(), uid, matterId, DEFAULT_FIRM_ID.value());

function assertConfigured() {
  if (!CLIO_CLIENT_ID.value() || !CLIO_REDIRECT_URI.value()) {
    throw new HttpsError('failed-precondition', 'Clio is not configured yet (CLIO_CLIENT_ID / CLIO_REDIRECT_URI).');
  }
}

function secretDoc(firmId) {
  return db().collection(SECRETS).doc(`${firmId}__clio`);
}

function sessionFor(firmId) {
  const key = TOKEN_ENCRYPTION_KEY.value();
  const ref = secretDoc(firmId);
  return clio.createClioSession({
    fetch,
    region: CLIO_REGION.value(),
    clientId: CLIO_CLIENT_ID.value(),
    clientSecret: CLIO_CLIENT_SECRET.value(),
    loadTokens: async () => {
      const snap = await ref.get();
      if (!snap.exists) return null;
      const d = snap.data();
      return {
        accessToken: d.accessTokenEnc ? open(d.accessTokenEnc, key) : null,
        refreshToken: d.refreshTokenEnc ? open(d.refreshTokenEnc, key) : null,
        expiresAt: d.expiresAt || null,
      };
    },
    saveTokens: async (t) => {
      await ref.set(
        {
          accessTokenEnc: seal(t.accessToken, key),
          refreshTokenEnc: t.refreshToken ? seal(t.refreshToken, key) : null,
          expiresAt: t.expiresAt,
          refreshedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    },
  });
}

function toHttpsError(e) {
  if (e instanceof HttpsError) return e;
  if (e instanceof clio.ClioApiError) {
    if (e.status === 401) return new HttpsError('failed-precondition', 'Clio connection expired or was revoked. Reconnect Clio in Firm Settings.');
    if (e.status === 403) {
      console.error('Clio 403', e.message, e.body);
      const why = String(e.message || '').replace(/^Clio \w+ \S+ failed \(403\): /, '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 200);
      return new HttpsError(
        'permission-denied',
        `Clio refused this (403${why ? `: ${why}` : ''}). Check the app's permissions in the Clio developer portal, then deauthorize Verin inside Clio and connect again.`,
      );
    }
    if (e.status === 404) return new HttpsError('not-found', 'That record was not found in Clio.');
    if (e.status === 429) return new HttpsError('resource-exhausted', 'Clio rate limit hit; try again in a minute.');
    return new HttpsError('unavailable', `Clio error: ${e.message}`);
  }
  console.error(e);
  return new HttpsError('internal', 'Unexpected error talking to Clio.');
}

const CLIO_SECRETS = [CLIO_CLIENT_SECRET, TOKEN_ENCRYPTION_KEY];

// ---------------------------------------------------------------- intake note

function prettyPhone(e164) {
  const m = /^\+1(\d{3})(\d{3})(\d{4})$/.exec(String(e164 || ''));
  return m ? `(${m[1]}) ${m[2]}-${m[3]}` : String(e164 || '');
}

/// The note text for a matter's intake details, or null when it has none yet.
function intakeNote(matter) {
  const email = String(matter.emailAddress || '').trim();
  const sms = String(matter.smsNumber || '').trim();
  if (!email && !sms) return null;
  const lines = ['Where this client sends evidence (Verin Legal intake). Give these to the client if they ask:'];
  if (email) lines.push(`Email: ${email}`);
  if (sms) lines.push(`Text: ${prettyPhone(sms)} (from the client's own mobile)`);
  lines.push('Everything sent there is received, fingerprinted and filed to this matter in Verin.');
  return { key: `${email}|${sms}`, subject: 'Verin Legal: client evidence intake', detail: lines.join('\n') };
}

/// Posts the intake note on the Clio matter unless the same details were
/// already noted there. Never throws: linking and pushing must not fail
/// because of the note.
async function noteIntakeOnClio(session, matterRef, matter, clioMatterId) {
  const note = intakeNote(matter);
  if (!note) return false;
  if (matter.clioIntakeNoteKey === note.key && String(matter.clioIntakeNoteMatter || '') === String(clioMatterId)) return false;
  try {
    const res = await session.request({
      method: 'POST',
      path: '/notes.json',
      query: { fields: 'id' },
      body: { data: { type: 'Matter', matter: { id: Number(clioMatterId) }, subject: note.subject, detail: note.detail } },
    });
    await matterRef.set(
      {
        clioIntakeNoteKey: note.key,
        clioIntakeNoteMatter: String(clioMatterId),
        clioIntakeNoteId: res && res.data && res.data.id ? String(res.data.id) : '',
        clioIntakeNotedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return true;
  } catch (e) {
    console.warn('Clio intake note failed', String(clioMatterId), e.message);
    return false;
  }
}

// ---------------------------------------------------------------- connect

exports.clioAuthStart = onCall(async (request) => {
  const uid = requireAuth(request);
  assertConfigured();
  const firmId = await firmIdFor(uid);
  const state = crypto.randomBytes(24).toString('base64url');
  await db().collection(STATES).doc(state).set({
    provider: 'clio',
    uid,
    firmId,
    expiresAtMs: Date.now() + STATE_TTL_MS,
    createdAt: FieldValue.serverTimestamp(),
  });
  return {
    url: clio.authorizeUrl({
      region: CLIO_REGION.value(),
      clientId: CLIO_CLIENT_ID.value(),
      redirectUri: CLIO_REDIRECT_URI.value(),
      state,
    }),
  };
});

function resultPage(res, { ok, title, detail }) {
  const appUrl = APP_URL.value();
  const back = appUrl ? `<p><a href="${escapeHtml(appUrl)}">Return to Verin</a></p>` : '<p>You can close this tab and return to Verin.</p>';
  const color = ok ? '#0f766e' : '#b91c1c';
  res
    .status(ok ? 200 : 400)
    .set('Content-Type', 'text/html; charset=utf-8')
    .set('Cache-Control', 'no-store')
    .send(
      `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">` +
        `<title>${escapeHtml(title)}</title></head>` +
        `<body style="font-family:system-ui,sans-serif;max-width:480px;margin:15vh auto;padding:0 16px;color:#0f172a">` +
        `<h1 style="color:${color};font-size:22px">${escapeHtml(title)}</h1><p>${escapeHtml(detail)}</p>${back}</body></html>`,
    );
}

function escapeHtml(s) {
  return String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
}

exports.clioOAuthCallback = onRequest({ secrets: CLIO_SECRETS }, async (req, res) => {
  const { code, state, error } = req.query;
  if (typeof state !== 'string' || !state) {
    return resultPage(res, { ok: false, title: 'Clio connection failed', detail: 'Missing state. Start again from Firm Settings.' });
  }

  // Single-use state: read and delete in one transaction.
  const stateRef = db().collection(STATES).doc(state);
  let saved;
  try {
    saved = await db().runTransaction(async (tx) => {
      const snap = await tx.get(stateRef);
      if (!snap.exists) return null;
      tx.delete(stateRef);
      return snap.data();
    });
  } catch (e) {
    console.error('state lookup failed', e);
  }
  if (!saved || saved.provider !== 'clio' || saved.expiresAtMs < Date.now()) {
    return resultPage(res, { ok: false, title: 'Clio connection failed', detail: 'This link expired or was already used. Start again from Firm Settings.' });
  }
  if (error) {
    return resultPage(res, { ok: false, title: 'Clio connection cancelled', detail: 'Access was not granted in Clio.' });
  }
  if (typeof code !== 'string' || !code) {
    return resultPage(res, { ok: false, title: 'Clio connection failed', detail: 'Clio did not send an authorization code.' });
  }

  try {
    const region = CLIO_REGION.value();
    const tokens = await clio.exchangeCode({
      fetch,
      region,
      clientId: CLIO_CLIENT_ID.value(),
      clientSecret: CLIO_CLIENT_SECRET.value(),
      code,
      redirectUri: CLIO_REDIRECT_URI.value(),
    });
    const key = TOKEN_ENCRYPTION_KEY.value();
    await secretDoc(saved.firmId).set({
      provider: 'clio',
      region,
      accessTokenEnc: seal(tokens.accessToken, key),
      refreshTokenEnc: tokens.refreshToken ? seal(tokens.refreshToken, key) : null,
      expiresAt: tokens.expiresAt,
      connectedByUid: saved.uid,
      connectedAt: FieldValue.serverTimestamp(),
    });

    let who = null;
    try {
      who = (await sessionFor(saved.firmId).whoAmI()).data;
    } catch (e) {
      console.warn('who_am_i failed after connect', e.message);
    }
    await db().collection(STATUS).doc(saved.firmId).set(
      {
        clioConnected: true,
        clioRegion: region,
        clioUserName: (who && who.name) || '',
        clioConnectedAt: FieldValue.serverTimestamp(),
        clioConnectedByUid: saved.uid,
      },
      { merge: true },
    );
    return resultPage(res, {
      ok: true,
      title: 'Clio connected',
      detail: who && who.name ? `Connected as ${who.name}.` : 'Your firm\'s Clio account is now connected.',
    });
  } catch (e) {
    console.error('Clio token exchange failed', e);
    return resultPage(res, { ok: false, title: 'Clio connection failed', detail: e.message || 'Token exchange failed.' });
  }
});

exports.clioDisconnect = onCall({ secrets: CLIO_SECRETS }, async (request) => {
  const uid = requireAuth(request);
  const firmId = await firmIdFor(uid);
  const ref = secretDoc(firmId);
  const snap = await ref.get();
  if (snap.exists && snap.get('accessTokenEnc')) {
    try {
      await clio.deauthorize({
        fetch,
        region: snap.get('region') || CLIO_REGION.value(),
        accessToken: open(snap.get('accessTokenEnc'), TOKEN_ENCRYPTION_KEY.value()),
      });
    } catch (e) {
      console.warn('Clio deauthorize failed; deleting local tokens anyway', e.message);
    }
  }
  await ref.delete();
  await db().collection(STATUS).doc(firmId).set(
    { clioConnected: false, clioUserName: '', clioDisconnectedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { ok: true };
});

// ---------------------------------------------------------------- matters

exports.clioSearchMatters = onCall({ secrets: CLIO_SECRETS }, async (request) => {
  const uid = requireAuth(request);
  const firmId = await firmIdFor(uid);
  const query = String((request.data && request.data.query) || '').slice(0, 100);
  try {
    return { matters: await sessionFor(firmId).searchMatters({ query, limit: 20 }) };
  } catch (e) {
    throw toHttpsError(e);
  }
});

exports.clioLinkMatter = onCall({ secrets: CLIO_SECRETS }, async (request) => {
  const uid = requireAuth(request);
  const { matterId, clioMatterId } = request.data || {};
  const { ref, snap, firmId } = await loadMatterForUser(uid, matterId);
  if (!/^\d+$/.test(String(clioMatterId || ''))) {
    throw new HttpsError('invalid-argument', 'clioMatterId must be a Clio matter id');
  }
  const session = sessionFor(firmId);
  let m;
  try {
    m = await session.getMatter(String(clioMatterId)); // confirms it exists and we can see it
  } catch (e) {
    throw toHttpsError(e);
  }
  const region = CLIO_REGION.value();
  await ref.set(
    {
      clioMatterID: String(m.id),
      clioConnected: true,
      providerMatterReference: String(m.id),
      clioMatterUrl: clio.matterWebUrl(region, m.id),
      clioMatterDisplayNumber: m.display_number || '',
    },
    { merge: true },
  );
  const intakeNoted = await noteIntakeOnClio(session, ref, snap.data() || {}, m.id);
  return { clioMatterId: String(m.id), displayNumber: m.display_number || '', url: clio.matterWebUrl(region, m.id), intakeNoted };
});

// ---------------------------------------------------------------- push

exports.clioPushDocument = onCall({ secrets: CLIO_SECRETS, timeoutSeconds: 120, memory: '512MiB' }, async (request) => {
  const uid = requireAuth(request);
  const { matterId, storagePath, documentName } = request.data || {};
  const { ref, snap, firmId } = await loadMatterForUser(uid, matterId);

  const clioMatterId = snap.get('clioMatterID') || snap.get('providerMatterReference');
  if (!clioMatterId) {
    throw new HttpsError('failed-precondition', 'Link this matter to a Clio matter first.');
  }
  if (typeof storagePath !== 'string' || !storagePath || storagePath.includes('..') || storagePath.startsWith('/')) {
    throw new HttpsError('invalid-argument', 'storagePath is required (the export PDF\'s path in Storage)');
  }
  const name = String(documentName || storagePath.split('/').pop()).slice(0, 200);

  const logRef = db().collection(SYNC_LOG).doc();
  const baseLog = {
    matterID: ref,
    documentName: name,
    storagePath,
    pushedByUid: uid,
    pushedAt: FieldValue.serverTimestamp(),
  };

  try {
    const file = getStorage().bucket().file(storagePath);
    const [exists] = await file.exists();
    if (!exists) throw new HttpsError('not-found', 'No file at that storage path');
    const [[bytes], [meta]] = await Promise.all([file.download(), file.getMetadata()]);
    const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');

    const session = sessionFor(firmId);
    const uploaded = await session.uploadDocument({
      clioMatterId,
      name,
      bytes,
      contentType: meta.contentType || 'application/pdf',
    });

    const batch = db().batch();
    batch.set(logRef, { ...baseLog, status: 'Synced', clioDocumentId: uploaded.id, sha256, error: '' });
    batch.set(ref, { clioSyncedAt: FieldValue.serverTimestamp(), providerSyncedAt: FieldValue.serverTimestamp() }, { merge: true });
    await batch.commit();
    // Intake details added (or changed) since the matter was linked.
    await noteIntakeOnClio(session, ref, snap.data() || {}, clioMatterId);
    return { status: 'Synced', clioDocumentId: uploaded.id, logId: logRef.id };
  } catch (e) {
    const err = toHttpsError(e);
    await logRef.set({ ...baseLog, status: 'Failed', clioDocumentId: '', error: err.message });
    throw err;
  }
});

exports._internal = { intakeNote, prettyPhone };
