// Verin — mapping between Firestore records and the states the Make design
// displays (channel, item state, Clio state, chain status), plus the shared
// live queries.


import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

// ---------------------------------------------------------------------------
// Small readers for fields the generated record classes don't declare.
// ---------------------------------------------------------------------------

String rStr(Map<String, dynamic> d, String k) {
  final v = d[k];
  return v is String ? v : '';
}

int rInt(Map<String, dynamic> d, String k) {
  final v = d[k];
  return v is num ? v.toInt() : 0;
}

bool rBool(Map<String, dynamic> d, String k) => d[k] == true;

DateTime? rDate(Map<String, dynamic> d, String k) {
  final v = d[k];
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

// ---------------------------------------------------------------------------
// Channels
// ---------------------------------------------------------------------------

enum VChannel { email, sms, whatsapp, upload, inPerson, mail, other }

VChannel channelOf(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.contains('whatsapp')) return VChannel.whatsapp;
  if (s == 'sms' || s.contains('text') || s.contains('mms') || s.contains('rcs')) return VChannel.sms;
  if (s.contains('mail') && !s.contains('physical')) return s == 'mail' ? VChannel.mail : VChannel.email;
  if (s.contains('email')) return VChannel.email;
  if (s.contains('person') || s.contains('hand')) return VChannel.inPerson;
  if (s.contains('physical')) return VChannel.mail;
  if (s.contains('upload') || s.isEmpty) return VChannel.upload;
  return VChannel.other;
}

String channelLabel(VChannel c) => switch (c) {
      VChannel.email => 'Email',
      VChannel.sms => 'Text',
      VChannel.whatsapp => 'WhatsApp',
      VChannel.upload => 'Upload',
      VChannel.inPerson => 'In person',
      VChannel.mail => 'Mail',
      VChannel.other => 'Other',
    };

// ---------------------------------------------------------------------------
// Receipt state
// ---------------------------------------------------------------------------

enum VItemState { processed, uncertain, unreadable, processing }

VItemState itemStateOf(ReceiptsRecord r) {
  final label = r.classificationLabel.trim().toLowerCase();
  final ex = r.extractionState;
  if (label == 'processed') return VItemState.processed;
  if (label == 'unreadable') return VItemState.unreadable;
  if (label == 'uncertain') return VItemState.uncertain;
  if (ex == 'pending' || ex == 'running' || label == 'processing') return VItemState.processing;
  if (ex == 'extraction_failed') return VItemState.uncertain;
  // Older demo rows without a label count as processed.
  return label.isEmpty ? VItemState.processed : VItemState.uncertain;
}

/// Firestore label for a state the reviewer chooses.
String labelForState(VItemState s) => switch (s) {
      VItemState.processed => 'Processed',
      VItemState.uncertain => 'Uncertain',
      VItemState.unreadable => 'Unreadable',
      VItemState.processing => 'Processing',
    };

extension VerinReceiptMore on ReceiptsRecord {
  /// Who/where it came from ("elena@…", "+1 317…", "Client hand-off").
  String get fromLabel {
    final f = rStr(snapshotData, 'fromLabel');
    if (f.isNotEmpty) return f;
    final s = rStr(snapshotData, 'source');
    return s.isNotEmpty ? s : 'unknown sender';
  }

  /// photo | screenshot | video | document | email | physical | message thread
  String get kindLabel {
    final k = itemKind.trim().toLowerCase().replaceAll('_', ' ');
    if (k.isEmpty) return 'item';
    if (k == 'screenshot' || k == 'screen recording') return k;
    return k;
  }

  String get dateConfidence => rStr(snapshotData, 'dateConfidence');
  String get dateSource => rStr(snapshotData, 'dateSource');
  String get aiSummary => rStr(snapshotData, 'aiSummary');
  String get description => rStr(snapshotData, 'description');
  String get custodyNotes => rStr(snapshotData, 'custodyNotes');
  String get transcriptionState => rStr(snapshotData, 'transcriptionState');
  bool get isScreenRecordingItem => rBool(snapshotData, 'isScreenRecording');
  bool get hasAudioTrack => snapshotData['hasAudio'] != false;
  String get tsaToken => rStr(snapshotData, 'tsaTokenId');
  DateTime? get tsaTime => rDate(snapshotData, 'tsaGenTime');
  String get tsaName => rStr(snapshotData, 'tsaName');
  String get fileName => rStr(snapshotData, 'originalFileName');
  String get contentType => rStr(snapshotData, 'contentType');
  int get sizeBytes => rInt(snapshotData, 'sizeBytes');
  String get reviewReason => rStr(snapshotData, 'reviewReason');
  DateTime? get dateReceivedClaimed => rDate(snapshotData, 'dateReceivedClaimed');

  List<Map<String, dynamic>> get transcript {
    final v = snapshotData['transcript'];
    if (v is! List) return const [];
    return v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  /// Seconds as "47s" / "3m 14s".
  String? get durationLabel {
    final s = durationSeconds;
    if (s <= 0) return null;
    return s >= 60 ? '${s ~/ 60}m ${s % 60}s' : '${s}s';
  }
}

// ---------------------------------------------------------------------------
// Matter status helpers
// ---------------------------------------------------------------------------

enum VClioState { synced, pending, failed, notConnected }

VClioState clioStateOf(MattersRecord m, {required bool firmConnected}) {
  if (!firmConnected && !m.isClioLinked) return VClioState.notConnected;
  if (!m.isClioLinked) return VClioState.notConnected;
  if (rStr(m.snapshotData, 'clioLastPushStatus').toLowerCase() == 'failed') return VClioState.failed;
  if (m.clioSyncedAt != null) return VClioState.synced;
  return VClioState.pending;
}

enum VChainStatus { verified, needsReview, notStarted }

VChainStatus chainStatusOf(MattersRecord m) {
  if (!m.hasChainRoot && m.chainLength == 0) return VChainStatus.notStarted;
  if (m.hasChronologyShift) return VChainStatus.needsReview;
  return VChainStatus.verified;
}

bool matterIsOpen(MattersRecord m) => !m.status.toLowerCase().startsWith('closed');

String matterCause(MattersRecord m) => m.caseNumber;

String matterPractice(MattersRecord m) =>
    m.practiceArea.isNotEmpty ? m.practiceArea : (m.matterType.isNotEmpty ? m.matterType : 'Family law');

// ---------------------------------------------------------------------------
// Current user
// ---------------------------------------------------------------------------

class VUser {
  const VUser({required this.name, required this.email, required this.firm, required this.role});

  final String name;
  final String email;
  final String firm;
  final String role;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    return parts.map((w) => w[0]).take(2).join().toUpperCase();
  }

  String get firstName {
    final n = name.trim();
    return n.isEmpty ? '' : n.split(RegExp(r'\s+')).first;
  }

  bool get isAdmin {
    final r = role.trim().toLowerCase();
    return r == 'admin' || r == 'owner' || r == 'administrator' || r.startsWith('admin');
  }

  static VUser current() {
    final d = currentUserDocument;
    return VUser(
      name: (d?.displayName ?? '').isNotEmpty ? d!.displayName : currentUserDisplayName,
      email: currentUserEmail,
      firm: d?.lawFirm ?? '',
      role: d?.role ?? '',
    );
  }

  static VUser fromRecord(UsersRecord? d) {
    if (d == null) return current();
    return VUser(
      name: d.displayName.isNotEmpty ? d.displayName : currentUserDisplayName,
      email: d.email.isNotEmpty ? d.email : currentUserEmail,
      firm: d.lawFirm,
      role: d.role,
    );
  }
}

/// Live users/{uid} doc (role or firm changes apply without a reload).
Stream<UsersRecord?> currentUserStream() {
  final ref = currentUserReference;
  if (ref == null) return Stream.value(null);
  return UsersRecord.getDocument(ref).map<UsersRecord?>((u) => u).handleError((_) {});
}

// ---------------------------------------------------------------------------
// Queries
// ---------------------------------------------------------------------------

Stream<List<MattersRecord>> firmMattersStream() => queryMattersRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()).orderBy('openedAt', descending: true),
    );

/// A matter's receipts, oldest first (the order they arrived).
Stream<List<ReceiptsRecord>> matterReceiptsStream(DocumentReference matterRef) => queryReceiptsRecord(
      queryBuilder: (q) => q.where('matterId', isEqualTo: matterRef).where('firmID', isEqualTo: currentFirmId()).orderBy('receivedAt', descending: true),
    ).map((list) => list.reversed.toList());

/// Receipts waiting for a person, across all matters (filtered to the
/// firm's matters by the caller).
Stream<List<ReceiptsRecord>> flaggedReceiptsStream() => queryReceiptsRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()).where('classificationLabel', whereIn: ['Uncertain', 'Unreadable']),
    );

Stream<MattersRecord> matterStream(DocumentReference ref) => MattersRecord.getDocument(ref);

/// Live Clio connection for the firm (written by the Clio functions).
Stream<Map<String, dynamic>> integrationStatusStream() => FirebaseFirestore.instance
    .collection('integrationStatus')
    .doc(currentFirmId())
    .snapshots()
    .map((s) => s.data() ?? <String, dynamic>{});

/// The signed-in user's firm account record, or null.
Stream<FirmAccountRecord?> firmAccountStream() => queryFirmAccountRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()),
      singleRecord: true,
    ).map((list) => list.isEmpty ? null : list.first);

// ---------------------------------------------------------------------------
// Record lag
// ---------------------------------------------------------------------------

/// Days between an item's evidence date and the day it reached the firm.
List<int> recordLagsDays(Iterable<ReceiptsRecord> receipts) {
  final out = <int>[];
  for (final r in receipts) {
    final d = r.resolvedDate;
    final rec = r.receivedAt;
    if (d == null || rec == null) continue;
    final days = (rec.difference(d).inHours / 24.0).round();
    if (days >= 0) out.add(days);
  }
  out.sort();
  return out;
}

int? medianDays(List<int> sorted) {
  if (sorted.isEmpty) return null;
  final mid = sorted.length ~/ 2;
  return sorted.length.isEven ? ((sorted[mid - 1] + sorted[mid]) / 2).round() : sorted[mid];
}
