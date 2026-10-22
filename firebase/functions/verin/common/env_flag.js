// Reads an on/off setting that decides which functions exist at all
// (INTAKE_ENABLED, EMAIL_ENABLED, PRACTICEPANTHER_ENABLED …).
//
// Those switches are read while index.js loads. In the cloud, Firebase has
// already put the .env values into process.env by then. But when
// `firebase deploy` loads index.js on your machine to find out which
// functions exist, process.env does not reliably hold them, so a switch set to
// "true" in .env read as off and those functions were silently left out of the
// deploy. This falls back to reading the .env files next to this code
// directly: .env.<projectId> first, then .env.

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');

function projectId() {
  if (process.env.GCLOUD_PROJECT) return process.env.GCLOUD_PROJECT;
  try {
    return JSON.parse(process.env.FIREBASE_CONFIG || '{}').projectId || '';
  } catch (_) {
    return '';
  }
}

function fromFile(file, key) {
  try {
    const text = fs.readFileSync(path.join(ROOT, file), 'utf8');
    for (const line of text.split(/\r?\n/)) {
      const m = /^\s*([A-Za-z0-9_]+)\s*=\s*(.*?)\s*$/.exec(line);
      if (m && m[1] === key) return m[2].replace(/^(['"])(.*)\1$/, '$2');
    }
  } catch (_) {}
  return undefined;
}

/// The raw value of [key]: process.env, else .env.<projectId>, else .env,
/// else any other .env.<something> file (not .env.example / .env.local).
function envValue(key) {
  if (process.env[key] !== undefined && process.env[key] !== '') return process.env[key];
  const pid = projectId();
  if (pid) {
    const v = fromFile(`.env.${pid}`, key);
    if (v !== undefined) return v;
  }
  const base = fromFile('.env', key);
  if (base !== undefined) return base;
  try {
    for (const f of fs.readdirSync(ROOT)) {
      if (!/^\.env\.[^.]+$/.test(f) || f === '.env.example' || f === '.env.local') continue;
      const v = fromFile(f, key);
      if (v !== undefined) return v;
    }
  } catch (_) {}
  return undefined;
}

/// true when [key] is set to "true".
function envFlag(key) {
  return String(envValue(key) || '').trim().toLowerCase() === 'true';
}

module.exports = { envFlag, envValue };
