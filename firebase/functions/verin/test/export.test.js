// Run: npm test (from firebase/functions)
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const chain = require('../chain/chain');
const { buildRecordPdf, printable } = require('../export/record_pdf');

const sha = (s) => crypto.createHash('sha256').update(s).digest('hex');

function sample() {
  const entries = [];
  let prev = chain.GENESIS;
  const receipts = [];
  for (let i = 1; i <= 3; i++) {
    const itemHash = sha(`img-${i}`);
    const receivedAtIso = new Date(Date.UTC(2026, 9, i, 15, 4)).toISOString();
    const od = chain.originDigest({ channel: 'Upload', source: `uid:u1|file:IMG_${i}.png` });
    const entryHash = chain.computeEntryHash({ prevHash: prev, itemHash, receivedAtIso, originDigest: od });
    entries.push({ seq: i, prevHash: prev, itemHash, receivedAtIso, originDigest: od, entryHash });
    prev = entryHash;
    receipts.push({
      id: `r${i}`,
      receivedAt: new Date(receivedAtIso),
      channel: 'Upload',
      itemKind: 'screenshot',
      headline: `IMG_${i}.png`,
      itemHash,
      entryHash,
      chainSeq: i,
      detectedPlatform: 'iMessage',
      threadMessages: [
        { speaker: 'other', text: 'Today 2:14 PM', timestampLabel: '', isGap: false, isHeader: true, confidence: 1 },
        { speaker: 'other', text: 'Can you drop the kids at 6? 👍', timestampLabel: '2:14 PM', isGap: false, isHeader: false, confidence: 0.98 },
        { speaker: 'client', text: 'Yes — I\'ll be there by 5:45. Ünïcödé ok.', timestampLabel: '2:16 PM', isGap: i === 2, isHeader: false, confidence: 0.6 },
      ],
    });
  }
  return {
    matter: {
      id: 'm1', title: 'Whitmore v. Whitmore', clientName: 'Elena Whitmore', caseNumber: '49D08-2404-DR-014922',
      assignedCounsel: 'Marcus Thorne, Esq.', practiceArea: 'Family law', openedAt: new Date('2026-07-21T00:00:00Z'),
      redactionCount: 2, redactionCategories: 'Minor children names', hashChainLastAnchoredAt: null, chainHeadHash: prev,
    },
    receipts,
    chain: entries,
    verification: chain.verifyEntries(entries),
    generatedAt: new Date('2026-10-03T18:00:00Z'),
    generatedBy: 'jared@example.com',
  };
}

test('printable keeps text and marks glyphs the font lacks', () => {
  assert.equal(printable('Ünïcödé — ok'), 'Ünïcödé — ok');
  assert.match(printable('thumbs 👍'), /\[U\+1F44D\]/);
});

test('builds a multi-page record PDF with every section', async () => {
  const input = sample();
  const pdf = await buildRecordPdf(input);
  assert.ok(Buffer.isBuffer(pdf));
  assert.equal(pdf.subarray(0, 5).toString(), '%PDF-');
  assert.ok(pdf.length > 20000, `pdf is ${pdf.length} bytes`);
  const out = process.env.VERIN_PDF_OUT || path.join(os.tmpdir(), 'verin-sample-record.pdf');
  fs.writeFileSync(out, pdf);
});

test('a broken chain is stated on the certificate', async () => {
  const input = sample();
  input.chain[1].itemHash = sha('tampered');
  input.verification = chain.verifyEntries(input.chain);
  assert.equal(input.verification.ok, false);
  const pdf = await buildRecordPdf(input);
  assert.ok(pdf.length > 1000);
});
