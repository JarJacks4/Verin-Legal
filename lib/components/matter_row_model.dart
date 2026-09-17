import '/components/status_badge_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'matter_row_widget.dart' show MatterRowWidget;
import 'package:flutter/material.dart';

class MatterRowModel extends FlutterFlowModel<MatterRowWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for StatusBadge.
  late StatusBadgeModel statusBadgeModel;

  @override
  void initState(BuildContext context) {
    statusBadgeModel = createModel(context, () => StatusBadgeModel());
  }

  @override
  void dispose() {
    statusBadgeModel.dispose();
  }
}
