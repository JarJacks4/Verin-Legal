# Verin Legal — deployment guide

For whoever deploys this build. Read it top to bottom once before starting.

## Important: this code does not go back into FlutterFlow
FlutterFlow can export code to GitHub, but it cannot import code. This version was finished
by editing the exported Flutter code directly, so it is deployed straight from this repo with
the Flutter and Firebase command-line tools. Do not push a new FlutterFlow export over it; that
would erase these changes. From now on, this repo is the source of truth.

The web app is hosted on Firebase Hosting in the same Firebase project the app already uses
(`verin-legal-fbzp5w`).

## 0. What you need installed (Windows, macOS or Linux)
- Git: https://git-scm.com/downloads
- Flutter (stable): https://docs.flutter.dev/install. Check with `flutter doctor` (Flutter and Chrome must be green).
- Node.js 20 LTS: https://nodejs.org
- Firebase CLI: `npm install -g firebase-tools`, then `firebase login` with an account that is
  Owner or Editor on the `verin-legal-fbzp5w` Firebase project.
- The Firebase project must be on the **Blaze** (pay-as-you-go) plan. Cloud Functions require it.

## 1. Get the code onto GitHub
This folder is a full copy of the repo with the work committed on the branch `claude/finish-build`.
Open a terminal in this folder (the one containing `pubspec.yaml`):
```
git status                      # should say: On branch claude/finish-build
git remote -v                   # should point to github.com/JarJacks4/Verin-Legal
git push -u origin claude/finish-build
```
Then open a pull request on GitHub:
https://github.com/JarJacks4/Verin-Legal/compare/main...claude/finish-build
Review it and merge it into `main`.

## 2. Check the app compiles and runs locally
```
flutter pub get
flutter analyze
flutter run -d chrome
```
`flutter analyze` must report no **errors** (info and warnings are fine). This code was written
without a compiler available, so if it reports errors, copy the full output back to Claude
(or a developer) to fix before deploying.

## 3. Secrets and settings (one time)
Get these values first:
- **Anthropic API key**: console.anthropic.com → API Keys. Used to read photos, screenshots,
  PDFs, Word files and emails.
- **Vertex AI** (video and voice-note transcription): Google Cloud console → APIs & Services →
  enable **Vertex AI API** (`aiplatform.googleapis.com`) on project verin-legal-fbzp5w. No key is
  needed; the functions use their own service account. Model defaults to `gemini-3.5-flash`
  (override with `VIDEO_MODEL` in `.env`).
- **Clio app**: developers.clio.com. The **Client ID**, the **Client Secret**, and your Clio
  region (US/EU/CA/AU). Register this exact Redirect URI on the Clio app:
  `https://us-central1-verin-legal-fbzp5w.cloudfunctions.net/clioOAuthCallback`
  Permissions: Matters (read), Contacts (read), Documents (read/write).

Then, from the repo:
```
cd firebase/functions
npm install
npm test                                              # expect: 84 pass, 0 fail
copy .env.example .env                                # macOS/Linux: cp .env.example .env
```
Edit `firebase/functions/.env` and set `CLIO_CLIENT_ID`, `CLIO_REGION` (us/eu/ca/au), and
`APP_URL`. Set `APP_URL` to the hosting URL from step 5; fill it in after the first deploy.

Set the three secrets. Each command prompts you to paste the value, which never goes into a file:
```
firebase functions:secrets:set ANTHROPIC_API_KEY
firebase functions:secrets:set CLIO_CLIENT_SECRET
firebase functions:secrets:set TOKEN_ENCRYPTION_KEY
```
For `TOKEN_ENCRYPTION_KEY`, paste a random 32-byte base64 value. Generate one with
`node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"`.
Store it somewhere safe; if it's lost, Clio must be reconnected.

## 4. Deploy the backend (Cloud Functions, rules, indexes)
From the `firebase/` folder:
```
cd ..            # now in firebase/
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```
Indexes can take a few minutes to build after deploy. Screens may show an "index" error until then.
The first deploy of `onReceiptCreated` (a Firestore trigger) sometimes fails while Google sets up
Eventarc permissions; wait two minutes and run the same deploy again.

Storage rules (`firebase/storage.rules`) must be deployed — uploads go to `intake/{uid}/…` first
and are moved under the matter by `ingestEvidence`.

Allow the web app to display images stored in Firebase Storage (one time). This needs the
Google Cloud CLI (`gcloud`), which provides `gsutil`:
```
gsutil cors set cors.json gs://verin-legal-fbzp5w.firebasestorage.app
```
(That is this project's bucket, from its Firebase web config.)

## 5. Deploy the web app (Firebase Hosting)
From the repo root:
```
flutter build web --release --output firebase/public
cd firebase
firebase deploy --only hosting --project verin-legal-fbzp5w
```
The CLI prints the live URL, e.g. `https://verin-legal-fbzp5w.web.app`. Put that in `APP_URL`
(step 3) and redeploy functions once: `firebase deploy --only functions`.

In the Firebase console → Authentication → Settings → **Authorized domains**, make sure
the hosting domain (and any custom domain) is listed, or sign-in will fail.

Optional custom domain: Firebase console → Hosting → Add custom domain.

## 6. Data the app expects
- **Admins:** people who pick **Administrator** as their role when creating an account see the
  Admin console. To change someone later, set `role` in Firestore `users/{uid}` to `Admin`
  (or `Owner`); anything else hides it.
- **Firm account:** Admin console → Settings → **Save changes** creates the `firmAccount` document
  if none exists. Plan fields (`planName`, `planStatus`, `planPriceCents`, `planRenewsAt`,
  `memberSince`, `seatLimit`) can only be set in the Firebase console, so nobody can upgrade
  themselves from the app.
- **Firm ID:** every matter uses `firmID = "harbow-law"` (set in `lib/verin/verin_config.dart` and
  `DEFAULT_FIRM_ID` in `.env`). Change both together if you rename it.

## 7. Smoke test after deploying
1. Sign in → Matters list loads → open a matter (no crash, real name/client in the header).
2. Intake channel tab → **Add manual entry** → Photo → upload a PNG of a text conversation. The
   Receipts tab shows it with a SHA-256 ("Reading…" first), and the Thread tab shows the messages
   within ~30 seconds. Try a PDF (Document), an .eml (Email) and a short video too.
3. Integrity tab → chain entry #1 appears. **Standalone verify tool** → **Verify chain now** passes;
   **Export record ZIP** downloads a ZIP; unzip it and run `python3 verify.py` → PASS.
4. Integrity tab → **Certificate of preparation** → **Download PDF** opens the record PDF.
5. Practice tab → **Connect Clio** → sign in to Clio → page shows "Connected" → **Link to a Clio matter**
   → **Push record to Clio** → the sync log shows "synced" and the PDF is in that Clio matter's Documents.
6. Settings → change the firm name → Save → reload → the change is kept.
7. Admin Portal (as an Admin) → Dashboard numbers and charts show real counts.

If a function fails: Firebase console → Functions → Logs, or `firebase functions:log`.

## What the backend does
| Function | Purpose |
|---|---|
| ingestEvidence | Files any uploaded item (photo, video, voice note, PDF, Word, text, .eml/.msg) or a physical item: SHA-256 over the exact bytes while moving them under the matter, hash-chain entry, RFC 3161 timestamp |
| onReceiptCreated | AI reading after intake: Claude reads images/PDFs/documents/emails (summary, evidence date, messages); Gemini on Vertex transcribes video/audio and reads screen recordings; ffprobe records the video's metadata |
| reprocessReceipt | "Run AI reading again" / "Request transcription" |
| exportRecordZip | Standalone-verifiable ZIP: manifest.json, exhibits/, timestamps/*.tsr, certificate.pdf, verify.py |
| exportIntegrationReport / exportFirmData | Integration report PDF; all matters' manifests in one ZIP |
| ingestScreenshot / extractThreadMessages | Older screenshot-only path, kept for compatibility |
| verifyMatterChain | Recomputes a matter's hash chain (Standalone Verify Tool) |
| exportMatterRecord | Builds the record PDF: certificate, exhibit index, transcript, chain appendix |
| clioAuthStart / clioOAuthCallback / clioDisconnect | Server-side Clio sign-in. Tokens are encrypted and never reach the app |
| clioSearchMatters / clioLinkMatter / clioPushDocument | Link a matter to Clio and upload the record PDF |

Receipts, chainEntries, clioSyncLog and exports are written only by these functions (enforced in
`firebase/firestore.rules`), so the record can't be edited from the app.

## Not built yet (needs a product decision)
Billing/Stripe and card payments (invoices are read from `firmAccount/{id}/invoices` if you add
them); sending invite and notification emails; inbound email/SMS/WhatsApp intake addresses (the
Intake tab shows them once `emailAddress` / `smsNumber` / `whatsAppAddress` are set on a matter);
MyCase and Smokeball; the public REST API.

## 8. Automatic deploys from GitHub (after the first manual deploy works)
`.github/workflows/deploy-web.yml` runs on every push/merge to `main`: it checks the code
(`flutter analyze`, backend tests), builds the web app, and deploys it to Firebase Hosting.
Pull requests get a temporary preview link posted on the PR instead.

One-time setup, so GitHub can deploy:
1. Google Cloud console (console.cloud.google.com), project `verin-legal-fbzp5w` → **IAM & Admin → Service Accounts**
   → **Create service account**, name it `github-deploy`.
2. Grant it the roles **Firebase Hosting Admin** and **API Keys Viewer** (Cloud Run Viewer as well if
   you later add hosting rewrites to functions). Click Done.
3. Open the new account → **Keys** → **Add key → Create new key → JSON**. A .json file downloads.
4. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**.
   Name: `FIREBASE_SERVICE_ACCOUNT`. Value: paste the entire contents of that JSON file. Save.
5. Delete the downloaded JSON file from your computer. Never commit it.
6. GitHub repo → **Actions** tab → "Deploy web app" → **Run workflow** to test it once.

If a run fails, open it in the Actions tab; the failing step's log shows why (most often an
analyze error or a missing secret). Functions are still deployed manually (step 4) because
they need the Firebase secrets.

## Firms (multi-firm separation)

- Every account belongs to one firm: `users/{uid}.firmID`, plus `role` for
  access. Only the `setupAccount` function writes these; the app calls it
  after sign-up and once per session.
- A new sign-up creates a new firm (`firmAccount/f_…`) and is its Admin.
  Someone signing up with an email an admin invited (Admin → Team → Invite
  member, then send the link) joins that firm with the invited role.
- Receipts, chain entries and Clio sync log entries carry `firmID`; the
  Firestore and Storage rules only let people read their own firm's records.
- Records created before separation are stamped with their firm the first
  time someone from that firm opens the app (marker: `firmScope/{firmId}`).
- Deploy order when changing any of this: functions, then
  `firestore:indexes`, then `firestore:rules,storage`, then hosting.

## Verification, reconstruction, follow-ups, exhibits, value (Oct 2026)

New functions: `onReceiptWritten`, `onMatterNamesChanged`, `refreshMatterRecord`
(server-side thread reconstruction, what's-new updates, follow-up suggestions),
`produceExhibits` (Bates-stamped productions; 4 GiB, 540 s). New packages in
functions: `pdf-lib`, `pdfjs-dist`, `@napi-rs/canvas` (prebuilt Linux binary;
used to burn redactions into pixels).

New collections: `FollowUps`, `Corrections`, `Activity`; per matter:
`derived/thread`, `updates/{receiptId}`, `productions/{id}`. Rules and indexes
cover all of them — deploy `firestore:rules` and `firestore:indexes` with the
functions.

Existing matters build their thread the first time someone opens the Thread
tab (or on the next item that arrives). Items read before this release have no
locations or redaction suggestions until "Run AI reading again".

## Email and text intake (client forwarding)

Each matter gets `<name>-<4 digits>@in.verinlegal.com`. Texts go to one firm
number and are filed to the matter whose **client mobile** matches the sender.
Unknown email senders are stored, hashed and chained but held in **quarantine**
until someone approves them (receipt drawer → *Approve and read*). Texts from
unknown numbers appear at the top of the **Review queue** to file by hand.

Functions: `inboundEmail`, `inboundSms` (webhooks), `onInboundEvent` (files
items), `onMatterIntake` / `provisionIntake` (addresses). `approveQuarantined` and
`assignUnrouted` (Review queue actions) are always deployed, intake on or off.

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

### 4. WhatsApp — same Twilio number (optional)
1. Twilio → Messaging → Senders → WhatsApp senders → self sign-up: connect the Meta
   Business account, finish Meta business verification, register the firm's Twilio
   number with display name "Verin Legal". The number must not be on the WhatsApp app.
2. On the sender, "A message comes in" → the same `inboundSms` URL, HTTP POST.
3. Once Meta approves it, set `WHATSAPP_ENABLED=true` in `.env` and deploy functions.
   Messages are filed like texts but labelled WhatsApp; client cards gain a WhatsApp line.

Existing matters get their address the first time someone opens their Intake tab.

## NFR demo workspace

A demo is its own account and firm, filled with fictional sample matters.
1. Sign up a separate account (e.g. demo@verinlegal.com) with firm name "Verin Demo".
2. Admin → Settings → Demo workspace → **Make this a demo workspace**. It must have no real matters.
3. Every screen shows a yellow "NFR DEMO" strip. **Reset demo** (strip or Settings) wipes everything in the
   workspace — including anything added during a demo — and restores the sample matters (about a minute).
Function: `seedDemoWorkspace` (no AI calls; items are hashed, chained and time-stamped like real ones).

## Launch-readiness release (Oct 7, 2026)

Features from launch checklist v2 that live in the app:

| Checklist | Where |
|---|---|
| #8 every demo timed and logged | Demo banner → **Time this demo** / **End demo**; log in Admin → Settings → Demo runs (`demoRuns`) |
| #9 demo data-handling note | Demo banner → **Data handling**. Shows a DRAFT label to admins until `kDemoTermsCounselReviewed` (lib/verin_app/demo/data_handling.dart) is set to `true` after counsel review |
| #12 sample matters, all five practices | Reset demo now builds 7 fictional matters (family ×3, personal injury, immigration, civil, criminal) |
| #19 accuracy targets measured | Verify against the original → **Date is wrong** / **Wrong place in thread**; Admin → Dashboard → Accuracy. Targets in `lib/verin/verin_config.dart` |
| #22 MyCase tier told up front | Practice mgmt tab |
| #29 client never sees an error | SMS auto-reply (when `SMS_AUTO_REPLY=true`) confirms receipt and gives the 911 line |
| #41 Terms / Privacy | Sign-up requires agreeing; links go to `www.verinlegal.com/terms` and `/privacy` (publish those pages on Framer) |
| #50 client instruction card, English and Spanish | Intake channel → **Copy instructions** / **Copiar en español**, with a what-to-send note per practice |
| #51 support | Profile → **Help & support**: address, hours, response time, ten how-tos. Edit them in `verin_config.dart` |
| #52 status and incidents | Create Firestore doc `systemStatus/current` in the console: `active: true`, `level: info / degraded / outage`, `message`, `updatedAt`. Every screen shows the strip; set `active: false` to clear |
| #66 / #69 chronology export | Thread tab → **Chronology (Excel)** |
| #73 declaration template | Exhibits → finished production → **Draft declaration** (counsel to review the template before first use) |

Also: cited summaries on the Thread tab (`summarizeThread` function), hearing and filing dates on
each matter with Upcoming hearings on the Matters list, search across all evidence from the
Matters search box, and a per-item access log in the receipt drawer (admins).

Deploy: functions (new `summarizeThread`, updated `seedDemoWorkspace` and `inboundSms`),
`firestore:rules`, then hosting. Then press **Reset demo** once in the demo workspace.

## Launch checklist release 2 (Oct 8, 2026)

Everything app-side still open on launch checklist v2, except billing (firms sign a contract first).

| Checklist | What was added | Where |
|---|---|---|
| #1 separate demo intake | Demo matters use their own email domain and texting number; live addresses never reach a demo and demo addresses never reach a firm. Any matter opened in a demo workspace is a demo matter. | `DEMO_INBOUND_EMAIL_DOMAIN`, `DEMO_TWILIO_SMS_NUMBER` in `.env` |
| #3 "text it now" | Demo Intake tab shows the real demo number and address, and celebrates anything that arrives while it's open. Texts from any phone (and emails from anyone) to the demo number land in the case marked live (Reyes by default; **Use this case for live messages** on another). | Intake tab (demo) |
| #4 closed-matter import | ZIP of a folder, .mbox, .eml or loose files; every file becomes its own item. Counts: items received, distinct dated items, conversations rebuilt, items flagged. | Matter → **Record** → Import a closed matter |
| #5 before and after | As-sent items next to the assembled record; every line cites its item; gaps and unreadable items shown. | Matter → **Timeline** tab → Before and after |
| #6 write-back live | Connecting a real Clio sandbox from the demo workspace replaces the simulation; Reset demo keeps the real connection. | Practice mgmt tab |
| #9 demo deletion | Deletes a prospect's material and emails the deletion confirmation (or shows it to copy). | Matter → Record → Delete demo material (demo only) |
| #15 provisioning | Failed or incomplete provisioning raises a firm alert; `TWILIO_NUMBER_POOL` hands numbers out one per firm. | Alert strip at the top of every page |
| #16 delete after delivery | Record ZIP delivered to Clio (confirmed upload) or downloaded and confirmed by the firm, then Verin deletes its copy of each finished file. Hashes, RFC 3161 tokens, chain and audit log stay. Nightly Clio delivery. **Verify a file** checks any copy against the record in the browser. | Matter → Record → Deliver the record / Verify a file; Settings → Records and delivery |
| #21 timeline | Every item on one dated line with both dates, hearings as milestones. | Timeline tab |
| #22 versioned write-back | Each push to Clio is a new version of the same document, not a duplicate. | automatic |
| #23 baseline at connect | Firm's own pre-Verin Record Lag captured from Clio when it connects, then locked; or entered from a dated sample. Dashboard and Program use it. | Settings → Baseline Record Lag |
| #29 client never sees an error | Email receipt with the emergency line (`EMAIL_AUTO_REPLY`); more than 40 attachments, or a text photo that couldn't be collected, raises a firm-facing request. | alerts |
| #31 two-step sign-in | Authenticator-app codes; firms can require it for everyone. | Profile drawer; Settings → Records and delivery |
| #53 cost to serve | Weekly per firm (`costReports`, Verin staff only) and on demand for admins. | Settings → Reports |
| #27 / #71 packets | PI treatment chronology, immigration checklist coverage, civil key-date chronology, criminal event window and mitigation packet; family uses Exhibits. Redactions confirmed first; flagged values masked. | Matter → Record → Hearing / filing packet |
| #67 Record Lag Audit | Headline median, three figures, matter table, latest-arriving item, method, every item. | Settings → Reports |
| #68 Standing Record | Record PDF now has both dates per item, pre-intake flags, a gap memorandum and a receipt and handling log. | every record export |
| #69 Word export | Status, review queue, requests, issues, cited chronology, exhibits, integrity appendix. | Matter → Record → Standing Record (Word) |
| #70 weekly digest | Mondays 7:00: one page per open matter, added to Clio as a new version, optional email. | Settings toggles; Record → This week's digest |
| #72 exit export | Firm export now carries every native file plus `index.csv` mapping each file to its entry. | Settings → Export all data |
| #74 monthly report | 1st of each month, or on demand. | Settings → Reports |
| #76 AI model layer | Every model call goes through `verin/ai/models.js`; provider, model, prompt id and prompt fingerprint are saved on each item. | backend |

### One-time setup for this release

1. **Deploy:** functions, `firestore:rules`, `firestore:indexes`, then hosting (the usual `deploy.bat`). Then press **Reset demo** in the demo workspace.
2. **Two-step sign-in:** Firebase console → Authentication → Settings → upgrade to **Identity Platform** (free tier covers this), then enable **Multi-factor authentication → TOTP**. Until then the "Turn on" button explains that it isn't enabled.
3. **Outbound email** (client receipts, digests, deletion confirmations): create the secret `EMAIL_API_KEY` (Postmark server token, or a SendGrid key for the demo) in Secret Manager, then set `EMAIL_ENABLED=true` and `EMAIL_FROM` in `.env` and deploy functions. With it off, everything else works and emails are simply not sent.
4. **Demo intake:** buy a second Twilio number for demos, point it at the same `inboundSms` webhook, and set `DEMO_TWILIO_SMS_NUMBER`; add a demo email domain (e.g. `demo.in.verinlegal.com`) to SendGrid Inbound Parse with the same webhook, and set `DEMO_INBOUND_EMAIL_DOMAIN`. Both need `INTAKE_ENABLED=true`.
5. **Clio sandbox for demos:** sign in to the demo workspace as an admin and connect the Clio sandbox account from Settings; link each demo matter to a sandbox matter in its Practice mgmt tab.
6. **Backups (#31):** create a bucket `verin-legal-fbzp5w-backups` (same region, 30-day lifecycle delete), give the App Engine default service account the roles **Cloud Datastore Import Export Admin** and **Storage Admin** on that bucket, then set `BACKUP_BUCKET=verin-legal-fbzp5w-backups` in `.env` and deploy. Test a restore once into a scratch project: `gcloud firestore import gs://verin-legal-fbzp5w-backups/firestore/<date> --project <scratch-project>`.
