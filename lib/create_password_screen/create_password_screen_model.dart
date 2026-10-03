import '/components/button18_widget.dart';
import '/components/feature_row_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'create_password_screen_widget.dart' show CreatePasswordScreenWidget;
import 'package:flutter/material.dart';

class CreatePasswordScreenModel
    extends FlutterFlowModel<CreatePasswordScreenWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for FeatureRow.
  late FeatureRowModel featureRowModel1;
  // Model for FeatureRow.
  late FeatureRowModel featureRowModel2;
  // Model for FeatureRow.
  late FeatureRowModel featureRowModel3;
  // Model for TextField.
  late TextField10Model textFieldModel1;
  // Model for TextField.
  late TextField10Model textFieldModel2;
  // Model for TextField.
  late TextField10Model textFieldModel3;
  // Model for Button.
  late Button18Model buttonModel1;
  // Model for Button.
  late Button18Model buttonModel2;

  @override
  void initState(BuildContext context) {
    featureRowModel1 = createModel(context, () => FeatureRowModel());
    featureRowModel2 = createModel(context, () => FeatureRowModel());
    featureRowModel3 = createModel(context, () => FeatureRowModel());
    textFieldModel1 = createModel(context, () => TextField10Model());
    textFieldModel2 = createModel(context, () => TextField10Model());
    textFieldModel3 = createModel(context, () => TextField10Model());
    buttonModel1 = createModel(context, () => Button18Model());
    buttonModel2 = createModel(context, () => Button18Model());
  }

  @override
  void dispose() {
    featureRowModel1.dispose();
    featureRowModel2.dispose();
    featureRowModel3.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
