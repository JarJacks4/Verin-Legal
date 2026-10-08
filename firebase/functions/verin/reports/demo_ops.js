// Verin Legal — demo operations.
//
//   deleteDemoMatter     (#9) After a demo on a firm's closed matter: deletes
//                        everything Verin holds for that matter (items, files,
//                        chain, notes, exports) and emails the firm a deletion
//                        confirmation. Only in an NFR demo workspace. What is
//                        kept: a deletion log with counts and times — no content.
//   weeklyCostToServe    (#53) Cost per active matter, per firm, every Monday,
//                        from the four levers: AI reading, messaging, storage,
//                        and delivery/processing runs. Rates are settings.

const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineString } = require('firebase-functions/params');
const { requireAuth, requireAdmin, loadMatterForUser } = require('../common/access');
const { emailSecrets } = require('../common/mail_secrets');
const { sendMail } = require('../common/mailer');
const { firmData, firmDocRef } = require('../common/firm');
const M = require('./metrics');

// $ per million tokens / per message / per GB-month (override in .env).
const RATES = {
  AI_INPUT_PER_MTOK: defineString('COST_AI_INPUT_PER_MTOK', { default: '3' }),
  AI_OUTPUT_PER_MTOK: defineString('COST_AI_OUTPUT_PER_MTOK', { default: '15' }),
  SMS_PER_MESSAGE: defineString('COST_SMS_PER_MESSAGE', { default: '0.0083' }),
  EMAIL_PER_MESSAGE: defineString('COST_EMAIL_PER_MESSAGE', { default: '0.0012' }),
  STORAGE_PER_GB_MONTH: defineString('COST_STORAGE_PER_GB_MONTH', { default: '0.026' }),
};
const RATE_DEFAULTS = { AI_INPUT_PER_MTOK: 3, AI_OUTPUT_PER_MTOK: 15, SMS_PER_MESSAGE: 0.0083, EMAIL_PER_MESSAGE: 0.0012, STORAGE_PER_GB_MONTH: 0.026 };
const rate = (k) => {
  let v = '';
  try {
    v = RATES[k].value();
  } catch (_) {
    /* outside the functions runtime */
  }
  const n = Number(v);
  return v !== '' && Number.isFinite(n) ? n : RATE_DEFAULTS[k];
};

exports.deleteDemoMatter = onCall({ secrets: emailSecrets(), timeoutSeconds: 540, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const data = request.data || {};
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, data.matterId);
  const firm = await firmData(db, firmId);
  if (firm.isDemo !== true) throw new HttpsError('failed-precondition', 'Only matters in an NFR demo workspace can be deleted this way.');
  const md = snap.data() || {};
  const counts = { items: 0, files: 0, chain: 0, notes: 0 };

  const receipts = await db.collection('Receipts').where('matterId', '==', ref).get();
  counts.items = receipts.size;
  const [files] = await bucket.getFiles({ prefix: `matters/${ref.id}/` });
  for (const f of files) {
    await f.delete({ ignoreNotFound: true }).catch(() => {});
    counts.files++;
  }
  const writer = db.bulkWriter();
  for (const d of receipts.docs) writer.delete(d.ref);
  for (const col of ['chainEntries']) {
    const s = await db.collection(col).where('matterID', '==', ref).get();
    counts.chain += s.size;
    s.docs.forEach((d) => writer.delete(d.ref));
  }
  for (const col of ['Annotations', 'Corrections', 'FollowUps', 'Activity']) {
    const s = await db.collection(col).where('matterId', '==', ref).get();
    counts.notes += s.size;
    s.docs.forEach((d) => writer.delete(d.ref));
  }
  const addrs = await db.collection('intakeAddresses').where('matterRef', '==', ref).get();
  addrs.docs.forEach((d) => writer.delete(d.ref));
  await writer.close();
  await db.recursiveDelete(ref);

  const deletedAt = new Date();
  const logRef = await (await firmDocRef(db, firmId)).collection('demoDeletions').add({
    matterName: md.matterName || md.caseTitle || '',
    prospect: String(data.prospect || '').slice(0, 200),
    ...counts,
    deletedByUid: uid,
    deletedAt: FieldValue.serverTimestamp(),
  });
  const to = String(data.confirmTo || '').trim();
  const text = [
    `Verin Legal — deletion confirmation`,
    '',
    `The material your firm provided for the demonstration${data.prospect ? ` (${data.prospect})` : ''}, "${md.matterName || 'demo matter'}", was deleted from Verin on ${deletedAt.toUTCString()}.`,
    `Deleted: ${counts.items} item${counts.items === 1 ? '' : 's'}, ${counts.files} stored file${counts.files === 1 ? '' : 's'}, ${counts.chain} chain entr${counts.chain === 1 ? 'y' : 'ies'}, ${counts.notes} note${counts.notes === 1 ? '' : 's'}.`,
    'Verin keeps only this confirmation record (counts and times), not the material itself.',
    '',
    `Reference: ${logRef.id}`,
  ].join('\n');
  let emailed = false;
  if (to) {
    const r = await sendMail({ to, subject: 'Verin Legal — your demo material has been deleted', text }).catch((e) => ({ sent: false, reason: e.message }));
    emailed = !!r.sent;
  }
  await logRef.set({ confirmationTo: to, emailed }, { merge: true });
  return { ...counts, reference: logRef.id, emailed, confirmationText: text };
});

/// Pure: one firm's week.
function costFigures({ receipts, aiUsage, now = new Date() }) {
  const since = new Date(now.getTime() - 7 * M.DAY);
  const recent = receipts.filter((r) => (M.toDate(r.receivedAt) || 0) >= since);
  const active = new Set(recent.map((r) => (r.matterId && r.matterId.id) || r.matterId || '')).size;
  let inTok = 0;
  let outTok = 0;
  for (const r of recent) {
    const u = (r.ai && r.ai.usage) || null;
    if (u) {
      inTok += u.inputTokens || 0;
      outTok += u.outputTokens || 0;
    }
  }
  for (const u of aiUsage) {
    if ((M.toDate(u.at) || 0) < since || !u.usage) continue;
    inTok += u.usage.inputTokens || 0;
    outTok += u.usage.outputTokens || 0;
  }
  const sms = recent.filter((r) => ['sms', 'whatsapp', 'mms'].includes(String(r.channelKey || '').toLowerCase())).length;
  const emails = recent.filter((r) => String(r.channelKey || '') === 'email' && !r.parentReceiptId).length;
  const storedBytes = receipts.filter((r) => !r.originalDeletedAt).reduce((n, r) => n + (Number(r.sizeBytes) || 0), 0);
  const ai = (inTok / 1e6) * rate('AI_INPUT_PER_MTOK') + (outTok / 1e6) * rate('AI_OUTPUT_PER_MTOK');
  const messaging = sms * rate('SMS_PER_MESSAGE') + emails * rate('EMAIL_PER_MESSAGE');
  const storage = (storedBytes / 1e9) * rate('STORAGE_PER_GB_MONTH') * (7 / 30);
  const total = ai + messaging + storage;
  const r2 = (x) => Math.round(x * 100) / 100;
  return {
    weekStart: since.toISOString().slice(0, 10),
    activeMatters: active,
    items: recent.length,
    levers: { ai: r2(ai), messaging: r2(messaging), storage: r2(storage), itemsProcessed: recent.length },
    tokens: { input: inTok, output: outTok },
    sms,
    emails,
    storedGB: Math.round((storedBytes / 1e9) * 1000) / 1000,
    total: r2(total),
    perActiveMatter: active ? r2(total / active) : null,
  };
}

exports.weeklyCostToServe = onSchedule({ schedule: 'every monday 06:00', timeZone: 'America/Indiana/Indianapolis', timeoutSeconds: 540, memory: '1GiB' }, async () => {
  const db = getFirestore();
  const firms = await db.collection('firmAccount').get();
  for (const f of firms.docs) {
    const firm = f.data() || {};
    if (!firm.firmID) continue;
    try {
      const receipts = (await db.collection('Receipts').where('firmID', '==', firm.firmID).get()).docs.map((d) => d.data());
      const aiUsage = (await db.collectionGroup('aiUsage').where('firmID', '==', firm.firmID).get()).docs.map((d) => d.data());
      const c = costFigures({ receipts, aiUsage });
      await db.collection('costReports').doc(`${firm.firmID}_${c.weekStart}`).set({ firmID: firm.firmID, firmName: firm.firmName || '', isDemo: firm.isDemo === true, ...c, at: FieldValue.serverTimestamp() });
    } catch (e) {
      console.error('cost report failed', firm.firmID, e.message);
    }
  }
});

/// On demand, for the caller's own firm (admins).
exports.costToServeNow = onCall(async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { firmId } = await requireAdmin(db, uid);
  const receipts = (await db.collection('Receipts').where('firmID', '==', firmId).get()).docs.map((d) => d.data());
  const aiUsage = (await db.collectionGroup('aiUsage').where('firmID', '==', firmId).get()).docs.map((d) => d.data());
  return costFigures({ receipts, aiUsage });
});

exports._internal = { costFigures };
