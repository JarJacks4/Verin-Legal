import '/components/tab_item2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'tab_group_widget.dart' show TabGroupWidget;
import 'package:flutter/material.dart';

class TabGroupModel extends FlutterFlowModel<TabGroupWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TabItem.
  late TabItem2Model tabItemModel1;
  // Model for TabItem.
  late TabItem2Model tabItemModel2;
  // Model for TabItem.
  late TabItem2Model tabItemModel3;
  // Model for TabItem.
  late TabItem2Model tabItemModel4;
  // Model for TabItem.
  late TabItem2Model tabItemModel5;

  @override
  void initState(BuildContext context) {
    tabItemModel1 = createModel(context, () => TabItem2Model());
    tabItemModel2 = createModel(context, () => TabItem2Model());
    tabItemModel3 = createModel(context, () => TabItem2Model());
    tabItemModel4 = createModel(context, () => TabItem2Model());
    tabItemModel5 = createModel(context, () => TabItem2Model());
  }

  @override
  void dispose() {
    tabItemModel1.dispose();
    tabItemModel2.dispose();
    tabItemModel3.dispose();
    tabItemModel4.dispose();
    tabItemModel5.dispose();
  }
}
