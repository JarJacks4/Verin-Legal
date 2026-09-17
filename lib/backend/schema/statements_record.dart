import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class StatementsRecord extends FirestoreRecord {
  StatementsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "matterId" field.
  DocumentReference? _matterId;
  DocumentReference? get matterId => _matterId;
  bool hasMatterId() => _matterId != null;

  // "statementText" field.
  String? _statementText;
  String get statementText => _statementText ?? '';
  bool hasStatementText() => _statementText != null;

  // "verified" field.
  bool? _verified;
  bool get verified => _verified ?? false;
  bool hasVerified() => _verified != null;

  // "sourceLabel" field.
  String? _sourceLabel;
  String get sourceLabel => _sourceLabel ?? '';
  bool hasSourceLabel() => _sourceLabel != null;

  // "sourceThumbnailUrl" field.
  String? _sourceThumbnailUrl;
  String get sourceThumbnailUrl => _sourceThumbnailUrl ?? '';
  bool hasSourceThumbnailUrl() => _sourceThumbnailUrl != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _matterId = snapshotData['matterId'] as DocumentReference?;
    _statementText = snapshotData['statementText'] as String?;
    _verified = snapshotData['verified'] as bool?;
    _sourceLabel = snapshotData['sourceLabel'] as String?;
    _sourceThumbnailUrl = snapshotData['sourceThumbnailUrl'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Statements');

  static Stream<StatementsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => StatementsRecord.fromSnapshot(s));

  static Future<StatementsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => StatementsRecord.fromSnapshot(s));

  static StatementsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      StatementsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static StatementsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      StatementsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'StatementsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is StatementsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createStatementsRecordData({
  DocumentReference? matterId,
  String? statementText,
  bool? verified,
  String? sourceLabel,
  String? sourceThumbnailUrl,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matterId': matterId,
      'statementText': statementText,
      'verified': verified,
      'sourceLabel': sourceLabel,
      'sourceThumbnailUrl': sourceThumbnailUrl,
      'createdAt': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class StatementsRecordDocumentEquality implements Equality<StatementsRecord> {
  const StatementsRecordDocumentEquality();

  @override
  bool equals(StatementsRecord? e1, StatementsRecord? e2) {
    return e1?.matterId == e2?.matterId &&
        e1?.statementText == e2?.statementText &&
        e1?.verified == e2?.verified &&
        e1?.sourceLabel == e2?.sourceLabel &&
        e1?.sourceThumbnailUrl == e2?.sourceThumbnailUrl &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(StatementsRecord? e) => const ListEquality().hash([
        e?.matterId,
        e?.statementText,
        e?.verified,
        e?.sourceLabel,
        e?.sourceThumbnailUrl,
        e?.createdAt
      ]);

  @override
  bool isValidKey(Object? o) => o is StatementsRecord;
}
