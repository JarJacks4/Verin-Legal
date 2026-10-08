// Outbound email key, kept apart so the rest of Verin deploys before it exists
// (Firebase checks every defined secret at deploy time). Functions that send
// email list it only when EMAIL_ENABLED=true in functions/.env.
//   EMAIL_API_KEY   Postmark server token or SendGrid API key
const { defineSecret } = require('firebase-functions/params');

const EMAIL_API_KEY = defineSecret('EMAIL_API_KEY');
const emailEnabled = () => process.env.EMAIL_ENABLED === 'true';

module.exports = { EMAIL_API_KEY, emailEnabled, emailSecrets: () => (emailEnabled() ? [EMAIL_API_KEY] : []) };
