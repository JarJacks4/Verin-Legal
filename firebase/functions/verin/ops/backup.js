// Verin Legal — nightly backup of system and audit data (checklist #31).
//
// Exports every Firestore collection (records, hashes, chain, audit logs,
// settings — never client files, which live in Storage and are delivered to
// the firm) to a separate bucket. Restore steps are in DEPLOYMENT.md.
//
//   BACKUP_BUCKET   e.g. verin-legal-fbzp5w-backups (empty = off)

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineString } = require('firebase-functions/params');

const BACKUP_BUCKET = defineString('BACKUP_BUCKET', { default: '' });

exports.nightlyFirestoreBackup = onSchedule({ schedule: 'every day 03:15', timeZone: 'America/Indiana/Indianapolis', timeoutSeconds: 300 }, async () => {
  const bucket = String(BACKUP_BUCKET.value() || '').replace(/^gs:\/\//, '').trim();
  if (!bucket) {
    console.log('nightlyFirestoreBackup: BACKUP_BUCKET is not set; skipped');
    return;
  }
  const { v1 } = require('@google-cloud/firestore');
  const client = new v1.FirestoreAdminClient();
  const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
  const stamp = new Date().toISOString().slice(0, 10);
  const [op] = await client.exportDocuments({
    name: client.databasePath(project, '(default)'),
    outputUriPrefix: `gs://${bucket}/firestore/${stamp}`,
    collectionIds: [],
  });
  console.log('nightlyFirestoreBackup started', op.name);
});
