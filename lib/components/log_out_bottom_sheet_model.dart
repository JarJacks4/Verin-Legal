import '/components/button8_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'log_out_bottom_sheet_widget.dart' show LogOutBottomSheetWidget;
import 'package:flutter/material.dart';

class LogOutBottomSheetModel extends FlutterFlowModel<LogOutBottomSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late Button8Model buttonModel;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => Button8Model());
  }

  @override
  void dispose() {
    buttonModel.dispose();
  }
}
