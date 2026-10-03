import '/components/button21_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'integration_report_widget.dart' show IntegrationReportWidget;
import 'package:flutter/material.dart';

class IntegrationReportModel extends FlutterFlowModel<IntegrationReportWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;
  // Model for Button.
  late Button21Model buttonModel1;
  // Model for Button.
  late Button21Model buttonModel2;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
    buttonModel1 = createModel(context, () => Button21Model());
    buttonModel2 = createModel(context, () => Button21Model());
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
