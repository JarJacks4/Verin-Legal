// Run: npm test   (node --test verin/test/*.test.js)
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const { Readable } = require('stream');

const tsa = require('../evidence/tsa');
const { validateAnalysis, buildAnalysisRequest, analyzeWithClaude } = require('../evidence/analyze');
const { detectKind, extractText, rtfToText } = require('../evidence/docs');
const video = require('../evidence/video');
const { processReceipt, fieldsFromAnalysis } = require('../evidence/process');
const { physicalRecordBytes, dateOnly, copyAndHash } = require('../evidence/ingest');
const { buildManifest, readmeText } = require('../export/archive');
const { computeEntryHash, originDigest } = require('../chain/chain');

const sha = (b) => crypto.createHash('sha256').update(b).digest('hex');

// ---------------------------------------------------------------- RFC 3161

test('TimeStampReq is valid DER with the digest, nonce and certReq', () => {
  const h = sha('hello');
  const nonce = Buffer.from('0102030405060708', 'hex');
  const { der } = tsa.buildTimeStampReq(h, nonce);
  assert.equal(der[0], 0x30);
  assert.ok(der.indexOf(Buffer.from(h, 'hex')) > 0, 'digest present');
  assert.ok(der.indexOf(nonce) > 0, 'nonce present');
  // sha256 OID 2.16.840.1.101.3.4.2.1
  assert.ok(der.indexOf(Buffer.from('0609608648016503040201', 'hex')) > 0);
  assert.deepEqual([...der.subarray(der.length - 3)], [0x01, 0x01, 0xff]);
});

test('TimeStampReq nonce with the top bit set is encoded as a positive INTEGER', () => {
  const { der } = tsa.buildTimeStampReq(sha('x'), Buffer.from('ff00000000000001', 'hex'));
  assert.ok(der.indexOf(Buffer.from('020900ff00000000000001', 'hex')) > 0);
});

test('parses a granted TimeStampResp (fixture made with openssl ts -reply)', () => {
  const resp = fs.readFileSync(path.join(__dirname, 'fixtures', 'hello.tsr'));
  const r = tsa.parseTimeStampResp(resp, { hexDigest: sha('hello') });
  assert.equal(r.ok, true, r.error);
  assert.equal(r.status, 0);
  assert.ok(r.genTime instanceof Date);
  assert.ok(r.token.length > 100);
});

test('rejects a token for a different hash', () => {
  const resp = fs.readFileSync(path.join(__dirname, 'fixtures', 'hello.tsr'));
  const r = tsa.parseTimeStampResp(resp, { hexDigest: sha('something else') });
  assert.equal(r.ok, false);
  assert.match(r.error, /hash/);
});

test('rejects a refused TimeStampResp', () => {
  // SEQUENCE { SEQUENCE { INTEGER 2 } }
  const r = tsa.parseTimeStampResp(Buffer.from('3005300302010 2'.replace(/ /g, ''), 'hex'));
  assert.equal(r.ok, false);
  assert.match(r.error, /refused/);
});

test('requestTimestamp never throws and reports HTTP errors', async () => {
  const r = await tsa.requestTimestamp(sha('a'), { url: 'http://tsa.example', fetchImpl: async () => ({ ok: false, status: 503 }) });
  assert.equal(r.ok, false);
  assert.match(r.error, /503/);
});

test('requestTimestamp checks the echoed nonce', async () => {
  const resp = fs.readFileSync(path.join(__dirname, 'fixtures', 'hello.tsr'));
  const r = await tsa.requestTimestamp(sha('hello'), {
    url: 'http://tsa.example',
    fetchImpl: async () => ({ ok: true, arrayBuffer: async () => resp }),
  });
  // The fixture was made for a different request, so its nonce can't match.
  assert.equal(r.ok, false);
  assert.match(r.error, /nonce/);
});

test('GeneralizedTime parsing', () => {
  assert.equal(tsa.parseGeneralizedTime('20261004172329Z').toISOString(), '2026-10-04T17:23:29.000Z');
  assert.equal(tsa.parseGeneralizedTime('20261004172329.5Z').toISOString(), '2026-10-04T17:23:29.500Z');
  assert.equal(tsa.parseGeneralizedTime('bogus'), null);
});

// ---------------------------------------------------------------- analysis schema

const msg = (o = {}) => ({ speaker: 'client', text: 'Running late', timestampLabel: '5:40 PM', isGap: false, confidence: 0.95, isHeader: false, ...o });
const analysis = (o = {}) => ({
  evidenceType: 'conversation',
  summary: 'A text thread about a pickup time.',
  eventDate: '2025-04-18',
  eventDateSource: 'on-screen timestamp',
  eventDateConfidence: 'high',
  containsConversation: true,
  platform: 'iMessage',
  messages: [msg()],
  ...o,
});

test('validateAnalysis accepts a conversation with a date', () => {
  const r = validateAnalysis(analysis());
  assert.equal(r.ok, true, JSON.stringify(r.errors));
  assert.equal(r.value.eventDate.toISOString().slice(0, 10), '2025-04-18');
  assert.equal(r.value.eventDateConfidence, 'high');
});

test('validateAnalysis drops the date when confidence is none', () => {
  const r = validateAnalysis(analysis({ eventDateConfidence: 'none' }));
  assert.equal(r.ok, true);
  assert.equal(r.value.eventDate, null);
});

test('validateAnalysis rejects impossible and future dates', () => {
  assert.equal(validateAnalysis(analysis({ eventDate: '2025-02-30' })).ok, false);
  assert.equal(validateAnalysis(analysis({ eventDate: '2999-01-01' })).ok, false);
  assert.equal(validateAnalysis(analysis({ eventDate: '04/18/2025' })).ok, false);
});

test('validateAnalysis accepts a non-conversation photo with no date', () => {
  const r = validateAnalysis(analysis({ evidenceType: 'photo', eventDate: '', eventDateConfidence: 'none', containsConversation: false, platform: '', messages: [] }));
  assert.equal(r.ok, true, JSON.stringify(r.errors));
  assert.equal(r.value.conversation.containsConversation, false);
});

test('validateAnalysis rejects a malformed message', () => {
  const r = validateAnalysis(analysis({ messages: [msg({ confidence: 85 })] }));
  assert.equal(r.ok, false);
});

test('analysis request uses structured output and effort on 5.x models', () => {
  const req = buildAnalysisRequest({ model: 'claude-sonnet-5-5', maxTokens: 1000, content: [{ type: 'text', text: 'x' }], clientSide: 'left', kind: 'document' });
  assert.equal(req.output_config.format.type, 'json_schema');
  assert.equal(req.output_config.effort, 'low');
  assert.equal(req.temperature, undefined);
  assert.match(req.messages[0].content.at(-1).text, /left side were sent by the client/);
});

test('summary instructions forbid authenticity language', () => {
  const req = buildAnalysisRequest({ model: 'claude-sonnet-5-5', maxTokens: 10, content: [], clientSide: 'right' });
  assert.match(req.system, /Never state or imply that anything is authentic/);
});

test('analyzeWithClaude maps a response into thread messages', async () => {
  const anthropic = { messages: { create: async () => ({ stop_reason: 'end_turn', content: [{ type: 'text', text: JSON.stringify(analysis()) }] }) } };
  const r = await analyzeWithClaude({ anthropic, model: 'claude-sonnet-5-5', maxTokens: 100, content: [], clientSide: 'right', sourceUrl: 'u' });
  assert.equal(r.ok, true);
  assert.equal(r.threadMessages.length, 1);
  assert.equal(r.threadMessages[0].sourceThumbnailUrl, 'u');
});

test('analyzeWithClaude reports API errors without throwing', async () => {
  const anthropic = { messages: { create: async () => { const e = new Error('overloaded'); e.status = 529; throw e; } } };
  const r = await analyzeWithClaude({ anthropic, model: 'm', maxTokens: 1, content: [], clientSide: 'right' });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /overloaded/);
});

test('low-confidence messages send the item to review', () => {
  const v = validateAnalysis(analysis({ messages: [msg({ confidence: 0.4 })] })).value;
  const f = fieldsFromAnalysis(v, [{ isHeader: false, confidence: 0.4 }]);
  assert.equal(f.classificationLabel, 'Uncertain');
  assert.match(f.reviewReason, /hard to read/);
});

// ---------------------------------------------------------------- documents

test('detectKind by magic bytes and extension', () => {
  assert.equal(detectKind(Buffer.from('%PDF-1.7 xxxx'), 'a.pdf'), 'pdf');
  assert.equal(detectKind(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0, 0, 0, 0]), 'a.png'), 'image');
  assert.equal(detectKind(Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypheic')]), 'a.heic'), 'heic');
  assert.equal(detectKind(Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypqt  ')]), 'a.mov'), 'video');
  assert.equal(detectKind(Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypM4A ')]), 'a.m4a', 'audio/mp4'), 'audio');
  assert.equal(detectKind(Buffer.from('PK\u0003\u0004xxxx'), 'a.docx'), 'docx');
  assert.equal(detectKind(Buffer.from('PK\u0003\u0004xxxx'), 'a.odt'), 'odt');
  assert.equal(detectKind(Buffer.from('From: a@b.c\n'), 'm.eml'), 'eml');
  assert.equal(detectKind(Buffer.from('hello world'), 'notes.txt'), 'text');
  assert.equal(detectKind(Buffer.from('{\\rtf1 hi}'), 'a.rtf'), 'rtf');
  assert.equal(detectKind(Buffer.from([0xd0, 0xcf, 0x11, 0xe0, 0, 0]), 'a.doc'), 'doc');
  assert.equal(detectKind(Buffer.from([0xd0, 0xcf, 0x11, 0xe0, 0, 0]), 'a.msg'), 'msg');
});

test('extracts text from a .docx', async () => {
  const JSZip = require('jszip');
  const zip = new JSZip();
  zip.file('[Content_Types].xml', '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>');
  zip.file('_rels/.rels', '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>');
  zip.file('word/document.xml', '<?xml version="1.0"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Pickup moved to 6pm on April 18, 2025.</w:t></w:r></w:p></w:body></w:document>');
  const buf = await zip.generateAsync({ type: 'nodebuffer' });
  const r = await extractText('docx', buf);
  assert.equal(r.ok, true, r.error);
  assert.match(r.text, /Pickup moved to 6pm/);
});

test('extracts headers and body from an .eml', async () => {
  const eml = [
    'From: Elena <elena@example.com>',
    'To: Firm <intake@example.com>',
    'Date: Fri, 18 Apr 2025 17:41:00 -0400',
    'Subject: Exchange tonight',
    'Content-Type: text/plain; charset=utf-8',
    '',
    'He said he would be there at 5:20.',
  ].join('\r\n');
  const r = await extractText('eml', Buffer.from(eml));
  assert.equal(r.ok, true, r.error);
  assert.match(r.text, /Subject: Exchange tonight/);
  assert.match(r.text, /5:20/);
  assert.equal(r.meta.emailDate.toISOString(), '2025-04-18T21:41:00.000Z');
});

test('RTF and ODT text', async () => {
  assert.match(rtfToText('{\\rtf1\\ansi Hello\\par World}'), /Hello\nWorld/);
  const JSZip = require('jszip');
  const zip = new JSZip();
  zip.file('content.xml', '<office:document-content><office:body><office:text><text:p>Line one</text:p><text:p>Line &amp; two</text:p></office:text></office:body></office:document-content>');
  const r = await extractText('odt', await zip.generateAsync({ type: 'nodebuffer' }));
  assert.equal(r.ok, true);
  assert.match(r.text, /Line one\nLine & two/);
});

test('legacy .doc gets a clear message', async () => {
  const r = await extractText('doc', Buffer.alloc(10));
  assert.equal(r.ok, false);
  assert.match(r.error, /docx or PDF/);
});

// ---------------------------------------------------------------- video

test('summarizeProbe reads duration, audio, creation time', () => {
  const p = video.summarizeProbe({
    format: { format_name: 'mov,mp4', duration: '47.2', tags: { creation_time: '2025-04-18T22:12:00.000000Z' } },
    streams: [
      { codec_type: 'video', codec_name: 'h264', width: 1080, height: 1920, r_frame_rate: '30000/1001' },
      { codec_type: 'audio', codec_name: 'aac' },
    ],
  });
  assert.equal(p.durationSeconds, 47);
  assert.equal(p.hasAudio, true);
  assert.equal(p.fps, 29.97);
  assert.equal(p.creationTime, '2025-04-18T22:12:00.000000Z');
});

test('origin fidelity by channel (spec §2)', () => {
  assert.equal(video.originFidelityFor('sms'), 'transcoded_in_transit');
  assert.equal(video.originFidelityFor('whatsapp'), 'transcoded_in_transit');
  assert.equal(video.originFidelityFor('email'), 'undetermined');
  assert.equal(video.originFidelityFor('upload'), 'undetermined');
});

test('container date is ignored on transcoded items and epoch values', () => {
  const probe = { ok: true, creationTime: '2025-04-18T22:12:00Z' };
  assert.equal(video.containerDate(probe, 'transcoded_in_transit', new Date()), null);
  assert.equal(video.containerDate(probe, 'undetermined', new Date()).toISOString(), '2025-04-18T22:12:00.000Z');
  assert.equal(video.containerDate({ ok: true, creationTime: '1904-01-01T00:00:00Z' }, 'undetermined', new Date()), null);
  assert.equal(video.containerDate(probe, 'undetermined', new Date('2024-01-01')), null, 'not after receipt');
});

test('validateVideoResult keeps transcript and screen-recording messages', () => {
  const r = video.validateVideoResult(
    {
      isScreenRecording: true,
      hasSpeech: false,
      summary: 'Screen recording of a chat.',
      onScreenDate: '2025-04-18',
      transcript: [],
      platform: 'WhatsApp',
      messages: [msg(), msg({ speaker: 'other', text: 'Here now.' })],
    },
    { sourceUrl: 'u' },
  );
  assert.equal(r.ok, true, JSON.stringify(r.errors));
  assert.equal(r.value.threadMessages.length, 2);
  assert.equal(r.value.onScreenDate.toISOString().slice(0, 10), '2025-04-18');
});

test('analyzeVideo surfaces a Vertex setup hint', async () => {
  const client = { models: { generateContent: async () => { throw new Error('PERMISSION_DENIED: Vertex AI API has not been used in project'); } } };
  const r = await video.analyzeVideo({ model: 'm', gcsUri: 'gs://b/x', mimeType: 'video/mp4', clientSide: 'right', hasAudio: true, client });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /aiplatform\.googleapis\.com/);
});

// ---------------------------------------------------------------- processReceipt with fakes

function fakeEnv({ receipt, files }) {
  const store = { receipt: { ...receipt }, runs: [] };
  const receiptRef = {
    id: 'r1',
    get: async () => ({ exists: true, data: () => store.receipt }),
    collection: () => ({ doc: () => ({ kind: 'run' }) }),
  };
  const db = {
    batch: () => {
      const ops = [];
      return {
        set: (ref, data) => ops.push([ref, data]),
        commit: async () => {
          for (const [ref, data] of ops) {
            if (ref === receiptRef) Object.assign(store.receipt, data);
            else store.runs.push(data);
          }
        },
      };
    },
  };
  const bucket = {
    name: 'bucket',
    file: (p) => ({
      exists: async () => [Object.prototype.hasOwnProperty.call(files, p)],
      getMetadata: async () => [{ size: String(files[p].length), contentType: '' }],
      createReadStream: ({ start = 0, end } = {}) => Readable.from([files[p].subarray(start, end === undefined ? undefined : end + 1)]),
      download: async () => [files[p]],
      save: async (b) => {
        files[`${p}`] = Buffer.from(b);
      },
    }),
  };
  const deps = {
    db,
    bucket,
    claudeModel: 'claude-sonnet-5-5',
    maxTokens: 1000,
    videoModel: 'gemini',
    serverTimestamp: () => 'SERVER_TS',
    Timestamp: { fromDate: (d) => ({ ts: d.toISOString() }) },
    log: { warn() {}, error() {} },
  };
  return { store, receiptRef, deps };
}

test('processReceipt reads a screenshot into the thread', async () => {
  const png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(200, 7)]);
  const { store, receiptRef, deps } = fakeEnv({
    receipt: { itemKind: 'photo', sourceStoragePath: 'm/r1.png', sourceUrl: 'https://x', originalFileName: 'IMG_1.png', clientSide: 'right' },
    files: { 'm/r1.png': png },
  });
  let request;
  deps.anthropic = () => ({ messages: { create: async (req) => { request = req; return { stop_reason: 'end_turn', content: [{ type: 'text', text: JSON.stringify(analysis()) }] }; } } });
  const r = await processReceipt(deps, receiptRef);
  assert.equal(r.status, 'extracted');
  assert.equal(request.messages[0].content[0].type, 'image');
  assert.equal(request.messages[0].content[0].source.media_type, 'image/png');
  assert.equal(store.receipt.itemKind, 'screenshot');
  assert.equal(store.receipt.threadMessages.length, 1);
  assert.equal(store.receipt.classificationLabel, 'Processed');
  assert.deepEqual(store.receipt.resolvedDate, { ts: '2025-04-18T12:00:00.000Z' });
  assert.equal(store.runs.length, 1);
});

test('processReceipt sends PDFs as document blocks', async () => {
  const { store, receiptRef, deps } = fakeEnv({
    receipt: { itemKind: 'document', sourceStoragePath: 'm/r1.pdf', originalFileName: 'school.pdf' },
    files: { 'm/r1.pdf': Buffer.from('%PDF-1.7\n...') },
  });
  let request;
  deps.anthropic = () => ({
    messages: {
      create: async (req) => {
        request = req;
        return { stop_reason: 'end_turn', content: [{ type: 'text', text: JSON.stringify(analysis({ evidenceType: 'document', containsConversation: false, platform: '', messages: [] })) }] };
      },
    },
  });
  const r = await processReceipt(deps, receiptRef);
  assert.equal(r.status, 'no_conversation_detected');
  assert.equal(request.messages[0].content[0].type, 'document');
  assert.equal(store.receipt.aiSummary, 'A text thread about a pickup time.');
});

test('processReceipt flags HEIC for a person instead of failing silently', async () => {
  const heic = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypheic'), Buffer.alloc(40)]);
  const { store, receiptRef, deps } = fakeEnv({ receipt: { itemKind: 'photo', sourceStoragePath: 'm/r1.heic', originalFileName: 'a.heic' }, files: { 'm/r1.heic': heic } });
  deps.anthropic = () => assert.fail('should not call Claude');
  const r = await processReceipt(deps, receiptRef);
  assert.equal(r.status, 'extraction_failed');
  assert.equal(store.receipt.classificationLabel, 'Uncertain');
  assert.match(store.receipt.reviewReason, /HEIC/);
});

test('processReceipt defers long video transcription and keeps the probe', async () => {
  const mp4 = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypisom'), Buffer.alloc(40)]);
  const { store, receiptRef, deps } = fakeEnv({
    receipt: { itemKind: 'video', channel: 'SMS', channelKey: 'sms', sourceStoragePath: 'm/r1.mp4', sourceUrl: 'https://x', originalFileName: 'clip.mp4', receivedAt: { toDate: () => new Date() } },
    files: { 'm/r1.mp4': mp4 },
  });
  deps.probeMedia = async () => ({ ok: true, durationSeconds: 900, hasAudio: true, creationTime: '2025-04-18T22:12:00Z', raw: { format: {} } });
  deps.videoClient = { models: { generateContent: async () => assert.fail('should defer') } };
  const r = await processReceipt(deps, receiptRef);
  assert.equal(r.status, 'deferred');
  assert.equal(store.receipt.transcriptionState, 'deferred');
  assert.equal(store.receipt.originFidelity, 'transcoded_in_transit');
  assert.equal(store.receipt.resolvedDate, undefined, 'transcoded container date is not used');
});

test('processReceipt transcribes a short video', async () => {
  const mp4 = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypisom'), Buffer.alloc(40)]);
  const { store, receiptRef, deps } = fakeEnv({
    receipt: { itemKind: 'video', channelKey: 'upload', sourceStoragePath: 'm/r1.mp4', sourceUrl: 'https://x', originalFileName: 'clip.mp4', receivedAt: { toDate: () => new Date() } },
    files: { 'm/r1.mp4': mp4 },
  });
  deps.probeMedia = async () => ({ ok: true, durationSeconds: 47, hasAudio: true, creationTime: '2025-04-18T22:12:00Z', raw: {} });
  deps.videoClient = {
    models: {
      generateContent: async (req) => {
        assert.equal(req.contents[0].parts[0].fileData.fileUri, 'gs://bucket/m/r1.mp4');
        return { text: JSON.stringify({ isScreenRecording: false, hasSpeech: true, summary: 'Doorbell clip.', onScreenDate: '', transcript: [{ startSeconds: 3, speaker: 'Speaker 1', text: 'Here now.' }], platform: '', messages: [] }) };
      },
    },
  };
  const r = await processReceipt(deps, receiptRef);
  assert.equal(r.status, 'extracted');
  assert.equal(store.receipt.transcriptionState, 'complete');
  assert.equal(store.receipt.transcript.length, 1);
  assert.equal(store.receipt.dateSource, 'container creation_time');
  assert.equal(store.receipt.classificationLabel, 'Processed');
});

test('physical items need no reading', async () => {
  const { store, receiptRef, deps } = fakeEnv({ receipt: { itemKind: 'physical', classificationLabel: 'Processed' }, files: {} });
  const r = await processReceipt(deps, receiptRef);
  assert.equal(r.status, 'not_applicable');
  assert.equal(store.receipt.classificationLabel, 'Processed');
});

// ---------------------------------------------------------------- ingest helpers

test('physical record bytes are canonical (key order independent)', () => {
  const a = physicalRecordBytes({ description: 'Notebook', custodyNotes: 'Safe 2', fromLabel: 'Client', channel: 'in_person', dateReceived: '2026-10-01' });
  const b = physicalRecordBytes({ fromLabel: 'Client', channel: 'in_person', dateReceived: '2026-10-01', custodyNotes: 'Safe 2', description: 'Notebook' });
  assert.equal(sha(a), sha(b));
  assert.match(a.toString(), /^\{"channel":"in_person","custodyNotes":"Safe 2"/);
});

test('dateOnly parses calendar dates only', () => {
  assert.equal(dateOnly('2026-10-04').toISOString(), '2026-10-04T12:00:00.000Z');
  assert.equal(dateOnly('10/04/2026'), null);
});

test('copyAndHash hashes exactly the bytes it copies', async () => {
  const data = crypto.randomBytes(300000);
  const chunks = [];
  const src = { createReadStream: () => Readable.from([data.subarray(0, 100000), data.subarray(100000)]) };
  const { Writable } = require('stream');
  const dest = { createWriteStream: () => new Writable({ write(c, _e, cb) { chunks.push(c); cb(); } }) };
  const r = await copyAndHash(src, dest, { contentType: 'x', metadata: {}, size: data.length });
  assert.equal(r.sha256, sha(data));
  assert.equal(r.bytes, data.length);
  assert.ok(Buffer.concat(chunks).equals(data));
});

// ---------------------------------------------------------------- manifest + verify.py

function buildChain(items) {
  let prev = '0'.repeat(64);
  return items.map((it, i) => {
    const receivedAtIso = new Date(Date.UTC(2026, 9, 1, 10, i)).toISOString();
    const od = originDigest({ channel: 'upload', source: `file:${it.name}` });
    const entryHash = computeEntryHash({ prevHash: prev, itemHash: sha(it.bytes), receivedAtIso, originDigest: od });
    const e = { seq: i + 1, prevHash: prev, itemHash: sha(it.bytes), receivedAtIso, originDigest: od, entryHash };
    prev = entryHash;
    return e;
  });
}

test('manifest + verify.py: pass on an intact record, fail on a changed exhibit', (t) => {
  try {
    execFileSync('python3', ['--version']);
  } catch (_) {
    t.skip('python3 not available');
    return;
  }
  const items = [
    { name: 'a.png', bytes: Buffer.from('first file') },
    { name: 'b.pdf', bytes: Buffer.from('second file') },
  ];
  const chain = buildChain(items);
  const receipts = items.map((it, i) => ({
    id: `r${i}`,
    data: {
      receivedAt: new Date(chain[i].receivedAtIso),
      channel: 'Upload',
      itemKind: 'photo',
      content: it.name,
      originalFileName: it.name,
      item_hash: sha(it.bytes),
      chainSeq: i + 1,
      entryHash: chain[i].entryHash,
      sourceStoragePath: `m/r${i}`,
    },
  }));
  const manifest = buildManifest({
    matterId: 'm1',
    matter: { matterName: 'Test v. Test', chainHeadHash: chain[1].entryHash },
    receipts,
    chain,
    exportedAt: new Date(),
    exportedBy: 'tester',
    exhibitFor: ({ data }) => `exhibits/${String(data.chainSeq).padStart(3, '0')}-${data.originalFileName}`,
  });
  assert.equal(manifest.chain_verification_at_export.ok, true);
  assert.match(readmeText(manifest), /python3 verify.py/);

  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'verin-'));
  fs.mkdirSync(path.join(dir, 'exhibits'));
  fs.writeFileSync(path.join(dir, 'manifest.json'), JSON.stringify(manifest));
  items.forEach((it, i) => fs.writeFileSync(path.join(dir, manifest.receipts[i].exhibit_file), it.bytes));
  const verifier = path.join(__dirname, '..', 'export', 'verify.py');
  const out = execFileSync('python3', [verifier, dir]).toString();
  assert.match(out, /PASS/);
  assert.match(out, /Chain entries verified:  2/);

  fs.writeFileSync(path.join(dir, manifest.receipts[0].exhibit_file), Buffer.from('tampered'));
  let failed = false;
  try {
    execFileSync('python3', [verifier, dir], { stdio: 'pipe' });
  } catch (e) {
    failed = true;
    assert.match(e.stdout.toString(), /hash mismatch/);
  }
  assert.equal(failed, true);
});
