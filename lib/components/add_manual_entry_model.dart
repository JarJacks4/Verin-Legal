import '/components/text_field9_widget.dart';
import '/components/upload_dropzone_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'add_manual_entry_widget.dart' show AddManualEntryWidget;
import 'package:flutter/material.dart';

class AddManualEntryModel extends FlutterFlowModel<AddManualEntryWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for TextField.
  late TextField9Model textFieldModel1;
  // Model for TextField.
  late TextField9Model textFieldModel2;
  // Model for TextField.
  late TextField9Model textFieldModel3;
  // Model for TextField.
  late TextField9Model textFieldModel4;
  // Model for TextField.
  late TextField9Model textFieldModel5;
  // Model for UploadDropzone component.
  late UploadDropzoneModel uploadDropzoneModel;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    textFieldModel1 = createModel(context, () => TextField9Model());
    textFieldModel2 = createModel(context, () => TextField9Model());
    textFieldModel3 = createModel(context, () => TextField9Model());
    textFieldModel4 = createModel(context, () => TextField9Model());
    textFieldModel5 = createModel(context, () => TextField9Model());
    uploadDropzoneModel = createModel(context, () => UploadDropzoneModel());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    textFieldModel3.dispose();
    textFieldModel4.dispose();
    textFieldModel5.dispose();
    uploadDropzoneModel.dispose();
  }
}
