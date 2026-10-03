import '/components/form_label_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'sheet_field_widget.dart' show SheetFieldWidget;
import 'package:flutter/material.dart';

class SheetFieldModel extends FlutterFlowModel<SheetFieldWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for FormLabel.
  late FormLabelModel formLabelModel;
  // Model for TextField.
  late TextField10Model textFieldModel;

  @override
  void initState(BuildContext context) {
    formLabelModel = createModel(context, () => FormLabelModel());
    textFieldModel = createModel(context, () => TextField10Model());
  }

  @override
  void dispose() {
    formLabelModel.dispose();
    textFieldModel.dispose();
  }
}
