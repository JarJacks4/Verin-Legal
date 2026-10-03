import '/components/button22_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'user_profile_modal_widget.dart' show UserProfileModalWidget;
import 'package:flutter/material.dart';

class UserProfileModalModel extends FlutterFlowModel<UserProfileModalWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for Button.
  late Button22Model buttonModel;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    buttonModel = createModel(context, () => Button22Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    buttonModel.dispose();
  }
}
