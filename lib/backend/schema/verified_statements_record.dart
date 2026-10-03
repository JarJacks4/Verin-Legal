import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class VerifiedStatementsRecord extends FirestoreRecord {
  VerifiedStatementsRecord._(
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

  // "verifiedStatements" field.
  bool? _verifiedStatements;
  bool get verifiedStatements => _verifiedStatements ?? false;
  bool hasVerifiedStatements() => _verifiedStatements != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  void _initializeFields() {
    _matterId = snapshotData['matterId'] as DocumentReference?;
    _statementText = snapshotData['statementText'] as String?;
    _verified = snapshotData['verified'] as bool?;
    _sourceLabel = snapshotData['sourceLabel'] as String?;
    _sourceThumbnailUrl = snapshotData['sourceThumbnailUrl'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _verifiedStatements = snapshotData['verifiedStatements'] as bool?;
    _status = snapshotData['status'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('VerifiedStatements');

  static Stream<VerifiedStatementsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => VerifiedStatementsRecord.fromSnapshot(s));

  static Future<VerifiedStatementsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => VerifiedStatementsRecord.fromSnapshot(s));

  static VerifiedStatementsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      VerifiedStatementsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static VerifiedStatementsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      VerifiedStatementsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'VerifiedStatementsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is VerifiedStatementsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createVerifiedStatementsRecordData({
  DocumentReference? matterId,
  String? statementText,
  bool? verified,
  String? sourceLabel,
  String? sourceThumbnailUrl,
  DateTime? createdAt,
  bool? verifiedStatements,
  String? status,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matterId': matterId,
      'statementText': statementText,
      'verified': verified,
      'sourceLabel': sourceLabel,
      'sourceThumbnailUrl': sourceThumbnailUrl,
      'createdAt': createdAt,
      'verifiedStatements': verifiedStatements,
      'status': status,
    }.withoutNulls,
  );

  return firestoreData;
}

class VerifiedStatementsRecordDocumentEquality
    implements Equality<VerifiedStatementsRecord> {
  const VerifiedStatementsRecordDocumentEquality();

  @override
  bool equals(VerifiedStatementsRecord? e1, VerifiedStatementsRecord? e2) {
    return e1?.matterId == e2?.matterId &&
        e1?.statementText == e2?.statementText &&
        e1?.verified == e2?.verified &&
        e1?.sourceLabel == e2?.sourceLabel &&
        e1?.sourceThumbnailUrl == e2?.sourceThumbnailUrl &&
        e1?.createdAt == e2?.createdAt &&
        e1?.verifiedStatements == e2?.verifiedStatements &&
        e1?.status == e2?.status;
  }

  @override
  int hash(VerifiedStatementsRecord? e) => const ListEquality().hash([
        e?.matterId,
        e?.statementText,
        e?.verified,
        e?.sourceLabel,
        e?.sourceThumbnailUrl,
        e?.createdAt,
        e?.verifiedStatements,
        e?.status
      ]);

  @override
  bool isValidKey(Object? o) => o is VerifiedStatementsRecord;
}
