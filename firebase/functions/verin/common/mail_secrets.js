// Outbound email key. Firebase registers every defineSecret it sees and, on
// deploy, insists the secret exists — so EMAIL_API_KEY is only defined once
// EMAIL_ENABLED=true is in functions/.env (and the secret has been created).
//   EMAIL_API_KEY   Postmark server token or SendGrid API key
const { defineSecret } = require('firebase-functions/params');

const emailEnabled = () => process.env.EMAIL_ENABLED === 'true';
const EMAIL_API_KEY = emailEnabled() ? defineSecret('EMAIL_API_KEY') : null;

/// The key, inside a function that lists emailSecrets().
function emailApiKey() {
  if (!EMAIL_API_KEY) return '';
  try {
    return String(EMAIL_API_KEY.value() || '').trim();
  } catch (_) {
    return String(process.env.EMAIL_API_KEY || '').trim();
  }
}

module.exports = { emailEnabled, emailApiKey, emailSecrets: () => (EMAIL_API_KEY ? [EMAIL_API_KEY] : []) };
