import '/components/button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'source_verification_item_widget.dart' show SourceVerificationItemWidget;
import 'package:flutter/material.dart';

class SourceVerificationItemModel
    extends FlutterFlowModel<SourceVerificationItemWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel.dispose();
  }
}
