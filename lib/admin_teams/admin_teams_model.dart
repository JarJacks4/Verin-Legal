import '/components/button13_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_teams_widget.dart' show AdminTeamsWidget;
import 'package:flutter/material.dart';

class AdminTeamsModel extends FlutterFlowModel<AdminTeamsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SideNavAdmin component.
  late SideNavAdminModel sideNavAdminModel;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for Button.
  late Button13Model buttonModel;

  @override
  void initState(BuildContext context) {
    sideNavAdminModel = createModel(context, () => SideNavAdminModel());
    columnScrollController = ScrollController();
    buttonModel = createModel(context, () => Button13Model());
  }

  @override
  void dispose() {
    sideNavAdminModel.dispose();
    columnScrollController?.dispose();
    buttonModel.dispose();
  }
}
