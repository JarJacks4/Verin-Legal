import '/components/evidence_thumb_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'thread_tab_comp_widget.dart' show ThreadTabCompWidget;
import 'package:flutter/material.dart';

class ThreadTabCompModel extends FlutterFlowModel<ThreadTabCompWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for EvidenceThumb.
  late EvidenceThumbModel evidenceThumbModel;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;

  @override
  void initState(BuildContext context) {
    evidenceThumbModel = createModel(context, () => EvidenceThumbModel());
    columnScrollController = ScrollController();
  }

  @override
  void dispose() {
    evidenceThumbModel.dispose();
    columnScrollController?.dispose();
  }
}
