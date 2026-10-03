import '/components/table_row_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'provider_section_widget.dart' show ProviderSectionWidget;
import 'package:flutter/material.dart';

class ProviderSectionModel extends FlutterFlowModel<ProviderSectionWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TableRow.
  late TableRowModel tableRowModel1;
  // Model for TableRow.
  late TableRowModel tableRowModel2;

  @override
  void initState(BuildContext context) {
    tableRowModel1 = createModel(context, () => TableRowModel());
    tableRowModel2 = createModel(context, () => TableRowModel());
  }

  @override
  void dispose() {
    tableRowModel1.dispose();
    tableRowModel2.dispose();
  }
}
