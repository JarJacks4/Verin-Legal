import '/components/button2_widget.dart';
import '/components/tab_group_widget.dart';
import '/components/text_field2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'matter_a_bottom_widget.dart' show MatterABottomWidget;
import 'package:flutter/material.dart';

class MatterABottomModel extends FlutterFlowModel<MatterABottomWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TextField.
  late TextField2Model textFieldModel1;
  // Model for TextField.
  late TextField2Model textFieldModel2;
  // Model for TextField.
  late TextField2Model textFieldModel3;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for TabGroup.
  late TabGroupModel tabGroupModel;
  // Model for Button.
  late Button2Model buttonModel1;
  // Model for Button.
  late Button2Model buttonModel2;

  @override
  void initState(BuildContext context) {
    textFieldModel1 = createModel(context, () => TextField2Model());
    textFieldModel2 = createModel(context, () => TextField2Model());
    textFieldModel3 = createModel(context, () => TextField2Model());
    tabGroupModel = createModel(context, () => TabGroupModel());
    buttonModel1 = createModel(context, () => Button2Model());
    buttonModel2 = createModel(context, () => Button2Model());
  }

  @override
  void dispose() {
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    tabGroupModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
