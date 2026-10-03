import '/flutter_flow/flutter_flow_util.dart';
import 'receipt_details_drawer_sheet_widget.dart'
    show ReceiptDetailsDrawerSheetWidget;
import 'package:flutter/material.dart';

class ReceiptDetailsDrawerSheetModel
    extends FlutterFlowModel<ReceiptDetailsDrawerSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // State field(s) for Row widget.
  ScrollController? rowScrollController;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    rowScrollController = ScrollController();
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    rowScrollController?.dispose();
  }
}
