// Verin Legal — video and audio intake (Video Intake spec v1.0 §2–5, §8).
//
//   probe       ffprobe over the stored copy: container, codecs, duration,
//               resolution, audio presence, every metadata tag. Whole output
//               is kept — it is what an examiner will ask for.
//   dating      container creation_time is used only when the item is not
//               transcoded in transit; on-screen dates in screen recordings
//               come from the model.
//   transcribe  Gemini on Vertex AI reads the video from Cloud Storage
//               directly: speaker-separated transcript timestamped to the
//               second, screen-recording detection, and the messages shown in
//               a screen recording (routed to thread reconstruction).
//               Items over the automatic threshold (10 min) are deferred.

const { execFile } = require('child_process');
const { promisify } = require('util');

const { validateExtraction, toThreadMessages } = require('../extraction/validate');
const { messageSource } = require('./source');

const execFileP = promisify(execFile);

const AUTO_TRANSCRIBE_MAX_SECONDS = 10 * 60;

function ffprobePath() {
  try {
    const p = require('ffprobe-static');
    return p.path || p;
  } catch (_) {
    return 'ffprobe';
  }
}

/// Runs ffprobe on a URL (the stored copy's tokenized download URL).
async function probeMedia(url, { exec = execFileP, bin = ffprobePath() } = {}) {
  try {
    const { stdout } = await exec(bin, ['-v', 'error', '-print_format', 'json', '-show_format', '-show_streams', url], {
      timeout: 90000,
      maxBuffer: 8 * 1024 * 1024,
    });
    return summarizeProbe(JSON.parse(stdout));
  } catch (e) {
    return { ok: false, error: `ffprobe failed: ${e.message ? e.message.split('\n')[0] : e}` };
  }
}

function summarizeProbe(raw) {
  const streams = Array.isArray(raw.streams) ? raw.streams : [];
  const fmt = raw.format || {};
  const video = streams.find((s) => s.codec_type === 'video' && !(s.disposition && s.disposition.attached_pic));
  const audio = streams.find((s) => s.codec_type === 'audio');
  const tags = { ...(fmt.tags || {}), ...((video && video.tags) || {}) };
  const durationSec = Number(fmt.duration || (video && video.duration) || (audio && audio.duration) || 0);
  const created = tags.creation_time || tags['com.apple.quicktime.creationdate'] || '';
  let fps = null;
  if (video && typeof video.r_frame_rate === 'string' && video.r_frame_rate.includes('/')) {
    const [a, b] = video.r_frame_rate.split('/').map(Number);
    if (b) fps = Math.round((a / b) * 100) / 100;
  }
  return {
    ok: true,
    durationSeconds: Number.isFinite(durationSec) ? Math.round(durationSec) : 0,
    hasVideo: !!video,
    hasAudio: !!audio,
    container: fmt.format_name || '',
    videoCodec: video ? video.codec_name || '' : '',
    audioCodec: audio ? audio.codec_name || '' : '',
    width: video ? video.width || null : null,
    height: video ? video.height || null : null,
    fps,
    creationTime: created,
    gps: tags.location || tags['com.apple.quicktime.location.ISO6709'] || '',
    make: tags['com.apple.quicktime.make'] || tags.make || '',
    model: tags['com.apple.quicktime.model'] || tags.model || '',
    raw,
  };
}

const VIDEO_SCHEMA = {
  type: 'OBJECT',
  properties: {
    isScreenRecording: { type: 'BOOLEAN', description: 'True if this is a recording of a phone or computer screen.' },
    hasSpeech: { type: 'BOOLEAN' },
    summary: { type: 'STRING', description: 'One to three neutral sentences describing what the recording shows.' },
    onScreenDate: { type: 'STRING', description: 'YYYY-MM-DD of a full date clearly visible on screen, else "".' },
    transcript: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          startSeconds: { type: 'INTEGER' },
          speaker: { type: 'STRING', description: 'Speaker 1, Speaker 2, … (or a name only if clearly stated in the audio).' },
          text: { type: 'STRING' },
        },
        required: ['startSeconds', 'speaker', 'text'],
      },
    },
    platform: { type: 'STRING' },
    messages: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          speaker: { type: 'STRING', enum: ['client', 'other'] },
          text: { type: 'STRING' },
          timestampLabel: { type: 'STRING' },
          isGap: { type: 'BOOLEAN' },
          confidence: { type: 'NUMBER' },
          isHeader: { type: 'BOOLEAN' },
          senderName: { type: 'STRING', description: 'Sender name or number shown with the message, as displayed; "" if none.' },
          atSeconds: { type: 'INTEGER', description: 'Seconds from the start of the video where the message is first fully visible.' },
        },
        required: ['speaker', 'text', 'timestampLabel', 'isGap', 'confidence', 'isHeader', 'senderName', 'atSeconds'],
      },
    },
  },
  required: ['isScreenRecording', 'hasSpeech', 'summary', 'onScreenDate', 'transcript', 'platform', 'messages'],
};

function videoPrompt({ clientSide, hasAudio }) {
  const side = clientSide === 'left' ? 'left' : 'right';
  return [
    'You read one video or audio file for a family-law firm\'s evidence record. You describe and transcribe; you never judge.',
    '- summary: one to three neutral sentences on what the recording shows. Never say it is authentic, original, unaltered, edited, fake or AI-generated.',
    hasAudio
      ? '- transcript: every spoken line, speaker-separated ("Speaker 1", "Speaker 2"…), with startSeconds from the start of the file. Verbatim; mark unclear words [inaudible]. Empty if nobody speaks.'
      : '- The file has no audio track: transcript must be empty and hasSpeech false.',
    '- isScreenRecording: true if this is a recording of a phone or computer screen.',
    `- If it is a screen recording of a message thread: list each distinct message once, top to bottom in conversation order, even if it appears in many frames. Messages on the ${side} side were sent by the client ("client"); the other side is "other". Copy text verbatim, timestampLabel as displayed or "", isHeader for date dividers, isGap where the scroll skipped part of the conversation, confidence 0..1, senderName as displayed (or ""), and atSeconds where the message is first fully on screen. Otherwise messages is empty and platform "".`,
    '- onScreenDate: only a full date clearly visible on screen, as YYYY-MM-DD; otherwise "".',
  ].join('\n');
}

let cachedGenAI = null;
function genAIClient(project, location) {
  if (!cachedGenAI) {
    const { GoogleGenAI } = require('@google/genai');
    cachedGenAI = new GoogleGenAI({ vertexai: true, project, location });
  }
  return cachedGenAI;
}

const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

function validateVideoResult(parsed, { sourceUrl }) {
  if (!parsed || typeof parsed !== 'object') return { ok: false, errors: ['response is not a JSON object'] };
  const errors = [];
  const transcript = Array.isArray(parsed.transcript)
    ? parsed.transcript
        .filter((t) => t && typeof t.text === 'string' && t.text.trim())
        .map((t) => ({ startSeconds: Number.isFinite(t.startSeconds) ? Math.max(0, Math.round(t.startSeconds)) : 0, speaker: String(t.speaker || 'Speaker'), text: t.text }))
    : [];
  let onScreenDate = null;
  if (typeof parsed.onScreenDate === 'string' && ISO_DATE.test(parsed.onScreenDate.trim())) {
    const [, y, m, d] = ISO_DATE.exec(parsed.onScreenDate.trim());
    const dt = new Date(Date.UTC(+y, +m - 1, +d, 12));
    if (dt.getUTCMonth() === +m - 1 && dt.getTime() <= Date.now() + 86400000) onScreenDate = dt;
  }
  let threadMessages = [];
  let platform = '';
  const isScreen = parsed.isScreenRecording === true;
  if (isScreen && Array.isArray(parsed.messages) && parsed.messages.length) {
    const conv = validateExtraction({ containsConversation: true, platform: String(parsed.platform || ''), messages: parsed.messages });
    if (conv.ok) {
      threadMessages = toThreadMessages(conv.value, { sourceThumbnailUrl: sourceUrl || '' }).map((m, i) => ({
        ...m,
        ...messageSource(parsed.messages[i]),
      }));
      platform = conv.value.platform;
    } else {
      errors.push(...conv.errors.map((e) => `screen recording messages: ${e}`));
    }
  }
  if (errors.length) return { ok: false, errors };
  return {
    ok: true,
    value: {
      isScreenRecording: isScreen,
      hasSpeech: parsed.hasSpeech === true && transcript.length > 0,
      summary: typeof parsed.summary === 'string' ? parsed.summary.trim() : '',
      onScreenDate,
      transcript,
      threadMessages,
      platform,
    },
  };
}

/// Gemini over gs://bucket/path. Never throws. Returns { ok, value, audit } | { ok:false, errors, audit }.
async function analyzeVideo({ project, location, model, gcsUri, mimeType, clientSide, hasAudio, sourceUrl, client }) {
  const audit = { model, engine: 'gemini-vertex' };
  let res;
  try {
    const ai = client || genAIClient(project, location);
    res = await ai.models.generateContent({
      model,
      contents: [{ role: 'user', parts: [{ fileData: { fileUri: gcsUri, mimeType } }, { text: videoPrompt({ clientSide, hasAudio }) }] }],
      config: { responseMimeType: 'application/json', responseSchema: VIDEO_SCHEMA, temperature: 0 },
    });
  } catch (e) {
    const msg = e && e.message ? e.message : String(e);
    const hint = /PERMISSION_DENIED|has not been used|disabled|SERVICE_DISABLED/i.test(msg)
      ? ' — enable the Vertex AI API (aiplatform.googleapis.com) for this project'
      : '';
    return { ok: false, errors: [`Video model error: ${msg.slice(0, 300)}${hint}`], audit };
  }
  const text = typeof res.text === 'string' ? res.text : '';
  audit.rawText = text.length > 200000 ? text.slice(0, 200000) : text;
  if (res.usageMetadata) audit.usage = { inputTokens: res.usageMetadata.promptTokenCount || 0, outputTokens: res.usageMetadata.candidatesTokenCount || 0 };
  let parsed;
  try {
    parsed = JSON.parse(text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, ''));
  } catch (e) {
    return { ok: false, errors: [`video model returned invalid JSON: ${e.message}`], audit };
  }
  const v = validateVideoResult(parsed, { sourceUrl });
  return v.ok ? { ok: true, value: v.value, audit } : { ok: false, errors: v.errors, audit };
}

/// origin_fidelity for a video by the channel it came through (spec §2).
function originFidelityFor(channel) {
  const c = String(channel || '').toLowerCase();
  if (c === 'sms' || c === 'whatsapp' || c === 'mms' || c === 'rcs') return 'transcoded_in_transit';
  return 'undetermined';
}

/// Capture date from container metadata — only when the file was not
/// transcoded in transit (a transcode rewrites creation_time).
function containerDate(probe, fidelity, receivedAt) {
  if (!probe || !probe.ok || !probe.creationTime) return null;
  if (fidelity === 'transcoded_in_transit') return null;
  const d = new Date(probe.creationTime);
  if (Number.isNaN(d.getTime())) return null;
  if (d.getUTCFullYear() < 2000) return null; // 1904/1970 epochs mean "unset"
  if (receivedAt && d.getTime() > new Date(receivedAt).getTime()) return null;
  return d;
}

module.exports = {
  AUTO_TRANSCRIBE_MAX_SECONDS,
  VIDEO_SCHEMA,
  probeMedia,
  summarizeProbe,
  videoPrompt,
  validateVideoResult,
  analyzeVideo,
  originFidelityFor,
  containerDate,
};
