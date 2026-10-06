const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  let firestore = admin.firestore();
  let userRef = firestore.doc("users/" + user.uid);
  await firestore.collection("users").doc(user.uid).delete();
});

// ---- Verin: AI screenshot extraction, hash chain, Clio (see verin/README.md) ----
const verinExtraction = require("./verin/extraction/callable");
exports.ingestScreenshot = verinExtraction.ingestScreenshot;
exports.extractThreadMessages = verinExtraction.extractThreadMessages;

exports.verifyMatterChain = require("./verin/chain/callable").verifyMatterChain;

const verinAccount = require("./verin/account/setup");
exports.setupAccount = verinAccount.setupAccount;
exports.deleteAccount = require("./verin/account/delete").deleteAccount;

const verinThread = require("./verin/thread/rebuild");
exports.onReceiptWritten = verinThread.onReceiptWritten;
exports.onMatterNamesChanged = verinThread.onMatterNamesChanged;
exports.refreshMatterRecord = verinThread.refreshMatterRecord;

exports.produceExhibits = require("./verin/exhibits/produce").produceExhibits;

const verinClio = require("./verin/clio/functions");
exports.clioAuthStart = verinClio.clioAuthStart;
exports.clioOAuthCallback = verinClio.clioOAuthCallback;
exports.clioDisconnect = verinClio.clioDisconnect;
exports.clioSearchMatters = verinClio.clioSearchMatters;
exports.clioLinkMatter = verinClio.clioLinkMatter;
exports.clioPushDocument = verinClio.clioPushDocument;

exports.exportMatterRecord = require("./verin/export/callable").exportMatterRecord;

// ---- Verin: any-file evidence intake, AI reading, RFC 3161, archives ----
const verinEvidence = require("./verin/evidence/ingest");
exports.ingestEvidence = verinEvidence.ingestEvidence;
exports.onReceiptCreated = verinEvidence.onReceiptCreated;
exports.reprocessReceipt = verinEvidence.reprocessReceipt;

const verinArchive = require("./verin/export/archive");
exports.exportRecordZip = verinArchive.exportRecordZip;
exports.exportFirmData = verinArchive.exportFirmData;
exports.exportIntegrationReport = verinArchive.exportIntegrationReport;

// ---- Verin: client email and text intake (SendGrid / Postmark, Twilio) ----
// Off until the intake secrets exist (INBOUND_WEBHOOK_KEY, TWILIO_AUTH_TOKEN):
// set INTAKE_ENABLED=true in .env, then deploy. See DEPLOYMENT.md.
if (process.env.INTAKE_ENABLED === "true") {
  const verinIntake = require("./verin/intake/functions");
  exports.inboundEmail = verinIntake.inboundEmail;
  exports.inboundSms = verinIntake.inboundSms;
  exports.onInboundEvent = verinIntake.onInboundEvent;
  exports.onMatterIntake = verinIntake.onMatterIntake;
  exports.provisionIntake = verinIntake.provisionIntake;
  exports.approveQuarantined = verinIntake.approveQuarantined;
  exports.assignUnrouted = verinIntake.assignUnrouted;
}

// ---- Verin: NFR demo workspace ----
exports.seedDemoWorkspace = require("./verin/demo/seed").seedDemoWorkspace;
exports.demoSimulateArrival = require("./verin/demo/seed").demoSimulateArrival;
