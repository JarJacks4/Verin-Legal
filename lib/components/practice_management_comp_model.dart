import '/components/button20_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'practice_management_comp_widget.dart' show PracticeManagementCompWidget;
import 'package:flutter/material.dart';

class PracticeManagementCompModel
    extends FlutterFlowModel<PracticeManagementCompWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController1;
  // Model for Button.
  late Button20Model buttonModel1;
  // State field(s) for Column widget.
  ScrollController? columnScrollController2;
  // Model for Button.
  late Button20Model buttonModel2;
  // Model for Button.
  late Button20Model buttonModel3;
  // Model for Button.
  late Button20Model buttonModel4;
  // Model for Button.
  late Button20Model buttonModel5;

  @override
  void initState(BuildContext context) {
    columnScrollController1 = ScrollController();
    buttonModel1 = createModel(context, () => Button20Model());
    columnScrollController2 = ScrollController();
    buttonModel2 = createModel(context, () => Button20Model());
    buttonModel3 = createModel(context, () => Button20Model());
    buttonModel4 = createModel(context, () => Button20Model());
    buttonModel5 = createModel(context, () => Button20Model());
  }

  @override
  void dispose() {
    columnScrollController1?.dispose();
    buttonModel1.dispose();
    columnScrollController2?.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
    buttonModel5.dispose();
  }
}
