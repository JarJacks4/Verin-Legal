import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FollowUpRequestsRecord extends FirestoreRecord {
  FollowUpRequestsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "matterId" field.
  DocumentReference? _matterId;
  DocumentReference? get matterId => _matterId;
  bool hasMatterId() => _matterId != null;

  // "draftText" field.
  String? _draftText;
  String get draftText => _draftText ?? '';
  bool hasDraftText() => _draftText != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "sentAt" field.
  DateTime? _sentAt;
  DateTime? get sentAt => _sentAt;
  bool hasSentAt() => _sentAt != null;

  void _initializeFields() {
    _matterId = snapshotData['matterId'] as DocumentReference?;
    _draftText = snapshotData['draftText'] as String?;
    _status = snapshotData['status'] as String?;
    _sentAt = snapshotData['sentAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Follow-UpRequests');

  static Stream<FollowUpRequestsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FollowUpRequestsRecord.fromSnapshot(s));

  static Future<FollowUpRequestsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => FollowUpRequestsRecord.fromSnapshot(s));

  static FollowUpRequestsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FollowUpRequestsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FollowUpRequestsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FollowUpRequestsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FollowUpRequestsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FollowUpRequestsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFollowUpRequestsRecordData({
  DocumentReference? matterId,
  String? draftText,
  String? status,
  DateTime? sentAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matterId': matterId,
      'draftText': draftText,
      'status': status,
      'sentAt': sentAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class FollowUpRequestsRecordDocumentEquality
    implements Equality<FollowUpRequestsRecord> {
  const FollowUpRequestsRecordDocumentEquality();

  @override
  bool equals(FollowUpRequestsRecord? e1, FollowUpRequestsRecord? e2) {
    return e1?.matterId == e2?.matterId &&
        e1?.draftText == e2?.draftText &&
        e1?.status == e2?.status &&
        e1?.sentAt == e2?.sentAt;
  }

  @override
  int hash(FollowUpRequestsRecord? e) => const ListEquality()
      .hash([e?.matterId, e?.draftText, e?.status, e?.sentAt]);

  @override
  bool isValidKey(Object? o) => o is FollowUpRequestsRecord;
}
