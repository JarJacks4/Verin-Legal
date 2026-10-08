// Verin Legal — weekly matter digest (A2, checklist #70).
//
// One page per active matter each Monday: what arrived this week, what needs
// a person, Record Lag, open requests to the client, upcoming hearings. It is
// written back to the matter (Clio, when linked) and kept in Verin; when the
// matter names a responsible attorney's email and the firm allows it, it is
// emailed too.

const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { requireAuth, loadMatterForUser } = require('../common/access');
const { emailSecrets } = require('../common/mail_secrets');
const { sendMail } = require('../common/mailer');
const M = require('./metrics');
const { createReport, day } = require('./pdf');
const { saveReport, stampOf, slug } = require('./store');

const WEEK = 7 * M.DAY;
const headline = (r) => String(r.content || r.description || r.originalFileName || 'Item').split('\n')[0].slice(0, 120);

/// Pure: the digest's numbers for one matter.
function digestFigures({ matter, receipts, followUps, now = new Date() }) {
  const since = new Date(now.getTime() - WEEK);
  const recent = receipts.filter((r) => {
    const t = M.toDate(r.receivedAt);
    return t && t >= since;
  });
  const byChannel = {};
  for (const r of recent) byChannel[r.channel || 'Other'] = (byChannel[r.channel || 'Other'] || 0) + 1;
  const review = receipts.filter((r) => ['Uncertain', 'Quarantined'].includes(r.classificationLabel) || r.isQuarantined === true);
  const lagAll = M.median(M.recordLagDays(receipts));
  const lagWeek = M.median(M.recordLagDays(recent));
  const upcoming = (matter.hearings || [])
    .map((h) => ({ ...h, at: M.toDate(h.at) }))
    .filter((h) => h.at && h.at >= now && h.at <= new Date(now.getTime() + 30 * M.DAY))
    .sort((a, b) => a.at - b.at);
  return { since, recent, byChannel, review, lagAll, lagWeek, upcoming, openRequests: followUps.filter((f) => f.status === 'sent') };
}

async function buildDigestPdf({ matter, figures, generatedAt }) {
  const f = figures;
  const title = matter.matterName || matter.caseTitle || 'Matter';
  const R = createReport({
    title: 'Weekly matter digest',
    subtitle: `${title} · week of ${day(f.since)} to ${day(generatedAt)}`,
    footer: `Verin weekly digest · ${title} · ${generatedAt.toISOString()}`,
  });
  R.tiles([
    { label: 'New this week', value: String(f.recent.length), note: Object.entries(f.byChannel).map(([k, v]) => `${v} ${k}`).join(' · ') || 'nothing new' },
    { label: 'Needs a person', value: String(f.review.length), note: 'review queue' },
    { label: 'Record Lag (matter)', value: f.lagAll === null ? '—' : `${f.lagAll} d`, note: f.lagWeek === null ? 'no dated items this week' : `this week ${f.lagWeek} d` },
    { label: 'Open requests', value: String(f.openRequests.length), note: 'sent to the client' },
  ]);
  R.heading('Arrived this week', 12.5);
  if (!f.recent.length) R.para('Nothing new arrived this week.', { muted: true });
  for (const r of f.recent.slice(0, 25)) R.bullet(`${day(M.toDate(r.receivedAt))} · ${r.channel || ''} · ${headline(r)}${r.classificationLabel === 'Uncertain' ? ' (needs review)' : ''}`);
  if (f.recent.length > 25) R.para(`…and ${f.recent.length - 25} more in Verin.`, { muted: true, size: 9 });
  if (f.review.length) {
    R.heading('Waiting for a person', 12.5);
    for (const r of f.review.slice(0, 10)) R.bullet(`${headline(r)}${r.reviewReason ? ` — ${r.reviewReason}` : ''}`);
  }
  if (f.upcoming.length) {
    R.heading('Coming up (30 days)', 12.5);
    for (const h of f.upcoming) R.bullet(`${day(h.at)} · ${h.title || 'Hearing'}`);
  }
  if (f.openRequests.length) {
    R.heading('Requests still open with the client', 12.5);
    for (const q of f.openRequests.slice(0, 10)) R.bullet(String(q.title || q.text || q.message || 'Request').slice(0, 160));
  }
  return R.finish();
}

async function digestForMatter({ db, bucket, ref, matter, firm, now, uid, clio }) {
  const [rs, fu] = await Promise.all([db.collection('Receipts').where('matterId', '==', ref).get(), db.collection('FollowUps').where('matterId', '==', ref).get()]);
  const figures = digestFigures({ matter, receipts: rs.docs.map((d) => d.data()), followUps: fu.docs.map((d) => d.data()), now });
  const pdf = await buildDigestPdf({ matter, figures, generatedAt: now });
  const fileName = `${slug(matter.matterName || ref.id)}-weekly-digest-${stampOf(now)}.pdf`;
  const storagePath = `matters/${ref.id}/digests/${fileName}`;
  const saved = await saveReport({ db, bucket, firmId: null, storagePath, bytes: pdf, contentType: 'application/pdf', fileName, uid, kind: 'weekly_digest' });
  const result = { ...saved, newItems: figures.recent.length, review: figures.review.length, writtenBack: false, emailed: false };

  const clioMatterId = matter.clioMatterID || matter.providerMatterReference;
  if (clio && clioMatterId && matter.demo !== true) {
    try {
      const up = await clio.sessionFor(matter.firmID).uploadDocument({ clioMatterId, name: fileName, bytes: pdf, contentType: 'application/pdf' });
      result.writtenBack = true;
      result.clioDocumentId = up.id;
    } catch (e) {
      result.writeBackError = String(e.message || e).slice(0, 300);
    }
  }
  const to = matter.digestEmail || matter.responsibleAttorneyEmail || '';
  if (to && firm.digestEmails !== false && matter.demo !== true) {
    const r = await sendMail({
      to,
      subject: `Weekly digest: ${matter.matterName || 'matter'} — ${figures.recent.length} new, ${figures.review.length} to review`,
      text: [
        `${matter.matterName || 'Matter'} — week ending ${day(now)}`,
        `New items: ${figures.recent.length}`,
        `Waiting for a person: ${figures.review.length}`,
        `Record Lag (median): ${figures.lagAll === null ? '—' : `${figures.lagAll} days`}`,
        '',
        `The one-page digest: ${saved.downloadUrl}`,
      ].join('\n'),
    }).catch((e) => ({ sent: false, reason: e.message }));
    result.emailed = !!r.sent;
  }
  await ref.collection('digests').add({ ...result, generatedAt: FieldValue.serverTimestamp() });
  return result;
}

exports.buildMatterDigest = onCall({ secrets: require('../clio/functions')._clio.CLIO_SECRETS.concat(emailSecrets()), timeoutSeconds: 120, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, (request.data || {}).matterId);
  const firmSnap = await db.collection('firmAccount').where('firmID', '==', firmId).limit(1).get();
  const writeBack = (request.data || {}).writeBack === true;
  return digestForMatter({ db, bucket: getStorage().bucket(), ref, matter: snap.data() || {}, firm: firmSnap.empty ? {} : firmSnap.docs[0].data(), now: new Date(), uid, clio: writeBack ? require('../clio/functions')._clio : null });
});

exports.weeklyMatterDigests = onSchedule(
  { schedule: 'every monday 07:00', timeZone: 'America/Indiana/Indianapolis', secrets: require('../clio/functions')._clio.CLIO_SECRETS.concat(emailSecrets()), timeoutSeconds: 540, memory: '1GiB' },
  async () => {
    const db = getFirestore();
    const bucket = getStorage().bucket();
    const now = new Date();
    const clio = require('../clio/functions')._clio;
    const firms = await db.collection('firmAccount').get();
    for (const f of firms.docs) {
      const firm = f.data() || {};
      if (firm.isDemo === true || firm.weeklyDigests === false || !firm.firmID) continue;
      const matters = await db.collection('Matters').where('firmID', '==', firm.firmID).get();
      for (const m of matters.docs) {
        const md = m.data() || {};
        if (String(md.status || 'Open') === 'Closed') continue;
        try {
          await digestForMatter({ db, bucket, ref: m.ref, matter: md, firm, now, uid: 'system', clio });
        } catch (e) {
          console.error('weekly digest failed', m.id, e.message);
        }
      }
    }
  },
);

exports._internal = { digestFigures, buildDigestPdf };
