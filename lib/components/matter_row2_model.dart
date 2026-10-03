import '/components/status_badge4_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'matter_row2_widget.dart' show MatterRow2Widget;
import 'package:flutter/material.dart';

class MatterRow2Model extends FlutterFlowModel<MatterRow2Widget> {
  ///  State fields for stateful widgets in this component.

  // Model for StatusBadge.
  late StatusBadge4Model statusBadgeModel;

  @override
  void initState(BuildContext context) {
    statusBadgeModel = createModel(context, () => StatusBadge4Model());
  }

  @override
  void dispose() {
    statusBadgeModel.dispose();
  }
}
