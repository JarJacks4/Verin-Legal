import '/components/button21_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/components/switch_component5_widget.dart';
import '/components/text_field12_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'firm_settings_widget.dart' show FirmSettingsWidget;
import 'package:flutter/material.dart';

class FirmSettingsModel extends FlutterFlowModel<FirmSettingsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SideNavAdmin component.
  late SideNavAdminModel sideNavAdminModel;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for TextField.
  late TextField12Model textFieldModel1;
  // Model for TextField.
  late TextField12Model textFieldModel2;
  // Model for TextField.
  late TextField12Model textFieldModel3;
  // Model for Switch.
  late SwitchComponent5Model switchModel1;
  // Model for Switch.
  late SwitchComponent5Model switchModel2;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for Button.
  late Button21Model buttonModel1;
  // Model for Button.
  late Button21Model buttonModel2;
  // Model for Button.
  late Button21Model buttonModel3;
  // Model for Button.
  late Button21Model buttonModel4;
  // Model for Button.
  late Button21Model buttonModel5;

  @override
  void initState(BuildContext context) {
    sideNavAdminModel = createModel(context, () => SideNavAdminModel());
    columnScrollController = ScrollController();
    textFieldModel1 = createModel(context, () => TextField12Model());
    textFieldModel2 = createModel(context, () => TextField12Model());
    textFieldModel3 = createModel(context, () => TextField12Model());
    switchModel1 = createModel(context, () => SwitchComponent5Model());
    switchModel2 = createModel(context, () => SwitchComponent5Model());
    buttonModel1 = createModel(context, () => Button21Model());
    buttonModel2 = createModel(context, () => Button21Model());
    buttonModel3 = createModel(context, () => Button21Model());
    buttonModel4 = createModel(context, () => Button21Model());
    buttonModel5 = createModel(context, () => Button21Model());
  }

  @override
  void dispose() {
    sideNavAdminModel.dispose();
    columnScrollController?.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    switchModel1.dispose();
    switchModel2.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
    buttonModel5.dispose();
  }
}
