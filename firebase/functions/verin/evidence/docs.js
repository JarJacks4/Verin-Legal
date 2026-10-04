// Verin Legal — getting readable content out of documents and email files
// before AI reading. The stored file is never modified; these are reading
// aids derived from it.

const MAX_TEXT_CHARS = 180000; // keeps one request well inside the context window

function detectKind(buf, fileName, contentType) {
  const name = String(fileName || '').toLowerCase();
  const ext = name.includes('.') ? name.slice(name.lastIndexOf('.') + 1) : '';
  const ct = String(contentType || '').toLowerCase();
  if (buf && buf.length >= 4) {
    if (buf.toString('ascii', 0, 5) === '%PDF-') return 'pdf';
    if (buf[0] === 0x89 && buf[1] === 0x50) return 'image';
    if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'image';
    if (buf.toString('ascii', 0, 4) === 'GIF8') return 'image';
    if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WEBP') return 'image';
    if (buf.length >= 12 && /^ftyp(heic|heix|mif1|hevc|heif)/.test(buf.toString('ascii', 4, 12))) return 'heic';
    if (buf.length >= 12 && buf.toString('ascii', 4, 8) === 'ftyp') return ct.startsWith('audio/') || /^(m4a|aac)$/.test(ext) ? 'audio' : 'video';
    if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 11) === 'AVI') return 'video';
    if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WAVE') return 'audio';
    if (buf[0] === 0x1a && buf[1] === 0x45 && buf[2] === 0xdf && buf[3] === 0xa3) return 'video'; // webm / mkv
    if (buf.toString('ascii', 0, 3) === 'ID3' || (buf[0] === 0xff && (buf[1] & 0xe0) === 0xe0)) return 'audio';
    if (buf.toString('ascii', 0, 4) === 'OggS') return 'audio';
    if (buf.toString('ascii', 0, 6) === '#!AMR\n') return 'audio';
    if (buf[0] === 0x50 && buf[1] === 0x4b) {
      if (ext === 'docx') return 'docx';
      if (ext === 'odt') return 'odt';
      return ext === 'zip' ? 'zip' : 'docx';
    }
    if (buf[0] === 0xd0 && buf[1] === 0xcf && buf[2] === 0x11 && buf[3] === 0xe0) return ext === 'msg' ? 'msg' : 'doc';
    if (buf.toString('ascii', 0, 5) === '{\\rtf') return 'rtf';
  }
  if (ext === 'eml' || ct === 'message/rfc822') return 'eml';
  if (ext === 'txt' || ct.startsWith('text/')) return 'text';
  if (ct.startsWith('video/')) return 'video';
  if (ct.startsWith('audio/')) return 'audio';
  if (ct.startsWith('image/')) return 'image';
  return 'unknown';
}

function clip(text) {
  const t = String(text || '').replace(/\r\n/g, '\n').replace(/\n{4,}/g, '\n\n\n').trim();
  return t.length > MAX_TEXT_CHARS ? { text: t.slice(0, MAX_TEXT_CHARS), truncated: true } : { text: t, truncated: false };
}

function rtfToText(rtf) {
  return String(rtf)
    .replace(/\\par[d]?/g, '\n')
    .replace(/\\'([0-9a-f]{2})/gi, (_, h) => String.fromCharCode(parseInt(h, 16)))
    .replace(/\\u(-?\d+)\??/g, (_, n) => String.fromCharCode(((+n % 65536) + 65536) % 65536))
    .replace(/\{\\\*[^{}]*\}/g, '')
    .replace(/\\[a-z]+-?\d* ?/gi, '')
    .replace(/[{}]/g, '')
    .replace(/\n[ \t]+/g, '\n');
}

function xmlToText(xml) {
  return String(xml)
    .replace(/<text:tab\/>/g, '\t')
    .replace(/<text:line-break\/>/g, '\n')
    .replace(/<\/text:(p|h)>/g, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&');
}

/// Returns { ok, text, truncated, meta } or { ok: false, error }.
async function extractText(kind, buf) {
  try {
    if (kind === 'text') return { ok: true, ...clip(buf.toString('utf8')), meta: {} };
    if (kind === 'rtf') return { ok: true, ...clip(rtfToText(buf.toString('latin1'))), meta: {} };
    if (kind === 'docx') {
      const mammoth = require('mammoth');
      const r = await mammoth.extractRawText({ buffer: buf });
      return { ok: true, ...clip(r.value), meta: {} };
    }
    if (kind === 'odt') {
      const JSZip = require('jszip');
      const zip = await JSZip.loadAsync(buf);
      const f = zip.file('content.xml');
      if (!f) return { ok: false, error: 'not an OpenDocument text file' };
      return { ok: true, ...clip(xmlToText(await f.async('string'))), meta: {} };
    }
    if (kind === 'eml') {
      const { simpleParser } = require('mailparser');
      const m = await simpleParser(buf);
      const addr = (a) => (a && a.text) || '';
      const header = [
        `From: ${addr(m.from)}`,
        `To: ${addr(m.to)}`,
        m.cc ? `Cc: ${addr(m.cc)}` : '',
        `Date: ${m.date ? m.date.toISOString() : ''}`,
        `Subject: ${m.subject || ''}`,
        (m.attachments || []).length ? `Attachments: ${m.attachments.map((a) => `${a.filename || 'unnamed'} (${a.contentType}, ${a.size} bytes)`).join('; ')}` : '',
      ]
        .filter(Boolean)
        .join('\n');
      const body = m.text || (m.html ? xmlToText(m.html) : '');
      return {
        ok: true,
        ...clip(`${header}\n\n${body}`),
        meta: {
          emailFrom: addr(m.from),
          emailTo: addr(m.to),
          emailSubject: m.subject || '',
          emailDate: m.date || null,
          attachmentCount: (m.attachments || []).length,
        },
      };
    }
    if (kind === 'msg') {
      const MsgReader = require('@kenjiuno/msgreader').default;
      const reader = new MsgReader(buf);
      const d = reader.getFileData();
      const date = d.messageDeliveryTime || d.clientSubmitTime || d.creationTime || '';
      const header = [
        `From: ${d.senderName || ''} <${d.senderEmail || d.senderSmtpAddress || ''}>`,
        `To: ${(d.recipients || []).map((r) => r.name || r.email).join(', ')}`,
        `Date: ${date}`,
        `Subject: ${d.subject || ''}`,
      ].join('\n');
      const parsedDate = date ? new Date(date) : null;
      return {
        ok: true,
        ...clip(`${header}\n\n${d.body || ''}`),
        meta: {
          emailFrom: d.senderEmail || d.senderName || '',
          emailSubject: d.subject || '',
          emailDate: parsedDate && !Number.isNaN(parsedDate.getTime()) ? parsedDate : null,
          attachmentCount: (d.attachments || []).length,
        },
      };
    }
    if (kind === 'doc') return { ok: false, error: 'Legacy .doc files cannot be read automatically. Save it as .docx or PDF and upload that too.' };
    return { ok: false, error: `no text reader for ${kind}` };
  } catch (e) {
    return { ok: false, error: `could not read the file: ${e.message}` };
  }
}

module.exports = { detectKind, extractText, rtfToText, xmlToText, clip, MAX_TEXT_CHARS };
