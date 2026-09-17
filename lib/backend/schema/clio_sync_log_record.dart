import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ClioSyncLogRecord extends FirestoreRecord {
  ClioSyncLogRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "matterID" field.
  DocumentReference? _matterID;
  DocumentReference? get matterID => _matterID;
  bool hasMatterID() => _matterID != null;

  // "documentName" field.
  String? _documentName;
  String get documentName => _documentName ?? '';
  bool hasDocumentName() => _documentName != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "pushedAt" field.
  DateTime? _pushedAt;
  DateTime? get pushedAt => _pushedAt;
  bool hasPushedAt() => _pushedAt != null;

  void _initializeFields() {
    _matterID = snapshotData['matterID'] as DocumentReference?;
    _documentName = snapshotData['documentName'] as String?;
    _status = snapshotData['status'] as String?;
    _pushedAt = snapshotData['pushedAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('clioSyncLog');

  static Stream<ClioSyncLogRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ClioSyncLogRecord.fromSnapshot(s));

  static Future<ClioSyncLogRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ClioSyncLogRecord.fromSnapshot(s));

  static ClioSyncLogRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ClioSyncLogRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ClioSyncLogRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ClioSyncLogRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ClioSyncLogRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ClioSyncLogRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createClioSyncLogRecordData({
  DocumentReference? matterID,
  String? documentName,
  String? status,
  DateTime? pushedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matterID': matterID,
      'documentName': documentName,
      'status': status,
      'pushedAt': pushedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ClioSyncLogRecordDocumentEquality implements Equality<ClioSyncLogRecord> {
  const ClioSyncLogRecordDocumentEquality();

  @override
  bool equals(ClioSyncLogRecord? e1, ClioSyncLogRecord? e2) {
    return e1?.matterID == e2?.matterID &&
        e1?.documentName == e2?.documentName &&
        e1?.status == e2?.status &&
        e1?.pushedAt == e2?.pushedAt;
  }

  @override
  int hash(ClioSyncLogRecord? e) => const ListEquality()
      .hash([e?.matterID, e?.documentName, e?.status, e?.pushedAt]);

  @override
  bool isValidKey(Object? o) => o is ClioSyncLogRecord;
}
