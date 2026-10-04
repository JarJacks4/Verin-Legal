// Verin Legal — every secret and setting the Verin functions read, in one place.
//
// Secrets (set once; never in the repo or the app):
//   firebase functions:secrets:set ANTHROPIC_API_KEY
//   firebase functions:secrets:set CLIO_CLIENT_SECRET
//   firebase functions:secrets:set TOKEN_ENCRYPTION_KEY    # openssl rand -base64 32
//
// Settings go in firebase/functions/.env (see .env.example next to this repo's
// functions/ folder). Each has a sensible default except the Clio ones.

const { defineSecret, defineString, defineInt } = require('firebase-functions/params');

module.exports = {
  ANTHROPIC_API_KEY: defineSecret('ANTHROPIC_API_KEY'),
  CLIO_CLIENT_SECRET: defineSecret('CLIO_CLIENT_SECRET'),
  TOKEN_ENCRYPTION_KEY: defineSecret('TOKEN_ENCRYPTION_KEY'),

  EXTRACTION_MODEL: defineString('EXTRACTION_MODEL', { default: 'claude-sonnet-5-5' }),
  EXTRACTION_MAX_TOKENS: defineInt('EXTRACTION_MAX_TOKENS', { default: 16000 }),

  // Video / audio reading (transcripts, screen recordings) via Gemini on
  // Vertex AI, using the functions' own service account — no extra key.
  VIDEO_MODEL: defineString('VIDEO_MODEL', { default: 'gemini-3.5-flash' }),
  VERTEX_LOCATION: defineString('VERTEX_LOCATION', { default: 'global' }),

  // RFC 3161 Time-Stamp Authority. Empty TSA_URL turns timestamping off.
  TSA_URL: defineString('TSA_URL', { default: 'http://timestamp.digicert.com' }),
  TSA_NAME: defineString('TSA_NAME', { default: 'DigiCert' }),

  CLIO_CLIENT_ID: defineString('CLIO_CLIENT_ID', { default: '' }),
  CLIO_REGION: defineString('CLIO_REGION', { default: 'us' }),
  // Must exactly match a Redirect URI registered on the Clio app: the deployed
  // URL of clioOAuthCallback, e.g.
  // https://us-central1-verin-legal-fbzp5w.cloudfunctions.net/clioOAuthCallback
  CLIO_REDIRECT_URI: defineString('CLIO_REDIRECT_URI', { default: '' }),
  // Where the "Return to Verin" link on the Clio result page goes.
  APP_URL: defineString('APP_URL', { default: '' }),

  // Single-tenant fallback: the firmID every matter is filed under today.
  DEFAULT_FIRM_ID: defineString('DEFAULT_FIRM_ID', { default: 'harbow-law' }),
};
