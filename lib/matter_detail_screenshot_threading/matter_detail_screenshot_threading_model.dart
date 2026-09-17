import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/side_nav_widget.dart';
import '/components/tab_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'matter_detail_screenshot_threading_widget.dart'
    show MatterDetailScreenshotThreadingWidget;
import 'package:flutter/material.dart';

class MatterDetailScreenshotThreadingModel
    extends FlutterFlowModel<MatterDetailScreenshotThreadingWidget> {
  ///  Local state fields for this page.

  String? highlightedUrl;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in MatterDetailScreenshotThreading widget.
  ItemsRecord? threadItem;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for Button.
  late ButtonModel buttonModel;
  // Model for TabItem.
  late TabItemModel tabItemModel1;
  // Model for TabItem.
  late TabItemModel tabItemModel2;
  // Model for TabItem.
  late TabItemModel tabItemModel3;
  // Model for TabItem.
  late TabItemModel tabItemModel4;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    buttonModel = createModel(context, () => ButtonModel());
    tabItemModel1 = createModel(context, () => TabItemModel());
    tabItemModel2 = createModel(context, () => TabItemModel());
    tabItemModel3 = createModel(context, () => TabItemModel());
    tabItemModel4 = createModel(context, () => TabItemModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    buttonModel.dispose();
    tabItemModel1.dispose();
    tabItemModel2.dispose();
    tabItemModel3.dispose();
    tabItemModel4.dispose();
  }
}
