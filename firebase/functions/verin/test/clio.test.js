// Run: node --test test/*.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');

const clio = require('../clio/clioApi');
const { seal, open } = require('../clio/tokenCrypto');

// Minimal fetch fake: route by "METHOD url-prefix" to handlers.
function fakeFetch(routes) {
  const calls = [];
  const fn = async (url, init = {}) => {
    const method = init.method || 'GET';
    calls.push({ url, method, init });
    const key = Object.keys(routes).find((k) => {
      const [m, prefix] = k.split(' ');
      return m === method && url.startsWith(prefix);
    });
    if (!key) throw new Error(`unexpected fetch ${method} ${url}`);
    const r = typeof routes[key] === 'function' ? routes[key]({ url, init, calls }) : routes[key];
    const status = r.status || 200;
    const text = r.body === undefined ? '' : typeof r.body === 'string' ? r.body : JSON.stringify(r.body);
    return { ok: status >= 200 && status < 300, status, statusText: String(status), text: async () => text };
  };
  fn.calls = calls;
  return fn;
}

// ---------- tokenCrypto ----------

test('seal/open round-trips and detects tampering', () => {
  const key = crypto.randomBytes(32).toString('base64');
  const sealed = seal('refresh-abc', key);
  assert.notEqual(sealed, 'refresh-abc');
  assert.equal(open(sealed, key), 'refresh-abc');
  const parts = sealed.split('.');
  parts[3] = Buffer.from('tampered').toString('base64url');
  assert.throws(() => open(parts.join('.'), key));
  assert.throws(() => open(sealed, crypto.randomBytes(32).toString('base64')));
});

test('rejects a key that is not 32 bytes', () => {
  assert.throws(() => seal('x', Buffer.alloc(16).toString('base64')), /32 bytes/);
});

// ---------- URLs ----------

test('authorize URL carries state, redirect and decline flag, per region', () => {
  const u = new URL(clio.authorizeUrl({ region: 'eu', clientId: 'CID', redirectUri: 'https://x/cb', state: 'S1' }));
  assert.equal(u.host, 'eu.app.clio.com');
  assert.equal(u.pathname, '/oauth/authorize');
  assert.equal(u.searchParams.get('response_type'), 'code');
  assert.equal(u.searchParams.get('client_id'), 'CID');
  assert.equal(u.searchParams.get('redirect_uri'), 'https://x/cb');
  assert.equal(u.searchParams.get('state'), 'S1');
  assert.equal(u.searchParams.get('redirect_on_decline'), 'true');
  assert.throws(() => clio.hostFor('mars'), /unknown Clio region/);
});

// ---------- token exchange ----------

test('code exchange posts form-encoded body with the secret, server-side', async () => {
  const f = fakeFetch({
    'POST https://app.clio.com/oauth/token': ({ init }) => {
      const form = new URLSearchParams(init.body);
      assert.equal(init.headers['Content-Type'], 'application/x-www-form-urlencoded');
      assert.equal(form.get('grant_type'), 'authorization_code');
      assert.equal(form.get('client_secret'), 'SECRET');
      assert.equal(form.get('code'), 'CODE');
      return { body: { access_token: 'A1', refresh_token: 'R1', expires_in: 2592000, token_type: 'bearer' } };
    },
  });
  const t = await clio.exchangeCode({ fetch: f, region: 'us', clientId: 'C', clientSecret: 'SECRET', code: 'CODE', redirectUri: 'https://x/cb', now: 1000 });
  assert.deepEqual(t, { accessToken: 'A1', refreshToken: 'R1', expiresAt: 1000 + 2592000 * 1000 });
});

test('a token error surfaces Clio\'s own message', async () => {
  const f = fakeFetch({ 'POST https://app.clio.com/oauth/token': { status: 400, body: { error: 'invalid_grant', error_description: 'code expired' } } });
  await assert.rejects(
    clio.exchangeCode({ fetch: f, region: 'us', clientId: 'C', clientSecret: 'S', code: 'X', redirectUri: 'r' }),
    /invalid_grant: code expired/,
  );
});

test('refresh keeps the old refresh token when Clio does not rotate it', async () => {
  const f = fakeFetch({ 'POST https://app.clio.com/oauth/token': { body: { access_token: 'A2', expires_in: 60 } } });
  const t = await clio.refreshTokens({ fetch: f, region: 'us', clientId: 'C', clientSecret: 'S', refreshToken: 'R1', now: 0 });
  assert.equal(t.refreshToken, 'R1');
  assert.equal(t.accessToken, 'A2');
});

// ---------- session: refresh + retry ----------

function session(fetch, initial, now = () => 10_000) {
  const saved = [];
  const s = clio.createClioSession({
    fetch, region: 'us', clientId: 'C', clientSecret: 'S',
    loadTokens: async () => initial,
    saveTokens: async (t) => saved.push(t),
    now,
  });
  return { s, saved };
}

test('refreshes before calling when the access token is about to expire', async () => {
  const f = fakeFetch({
    'POST https://app.clio.com/oauth/token': { body: { access_token: 'NEW', refresh_token: 'R2', expires_in: 3600 } },
    'GET https://app.clio.com/api/v4/users/who_am_i.json': ({ init }) => {
      assert.equal(init.headers.Authorization, 'Bearer NEW');
      return { body: { data: { id: 1, name: 'Jared' } } };
    },
  });
  const { s, saved } = session(f, { accessToken: 'OLD', refreshToken: 'R1', expiresAt: 10_000 + 60_000 });
  const who = await s.whoAmI();
  assert.equal(who.data.name, 'Jared');
  assert.equal(saved[0].refreshToken, 'R2', 'rotated refresh token must be persisted');
});

test('on a 401, refreshes once and retries once', async () => {
  let hits = 0;
  const f = fakeFetch({
    'POST https://app.clio.com/oauth/token': { body: { access_token: 'NEW', expires_in: 3600 } },
    'GET https://app.clio.com/api/v4/matters.json': ({ init }) => {
      hits++;
      if (init.headers.Authorization === 'Bearer OLD') return { status: 401, body: { error: { message: 'expired' } } };
      return { body: { data: [{ id: 42, display_number: '00042-Whitmore', description: 'Custody', status: 'Open', client: { name: 'Elena Whitmore' } }] } };
    },
  });
  const { s } = session(f, { accessToken: 'OLD', refreshToken: 'R1', expiresAt: null });
  const matters = await s.searchMatters({ query: 'Whitmore' });
  assert.equal(hits, 2);
  assert.deepEqual(matters[0], { id: '42', displayNumber: '00042-Whitmore', description: 'Custody', status: 'Open', clientName: 'Elena Whitmore' });
  const q = new URL(f.calls.find((c) => c.url.includes('matters.json')).url).searchParams;
  assert.equal(q.get('query'), 'Whitmore');
  assert.match(q.get('fields'), /client\{name\}/);
});

test('a second 401 after refresh is surfaced, not looped', async () => {
  const f = fakeFetch({
    'POST https://app.clio.com/oauth/token': { body: { access_token: 'NEW', expires_in: 3600 } },
    'GET https://app.clio.com/api/v4/users/who_am_i.json': { status: 401, body: { error: { message: 'revoked' } } },
  });
  const { s } = session(f, { accessToken: 'OLD', refreshToken: 'R1', expiresAt: null });
  await assert.rejects(s.whoAmI(), (e) => e instanceof clio.ClioApiError && e.status === 401);
  assert.equal(f.calls.filter((c) => c.url.includes('who_am_i')).length, 2);
});

test('not connected is a clear 401, with no network call', async () => {
  const f = fakeFetch({});
  const { s } = session(f, null);
  await assert.rejects(s.whoAmI(), /not connected/);
  assert.equal(f.calls.length, 0);
});

// ---------- document upload ----------

test('uploads a document in Clio\'s three steps and confirms fully_uploaded', async () => {
  const bytes = Buffer.from('%PDF-1.7 fake');
  const f = fakeFetch({
    'POST https://app.clio.com/api/v4/documents.json': ({ url, init }) => {
      const body = JSON.parse(init.body);
      assert.deepEqual(body, { data: { name: 'Whitmore export.pdf', parent: { id: 42, type: 'Matter' } } });
      assert.match(decodeURIComponent(url), /latest_document_version\{uuid,put_url,put_headers\}/);
      return {
        status: 201,
        body: {
          data: {
            id: 900, name: 'Whitmore export.pdf',
            latest_document_version: {
              uuid: 'uuid-1', put_url: 'https://storage.clio.example/put/abc',
              put_headers: [{ name: 'x-amz-server-side-encryption', value: 'AES256' }, { name: 'Content-Type', value: 'application/pdf' }],
            },
          },
        },
      };
    },
    'PUT https://storage.clio.example/put/abc': ({ init }) => {
      assert.equal(init.headers['x-amz-server-side-encryption'], 'AES256');
      assert.equal(init.body, bytes);
      return { status: 200 };
    },
    'PATCH https://app.clio.com/api/v4/documents/900.json': ({ init }) => {
      assert.deepEqual(JSON.parse(init.body), { data: { uuid: 'uuid-1', fully_uploaded: true } });
      return { body: { data: { id: 900, name: 'Whitmore export.pdf', latest_document_version: { fully_uploaded: true } } } };
    },
  });
  const { s } = session(f, { accessToken: 'A', refreshToken: 'R', expiresAt: null });
  const r = await s.uploadDocument({ clioMatterId: '42', name: 'Whitmore export.pdf', bytes });
  assert.deepEqual(r, { id: '900', name: 'Whitmore export.pdf' });
  assert.deepEqual(f.calls.map((c) => c.method), ['POST', 'PUT', 'PATCH']);
});

test('a failed byte upload is an error, never a silent success', async () => {
  const f = fakeFetch({
    'POST https://app.clio.com/api/v4/documents.json': {
      body: { data: { id: 1, latest_document_version: { uuid: 'u', put_url: 'https://s/put', put_headers: [] } } },
    },
    'PUT https://s/put': { status: 403 },
  });
  const { s } = session(f, { accessToken: 'A', refreshToken: 'R', expiresAt: null });
  await assert.rejects(s.uploadDocument({ clioMatterId: '1', name: 'x.pdf', bytes: Buffer.from('x') }), /uploading file bytes/);
});

test('matter web link points at the right regional host', () => {
  assert.equal(clio.matterWebUrl('ca', 42), 'https://ca.app.clio.com/nc/#/matters/42');
});
