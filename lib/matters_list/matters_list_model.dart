import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'matters_list_widget.dart' show MattersListWidget;
import 'package:flutter/material.dart';

class MattersListModel extends FlutterFlowModel<MattersListWidget> {
  ///  Local state fields for this page.

  List<String> filteredLists = [];
  void addToFilteredLists(String item) => filteredLists.add(item);
  void removeFromFilteredLists(String item) => filteredLists.remove(item);
  void removeAtIndexFromFilteredLists(int index) =>
      filteredLists.removeAt(index);
  void insertAtIndexInFilteredLists(int index, String item) =>
      filteredLists.insert(index, item);
  void updateFilteredListsAtIndex(int index, Function(String) updateFn) =>
      filteredLists[index] = updateFn(filteredLists[index]);

  String? filterStatus;

  String? filterMatterType;

  String? sortOption;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in MattersList widget.
  List<MattersRecord>? mattersList;
  // Stores action output result for [Firestore Query - Query a collection] action in MattersList widget.
  SyncStatusRecord? sync;
  // Stores action output result for [Backend Call - Read Document] action in MattersList widget.
  SyncStatusRecord? readSync;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - filterMattersLocally] action in TextField widget.
  List<MattersRecord>? filteredMattersList;
  // Result returned by the Filter & Sort sheet (null = no filter applied).
  List<MattersRecord>? sheetFilteredMatters;
  // True until the first Matters query finishes.
  bool isLoading = true;
  // Set when the Matters query fails.
  String? loadError;
  // Receipts count per matter (keyed by matter path), fetched once per load.
  final Map<String, Future<int>> itemCountFutures = {};
  // Model for Button.
  late ButtonModel buttonModel;
  // State field(s) for Column widget.
  ScrollController? columnScrollController;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    buttonModel = createModel(context, () => ButtonModel());
    columnScrollController = ScrollController();
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    buttonModel.dispose();
    columnScrollController?.dispose();
  }
}
