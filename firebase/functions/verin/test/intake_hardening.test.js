const test = require('node:test');
const assert = require('node:assert');
const { requestFor, parseFrom } = require('../common/mailer');

test('mailer builds Postmark and SendGrid requests', () => {
  const pm = requestFor('postmark', 'k', { from: 'Verin <no-reply@verinlegal.com>', to: 'a@b.com', subject: 's', text: 't' });
  assert.strictEqual(pm.url, 'https://api.postmarkapp.com/email');
  assert.strictEqual(pm.headers['X-Postmark-Server-Token'], 'k');
  assert.strictEqual(pm.body.To, 'a@b.com');
  const sg = requestFor('sendgrid', 'k', { from: 'Verin <no-reply@verinlegal.com>', to: 'a@b.com', subject: 's', text: 't' });
  assert.strictEqual(sg.body.from.email, 'no-reply@verinlegal.com');
  assert.strictEqual(sg.body.from.name, 'Verin');
  assert.deepStrictEqual(parseFrom('x@y.com'), { name: '', email: 'x@y.com' });
});

test('sendMail is a no-op until email is switched on', async () => {
  delete process.env.EMAIL_ENABLED;
  const { sendMail } = require('../common/mailer');
  const r = await sendMail({ to: 'a@b.com', subject: 's', text: 't' }, { fetchImpl: () => assert.fail('should not send') });
  assert.strictEqual(r.sent, false);
});

test('provisioning gaps name what a matter is missing', () => {
  process.env.INBOUND_EMAIL_DOMAIN = 'in.example.com';
  process.env.TWILIO_SMS_NUMBER = '+13175551234';
  process.env.DEMO_INBOUND_EMAIL_DOMAIN = '';
  process.env.DEMO_TWILIO_SMS_NUMBER = '';
  const { provisioningGaps } = require('../intake/functions')._internal;
  assert.deepStrictEqual(provisioningGaps({}), ['email address', 'texting number']);
  assert.deepStrictEqual(provisioningGaps({ emailAddress: 'a@in.example.com', smsNumber: '+1' }), []);
  assert.deepStrictEqual(provisioningGaps({ intakeEnabled: { email: false, sms: false } }), []);
  // Demo matters with no demo intake configured are not "missing" anything.
  assert.deepStrictEqual(provisioningGaps({ demo: true }), []);
});
