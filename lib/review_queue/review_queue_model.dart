import '/backend/backend.dart';
import '/components/side_nav_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'review_queue_widget.dart' show ReviewQueueWidget;
import 'package:flutter/material.dart';

class ReviewQueueModel extends FlutterFlowModel<ReviewQueueWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in ReviewQueue widget.
  List<ItemsRecord>? queueItems;
  // Stores action output result for [Custom Action - daysAgoStart] action in ReviewQueue widget.
  DateTime? startOffToday;
  // Stores action output result for [Firestore Query - Query a collection] action in ReviewQueue widget.
  int? autoResolvedTodayCount;
  // Stores action output result for [Custom Action - estimateTimeSaved] action in ReviewQueue widget.
  double? hoursSaved;
  // Stores action output result for [Custom Action - daysAgoStart] action in ReviewQueue widget.
  DateTime? startofWeek;
  // Stores action output result for [Firestore Query - Query a collection] action in ReviewQueue widget.
  List<ItemsRecord>? weeklyProcessedItems;
  // Stores action output result for [Custom Action - bucketByWeekday] action in ReviewQueue widget.
  dynamic weeklyVolume;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for TextField.
  late TextFieldModel textFieldModel;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    textFieldModel = createModel(context, () => TextFieldModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    textFieldModel.dispose();
  }
}
