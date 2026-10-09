// Verin Legal — practice management systems beyond Clio (Clio keeps its own
// module in ../clio). Each provider exposes the same four things Verin needs:
//
//   searchMatters(query)                → [{ id, display, name, client, url }]
//   uploadDocument({ matterId, name, bytes, contentType }) → { id }
//   addNote({ matterId, subject, text }) → { id }
//   whoAmI()                            → { name }
//
// Endpoint details that the vendors only publish behind developer access are
// kept in ENDPOINTS below, marked CONFIRM, so they can be checked against the
// vendor's docs (and corrected in one place) once access is granted.
//
// Pure HTTP: `fetch` is injected, so everything here is testable without a
// network.

class PracticeApiError extends Error {
  constructor(provider, message, { status = null, body = null } = {}) {
    super(message);
    this.provider = provider;
    this.status = status;
    this.body = body;
  }
}

async function readBody(res) {
  const text = await res.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch (_) {
    return { raw: text.slice(0, 500) };
  }
}

const norm = (s) => String(s || '').toLowerCase();
const matches = (q, ...fields) => {
  const t = norm(q).trim();
  return !t || fields.some((f) => norm(f).includes(t));
};

// ---------------------------------------------------------------------------
// PracticePanther — OAuth 2 (authorization code), like Clio.
// Docs: support.practicepanther.com/en/articles/479897; Swagger at
// app.practicepanther.com/content/apidocs (after access is granted).
// ---------------------------------------------------------------------------

const PP = {
  host: 'https://app.practicepanther.com',
  authorize: '/oauth/authorize',
  token: '/oauth/token',
  // CONFIRM against the Swagger docs once API access is granted:
  matters: '/api/v2/matters', // GET, OData ($top, $skip, $orderby)
  notes: '/api/v2/notes', // POST { matter_ref: { id }, subject, note }
  files: '/api/v2/files', // POST multipart: file + matter_ref.id
  me: '/api/v2/users/me',
};

function ppAuthorizeUrl({ clientId, redirectUri, state }) {
  const u = new URL(PP.host + PP.authorize);
  u.searchParams.set('response_type', 'code');
  u.searchParams.set('client_id', clientId);
  u.searchParams.set('redirect_uri', redirectUri);
  u.searchParams.set('state', state);
  return u.toString();
}

async function ppToken({ fetch, form, now = Date.now() }) {
  const res = await fetch(PP.host + PP.token, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' },
    body: new URLSearchParams(form).toString(),
  });
  const body = await readBody(res);
  if (!res.ok || !body || !body.access_token) {
    throw new PracticeApiError('practicepanther', `PracticePanther sign-in failed (${res.status}): ${(body && (body.error_description || body.error)) || 'no token'}`, { status: res.status, body });
  }
  return {
    accessToken: body.access_token,
    // Refresh tokens rotate: always keep the newest.
    refreshToken: body.refresh_token || form.refresh_token || null,
    expiresAt: now + (Number(body.expires_in) || 3600) * 1000,
  };
}

function ppExchangeCode({ fetch, clientId, clientSecret, code, redirectUri }) {
  return ppToken({ fetch, form: { grant_type: 'authorization_code', code, client_id: clientId, client_secret: clientSecret, redirect_uri: redirectUri } });
}

/// loadTokens/saveTokens persist { accessToken, refreshToken, expiresAt }.
function createPracticePantherSession({ fetch, clientId, clientSecret, loadTokens, saveTokens, now = () => Date.now() }) {
  let tokens = null;
  async function current() {
    if (!tokens) tokens = await loadTokens();
    if (!tokens || !tokens.accessToken) throw new PracticeApiError('practicepanther', 'PracticePanther is not connected for this firm.', { status: 401 });
    if (tokens.expiresAt && tokens.expiresAt - 60000 < now()) await refresh();
    return tokens;
  }
  async function refresh() {
    if (!tokens || !tokens.refreshToken) throw new PracticeApiError('practicepanther', 'PracticePanther connection expired. Reconnect it in Settings.', { status: 401 });
    tokens = await ppToken({ fetch, form: { grant_type: 'refresh_token', refresh_token: tokens.refreshToken, client_id: clientId, client_secret: clientSecret } });
    await saveTokens(tokens);
  }
  async function call(method, path, { query, json, form } = {}, retried = false) {
    const t = await current();
    const u = new URL(PP.host + path);
    for (const [k, v] of Object.entries(query || {})) if (v !== undefined && v !== null) u.searchParams.set(k, String(v));
    const headers = { Authorization: `Bearer ${t.accessToken}`, Accept: 'application/json' };
    let body;
    if (json) {
      headers['Content-Type'] = 'application/json';
      body = JSON.stringify(json);
    } else if (form) {
      body = form; // FormData sets its own content type
    }
    const res = await fetch(u.toString(), { method, headers, body });
    if (res.status === 401 && !retried) {
      await refresh();
      return call(method, path, { query, json, form }, true);
    }
    const out = await readBody(res);
    if (!res.ok) throw new PracticeApiError('practicepanther', `PracticePanther ${method} ${path} failed (${res.status})`, { status: res.status, body: out });
    return out;
  }
  const list = (b) => (Array.isArray(b) ? b : (b && (b.value || b.data || b.items)) || []);
  return {
    provider: 'practicepanther',
    whoAmI: async () => {
      const b = await call('GET', PP.me).catch(() => null);
      return { name: (b && (b.display_name || b.name || [b.first_name, b.last_name].filter(Boolean).join(' '))) || '' };
    },
    searchMatters: async (q) => {
      // Fetch recent matters and match locally: works whatever filter syntax
      // the API accepts.
      const b = await call('GET', PP.matters, { query: { $top: 200, $orderby: 'created_at desc' } });
      return list(b)
        .map((m) => ({
          id: String(m.id || m.matter_id || ''),
          display: String(m.number || m.display_number || m.matter_number || ''),
          name: String(m.name || m.display_name || ''),
          client: String((m.account_ref && (m.account_ref.display_name || m.account_ref.name)) || m.account_name || ''),
          url: m.id ? `${PP.host}/Matter/Edit/${m.id}` : '',
        }))
        .filter((m) => m.id && matches(q, m.name, m.display, m.client))
        .slice(0, 25);
    },
    uploadDocument: async ({ matterId, name, bytes, contentType }) => {
      const fd = new FormData();
      fd.append('matter_ref.id', String(matterId));
      fd.append('file', new Blob([bytes], { type: contentType || 'application/octet-stream' }), name);
      const b = await call('POST', PP.files, { form: fd });
      return { id: String((b && (b.id || (b.data && b.data.id))) || '') };
    },
    addNote: async ({ matterId, subject, text }) => {
      const b = await call('POST', PP.notes, { json: { matter_ref: { id: String(matterId) }, subject, note: text } });
      return { id: String((b && b.id) || '') };
    },
  };
}

// ---------------------------------------------------------------------------
// Filevine — personal access token (PAT) for a firm's service account,
// exchanged with a client id + secret (Verin's partner credentials, or the
// firm's own from Account Manager → Access Tokens → Client Secrets).
// Docs: support.filevine.com/hc/en-us/articles/29937964706203,
//       developer.filevine.io (API v2).
// ---------------------------------------------------------------------------

const FV = {
  identity: { us: 'https://identity.filevine.com/connect/token', ca: 'https://identity.filevine.ca/connect/token' },
  api: { us: 'https://api.filevineapp.com/fv-app/v2', ca: 'https://api.filevineapp.ca/fv-app/v2' },
  web: { us: 'https://app.filevine.com', ca: 'https://app.filevine.ca' },
  scope: 'fv.api.gateway.access tenant filevine.v2.api.* openid email fv.auth.tenant.read',
  // CONFIRM against developer.filevine.io once partner access is granted:
  projects: '/Projects', // GET ?name=&limit=
  documents: '/Documents', // POST { filename, size } → { documentId, url }; PUT bytes to url
  attach: (projectId, documentId) => `/Projects/${encodeURIComponent(projectId)}/Documents/${encodeURIComponent(documentId)}`,
  notes: '/Notes', // POST { projectId: { native }, body }
  orgs: '/utils/GetUserOrgsWithToken',
};

const native = (v) => (v && typeof v === 'object' ? v.native ?? v.Native ?? v.id ?? '' : v ?? '');

function createFilevineSession({ fetch, region = 'us', clientId, clientSecret, pat, scope = FV.scope, now = () => Date.now() }) {
  const r = region === 'ca' ? 'ca' : 'us';
  let auth = null; // { accessToken, expiresAt, orgId, userId }

  async function token() {
    const res = await fetch(FV.identity[r], {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' },
      body: new URLSearchParams({ client_id: clientId, client_secret: clientSecret, grant_type: 'personal_access_token', scope, token: pat }).toString(),
    });
    const body = await readBody(res);
    if (!res.ok || !body || !body.access_token) {
      throw new PracticeApiError('filevine', `Filevine sign-in failed (${res.status}): ${(body && (body.error_description || body.error)) || 'no token'}`, { status: res.status, body });
    }
    return { accessToken: body.access_token, expiresAt: now() + (Number(body.expires_in) || 3600) * 1000 };
  }

  async function current() {
    if (auth && auth.expiresAt - 60000 > now()) return auth;
    const t = await token();
    const res = await fetch(FV.api[r] + FV.orgs, { method: 'POST', headers: { Authorization: `Bearer ${t.accessToken}`, Accept: 'application/json' } });
    const b = await readBody(res);
    if (!res.ok) throw new PracticeApiError('filevine', `Filevine did not return the organization (${res.status})`, { status: res.status, body: b });
    const user = (b && (b.user || b.User)) || {};
    const orgs = (b && (b.orgs || b.Orgs)) || [];
    auth = {
      ...t,
      userId: String(native(user.userId || user.UserId || user.id) || ''),
      orgId: String(native((orgs[0] && (orgs[0].orgId || orgs[0].OrgId || orgs[0].id)) || '') || ''),
      userName: String(user.fullname || user.fullName || user.username || user.email || ''),
    };
    if (!auth.orgId || !auth.userId) throw new PracticeApiError('filevine', 'Filevine did not return an organization and user for this token.', { body: b });
    return auth;
  }

  async function call(method, path, { query, json } = {}) {
    const a = await current();
    const u = new URL(FV.api[r] + path);
    for (const [k, v] of Object.entries(query || {})) if (v !== undefined && v !== null && v !== '') u.searchParams.set(k, String(v));
    const headers = { Authorization: `Bearer ${a.accessToken}`, 'x-fv-orgid': a.orgId, 'x-fv-userid': a.userId, Accept: 'application/json' };
    if (json) headers['Content-Type'] = 'application/json';
    const res = await fetch(u.toString(), { method, headers, body: json ? JSON.stringify(json) : undefined });
    const out = await readBody(res);
    if (!res.ok) throw new PracticeApiError('filevine', `Filevine ${method} ${path} failed (${res.status})`, { status: res.status, body: out });
    return out;
  }
  const items = (b) => (Array.isArray(b) ? b : (b && (b.items || b.Items || b.data)) || []);

  return {
    provider: 'filevine',
    whoAmI: async () => ({ name: (await current()).userName }),
    searchMatters: async (q) => {
      const b = await call('GET', FV.projects, { query: { name: q || undefined, limit: 50 } });
      return items(b)
        .map((p) => {
          const id = String(native(p.projectId || p.ProjectId || p.id) || '');
          return {
            id,
            display: String(p.number || p.projectNumber || ''),
            name: String(p.projectName || p.ProjectName || p.name || ''),
            client: String(p.clientName || (p.client && (p.client.fullName || p.client.name)) || ''),
            url: p.projectUrl || (id ? `${FV.web[r]}/#/project/${id}` : ''),
          };
        })
        .filter((p) => p.id && matches(q, p.name, p.display, p.client))
        .slice(0, 25);
    },
    uploadDocument: async ({ matterId, name, bytes, contentType }) => {
      const created = await call('POST', FV.documents, { json: { filename: name, size: bytes.length } });
      const docId = String(native(created && (created.documentId || created.DocumentId || created.id)) || '');
      const url = created && (created.url || created.Url || created.uploadUrl);
      if (!docId || !url) throw new PracticeApiError('filevine', 'Filevine did not return an upload address for the document.', { body: created });
      const put = await fetch(url, { method: 'PUT', headers: { 'Content-Type': contentType || 'application/octet-stream', 'Content-Length': String(bytes.length) }, body: bytes });
      if (!put.ok) throw new PracticeApiError('filevine', `Uploading the file to Filevine failed (${put.status})`, { status: put.status });
      await call('POST', FV.attach(matterId, docId));
      return { id: docId };
    },
    addNote: async ({ matterId, subject, text }) => {
      const b = await call('POST', FV.notes, { json: { projectId: { native: Number(matterId) || matterId }, body: subject ? `${subject}\n\n${text}` : text } });
      return { id: String(native(b && (b.noteId || b.NoteId || b.id)) || '') };
    },
  };
}

const PROVIDERS = {
  practicepanther: { id: 'practicepanther', label: 'PracticePanther', auth: 'oauth' },
  filevine: { id: 'filevine', label: 'Filevine', auth: 'pat' },
};

module.exports = {
  PROVIDERS,
  PracticeApiError,
  PP,
  FV,
  ppAuthorizeUrl,
  ppExchangeCode,
  createPracticePantherSession,
  createFilevineSession,
};
