import '/components/button18_widget.dart';
import '/components/form_label_widget.dart';
import '/components/sheet_field_widget.dart';
import '/components/upload_dropzone_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'create_new_matter_bottom_sheet_widget.dart'
    show CreateNewMatterBottomSheetWidget;
import 'package:flutter/material.dart';

class CreateNewMatterBottomSheetModel
    extends FlutterFlowModel<CreateNewMatterBottomSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for SheetField.
  late SheetFieldModel sheetFieldModel1;
  // Model for SheetField.
  late SheetFieldModel sheetFieldModel2;
  // Model for SheetField.
  late SheetFieldModel sheetFieldModel3;
  // Model for FormLabel.
  late FormLabelModel formLabelModel1;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for FormLabel.
  late FormLabelModel formLabelModel2;
  // Model for UploadDropzone component.
  late UploadDropzoneModel uploadDropzoneModel;
  // Model for Button.
  late Button18Model buttonModel1;
  // Model for Button.
  late Button18Model buttonModel2;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    sheetFieldModel1 = createModel(context, () => SheetFieldModel());
    sheetFieldModel2 = createModel(context, () => SheetFieldModel());
    sheetFieldModel3 = createModel(context, () => SheetFieldModel());
    formLabelModel1 = createModel(context, () => FormLabelModel());
    formLabelModel2 = createModel(context, () => FormLabelModel());
    uploadDropzoneModel = createModel(context, () => UploadDropzoneModel());
    buttonModel1 = createModel(context, () => Button18Model());
    buttonModel2 = createModel(context, () => Button18Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    sheetFieldModel1.dispose();
    sheetFieldModel2.dispose();
    sheetFieldModel3.dispose();
    formLabelModel1.dispose();
    formLabelModel2.dispose();
    uploadDropzoneModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
