import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TeamMembersRecord extends FirestoreRecord {
  TeamMembersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "firmAccountI" field.
  DocumentReference? _firmAccountI;
  DocumentReference? get firmAccountI => _firmAccountI;
  bool hasFirmAccountI() => _firmAccountI != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "role" field.
  String? _role;
  String get role => _role ?? '';
  bool hasRole() => _role != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "invitedAt" field.
  DateTime? _invitedAt;
  DateTime? get invitedAt => _invitedAt;
  bool hasInvitedAt() => _invitedAt != null;

  void _initializeFields() {
    _firmAccountI = snapshotData['firmAccountI'] as DocumentReference?;
    _name = snapshotData['name'] as String?;
    _email = snapshotData['email'] as String?;
    _role = snapshotData['role'] as String?;
    _status = snapshotData['status'] as String?;
    _invitedAt = snapshotData['invitedAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('TeamMembers');

  static Stream<TeamMembersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TeamMembersRecord.fromSnapshot(s));

  static Future<TeamMembersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TeamMembersRecord.fromSnapshot(s));

  static TeamMembersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TeamMembersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TeamMembersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TeamMembersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TeamMembersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TeamMembersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTeamMembersRecordData({
  DocumentReference? firmAccountI,
  String? name,
  String? email,
  String? role,
  String? status,
  DateTime? invitedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'firmAccountI': firmAccountI,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'invitedAt': invitedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class TeamMembersRecordDocumentEquality implements Equality<TeamMembersRecord> {
  const TeamMembersRecordDocumentEquality();

  @override
  bool equals(TeamMembersRecord? e1, TeamMembersRecord? e2) {
    return e1?.firmAccountI == e2?.firmAccountI &&
        e1?.name == e2?.name &&
        e1?.email == e2?.email &&
        e1?.role == e2?.role &&
        e1?.status == e2?.status &&
        e1?.invitedAt == e2?.invitedAt;
  }

  @override
  int hash(TeamMembersRecord? e) => const ListEquality().hash(
      [e?.firmAccountI, e?.name, e?.email, e?.role, e?.status, e?.invitedAt]);

  @override
  bool isValidKey(Object? o) => o is TeamMembersRecord;
}
