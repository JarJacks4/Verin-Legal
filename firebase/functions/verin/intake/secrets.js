// Intake secrets, kept out of common/params.js: Firebase checks every defined
// secret at deploy time, and these exist only once intake is set up.
//   INBOUND_WEBHOOK_KEY  long random string; part of the inbound-email URL
//   TWILIO_AUTH_TOKEN    verifies Twilio's signature and fetches photos
const { defineSecret } = require('firebase-functions/params');

module.exports = {
  INBOUND_WEBHOOK_KEY: defineSecret('INBOUND_WEBHOOK_KEY'),
  TWILIO_AUTH_TOKEN: defineSecret('TWILIO_AUTH_TOKEN'),
};
