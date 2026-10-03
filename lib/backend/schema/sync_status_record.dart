import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SyncStatusRecord extends FirestoreRecord {
  SyncStatusRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "newItemsCount" field.
  int? _newItemsCount;
  int get newItemsCount => _newItemsCount ?? 0;
  bool hasNewItemsCount() => _newItemsCount != null;

  // "duplicatesFilteredCount" field.
  int? _duplicatesFilteredCount;
  int get duplicatesFilteredCount => _duplicatesFilteredCount ?? 0;
  bool hasDuplicatesFilteredCount() => _duplicatesFilteredCount != null;

  // "chronologyShiftsCount" field.
  int? _chronologyShiftsCount;
  int get chronologyShiftsCount => _chronologyShiftsCount ?? 0;
  bool hasChronologyShiftsCount() => _chronologyShiftsCount != null;

  // "lastSyncAt" field.
  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool hasLastSyncAt() => _lastSyncAt != null;

  void _initializeFields() {
    _newItemsCount = castToType<int>(snapshotData['newItemsCount']);
    _duplicatesFilteredCount =
        castToType<int>(snapshotData['duplicatesFilteredCount']);
    _chronologyShiftsCount =
        castToType<int>(snapshotData['chronologyShiftsCount']);
    _lastSyncAt = snapshotData['lastSyncAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Sync_Status');

  static Stream<SyncStatusRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SyncStatusRecord.fromSnapshot(s));

  static Future<SyncStatusRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SyncStatusRecord.fromSnapshot(s));

  static SyncStatusRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SyncStatusRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SyncStatusRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SyncStatusRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SyncStatusRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SyncStatusRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSyncStatusRecordData({
  int? newItemsCount,
  int? duplicatesFilteredCount,
  int? chronologyShiftsCount,
  DateTime? lastSyncAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'newItemsCount': newItemsCount,
      'duplicatesFilteredCount': duplicatesFilteredCount,
      'chronologyShiftsCount': chronologyShiftsCount,
      'lastSyncAt': lastSyncAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class SyncStatusRecordDocumentEquality implements Equality<SyncStatusRecord> {
  const SyncStatusRecordDocumentEquality();

  @override
  bool equals(SyncStatusRecord? e1, SyncStatusRecord? e2) {
    return e1?.newItemsCount == e2?.newItemsCount &&
        e1?.duplicatesFilteredCount == e2?.duplicatesFilteredCount &&
        e1?.chronologyShiftsCount == e2?.chronologyShiftsCount &&
        e1?.lastSyncAt == e2?.lastSyncAt;
  }

  @override
  int hash(SyncStatusRecord? e) => const ListEquality().hash([
        e?.newItemsCount,
        e?.duplicatesFilteredCount,
        e?.chronologyShiftsCount,
        e?.lastSyncAt
      ]);

  @override
  bool isValidKey(Object? o) => o is SyncStatusRecord;
}
