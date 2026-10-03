import '/flutter_flow/flutter_flow_util.dart';
import 'same_deep_teal2_widget.dart' show SameDeepTeal2Widget;
import 'package:flutter/material.dart';

class SameDeepTeal2Model extends FlutterFlowModel<SameDeepTeal2Widget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Column widget.
  ScrollController? columnScrollController;

  @override
  void initState(BuildContext context) {
    columnScrollController = ScrollController();
  }

  @override
  void dispose() {
    columnScrollController?.dispose();
  }
}
