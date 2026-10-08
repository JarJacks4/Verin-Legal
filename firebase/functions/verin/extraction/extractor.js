// Verin Legal — core screenshot extraction, with dependencies injected so it
// can be tested without Firebase or a live API key.
//
//   image bytes -> Claude -> parse + validate (guide §14e) -> threadMessages
//
// Two entry points:
//   extractFromBytes(...)  pure-ish: bytes in, validated result + audit out.
//   createExtractor(...).run(...)  re-runs extraction for an existing
//       Receipts/Items document whose image is already in Storage, writing the
//       result (or a clear failure state) back onto that document.

const crypto = require('crypto');
const ai = require('../ai/models');
const { EXTRACTION_SCHEMA, buildSystemPrompt, buildUserText } = require('./schema');
const {
  detectImageMediaType,
  looksLikeHeic,
  validateExtraction,
  toThreadMessages,
  parseModelResponse,
  storagePathFromDownloadUrl,
} = require('./validate');

// Base64 payload limit on the Claude API is 10 MB; base64 inflates by 4/3.
const MAX_IMAGE_BYTES = 7 * 1024 * 1024;

const STATUS = {
  EXTRACTED: 'extracted',
  FAILED: 'extraction_failed',
  NO_CONVERSATION: 'no_conversation_detected',
};

// Models that still accept sampling params and run without thinking by default.
// Newer models (Sonnet 5.5, Opus 5.5, ...) reject a non-default temperature with
// a 400 and think adaptively, so `effort` is the knob there instead.
function isLegacySamplingModel(model) {
  return /^claude-(haiku-4|sonnet-4|opus-4)/.test(model);
}

function buildRequest({ model, maxTokens, mediaType, base64, clientSide }) {
  const req = {
    model,
    max_tokens: maxTokens,
    system: buildSystemPrompt(),
    messages: [
      {
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: mediaType, data: base64 } },
          { type: 'text', text: buildUserText(clientSide) },
        ],
      },
    ],
    output_config: { format: { type: 'json_schema', schema: EXTRACTION_SCHEMA } },
  };
  if (isLegacySamplingModel(model)) {
    req.temperature = 0;
  } else {
    // Transcription has one right answer; little reasoning needed.
    req.output_config.effort = 'low';
  }
  return req;
}

// Firestore documents cap at 1 MiB; keep the audit copy well under that.
function truncate(s, max = 200000) {
  if (typeof s !== 'string') return null;
  return s.length > max ? s.slice(0, max) + '…[truncated]' : s;
}

// Returns {
//   status: 'extracted' | 'no_conversation_detected' | 'extraction_failed',
//   threadMessages: [...] (only when not failed),
//   platform, errors: [...],
//   audit: { model, requestId, stopReason, usage, rawText, apiStatus }
// }
// Never throws for model/API problems — those come back as a failed status so
// the caller can record them.
async function extractFromBytes({ anthropic, model, maxTokens, bytes, clientSide, sourceThumbnailUrl }) {
  const audit = { model };
  const failed = (errors, extra = {}) => ({
    status: STATUS.FAILED,
    errors,
    platform: '',
    audit: { ...audit, ...extra },
  });

  if (!bytes || !bytes.length) return failed(['image is empty']);
  if (bytes.length > MAX_IMAGE_BYTES) {
    return failed([`image is ${(bytes.length / 1048576).toFixed(1)} MB; the limit is 7 MB`]);
  }
  const mediaType = detectImageMediaType(bytes);
  if (!mediaType) {
    return failed([
      looksLikeHeic(bytes)
        ? 'image is HEIC; upload a PNG or JPEG screenshot instead'
        : 'unsupported image type; upload a PNG, JPEG, WebP or GIF',
    ]);
  }

  let response;
  try {
    const out = await ai.call('extraction', buildRequest({ model, maxTokens, mediaType, base64: bytes.toString('base64'), clientSide }), { client: anthropic });
    response = out.response;
    Object.assign(audit, { ai: out.meta, promptId: out.meta.promptId, promptVersion: out.meta.promptVersion, provider: out.meta.provider });
  } catch (e) {
    const msg = e && e.message ? e.message : String(e);
    return failed([`Claude API error: ${msg}`], { apiStatus: e && e.status ? e.status : null, ...(e && e.aiMeta ? { ai: e.aiMeta } : {}) });
  }

  Object.assign(audit, {
    requestId: response._request_id || response.id || null,
    stopReason: response.stop_reason || null,
    usage: response.usage
      ? { inputTokens: response.usage.input_tokens || 0, outputTokens: response.usage.output_tokens || 0 }
      : null,
  });

  const parsed = parseModelResponse(response);
  if (!parsed.ok) return failed(parsed.errors, { rawText: truncate(parsed.rawText) });
  audit.rawText = truncate(parsed.rawText);

  const checked = validateExtraction(parsed.parsed);
  if (!checked.ok) return failed(checked.errors);

  const v = checked.value;
  return {
    status: v.containsConversation ? STATUS.EXTRACTED : STATUS.NO_CONVERSATION,
    threadMessages: toThreadMessages(v, { sourceThumbnailUrl: sourceThumbnailUrl || '' }),
    platform: v.platform,
    errors: [],
    audit,
  };
}

// Fields written onto the receipt for a given extraction result. Only a
// successful extraction writes threadMessages — a failure never leaves
// partial or malformed messages behind.
function resultFields(result, base) {
  const fields = {
    ...base,
    extractionState: result.status,
    extractionErrors: result.errors,
    // Drives the existing Processed / Uncertain status tag on the Receipts tab.
    classificationLabel: result.status === STATUS.EXTRACTED ? 'Processed' : 'Uncertain',
  };
  if (result.status !== STATUS.FAILED) {
    fields.threadMessages = result.threadMessages;
    fields.detectedPlatform = result.platform;
  }
  return fields;
}

function createExtractor({ db, bucket, anthropic, model, maxTokens, serverTimestamp, allowedCollections, log }) {
  const logger = log || { info() {}, warn() {}, error() {} };

  // Throws InputError for caller mistakes (bad args, missing doc/file);
  // returns { status, ... } for everything that reached the model.
  async function run({ uid, collection, docId, storagePath, imageUrl, clientSide }) {
    if (!allowedCollections.includes(collection)) {
      throw new InputError(`collection must be one of: ${allowedCollections.join(', ')}`);
    }
    if (typeof docId !== 'string' || !docId || docId.includes('/')) {
      throw new InputError('docId is required');
    }
    // Accept either a raw storage path or the download URL FlutterFlow's
    // upload action returns; a URL must point at this project's own bucket.
    if (!storagePath && typeof imageUrl === 'string') {
      storagePath = storagePathFromDownloadUrl(imageUrl, bucket.name);
      if (!storagePath) throw new InputError('imageUrl must be a Firebase Storage URL from this project');
    }

    const docRef = db.collection(collection).doc(docId);
    const snap = await docRef.get();
    if (!snap.exists) throw new InputError(`${collection}/${docId} not found`);

    // A receipt created by ingestScreenshot remembers where its image lives,
    // so "retry extraction" only needs the document id.
    if (!storagePath && typeof snap.get === 'function') {
      storagePath = snap.get('sourceStoragePath') || null;
      if (!imageUrl) imageUrl = snap.get('sourceUrl') || undefined;
    }
    if (typeof storagePath !== 'string' || !storagePath || storagePath.includes('..') || storagePath.startsWith('/')) {
      throw new InputError('storagePath or imageUrl is required');
    }

    const file = bucket.file(storagePath);
    const [exists] = await file.exists();
    if (!exists) throw new InputError(`no file at ${storagePath}`);
    const [bytes] = await file.download();
    const sourceSha256 = crypto.createHash('sha256').update(bytes).digest('hex');

    const result = await extractFromBytes({
      anthropic,
      model,
      maxTokens,
      bytes,
      clientSide,
      sourceThumbnailUrl: typeof imageUrl === 'string' ? imageUrl : '',
    });

    const batch = db.batch();
    batch.set(
      docRef,
      resultFields(result, {
        extractionModel: model,
        extractionSourcePath: storagePath,
        extractionSourceSha256: sourceSha256,
        extractedAt: serverTimestamp(),
      }),
      { merge: true },
    );
    batch.set(docRef.collection('extractionRuns').doc(), {
      ...result.audit,
      uid: uid || null,
      storagePath,
      sourceSha256,
      status: result.status,
      errors: result.errors,
      messageCount: result.threadMessages ? result.threadMessages.length : 0,
      createdAt: serverTimestamp(),
    });
    await batch.commit();

    if (result.status === STATUS.FAILED) logger.warn('extraction failed', { collection, docId, errors: result.errors });
    return {
      status: result.status,
      messageCount: result.threadMessages ? result.threadMessages.length : 0,
      platform: result.platform,
      errors: result.errors,
    };
  }

  return { run };
}

class InputError extends Error {}

module.exports = {
  createExtractor,
  extractFromBytes,
  resultFields,
  buildRequest,
  isLegacySamplingModel,
  truncate,
  InputError,
  STATUS,
  MAX_IMAGE_BYTES,
};
