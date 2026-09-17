import '/components/settings_row_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'firm_user_profile_page_widget.dart' show FirmUserProfilePageWidget;
import 'package:flutter/material.dart';

class FirmUserProfilePageModel
    extends FlutterFlowModel<FirmUserProfilePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SettingsRow.
  late SettingsRowModel settingsRowModel1;
  // Model for SettingsRow.
  late SettingsRowModel settingsRowModel2;
  // Model for SettingsRow.
  late SettingsRowModel settingsRowModel3;

  @override
  void initState(BuildContext context) {
    settingsRowModel1 = createModel(context, () => SettingsRowModel());
    settingsRowModel2 = createModel(context, () => SettingsRowModel());
    settingsRowModel3 = createModel(context, () => SettingsRowModel());
  }

  @override
  void dispose() {
    settingsRowModel1.dispose();
    settingsRowModel2.dispose();
    settingsRowModel3.dispose();
  }
}
