// Verin Legal — PracticePanther and Filevine (Clio lives in ../clio).
//
//   practicePantherAuthStart      → { url } to approve Verin in PracticePanther
//   practicePantherOAuthCallback  PracticePanther redirects here after approval
//   filevineConnect               admin pastes the firm's Filevine service-account
//                                 token (and, without Verin partner keys, the
//                                 firm's own client id + secret)
//   practiceDisconnect            { provider }
//   practiceSearchMatters         { provider, query } → [{ id, display, name, client, url }]
//   practiceLinkMatter            { provider, matterId, externalId, display, name, url }
//   practicePushDocument          { provider, matterId, storagePath, documentName }
//
// Tokens are encrypted with TOKEN_ENCRYPTION_KEY (the same key as Clio) in
// integrationSecrets/{firmId}__{provider}; integrationStatus/{firmId} carries
// what the app shows. Matters keep their links in practiceLinks.{provider}.
//
// Settings (functions/.env): PRACTICEPANTHER_ENABLED, PRACTICEPANTHER_CLIENT_ID,
// PRACTICEPANTHER_REDIRECT_URI, FILEVINE_ENABLED, FILEVINE_PARTNER,
// FILEVINE_CLIENT_ID, FILEVINE_REGION (us | ca).

const crypto = require('crypto');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');

const P = require('../common/params');
const access = require('../common/access');
const { seal, open } = require('../clio/tokenCrypto');
const S = require('./secrets');
const V = require('./providers');

if (!getApps().length) initializeApp();

const db = () => getFirestore();
const env = (k) => String(process.env[k] || '').trim();
const SECRETS = () => [P.TOKEN_ENCRYPTION_KEY, ...S.practiceSecrets()];
const STATE_TTL_MS = 10 * 60 * 1000;

function assertProvider(p) {
  if (!V.PROVIDERS[p]) throw new HttpsError('invalid-argument', 'provider must be practicepanther or filevine');
  if (p === 'practicepanther' && !(S.practicePantherEnabled() && env('PRACTICEPANTHER_CLIENT_ID'))) {
    throw new HttpsError('failed-precondition', 'PracticePanther is not set up in Verin yet (waiting on API access).');
  }
  if (p === 'filevine' && !S.filevineEnabled()) {
    throw new HttpsError('failed-precondition', 'Filevine is not set up in Verin yet (waiting on API access).');
  }
  return p;
}

const secretRef = (firmId, provider) => db().collection('integrationSecrets').doc(`${firmId}__${provider}`);
const statusRef = (firmId) => db().collection('integrationStatus').doc(firmId);

/// A ready session for a firm's connected provider.
async function sessionFor(firmId, provider) {
  const key = P.TOKEN_ENCRYPTION_KEY.value();
  const ref = secretRef(firmId, provider);
  if (provider === 'practicepanther') {
    return V.createPracticePantherSession({
      fetch,
      clientId: env('PRACTICEPANTHER_CLIENT_ID'),
      clientSecret: S.ppClientSecret(),
      loadTokens: async () => {
        const s = await ref.get();
        if (!s.exists) return null;
        const d = s.data();
        return { accessToken: d.accessTokenEnc ? open(d.accessTokenEnc, key) : null, refreshToken: d.refreshTokenEnc ? open(d.refreshTokenEnc, key) : null, expiresAt: d.expiresAt || null };
      },
      saveTokens: (t) =>
        ref.set({ accessTokenEnc: seal(t.accessToken, key), refreshTokenEnc: t.refreshToken ? seal(t.refreshToken, key) : null, expiresAt: t.expiresAt, refreshedAt: FieldValue.serverTimestamp() }, { merge: true }),
    });
  }
  const s = await ref.get();
  if (!s.exists) throw new HttpsError('failed-precondition', 'Filevine is not connected for this firm.');
  const d = s.data();
  return V.createFilevineSession({
    fetch,
    region: d.region || env('FILEVINE_REGION') || 'us',
    clientId: d.clientId || env('FILEVINE_CLIENT_ID'),
    clientSecret: d.clientSecretEnc ? open(d.clientSecretEnc, key) : S.fvPartnerSecret(),
    pat: open(d.patEnc, key),
  });
}

function toHttpsError(e) {
  if (e instanceof HttpsError) return e;
  if (e instanceof V.PracticeApiError) {
    const label = V.PROVIDERS[e.provider] ? V.PROVIDERS[e.provider].label : 'The practice system';
    console.error(e.provider, e.status, e.message, JSON.stringify(e.body || {}).slice(0, 500));
    if (e.status === 401) return new HttpsError('failed-precondition', `${label} connection expired or was revoked. Reconnect it in Settings.`);
    if (e.status === 403) return new HttpsError('permission-denied', `${label} refused this (403). Check the account's permissions.`);
    if (e.status === 404) return new HttpsError('not-found', `${label} could not find that record.`);
    if (e.status === 429) return new HttpsError('resource-exhausted', `${label} rate limit hit; try again in a minute.`);
    return new HttpsError('unavailable', e.message);
  }
  console.error(e);
  return new HttpsError('internal', 'Unexpected error talking to the practice system.');
}

// ---------------------------------------------------------------- connect

/// Which providers Verin can connect to right now (keys in place).
exports.practiceAvailability = onCall(async (request) => {
  access.requireAuth(request);
  return {
    practicepanther: S.practicePantherEnabled() && !!env('PRACTICEPANTHER_CLIENT_ID'),
    filevine: S.filevineEnabled(),
    filevinePartner: S.filevinePartner(),
  };
});

exports.practicePantherAuthStart = onCall(async (request) => {
  const uid = access.requireAuth(request);
  assertProvider('practicepanther');
  const { firmId } = await access.requireAdmin(db(), uid);
  const state = crypto.randomBytes(24).toString('base64url');
  await db().collection('oauthStates').doc(state).set({ provider: 'practicepanther', uid, firmId, expiresAtMs: Date.now() + STATE_TTL_MS, createdAt: FieldValue.serverTimestamp() });
  return { url: V.ppAuthorizeUrl({ clientId: env('PRACTICEPANTHER_CLIENT_ID'), redirectUri: env('PRACTICEPANTHER_REDIRECT_URI'), state }) };
});

function escapeHtml(s) {
  return String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
}

function resultPage(res, { ok, title, detail }) {
  const appUrl = P.APP_URL.value();
  const back = appUrl ? `<p><a href="${escapeHtml(appUrl)}">Return to Verin</a></p>` : '<p>You can close this tab and return to Verin.</p>';
  res
    .status(ok ? 200 : 400)
    .set('Content-Type', 'text/html; charset=utf-8')
    .set('Cache-Control', 'no-store')
    .send(
      `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(title)}</title></head>` +
        `<body style="font-family:system-ui,sans-serif;max-width:480px;margin:15vh auto;padding:0 16px;color:#0f172a">` +
        `<h1 style="color:${ok ? '#0f766e' : '#b91c1c'};font-size:22px">${escapeHtml(title)}</h1><p>${escapeHtml(detail)}</p>${back}</body></html>`,
    );
}

exports.practicePantherOAuthCallback = onRequest({ secrets: SECRETS() }, async (req, res) => {
  const { code, state, error } = req.query;
  const fail = (detail) => resultPage(res, { ok: false, title: 'PracticePanther connection failed', detail });
  if (typeof state !== 'string' || !state) return fail('Missing state. Start again from Settings.');
  const stateRef = db().collection('oauthStates').doc(state);
  const saved = await db()
    .runTransaction(async (tx) => {
      const s = await tx.get(stateRef);
      if (!s.exists) return null;
      tx.delete(stateRef);
      return s.data();
    })
    .catch(() => null);
  if (!saved || saved.provider !== 'practicepanther' || saved.expiresAtMs < Date.now()) return fail('This link expired or was already used. Start again from Settings.');
  if (error) return fail('Access was not granted in PracticePanther.');
  if (typeof code !== 'string' || !code) return fail('PracticePanther did not send an authorization code.');
  try {
    const t = await V.ppExchangeCode({ fetch, clientId: env('PRACTICEPANTHER_CLIENT_ID'), clientSecret: S.ppClientSecret(), code, redirectUri: env('PRACTICEPANTHER_REDIRECT_URI') });
    const key = P.TOKEN_ENCRYPTION_KEY.value();
    await secretRef(saved.firmId, 'practicepanther').set({
      provider: 'practicepanther',
      accessTokenEnc: seal(t.accessToken, key),
      refreshTokenEnc: t.refreshToken ? seal(t.refreshToken, key) : null,
      expiresAt: t.expiresAt,
      connectedByUid: saved.uid,
      connectedAt: FieldValue.serverTimestamp(),
    });
    let who = { name: '' };
    try {
      who = await (await sessionFor(saved.firmId, 'practicepanther')).whoAmI();
    } catch (_) {
      /* cosmetic */
    }
    await statusRef(saved.firmId).set(
      { practicepantherConnected: true, practicepantherUserName: who.name || '', practicepantherConnectedAt: FieldValue.serverTimestamp(), practicepantherConnectedByUid: saved.uid },
      { merge: true },
    );
    return resultPage(res, { ok: true, title: 'PracticePanther connected', detail: who.name ? `Connected as ${who.name}.` : "Your firm's PracticePanther account is now connected." });
  } catch (e) {
    console.error('PracticePanther token exchange failed', e);
    return fail(e.message || 'Token exchange failed.');
  }
});

exports.filevineConnect = onCall({ secrets: SECRETS() }, async (request) => {
  const uid = access.requireAuth(request);
  assertProvider('filevine');
  const { firmId } = await access.requireAdmin(db(), uid);
  const data = request.data || {};
  const pat = String(data.token || '').trim();
  const clientId = String(data.clientId || '').trim();
  const clientSecret = String(data.clientSecret || '').trim();
  const region = data.region === 'ca' ? 'ca' : 'us';
  if (!pat) throw new HttpsError('invalid-argument', 'Paste the personal access token from your Filevine service account.');
  if (!S.filevinePartner() && (!clientId || !clientSecret)) {
    throw new HttpsError('invalid-argument', "Also paste your firm's Filevine client ID and client secret (Account Manager → Access Tokens → Client Secrets).");
  }
  const session = V.createFilevineSession({
    fetch,
    region,
    clientId: clientId || env('FILEVINE_CLIENT_ID'),
    clientSecret: clientSecret || S.fvPartnerSecret(),
    pat,
  });
  let who;
  try {
    who = await session.whoAmI(); // proves the token works before anything is saved
  } catch (e) {
    throw toHttpsError(e);
  }
  const key = P.TOKEN_ENCRYPTION_KEY.value();
  await secretRef(firmId, 'filevine').set({
    provider: 'filevine',
    region,
    patEnc: seal(pat, key),
    clientId: clientId || '',
    clientSecretEnc: clientSecret ? seal(clientSecret, key) : null,
    connectedByUid: uid,
    connectedAt: FieldValue.serverTimestamp(),
  });
  await statusRef(firmId).set({ filevineConnected: true, filevineUserName: who.name || '', filevineConnectedAt: FieldValue.serverTimestamp(), filevineConnectedByUid: uid }, { merge: true });
  return { connected: true, name: who.name || '' };
});

exports.practiceDisconnect = onCall(async (request) => {
  const uid = access.requireAuth(request);
  const provider = String((request.data || {}).provider || '');
  if (!V.PROVIDERS[provider]) throw new HttpsError('invalid-argument', 'Unknown provider');
  const { firmId } = await access.requireAdmin(db(), uid);
  await secretRef(firmId, provider).delete().catch(() => {});
  await statusRef(firmId).set({ [`${provider}Connected`]: false, [`${provider}DisconnectedAt`]: FieldValue.serverTimestamp() }, { merge: true });
  return { disconnected: true };
});

// ---------------------------------------------------------------- matters

exports.practiceSearchMatters = onCall({ secrets: SECRETS() }, async (request) => {
  const uid = access.requireAuth(request);
  const provider = assertProvider(String((request.data || {}).provider || ''));
  const firmId = await access.firmIdForUser(db(), uid);
  try {
    return { matters: await (await sessionFor(firmId, provider)).searchMatters(String((request.data || {}).query || '').slice(0, 100)) };
  } catch (e) {
    throw toHttpsError(e);
  }
});

function intakeText(m) {
  const lines = [];
  if (m.emailAddress) lines.push(`Email: ${m.emailAddress}`);
  if (m.smsNumber) lines.push(`Text: ${m.smsNumber} (from the client's own mobile)`);
  return lines.length ? `Where this client sends evidence (Verin Legal intake):\n${lines.join('\n')}\nEverything sent there is received, fingerprinted and filed to this matter in Verin.` : '';
}

exports.practiceLinkMatter = onCall({ secrets: SECRETS() }, async (request) => {
  const uid = access.requireAuth(request);
  const data = request.data || {};
  const provider = assertProvider(String(data.provider || ''));
  const { ref, snap, firmId } = await access.loadMatterForUser(db(), uid, data.matterId);
  const externalId = String(data.externalId || '').trim();
  if (!externalId) throw new HttpsError('invalid-argument', 'externalId is required');
  const link = {
    id: externalId,
    display: String(data.display || '').slice(0, 80),
    name: String(data.name || '').slice(0, 200),
    url: String(data.url || '').slice(0, 500),
    linkedAt: FieldValue.serverTimestamp(),
    linkedByUid: uid,
  };
  await ref.set({ practiceLinks: { [provider]: link } }, { merge: true });
  // The client's intake details, as a note on the linked matter (best effort).
  const text = intakeText(snap.data() || {});
  if (text) {
    try {
      await (await sessionFor(firmId, provider)).addNote({ matterId: externalId, subject: 'Verin Legal: client evidence intake', text });
    } catch (e) {
      console.warn('intake note failed', provider, e.message);
    }
  }
  return { linked: true };
});

/// Uploads one stored file to the linked matter. Used by the Practice tab and
/// by delivery (../export/delivery.js).
async function pushToProvider({ firmId, provider, matterRef, matter, name, bytes, contentType, uid, storagePath = '', deliveryId = '' }) {
  const link = (matter.practiceLinks || {})[provider];
  if (!link || !link.id) throw new HttpsError('failed-precondition', `Link this matter to ${V.PROVIDERS[provider].label} first.`);
  const logRef = db().collection('practiceSyncLog').doc();
  const base = { provider, matterID: matterRef, firmID: firmId, documentName: name, storagePath, pushedByUid: uid, pushedAt: FieldValue.serverTimestamp(), deliveryId };
  const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
  try {
    const up = await (await sessionFor(firmId, provider)).uploadDocument({ matterId: link.id, name, bytes, contentType });
    await logRef.set({ ...base, status: 'Synced', externalDocumentId: up.id, sha256, error: '' });
    await matterRef.set({ practiceSyncedAt: { [provider]: FieldValue.serverTimestamp() } }, { merge: true });
    return { status: 'Synced', documentId: up.id, logId: logRef.id };
  } catch (e) {
    const err = toHttpsError(e);
    await logRef.set({ ...base, status: 'Failed', externalDocumentId: '', sha256, error: err.message });
    throw err;
  }
}

exports.practicePushDocument = onCall({ secrets: SECRETS(), timeoutSeconds: 300, memory: '1GiB' }, async (request) => {
  const uid = access.requireAuth(request);
  const data = request.data || {};
  const provider = assertProvider(String(data.provider || ''));
  const { ref, snap, firmId } = await access.loadMatterForUser(db(), uid, data.matterId);
  const storagePath = String(data.storagePath || '');
  if (!storagePath || storagePath.includes('..') || !storagePath.startsWith(`matters/${ref.id}/`)) throw new HttpsError('invalid-argument', "storagePath must be one of this matter's exports");
  const file = getStorage().bucket().file(storagePath);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError('not-found', 'No file at that storage path');
  const [[bytes], [meta]] = await Promise.all([file.download(), file.getMetadata()]);
  return pushToProvider({ firmId, provider, matterRef: ref, matter: snap.data() || {}, name: String(data.documentName || storagePath.split('/').pop()).slice(0, 200), bytes, contentType: meta.contentType || 'application/pdf', uid, storagePath });
});

exports._practice = { sessionFor, pushToProvider, SECRETS, assertProvider, intakeText };
