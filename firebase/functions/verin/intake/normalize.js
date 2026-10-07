// Verin Legal — pure helpers for client email/text intake (no I/O; tested).

/// "+1 (317) 555-0142", "317.555.0142", "13175550142" -> "+13175550142".
/// Numbers without a country code are taken as US/Canada. '' if unusable.
function normPhone(s) {
  const raw = String(s || '').trim();
  if (!raw) return '';
  const digits = raw.replace(/\D/g, '');
  if (raw.startsWith('+')) return digits.length >= 8 && digits.length <= 15 ? `+${digits}` : '';
  if (digits.length === 10) return `+1${digits}`;
  if (digits.length === 11 && digits.startsWith('1')) return `+${digits}`;
  return '';
}

function normEmail(s) {
  const m = /[^\s<>,;"'()]+@[^\s<>,;"'()]+\.[^\s<>,;"'()]+/.exec(String(s || ''));
  return m ? m[0].toLowerCase().replace(/\.$/, '') : '';
}

/// Every email address in a header-ish string ("A <a@x.com>, b@y.com").
function emailsIn(s) {
  const out = [];
  const re = /[^\s<>,;"'()]+@[^\s<>,;"'()]+\.[^\s<>,;"'()]+/g;
  let m;
  while ((m = re.exec(String(s || '')))) {
    const e = m[0].toLowerCase().replace(/\.$/, '');
    if (!out.includes(e)) out.push(e);
  }
  return out;
}

/// The display name in "Dana Miller <dana@x.com>", or ''.
function displayNameIn(s) {
  const m = /^\s*"?([^"<]*?)"?\s*<[^>]+>/.exec(String(s || ''));
  return m ? m[1].trim() : '';
}

/// The intake local part an address points at, if it is on [domain]:
/// "Miller-4821+photos@In.VerinLegal.com" -> "miller-4821".
function intakeLocalPart(address, domain) {
  const e = normEmail(address);
  const d = String(domain || '').toLowerCase().trim();
  if (!e || !d) return '';
  const at = e.lastIndexOf('@');
  if (e.slice(at + 1) !== d) return '';
  return e.slice(0, at).split('+')[0];
}

/// "miller" from a client name or matter title; "matter" if nothing usable.
function addressStem(matter) {
  const pick = (s) =>
    String(s || '')
      .normalize('NFKD')
      .replace(/[̀-ͯ]/g, '')
      .toLowerCase()
      .split(/[^a-z]+/)
      .filter((w) => w.length >= 2 && !['v', 'vs', 'the', 'of', 'in', 're', 'and', 'matter', 'estate'].includes(w));
  const client = pick(matter && matter.clientName);
  const title = pick((matter && (matter.matterName || matter.caseTitle)) || '');
  const word = client.length ? client[client.length - 1] : title.length ? title[0] : 'matter';
  return word.slice(0, 14);
}

/// What kind of evidence a file is, from its type and name.
function kindFor(contentType, name) {
  const ct = String(contentType || '').toLowerCase();
  const ext = (/\.([a-z0-9]{1,6})$/i.exec(name || '') || [])[1];
  const e = ext ? ext.toLowerCase() : '';
  if (ct.startsWith('image/') || ['jpg', 'jpeg', 'png', 'heic', 'heif', 'gif', 'webp'].includes(e)) return 'photo';
  if (ct.startsWith('video/') || ct.startsWith('audio/') || ['mp4', 'mov', 'm4v', 'webm', '3gp', 'mp3', 'm4a', 'wav', 'amr', 'ogg'].includes(e)) return 'video';
  if (ct === 'message/rfc822' || e === 'eml' || e === 'msg') return 'email';
  return 'document';
}

const EXT_FOR = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/gif': '.gif',
  'image/heic': '.heic',
  'image/webp': '.webp',
  'video/mp4': '.mp4',
  'video/quicktime': '.mov',
  'video/3gpp': '.3gp',
  'audio/mpeg': '.mp3',
  'audio/amr': '.amr',
  'audio/ogg': '.ogg',
  'audio/mp4': '.m4a',
  'application/pdf': '.pdf',
  'text/plain': '.txt',
  'text/vcard': '.vcf',
  'text/x-vcard': '.vcf',
};

function extFor(contentType) {
  return EXT_FOR[String(contentType || '').toLowerCase().split(';')[0].trim()] || '';
}

/// Small inline images are signature logos and tracking pixels, not evidence.
function isDecorativeAttachment(a) {
  const size = Number(a.size || (a.content && a.content.length) || 0);
  const ct = String(a.contentType || '').toLowerCase();
  return ct.startsWith('image/') && (a.inline || a.related) && size < 20 * 1024;
}

/// Twilio's request signature: base64 HMAC-SHA1 of the URL followed by each
/// POST parameter name and value, sorted by name.
function twilioSignature(authToken, url, params) {
  const crypto = require('crypto');
  const data = Object.keys(params || {})
    .sort()
    .reduce((acc, k) => acc + k + (params[k] == null ? '' : String(params[k])), url);
  return crypto.createHmac('sha1', authToken).update(Buffer.from(data, 'utf8')).digest('base64');
}

function safeEqual(a, b) {
  const crypto = require('crypto');
  const x = Buffer.from(String(a || ''));
  const y = Buffer.from(String(b || ''));
  return x.length === y.length && x.length > 0 && crypto.timingSafeEqual(x, y);
}

/// The text file a single SMS is kept as (what gets hashed).
function smsRecordText({ from, to, body, at, sid }) {
  return [`From: ${from}`, `To: ${to}`, `Received: ${at}`, `Message SID: ${sid || ''}`, '', String(body || '')].join('\n');
}

/// Reply to a client's text (launch checklist #29: the client never sees an
/// error). Everything sent is accepted and kept; the reply says so and that
/// the number is not watched for emergencies.
const SMS_ACK_TEXT =
  "Received — your attorney's office has it. This number isn't monitored around the clock. If this is an emergency, call 911.";

/// Twilio TwiML for the reply, escaped for XML.
function smsAckTwiml(text = SMS_ACK_TEXT) {
  const esc = String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return `<Message>${esc}</Message>`;
}

module.exports = {
  SMS_ACK_TEXT,
  smsAckTwiml,
  normPhone,
  normEmail,
  emailsIn,
  displayNameIn,
  intakeLocalPart,
  addressStem,
  kindFor,
  extFor,
  isDecorativeAttachment,
  twilioSignature,
  safeEqual,
  smsRecordText,
};
