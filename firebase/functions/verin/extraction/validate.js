// Verin Legal — defensive validation of the model's extraction (guide §14e).
// Pure functions only, so they can be unit-tested without Firebase or the API.

const { SPEAKERS } = require('./schema');

const MESSAGE_FIELDS = ['speaker', 'text', 'timestampLabel', 'isGap', 'confidence', 'isHeader'];

// Anthropic accepts these four. Anything else (HEIC from an iPhone camera roll,
// PDF, etc.) is rejected up front with a clear reason instead of an API error.
function detectImageMediaType(buf) {
  if (!buf || buf.length < 12) return null;
  if (buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47) return 'image/png';
  if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'image/jpeg';
  if (buf.toString('ascii', 0, 4) === 'GIF8') return 'image/gif';
  if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WEBP') return 'image/webp';
  return null;
}

function looksLikeHeic(buf) {
  if (!buf || buf.length < 12) return false;
  const brand = buf.toString('ascii', 4, 12);
  return brand.startsWith('ftypheic') || brand.startsWith('ftypheix') || brand.startsWith('ftypmif1') || brand.startsWith('ftyphevc');
}

// Returns { ok: true, value } or { ok: false, errors: [...] }.
// Never coerces silently: a string "true" or a confidence of "85" is an error,
// because a quietly-fixed value is indistinguishable from a correct one later.
function validateExtraction(parsed) {
  const errors = [];

  if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    return { ok: false, errors: ['response is not a JSON object'] };
  }
  if (typeof parsed.containsConversation !== 'boolean') {
    errors.push('containsConversation missing or not a boolean');
  }
  if (typeof parsed.platform !== 'string') {
    errors.push('platform missing or not a string');
  }
  if (!Array.isArray(parsed.messages)) {
    errors.push('messages missing or not an array');
    return { ok: false, errors };
  }

  const messages = [];
  parsed.messages.forEach((m, i) => {
    const at = `messages[${i}]`;
    if (m === null || typeof m !== 'object' || Array.isArray(m)) {
      errors.push(`${at} is not an object`);
      return;
    }
    for (const f of MESSAGE_FIELDS) {
      if (!(f in m)) errors.push(`${at}.${f} missing`);
    }
    if (typeof m.text !== 'string') errors.push(`${at}.text not a string`);
    if (typeof m.timestampLabel !== 'string') errors.push(`${at}.timestampLabel not a string`);
    if (typeof m.isGap !== 'boolean') errors.push(`${at}.isGap not a boolean (got ${JSON.stringify(m.isGap)})`);
    if (typeof m.isHeader !== 'boolean') errors.push(`${at}.isHeader not a boolean (got ${JSON.stringify(m.isHeader)})`);
    if (typeof m.confidence !== 'number' || !Number.isFinite(m.confidence) || m.confidence < 0 || m.confidence > 1) {
      errors.push(`${at}.confidence must be a number from 0.0 to 1.0 (got ${JSON.stringify(m.confidence)})`);
    }
    // Structured outputs don't guarantee enum capitalization, so compare
    // case-insensitively. Anything outside the two values is flagged, not mapped.
    const speaker = typeof m.speaker === 'string' ? m.speaker.trim().toLowerCase() : m.speaker;
    if (!SPEAKERS.includes(speaker)) {
      errors.push(`${at}.speaker must be "client" or "other" (got ${JSON.stringify(m.speaker)})`);
    }
    messages.push({
      speaker,
      text: m.text,
      timestampLabel: m.timestampLabel,
      isGap: m.isGap,
      confidence: m.confidence,
      isHeader: m.isHeader,
    });
  });

  if (parsed.containsConversation === true && parsed.messages.length === 0) {
    errors.push('model reported a conversation but returned no messages (likely a silent failure)');
  }

  if (errors.length) return { ok: false, errors };
  return {
    ok: true,
    value: {
      containsConversation: parsed.containsConversation,
      platform: parsed.platform.trim() || 'Unknown',
      messages,
    },
  };
}

// Shape each validated message into the ThreadMessages data type (§1g).
function toThreadMessages(value, { sourceThumbnailUrl }) {
  return value.messages.map((m) => ({
    speaker: m.speaker,
    text: m.text,
    timestampLabel: m.timestampLabel,
    isGap: m.isGap,
    confidence: m.confidence,
    sourceThumbnailUrl: sourceThumbnailUrl || '',
    platform: value.platform,
    isHeader: m.isHeader,
  }));
}

// Pull the JSON text out of a Messages API response and parse it.
// Returns { ok: true, parsed } or { ok: false, errors }.
function parseModelResponse(response) {
  if (!response || !Array.isArray(response.content)) {
    return { ok: false, errors: ['empty response from model'] };
  }
  if (response.stop_reason === 'max_tokens') {
    return { ok: false, errors: ['response was cut off at max_tokens; raise EXTRACTION_MAX_TOKENS'] };
  }
  if (response.stop_reason === 'refusal') {
    return { ok: false, errors: ['model declined to process this image'] };
  }
  const text = response.content
    .filter((b) => b && b.type === 'text')
    .map((b) => b.text)
    .join('')
    .trim();
  if (!text) return { ok: false, errors: ['model returned no text'] };
  // Belt and braces: strip a stray ```json fence if one ever appears.
  const unfenced = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  try {
    return { ok: true, parsed: JSON.parse(unfenced), rawText: text };
  } catch (e) {
    return { ok: false, errors: [`response was not valid JSON: ${e.message}`], rawText: text };
  }
}

// FlutterFlow's "Upload Media to Firebase" action hands back a download URL,
// not a storage path. Turn
//   https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded path>?alt=media&token=...
// back into <path>, and refuse URLs that point at any other bucket or host.
function storagePathFromDownloadUrl(url, bucketName) {
  let u;
  try {
    u = new URL(url);
  } catch (_) {
    return null;
  }
  if (u.protocol !== 'https:') return null;
  if (u.hostname !== 'firebasestorage.googleapis.com') return null;
  const m = u.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
  if (!m) return null;
  if (bucketName && decodeURIComponent(m[1]) !== bucketName) return null;
  const path = decodeURIComponent(m[2]);
  if (!path || path.includes('..') || path.startsWith('/')) return null;
  return path;
}

module.exports = {
  storagePathFromDownloadUrl,
  MESSAGE_FIELDS,
  detectImageMediaType,
  looksLikeHeic,
  validateExtraction,
  toThreadMessages,
  parseModelResponse,
};
