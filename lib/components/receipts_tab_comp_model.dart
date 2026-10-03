import '/components/button18_widget.dart';
import '/components/status_badge22_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'receipts_tab_comp_widget.dart' show ReceiptsTabCompWidget;
import 'package:flutter/material.dart';

class ReceiptsTabCompModel extends FlutterFlowModel<ReceiptsTabCompWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for Button.
  late Button18Model buttonModel;
  // Model for TextField.
  late TextField10Model textFieldModel;
  // Model for StatusBadge.
  late StatusBadge22Model statusBadgeModel1;
  // Model for StatusBadge.
  late StatusBadge22Model statusBadgeModel2;
  // Model for StatusBadge.
  late StatusBadge22Model statusBadgeModel3;
  // Model for StatusBadge.
  late StatusBadge22Model statusBadgeModel4;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    buttonModel = createModel(context, () => Button18Model());
    textFieldModel = createModel(context, () => TextField10Model());
    statusBadgeModel1 = createModel(context, () => StatusBadge22Model());
    statusBadgeModel2 = createModel(context, () => StatusBadge22Model());
    statusBadgeModel3 = createModel(context, () => StatusBadge22Model());
    statusBadgeModel4 = createModel(context, () => StatusBadge22Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    buttonModel.dispose();
    textFieldModel.dispose();
    statusBadgeModel1.dispose();
    statusBadgeModel2.dispose();
    statusBadgeModel3.dispose();
    statusBadgeModel4.dispose();
  }
}
