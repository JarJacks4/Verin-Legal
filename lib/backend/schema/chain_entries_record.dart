import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChainEntriesRecord extends FirestoreRecord {
  ChainEntriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "matterID" field.
  DocumentReference? _matterID;
  DocumentReference? get matterID => _matterID;
  bool hasMatterID() => _matterID != null;

  // "seq" field.
  int? _seq;
  int get seq => _seq ?? 0;
  bool hasSeq() => _seq != null;

  // "entryHash" field.
  String? _entryHash;
  String get entryHash => _entryHash ?? '';
  bool hasEntryHash() => _entryHash != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "verificationBadge" field.
  String? _verificationBadge;
  String get verificationBadge => _verificationBadge ?? '';
  bool hasVerificationBadge() => _verificationBadge != null;

  // "digitalSignature" field.
  String? _digitalSignature;
  String get digitalSignature => _digitalSignature ?? '';
  bool hasDigitalSignature() => _digitalSignature != null;

  void _initializeFields() {
    _matterID = snapshotData['matterID'] as DocumentReference?;
    _seq = castToType<int>(snapshotData['seq']);
    _entryHash = snapshotData['entryHash'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _verificationBadge = snapshotData['verificationBadge'] as String?;
    _digitalSignature = snapshotData['digitalSignature'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('chainEntries');

  static Stream<ChainEntriesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ChainEntriesRecord.fromSnapshot(s));

  static Future<ChainEntriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ChainEntriesRecord.fromSnapshot(s));

  static ChainEntriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ChainEntriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChainEntriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChainEntriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChainEntriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChainEntriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChainEntriesRecordData({
  DocumentReference? matterID,
  int? seq,
  String? entryHash,
  DateTime? createdAt,
  String? verificationBadge,
  String? digitalSignature,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matterID': matterID,
      'seq': seq,
      'entryHash': entryHash,
      'createdAt': createdAt,
      'verificationBadge': verificationBadge,
      'digitalSignature': digitalSignature,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChainEntriesRecordDocumentEquality
    implements Equality<ChainEntriesRecord> {
  const ChainEntriesRecordDocumentEquality();

  @override
  bool equals(ChainEntriesRecord? e1, ChainEntriesRecord? e2) {
    return e1?.matterID == e2?.matterID &&
        e1?.seq == e2?.seq &&
        e1?.entryHash == e2?.entryHash &&
        e1?.createdAt == e2?.createdAt &&
        e1?.verificationBadge == e2?.verificationBadge &&
        e1?.digitalSignature == e2?.digitalSignature;
  }

  @override
  int hash(ChainEntriesRecord? e) => const ListEquality().hash([
        e?.matterID,
        e?.seq,
        e?.entryHash,
        e?.createdAt,
        e?.verificationBadge,
        e?.digitalSignature
      ]);

  @override
  bool isValidKey(Object? o) => o is ChainEntriesRecord;
}
