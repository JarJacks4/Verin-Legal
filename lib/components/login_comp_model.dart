import '/components/button18_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'login_comp_widget.dart' show LoginCompWidget;
import 'package:flutter/material.dart';

class LoginCompModel extends FlutterFlowModel<LoginCompWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TextField.
  late TextField10Model textFieldModel1;
  // Model for TextField.
  late TextField10Model textFieldModel2;
  // Model for Button.
  late Button18Model buttonModel1;
  // Model for Button.
  late Button18Model buttonModel2;
  // Model for Button.
  late Button18Model buttonModel3;

  @override
  void initState(BuildContext context) {
    textFieldModel1 = createModel(context, () => TextField10Model());
    textFieldModel2 = createModel(context, () => TextField10Model());
    buttonModel1 = createModel(context, () => Button18Model());
    buttonModel2 = createModel(context, () => Button18Model());
    buttonModel3 = createModel(context, () => Button18Model());
  }

  @override
  void dispose() {
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
  }
}
