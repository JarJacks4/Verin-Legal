// Verin Legal — typed access to Firestore fields the Cloud Functions write
// that aren't (yet) declared in FlutterFlow's generated record classes.
//
// Read straight from snapshotData so a FlutterFlow re-export that regenerates
// lib/backend/schema/ can't break this file. If a field is later added in
// FlutterFlow under the same name, the generated getter simply takes
// precedence over the extension.

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';

String _str(Map<String, dynamic> d, String k) {
  final v = d[k];
  return v is String ? v : '';
}

int _int(Map<String, dynamic> d, String k) {
  final v = d[k];
  return v is num ? v.toInt() : 0;
}

DateTime? _date(Map<String, dynamic> d, String k) {
  final v = d[k];
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}

extension VerinMatterFields on MattersRecord {
  /// Display title: matterName, then caseTitle.
  String get title => matterName.isNotEmpty ? matterName : caseTitle;

  /// entryHash of the newest chainEntries row for this matter.
  String get chainHeadHash => _str(snapshotData, 'chainHeadHash');
  int get chainLength => _int(snapshotData, 'chainLength');
  String get clioMatterUrl => _str(snapshotData, 'clioMatterUrl');
  String get clioMatterDisplayNumber => _str(snapshotData, 'clioMatterDisplayNumber');

  /// Chain pill: a root exists and no chronology shift is flagged.
  bool get chainVerified => hasChainRoot && !hasChronologyShift;

  bool get isClioLinked => clioMatterID.isNotEmpty || providerMatterReference.isNotEmpty;
  String get clioMatterRef => clioMatterID.isNotEmpty ? clioMatterID : providerMatterReference;
}

extension VerinReceiptFields on ReceiptsRecord {
  String get sourceUrl => _str(snapshotData, 'sourceUrl');
  String get sourceStoragePath => _str(snapshotData, 'sourceStoragePath');

  /// pending | extracted | no_conversation_detected | extraction_failed | '' (older receipts)
  String get extractionState => _str(snapshotData, 'extractionState');
  List<String> get extractionErrors {
    final v = snapshotData['extractionErrors'];
    return v is List ? v.map((e) => '$e').toList() : const [];
  }

  String get entryHash => _str(snapshotData, 'entryHash');
  int get chainSeq => _int(snapshotData, 'chainSeq');
  String get extractionModel => _str(snapshotData, 'extractionModel');
  DateTime? get extractedAt => _date(snapshotData, 'extractedAt');

  bool get isImage =>
      itemKind == 'photo' || itemKind == 'screenshot' || itemKind == 'image' || sourceUrl.isNotEmpty;
  bool get isVideo => itemKind == 'video' || itemKind == 'screen_recording';

  /// Headline for lists: the stored content line, else a readable fallback.
  String get headline {
    if (content.isNotEmpty) return content;
    final kind = itemKind.isEmpty ? 'Item' : '${itemKind[0].toUpperCase()}${itemKind.substring(1).replaceAll('_', ' ')}';
    return channel.isEmpty ? kind : '$kind via $channel';
  }
}

extension VerinChainEntryFields on ChainEntriesRecord {
  String get prevHash => _str(snapshotData, 'prevHash');
  String get itemHash => _str(snapshotData, 'itemHash');
  String get receivedAtIso => _str(snapshotData, 'receivedAtIso');
  String get originDigest => _str(snapshotData, 'originDigest');
  DocumentReference? get receiptRef {
    final v = snapshotData['receiptRef'];
    return v is DocumentReference ? v : null;
  }
}

extension VerinClioSyncLogFields on ClioSyncLogRecord {
  String get error => _str(snapshotData, 'error');
  String get clioDocumentId => _str(snapshotData, 'clioDocumentId');
}

extension VerinTeamMemberFields on TeamMembersRecord {
  DateTime? get expiresAt => _date(snapshotData, 'expiresAt');
  bool get inviteExpired {
    final e = expiresAt;
    return status.toLowerCase() == 'invited' && e != null && e.isBefore(DateTime.now());
  }
}
