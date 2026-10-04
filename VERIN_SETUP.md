# Verin — setup and deploy

This branch (`claude/finish-build`) wires every screen to Firestore and adds the backend
in `firebase/functions/verin/`. Once you edit code here, **stop pushing from FlutterFlow** —
a FlutterFlow export would overwrite these changes.

## 1. Run the app locally
```
flutter pub get
flutter analyze
flutter run -d chrome
```
Send any `flutter analyze` errors back to Claude; the code was written without a compiler.

## 2. One-time Firebase setup (project `verin-legal-fbzp5w`)
Requires the Firebase CLI (`npm install -g firebase-tools`, then `firebase login`) and the Blaze plan.

```
cd firebase/functions
npm install
npm test                      # 46 backend tests
cp .env.example .env          # then fill in CLIO_CLIENT_ID etc. when you have them
firebase functions:secrets:set ANTHROPIC_API_KEY      # from console.anthropic.com
firebase functions:secrets:set TOKEN_ENCRYPTION_KEY   # paste output of: openssl rand -base64 32
firebase functions:secrets:set CLIO_CLIENT_SECRET     # from the Clio developer portal
cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```
Images in the app load from Firebase Storage; allow the browser to read them once:
`gsutil cors set cors.json gs://<your-bucket>` (run inside `firebase/`).

## 3. What the backend does
| Function | Purpose |
|---|---|
| ingestScreenshot | Stores an uploaded screenshot, SHA-256 hashes it, appends it to the matter's hash chain, reads the messages with Claude, writes the Receipt |
| extractThreadMessages | Retry extraction on an existing Receipt |
| verifyMatterChain | Recomputes a matter's hash chain (Standalone Verify Tool) |
| exportMatterRecord | Builds the Certificate of Preparation / exhibit index / transcript / chain appendix PDF |
| clioAuthStart, clioOAuthCallback, clioDisconnect | Server-side Clio OAuth; tokens are encrypted, never in the app |
| clioSearchMatters, clioLinkMatter, clioPushDocument | Link a Verin matter to a Clio matter and upload the record PDF |

## 4. Data notes
- Receipts, chainEntries, clioSyncLog and exports are written only by the functions (see `firebase/firestore.rules`).
- Admin pages require `users/{uid}.role` = `Admin` or `Owner`.
- Firm settings read the first `firmAccount` document; create one in the Firebase console if missing.

## 5. Not built yet (needs a decision)
Billing/Stripe and invoices, sending invite emails and client follow-up messages (SMS/email),
inbound email/SMS/WhatsApp intake addresses, external timestamp anchoring (RFC 3161),
MyCase/Smokeball/Dropbox, enforcing MFA/IP/session settings.
