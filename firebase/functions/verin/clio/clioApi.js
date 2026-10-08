// Verin Legal — Clio Manage API v4 client (server-side only).
//
// Plain HTTPS against Clio's documented endpoints; `fetch` is injected so the
// whole flow is testable without network access. Nothing in this file ever
// runs in the app: the client secret and tokens stay in Cloud Functions.
//
// Endpoints (Clio Manage developer docs):
//   authorize   https://<host>/oauth/authorize
//   token       https://<host>/oauth/token        (form-encoded, not JSON)
//   deauthorize https://<host>/oauth/deauthorize
//   API         https://<host>/api/v4/...
// Tokens are region-specific: a US token does not work against EU/CA/AU.

const REGION_HOSTS = {
  us: 'app.clio.com',
  eu: 'eu.app.clio.com',
  ca: 'ca.app.clio.com',
  au: 'au.app.clio.com',
};

// Clio sits behind a web firewall that rejects anonymous clients (Node's
// default User-Agent is just "node"), so every call identifies itself. Keep
// it plain: a URL in the User-Agent ("VerinLegal/1.0 (+https://…)") makes the
// same firewall answer every /api/v4 call with a bare HTML 403.
const USER_AGENT = 'VerinLegal/1.0';

// Refresh a little before the access token actually expires.
const REFRESH_SKEW_MS = 5 * 60 * 1000;

class ClioApiError extends Error {
  constructor(message, { status, body } = {}) {
    super(message);
    this.status = status;
    this.body = body;
  }
}

function hostFor(region) {
  const host = REGION_HOSTS[String(region || 'us').toLowerCase()];
  if (!host) throw new Error(`unknown Clio region "${region}" (use us, eu, ca or au)`);
  return host;
}

function authorizeUrl({ region, clientId, redirectUri, state }) {
  const u = new URL(`https://${hostFor(region)}/oauth/authorize`);
  u.searchParams.set('response_type', 'code');
  u.searchParams.set('client_id', clientId);
  u.searchParams.set('redirect_uri', redirectUri);
  u.searchParams.set('state', state);
  // Send the user back to us (with an error) if they click Deny, instead of
  // stranding them on Clio's site.
  u.searchParams.set('redirect_on_decline', 'true');
  return u.toString();
}

async function readJson(res) {
  const text = await res.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch (_) {
    return { raw: text.slice(0, 500) };
  }
}

function errorMessage(body, fallback) {
  if (!body) return fallback;
  if (typeof body.error === 'string') return body.error_description ? `${body.error}: ${body.error_description}` : body.error;
  if (body.error && body.error.message) return body.error.message;
  if (body.raw) return body.raw;
  return fallback;
}

function toTokens(body, now, previousRefreshToken) {
  if (!body || !body.access_token) throw new ClioApiError('Clio did not return an access token', { body });
  const expiresIn = Number(body.expires_in) || 0;
  return {
    accessToken: body.access_token,
    // Clio may or may not rotate the refresh token; keep the old one if not.
    refreshToken: body.refresh_token || previousRefreshToken || null,
    expiresAt: expiresIn ? now + expiresIn * 1000 : null,
  };
}

async function tokenRequest({ fetch, region, form }) {
  const res = await fetch(`https://${hostFor(region)}/oauth/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json', 'User-Agent': USER_AGENT },
    body: new URLSearchParams(form).toString(),
  });
  const body = await readJson(res);
  if (!res.ok) {
    if (body && body.raw) {
      // An HTML page instead of an OAuth error means something in front of
      // Clio refused the request. Log who answered so it can be traced.
      const h = (k) => (res.headers && res.headers.get ? res.headers.get(k) : null) || '';
      console.error('Clio token endpoint returned non-JSON', {
        status: res.status,
        server: h('server'),
        via: h('via'),
        requestId: h('x-request-id') || h('x-amzn-requestid') || h('cf-ray'),
        body: body.raw.slice(0, 300),
      });
    }
    throw new ClioApiError(`Clio token request failed (${res.status}): ${errorMessage(body, res.statusText)}`, {
      status: res.status,
      body,
    });
  }
  return body;
}

async function exchangeCode({ fetch, region, clientId, clientSecret, code, redirectUri, now = Date.now() }) {
  const body = await tokenRequest({
    fetch,
    region,
    form: {
      grant_type: 'authorization_code',
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
    },
  });
  return toTokens(body, now);
}

async function refreshTokens({ fetch, region, clientId, clientSecret, refreshToken, now = Date.now() }) {
  if (!refreshToken) throw new ClioApiError('no Clio refresh token stored; reconnect Clio', { status: 401 });
  const body = await tokenRequest({
    fetch,
    region,
    form: {
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: clientId,
      client_secret: clientSecret,
    },
  });
  return toTokens(body, now, refreshToken);
}

async function deauthorize({ fetch, region, accessToken }) {
  const res = await fetch(`https://${hostFor(region)}/oauth/deauthorize`, {
    method: 'POST',
    headers: {
      'User-Agent': USER_AGENT,
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({ token: accessToken }).toString(),
  });
  return res.ok;
}

async function apiRequest({ fetch, region, accessToken, method = 'GET', path, query, body }) {
  const u = new URL(`https://${hostFor(region)}/api/v4${path}`);
  for (const [k, v] of Object.entries(query || {})) {
    if (v !== undefined && v !== null && v !== '') u.searchParams.set(k, String(v));
  }
  const res = await fetch(u.toString(), {
    method,
    headers: {
      'User-Agent': USER_AGENT,
      Authorization: `Bearer ${accessToken}`,
      Accept: 'application/json',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await readJson(res);
  if (!res.ok) {
    if (json && json.raw) {
      // An HTML page instead of Clio's JSON: something in front of Clio refused it.
      const h = (k) => (res.headers && res.headers.get ? res.headers.get(k) : null) || '';
      console.error('Clio API returned non-JSON', {
        method,
        path,
        status: res.status,
        server: h('server'),
        via: h('via'),
        requestId: h('x-request-id') || h('x-amzn-requestid') || h('x-amz-cf-id') || h('cf-ray'),
        body: json.raw.slice(0, 300),
      });
    }
    throw new ClioApiError(`Clio ${method} ${path} failed (${res.status}): ${errorMessage(json, res.statusText)}`, {
      status: res.status,
      body: json,
    });
  }
  return json;
}

// Wraps every API call with: refresh if the token is (nearly) expired, and on a
// 401 refresh once and retry once. Expired tokens never surface to the attorney
// as a mysterious error (Production Readiness Guide §2.2, step 5).
function createClioSession({ fetch, region, clientId, clientSecret, loadTokens, saveTokens, now = () => Date.now() }) {
  let tokens = null;

  async function current() {
    if (!tokens) tokens = await loadTokens();
    if (!tokens || !tokens.accessToken) {
      throw new ClioApiError('Clio is not connected for this firm', { status: 401 });
    }
    if (tokens.expiresAt && tokens.expiresAt - REFRESH_SKEW_MS <= now()) {
      await refresh();
    }
    return tokens;
  }

  async function refresh() {
    tokens = await refreshTokens({
      fetch,
      region,
      clientId,
      clientSecret,
      refreshToken: tokens && tokens.refreshToken,
      now: now(),
    });
    await saveTokens(tokens);
    return tokens;
  }

  async function request(opts) {
    const t = await current();
    try {
      return await apiRequest({ fetch, region, accessToken: t.accessToken, ...opts });
    } catch (e) {
      if (e instanceof ClioApiError && e.status === 401) {
        await refresh();
        return apiRequest({ fetch, region, accessToken: tokens.accessToken, ...opts });
      }
      throw e;
    }
  }

  return {
    request,
    whoAmI: () => request({ path: '/users/who_am_i.json', query: { fields: 'id,name,email' } }),

    searchMatters: async ({ query, limit = 20 }) => {
      const res = await request({
        path: '/matters.json',
        query: {
          query,
          limit: Math.min(Math.max(Number(limit) || 20, 1), 50),
          fields: 'id,display_number,description,status,client{name}',
        },
      });
      return (res && res.data ? res.data : []).map((m) => ({
        id: String(m.id),
        displayNumber: m.display_number || '',
        description: m.description || '',
        status: m.status || '',
        clientName: (m.client && m.client.name) || '',
      }));
    },

    getMatter: async (id) => {
      const res = await request({
        path: `/matters/${encodeURIComponent(id)}.json`,
        query: { fields: 'id,display_number,description,status,client{name}' },
      });
      return res && res.data;
    },

    // Clio's three-step upload: create the document record (which returns a
    // signed put_url), PUT the bytes there, then mark the version uploaded.
    // versionOf: an existing Clio document id → upload as its next version
    // (versioned, not duplicated); otherwise a new document on the matter.
    uploadDocument: async ({ clioMatterId, name, bytes, contentType = 'application/pdf', versionOf = null }) => {
      const parent = versionOf ? { id: Number(versionOf), type: 'Document' } : { id: Number(clioMatterId), type: 'Matter' };
      const created = await request({
        method: 'POST',
        path: '/documents.json',
        query: { fields: 'id,name,latest_document_version{uuid,put_url,put_headers}' },
        body: { data: { name, parent } },
      });
      const doc = created && created.data;
      const version = doc && doc.latest_document_version;
      if (!doc || !version || !version.put_url || !version.uuid) {
        throw new ClioApiError('Clio did not return an upload URL for the new document', { body: created });
      }

      const putHeaders = {};
      for (const h of version.put_headers || []) {
        if (h && h.name) putHeaders[h.name] = h.value;
      }
      if (!Object.keys(putHeaders).some((k) => k.toLowerCase() === 'content-type')) {
        putHeaders['Content-Type'] = contentType;
      }
      const put = await fetch(version.put_url, { method: 'PUT', headers: putHeaders, body: bytes });
      if (!put.ok) {
        throw new ClioApiError(`uploading file bytes to Clio failed (${put.status})`, { status: put.status });
      }

      const done = await request({
        method: 'PATCH',
        path: `/documents/${doc.id}.json`,
        query: { fields: 'id,name,latest_document_version{fully_uploaded}' },
        body: { data: { uuid: version.uuid, fully_uploaded: true } },
      });
      const finished = done && done.data;
      if (!finished || !finished.latest_document_version || finished.latest_document_version.fully_uploaded !== true) {
        throw new ClioApiError('Clio did not confirm the upload completed', { body: done });
      }
      return { id: String(doc.id), name: doc.name || name };
    },
  };
}

function matterWebUrl(region, clioMatterId) {
  return `https://${hostFor(region)}/nc/#/matters/${encodeURIComponent(clioMatterId)}`;
}

module.exports = {
  REGION_HOSTS,
  ClioApiError,
  hostFor,
  authorizeUrl,
  exchangeCode,
  refreshTokens,
  deauthorize,
  apiRequest,
  createClioSession,
  matterWebUrl,
};
