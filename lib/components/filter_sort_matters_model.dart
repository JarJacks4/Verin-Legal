import '/backend/backend.dart';
import '/components/button4_widget.dart';
import '/components/radio_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'filter_sort_matters_widget.dart' show FilterSortMattersWidget;
import 'package:flutter/material.dart';

class FilterSortMattersModel extends FlutterFlowModel<FilterSortMattersWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - sortAndFilterMatters] action in Text widget.
  List<MattersRecord>? filterReset;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for Radio.
  late RadioModel radioModel1;
  // Model for Radio.
  late RadioModel radioModel2;
  // Model for Radio.
  late RadioModel radioModel3;
  // Model for Button.
  late Button4Model buttonModel;
  // Stores action output result for [Custom Action - sortAndFilterMatters] action in Button widget.
  List<MattersRecord>? filteredLists;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    radioModel1 = createModel(context, () => RadioModel());
    radioModel2 = createModel(context, () => RadioModel());
    radioModel3 = createModel(context, () => RadioModel());
    buttonModel = createModel(context, () => Button4Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    radioModel1.dispose();
    radioModel2.dispose();
    radioModel3.dispose();
    buttonModel.dispose();
  }
}
