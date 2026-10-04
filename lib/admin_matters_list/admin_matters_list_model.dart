import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
  // Search text applied to the matters list (client-side).
  String searchText = '';
  // Stores action output result for [Bottom Sheet - FilterSortMatters] action in IconButton widget.
  List<MattersRecord>? filterSortResult;
  // Matter ids (in the sheet's sort order) from the last applied
  // Filter & Sort, or null when no filter is applied.
  List<String>? filterIds;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    sideNavAdminModel = createModel(context, () => SideNavAdminModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    sideNavAdminModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    buttonModel.dispose();
  }
}
