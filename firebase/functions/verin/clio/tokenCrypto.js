// Verin Legal — encrypt Clio tokens at rest.
//
// Clio's docs say refresh tokens don't expire and "should be encrypted and
// stored securely". They're stored in a Firestore doc the client can never read
// (rules deny it), and additionally sealed with AES-256-GCM using a key that
// lives only in Secret Manager — so a Firestore export or a rules mistake alone
// doesn't leak a working token.
//
// Generate the key once:   openssl rand -base64 32
// Store it:                firebase functions:secrets:set TOKEN_ENCRYPTION_KEY

const crypto = require('crypto');

function keyFrom(base64Key) {
  const key = Buffer.from(String(base64Key || '').trim(), 'base64');
  if (key.length !== 32) {
    throw new Error('TOKEN_ENCRYPTION_KEY must be 32 bytes, base64-encoded (openssl rand -base64 32)');
  }
  return key;
}

// Output: "v1.<iv>.<tag>.<ciphertext>", all base64url.
function seal(plaintext, base64Key) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', keyFrom(base64Key), iv);
  const ct = Buffer.concat([cipher.update(String(plaintext), 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return ['v1', iv.toString('base64url'), tag.toString('base64url'), ct.toString('base64url')].join('.');
}

function open(sealed, base64Key) {
  const parts = String(sealed || '').split('.');
  if (parts.length !== 4 || parts[0] !== 'v1') throw new Error('stored token is not in the expected format');
  const [, iv, tag, ct] = parts.map((p, i) => (i === 0 ? p : Buffer.from(p, 'base64url')));
  const decipher = crypto.createDecipheriv('aes-256-gcm', keyFrom(base64Key), iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(ct), decipher.final()]).toString('utf8');
}

module.exports = { seal, open };
