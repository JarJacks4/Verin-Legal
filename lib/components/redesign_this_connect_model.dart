import '/components/button9_widget.dart';
import '/components/text_field5_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'redesign_this_connect_widget.dart' show RedesignThisConnectWidget;
import 'package:flutter/material.dart';

class RedesignThisConnectModel
    extends FlutterFlowModel<RedesignThisConnectWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TextField.
  late TextField5Model textFieldModel;
  // Model for Button.
  late Button9Model buttonModel;

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextField5Model());
    buttonModel = createModel(context, () => Button9Model());
  }

  @override
  void dispose() {
    textFieldModel.dispose();
    buttonModel.dispose();
  }
}
