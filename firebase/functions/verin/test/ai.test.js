const test = require('node:test');
const assert = require('node:assert');
const ai = require('../ai/models');

test('promptVersion changes with instructions, not with evidence bytes', () => {
  const base = { model: 'm', system: 'Read the screenshot.', messages: [{ role: 'user', content: [{ type: 'image', source: { data: 'AAA' } }, { type: 'text', text: 'Client is right.' }] }] };
  const otherImage = JSON.parse(JSON.stringify(base));
  otherImage.messages[0].content[0].source.data = 'BBB';
  const otherPrompt = { ...base, system: 'Read the screenshot carefully.' };
  assert.strictEqual(ai.promptVersion(base), ai.promptVersion(otherImage));
  assert.notStrictEqual(ai.promptVersion(base), ai.promptVersion(otherPrompt));
});

test('call returns meta with stage, provider, model and usage', async () => {
  const client = { messages: { create: async (r) => ({ id: 'req_1', model: r.model, usage: { input_tokens: 10, output_tokens: 3 }, content: [] }) } };
  const { meta } = await ai.call('extraction', { model: 'claude-x', system: 's', messages: [] }, { client });
  assert.strictEqual(meta.stage, 'extraction');
  assert.strictEqual(meta.provider, 'anthropic');
  assert.strictEqual(meta.model, 'claude-x');
  assert.deepStrictEqual(meta.usage, { inputTokens: 10, outputTokens: 3 });
  assert.strictEqual(meta.requestId, 'req_1');
});

test('gemini stage uses generateContent and reads usageMetadata', async () => {
  const client = { models: { generateContent: async () => ({ text: '{}', usageMetadata: { promptTokenCount: 5, candidatesTokenCount: 2 } }) } };
  const { meta } = await ai.call('video', { model: 'gemini-x', contents: [] }, { client });
  assert.strictEqual(meta.provider, 'gemini-vertex');
  assert.deepStrictEqual(meta.usage, { inputTokens: 5, outputTokens: 2 });
});

test('errors carry aiMeta and unknown stages are refused', async () => {
  const client = { messages: { create: async () => { throw Object.assign(new Error('boom'), { status: 529 }); } } };
  await assert.rejects(ai.call('analysis', { model: 'm' }, { client }), (e) => e.aiMeta && e.aiMeta.stage === 'analysis');
  await assert.rejects(ai.call('nope', {}, { client }), /Unknown AI stage/);
});
