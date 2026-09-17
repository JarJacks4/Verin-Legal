import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MattersRecord extends FirestoreRecord {
  MattersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "firmID" field.
  String? _firmID;
  String get firmID => _firmID ?? '';
  bool hasFirmID() => _firmID != null;

  // "clientName" field.
  String? _clientName;
  String get clientName => _clientName ?? '';
  bool hasClientName() => _clientName != null;

  // "matterName" field.
  String? _matterName;
  String get matterName => _matterName ?? '';
  bool hasMatterName() => _matterName != null;

  // "caseNumber" field.
  String? _caseNumber;
  String get caseNumber => _caseNumber ?? '';
  bool hasCaseNumber() => _caseNumber != null;

  // "matterType" field.
  String? _matterType;
  String get matterType => _matterType ?? '';
  bool hasMatterType() => _matterType != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "openedAt" field.
  DateTime? _openedAt;
  DateTime? get openedAt => _openedAt;
  bool hasOpenedAt() => _openedAt != null;

  // "emailAddress" field.
  String? _emailAddress;
  String get emailAddress => _emailAddress ?? '';
  bool hasEmailAddress() => _emailAddress != null;

  // "smsNumber" field.
  String? _smsNumber;
  String get smsNumber => _smsNumber ?? '';
  bool hasSmsNumber() => _smsNumber != null;

  // "whatsAppAddress" field.
  String? _whatsAppAddress;
  String get whatsAppAddress => _whatsAppAddress ?? '';
  bool hasWhatsAppAddress() => _whatsAppAddress != null;

  // "clioMatterID" field.
  String? _clioMatterID;
  String get clioMatterID => _clioMatterID ?? '';
  bool hasClioMatterID() => _clioMatterID != null;

  // "clioConnected" field.
  bool? _clioConnected;
  bool get clioConnected => _clioConnected ?? false;
  bool hasClioConnected() => _clioConnected != null;

  // "exportAutoDailySync" field.
  bool? _exportAutoDailySync;
  bool get exportAutoDailySync => _exportAutoDailySync ?? false;
  bool hasExportAutoDailySync() => _exportAutoDailySync != null;

  // "exportIncludeMetadataJson" field.
  bool? _exportIncludeMetadataJson;
  bool get exportIncludeMetadataJson => _exportIncludeMetadataJson ?? false;
  bool hasExportIncludeMetadataJson() => _exportIncludeMetadataJson != null;

  // "exportIncludeHighResExhibits" field.
  bool? _exportIncludeHighResExhibits;
  bool get exportIncludeHighResExhibits =>
      _exportIncludeHighResExhibits ?? false;
  bool hasExportIncludeHighResExhibits() =>
      _exportIncludeHighResExhibits != null;

  // "assignedCounsel" field.
  String? _assignedCounsel;
  String get assignedCounsel => _assignedCounsel ?? '';
  bool hasAssignedCounsel() => _assignedCounsel != null;

  // "activeMonitoring" field.
  bool? _activeMonitoring;
  bool get activeMonitoring => _activeMonitoring ?? false;
  bool hasActiveMonitoring() => _activeMonitoring != null;

  // "redactionCount" field.
  int? _redactionCount;
  int get redactionCount => _redactionCount ?? 0;
  bool hasRedactionCount() => _redactionCount != null;

  // "redactionCategories" field.
  String? _redactionCategories;
  String get redactionCategories => _redactionCategories ?? '';
  bool hasRedactionCategories() => _redactionCategories != null;

  // "detectedGapRange" field.
  String? _detectedGapRange;
  String get detectedGapRange => _detectedGapRange ?? '';
  bool hasDetectedGapRange() => _detectedGapRange != null;

  // "suggestedFollowUpDraft" field.
  String? _suggestedFollowUpDraft;
  String get suggestedFollowUpDraft => _suggestedFollowUpDraft ?? '';
  bool hasSuggestedFollowUpDraft() => _suggestedFollowUpDraft != null;

  void _initializeFields() {
    _firmID = snapshotData['firmID'] as String?;
    _clientName = snapshotData['clientName'] as String?;
    _matterName = snapshotData['matterName'] as String?;
    _caseNumber = snapshotData['caseNumber'] as String?;
    _matterType = snapshotData['matterType'] as String?;
    _status = snapshotData['status'] as String?;
    _openedAt = snapshotData['openedAt'] as DateTime?;
    _emailAddress = snapshotData['emailAddress'] as String?;
    _smsNumber = snapshotData['smsNumber'] as String?;
    _whatsAppAddress = snapshotData['whatsAppAddress'] as String?;
    _clioMatterID = snapshotData['clioMatterID'] as String?;
    _clioConnected = snapshotData['clioConnected'] as bool?;
    _exportAutoDailySync = snapshotData['exportAutoDailySync'] as bool?;
    _exportIncludeMetadataJson =
        snapshotData['exportIncludeMetadataJson'] as bool?;
    _exportIncludeHighResExhibits =
        snapshotData['exportIncludeHighResExhibits'] as bool?;
    _assignedCounsel = snapshotData['assignedCounsel'] as String?;
    _activeMonitoring = snapshotData['activeMonitoring'] as bool?;
    _redactionCount = castToType<int>(snapshotData['redactionCount']);
    _redactionCategories = snapshotData['redactionCategories'] as String?;
    _detectedGapRange = snapshotData['detectedGapRange'] as String?;
    _suggestedFollowUpDraft = snapshotData['suggestedFollowUpDraft'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Matters');

  static Stream<MattersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MattersRecord.fromSnapshot(s));

  static Future<MattersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MattersRecord.fromSnapshot(s));

  static MattersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MattersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MattersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MattersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MattersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MattersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMattersRecordData({
  String? firmID,
  String? clientName,
  String? matterName,
  String? caseNumber,
  String? matterType,
  String? status,
  DateTime? openedAt,
  String? emailAddress,
  String? smsNumber,
  String? whatsAppAddress,
  String? clioMatterID,
  bool? clioConnected,
  bool? exportAutoDailySync,
  bool? exportIncludeMetadataJson,
  bool? exportIncludeHighResExhibits,
  String? assignedCounsel,
  bool? activeMonitoring,
  int? redactionCount,
  String? redactionCategories,
  String? detectedGapRange,
  String? suggestedFollowUpDraft,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'firmID': firmID,
      'clientName': clientName,
      'matterName': matterName,
      'caseNumber': caseNumber,
      'matterType': matterType,
      'status': status,
      'openedAt': openedAt,
      'emailAddress': emailAddress,
      'smsNumber': smsNumber,
      'whatsAppAddress': whatsAppAddress,
      'clioMatterID': clioMatterID,
      'clioConnected': clioConnected,
      'exportAutoDailySync': exportAutoDailySync,
      'exportIncludeMetadataJson': exportIncludeMetadataJson,
      'exportIncludeHighResExhibits': exportIncludeHighResExhibits,
      'assignedCounsel': assignedCounsel,
      'activeMonitoring': activeMonitoring,
      'redactionCount': redactionCount,
      'redactionCategories': redactionCategories,
      'detectedGapRange': detectedGapRange,
      'suggestedFollowUpDraft': suggestedFollowUpDraft,
    }.withoutNulls,
  );

  return firestoreData;
}

class MattersRecordDocumentEquality implements Equality<MattersRecord> {
  const MattersRecordDocumentEquality();

  @override
  bool equals(MattersRecord? e1, MattersRecord? e2) {
    return e1?.firmID == e2?.firmID &&
        e1?.clientName == e2?.clientName &&
        e1?.matterName == e2?.matterName &&
        e1?.caseNumber == e2?.caseNumber &&
        e1?.matterType == e2?.matterType &&
        e1?.status == e2?.status &&
        e1?.openedAt == e2?.openedAt &&
        e1?.emailAddress == e2?.emailAddress &&
        e1?.smsNumber == e2?.smsNumber &&
        e1?.whatsAppAddress == e2?.whatsAppAddress &&
        e1?.clioMatterID == e2?.clioMatterID &&
        e1?.clioConnected == e2?.clioConnected &&
        e1?.exportAutoDailySync == e2?.exportAutoDailySync &&
        e1?.exportIncludeMetadataJson == e2?.exportIncludeMetadataJson &&
        e1?.exportIncludeHighResExhibits == e2?.exportIncludeHighResExhibits &&
        e1?.assignedCounsel == e2?.assignedCounsel &&
        e1?.activeMonitoring == e2?.activeMonitoring &&
        e1?.redactionCount == e2?.redactionCount &&
        e1?.redactionCategories == e2?.redactionCategories &&
        e1?.detectedGapRange == e2?.detectedGapRange &&
        e1?.suggestedFollowUpDraft == e2?.suggestedFollowUpDraft;
  }

  @override
  int hash(MattersRecord? e) => const ListEquality().hash([
        e?.firmID,
        e?.clientName,
        e?.matterName,
        e?.caseNumber,
        e?.matterType,
        e?.status,
        e?.openedAt,
        e?.emailAddress,
        e?.smsNumber,
        e?.whatsAppAddress,
        e?.clioMatterID,
        e?.clioConnected,
        e?.exportAutoDailySync,
        e?.exportIncludeMetadataJson,
        e?.exportIncludeHighResExhibits,
        e?.assignedCounsel,
        e?.activeMonitoring,
        e?.redactionCount,
        e?.redactionCategories,
        e?.detectedGapRange,
        e?.suggestedFollowUpDraft
      ]);

  @override
  bool isValidKey(Object? o) => o is MattersRecord;
}
