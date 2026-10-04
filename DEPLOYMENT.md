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
