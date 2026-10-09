const test = require('node:test');
const assert = require('node:assert');
const V = require('../practice/providers');

/// Fake fetch: routes by "METHOD url-prefix" and records calls.
function fakeFetch(routes) {
  const calls = [];
  const fn = async (url, opts = {}) => {
    const method = opts.method || 'GET';
    calls.push({ method, url, opts });
    const key = Object.keys(routes).find((k) => {
      const [m, prefix] = k.split(' ');
      return m === method && url.startsWith(prefix);
    });
    if (!key) return { ok: false, status: 404, text: async () => '{}' };
    const r = typeof routes[key] === 'function' ? routes[key](url, opts) : routes[key];
    return { ok: (r.status || 200) < 400, status: r.status || 200, text: async () => (r.body === undefined ? '' : JSON.stringify(r.body)) };
  };
  fn.calls = calls;
  return fn;
}

test('PracticePanther authorize URL carries client, redirect and state', () => {
  const u = new URL(V.ppAuthorizeUrl({ clientId: 'cid', redirectUri: 'https://x/cb', state: 's1' }));
  assert.strictEqual(u.origin + u.pathname, 'https://app.practicepanther.com/oauth/authorize');
  assert.strictEqual(u.searchParams.get('response_type'), 'code');
  assert.strictEqual(u.searchParams.get('state'), 's1');
});

test('PracticePanther: search filters locally, refreshes an expired token and keeps the rotated refresh token', async () => {
  let saved = null;
  const f = fakeFetch({
    'POST https://app.practicepanther.com/oauth/token': { body: { access_token: 'new', refresh_token: 'r2', expires_in: 3600 } },
    'GET https://app.practicepanther.com/api/v2/matters': {
      body: [
        { id: 'm1', name: 'Reyes v. Reyes', number: '0041', account_ref: { display_name: 'Dana Reyes' } },
        { id: 'm2', name: 'Carter divorce', number: '0042' },
      ],
    },
  });
  const s = V.createPracticePantherSession({
    fetch: f,
    clientId: 'c',
    clientSecret: 'x',
    loadTokens: async () => ({ accessToken: 'old', refreshToken: 'r1', expiresAt: 1 }),
    saveTokens: async (t) => {
      saved = t;
    },
    now: () => 1000,
  });
  const res = await s.searchMatters('reyes');
  assert.deepStrictEqual(res.map((m) => m.id), ['m1']);
  assert.strictEqual(res[0].client, 'Dana Reyes');
  assert.strictEqual(saved.refreshToken, 'r2');
  const tokenCall = f.calls.find((c) => c.url.includes('/oauth/token'));
  assert.match(tokenCall.opts.body, /grant_type=refresh_token/);
  const apiCall = f.calls.find((c) => c.url.includes('/api/v2/matters'));
  assert.strictEqual(apiCall.opts.headers.Authorization, 'Bearer new');
});

test('Filevine: token, org lookup, headers, and the three-step document upload', async () => {
  const f = fakeFetch({
    'POST https://identity.filevine.com/connect/token': { body: { access_token: 'tok', expires_in: 3600 } },
    'POST https://api.filevineapp.com/fv-app/v2/utils/GetUserOrgsWithToken': { body: { user: { userId: { native: 77 }, fullname: 'Svc Verin' }, orgs: [{ orgId: 9 }] } },
    'POST https://api.filevineapp.com/fv-app/v2/Documents': { body: { documentId: { native: 555 }, url: 'https://s3.example/put' } },
    'PUT https://s3.example/put': { body: {} },
    'POST https://api.filevineapp.com/fv-app/v2/Projects/123/Documents/555': { body: {} },
    'GET https://api.filevineapp.com/fv-app/v2/Projects': { body: { items: [{ projectId: { native: 123 }, projectName: 'Alvarez PI', number: 'PI-1' }] } },
  });
  const s = V.createFilevineSession({ fetch: f, clientId: 'c', clientSecret: 'x', pat: 'p' });
  assert.deepStrictEqual(await s.whoAmI(), { name: 'Svc Verin' });
  const up = await s.uploadDocument({ matterId: '123', name: 'record.zip', bytes: Buffer.from('abc'), contentType: 'application/zip' });
  assert.strictEqual(up.id, '555');
  const create = f.calls.find((c) => c.url.endsWith('/Documents') && c.method === 'POST');
  assert.strictEqual(create.opts.headers['x-fv-orgid'], '9');
  assert.strictEqual(create.opts.headers['x-fv-userid'], '77');
  assert.deepStrictEqual(JSON.parse(create.opts.body), { filename: 'record.zip', size: 3 });
  assert.ok(f.calls.some((c) => c.method === 'PUT' && c.url === 'https://s3.example/put'));
  assert.ok(f.calls.some((c) => c.url.endsWith('/Projects/123/Documents/555')));
  const found = await s.searchMatters('alvarez');
  assert.deepStrictEqual(found.map((p) => [p.id, p.display]), [['123', 'PI-1']]);
  // One token request for the whole session.
  assert.strictEqual(f.calls.filter((c) => c.url.includes('/connect/token')).length, 1);
});

test('Filevine sign-in failure is reported, not swallowed', async () => {
  const f = fakeFetch({ 'POST https://identity.filevine.com/connect/token': { status: 400, body: { error: 'invalid_client' } } });
  const s = V.createFilevineSession({ fetch: f, clientId: 'c', clientSecret: 'x', pat: 'p' });
  await assert.rejects(s.whoAmI(), (e) => e instanceof V.PracticeApiError && /invalid_client/.test(e.message));
});
