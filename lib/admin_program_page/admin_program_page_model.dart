import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_program_page_widget.dart' show AdminProgramPageWidget;
import 'package:flutter/material.dart';

class AdminProgramPageModel extends FlutterFlowModel<AdminProgramPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SideNavAdmin component.
  late SideNavAdminModel sideNavAdminModel;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;

  @override
  void initState(BuildContext context) {
    sideNavAdminModel = createModel(context, () => SideNavAdminModel());
    columnScrollController = ScrollController();
  }

  @override
  void dispose() {
    sideNavAdminModel.dispose();
    columnScrollController?.dispose();
  }
}
