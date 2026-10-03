import '/components/button19_widget.dart';
import '/components/step_indicator_widget.dart';
import '/components/text_field11_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'create_password_comp_widget.dart' show CreatePasswordCompWidget;
import 'package:flutter/material.dart';

class CreatePasswordCompModel
    extends FlutterFlowModel<CreatePasswordCompWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for StepIndicator.
  late StepIndicatorModel stepIndicatorModel;
  // Model for TextField.
  late TextField11Model textFieldModel1;
  // Model for TextField.
  late TextField11Model textFieldModel2;
  // Model for TextField.
  late TextField11Model textFieldModel3;
  // Model for Button.
  late Button19Model buttonModel;

  @override
  void initState(BuildContext context) {
    stepIndicatorModel = createModel(context, () => StepIndicatorModel());
    textFieldModel1 = createModel(context, () => TextField11Model());
    textFieldModel2 = createModel(context, () => TextField11Model());
    textFieldModel3 = createModel(context, () => TextField11Model());
    buttonModel = createModel(context, () => Button19Model());
  }

  @override
  void dispose() {
    stepIndicatorModel.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    buttonModel.dispose();
  }
}
