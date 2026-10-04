// Verin Legal — screenshot -> threadMessages extraction: prompt + output schema.
//
// The model is asked for a small, strict JSON object. Fields the model can't
// know (sourceThumbnailUrl) or that are the same for every message (platform)
// are filled in server-side after validation, so the shape written to
// Firestore still matches the ThreadMessages data type (guide §1g):
//   speaker, text, timestampLabel, isGap, confidence,
//   sourceThumbnailUrl, platform, isHeader

const SPEAKERS = ['client', 'other'];

// JSON schema sent as output_config.format. Structured outputs don't support
// minimum/maximum, so the 0..1 range on confidence is enforced in validate.js.
const EXTRACTION_SCHEMA = {
  type: 'object',
  properties: {
    containsConversation: {
      type: 'boolean',
      description:
        'true if the image shows a message thread (SMS, iMessage, WhatsApp, email, etc.), false otherwise.',
    },
    platform: {
      type: 'string',
      description:
        'Messaging app shown, e.g. "iMessage", "SMS", "WhatsApp", "Facebook Messenger", "Email", or "Unknown".',
    },
    messages: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          speaker: { type: 'string', enum: SPEAKERS },
          text: { type: 'string' },
          timestampLabel: { type: 'string' },
          isGap: { type: 'boolean' },
          confidence: {
            type: 'number',
            description: 'How sure you are this text is read correctly, from 0.0 to 1.0.',
          },
          isHeader: { type: 'boolean' },
        },
        required: ['speaker', 'text', 'timestampLabel', 'isGap', 'confidence', 'isHeader'],
        additionalProperties: false,
      },
    },
  },
  required: ['containsConversation', 'platform', 'messages'],
  additionalProperties: false,
};

function buildSystemPrompt() {
  return [
    'You extract messages from a single screenshot of a text, chat, or email conversation for a legal evidence record.',
    'Accuracy matters more than completeness. Never invent, paraphrase, correct, or summarize text.',
    '',
    'Rules:',
    '- Return one entry per visible message bubble, in top-to-bottom order exactly as shown.',
    '- text: the message text verbatim, including typos, emoji, and punctuation. For a photo/attachment bubble with no text, use "[attachment]".',
    '- speaker: "client" or "other", based on which side of the screen the bubble is on (the user message says which side belongs to the client).',
    '- timestampLabel: the time/date text shown for that message or the nearest timestamp divider above it, copied as displayed (e.g. "2:14 PM", "Yesterday 9:03 AM"). Use "" if none is visible. Do not compute or guess dates.',
    '- isHeader: true only for date/time divider rows or system lines (e.g. "Today 2:14 PM", "Messages and calls are end-to-end encrypted"); for those, speaker is "other" and text is the divider text.',
    '- isGap: true on the first message after a visible break in the conversation: a jump of a day or more in the timestamps, or text that is cut off at the top/bottom edge of the screenshot. Otherwise false.',
    '- confidence: 0.0 to 1.0 for how sure you are the text was read correctly. Use lower values for blurry, cropped, or partially covered text. Do not default everything to 1.0.',
    '- If part of a message is unreadable, transcribe what you can and put "[illegible]" where text cannot be read, with a lower confidence.',
    '- Ignore app chrome: the keyboard, input box, status bar, buttons, contact name header, and read receipts are not messages.',
    '- containsConversation: false if the image is not a conversation at all; then return an empty messages array.',
  ].join('\n');
}

function buildUserText(clientSide) {
  const side = clientSide === 'left' ? 'left' : 'right';
  const otherSide = side === 'right' ? 'left' : 'right';
  return (
    `Messages on the ${side} side of the screen were sent by the client; ` +
    `messages on the ${otherSide} side are from the other party. ` +
    'Extract the conversation from this screenshot.'
  );
}

module.exports = { SPEAKERS, EXTRACTION_SCHEMA, buildSystemPrompt, buildUserText };
