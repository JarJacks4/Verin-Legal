import '/flutter_flow/flutter_flow_util.dart';
import 'scrollable_message_thread_widget.dart'
    show ScrollableMessageThreadWidget;
import 'package:flutter/material.dart';

class ScrollableMessageThreadModel
    extends FlutterFlowModel<ScrollableMessageThreadWidget> {
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
