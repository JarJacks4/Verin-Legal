import '/components/button10_widget.dart';
import '/components/text_field6_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'redesign_the_top_widget.dart' show RedesignTheTopWidget;
import 'package:flutter/material.dart';

class RedesignTheTopModel extends FlutterFlowModel<RedesignTheTopWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TextField.
  late TextField6Model textFieldModel1;
  // Model for Button.
  late Button10Model buttonModel;
  // Model for TextField.
  late TextField6Model textFieldModel2;
  // Model for TextField.
  late TextField6Model textFieldModel3;
  // Model for TextField.
  late TextField6Model textFieldModel4;
  // Model for TextField.
  late TextField6Model textFieldModel5;
  // Model for TextField.
  late TextField6Model textFieldModel6;

  @override
  void initState(BuildContext context) {
    textFieldModel1 = createModel(context, () => TextField6Model());
    buttonModel = createModel(context, () => Button10Model());
    textFieldModel2 = createModel(context, () => TextField6Model());
    textFieldModel3 = createModel(context, () => TextField6Model());
    textFieldModel4 = createModel(context, () => TextField6Model());
    textFieldModel5 = createModel(context, () => TextField6Model());
    textFieldModel6 = createModel(context, () => TextField6Model());
  }

  @override
  void dispose() {
    textFieldModel1.dispose();
    buttonModel.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    textFieldModel4.dispose();
    textFieldModel5.dispose();
    textFieldModel6.dispose();
  }
}
