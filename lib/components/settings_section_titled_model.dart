import '/components/switch_component3_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'settings_section_titled_widget.dart' show SettingsSectionTitledWidget;
import 'package:flutter/material.dart';

class SettingsSectionTitledModel
    extends FlutterFlowModel<SettingsSectionTitledWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Switch.
  late SwitchComponent3Model switchModel1;
  // Model for Switch.
  late SwitchComponent3Model switchModel2;
  // Model for Switch.
  late SwitchComponent3Model switchModel3;

  @override
  void initState(BuildContext context) {
    switchModel1 = createModel(context, () => SwitchComponent3Model());
    switchModel2 = createModel(context, () => SwitchComponent3Model());
    switchModel3 = createModel(context, () => SwitchComponent3Model());
  }

  @override
  void dispose() {
    switchModel1.dispose();
    switchModel2.dispose();
    switchModel3.dispose();
  }
}
