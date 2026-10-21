const test = require('node:test');
const assert = require('node:assert');
const N = require('../intake/normalize');
const { _internal } = require('../intake/functions');

test('phones normalize to E.164', () => {
  assert.strictEqual(N.normPhone('(317) 555-0142'), '+13175550142');
  assert.strictEqual(N.normPhone('1-317-555-0142'), '+13175550142');
  assert.strictEqual(N.normPhone('+44 7700 900123'), '+447700900123');
  assert.strictEqual(N.normPhone('555-0142'), '');
  // The legacy "whatsapp:+1..." prefix form, international included.
  assert.strictEqual(N.normPhone('whatsapp:+447700900123'), '+447700900123');
  assert.strictEqual(N.normPhone('whatsapp:+13175550142'), '+13175550142');
});

test('WhatsApp messages are told apart from texts', () => {
  assert.strictEqual(N.messageChannel('+447700900123', 'whatsapp'), 'whatsapp');
  assert.strictEqual(N.messageChannel('+13175550142', 'SMS'), 'sms');
  assert.strictEqual(N.messageChannel('+13175550142', 'MMS'), 'sms');
  assert.strictEqual(N.messageChannel('whatsapp:+447700900123'), 'whatsapp'); // legacy prefix form
  assert.strictEqual(N.messageChannel(''), 'sms');
});

test('emails and intake local parts', () => {
  assert.deepStrictEqual(N.emailsIn('"Dana" <Dana@X.com>, b@y.org'), ['dana@x.com', 'b@y.org']);
  assert.strictEqual(N.displayNameIn('"Dana Miller" <dana@x.com>'), 'Dana Miller');
  assert.strictEqual(N.intakeLocalPart('Miller-4821+pics@In.VerinLegal.com', 'in.verinlegal.com'), 'miller-4821');
  assert.strictEqual(N.intakeLocalPart('miller-4821@other.com', 'in.verinlegal.com'), '');
});

test('address stems', () => {
  assert.strictEqual(N.addressStem({ clientName: 'Courtney Curtis-Miller' }), 'miller');
  assert.strictEqual(N.addressStem({ clientName: '', matterName: 'Miller v The State of Indiana' }), 'miller');
  assert.strictEqual(N.addressStem({}), 'matter');
  assert.strictEqual(N.addressStem({ clientName: 'José Peña' }), 'pena');
});

test('kinds and decorative images', () => {
  assert.strictEqual(N.kindFor('image/jpeg', 'a.jpg'), 'photo');
  assert.strictEqual(N.kindFor('video/quicktime', 'a.mov'), 'video');
  assert.strictEqual(N.kindFor('application/pdf', 'a.pdf'), 'document');
  assert.strictEqual(N.kindFor('message/rfc822', 'a.eml'), 'email');
  assert.ok(N.isDecorativeAttachment({ contentType: 'image/png', inline: true, size: 3000 }));
  assert.ok(!N.isDecorativeAttachment({ contentType: 'image/png', inline: false, size: 3000 }));
});

test('telnyx webhook signature verifies, rejects tampering, and rejects a stale timestamp', () => {
  const crypto = require('node:crypto');
  const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
  const pubRaw = publicKey.export({ type: 'spki', format: 'der' }).subarray(-32).toString('base64');
  const body = Buffer.from(JSON.stringify({ data: { event_type: 'message.received' } }));
  const ts = String(Math.floor(Date.now() / 1000));
  const sig = crypto.sign(null, Buffer.concat([Buffer.from(ts), Buffer.from('|'), body]), privateKey).toString('base64');
  assert.ok(N.telnyxSignatureValid(pubRaw, ts, body, sig));
  assert.ok(!N.telnyxSignatureValid(pubRaw, ts, Buffer.from('tampered'), sig));
  assert.ok(!N.telnyxSignatureValid(pubRaw, String(Number(ts) - 3600), body, sig)); // 1h old: stale
  assert.ok(!N.telnyxSignatureValid(pubRaw, ts, body, 'not-a-real-signature'));
});

test('postmark JSON parses with attachments', async () => {
  const body = Buffer.from(
    JSON.stringify({
      FromFull: { Email: 'Dana@X.com', Name: 'Dana' },
      ToFull: [{ Email: 'miller-4821@in.verinlegal.com' }],
      Subject: 'Pics',
      TextBody: 'see attached',
      Attachments: [{ Name: 'a.jpg', ContentType: 'image/jpeg', Content: Buffer.from('hello').toString('base64') }],
    }),
  );
  const e = await _internal.parseEmail('postmark', body, 'application/json');
  assert.strictEqual(e.from.email, 'dana@x.com');
  assert.ok(e.recipients.includes('miller-4821@in.verinlegal.com'));
  assert.strictEqual(e.attachments[0].content.toString(), 'hello');
  assert.match(_internal.synthesizeEml(e).toString(), /Subject: Pics/);
});

test('sendgrid multipart (raw MIME) parses', async () => {
  const mime = [
    'From: "Dana" <dana@x.com>',
    'To: miller-4821@in.verinlegal.com',
    'Subject: Raw',
    'MIME-Version: 1.0',
    'Content-Type: multipart/mixed; boundary="b1"',
    '',
    '--b1',
    'Content-Type: text/plain',
    '',
    'body text',
    '--b1',
    'Content-Type: application/pdf; name="x.pdf"',
    'Content-Disposition: attachment; filename="x.pdf"',
    'Content-Transfer-Encoding: base64',
    '',
    Buffer.from('%PDF-1.4 test').toString('base64'),
    '--b1--',
    '',
  ].join('\r\n');
  const boundary = 'XYZ';
  const part = (name, val) => `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${val}\r\n`;
  const body = Buffer.from(part('email', mime) + part('envelope', JSON.stringify({ to: ['miller-4821@in.verinlegal.com'], from: 'dana@x.com' })) + `--${boundary}--\r\n`);
  const e = await _internal.parseEmail('sendgrid', body, `multipart/form-data; boundary=${boundary}`);
  assert.ok(e.raw);
  assert.strictEqual(e.subject, 'Raw');
  assert.strictEqual(e.from.email, 'dana@x.com');
  assert.strictEqual(e.attachments.length, 1);
  assert.strictEqual(e.attachments[0].filename, 'x.pdf');
});

test('sendgrid multipart (parsed fields + files)', async () => {
  const boundary = 'QQ';
  const field = (name, val) => `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${val}\r\n`;
  const file = `--${boundary}\r\nContent-Disposition: form-data; name="attachment1"; filename="p.png"\r\nContent-Type: image/png\r\n\r\nPNGDATA\r\n`;
  const body = Buffer.from(
    field('from', 'Dana <dana@x.com>') + field('to', 'miller-4821@in.verinlegal.com') + field('subject', 'Hi') + field('text', 'yo') + field('attachment-info', JSON.stringify({ attachment1: { filename: 'p.png', type: 'image/png' } })) + file + `--${boundary}--\r\n`,
  );
  const e = await _internal.parseEmail('sendgrid', body, `multipart/form-data; boundary=${boundary}`);
  assert.strictEqual(e.raw, null);
  assert.strictEqual(e.attachments[0].content.toString(), 'PNGDATA');
  assert.strictEqual(e.from.name, 'Dana');
});

test('SMS acknowledgment confirms receipt and gives the emergency instruction', () => {
  assert.match(N.SMS_ACK_TEXT, /Received/);
  assert.match(N.SMS_ACK_TEXT, /911/);
});
