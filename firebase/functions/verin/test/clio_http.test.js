// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const zlib = require('zlib');
const { nodeFetch } = require('../clio/http');

test('Clio client sends only our headers (no browser fingerprint) and decodes gzip', async () => {
  let seen = null;
  let body = '';
  const server = http.createServer((req, res) => {
    seen = req.headers;
    req.on('data', (c) => (body += c));
    req.on('end', () => {
      res.writeHead(200, { 'content-type': 'application/json', 'content-encoding': 'gzip' });
      res.end(zlib.gzipSync(JSON.stringify({ data: [{ id: 1 }] })));
    });
  });
  await new Promise((r) => server.listen(0, r));
  const port = server.address().port;
  try {
    const res = await nodeFetch(
      `https://127.0.0.1:${port}/api/v4/matters.json?query=Benjamin%20Miller&fields=id%2Cclient%7Bname%7D`,
      { method: 'POST', headers: { 'User-Agent': 'VerinLegal/1.0', Authorization: 'Bearer t', Accept: 'application/json', 'Content-Type': 'application/json' }, body: '{"a":1}' },
      { request: http.request },
    );
    assert.equal(res.ok, true);
    assert.deepEqual(await res.json(), { data: [{ id: 1 }] });
    assert.equal(seen['user-agent'], 'VerinLegal/1.0');
    assert.equal(seen['sec-fetch-mode'], undefined);
    assert.equal(seen['accept-language'], undefined);
    assert.equal(seen['content-length'], '7');
    assert.equal(body, '{"a":1}');
  } finally {
    server.close();
  }
});
