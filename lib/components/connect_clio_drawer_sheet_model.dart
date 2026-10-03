import '/components/button18_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'connect_clio_drawer_sheet_widget.dart'
    show ConnectClioDrawerSheetWidget;
import 'package:flutter/material.dart';

class ConnectClioDrawerSheetModel
    extends FlutterFlowModel<ConnectClioDrawerSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for TextField.
  late TextField10Model textFieldModel;
  // Model for Button.
  late Button18Model buttonModel;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    textFieldModel = createModel(context, () => TextField10Model());
    buttonModel = createModel(context, () => Button18Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    textFieldModel.dispose();
    buttonModel.dispose();
  }
}
