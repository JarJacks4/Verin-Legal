import '/components/button3_widget.dart';
import '/components/switch_component2_widget.dart';
import '/components/text_field3_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'edit_matter_a_widget.dart' show EditMatterAWidget;
import 'package:flutter/material.dart';

class EditMatterAModel extends FlutterFlowModel<EditMatterAWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for TextField.
  late TextField3Model textFieldModel1;
  // Model for TextField.
  late TextField3Model textFieldModel2;
  // Model for TextField.
  late TextField3Model textFieldModel3;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for TextField.
  late TextField3Model textFieldModel4;
  // Model for Switch.
  late SwitchComponent2Model switchModel;
  // Model for Button.
  late Button3Model buttonModel1;
  // Model for Button.
  late Button3Model buttonModel2;
  // Model for Button.
  late Button3Model buttonModel3;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    textFieldModel1 = createModel(context, () => TextField3Model());
    textFieldModel2 = createModel(context, () => TextField3Model());
    textFieldModel3 = createModel(context, () => TextField3Model());
    textFieldModel4 = createModel(context, () => TextField3Model());
    switchModel = createModel(context, () => SwitchComponent2Model());
    buttonModel1 = createModel(context, () => Button3Model());
    buttonModel2 = createModel(context, () => Button3Model());
    buttonModel3 = createModel(context, () => Button3Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    textFieldModel4.dispose();
    switchModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
  }
}
