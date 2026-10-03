import '/components/button6_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'expandable_missing_evidence_widget.dart'
    show ExpandableMissingEvidenceWidget;
import 'package:flutter/material.dart';

class ExpandableMissingEvidenceModel
    extends FlutterFlowModel<ExpandableMissingEvidenceWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for Button.
  late Button6Model buttonModel1;
  // Model for Button.
  late Button6Model buttonModel2;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => Button6Model());
    buttonModel2 = createModel(context, () => Button6Model());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
