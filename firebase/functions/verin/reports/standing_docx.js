// Verin Legal — the live Standing Record as a Word document (A1, checklist #69).
// (The chronology already exports to Excel from the Thread tab.)
//
// Status, Record Lag, review queue, open requests, issues, the assembled
// chronology with each line's source exhibit, and the integrity appendix.
// Editable by design: the firm's own work product starts from it.

const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall } = require('firebase-functions/v2/https');
const { requireAuth, loadMatterForUser } = require('../common/access');
const { verifyEntries } = require('../chain/chain');
const M = require('./metrics');
const { saveReport, stampOf, slug } = require('./store');

const headline = (r) => String(r.content || r.description || r.originalFileName || 'Item').split('\n')[0].slice(0, 140);
const day = (d) => (d ? d.toISOString().slice(0, 10) : '—');

async function buildStandingDocx({ matter, receipts, thread, followUps, chain, generatedAt }) {
  const D = require('docx');
  const { Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell, WidthType, AlignmentType } = D;
  const p = (text, opts = {}) => new Paragraph({ children: [new TextRun({ text: String(text ?? ''), ...opts })], spacing: { after: 80 } });
  const h = (text, level = HeadingLevel.HEADING_2) => new Paragraph({ text, heading: level, spacing: { before: 240, after: 120 } });
  const table = (head, rows, widths) =>
    new Table({
      width: { size: 100, type: WidthType.PERCENTAGE },
      rows: [
        new TableRow({ tableHeader: true, children: head.map((t, i) => new TableCell({ width: { size: widths[i], type: WidthType.PERCENTAGE }, children: [p(t, { bold: true, size: 18 })] })) }),
        ...rows.map((r) => new TableRow({ children: r.map((t, i) => new TableCell({ width: { size: widths[i], type: WidthType.PERCENTAGE }, children: [p(t, { size: 18 })] })) })),
      ],
    });

  const order = new Map(receipts.slice().sort((a, b) => (M.toDate(a.receivedAt) || 0) - (M.toDate(b.receivedAt) || 0)).map((r, i) => [r._id, i + 1]));
  const lag = M.median(M.recordLagDays(receipts));
  const review = receipts.filter((r) => ['Uncertain', 'Quarantined'].includes(r.classificationLabel) || r.isQuarantined === true);
  const stats = (thread && thread.stats) || {};
  const sinceIso = matter.lastStandingExportAt ? M.toDate(matter.lastStandingExportAt) : null;
  const newSince = sinceIso ? receipts.filter((r) => (M.toDate(r.receivedAt) || 0) > sinceIso) : [];
  const ver = verifyEntries(chain.slice().sort((a, b) => (a.seq || 0) - (b.seq || 0)));

  const msgs = ((thread && thread.entries) || []).filter((e) => e.kind === 'msg' || e.kind === 'gap');
  const children = [
    new Paragraph({ children: [new TextRun({ text: 'VERIN · STANDING RECORD', bold: true, color: '0E6E7D', size: 18 })] }),
    new Paragraph({ text: matter.matterName || matter.caseTitle || 'Matter', heading: HeadingLevel.TITLE }),
    p(`${matter.clientName || ''}${matter.caseNumber ? ` · ${matter.caseNumber}` : ''} · as of ${generatedAt.toISOString().slice(0, 16).replace('T', ' ')} UTC`, { color: '5C6A6E' }),
    h('Status'),
    table(
      ['Items', 'Messages assembled', 'Needs a person', 'Gaps', 'Record Lag (median)'],
      [[String(receipts.length), String(stats.messages || 0), String(review.length), String(stats.gaps || 0), lag === null ? '—' : `${lag} days`]],
      [16, 22, 20, 14, 28],
    ),
    ...(sinceIso ? [p(`New since the last export (${day(sinceIso)}): ${newSince.length} item${newSince.length === 1 ? '' : 's'}.`)] : []),
    h('Waiting for a person'),
    ...(review.length ? review.map((r) => p(`Exhibit ${order.get(r._id)} — ${headline(r)}${r.reviewReason ? `: ${r.reviewReason}` : ''}`)) : [p('Nothing waiting.')]),
    h('Open requests to the client'),
    ...(followUps.filter((f) => f.status === 'sent').length
      ? followUps.filter((f) => f.status === 'sent').map((f) => p(String(f.title || f.text || f.message || 'Request')))
      : [p('None open.')]),
    h('Issues to check'),
    ...((thread && thread.notes) || []).map((n) => p(n)),
    h('Chronology'),
    p('Each line cites the exhibit it was read from. The originals are the record; this text is a reading aid.', { italics: true, color: '5C6A6E', size: 18 }),
    table(
      ['Date', 'Time', 'Who', 'Message', 'Exhibit'],
      msgs.map((e) =>
        e.kind === 'gap'
          ? ['', '', '', '— continuity not established here —', '']
          : [e.date || 'undated', e.time || e.timeOnly || '', e.person || (e.speaker === 'client' ? 'Client' : 'Other'), e.text || '', e.rid && order.get(e.rid) ? `#${order.get(e.rid)}` : ''],
      ),
      [13, 9, 16, 52, 10],
    ),
    h('Exhibits'),
    table(
      ['#', 'Received', 'Item', 'Item date', 'SHA-256'],
      receipts
        .slice()
        .sort((a, b) => order.get(a._id) - order.get(b._id))
        .map((r) => [String(order.get(r._id)), day(M.toDate(r.receivedAt)), headline(r), M.toDate(r.resolvedDate) ? `${day(M.toDate(r.resolvedDate))}${r.dateSource ? ` (${String(r.dateSource).replace(/_/g, ' ')})` : ''}` : 'no date in item', r.item_hash || '']),
      [6, 14, 34, 18, 28],
    ),
    h('Integrity appendix'),
    p(`Hash chain: ${chain.length} entries, ${ver.ok ? 'intact when this document was generated' : `does not verify at entry #${ver.brokenAt}`}.`),
    p(`Chain head: ${matter.chainHeadHash || ver.head || '—'}`, { font: 'Consolas', size: 16 }),
    p('entry_hash = SHA256(prev_hash | item_hash | received_at | origin_digest). The record ZIP includes verify.py to check every file and link offline.', { size: 16, color: '5C6A6E' }),
    new Paragraph({
      alignment: AlignmentType.LEFT,
      spacing: { before: 240 },
      children: [new TextRun({ text: 'Generated by software from the stored record. Verin does not practice law. No opinion on authenticity, completeness or admissibility is offered or implied.', size: 16, color: '5C6A6E' })],
    }),
  ];
  const doc = new Document({ creator: 'Verin Legal', title: `Standing Record — ${matter.matterName || ''}`, sections: [{ children }] });
  return Packer.toBuffer(doc);
}

exports.exportStandingRecordDocx = onCall({ timeoutSeconds: 180, memory: '1GiB' }, async (request) => {
  const uid = requireAuth(request);
  const db = getFirestore();
  const { ref, snap, firmId } = await loadMatterForUser(db, uid, (request.data || {}).matterId);
  const [rs, t, fu, ch] = await Promise.all([
    db.collection('Receipts').where('matterId', '==', ref).get(),
    ref.collection('derived').doc('thread').get(),
    db.collection('FollowUps').where('matterId', '==', ref).get(),
    db.collection('chainEntries').where('matterID', '==', ref).get(),
  ]);
  const generatedAt = new Date();
  const matter = snap.data() || {};
  const bytes = await buildStandingDocx({
    matter,
    receipts: rs.docs.map((d) => ({ _id: d.id, ...d.data() })),
    thread: t.exists ? t.data() : null,
    followUps: fu.docs.map((d) => d.data()),
    chain: ch.docs.map((d) => d.data()),
    generatedAt,
  });
  const fileName = `${slug(matter.matterName || ref.id)}-standing-record-${stampOf(generatedAt)}.docx`;
  const saved = await saveReport({ db, bucket: getStorage().bucket(), firmId, storagePath: `matters/${ref.id}/exports/${fileName}`, bytes, contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', fileName, uid, kind: 'standing_record_docx', extra: { matterId: ref.id } });
  await ref.set({ lastStandingExportAt: generatedAt }, { merge: true });
  return saved;
});

exports._internal = { buildStandingDocx };
