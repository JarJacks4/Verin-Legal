import '/components/button19_copy_widget.dart';
import '/components/button19_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'welcome_to_verin_comp_widget.dart' show WelcomeToVerinCompWidget;
import 'package:flutter/material.dart';

class WelcomeToVerinCompModel
    extends FlutterFlowModel<WelcomeToVerinCompWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late Button19Model buttonModel;
  // Model for Button19Copy component.
  late Button19CopyModel button19CopyModel;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => Button19Model());
    button19CopyModel = createModel(context, () => Button19CopyModel());
  }

  @override
  void dispose() {
    buttonModel.dispose();
    button19CopyModel.dispose();
  }
}
