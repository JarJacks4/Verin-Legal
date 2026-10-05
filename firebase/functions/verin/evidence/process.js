// Verin Legal — AI reading of a filed receipt (runs after ingest, and on
// "Run AI reading again" / "Request transcription").
//
// Reads the stored copy (never modifies it), produces reading aids — summary,
// evidence date, transcript, extracted messages — and decides whether the item
// is Processed or needs a person (Uncertain). Every run is recorded under
// Receipts/{id}/extractionRuns.

const crypto = require('crypto');

const { detectKind, extractText } = require('./docs');
const { analyzeWithClaude } = require('./analyze');
const video = require('./video');
const { kLowConfidence } = require('./constants');
const { imageSize } = require('./source');

// Text kept on the receipt so the verification view can show a passage in its
// context (Firestore documents cap at 1 MB; the original file is always kept).
const MAX_STORED_TEXT = 200000;

const MAX_IMAGE_BYTES = 7 * 1024 * 1024; // Claude base64 image limit, with headroom
const MAX_PDF_BYTES = 24 * 1024 * 1024; // keeps a single request under 32 MB

function imageMediaType(buf) {
  if (buf[0] === 0x89 && buf[1] === 0x50) return 'image/png';
  if (buf[0] === 0xff && buf[1] === 0xd8) return 'image/jpeg';
  if (buf.toString('ascii', 0, 4) === 'GIF8') return 'image/gif';
  if (buf.toString('ascii', 0, 4) === 'RIFF') return 'image/webp';
  return null;
}

async function readHead(file, n = 64) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    file
      .createReadStream({ start: 0, end: n - 1 })
      .on('data', (c) => chunks.push(c))
      .on('error', reject)
      .on('end', () => resolve(Buffer.concat(chunks)));
  });
}

/// Turns a successful Claude analysis into receipt fields.
function fieldsFromAnalysis(value, threadMessages) {
  const lowMsgs = threadMessages.filter((m) => !m.isHeader && m.confidence < kLowConfidence).length;
  const reasons = [];
  if (lowMsgs) reasons.push(`${lowMsgs} message${lowMsgs === 1 ? ' was' : 's were'} hard to read — check against the image.`);
  return {
    aiSummary: value.summary,
    resolvedDate: value.eventDate || null,
    dateConfidence: value.eventDate ? value.eventDateConfidence : '',
    dateSource: value.eventDate ? value.eventDateSource : '',
    threadMessages,
    detectedPlatform: threadMessages.length ? value.conversation.platform : '',
    evidenceType: value.evidenceType,
    statements: value.statements || [],
    sensitive: value.sensitive || [],
    classificationLabel: reasons.length ? 'Uncertain' : 'Processed',
    reviewReason: reasons.join(' '),
  };
}

/**
 * deps: { db, bucket, anthropic(), claudeModel, maxTokens, videoModel, project, location, serverTimestamp, Timestamp, log }
 * Returns { status, errors, fields } and writes the receipt.
 */
async function processReceipt(deps, receiptRef, { force = false, uid = null } = {}) {
  const { db, bucket, serverTimestamp, Timestamp } = deps;
  const log = deps.log || console;
  const snap = await receiptRef.get();
  if (!snap.exists) throw new Error('receipt not found');
  const r = snap.data();
  const kindFiled = r.itemKind || '';
  const clientSide = r.clientSide === 'left' ? 'left' : 'right';
  const storagePath = r.sourceStoragePath || '';
  const sourceUrl = r.sourceUrl || '';
  const fileName = r.originalFileName || '';

  const run = { uid, startedAt: new Date().toISOString(), storagePath, force };
  let fields = {};
  let status = 'extracted';
  let errors = [];
  let audit = {};

  const finish = async () => {
    const toTs = (d) => (d instanceof Date ? Timestamp.fromDate(d) : d);
    const write = {
      ...fields,
      resolvedDate: fields.resolvedDate === undefined ? r.resolvedDate || null : toTs(fields.resolvedDate),
      extractionState: status,
      extractionErrors: errors,
      extractedAt: serverTimestamp(),
    };
    if (write.resolvedDate === null) delete write.resolvedDate;
    const batch = db.batch();
    batch.set(receiptRef, write, { merge: true });
    batch.set(receiptRef.collection('extractionRuns').doc(), {
      ...run,
      ...audit,
      status,
      errors,
      messageCount: Array.isArray(fields.threadMessages) ? fields.threadMessages.length : 0,
      createdAt: serverTimestamp(),
    });
    await batch.commit();
    if (status === 'extraction_failed') log.warn('evidence reading failed', receiptRef.id, errors);
    return { status, errors, fields: write };
  };

  if (kindFiled === 'physical' || !storagePath) {
    status = 'not_applicable';
    fields = { classificationLabel: r.classificationLabel || 'Processed' };
    return finish();
  }

  const file = bucket.file(storagePath);
  const [exists] = await file.exists();
  if (!exists) {
    status = 'extraction_failed';
    errors = [`the stored file is missing (${storagePath})`];
    fields = { classificationLabel: 'Uncertain', reviewReason: 'The stored file could not be found.' };
    return finish();
  }
  const [meta] = await file.getMetadata();
  const size = Number(meta.size || 0);
  const head = await readHead(file, 64);
  const kind = detectKind(head, fileName, r.contentType || meta.contentType);
  run.detectedKind = kind;

  const fail = (msg, reason) => {
    status = 'extraction_failed';
    errors = Array.isArray(msg) ? msg : [msg];
    fields = { classificationLabel: 'Uncertain', reviewReason: reason || 'AI reading failed — open the file and review it by hand.' };
    return finish();
  };

  // ---------------------------------------------------------------- video / audio
  if (kind === 'video' || kind === 'audio') {
    const probe = await (deps.probeMedia || video.probeMedia)(sourceUrl);
    run.probe = probe.ok ? { ...probe, raw: undefined } : { error: probe.error };
    if (probe.ok) {
      try {
        await bucket.file(`${storagePath}.probe.json`).save(JSON.stringify(probe.raw, null, 2), { resumable: false, contentType: 'application/json' });
      } catch (e) {
        log.warn('probe save failed', e.message);
      }
    }
    const fidelity = r.originFidelity || video.originFidelityFor(r.channelKey || r.channel);
    const duration = probe.ok ? probe.durationSeconds : Number(r.durationSeconds || 0);
    const hasAudio = probe.ok ? probe.hasAudio : true;
    const receivedAt = r.receivedAt && r.receivedAt.toDate ? r.receivedAt.toDate() : null;
    const cDate = video.containerDate(probe, fidelity, receivedAt);
    const baseFields = {
      itemKind: kind === 'audio' ? 'audio' : 'video',
      originFidelity: fidelity,
      durationSeconds: duration,
      hasAudio,
      probe: probe.ok
        ? {
            container: probe.container,
            videoCodec: probe.videoCodec,
            audioCodec: probe.audioCodec,
            width: probe.width,
            height: probe.height,
            fps: probe.fps,
            creationTime: probe.creationTime,
            make: probe.make,
            model: probe.model,
            gps: probe.gps,
            probePath: `${storagePath}.probe.json`,
          }
        : { error: probe.error },
    };
    const reasons = [];
    if (!probe.ok) reasons.push('The file could not be probed — check that it plays.');

    const tooLong = duration > video.AUTO_TRANSCRIBE_MAX_SECONDS;
    if (tooLong && !force) {
      fields = {
        ...baseFields,
        transcriptionState: 'deferred',
        resolvedDate: cDate,
        dateConfidence: cDate ? 'medium' : '',
        dateSource: cDate ? 'container creation_time' : '',
        aiSummary: '',
        classificationLabel: 'Uncertain',
        reviewReason: 'Transcription deferred — over 10 minutes. Request transcription from the receipt to generate a reading aid.',
      };
      status = 'deferred';
      return finish();
    }

    const gcsUri = `gs://${bucket.name}/${storagePath}`;
    const res = await video.analyzeVideo({
      project: deps.project,
      location: deps.location,
      model: deps.videoModel,
      gcsUri,
      mimeType: r.contentType || meta.contentType || (kind === 'audio' ? 'audio/mp4' : 'video/mp4'),
      clientSide,
      hasAudio,
      sourceUrl,
      client: deps.videoClient,
    });
    audit = res.audit || {};
    if (!res.ok) {
      fields = {
        ...baseFields,
        transcriptionState: 'failed',
        resolvedDate: cDate,
        dateConfidence: cDate ? 'medium' : '',
        dateSource: cDate ? 'container creation_time' : '',
        classificationLabel: 'Uncertain',
        reviewReason: 'Transcription failed — the video is stored and hashed. Request transcription again from the receipt.',
      };
      status = 'extraction_failed';
      errors = res.errors;
      return finish();
    }
    const v = res.value;
    const lowMsgs = v.threadMessages.filter((m) => !m.isHeader && m.confidence < kLowConfidence).length;
    if (!hasAudio && !v.isScreenRecording) reasons.push('No audio track — there is no transcript to read.');
    if (lowMsgs) reasons.push(`${lowMsgs} message${lowMsgs === 1 ? ' was' : 's were'} hard to read in the screen recording.`);
    // An item with neither date stays undated and counts in the undated
    // share of Record Lag (spec §5) — that is a finding, not an error.
    const date = v.onScreenDate || cDate;
    fields = {
      ...baseFields,
      isScreenRecording: v.isScreenRecording,
      itemKind: v.isScreenRecording ? 'screen_recording' : baseFields.itemKind,
      aiSummary: v.summary,
      transcript: v.transcript,
      transcriptionState: !hasAudio ? 'no_audio' : 'complete',
      isTranscribed: hasAudio && v.transcript.length > 0,
      threadMessages: v.threadMessages,
      detectedPlatform: v.platform,
      resolvedDate: date,
      dateConfidence: v.onScreenDate ? 'high' : cDate ? 'medium' : '',
      dateSource: v.onScreenDate ? 'on-screen date' : cDate ? 'container creation_time' : '',
      classificationLabel: reasons.length ? 'Uncertain' : 'Processed',
      reviewReason: reasons.join(' '),
    };
    status = 'extracted';
    return finish();
  }

  // ---------------------------------------------------------------- images / documents
  if (kind === 'heic') {
    return fail('HEIC images cannot be read automatically', 'HEIC photo — stored and hashed. AI reading needs a PNG or JPEG copy; open the file to review it.');
  }
  if (kind === 'doc') {
    return fail('legacy .doc', 'Legacy Word (.doc) file — stored and hashed. Upload a .docx or PDF copy for AI reading, or review it by hand.');
  }
  if (kind === 'unknown' || kind === 'zip') {
    return fail(`unsupported file type (${kind})`, 'This file type cannot be read automatically — stored and hashed; review it by hand.');
  }

  let content;
  let extra = '';
  let emailMeta = null;
  let sourceFields = {};
  if (kind === 'image') {
    if (size > MAX_IMAGE_BYTES) return fail(`image is ${(size / 1048576).toFixed(1)} MB; the AI reading limit is 7 MB`, 'Image too large to read automatically (7 MB limit) — stored and hashed; review it by hand.');
    const [bytes] = await file.download();
    content = [{ type: 'image', source: { type: 'base64', media_type: imageMediaType(bytes) || 'image/jpeg', data: bytes.toString('base64') } }];
    const dims = imageSize(bytes);
    if (dims && dims.width > 0 && dims.height > 0) sourceFields = { imageWidth: dims.width, imageHeight: dims.height };
  } else if (kind === 'pdf') {
    if (size > MAX_PDF_BYTES) return fail(`PDF is ${(size / 1048576).toFixed(1)} MB; the AI reading limit is 24 MB`, 'PDF too large to read automatically — stored and hashed; review it by hand.');
    const [bytes] = await file.download();
    content = [{ type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: bytes.toString('base64') } }];
  } else {
    const [bytes] = await file.download();
    const t = await extractText(kind, bytes);
    if (!t.ok) return fail(t.error, `${t.error} The file is stored and hashed.`);
    if (!t.text.trim()) return fail('no readable text', 'No readable text was found in this file — review it by hand.');
    emailMeta = t.meta && t.meta.emailDate !== undefined ? t.meta : null;
    sourceFields = { documentText: t.text.length > MAX_STORED_TEXT ? t.text.slice(0, MAX_STORED_TEXT) : t.text, documentTextTruncated: t.text.length > MAX_STORED_TEXT || !!t.truncated };
    content = [{ type: 'text', text: `<document name="${fileName.replace(/"/g, "'")}">\n${t.text}\n</document>` }];
    if (t.truncated) extra = 'The document text was truncated for length; describe only what is included.';
  }

  const res = await analyzeWithClaude({
    anthropic: deps.anthropic(),
    model: deps.claudeModel,
    maxTokens: deps.maxTokens,
    content,
    clientSide,
    kind: kindFiled,
    fileName,
    extra,
    sourceUrl: kind === 'image' ? sourceUrl : '',
  });
  audit = res.audit || {};
  if (!res.ok) return fail(res.errors);

  fields = { ...fieldsFromAnalysis(res.value, res.threadMessages), ...sourceFields };
  if (emailMeta) {
    if (emailMeta.emailDate && !fields.resolvedDate) {
      fields.resolvedDate = emailMeta.emailDate;
      fields.dateConfidence = 'high';
      fields.dateSource = 'email Date header';
    }
    fields.emailSubject = emailMeta.emailSubject || '';
    fields.emailFrom = emailMeta.emailFrom || '';
    fields.attachmentCount = emailMeta.attachmentCount || 0;
  }
  if (kindFiled === 'photo' && res.threadMessages.length) fields.itemKind = 'screenshot';
  status = res.value.conversation.containsConversation ? 'extracted' : 'no_conversation_detected';
  return finish();
}

function sha256(buf) {
  return crypto.createHash('sha256').update(buf).digest('hex');
}

module.exports = { processReceipt, fieldsFromAnalysis, imageMediaType, readHead, sha256, MAX_IMAGE_BYTES, MAX_PDF_BYTES };
