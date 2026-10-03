import '/components/archive_file_widget.dart';
import '/components/button18_widget.dart';
import '/components/instruction_step_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'standalone_verify_tool_drawer_sheet_widget.dart'
    show StandaloneVerifyToolDrawerSheetWidget;
import 'package:flutter/material.dart';

class StandaloneVerifyToolDrawerSheetModel
    extends FlutterFlowModel<StandaloneVerifyToolDrawerSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for InstructionStep.
  late InstructionStepModel instructionStepModel1;
  // Model for InstructionStep.
  late InstructionStepModel instructionStepModel2;
  // Model for InstructionStep.
  late InstructionStepModel instructionStepModel3;
  // Model for InstructionStep.
  late InstructionStepModel instructionStepModel4;
  // Model for ArchiveFile.
  late ArchiveFileModel archiveFileModel1;
  // Model for ArchiveFile.
  late ArchiveFileModel archiveFileModel2;
  // Model for ArchiveFile.
  late ArchiveFileModel archiveFileModel3;
  // Model for ArchiveFile.
  late ArchiveFileModel archiveFileModel4;
  // Model for Button.
  late Button18Model buttonModel1;
  // Model for Button.
  late Button18Model buttonModel2;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    instructionStepModel1 = createModel(context, () => InstructionStepModel());
    instructionStepModel2 = createModel(context, () => InstructionStepModel());
    instructionStepModel3 = createModel(context, () => InstructionStepModel());
    instructionStepModel4 = createModel(context, () => InstructionStepModel());
    archiveFileModel1 = createModel(context, () => ArchiveFileModel());
    archiveFileModel2 = createModel(context, () => ArchiveFileModel());
    archiveFileModel3 = createModel(context, () => ArchiveFileModel());
    archiveFileModel4 = createModel(context, () => ArchiveFileModel());
    buttonModel1 = createModel(context, () => Button18Model());
    buttonModel2 = createModel(context, () => Button18Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    instructionStepModel1.dispose();
    instructionStepModel2.dispose();
    instructionStepModel3.dispose();
    instructionStepModel4.dispose();
    archiveFileModel1.dispose();
    archiveFileModel2.dispose();
    archiveFileModel3.dispose();
    archiveFileModel4.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
