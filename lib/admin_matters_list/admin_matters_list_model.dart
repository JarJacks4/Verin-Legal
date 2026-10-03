import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admin_matters_list_widget.dart' show AdminMattersListWidget;
import 'package:flutter/material.dart';

class AdminMattersListModel extends FlutterFlowModel<AdminMattersListWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SideNavAdmin component.
  late SideNavAdminModel sideNavAdminModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - filterMattersLocally] action in TextField widget.
  List<MattersRecord>? filteredMattersList;
  // Stores action output result for [Bottom Sheet - FilterSortMatters] action in IconButton widget.
  List<MattersRecord>? filterSortResult;
  // Model for Button.
  late ButtonModel buttonModel;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;

  @override
  void initState(BuildContext context) {
    sideNavAdminModel = createModel(context, () => SideNavAdminModel());
    buttonModel = createModel(context, () => ButtonModel());
    columnScrollController = ScrollController();
  }

  @override
  void dispose() {
    sideNavAdminModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    buttonModel.dispose();
    columnScrollController?.dispose();
  }
}
