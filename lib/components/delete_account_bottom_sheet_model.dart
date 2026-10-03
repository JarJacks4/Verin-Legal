import '/components/button8_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'delete_account_bottom_sheet_widget.dart'
    show DeleteAccountBottomSheetWidget;
import 'package:flutter/material.dart';

class DeleteAccountBottomSheetModel
    extends FlutterFlowModel<DeleteAccountBottomSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late Button8Model buttonModel1;
  // Model for Button.
  late Button8Model buttonModel2;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => Button8Model());
    buttonModel2 = createModel(context, () => Button8Model());
  }

  @override
  void dispose() {
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
