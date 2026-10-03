import 'package:collection/collection.dart';

enum ThreadMessages {
  client,
  other,
}

enum OriginFidelity {
  as_sent,
  transcoded_in_transit,
}

enum ItemKind {
  video,
  screen_Recording,
  photo,
}

enum Itemskind {
  screenshot_batch,
}

enum StatementsStatus {
  needs_Review,
  verified,
}

enum IngestionReviewQueueReason {
  unrecognized_matter_id,
  invalid_json_response,
  failed_validation,
  processing_error,
}

enum TeamMemberStatusPill {
  Active,
  Invited,
  Suspended,
}

enum IntegrationConnectionPill {
  Connected,
  NotConnected,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (ThreadMessages):
      return ThreadMessages.values.deserialize(value) as T?;
    case (OriginFidelity):
      return OriginFidelity.values.deserialize(value) as T?;
    case (ItemKind):
      return ItemKind.values.deserialize(value) as T?;
    case (Itemskind):
      return Itemskind.values.deserialize(value) as T?;
    case (StatementsStatus):
      return StatementsStatus.values.deserialize(value) as T?;
    case (IngestionReviewQueueReason):
      return IngestionReviewQueueReason.values.deserialize(value) as T?;
    case (TeamMemberStatusPill):
      return TeamMemberStatusPill.values.deserialize(value) as T?;
    case (IntegrationConnectionPill):
      return IntegrationConnectionPill.values.deserialize(value) as T?;
    default:
      return null;
  }
}
