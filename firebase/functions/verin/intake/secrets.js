// Intake secrets, kept out of common/params.js: Firebase checks every defined
// secret at deploy time, and these exist only once intake is set up.
//   INBOUND_WEBHOOK_KEY  long random string; part of the inbound-email URL
//   TELNYX_API_KEY       bearer token for the Messaging API: fetches MMS
//                        photos and sends the optional auto-reply
const { defineSecret } = require('firebase-functions/params');

module.exports = {
  INBOUND_WEBHOOK_KEY: defineSecret('INBOUND_WEBHOOK_KEY'),
  TELNYX_API_KEY: defineSecret('TELNYX_API_KEY'),
};
