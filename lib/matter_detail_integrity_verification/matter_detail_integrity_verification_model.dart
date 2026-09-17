import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/integrity_row_widget.dart';
import '/components/side_nav_widget.dart';
import '/components/source_verification_item_widget.dart';
import '/components/tab_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'matter_detail_integrity_verification_widget.dart'
    show MatterDetailIntegrityVerificationWidget;
import 'package:flutter/material.dart';

class MatterDetailIntegrityVerificationModel
    extends FlutterFlowModel<MatterDetailIntegrityVerificationWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in MatterDetailIntegrityVerification widget.
  ChainEntriesRecord? latestEntry;
  // Stores action output result for [Firestore Query - Query a collection] action in MatterDetailIntegrityVerification widget.
  int? matterItemCount;
  // Stores action output result for [Firestore Query - Query a collection] action in MatterDetailIntegrityVerification widget.
  List<StatementsRecord>? statements;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for TabItem.
  late TabItemModel tabItemModel1;
  // Model for TabItem.
  late TabItemModel tabItemModel2;
  // Model for TabItem.
  late TabItemModel tabItemModel3;
  // Model for TabItem.
  late TabItemModel tabItemModel4;
  // Model for Button.
  late ButtonModel buttonModel3;
  // Model for SourceVerificationItem.
  late SourceVerificationItemModel sourceVerificationItemModel1;
  // Model for SourceVerificationItem.
  late SourceVerificationItemModel sourceVerificationItemModel2;
  // Model for SourceVerificationItem.
  late SourceVerificationItemModel sourceVerificationItemModel3;
  // Model for IntegrityRow.
  late IntegrityRowModel integrityRowModel1;
  // Model for IntegrityRow.
  late IntegrityRowModel integrityRowModel2;
  // Model for IntegrityRow.
  late IntegrityRowModel integrityRowModel3;
  // Model for IntegrityRow.
  late IntegrityRowModel integrityRowModel4;
  // Model for Button.
  late ButtonModel buttonModel4;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    tabItemModel1 = createModel(context, () => TabItemModel());
    tabItemModel2 = createModel(context, () => TabItemModel());
    tabItemModel3 = createModel(context, () => TabItemModel());
    tabItemModel4 = createModel(context, () => TabItemModel());
    buttonModel3 = createModel(context, () => ButtonModel());
    sourceVerificationItemModel1 =
        createModel(context, () => SourceVerificationItemModel());
    sourceVerificationItemModel2 =
        createModel(context, () => SourceVerificationItemModel());
    sourceVerificationItemModel3 =
        createModel(context, () => SourceVerificationItemModel());
    integrityRowModel1 = createModel(context, () => IntegrityRowModel());
    integrityRowModel2 = createModel(context, () => IntegrityRowModel());
    integrityRowModel3 = createModel(context, () => IntegrityRowModel());
    integrityRowModel4 = createModel(context, () => IntegrityRowModel());
    buttonModel4 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    tabItemModel1.dispose();
    tabItemModel2.dispose();
    tabItemModel3.dispose();
    tabItemModel4.dispose();
    buttonModel3.dispose();
    sourceVerificationItemModel1.dispose();
    sourceVerificationItemModel2.dispose();
    sourceVerificationItemModel3.dispose();
    integrityRowModel1.dispose();
    integrityRowModel2.dispose();
    integrityRowModel3.dispose();
    integrityRowModel4.dispose();
    buttonModel4.dispose();
  }
}
