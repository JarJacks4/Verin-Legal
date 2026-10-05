// Verin Legal — a minimal fetch() for talking to Clio.
//
// Node's built-in fetch (undici) adds browser-style headers of its own
// (sec-fetch-mode: cors, accept-language: *). Clio's edge firewall treats
// that fingerprint as an automated client and answers with a bare
// "403 Forbidden" page. This client sends exactly the headers we set —
// plus Host, Content-Length and Accept-Encoding — over node:https.

const https = require('https');
const zlib = require('zlib');

function headersOf(res) {
  return {
    get: (k) => {
      const v = res.headers[String(k).toLowerCase()];
      return Array.isArray(v) ? v.join(', ') : v === undefined ? null : String(v);
    },
    raw: res.headers,
  };
}

/// fetch(url, { method, headers, body }) -> { ok, status, statusText, headers, text(), json() }
function nodeFetch(url, opts = {}, { request = https.request, timeoutMs = 60000 } = {}) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const body = opts.body === undefined || opts.body === null ? null : Buffer.isBuffer(opts.body) ? opts.body : Buffer.from(String(opts.body));
    const headers = { 'Accept-Encoding': 'gzip', ...(opts.headers || {}) };
    if (body) headers['Content-Length'] = String(body.length);
    const req = request(
      {
        method: opts.method || 'GET',
        hostname: u.hostname,
        port: u.port || 443,
        path: `${u.pathname}${u.search}`,
        headers,
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('error', reject);
        res.on('end', () => {
          let buf = Buffer.concat(chunks);
          const enc = String(res.headers['content-encoding'] || '').toLowerCase();
          try {
            if (enc === 'gzip') buf = zlib.gunzipSync(buf);
            else if (enc === 'deflate') buf = zlib.inflateSync(buf);
          } catch (_) {
            /* leave as received */
          }
          const text = buf.toString('utf8');
          resolve({
            ok: res.statusCode >= 200 && res.statusCode < 300,
            status: res.statusCode,
            statusText: res.statusMessage || '',
            headers: headersOf(res),
            text: async () => text,
            json: async () => JSON.parse(text),
          });
        });
      },
    );
    req.setTimeout(timeoutMs, () => req.destroy(new Error(`request to ${u.hostname} timed out`)));
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

module.exports = { nodeFetch };
