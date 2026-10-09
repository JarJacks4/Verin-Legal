// Secrets for practice systems beyond Clio. Firebase insists every declared
// secret exists at deploy time, so each one is declared only after its
// switch is on in functions/.env:
//   PRACTICEPANTHER_ENABLED=true → secret PRACTICEPANTHER_CLIENT_SECRET
//   FILEVINE_ENABLED=true + FILEVINE_PARTNER=true → secret FILEVINE_CLIENT_SECRET
//     (without FILEVINE_PARTNER each firm enters its own client id/secret)
const { defineSecret } = require('firebase-functions/params');

const on = (k) => process.env[k] === 'true';
const PP_SECRET = on('PRACTICEPANTHER_ENABLED') ? defineSecret('PRACTICEPANTHER_CLIENT_SECRET') : null;
const FV_SECRET = on('FILEVINE_ENABLED') && on('FILEVINE_PARTNER') ? defineSecret('FILEVINE_CLIENT_SECRET') : null;

const read = (s, envName) => {
  if (!s) return '';
  try {
    return String(s.value() || '').trim();
  } catch (_) {
    return String(process.env[envName] || '').trim();
  }
};

module.exports = {
  practicePantherEnabled: () => on('PRACTICEPANTHER_ENABLED'),
  filevineEnabled: () => on('FILEVINE_ENABLED'),
  filevinePartner: () => on('FILEVINE_PARTNER') && !!FV_SECRET,
  ppClientSecret: () => read(PP_SECRET, 'PRACTICEPANTHER_CLIENT_SECRET'),
  fvPartnerSecret: () => read(FV_SECRET, 'FILEVINE_CLIENT_SECRET'),
  practiceSecrets: () => [PP_SECRET, FV_SECRET].filter(Boolean),
};
