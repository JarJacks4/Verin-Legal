// Verin — evidence upload: pick files, stage them, upload each to
// Storage (intake/{uid}/…), then ask the server to file it on the matter.

import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:firebase_storage/firebase_storage.dart' hide FirebaseException;

import '/auth/firebase_auth/auth_util.dart';
import '/verin/verin_api.dart';

/// What the person is adding (the Make's "What are you adding?" tiles).
enum EvidenceKind { photo, video, document, email, physical }

String evidenceKindId(EvidenceKind k) => k.name;

String evidenceKindLabel(EvidenceKind k) => switch (k) {
      EvidenceKind.photo => 'Photo',
      EvidenceKind.video => 'Video',
      EvidenceKind.document => 'Document',
      EvidenceKind.email => 'Email',
      EvidenceKind.physical => 'Physical',
    };

String evidenceKindHint(EvidenceKind k) => switch (k) {
      EvidenceKind.photo => 'JPG, PNG, HEIC, WebP — screenshots of messages are read into the Thread tab',
      EvidenceKind.video => 'MP4, MOV, AVI, voice notes — transcribed automatically under 10 minutes',
      EvidenceKind.document => 'PDF, Word, text',
      EvidenceKind.email => '.eml or .msg file',
      EvidenceKind.physical => 'Describe below',
    };

const _exts = <EvidenceKind, List<String>>{
  EvidenceKind.photo: ['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp', 'gif'],
  EvidenceKind.video: ['mp4', 'mov', 'm4v', 'avi', 'webm', '3gp', 'mkv', 'm4a', 'mp3', 'wav', 'aac', 'ogg', 'opus', 'amr'],
  EvidenceKind.document: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'],
  EvidenceKind.email: ['eml', 'msg', 'pdf'],
};

List<String> allowedExtensions(EvidenceKind k) => _exts[k] ?? const [];

const _mime = <String, String>{
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'mp4': 'video/mp4',
  'm4v': 'video/x-m4v',
  'mov': 'video/quicktime',
  'avi': 'video/x-msvideo',
  'webm': 'video/webm',
  '3gp': 'video/3gpp',
  'mkv': 'video/x-matroska',
  'm4a': 'audio/mp4',
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'aac': 'audio/aac',
  'ogg': 'audio/ogg',
  'opus': 'audio/opus',
  'amr': 'audio/amr',
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'txt': 'text/plain',
  'rtf': 'application/rtf',
  'odt': 'application/vnd.oasis.opendocument.text',
  'eml': 'message/rfc822',
  'msg': 'application/vnd.ms-outlook',
};

String extensionOf(String name) {
  final i = name.lastIndexOf('.');
  return i < 0 ? '' : name.substring(i + 1).toLowerCase();
}

String mimeFor(String name) => _mime[extensionOf(name)] ?? 'application/octet-stream';

/// Best kind for a file dropped without choosing a tile (New matter upload).
EvidenceKind kindForFile(String name) {
  final e = extensionOf(name);
  for (final entry in _exts.entries) {
    if (entry.value.contains(e)) return entry.key;
  }
  return EvidenceKind.document;
}

bool isImageName(String name) => mimeFor(name).startsWith('image/') && !name.toLowerCase().endsWith('.heic');

/// Largest single file the browser can hold in memory comfortably.
const int kMaxUploadBytes = 1024 * 1024 * 1024; // 1 GB (server accepts up to 2 GB)

class StagedFile {
  StagedFile({required this.name, required this.bytes, required this.kind});

  final String name;
  final Uint8List bytes;
  final EvidenceKind kind;

  int get size => bytes.length;
  String get mime => mimeFor(name);
  bool get isImage => isImageName(name);
  String get sizeLabel {
    final mb = size / 1024 / 1024;
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(size / 1024).toStringAsFixed(0)} KB';
  }
}

class PickResult {
  PickResult(this.files, this.skipped);

  final List<StagedFile> files;
  final List<String> skipped;
}

/// Opens the file chooser. [kind] null = any supported evidence file.
Future<PickResult> pickEvidence({EvidenceKind? kind, bool multiple = true}) async {
  final exts = kind == null
      ? {for (final l in _exts.values) ...l}.toList()
      : allowedExtensions(kind);
  final res = await FilePicker.platform.pickFiles(
    allowMultiple: multiple,
    withData: true,
    type: FileType.custom,
    allowedExtensions: exts,
  );
  if (res == null) return PickResult(const [], const []);
  final files = <StagedFile>[];
  final skipped = <String>[];
  for (final f in res.files) {
    final b = f.bytes;
    if (b == null || b.isEmpty) {
      skipped.add('${f.name} (could not be read)');
      continue;
    }
    if (b.length > kMaxUploadBytes) {
      skipped.add('${f.name} (over 1 GB — send it by email intake instead)');
      continue;
    }
    files.add(StagedFile(name: f.name, bytes: b, kind: kind ?? kindForFile(f.name)));
  }
  return PickResult(files, skipped);
}

String _uploadId() {
  final r = Random.secure();
  const a = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return '${DateTime.now().millisecondsSinceEpoch}-${List.generate(10, (_) => a[r.nextInt(a.length)]).join()}';
}

String _safeName(String name) {
  final s = name.replaceAll(RegExp(r'[\\/#?\[\]*\u0000-\u001f]'), '_').trim();
  return s.isEmpty ? 'file' : (s.length > 120 ? s.substring(s.length - 120) : s);
}

/// Uploads one file and files it on the matter. [onProgress] gets 0..1 for
/// the upload; the server step after it is reported as 1.0.
Future<Map<String, dynamic>> uploadAndIngest({
  required String matterId,
  required StagedFile file,
  String channel = 'upload',
  String fromLabel = '',
  String? dateReceived,
  String description = '',
  String custodyNotes = '',
  String clientSide = 'right',
  void Function(double progress)? onProgress,
}) async {
  final uid = currentUserUid;
  if (uid.isEmpty) throw VerinApiException('Sign in again to upload.');
  final path = 'intake/$uid/${_uploadId()}/${_safeName(file.name)}';
  final ref = FirebaseStorage.instance.ref(path);
  try {
    final task = ref.putData(file.bytes, SettableMetadata(contentType: file.mime));
    task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    }, onError: (_) {});
    await task;
  } on FirebaseException catch (e) {
    throw VerinApiException(e.code == 'unauthorized'
        ? 'Upload was blocked by Storage rules. Publish the storage rules from firebase/storage.rules.'
        : 'Upload failed (${e.code}).');
  }
  onProgress?.call(1.0);
  return VerinApi.ingestEvidence(
    matterId: matterId,
    kind: evidenceKindId(file.kind),
    uploadPath: path,
    fileName: file.name,
    contentType: file.mime,
    channel: channel,
    fromLabel: fromLabel,
    dateReceived: dateReceived,
    description: description,
    custodyNotes: custodyNotes,
    clientSide: clientSide,
  );
}

// ---------------------------------------------------------------------------
// Closed-matter import (checklist #4)
// ---------------------------------------------------------------------------

/// Archive types for a closed matter: a ZIP of a folder, a mailbox export,
/// or loose evidence files.
const kArchiveExtensions = ['zip', 'mbox', 'eml', 'msg', 'pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp', 'gif', 'mp4', 'mov', 'm4a', 'mp3', 'wav', 'doc', 'docx', 'txt'];

/// Picks one or more archives / files for a closed-matter import.
Future<PickResult> pickClosedMatterFiles() async {
  final res = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: FileType.custom,
    allowedExtensions: kArchiveExtensions,
  );
  if (res == null) return PickResult(const [], const []);
  final files = <StagedFile>[];
  final skipped = <String>[];
  for (final f in res.files) {
    final b = f.bytes;
    if (b == null || b.isEmpty) {
      skipped.add('${f.name} (could not be read)');
      continue;
    }
    if (b.length > kMaxUploadBytes) {
      skipped.add('${f.name} (over 1 GB — split the folder into parts)');
      continue;
    }
    files.add(StagedFile(name: f.name, bytes: b, kind: kindForFile(f.name)));
  }
  return PickResult(files, skipped);
}

/// Uploads one archive and files everything inside it, continuing until the
/// server has filed every entry. [onStatus] gets short progress lines.
/// Returns { found, filed, skipped }.
Future<Map<String, int>> uploadAndImportArchive({
  required String matterId,
  required StagedFile file,
  void Function(String status, double? progress)? onStatus,
}) async {
  final uid = currentUserUid;
  if (uid.isEmpty) throw VerinApiException('Sign in again to upload.');
  final path = 'intake/$uid/${_uploadId()}/${_safeName(file.name)}';
  final ref = FirebaseStorage.instance.ref(path);
  final ct = extensionOf(file.name) == 'zip'
      ? 'application/zip'
      : extensionOf(file.name) == 'mbox'
          ? 'application/mbox'
          : file.mime;
  try {
    final task = ref.putData(file.bytes, SettableMetadata(contentType: ct));
    task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onStatus?.call('Uploading ${file.name}', s.bytesTransferred / s.totalBytes);
    }, onError: (_) {});
    await task;
  } on FirebaseException catch (e) {
    throw VerinApiException(e.code == 'unauthorized'
        ? 'Upload was blocked by Storage rules. Publish the storage rules from firebase/storage.rules.'
        : 'Upload failed (${e.code}).');
  }
  var offset = 0;
  String? importId;
  var found = 0;
  var filed = 0;
  var skipped = 0;
  while (true) {
    onStatus?.call(offset == 0 ? 'Opening ${file.name}' : 'Filing items ($filed of $found)', found == 0 ? null : filed / found);
    final r = await VerinApi.importClosedMatter(matterId: matterId, uploadPath: path, fileName: file.name, offset: offset, importId: importId);
    importId = r['importId'] as String?;
    found = (r['found'] as num?)?.toInt() ?? found;
    filed += (r['filed'] as num?)?.toInt() ?? 0;
    skipped += (r['skipped'] as num?)?.toInt() ?? 0;
    final next = (r['nextOffset'] as num?)?.toInt();
    if (next == null) break;
    offset = next;
  }
  onStatus?.call('Filed $filed of $found', 1.0);
  return {'found': found, 'filed': filed, 'skipped': skipped};
}
