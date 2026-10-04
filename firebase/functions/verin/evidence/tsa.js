// Verin Legal — RFC 3161 trusted timestamps over a receipt's SHA-256.
//
// Builds a TimeStampReq (DER) by hand — it is a small, fixed structure — posts
// it to a public Time-Stamp Authority, and keeps the signed TimeStampResp
// token as returned. The token is stored as a .tsr file next to the evidence;
// anyone can check it with:
//   openssl ts -reply -in receipt.tsr -text
//   openssl ts -verify -digest <item_hash> -in receipt.tsr -CAfile <tsa chain>
//
// Only the status, the echoed hash, the nonce and genTime are read back here;
// the token itself is never altered.

const crypto = require('crypto');

const SHA256_OID = [2, 16, 840, 1, 101, 3, 4, 2, 1];

function derLength(n) {
  if (n < 0x80) return Buffer.from([n]);
  const bytes = [];
  while (n > 0) {
    bytes.unshift(n & 0xff);
    n >>= 8;
  }
  return Buffer.from([0x80 | bytes.length, ...bytes]);
}

function tlv(tag, value) {
  return Buffer.concat([Buffer.from([tag]), derLength(value.length), value]);
}

function derOid(parts) {
  const out = [40 * parts[0] + parts[1]];
  for (const p of parts.slice(2)) {
    const stack = [p & 0x7f];
    let v = p >> 7;
    while (v > 0) {
      stack.unshift((v & 0x7f) | 0x80);
      v >>= 7;
    }
    out.push(...stack);
  }
  return tlv(0x06, Buffer.from(out));
}

// Positive INTEGER from raw bytes (adds a leading 0x00 if the top bit is set).
function derUInt(bytes) {
  let b = Buffer.from(bytes);
  while (b.length > 1 && b[0] === 0 && (b[1] & 0x80) === 0) b = b.subarray(1);
  if (b[0] & 0x80) b = Buffer.concat([Buffer.from([0]), b]);
  return tlv(0x02, b);
}

/// DER TimeStampReq for a hex SHA-256 digest. Returns { der, nonce }.
function buildTimeStampReq(hexDigest, nonce = crypto.randomBytes(8)) {
  const digest = Buffer.from(hexDigest, 'hex');
  if (digest.length !== 32) throw new Error('expected a SHA-256 digest');
  const algId = tlv(0x30, Buffer.concat([derOid(SHA256_OID), Buffer.from([0x05, 0x00])]));
  const imprint = tlv(0x30, Buffer.concat([algId, tlv(0x04, digest)]));
  const body = Buffer.concat([
    derUInt([1]), // version v1
    imprint,
    derUInt(nonce),
    Buffer.from([0x01, 0x01, 0xff]), // certReq TRUE
  ]);
  return { der: tlv(0x30, body), nonce: Buffer.from(nonce) };
}

// Minimal DER reader: returns { tag, len, header, start, end } for the element at `pos`.
function readTlv(buf, pos) {
  const tag = buf[pos];
  let len = buf[pos + 1];
  let header = 2;
  if (len & 0x80) {
    const n = len & 0x7f;
    len = 0;
    for (let i = 0; i < n; i++) len = len * 256 + buf[pos + 2 + i];
    header = 2 + n;
  }
  return { tag, len, header, start: pos + header, end: pos + header + len };
}

// GeneralizedTime "20261004123456Z" / "20261004123456.123Z" -> Date.
function parseGeneralizedTime(s) {
  const m = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:\.(\d{1,6}))?Z$/.exec(s);
  if (!m) return null;
  const ms = m[7] ? Number((m[7] + '000').slice(0, 3)) : 0;
  return new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6], ms));
}

/// Reads a TimeStampResp. Returns { ok, status, token (Buffer), genTime, error }.
/// genTime is the first GeneralizedTime in the token: in SignedData the
/// encapsulated TSTInfo comes before the certificates, and signingTime in the
/// signed attributes is a UTCTime, so the first 0x18 element is TSTInfo.genTime.
function parseTimeStampResp(resp, { hexDigest, nonce } = {}) {
  try {
    const outer = readTlv(resp, 0);
    if (outer.tag !== 0x30) return { ok: false, error: 'response is not a DER sequence' };
    const statusInfo = readTlv(resp, outer.start);
    const statusInt = readTlv(resp, statusInfo.start);
    const status = resp[statusInt.start + statusInt.len - 1];
    if (status !== 0 && status !== 1) return { ok: false, status, error: `TSA refused the request (status ${status})` };
    if (statusInfo.end >= outer.end) return { ok: false, status, error: 'TSA returned no token' };
    const token = resp.subarray(statusInfo.end, outer.end);

    if (hexDigest && token.indexOf(Buffer.from(hexDigest, 'hex')) < 0) {
      return { ok: false, status, error: 'token does not contain the requested hash' };
    }
    if (nonce && token.indexOf(nonce) < 0) {
      return { ok: false, status, error: 'token does not echo the request nonce' };
    }

    let genTime = null;
    for (let i = 0; i < token.length - 2; i++) {
      if (token[i] !== 0x18) continue;
      const len = token[i + 1];
      if (len < 15 || len > 24) continue;
      const s = token.subarray(i + 2, i + 2 + len).toString('ascii');
      const d = parseGeneralizedTime(s);
      if (d) {
        genTime = d;
        break;
      }
    }
    return { ok: true, status, token: Buffer.from(token), genTime };
  } catch (e) {
    return { ok: false, error: `could not read the TSA response: ${e.message}` };
  }
}

/// Requests a timestamp. Never throws: returns { ok, ... } or { ok: false, error }.
async function requestTimestamp(hexDigest, { url, name, fetchImpl, timeoutMs = 12000 } = {}) {
  const f = fetchImpl || globalThis.fetch;
  const { der, nonce } = buildTimeStampReq(hexDigest);
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), timeoutMs);
  try {
    const res = await f(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/timestamp-query', Accept: 'application/timestamp-reply' },
      body: der,
      signal: ctl.signal,
    });
    if (!res.ok) return { ok: false, error: `TSA HTTP ${res.status}` };
    const buf = Buffer.from(await res.arrayBuffer());
    const parsed = parseTimeStampResp(buf, { hexDigest, nonce });
    return { ...parsed, tsaName: name || url, tsaUrl: url };
  } catch (e) {
    return { ok: false, error: e.name === 'AbortError' ? 'TSA timed out' : `TSA request failed: ${e.message}` };
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { buildTimeStampReq, parseTimeStampResp, parseGeneralizedTime, requestTimestamp, readTlv, derOid };
