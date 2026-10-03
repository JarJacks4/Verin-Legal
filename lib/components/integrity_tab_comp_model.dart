import '/components/button19_widget.dart';
import '/components/hash_row_widget.dart';
import '/components/integrity_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'integrity_tab_comp_widget.dart' show IntegrityTabCompWidget;
import 'package:flutter/material.dart';

class IntegrityTabCompModel extends FlutterFlowModel<IntegrityTabCompWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
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
