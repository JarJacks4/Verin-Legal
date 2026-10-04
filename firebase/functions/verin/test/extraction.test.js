// Run: node --test test/
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');

const {
  validateExtraction,
  parseModelResponse,
  detectImageMediaType,
  looksLikeHeic,
  toThreadMessages,
  storagePathFromDownloadUrl,
} = require('../extraction/validate');
const { createExtractor, buildRequest, InputError, STATUS } = require('../extraction/extractor');

const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(64, 1)]);
const JPG = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(64, 2)]);
const HEIC = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypheic'), Buffer.alloc(32)]);

const goodMsg = (o = {}) => ({
  speaker: 'client',
  text: 'Can you drop the kids at 6?',
  timestampLabel: '2:14 PM',
  isGap: false,
  confidence: 0.97,
  isHeader: false,
  ...o,
});
const good = (o = {}) => ({ containsConversation: true, platform: 'iMessage', messages: [goodMsg()], ...o });

// ---------- validateExtraction (§14e checklist) ----------

test('accepts a well-formed extraction', () => {
  const r = validateExtraction(good());
  assert.equal(r.ok, true);
  assert.equal(r.value.messages.length, 1);
});

test('rejects a missing field on any entry', () => {
  const m = goodMsg();
  delete m.isHeader;
  const r = validateExtraction(good({ messages: [goodMsg(), m] }));
  assert.equal(r.ok, false);
  assert.match(r.errors.join(), /messages\[1\]\.isHeader missing/);
});

test('rejects string booleans instead of coercing them', () => {
  const r = validateExtraction(good({ messages: [goodMsg({ isGap: 'false' })] }));
  assert.equal(r.ok, false);
  assert.match(r.errors.join(), /isGap not a boolean/);
});

test('rejects confidence as a string, a percentage, or out of range', () => {
  for (const c of ['0.9', 85, -0.1, NaN]) {
    const r = validateExtraction(good({ messages: [goodMsg({ confidence: c })] }));
    assert.equal(r.ok, false, `confidence ${c} should fail`);
  }
});

test('normalizes speaker case but flags a third speaker value', () => {
  const ok = validateExtraction(good({ messages: [goodMsg({ speaker: 'Client' })] }));
  assert.equal(ok.ok, true);
  assert.equal(ok.value.messages[0].speaker, 'client');
  const bad = validateExtraction(good({ messages: [goodMsg({ speaker: 'Mom' })] }));
  assert.equal(bad.ok, false);
});

test('empty array on a screenshot the model says is a conversation is a failure', () => {
  const r = validateExtraction(good({ messages: [] }));
  assert.equal(r.ok, false);
  assert.match(r.errors.join(), /silent failure/);
});

test('empty array is fine when the image is not a conversation', () => {
  const r = validateExtraction(good({ containsConversation: false, messages: [] }));
  assert.equal(r.ok, true);
});

// ---------- parseModelResponse ----------

test('parses JSON text and strips a stray code fence', () => {
  const r = parseModelResponse({ stop_reason: 'end_turn', content: [{ type: 'text', text: '```json\n{"a":1}\n```' }] });
  assert.equal(r.ok, true);
  assert.deepEqual(r.parsed, { a: 1 });
});

test('treats max_tokens truncation as a config error, not a model error', () => {
  const r = parseModelResponse({ stop_reason: 'max_tokens', content: [{ type: 'text', text: '{"a":' }] });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /EXTRACTION_MAX_TOKENS/);
});

test('reports a refusal clearly', () => {
  const r = parseModelResponse({ stop_reason: 'refusal', content: [] });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /declined/);
});

test('ignores thinking blocks and reads only text', () => {
  const r = parseModelResponse({
    stop_reason: 'end_turn',
    content: [{ type: 'thinking', thinking: 'hmm' }, { type: 'text', text: '{"ok":true}' }],
  });
  assert.deepEqual(r.parsed, { ok: true });
});

// ---------- image + URL helpers ----------

test('detects png/jpeg and flags HEIC', () => {
  assert.equal(detectImageMediaType(PNG), 'image/png');
  assert.equal(detectImageMediaType(JPG), 'image/jpeg');
  assert.equal(detectImageMediaType(HEIC), null);
  assert.equal(looksLikeHeic(HEIC), true);
});

test('turns a FlutterFlow download URL back into a storage path, same bucket only', () => {
  const url =
    'https://firebasestorage.googleapis.com/v0/b/verin-app.appspot.com/o/users%2Fabc%2Fuploads%2F1700.png?alt=media&token=t';
  assert.equal(storagePathFromDownloadUrl(url, 'verin-app.appspot.com'), 'users/abc/uploads/1700.png');
  assert.equal(storagePathFromDownloadUrl(url, 'someone-else.appspot.com'), null);
  assert.equal(storagePathFromDownloadUrl('https://evil.example.com/v0/b/verin-app.appspot.com/o/x.png', null), null);
  assert.equal(storagePathFromDownloadUrl('not a url', null), null);
});

test('toThreadMessages produces the full 8-field ThreadMessages shape', () => {
  const v = validateExtraction(good()).value;
  const [m] = toThreadMessages(v, { sourceThumbnailUrl: 'https://x/y.png' });
  assert.deepEqual(Object.keys(m).sort(), [
    'confidence', 'isGap', 'isHeader', 'platform', 'sourceThumbnailUrl', 'speaker', 'text', 'timestampLabel',
  ]);
  assert.equal(m.platform, 'iMessage');
});

// ---------- request building ----------

test('new models get effort, not temperature (temperature is a 400 on Sonnet 5.5)', () => {
  const r = buildRequest({ model: 'claude-sonnet-5-5', maxTokens: 100, mediaType: 'image/png', base64: 'AA', clientSide: 'right' });
  assert.equal(r.temperature, undefined);
  assert.equal(r.output_config.effort, 'low');
  assert.equal(r.output_config.format.type, 'json_schema');
});

test('Haiku 4.5 gets temperature 0 and no effort', () => {
  const r = buildRequest({ model: 'claude-haiku-4-5-20251001', maxTokens: 100, mediaType: 'image/png', base64: 'AA', clientSide: 'left' });
  assert.equal(r.temperature, 0);
  assert.equal(r.output_config.effort, undefined);
  assert.match(r.messages[0].content[1].text, /left side of the screen were sent by the client/);
});

// ---------- end-to-end with fakes ----------

function fakes({ docExists = true, fileBytes = PNG, response, apiError } = {}) {
  const writes = [];
  const audits = [];
  const docRef = {
    get: async () => ({ exists: docExists }),
    collection: () => ({ doc: () => ({ __audit: true }) }),
  };
  const db = {
    collection: () => ({ doc: () => docRef }),
    batch: () => {
      const ops = [];
      return {
        set: (ref, data) => ops.push({ ref, data }),
        commit: async () => {
          for (const op of ops) (op.ref.__audit ? audits : writes).push(op.data);
        },
      };
    },
  };
  const bucket = {
    name: 'verin-app.appspot.com',
    file: () => ({ exists: async () => [fileBytes !== null], download: async () => [fileBytes] }),
  };
  const calls = [];
  const anthropic = {
    messages: {
      create: async (req) => {
        calls.push(req);
        if (apiError) throw apiError;
        return response;
      },
    },
  };
  const extractor = createExtractor({
    db, bucket, anthropic,
    model: 'claude-sonnet-5-5',
    maxTokens: 16000,
    serverTimestamp: () => 'TS',
    allowedCollections: ['Receipts', 'Items'],
  });
  return { extractor, writes, audits, calls };
}

const okResponse = (body) => ({
  id: 'msg_1',
  stop_reason: 'end_turn',
  usage: { input_tokens: 1500, output_tokens: 300 },
  content: [{ type: 'text', text: JSON.stringify(body) }],
});

test('happy path writes threadMessages, platform, hash and an audit record', async () => {
  const body = good({ messages: [goodMsg(), goodMsg({ speaker: 'other', text: 'Sure' })] });
  const { extractor, writes, audits, calls } = fakes({ response: okResponse(body) });
  const url = 'https://firebasestorage.googleapis.com/v0/b/verin-app.appspot.com/o/users%2Fu1%2Fa.png?alt=media';
  const r = await extractor.run({ uid: 'u1', collection: 'Receipts', docId: 'r1', imageUrl: url, clientSide: 'right' });

  assert.equal(r.status, STATUS.EXTRACTED);
  assert.equal(r.messageCount, 2);
  assert.equal(calls[0].messages[0].content[0].source.media_type, 'image/png');
  const w = writes[0];
  assert.equal(w.extractionState, 'extracted');
  assert.equal(w.detectedPlatform, 'iMessage');
  assert.equal(w.threadMessages.length, 2);
  assert.equal(w.threadMessages[0].sourceThumbnailUrl, url);
  assert.equal(w.extractionSourceSha256, crypto.createHash('sha256').update(PNG).digest('hex'));
  assert.equal(w.extractionSourcePath, 'users/u1/a.png');
  assert.equal(audits[0].usage.inputTokens, 1500);
  assert.equal(audits[0].status, 'extracted');
});

test('malformed model output writes extraction_failed with reasons, not partial data', async () => {
  const body = good({ messages: [goodMsg({ isGap: 'true' })] });
  const { extractor, writes } = fakes({ response: okResponse(body) });
  const r = await extractor.run({ collection: 'Receipts', docId: 'r1', storagePath: 'users/u1/a.png' });
  assert.equal(r.status, STATUS.FAILED);
  assert.equal(writes[0].extractionState, 'extraction_failed');
  assert.equal(writes[0].threadMessages, undefined, 'must not write partial threadMessages');
  assert.match(writes[0].extractionErrors.join(), /isGap/);
});

test('API errors are recorded as extraction_failed', async () => {
  const err = Object.assign(new Error('overloaded'), { status: 529 });
  const { extractor, writes, audits } = fakes({ apiError: err });
  const r = await extractor.run({ collection: 'Receipts', docId: 'r1', storagePath: 'users/u1/a.png' });
  assert.equal(r.status, STATUS.FAILED);
  assert.match(writes[0].extractionErrors[0], /overloaded/);
  assert.equal(audits[0].apiStatus, 529);
});

test('HEIC is rejected before calling the API', async () => {
  const { extractor, calls, writes } = fakes({ fileBytes: HEIC });
  const r = await extractor.run({ collection: 'Receipts', docId: 'r1', storagePath: 'users/u1/a.heic' });
  assert.equal(r.status, STATUS.FAILED);
  assert.equal(calls.length, 0);
  assert.match(writes[0].extractionErrors[0], /HEIC/);
});

test('non-conversation image is its own state, not a failure', async () => {
  const { extractor, writes } = fakes({ response: okResponse(good({ containsConversation: false, messages: [] })) });
  const r = await extractor.run({ collection: 'Receipts', docId: 'r1', storagePath: 'users/u1/a.png' });
  assert.equal(r.status, STATUS.NO_CONVERSATION);
  assert.equal(writes[0].extractionState, 'no_conversation_detected');
});

test('caller mistakes throw InputError', async () => {
  const { extractor } = fakes({ response: okResponse(good()) });
  await assert.rejects(extractor.run({ collection: 'users', docId: 'x', storagePath: 'a.png' }), InputError);
  await assert.rejects(extractor.run({ collection: 'Receipts', docId: 'a/b', storagePath: 'a.png' }), InputError);
  await assert.rejects(extractor.run({ collection: 'Receipts', docId: 'r1', storagePath: '../secret' }), InputError);
  await assert.rejects(
    extractor.run({ collection: 'Receipts', docId: 'r1', imageUrl: 'https://firebasestorage.googleapis.com/v0/b/other/o/a.png' }),
    InputError,
  );
  const missing = fakes({ docExists: false, response: okResponse(good()) });
  await assert.rejects(missing.extractor.run({ collection: 'Receipts', docId: 'r1', storagePath: 'a.png' }), /not found/);
});
