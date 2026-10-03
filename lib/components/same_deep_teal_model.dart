import '/components/button14_widget.dart';
import '/components/switch_component4_widget.dart';
import '/components/text_field8_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'same_deep_teal_widget.dart' show SameDeepTealWidget;
import 'package:flutter/material.dart';

class SameDeepTealModel extends FlutterFlowModel<SameDeepTealWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for TextField.
  late TextField8Model textFieldModel1;
  // Model for TextField.
  late TextField8Model textFieldModel2;
  // Model for TextField.
  late TextField8Model textFieldModel3;
  // Model for TextField.
  late TextField8Model textFieldModel4;
  // Model for Switch.
  late SwitchComponent4Model switchModel1;
  // Model for Switch.
  late SwitchComponent4Model switchModel2;
  // Model for Switch.
  late SwitchComponent4Model switchModel3;
  // Model for Button.
  late Button14Model buttonModel1;
  // Model for Button.
  late Button14Model buttonModel2;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    textFieldModel1 = createModel(context, () => TextField8Model());
    textFieldModel2 = createModel(context, () => TextField8Model());
    textFieldModel3 = createModel(context, () => TextField8Model());
    textFieldModel4 = createModel(context, () => TextField8Model());
    switchModel1 = createModel(context, () => SwitchComponent4Model());
    switchModel2 = createModel(context, () => SwitchComponent4Model());
    switchModel3 = createModel(context, () => SwitchComponent4Model());
    buttonModel1 = createModel(context, () => Button14Model());
    buttonModel2 = createModel(context, () => Button14Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    textFieldModel4.dispose();
    switchModel1.dispose();
    switchModel2.dispose();
    switchModel3.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
