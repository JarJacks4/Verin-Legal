import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ItemsRecord extends FirestoreRecord {
  ItemsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "matterID" field.
  DocumentReference? _matterID;
  DocumentReference? get matterID => _matterID;
  bool hasMatterID() => _matterID != null;

  // "matterName" field.
  String? _matterName;
  String get matterName => _matterName ?? '';
  bool hasMatterName() => _matterName != null;

  // "kind" field.
  String? _kind;
  String get kind => _kind ?? '';
  bool hasKind() => _kind != null;

  // "channel" field.
  String? _channel;
  String get channel => _channel ?? '';
  bool hasChannel() => _channel != null;

  // "senderRaw" field.
  String? _senderRaw;
  String get senderRaw => _senderRaw ?? '';
  bool hasSenderRaw() => _senderRaw != null;

  // "recievedAt" field.
  DateTime? _recievedAt;
  DateTime? get recievedAt => _recievedAt;
  bool hasRecievedAt() => _recievedAt != null;

  // "sha256" field.
  String? _sha256;
  String get sha256 => _sha256 ?? '';
  bool hasSha256() => _sha256 != null;

  // "tsaToken" field.
  String? _tsaToken;
  String get tsaToken => _tsaToken ?? '';
  bool hasTsaToken() => _tsaToken != null;

  // "state" field.
  String? _state;
  String get state => _state ?? '';
  bool hasState() => _state != null;

  // "isQuarantined" field.
  bool? _isQuarantined;
  bool get isQuarantined => _isQuarantined ?? false;
  bool hasIsQuarantined() => _isQuarantined != null;

  // "speakerConfirmed" field.
  bool? _speakerConfirmed;
  bool get speakerConfirmed => _speakerConfirmed ?? false;
  bool hasSpeakerConfirmed() => _speakerConfirmed != null;

  // "clientSide" field.
  String? _clientSide;
  String get clientSide => _clientSide ?? '';
  bool hasClientSide() => _clientSide != null;

  // "threadMessages" field.
  List<ThreadMessagesStruct>? _threadMessages;
  List<ThreadMessagesStruct> get threadMessages => _threadMessages ?? const [];
  bool hasThreadMessages() => _threadMessages != null;

  // "thumbnailCount" field.
  int? _thumbnailCount;
  int get thumbnailCount => _thumbnailCount ?? 0;
  bool hasThumbnailCount() => _thumbnailCount != null;

  // "clientName" field.
  String? _clientName;
  String get clientName => _clientName ?? '';
  bool hasClientName() => _clientName != null;

  // "batesId" field.
  String? _batesId;
  String get batesId => _batesId ?? '';
  bool hasBatesId() => _batesId != null;

  // "classificationLabel" field.
  String? _classificationLabel;
  String get classificationLabel => _classificationLabel ?? '';
  bool hasClassificationLabel() => _classificationLabel != null;

  // "isDuplicate" field.
  bool? _isDuplicate;
  bool get isDuplicate => _isDuplicate ?? false;
  bool hasIsDuplicate() => _isDuplicate != null;

  // "hasChronologyShif" field.
  bool? _hasChronologyShif;
  bool get hasChronologyShif => _hasChronologyShif ?? false;
  bool hasHasChronologyShif() => _hasChronologyShif != null;

  void _initializeFields() {
    _matterID = snapshotData['matterID'] as DocumentReference?;
    _matterName = snapshotData['matterName'] as String?;
    _kind = snapshotData['kind'] as String?;
    _channel = snapshotData['channel'] as String?;
    _senderRaw = snapshotData['senderRaw'] as String?;
    _recievedAt = snapshotData['recievedAt'] as DateTime?;
    _sha256 = snapshotData['sha256'] as String?;
    _tsaToken = snapshotData['tsaToken'] as String?;
    _state = snapshotData['state'] as String?;
    _isQuarantined = snapshotData['isQuarantined'] as bool?;
    _speakerConfirmed = snapshotData['speakerConfirmed'] as bool?;
    _clientSide = snapshotData['clientSide'] as String?;
    _threadMessages = getStructList(
      snapshotData['threadMessages'],
      ThreadMessagesStruct.fromMap,
    );
    _thumbnailCount = castToType<int>(snapshotData['thumbnailCount']);
    _clientName = snapshotData['clientName'] as String?;
    _batesId = snapshotData['batesId'] as String?;
    _classificationLabel = snapshotData['classificationLabel'] as String?;
    _isDuplicate = snapshotData['isDuplicate'] as bool?;
    _hasChronologyShif = snapshotData['hasChronologyShif'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Items');

  static Stream<ItemsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ItemsRecord.fromSnapshot(s));

  static Future<ItemsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ItemsRecord.fromSnapshot(s));

  static ItemsRecord fromSnapshot(DocumentSnapshot snapshot) => ItemsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ItemsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ItemsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ItemsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ItemsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createItemsRecordData({
  DocumentReference? matterID,
  String? matterName,
  String? kind,
  String? channel,
  String? senderRaw,
  DateTime? recievedAt,
  String? sha256,
  String? tsaToken,
  String? state,
  bool? isQuarantined,
  bool? speakerConfirmed,
  String? clientSide,
  int? thumbnailCount,
  String? clientName,
  String? batesId,
  String? classificationLabel,
  bool? isDuplicate,
  bool? hasChronologyShif,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'matterID': matterID,
      'matterName': matterName,
      'kind': kind,
      'channel': channel,
      'senderRaw': senderRaw,
      'recievedAt': recievedAt,
      'sha256': sha256,
      'tsaToken': tsaToken,
      'state': state,
      'isQuarantined': isQuarantined,
      'speakerConfirmed': speakerConfirmed,
      'clientSide': clientSide,
      'thumbnailCount': thumbnailCount,
      'clientName': clientName,
      'batesId': batesId,
      'classificationLabel': classificationLabel,
      'isDuplicate': isDuplicate,
      'hasChronologyShif': hasChronologyShif,
    }.withoutNulls,
  );

  return firestoreData;
}

class ItemsRecordDocumentEquality implements Equality<ItemsRecord> {
  const ItemsRecordDocumentEquality();

  @override
  bool equals(ItemsRecord? e1, ItemsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.matterID == e2?.matterID &&
        e1?.matterName == e2?.matterName &&
        e1?.kind == e2?.kind &&
        e1?.channel == e2?.channel &&
        e1?.senderRaw == e2?.senderRaw &&
        e1?.recievedAt == e2?.recievedAt &&
        e1?.sha256 == e2?.sha256 &&
        e1?.tsaToken == e2?.tsaToken &&
        e1?.state == e2?.state &&
        e1?.isQuarantined == e2?.isQuarantined &&
        e1?.speakerConfirmed == e2?.speakerConfirmed &&
        e1?.clientSide == e2?.clientSide &&
        listEquality.equals(e1?.threadMessages, e2?.threadMessages) &&
        e1?.thumbnailCount == e2?.thumbnailCount &&
        e1?.clientName == e2?.clientName &&
        e1?.batesId == e2?.batesId &&
        e1?.classificationLabel == e2?.classificationLabel &&
        e1?.isDuplicate == e2?.isDuplicate &&
        e1?.hasChronologyShif == e2?.hasChronologyShif;
  }

  @override
  int hash(ItemsRecord? e) => const ListEquality().hash([
        e?.matterID,
        e?.matterName,
        e?.kind,
        e?.channel,
        e?.senderRaw,
        e?.recievedAt,
        e?.sha256,
        e?.tsaToken,
        e?.state,
        e?.isQuarantined,
        e?.speakerConfirmed,
        e?.clientSide,
        e?.threadMessages,
        e?.thumbnailCount,
        e?.clientName,
        e?.batesId,
        e?.classificationLabel,
        e?.isDuplicate,
        e?.hasChronologyShif
      ]);

  @override
  bool isValidKey(Object? o) => o is ItemsRecord;
}
