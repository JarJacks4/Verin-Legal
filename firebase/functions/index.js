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
exports.summarizeThread = require("./verin/thread/summary").summarizeThread;

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

// Delivery to the firm's system, then removal of Verin's copy (#16).
const verinDelivery = require("./verin/export/delivery");
exports.deliverMatterRecord = verinDelivery.deliverMatterRecord;
exports.confirmDelivery = verinDelivery.confirmDelivery;
exports.autoDeliverToClio = verinDelivery.autoDeliverToClio;

// The firm's own pre-Verin Record Lag (#23); Clio capture runs on connect.
exports.setBaselineRecordLag = require("./verin/baseline/record_lag").setBaselineRecordLag;

// Closed-matter import and the demo counts (#4).
const verinArchiveBuild = require("./verin/archive/import");
exports.importClosedMatter = verinArchiveBuild.importClosedMatter;
exports.standingRecordCounts = verinArchiveBuild.standingRecordCounts;

// Reports (#27, #53, #67, #69, #70, #71, #74) and demo deletion (#9).
exports.exportRecordLagAudit = require("./verin/reports/lag_audit").exportRecordLagAudit;
exports.exportPracticePacket = require("./verin/reports/packets").exportPracticePacket;
const verinDigest = require("./verin/reports/digest");
exports.buildMatterDigest = verinDigest.buildMatterDigest;
exports.weeklyMatterDigests = verinDigest.weeklyMatterDigests;
const verinMonthly = require("./verin/reports/firm_report");
exports.exportFirmMonthlyReport = verinMonthly.exportFirmMonthlyReport;
exports.monthlyFirmReports = verinMonthly.monthlyFirmReports;
exports.exportStandingRecordDocx = require("./verin/reports/standing_docx").exportStandingRecordDocx;
const verinDemoOps = require("./verin/reports/demo_ops");
exports.deleteDemoMatter = verinDemoOps.deleteDemoMatter;
exports.weeklyCostToServe = verinDemoOps.weeklyCostToServe;
exports.costToServeNow = verinDemoOps.costToServeNow;

// Nightly backup of system and audit data (#31).
exports.nightlyFirestoreBackup = require("./verin/ops/backup").nightlyFirestoreBackup;

// PracticePanther and Filevine (switched on in .env once API access is granted).
const verinPractice = require("./verin/practice/functions");
exports.practiceAvailability = verinPractice.practiceAvailability;
exports.practicePantherAuthStart = verinPractice.practicePantherAuthStart;
exports.practicePantherOAuthCallback = verinPractice.practicePantherOAuthCallback;
exports.filevineConnect = verinPractice.filevineConnect;
exports.practiceDisconnect = verinPractice.practiceDisconnect;
exports.practiceSearchMatters = verinPractice.practiceSearchMatters;
exports.practiceLinkMatter = verinPractice.practiceLinkMatter;
exports.practicePushDocument = verinPractice.practicePushDocument;

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
}

// Review queue actions on held items (approve an unknown sender, file a text
// from an unknown number). No intake secrets, so always deployed — the demo
// workspace uses them even while live intake is off.
const verinReview = require("./verin/intake/review");
exports.approveQuarantined = verinReview.approveQuarantined;
exports.assignUnrouted = verinReview.assignUnrouted;

// ---- Verin: NFR demo workspace ----
exports.seedDemoWorkspace = require("./verin/demo/seed").seedDemoWorkspace;
exports.demoSimulateArrival = require("./verin/demo/seed").demoSimulateArrival;
