// One place that builds the Anthropic client for every Verin function.
//
// Keys created at the organization level (not inside a workspace) must name a
// workspace on every request. Set ANTHROPIC_WORKSPACE_ID in .env to send the
// anthropic-workspace-id header; leave it empty for workspace-scoped keys.

const P = require('./params');

const clients = new Map();

function anthropicClient({ timeout = 300000 } = {}) {
  if (!clients.has(timeout)) {
    const mod = require('@anthropic-ai/sdk');
    const Anthropic = mod.default || mod;
    const workspace = (P.ANTHROPIC_WORKSPACE_ID.value() || '').trim();
    clients.set(
      timeout,
      new Anthropic({
        apiKey: P.ANTHROPIC_API_KEY.value().trim(),
        maxRetries: 2,
        timeout,
        ...(workspace ? { defaultHeaders: { 'anthropic-workspace-id': workspace } } : {}),
      }),
    );
  }
  return clients.get(timeout);
}

module.exports = { anthropicClient };
