// Files a text or WhatsApp message (and the photos already copied into
// storage) into a matter as receipts. No intake secrets: shared by onInboundEvent and the
// Review queue's "File to matter".

const N = require('./normalize');
const { fileInboundItem } = require('./file');

async function fileSmsInto(db, bucket, { eventId, matterRef, from, to, body, sid, at, media, known, channel = 'sms' }) {
  const filed = [];
  const wa = channel === 'whatsapp';
  const noun = wa ? 'WhatsApp' : 'Text';
  const fromLabel = `${noun} from ${from}`;
  const common = {
    db,
    bucket,
    matterRef,
    channelKey: wa ? 'whatsapp' : 'sms',
    fromLabel,
    senderKey: `tel:${from}`,
    quarantined: !known,
    reviewReason: known ? '' : `From ${from}, a number that isn't known on this matter. Approve to read it.`,
    receivedAt: at,
  };
  let parent = null;
  if (String(body || '').trim()) {
    const r = await fileInboundItem({
      ...common,
      buffer: Buffer.from(N.smsRecordText({ from, to, body, at: at.toISOString(), sid }), 'utf8'),
      fileName: `${noun} ${at.toISOString().slice(0, 16).replace('T', ' ')}.txt`,
      contentType: 'text/plain',
      kind: 'document',
      description: String(body).trim().slice(0, 300),
      source: `${wa ? 'whatsapp' : 'sms'}|from:${from}|to:${to}|sid:${sid}`,
      extra: { intakeEventId: eventId, smsBody: String(body).slice(0, 5000) },
    });
    parent = r.receiptId;
    filed.push(r.receiptId);
  }
  const bucketRef = bucket;
  for (let i = 0; i < media.length; i++) {
    const m = media[i];
    if (!m.path) continue;
    const [buf] = await bucketRef.file(m.path).download();
    const name = `${noun} photo ${at.toISOString().slice(0, 10)} ${i + 1}${N.extFor(m.contentType)}`;
    const r = await fileInboundItem({
      ...common,
      buffer: buf,
      fileName: name,
      contentType: m.contentType,
      kind: N.kindFor(m.contentType, name),
      description: String(body || '').trim() ? `Sent with: “${String(body).trim().slice(0, 120)}”` : wa ? 'WhatsApp media' : 'Picture message',
      source: `${wa ? 'whatsapp-media' : 'mms'}|from:${from}|to:${to}|sid:${sid}|n:${i + 1}`,
      extra: { intakeEventId: eventId, ...(parent ? { parentReceiptId: parent } : {}) },
    });
    filed.push(r.receiptId);
  }
  return filed;
}

module.exports = { fileSmsInto };
