import '/components/create_account_step1_comp_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'create_account_step1_widget.dart' show CreateAccountStep1Widget;
import 'package:flutter/material.dart';

class CreateAccountStep1Model
    extends FlutterFlowModel<CreateAccountStep1Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for CreateAccountStep1Comp component.
  late CreateAccountStep1CompModel createAccountStep1CompModel;

  @override
  void initState(BuildContext context) {
    createAccountStep1CompModel =
        createModel(context, () => CreateAccountStep1CompModel());
  }

  @override
  void dispose() {
    createAccountStep1CompModel.dispose();
  }
}
