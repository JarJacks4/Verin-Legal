import '/backend/backend.dart';
import '/components/nav_item4_widget.dart';
import '/components/sidebar_brand_capsule_widget.dart';
import '/components/user_profile_capsule_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'side_nav_widget.dart' show SideNavWidget;
import 'package:flutter/material.dart';

class SideNavModel extends FlutterFlowModel<SideNavWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Firestore Query - Query a collection] action in SideNav widget.
  List<MattersRecord>? profileRead;
  // Model for NavItem.
  late NavItem4Model navItemModel1;
  // Model for NavItem.
  late NavItem4Model navItemModel2;
  // Model for NavItem.
  late NavItem4Model navItemModel3;
  // Model for SidebarBrandCapsule.
  late SidebarBrandCapsuleModel sidebarBrandCapsuleModel;
  // Model for UserProfileCapsule.
  late UserProfileCapsuleModel userProfileCapsuleModel;

  @override
  void initState(BuildContext context) {
    navItemModel1 = createModel(context, () => NavItem4Model());
    navItemModel2 = createModel(context, () => NavItem4Model());
    navItemModel3 = createModel(context, () => NavItem4Model());
    sidebarBrandCapsuleModel =
        createModel(context, () => SidebarBrandCapsuleModel());
    userProfileCapsuleModel =
        createModel(context, () => UserProfileCapsuleModel());
  }

  @override
  void dispose() {
    navItemModel1.dispose();
    navItemModel2.dispose();
    navItemModel3.dispose();
    sidebarBrandCapsuleModel.dispose();
    userProfileCapsuleModel.dispose();
  }
}
