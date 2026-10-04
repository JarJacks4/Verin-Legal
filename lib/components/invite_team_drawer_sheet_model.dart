import '/components/button18_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'invite_team_drawer_sheet_widget.dart' show InviteTeamDrawerSheetWidget;
import 'package:flutter/material.dart';

class InviteTeamDrawerSheetModel
    extends FlutterFlowModel<InviteTeamDrawerSheetWidget> {
  ///  Local state fields for this component.

  // Role chip selection (stored on the TeamMembers doc as-is).
  String selectedRole = 'Paralegal';
  // True while the invitation is being saved.
  bool sending = false;
  // Validation / save error shown under the form.
  String? errorText;

  ///  State fields for stateful widgets in this component.

  // Model for TextField.
  late TextField10Model textFieldModel1;
  // Model for TextField.
  late TextField10Model textFieldModel2;
  // State field(s) for Row widget.
  ScrollController? rowScrollController;
  // Model for Button.
  late Button18Model buttonModel;

  @override
  void initState(BuildContext context) {
    textFieldModel1 = createModel(context, () => TextField10Model());
    textFieldModel2 = createModel(context, () => TextField10Model());
    rowScrollController = ScrollController();
    buttonModel = createModel(context, () => Button18Model());
  }

  @override
  void dispose() {
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    rowScrollController?.dispose();
    buttonModel.dispose();
  }
}
