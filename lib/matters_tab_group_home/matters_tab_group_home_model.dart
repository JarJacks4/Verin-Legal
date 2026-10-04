import '/components/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'matters_tab_group_home_widget.dart' show MattersTabGroupHomeWidget;
import 'package:flutter/material.dart';

// Matter Detail page model. The tab bodies are hand-written widgets in
// lib/verin/matter/ that keep their own state, so this only holds the side
// nav and the tab controller.
class MattersTabGroupHomeModel
    extends FlutterFlowModel<MattersTabGroupHomeWidget> {
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    tabBarController?.dispose();
  }
}
