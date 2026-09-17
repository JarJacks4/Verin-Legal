import '/components/button6_widget.dart';
import '/components/text_field4_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'expandable_missing_evidence_widget.dart'
    show ExpandableMissingEvidenceWidget;
import 'package:flutter/material.dart';

class ExpandableMissingEvidenceModel
    extends FlutterFlowModel<ExpandableMissingEvidenceWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TextField.
  late TextField4Model textFieldModel;
  // Model for Button.
  late Button6Model buttonModel1;
  // Model for Button.
  late Button6Model buttonModel2;

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextField4Model());
    buttonModel1 = createModel(context, () => Button6Model());
    buttonModel2 = createModel(context, () => Button6Model());
  }

  @override
  void dispose() {
    textFieldModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
