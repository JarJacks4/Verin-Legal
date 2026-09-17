import '/components/button5_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'confirm_approve_reject_widget.dart' show ConfirmApproveRejectWidget;
import 'package:flutter/material.dart';

class ConfirmApproveRejectModel
    extends FlutterFlowModel<ConfirmApproveRejectWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late Button5Model buttonModel1;
  // Model for Button.
  late Button5Model buttonModel2;
  // Model for Button.
  late Button5Model buttonModel3;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => Button5Model());
    buttonModel2 = createModel(context, () => Button5Model());
    buttonModel3 = createModel(context, () => Button5Model());
  }

  @override
  void dispose() {
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
  }
}
