import '/components/status_badge3_widget.dart';
import '/components/welcome_to_verin_comp_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'welcome_screen_widget.dart' show WelcomeScreenWidget;
import 'package:flutter/material.dart';

class WelcomeScreenModel extends FlutterFlowModel<WelcomeScreenWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StatusBadge.
  late StatusBadge3Model statusBadgeModel;
  // Model for WelcomeToVerinComp component.
  late WelcomeToVerinCompModel welcomeToVerinCompModel;

  @override
  void initState(BuildContext context) {
    statusBadgeModel = createModel(context, () => StatusBadge3Model());
    welcomeToVerinCompModel =
        createModel(context, () => WelcomeToVerinCompModel());
  }

  @override
  void dispose() {
    statusBadgeModel.dispose();
    welcomeToVerinCompModel.dispose();
  }
}
