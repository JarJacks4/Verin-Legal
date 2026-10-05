## Email and text intake (client forwarding)

Each matter gets `<name>-<4 digits>@in.verinlegal.com`. Texts go to one firm
number and are filed to the matter whose **client mobile** matches the sender.
Unknown email senders are stored, hashed and chained but held in **quarantine**
until someone approves them (receipt drawer → *Approve and read*). Texts from
unknown numbers appear at the top of the **Review queue** to file by hand.

Functions: `inboundEmail`, `inboundSms` (webhooks), `onInboundEvent` (files
items), `onMatterIntake` / `provisionIntake` (addresses), `approveQuarantined`,
`assignUnrouted`.

### 1. Secrets and settings
```
firebase functions:secrets:set INBOUND_WEBHOOK_KEY   # any long random string
firebase functions:secrets:set TWILIO_AUTH_TOKEN     # Twilio console → Account info
```
In `firebase/functions/.env`:
```
INBOUND_EMAIL_DOMAIN=in.verinlegal.com
TWILIO_ACCOUNT_SID=AC...
TWILIO_SMS_NUMBER=+1XXXXXXXXXX
TWILIO_WEBHOOK_URL=https://us-central1-verin-legal-fbzp5w.cloudfunctions.net/inboundSms
SMS_AUTO_REPLY=false
```
Then `npm install` in `firebase/functions` (adds busboy) and deploy functions,
rules and indexes.

### 2. Email — SendGrid (demo)
1. SendGrid → Settings → Sender Authentication: authenticate `verinlegal.com`.
2. DNS: `MX  in.verinlegal.com  →  mx.sendgrid.net` (priority 10).
3. SendGrid → Settings → Inbound Parse → Add Host & URL:
   host `in.verinlegal.com`, URL
   `https://us-central1-verin-legal-fbzp5w.cloudfunctions.net/inboundEmail?key=<INBOUND_WEBHOOK_KEY>`,
   tick **POST the raw, full MIME message** (keeps the exact original as evidence).

### 2b. Email — Postmark (production)
1. Postmark → Servers → Inbound stream → Settings: inbound domain `in.verinlegal.com`,
   webhook URL as above (same `?key=`), tick **Include raw email content**.
2. DNS: `MX  in.verinlegal.com  →  inbound.postmarkapp.com` (priority 10).
No code change: the webhook recognises either provider.

### 3. Text — Twilio
1. Buy a number with SMS + MMS. Phone Numbers → the number → Messaging →
   "A message comes in": Webhook, HTTP POST,
   `https://us-central1-verin-legal-fbzp5w.cloudfunctions.net/inboundSms`
   (must equal `TWILIO_WEBHOOK_URL` exactly — it's part of the signature check).
2. Receiving works right away. Replies (`SMS_AUTO_REPLY=true`) need A2P 10DLC or
   toll-free verification in Twilio first.
3. Optional per firm: set `smsNumber` on that firm's `firmAccount` document to
   give the firm its own number; otherwise `TWILIO_SMS_NUMBER` is used.

Existing matters get their address the first time someone opens their Intake tab.
