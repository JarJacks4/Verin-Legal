import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/log_entry_widget.dart';
import '/components/side_nav_widget.dart';
import '/components/switch_component_widget.dart';
import '/components/tab_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'matter_detail_clio_write_back_widget.dart'
    show MatterDetailClioWriteBackWidget;
import 'package:flutter/material.dart';

class MatterDetailClioWriteBackModel
    extends FlutterFlowModel<MatterDetailClioWriteBackWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in MatterDetailClioWriteBack widget.
  List<ClioSyncLogRecord>? syncLog;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for TabItem.
  late TabItemModel tabItemModel1;
  // Model for TabItem.
  late TabItemModel tabItemModel2;
  // Model for TabItem.
  late TabItemModel tabItemModel3;
  // Model for TabItem.
  late TabItemModel tabItemModel4;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Switch.
  late SwitchComponentModel switchModel1;
  // Model for Switch.
  late SwitchComponentModel switchModel2;
  // Model for Switch.
  late SwitchComponentModel switchModel3;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Stores action output result for [Custom Action - mockClioPush] action in Button widget.
  bool? pushSucceeded;
  // Model for LogEntry.
  late LogEntryModel logEntryModel1;
  // Model for LogEntry.
  late LogEntryModel logEntryModel2;
  // Model for LogEntry.
  late LogEntryModel logEntryModel3;
  // Model for LogEntry.
  late LogEntryModel logEntryModel4;
  // Model for LogEntry.
  late LogEntryModel logEntryModel5;
  // Model for Button.
  late ButtonModel buttonModel3;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    tabItemModel1 = createModel(context, () => TabItemModel());
    tabItemModel2 = createModel(context, () => TabItemModel());
    tabItemModel3 = createModel(context, () => TabItemModel());
    tabItemModel4 = createModel(context, () => TabItemModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    switchModel1 = createModel(context, () => SwitchComponentModel());
    switchModel2 = createModel(context, () => SwitchComponentModel());
    switchModel3 = createModel(context, () => SwitchComponentModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    logEntryModel1 = createModel(context, () => LogEntryModel());
    logEntryModel2 = createModel(context, () => LogEntryModel());
    logEntryModel3 = createModel(context, () => LogEntryModel());
    logEntryModel4 = createModel(context, () => LogEntryModel());
    logEntryModel5 = createModel(context, () => LogEntryModel());
    buttonModel3 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    tabItemModel1.dispose();
    tabItemModel2.dispose();
    tabItemModel3.dispose();
    tabItemModel4.dispose();
    buttonModel1.dispose();
    switchModel1.dispose();
    switchModel2.dispose();
    switchModel3.dispose();
    buttonModel2.dispose();
    logEntryModel1.dispose();
    logEntryModel2.dispose();
    logEntryModel3.dispose();
    logEntryModel4.dispose();
    logEntryModel5.dispose();
    buttonModel3.dispose();
  }
}
