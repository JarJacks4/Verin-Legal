// Verin Legal — AI reading of one evidence item with Claude (images, PDFs,
// extracted document / email text). One request returns a neutral summary,
// the evidence date with its source and confidence, and — when the item shows
// a conversation — every message verbatim for thread reconstruction.
//
// The model is never asked whether anything is authentic, original or
// unaltered, and the summary instructions forbid those conclusions
// (Video Intake spec §8 applies product-wide).

const { SPEAKERS } = require('../extraction/schema');
const ai = require('../ai/models');
const { validateExtraction, toThreadMessages, parseModelResponse } = require('../extraction/validate');
const { isLegacySamplingModel, truncate } = require('../extraction/extractor');
const { BOX_SCHEMA, STATEMENT_SCHEMA, SENSITIVE_SCHEMA, messageSource, cleanStatements, cleanSensitive } = require('./source');

const CONFIDENCE = ['high', 'medium', 'low', 'none'];
const EVIDENCE_TYPES = ['conversation', 'photo', 'document', 'email', 'other'];

const MESSAGE_SCHEMA = {
  type: 'object',
  properties: {
    speaker: { type: 'string', enum: SPEAKERS },
    text: { type: 'string' },
    timestampLabel: { type: 'string' },
    isGap: { type: 'boolean' },
    confidence: { type: 'number', description: 'How sure you are this text is read correctly, from 0.0 to 1.0.' },
    isHeader: { type: 'boolean' },
    senderName: { type: 'string', description: 'The sender name or number shown with this message (bubble label, contact header, email From), copied as displayed; "" if none is shown.' },
    page: { type: 'integer', description: '1-based PDF page the message is on; 0 otherwise.' },
    box: BOX_SCHEMA,
  },
  required: ['speaker', 'text', 'timestampLabel', 'isGap', 'confidence', 'isHeader', 'senderName', 'page', 'box'],
  additionalProperties: false,
};

const ANALYSIS_SCHEMA = {
  type: 'object',
  properties: {
    evidenceType: { type: 'string', enum: EVIDENCE_TYPES },
    summary: { type: 'string', description: 'One to three plain sentences describing what the item shows or says.' },
    eventDate: { type: 'string', description: 'YYYY-MM-DD of the event the item records, or "" if not established.' },
    eventDateSource: { type: 'string', description: 'Where the date came from, e.g. "on-screen timestamp", "email Date header", "document date line".' },
    eventDateConfidence: { type: 'string', enum: CONFIDENCE },
    containsConversation: { type: 'boolean' },
    platform: { type: 'string' },
    messages: { type: 'array', items: MESSAGE_SCHEMA },
    statements: { type: 'array', items: STATEMENT_SCHEMA },
    sensitive: { type: 'array', items: SENSITIVE_SCHEMA },
  },
  required: ['evidenceType', 'summary', 'eventDate', 'eventDateSource', 'eventDateConfidence', 'containsConversation', 'platform', 'messages', 'statements', 'sensitive'],
  additionalProperties: false,
};

function systemPrompt() {
  return [
    'You read one item of evidence for a family-law firm\'s evidence record. You describe and transcribe; you never judge.',
    '',
    'Summary rules:',
    '- One to three neutral sentences: what the item is and what it shows or says. Name people only as they are named in the item.',
    '- Never state or imply that anything is authentic, genuine, original, unaltered, edited, fake, AI-generated, admissible, or true. Never give a legal opinion.',
    '- Do not speculate about intent, emotion, or what happened outside the item.',
    '',
    'Date rules:',
    '- eventDate is the date of the event the item records (a message\'s visible date, an email\'s Date header, a dated letter, a date printed in a photo). Use YYYY-MM-DD.',
    '- Only use a date that is visible in the item. Never infer a year that is not shown. If no full date is visible, return "" and confidence "none".',
    '- eventDateConfidence: high = full date clearly visible; medium = date visible but partly obscured or ambiguous format; low = only partial evidence (e.g. weekday only plus context); none = no date.',
    '',
    'Conversation rules (only when the item shows a text, chat or email thread):',
    '- containsConversation true; return one entry per visible message in top-to-bottom order.',
    '- text: verbatim, including typos and emoji. Attachments with no text: "[attachment]". Unreadable parts: "[illegible]" with lower confidence.',
    '- speaker: "client" or "other" by which side of the screen the bubble is on (the user message says which side is the client). For an email thread, the client is the sender named as the client in the user message if given, otherwise use "other" for everyone but the account owner.',
    '- timestampLabel: the time/date text shown for that message or the nearest divider above it, copied as displayed; "" if none.',
    '- isHeader: true only for date dividers and system lines. isGap: true on the first message after a visible break or cut-off text.',
    '- confidence: 0.0 to 1.0 per message; do not default everything to 1.0.',
    '- senderName: the name or number displayed for that message\'s sender (a group-chat label, the contact name in the header, an email From) exactly as shown; "" when none is visible. Never invent or normalize a name.',
    '- If the item is not a conversation: containsConversation false, platform "", messages [].',
    '',
    'Location rules (so a reviewer can check each line against the original):',
    '- box: for images, the rectangle around that message bubble or passage as fractions of the image (x, y = top-left corner; w, h = width and height; all between 0 and 1). Use all zeros when the item is not an image or you cannot place it.',
    '- page: for PDFs, the 1-based page the text is on; 0 for anything else.',
    '',
    'Statements (documents, letters, emails, forms, photos with text — not message threads):',
    '- statements: up to 25 passages that state a fact a lawyer would need to check: dates, amounts, names, places, and events. Copy each passage verbatim (a sentence or line, not a paraphrase), with kind, page and box.',
    '- For a message thread, statements is [] (the messages already cover it).',
    '',
    'Sensitive details (suggestions for a person to review before anything is filed; never a judgment):',
    '- sensitive: every visible Social Security number (ssn), taxpayer ID (tax_id), financial account or card number (account), full birth date (birth_date), name of a child under 18 when the item makes that clear (minor_name), home street address (address), phone number (phone) and email address (email). Copy each exactly as shown, with page and box. [] if none.',
  ].join('\n');
}

function userText({ clientSide, kind, fileName, extra, clientName }) {
  const side = clientSide === 'left' ? 'left' : 'right';
  const other = side === 'right' ? 'left' : 'right';
  return [
    `Item kind as filed: ${kind || 'unknown'}${fileName ? ` (file name: ${fileName})` : ''}.`,
    `In message screenshots, messages on the ${side} side were sent by the client; messages on the ${other} side are from the other party.`,
    clientName ? `The client is ${String(clientName).replace(/[\r\n]/g, ' ').slice(0, 120)}. In emails and documents, messages sent by the client are "client"; everyone else is "other".` : '',
    extra || '',
    'Read this item.',
  ]
    .filter(Boolean)
    .join('\n');
}

/// content: Anthropic content blocks for the item (image / document / text).
function buildAnalysisRequest({ model, maxTokens, content, clientSide, kind, fileName, extra, clientName }) {
  const req = {
    model,
    max_tokens: maxTokens,
    system: systemPrompt(),
    messages: [{ role: 'user', content: [...content, { type: 'text', text: userText({ clientSide, kind, fileName, extra, clientName }) }] }],
    output_config: { format: { type: 'json_schema', schema: ANALYSIS_SCHEMA } },
  };
  if (isLegacySamplingModel(model)) req.temperature = 0;
  else req.output_config.effort = 'low';
  return req;
}

const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

/// Validates the model output. Returns { ok, value } or { ok: false, errors }.
function validateAnalysis(parsed) {
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return { ok: false, errors: ['response is not a JSON object'] };
  const errors = [];
  if (!EVIDENCE_TYPES.includes(parsed.evidenceType)) errors.push('evidenceType missing or not allowed');
  if (typeof parsed.summary !== 'string') errors.push('summary missing');
  if (typeof parsed.eventDate !== 'string') errors.push('eventDate missing');
  if (typeof parsed.eventDateSource !== 'string') errors.push('eventDateSource missing');
  const conf = typeof parsed.eventDateConfidence === 'string' ? parsed.eventDateConfidence.toLowerCase() : '';
  if (!CONFIDENCE.includes(conf)) errors.push('eventDateConfidence missing or not allowed');

  let eventDate = null;
  if (typeof parsed.eventDate === 'string' && parsed.eventDate.trim()) {
    const m = ISO_DATE.exec(parsed.eventDate.trim());
    if (!m) errors.push(`eventDate must be YYYY-MM-DD (got ${JSON.stringify(parsed.eventDate)})`);
    else {
      const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], 12));
      if (d.getUTCMonth() !== +m[2] - 1) errors.push('eventDate is not a real date');
      else if (d.getTime() > Date.now() + 86400000) errors.push('eventDate is in the future');
      else eventDate = d;
    }
  }

  const conv = validateExtraction({
    containsConversation: parsed.containsConversation,
    platform: typeof parsed.platform === 'string' ? parsed.platform : '',
    messages: parsed.messages,
  });
  // A non-conversation with an empty platform is fine; validateExtraction maps '' to Unknown.
  if (!conv.ok) errors.push(...conv.errors);
  if (errors.length) return { ok: false, errors };

  return {
    ok: true,
    value: {
      evidenceType: parsed.evidenceType,
      summary: parsed.summary.trim(),
      eventDate: conf === 'none' ? null : eventDate,
      eventDateSource: eventDate && conf !== 'none' ? parsed.eventDateSource.trim() : '',
      eventDateConfidence: eventDate ? conf : 'none',
      conversation: conv.value,
      // Where each message sits in the original, in the same order.
      messageSources: (Array.isArray(parsed.messages) ? parsed.messages : []).map(messageSource),
      ...cleanStatements(parsed.statements),
      sensitive: cleanSensitive(parsed.sensitive),
    },
  };
}

/// Calls Claude. Never throws for API/model problems. Returns
/// { ok: true, value, threadMessages, audit } or { ok: false, errors, audit }.
async function analyzeWithClaude({ anthropic, model, maxTokens, content, clientSide, kind, fileName, extra, sourceUrl, clientName }) {
  const audit = { model, engine: 'claude' };
  let response;
  try {
    const out = await ai.call('analysis', buildAnalysisRequest({ model, maxTokens, content, clientSide, kind, fileName, extra, clientName }), { client: anthropic });
    response = out.response;
    Object.assign(audit, { ai: out.meta, promptId: out.meta.promptId, promptVersion: out.meta.promptVersion, provider: out.meta.provider });
  } catch (e) {
    return { ok: false, errors: [`Claude API error: ${e && e.message ? e.message : e}`], audit: { ...audit, apiStatus: e && e.status ? e.status : null, ...(e && e.aiMeta ? { ai: e.aiMeta } : {}) } };
  }
  Object.assign(audit, {
    requestId: response._request_id || response.id || null,
    stopReason: response.stop_reason || null,
    usage: response.usage ? { inputTokens: response.usage.input_tokens || 0, outputTokens: response.usage.output_tokens || 0 } : null,
  });
  const parsed = parseModelResponse(response);
  if (!parsed.ok) return { ok: false, errors: parsed.errors, audit: { ...audit, rawText: truncate(parsed.rawText) } };
  audit.rawText = truncate(parsed.rawText);
  const checked = validateAnalysis(parsed.parsed);
  if (!checked.ok) return { ok: false, errors: checked.errors, audit };
  const v = checked.value;
  const threadMessages = v.conversation.containsConversation
    ? toThreadMessages(v.conversation, { sourceThumbnailUrl: sourceUrl || '' }).map((m, i) => ({ ...m, ...(v.messageSources[i] || {}) }))
    : [];
  return { ok: true, value: v, threadMessages, audit };
}

module.exports = {
  ANALYSIS_SCHEMA,
  CONFIDENCE,
  EVIDENCE_TYPES,
  MESSAGE_SCHEMA,
  systemPrompt,
  userText,
  buildAnalysisRequest,
  validateAnalysis,
  analyzeWithClaude,
};
