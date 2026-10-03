import '/components/button19_widget.dart';
import '/components/hash_row_widget.dart';
import '/components/heading_verin_comp_widget.dart';
import '/components/integrity_card_widget.dart';
import '/components/tab_item5_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'tabs_comp_widget.dart' show TabsCompWidget;
import 'package:flutter/material.dart';

class TabsCompModel extends FlutterFlowModel<TabsCompWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for HeadingVerinComp component.
  late HeadingVerinCompModel headingVerinCompModel;
  // Model for TabItem.
  late TabItem5Model tabItemModel1;
  // Model for TabItem.
  late TabItem5Model tabItemModel2;
  // Model for TabItem.
  late TabItem5Model tabItemModel3;
  // Model for TabItem.
  late TabItem5Model tabItemModel4;
  // Model for TabItem.
  late TabItem5Model tabItemModel5;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel1;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel2;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel3;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel4;
  // Model for HashRow.
  late HashRowModel hashRowModel1;
  // Model for HashRow.
  late HashRowModel hashRowModel2;
  // Model for HashRow.
  late HashRowModel hashRowModel3;
  // Model for HashRow.
  late HashRowModel hashRowModel4;
  // Model for HashRow.
  late HashRowModel hashRowModel5;
  // Model for HashRow.
  late HashRowModel hashRowModel6;
  // Model for Button.
  late Button19Model buttonModel1;
  // Model for Button.
  late Button19Model buttonModel2;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    headingVerinCompModel = createModel(context, () => HeadingVerinCompModel());
    tabItemModel1 = createModel(context, () => TabItem5Model());
    tabItemModel2 = createModel(context, () => TabItem5Model());
    tabItemModel3 = createModel(context, () => TabItem5Model());
    tabItemModel4 = createModel(context, () => TabItem5Model());
    tabItemModel5 = createModel(context, () => TabItem5Model());
    integrityCardModel1 = createModel(context, () => IntegrityCardModel());
    integrityCardModel2 = createModel(context, () => IntegrityCardModel());
    integrityCardModel3 = createModel(context, () => IntegrityCardModel());
    integrityCardModel4 = createModel(context, () => IntegrityCardModel());
    hashRowModel1 = createModel(context, () => HashRowModel());
    hashRowModel2 = createModel(context, () => HashRowModel());
    hashRowModel3 = createModel(context, () => HashRowModel());
    hashRowModel4 = createModel(context, () => HashRowModel());
    hashRowModel5 = createModel(context, () => HashRowModel());
    hashRowModel6 = createModel(context, () => HashRowModel());
    buttonModel1 = createModel(context, () => Button19Model());
    buttonModel2 = createModel(context, () => Button19Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    headingVerinCompModel.dispose();
    tabItemModel1.dispose();
    tabItemModel2.dispose();
    tabItemModel3.dispose();
    tabItemModel4.dispose();
    tabItemModel5.dispose();
    integrityCardModel1.dispose();
    integrityCardModel2.dispose();
    integrityCardModel3.dispose();
    integrityCardModel4.dispose();
    hashRowModel1.dispose();
    hashRowModel2.dispose();
    hashRowModel3.dispose();
    hashRowModel4.dispose();
    hashRowModel5.dispose();
    hashRowModel6.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
