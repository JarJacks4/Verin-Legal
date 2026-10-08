// Verin AI — the one door every model call goes through (checklist #76).
//
// Each pipeline stage (extraction, analysis, video, summary, …) names its
// provider here. Swapping a stage to another model — including Verin's own
// model later — means changing this file, not the pipeline.
//
// Every call returns `meta`, written onto the entry it produced:
//   { stage, provider, model, promptId, promptVersion, requestId, usage, at }
// promptVersion is a short fingerprint of the instructions sent (system
// prompt, tools and output schema), so a changed prompt is visible on every
// entry it touched without anyone remembering to bump a number.

const crypto = require('crypto');

const STAGES = {
  extraction: { provider: 'anthropic', promptId: 'thread-extraction' },
  analysis: { provider: 'anthropic', promptId: 'evidence-analysis' },
  summary: { provider: 'anthropic', promptId: 'cited-summary' },
  video: { provider: 'gemini-vertex', promptId: 'video-transcript' },
};

function stageInfo(stage) {
  const s = STAGES[stage];
  if (!s) throw new Error(`Unknown AI stage: ${stage}`);
  return s;
}

/// Fingerprint of the instructions in a request (not the evidence itself).
function promptVersion(request) {
  const r = request || {};
  const instructions = {
    system: r.system || (r.config && r.config.systemInstruction) || null,
    tools: r.tools || null,
    tool_choice: r.tool_choice || null,
    output: r.output_config || r.response_format || (r.config && r.config.responseSchema) || null,
    // Text parts of the user turn that are instructions, not evidence.
    text: instructionText(r),
  };
  return crypto.createHash('sha256').update(JSON.stringify(instructions)).digest('hex').slice(0, 12);
}

function instructionText(r) {
  const out = [];
  const msgs = Array.isArray(r.messages) ? r.messages : [];
  for (const m of msgs) {
    if (m && m.role === 'user' && Array.isArray(m.content)) {
      for (const c of m.content) if (c && c.type === 'text' && typeof c.text === 'string' && c.text.length < 4000) out.push(c.text);
    }
  }
  if (Array.isArray(r.contents)) {
    for (const m of r.contents) {
      for (const p of (m && m.parts) || []) if (p && typeof p.text === 'string' && p.text.length < 4000) out.push(p.text);
    }
  }
  return out;
}

function usageOf(provider, res) {
  if (!res) return null;
  if (provider === 'anthropic' && res.usage) {
    return { inputTokens: res.usage.input_tokens || 0, outputTokens: res.usage.output_tokens || 0 };
  }
  if (provider === 'gemini-vertex' && res.usageMetadata) {
    const u = res.usageMetadata;
    return { inputTokens: u.promptTokenCount || 0, outputTokens: u.candidatesTokenCount || 0 };
  }
  return null;
}

function metaFor(stage, request, res, model) {
  const s = stageInfo(stage);
  return {
    stage,
    provider: s.provider,
    model: (res && res.model) || model || (request && request.model) || '',
    promptId: s.promptId,
    promptVersion: promptVersion(request),
    requestId: (res && (res._request_id || res.id || res.responseId)) || null,
    usage: usageOf(s.provider, res),
    at: new Date().toISOString(),
  };
}

/**
 * Runs one model call for a stage.
 *   anthropic stages: client = Anthropic SDK client, request = messages.create body
 *   gemini stages:    client = GoogleGenAI client,   request = generateContent body
 * Returns { response, meta }. Throws what the provider throws (callers keep
 * their own error handling), with `err.aiMeta` attached.
 */
async function call(stage, request, { client }) {
  const s = stageInfo(stage);
  try {
    let response;
    if (s.provider === 'anthropic') response = await client.messages.create(request);
    else if (s.provider === 'gemini-vertex') response = await client.models.generateContent(request);
    else throw new Error(`No adapter for provider ${s.provider}`);
    return { response, meta: metaFor(stage, request, response, request && request.model) };
  } catch (e) {
    if (e && typeof e === 'object') e.aiMeta = metaFor(stage, request, null, request && request.model);
    throw e;
  }
}

module.exports = { STAGES, call, promptVersion, metaFor, usageOf };
