import '/components/kpi_card_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_dash_board_page_widget.dart' show AdminDashBoardPageWidget;
import 'package:flutter/material.dart';

class AdminDashBoardPageModel
    extends FlutterFlowModel<AdminDashBoardPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SideNavAdmin component.
  late SideNavAdminModel sideNavAdminModel;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel1;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel2;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel3;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel4;

  @override
  void initState(BuildContext context) {
    sideNavAdminModel = createModel(context, () => SideNavAdminModel());
    columnScrollController = ScrollController();
    kpiCardModel1 = createModel(context, () => KpiCardModel());
    kpiCardModel2 = createModel(context, () => KpiCardModel());
    kpiCardModel3 = createModel(context, () => KpiCardModel());
    kpiCardModel4 = createModel(context, () => KpiCardModel());
  }

  @override
  void dispose() {
    sideNavAdminModel.dispose();
    columnScrollController?.dispose();
    kpiCardModel1.dispose();
    kpiCardModel2.dispose();
    kpiCardModel3.dispose();
    kpiCardModel4.dispose();
  }
}
