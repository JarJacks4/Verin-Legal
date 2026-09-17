import '/components/nav_item4_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'side_nav_widget.dart' show SideNavWidget;
import 'package:flutter/material.dart';

class SideNavModel extends FlutterFlowModel<SideNavWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for NavItem.
  late NavItem4Model navItemModel1;
  // Model for NavItem.
  late NavItem4Model navItemModel2;
  // Model for NavItem.
  late NavItem4Model navItemModel3;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered1 = false;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered2 = false;

  @override
  void initState(BuildContext context) {
    navItemModel1 = createModel(context, () => NavItem4Model());
    navItemModel2 = createModel(context, () => NavItem4Model());
    navItemModel3 = createModel(context, () => NavItem4Model());
  }

  @override
  void dispose() {
    navItemModel1.dispose();
    navItemModel2.dispose();
    navItemModel3.dispose();
  }
}
