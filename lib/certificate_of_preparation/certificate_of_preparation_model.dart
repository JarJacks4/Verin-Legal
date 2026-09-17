import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/meta_row_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'certificate_of_preparation_widget.dart'
    show CertificateOfPreparationWidget;
import 'package:flutter/material.dart';

class CertificateOfPreparationModel
    extends FlutterFlowModel<CertificateOfPreparationWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in CertificateOfPreparation widget.
  List<ItemsRecord>? allItems;
  // Stores action output result for [Firestore Query - Query a collection] action in CertificateOfPreparation widget.
  ChainEntriesRecord? latestEntry;
  // Stores action output result for [Custom Action - summarizeItems] action in CertificateOfPreparation widget.
  dynamic itemCounts;
  // Stores action output result for [Custom Action - computeGapsAndAccuracy] action in CertificateOfPreparation widget.
  dynamic gapsAndAccuracy;
  // Model for Button.
  late ButtonModel buttonModel;
  // Model for MetaRow.
  late MetaRowModel metaRowModel1;
  // Model for MetaRow.
  late MetaRowModel metaRowModel2;
  // Model for MetaRow.
  late MetaRowModel metaRowModel3;
  // Model for MetaRow.
  late MetaRowModel metaRowModel4;
  // Model for MetaRow.
  late MetaRowModel metaRowModel5;
  // Model for MetaRow.
  late MetaRowModel metaRowModel6;
  // Model for MetaRow.
  late MetaRowModel metaRowModel7;
  // Model for MetaRow.
  late MetaRowModel metaRowModel8;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => ButtonModel());
    metaRowModel1 = createModel(context, () => MetaRowModel());
    metaRowModel2 = createModel(context, () => MetaRowModel());
    metaRowModel3 = createModel(context, () => MetaRowModel());
    metaRowModel4 = createModel(context, () => MetaRowModel());
    metaRowModel5 = createModel(context, () => MetaRowModel());
    metaRowModel6 = createModel(context, () => MetaRowModel());
    metaRowModel7 = createModel(context, () => MetaRowModel());
    metaRowModel8 = createModel(context, () => MetaRowModel());
  }

  @override
  void dispose() {
    buttonModel.dispose();
    metaRowModel1.dispose();
    metaRowModel2.dispose();
    metaRowModel3.dispose();
    metaRowModel4.dispose();
    metaRowModel5.dispose();
    metaRowModel6.dispose();
    metaRowModel7.dispose();
    metaRowModel8.dispose();
  }
}
