// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class ThreadMessagesStruct extends FFFirebaseStruct {
  ThreadMessagesStruct({
    String? speaker,
    String? text,
    String? timestampLabel,
    bool? isGap,
    double? confidence,
    String? sourceThumbnailUrl,
    String? platform,
    bool? isHeader,
    bool? repeatedPresent,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _speaker = speaker,
        _text = text,
        _timestampLabel = timestampLabel,
        _isGap = isGap,
        _confidence = confidence,
        _sourceThumbnailUrl = sourceThumbnailUrl,
        _platform = platform,
        _isHeader = isHeader,
        _repeatedPresent = repeatedPresent,
        super(firestoreUtilData);

  // "speaker" field.
  String? _speaker;
  String get speaker => _speaker ?? '';
  set speaker(String? val) => _speaker = val;

  bool hasSpeaker() => _speaker != null;

  // "text" field.
  String? _text;
  String get text => _text ?? '';
  set text(String? val) => _text = val;

  bool hasText() => _text != null;

  // "timestampLabel" field.
  String? _timestampLabel;
  String get timestampLabel => _timestampLabel ?? '';
  set timestampLabel(String? val) => _timestampLabel = val;

  bool hasTimestampLabel() => _timestampLabel != null;

  // "isGap" field.
  bool? _isGap;
  bool get isGap => _isGap ?? false;
  set isGap(bool? val) => _isGap = val;

  bool hasIsGap() => _isGap != null;

  // "confidence" field.
  double? _confidence;
  double get confidence => _confidence ?? 0.0;
  set confidence(double? val) => _confidence = val;

  void incrementConfidence(double amount) => confidence = confidence + amount;

  bool hasConfidence() => _confidence != null;

  // "sourceThumbnailUrl" field.
  String? _sourceThumbnailUrl;
  String get sourceThumbnailUrl => _sourceThumbnailUrl ?? '';
  set sourceThumbnailUrl(String? val) => _sourceThumbnailUrl = val;

  bool hasSourceThumbnailUrl() => _sourceThumbnailUrl != null;

  // "platform" field.
  String? _platform;
  String get platform => _platform ?? '';
  set platform(String? val) => _platform = val;

  bool hasPlatform() => _platform != null;

  // "isHeader" field.
  bool? _isHeader;
  bool get isHeader => _isHeader ?? false;
  set isHeader(bool? val) => _isHeader = val;

  bool hasIsHeader() => _isHeader != null;

  // "repeatedPresent" field.
  bool? _repeatedPresent;
  bool get repeatedPresent => _repeatedPresent ?? false;
  set repeatedPresent(bool? val) => _repeatedPresent = val;

  bool hasRepeatedPresent() => _repeatedPresent != null;

  static ThreadMessagesStruct fromMap(Map<String, dynamic> data) =>
      ThreadMessagesStruct(
        speaker: data['speaker'] as String?,
        text: data['text'] as String?,
        timestampLabel: data['timestampLabel'] as String?,
        isGap: data['isGap'] as bool?,
        confidence: castToType<double>(data['confidence']),
        sourceThumbnailUrl: data['sourceThumbnailUrl'] as String?,
        platform: data['platform'] as String?,
        isHeader: data['isHeader'] as bool?,
        repeatedPresent: data['repeatedPresent'] as bool?,
      );

  static ThreadMessagesStruct? maybeFromMap(dynamic data) => data is Map
      ? ThreadMessagesStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'speaker': _speaker,
        'text': _text,
        'timestampLabel': _timestampLabel,
        'isGap': _isGap,
        'confidence': _confidence,
        'sourceThumbnailUrl': _sourceThumbnailUrl,
        'platform': _platform,
        'isHeader': _isHeader,
        'repeatedPresent': _repeatedPresent,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'speaker': serializeParam(
          _speaker,
          ParamType.String,
        ),
        'text': serializeParam(
          _text,
          ParamType.String,
        ),
        'timestampLabel': serializeParam(
          _timestampLabel,
          ParamType.String,
        ),
        'isGap': serializeParam(
          _isGap,
          ParamType.bool,
        ),
        'confidence': serializeParam(
          _confidence,
          ParamType.double,
        ),
        'sourceThumbnailUrl': serializeParam(
          _sourceThumbnailUrl,
          ParamType.String,
        ),
        'platform': serializeParam(
          _platform,
          ParamType.String,
        ),
        'isHeader': serializeParam(
          _isHeader,
          ParamType.bool,
        ),
        'repeatedPresent': serializeParam(
          _repeatedPresent,
          ParamType.bool,
        ),
      }.withoutNulls;

  static ThreadMessagesStruct fromSerializableMap(Map<String, dynamic> data) =>
      ThreadMessagesStruct(
        speaker: deserializeParam(
          data['speaker'],
          ParamType.String,
          false,
        ),
        text: deserializeParam(
          data['text'],
          ParamType.String,
          false,
        ),
        timestampLabel: deserializeParam(
          data['timestampLabel'],
          ParamType.String,
          false,
        ),
        isGap: deserializeParam(
          data['isGap'],
          ParamType.bool,
          false,
        ),
        confidence: deserializeParam(
          data['confidence'],
          ParamType.double,
          false,
        ),
        sourceThumbnailUrl: deserializeParam(
          data['sourceThumbnailUrl'],
          ParamType.String,
          false,
        ),
        platform: deserializeParam(
          data['platform'],
          ParamType.String,
          false,
        ),
        isHeader: deserializeParam(
          data['isHeader'],
          ParamType.bool,
          false,
        ),
        repeatedPresent: deserializeParam(
          data['repeatedPresent'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'ThreadMessagesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ThreadMessagesStruct &&
        speaker == other.speaker &&
        text == other.text &&
        timestampLabel == other.timestampLabel &&
        isGap == other.isGap &&
        confidence == other.confidence &&
        sourceThumbnailUrl == other.sourceThumbnailUrl &&
        platform == other.platform &&
        isHeader == other.isHeader &&
        repeatedPresent == other.repeatedPresent;
  }

  @override
  int get hashCode => const ListEquality().hash([
        speaker,
        text,
        timestampLabel,
        isGap,
        confidence,
        sourceThumbnailUrl,
        platform,
        isHeader,
        repeatedPresent
      ]);
}

ThreadMessagesStruct createThreadMessagesStruct({
  String? speaker,
  String? text,
  String? timestampLabel,
  bool? isGap,
  double? confidence,
  String? sourceThumbnailUrl,
  String? platform,
  bool? isHeader,
  bool? repeatedPresent,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ThreadMessagesStruct(
      speaker: speaker,
      text: text,
      timestampLabel: timestampLabel,
      isGap: isGap,
      confidence: confidence,
      sourceThumbnailUrl: sourceThumbnailUrl,
      platform: platform,
      isHeader: isHeader,
      repeatedPresent: repeatedPresent,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ThreadMessagesStruct? updateThreadMessagesStruct(
  ThreadMessagesStruct? threadMessages, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    threadMessages
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addThreadMessagesStructData(
  Map<String, dynamic> firestoreData,
  ThreadMessagesStruct? threadMessages,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (threadMessages == null) {
    return;
  }
  if (threadMessages.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && threadMessages.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final threadMessagesData =
      getThreadMessagesFirestoreData(threadMessages, forFieldValue);
  final nestedData =
      threadMessagesData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = threadMessages.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getThreadMessagesFirestoreData(
  ThreadMessagesStruct? threadMessages, [
  bool forFieldValue = false,
]) {
  if (threadMessages == null) {
    return {};
  }
  final firestoreData = mapToFirestore(threadMessages.toMap());

  // Add any Firestore field values
  mapToFirestore(threadMessages.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getThreadMessagesListFirestoreData(
  List<ThreadMessagesStruct>? threadMessagess,
) =>
    threadMessagess
        ?.map((e) => getThreadMessagesFirestoreData(e, true))
        .toList() ??
    [];
