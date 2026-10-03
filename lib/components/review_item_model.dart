import '/components/button_widget.dart';
import '/components/status_badge2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'review_item_widget.dart' show ReviewItemWidget;
import 'package:flutter/material.dart';

class ReviewItemModel extends FlutterFlowModel<ReviewItemWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for StatusBadge.
  late StatusBadge2Model statusBadgeModel;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    statusBadgeModel = createModel(context, () => StatusBadge2Model());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    statusBadgeModel.dispose();
    buttonModel.dispose();
  }
}
