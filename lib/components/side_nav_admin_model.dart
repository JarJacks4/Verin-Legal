import '/components/sidebar_brand_capsule_widget.dart';
import '/components/sidebar_nav_item_widget.dart';
import '/components/user_profile_capsule_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'side_nav_admin_widget.dart' show SideNavAdminWidget;
import 'package:flutter/material.dart';

class SideNavAdminModel extends FlutterFlowModel<SideNavAdminWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for SidebarNavItem.
  late SidebarNavItemModel sidebarNavItemModel1;
  // Model for SidebarNavItem.
  late SidebarNavItemModel sidebarNavItemModel2;
  // Model for SidebarNavItem.
  late SidebarNavItemModel sidebarNavItemModel3;
  // Model for SidebarNavItem.
  late SidebarNavItemModel sidebarNavItemModel4;
  // Model for SidebarNavItem.
  late SidebarNavItemModel sidebarNavItemModel5;
  // Model for SidebarNavItem.
  late SidebarNavItemModel sidebarNavItemModel6;
  // Model for SidebarBrandCapsule.
  late SidebarBrandCapsuleModel sidebarBrandCapsuleModel;
  // Model for UserProfileCapsule.
  late UserProfileCapsuleModel userProfileCapsuleModel;

  @override
  void initState(BuildContext context) {
    sidebarNavItemModel1 = createModel(context, () => SidebarNavItemModel());
    sidebarNavItemModel2 = createModel(context, () => SidebarNavItemModel());
    sidebarNavItemModel3 = createModel(context, () => SidebarNavItemModel());
    sidebarNavItemModel4 = createModel(context, () => SidebarNavItemModel());
    sidebarNavItemModel5 = createModel(context, () => SidebarNavItemModel());
    sidebarNavItemModel6 = createModel(context, () => SidebarNavItemModel());
    sidebarBrandCapsuleModel =
        createModel(context, () => SidebarBrandCapsuleModel());
    userProfileCapsuleModel =
        createModel(context, () => UserProfileCapsuleModel());
  }

  @override
  void dispose() {
    sidebarNavItemModel1.dispose();
    sidebarNavItemModel2.dispose();
    sidebarNavItemModel3.dispose();
    sidebarNavItemModel4.dispose();
    sidebarNavItemModel5.dispose();
    sidebarNavItemModel6.dispose();
    sidebarBrandCapsuleModel.dispose();
    userProfileCapsuleModel.dispose();
  }
}
