import '/components/create_password_comp_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'create_account_step2_widget.dart' show CreateAccountStep2Widget;
import 'package:flutter/material.dart';

class CreateAccountStep2Model
    extends FlutterFlowModel<CreateAccountStep2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for CreatePasswordComp component.
  late CreatePasswordCompModel createPasswordCompModel;

  @override
  void initState(BuildContext context) {
    createPasswordCompModel =
        createModel(context, () => CreatePasswordCompModel());
  }

  @override
  void dispose() {
    createPasswordCompModel.dispose();
  }
}
