import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReceiptsRecord extends FirestoreRecord {
  ReceiptsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "matterId" field.
  DocumentReference? _matterId;
  DocumentReference? get matterId => _matterId;
  bool hasMatterId() => _matterId != null;

  // "itemKind" field.
  String? _itemKind;
  String get itemKind => _itemKind ?? '';
  bool hasItemKind() => _itemKind != null;

  // "receivedAt" field.
  DateTime? _receivedAt;
  DateTime? get receivedAt => _receivedAt;
  bool hasReceivedAt() => _receivedAt != null;

  // "resolvedDate" field.
  DateTime? _resolvedDate;
  DateTime? get resolvedDate => _resolvedDate;
  bool hasResolvedDate() => _resolvedDate != null;

  // "durationSeconds" field.
  int? _durationSeconds;
  int get durationSeconds => _durationSeconds ?? 0;
  bool hasDurationSeconds() => _durationSeconds != null;

  // "originFidelity" field.
  String? _originFidelity;
  String get originFidelity => _originFidelity ?? '';
  bool hasOriginFidelity() => _originFidelity != null;

  // "detectedPlatform" field.
  String? _detectedPlatform;
  String get detectedPlatform => _detectedPlatform ?? '';
  bool hasDetectedPlatform() => _detectedPlatform != null;

  // "item_hash" field.
  String? _itemHash;
  String get itemHash => _itemHash ?? '';
  bool hasItemHash() => _itemHash != null;

  // "isDuplicate" field.
  bool? _isDuplicate;
  bool get isDuplicate => _isDuplicate ?? false;
  bool hasIsDuplicate() => _isDuplicate != null;

  // "hasChronologyShift" field.
  bool? _hasChronologyShift;
  bool get hasChronologyShift => _hasChronologyShift ?? false;
  bool hasHasChronologyShift() => _hasChronologyShift != null;

  // "content" field.
  String? _content;
  String get content => _content ?? '';
  bool hasContent() => _content != null;

  // "channel" field.
  String? _channel;
  String get channel => _channel ?? '';
  bool hasChannel() => _channel != null;

  // "classificationLabel" field.
  String? _classificationLabel;
  String get classificationLabel => _classificationLabel ?? '';
  bool hasClassificationLabel() => _classificationLabel != null;

  // "isTranscribed" field.
  bool? _isTranscribed;
  bool get isTranscribed => _isTranscribed ?? false;
  bool hasIsTranscribed() => _isTranscribed != null;

  // "threadMessages" field.
  List<ThreadMessagesStruct>? _threadMessages;
  List<ThreadMessagesStruct> get threadMessages => _threadMessages ?? const [];
  bool hasThreadMessages() => _threadMessages != null;

  void _initializeFields() {
    _matterId = snapshotData['matterId'] as DocumentReference?;
    _itemKind = snapshotData['itemKind'] as String?;
    _receivedAt = snapshotData['receivedAt'] as DateTime?;
    _resolvedDate = snapshotData['resolvedDate'] as DateTime?;
    _durationSeconds = castToType<int>(snapshotData['durationSeconds']);
    _originFidelity = snapshotData['originFidelity'] as String?;
    _detectedPlatform = snapshotData['detectedPlatform'] as String?;
    _itemHash = snapshotData['item_hash'] as String?;
    _isDuplicate = snapshotData['isDuplicate'] as bool?;
    _hasChronologyShift = snapshotData['hasChronologyShift'] as bool?;
    _content = snapshotData['content'] as String?;
    _channel = snapshotData['channel'] as String?;
    _classificationLabel = snapshotData['classificationLabel'] as String?;
    _isTranscribed = snapshotData['isTranscribed'] as bool?;
    _threadMessages = getStructList(
      snapshotData['threadMessages'],
      ThreadMessagesStruct.fromMap,
    );
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Receipts');

  static Stream<ReceiptsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ReceiptsRecord.fromSnapshot(s));

  static Future<ReceiptsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ReceiptsRecord.fromSnapshot(s));

  static ReceiptsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ReceiptsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ReceiptsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ReceiptsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ReceiptsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReceiptsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createReceiptsRecordData({
  DocumentReference? matterId,
  String? itemKind,
  DateTime? receivedAt,
  DateTime? resolvedDate,
  int? durationSeconds,
  String? originFidelity,
  String? detectedPlatform,
  String? itemHash,
  bool? isDuplicate,
  bool? hasChronologyShift,
  String? content,
  String? channel,
  String? classificationLabel,
  bool? isTranscribed,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matterId': matterId,
      'itemKind': itemKind,
      'receivedAt': receivedAt,
      'resolvedDate': resolvedDate,
      'durationSeconds': durationSeconds,
      'originFidelity': originFidelity,
      'detectedPlatform': detectedPlatform,
      'item_hash': itemHash,
      'isDuplicate': isDuplicate,
      'hasChronologyShift': hasChronologyShift,
      'content': content,
      'channel': channel,
      'classificationLabel': classificationLabel,
      'isTranscribed': isTranscribed,
    }.withoutNulls,
  );

  return firestoreData;
}

class ReceiptsRecordDocumentEquality implements Equality<ReceiptsRecord> {
  const ReceiptsRecordDocumentEquality();

  @override
  bool equals(ReceiptsRecord? e1, ReceiptsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.matterId == e2?.matterId &&
        e1?.itemKind == e2?.itemKind &&
        e1?.receivedAt == e2?.receivedAt &&
        e1?.resolvedDate == e2?.resolvedDate &&
        e1?.durationSeconds == e2?.durationSeconds &&
        e1?.originFidelity == e2?.originFidelity &&
        e1?.detectedPlatform == e2?.detectedPlatform &&
        e1?.itemHash == e2?.itemHash &&
        e1?.isDuplicate == e2?.isDuplicate &&
        e1?.hasChronologyShift == e2?.hasChronologyShift &&
        e1?.content == e2?.content &&
        e1?.channel == e2?.channel &&
        e1?.classificationLabel == e2?.classificationLabel &&
        e1?.isTranscribed == e2?.isTranscribed &&
        listEquality.equals(e1?.threadMessages, e2?.threadMessages);
  }

  @override
  int hash(ReceiptsRecord? e) => const ListEquality().hash([
        e?.matterId,
        e?.itemKind,
        e?.receivedAt,
        e?.resolvedDate,
        e?.durationSeconds,
        e?.originFidelity,
        e?.detectedPlatform,
        e?.itemHash,
        e?.isDuplicate,
        e?.hasChronologyShift,
        e?.content,
        e?.channel,
        e?.classificationLabel,
        e?.isTranscribed,
        e?.threadMessages
      ]);

  @override
  bool isValidKey(Object? o) => o is ReceiptsRecord;
}
