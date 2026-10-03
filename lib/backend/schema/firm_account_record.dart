import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FirmAccountRecord extends FirestoreRecord {
  FirmAccountRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "firmName" field.
  String? _firmName;
  String get firmName => _firmName ?? '';
  bool hasFirmName() => _firmName != null;

  // "planName" field.
  String? _planName;
  String get planName => _planName ?? '';
  bool hasPlanName() => _planName != null;

  // "planStatus" field.
  String? _planStatus;
  String get planStatus => _planStatus ?? '';
  bool hasPlanStatus() => _planStatus != null;

  // "planPriceCents" field.
  int? _planPriceCents;
  int get planPriceCents => _planPriceCents ?? 0;
  bool hasPlanPriceCents() => _planPriceCents != null;

  // "planRenewsAt" field.
  DateTime? _planRenewsAt;
  DateTime? get planRenewsAt => _planRenewsAt;
  bool hasPlanRenewsAt() => _planRenewsAt != null;

  // "memberSince" field.
  DateTime? _memberSince;
  DateTime? get memberSince => _memberSince;
  bool hasMemberSince() => _memberSince != null;

  // "storageTier" field.
  String? _storageTier;
  String get storageTier => _storageTier ?? '';
  bool hasStorageTier() => _storageTier != null;

  // "seatLimit" field.
  int? _seatLimit;
  int get seatLimit => _seatLimit ?? 0;
  bool hasSeatLimit() => _seatLimit != null;

  // "connectedIntegrations" field.
  List<String>? _connectedIntegrations;
  List<String> get connectedIntegrations => _connectedIntegrations ?? const [];
  bool hasConnectedIntegrations() => _connectedIntegrations != null;

  // "dropboxMatterReference" field.
  String? _dropboxMatterReference;
  String get dropboxMatterReference => _dropboxMatterReference ?? '';
  bool hasDropboxMatterReference() => _dropboxMatterReference != null;

  // "dropboxSyncedAt" field.
  DateTime? _dropboxSyncedAt;
  DateTime? get dropboxSyncedAt => _dropboxSyncedAt;
  bool hasDropboxSyncedAt() => _dropboxSyncedAt != null;

  void _initializeFields() {
    _firmName = snapshotData['firmName'] as String?;
    _planName = snapshotData['planName'] as String?;
    _planStatus = snapshotData['planStatus'] as String?;
    _planPriceCents = castToType<int>(snapshotData['planPriceCents']);
    _planRenewsAt = snapshotData['planRenewsAt'] as DateTime?;
    _memberSince = snapshotData['memberSince'] as DateTime?;
    _storageTier = snapshotData['storageTier'] as String?;
    _seatLimit = castToType<int>(snapshotData['seatLimit']);
    _connectedIntegrations = getDataList(snapshotData['connectedIntegrations']);
    _dropboxMatterReference = snapshotData['dropboxMatterReference'] as String?;
    _dropboxSyncedAt = snapshotData['dropboxSyncedAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('firmAccount');

  static Stream<FirmAccountRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FirmAccountRecord.fromSnapshot(s));

  static Future<FirmAccountRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FirmAccountRecord.fromSnapshot(s));

  static FirmAccountRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FirmAccountRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FirmAccountRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FirmAccountRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FirmAccountRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FirmAccountRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFirmAccountRecordData({
  String? firmName,
  String? planName,
  String? planStatus,
  int? planPriceCents,
  DateTime? planRenewsAt,
  DateTime? memberSince,
  String? storageTier,
  int? seatLimit,
  String? dropboxMatterReference,
  DateTime? dropboxSyncedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'firmName': firmName,
      'planName': planName,
      'planStatus': planStatus,
      'planPriceCents': planPriceCents,
      'planRenewsAt': planRenewsAt,
      'memberSince': memberSince,
      'storageTier': storageTier,
      'seatLimit': seatLimit,
      'dropboxMatterReference': dropboxMatterReference,
      'dropboxSyncedAt': dropboxSyncedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class FirmAccountRecordDocumentEquality implements Equality<FirmAccountRecord> {
  const FirmAccountRecordDocumentEquality();

  @override
  bool equals(FirmAccountRecord? e1, FirmAccountRecord? e2) {
    const listEquality = ListEquality();
    return e1?.firmName == e2?.firmName &&
        e1?.planName == e2?.planName &&
        e1?.planStatus == e2?.planStatus &&
        e1?.planPriceCents == e2?.planPriceCents &&
        e1?.planRenewsAt == e2?.planRenewsAt &&
        e1?.memberSince == e2?.memberSince &&
        e1?.storageTier == e2?.storageTier &&
        e1?.seatLimit == e2?.seatLimit &&
        listEquality.equals(
            e1?.connectedIntegrations, e2?.connectedIntegrations) &&
        e1?.dropboxMatterReference == e2?.dropboxMatterReference &&
        e1?.dropboxSyncedAt == e2?.dropboxSyncedAt;
  }

  @override
  int hash(FirmAccountRecord? e) => const ListEquality().hash([
        e?.firmName,
        e?.planName,
        e?.planStatus,
        e?.planPriceCents,
        e?.planRenewsAt,
        e?.memberSince,
        e?.storageTier,
        e?.seatLimit,
        e?.connectedIntegrations,
        e?.dropboxMatterReference,
        e?.dropboxSyncedAt
      ]);

  @override
  bool isValidKey(Object? o) => o is FirmAccountRecord;
}
