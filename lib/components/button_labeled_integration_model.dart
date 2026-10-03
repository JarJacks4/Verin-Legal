import '/components/button11_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'button_labeled_integration_widget.dart'
    show ButtonLabeledIntegrationWidget;
import 'package:flutter/material.dart';

class ButtonLabeledIntegrationModel
    extends FlutterFlowModel<ButtonLabeledIntegrationWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late Button11Model buttonModel;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => Button11Model());
  }

  @override
  void dispose() {
    buttonModel.dispose();
  }
}
