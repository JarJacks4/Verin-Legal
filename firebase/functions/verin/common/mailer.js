// Verin Legal — outbound email (acknowledgments, digests, demo deletion
// confirmations). Off until EMAIL_ENABLED=true and the EMAIL_API_KEY secret
// exists; until then sendMail() reports { sent: false, reason } and callers
// carry on (nothing in Verin depends on an email going out).
//
//   EMAIL_PROVIDER  postmark (production) | sendgrid (demo)
//   EMAIL_FROM      e.g. "Verin Legal <no-reply@verinlegal.com>"

const P = require('./params');
const { EMAIL_API_KEY, emailEnabled } = require('./mail_secrets');

function parseFrom(from) {
  const m = /^\s*(.*?)\s*<([^>]+)>\s*$/.exec(String(from || ''));
  return m ? { name: m[1].replace(/^"|"$/g, ''), email: m[2] } : { name: '', email: String(from || '').trim() };
}

function requestFor(provider, key, { from, to, subject, text, replyTo }) {
  if (provider === 'sendgrid') {
    const f = parseFrom(from);
    return {
      url: 'https://api.sendgrid.com/v3/mail/send',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: {
        personalizations: [{ to: [{ email: to }] }],
        from: f.name ? { email: f.email, name: f.name } : { email: f.email },
        ...(replyTo ? { reply_to: { email: replyTo } } : {}),
        subject,
        content: [{ type: 'text/plain', value: text }],
      },
    };
  }
  return {
    url: 'https://api.postmarkapp.com/email',
    headers: { 'X-Postmark-Server-Token': key, 'Content-Type': 'application/json', Accept: 'application/json' },
    body: { From: from, To: to, Subject: subject, TextBody: text, ...(replyTo ? { ReplyTo: replyTo } : {}), MessageStream: 'outbound' },
  };
}

async function sendMail(msg, { fetchImpl = fetch } = {}) {
  if (!emailEnabled()) return { sent: false, reason: 'email sending is not switched on' };
  const from = P.EMAIL_FROM.value();
  if (!from || !msg.to) return { sent: false, reason: 'no sender or recipient' };
  const req = requestFor(P.EMAIL_PROVIDER.value(), EMAIL_API_KEY.value().trim(), { ...msg, from });
  const r = await fetchImpl(req.url, { method: 'POST', headers: req.headers, body: JSON.stringify(req.body) });
  if (!r.ok) return { sent: false, reason: `email provider answered ${r.status}` };
  return { sent: true };
}

module.exports = { sendMail, requestFor, parseFrom };
