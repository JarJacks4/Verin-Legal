import '/backend/backend.dart';
import '/components/button18_widget.dart';
import '/components/button19_widget.dart';
import '/components/button20_widget.dart';
import '/components/button_widget.dart';
import '/components/hash_row_widget.dart';
import '/components/integrity_card_widget.dart';
import '/components/message_bubble_widget.dart';
import '/components/side_nav_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'matters_tab_group_home_widget.dart' show MattersTabGroupHomeWidget;
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MattersTabGroupHomeModel
    extends FlutterFlowModel<MattersTabGroupHomeWidget> {
  ///  Local state fields for this page.

  List<String> matterReceipt = [];
  void addToMatterReceipt(String item) => matterReceipt.add(item);
  void removeFromMatterReceipt(String item) => matterReceipt.remove(item);
  void removeAtIndexFromMatterReceipt(int index) =>
      matterReceipt.removeAt(index);
  void insertAtIndexInMatterReceipt(int index, String item) =>
      matterReceipt.insert(index, item);
  void updateMatterReceiptAtIndex(int index, Function(String) updateFn) =>
      matterReceipt[index] = updateFn(matterReceipt[index]);

  int? videoStat;

  String? screenRecCountState;

  List<ItemsRecord> gapResults = [];
  void addToGapResults(ItemsRecord item) => gapResults.add(item);
  void removeFromGapResults(ItemsRecord item) => gapResults.remove(item);
  void removeAtIndexFromGapResults(int index) => gapResults.removeAt(index);
  void insertAtIndexInGapResults(int index, ItemsRecord item) =>
      gapResults.insert(index, item);
  void updateGapResultsAtIndex(int index, Function(ItemsRecord) updateFn) =>
      gapResults[index] = updateFn(gapResults[index]);

  String? searchText;

  String? activeFilter;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in MattersTabGroupHome widget.
  List<ReceiptsRecord>? matterReceipts;
  // Stores action output result for [Custom Action - summarizeVideoReceipts] action in MattersTabGroupHome widget.
  List<int>? videoStats;
  // Stores action output result for [Custom Action - countScreenRecordingReceipts] action in MattersTabGroupHome widget.
  int? screenRecCount;
  // Stores action output result for [Custom Action - buildIntakeAddresses] action in MattersTabGroupHome widget.
  dynamic intakeAddresses;
  // Stores action output result for [Firestore Query - Query a collection] action in MattersTabGroupHome widget.
  List<ItemsRecord>? itemsQuery;
  // Stores action output result for [Custom Action - computeGapsAndAccuracy] action in MattersTabGroupHome widget.
  dynamic gapResult;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for Column widget.
  ScrollController? columnScrollController1;
  // Model for Button.
  late Button18Model buttonModel;
  // Model for Button.
  late ButtonModel buttonModel1;
  // State field(s) for Row widget.
  ScrollController? rowScrollController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for Button.
  late ButtonModel buttonModel3;
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  FollowUpRequestsRecord? requests;
  // Model for Button.
  late ButtonModel buttonModel4;
  // State field(s) for Column widget.
  ScrollController? columnScrollController2;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  // State field(s) for ListView widget.
  final ItemScrollController listViewItemScrollController1 =
      ItemScrollController();
  final ItemPositionsListener listViewItemPositionsListener1 =
      ItemPositionsListener.create();
  int listViewFirstVisibleIndex1 = 0;
  int listViewLastVisibleIndex1 = 0;
  List<int> listViewVisibleIndexes1 = [];
  bool listViewItemPositionsAttached1 = false;
  // State field(s) for Column widget.
  ScrollController? columnScrollController3;
  // Model for MessageBubble.
  late MessageBubbleModel messageBubbleModel1;
  // Model for MessageBubble.
  late MessageBubbleModel messageBubbleModel2;
  // Model for MessageBubble.
  late MessageBubbleModel messageBubbleModel3;
  // State field(s) for Column widget.
  ScrollController? columnController;
  // State field(s) for Column widget.
  ScrollController? columnScrollController4;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel1;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel2;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel3;
  // Model for IntegrityCard.
  late IntegrityCardModel integrityCardModel4;
  // Model for HashRow.
  late HashRowModel hashRowModel1;
  // Model for HashRow.
  late HashRowModel hashRowModel2;
  // Model for HashRow.
  late HashRowModel hashRowModel3;
  // Model for HashRow.
  late HashRowModel hashRowModel4;
  // Model for HashRow.
  late HashRowModel hashRowModel5;
  // Model for HashRow.
  late HashRowModel hashRowModel6;
  // Model for Button.
  late Button19Model buttonModel1;
  // Model for Button.
  late Button19Model buttonModel2;
  // State field(s) for Column widget.
  ScrollController? columnScrollController5;
  // State field(s) for Column widget.
  ScrollController? columnScrollController6;
  // Model for Button.
  late Button20Model buttonModel1;
  // State field(s) for Column widget.
  ScrollController? columnScrollController7;
  // Model for Button.
  late Button20Model buttonModel2;
  // Model for Button.
  late Button20Model buttonModel3;
  // Model for Button.
  late Button20Model buttonModel4;
  // Model for Button.
  late Button20Model buttonModel5;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    columnScrollController1 = ScrollController();
    buttonModel = createModel(context, () => Button18Model());
    buttonModel1 = createModel(context, () => ButtonModel());
    rowScrollController = ScrollController();
    textFieldModel = createModel(context, () => TextFieldModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    buttonModel3 = createModel(context, () => ButtonModel());
    buttonModel4 = createModel(context, () => ButtonModel());
    columnScrollController2 = ScrollController();
    columnScrollController3 = ScrollController();
    messageBubbleModel1 = createModel(context, () => MessageBubbleModel());
    messageBubbleModel2 = createModel(context, () => MessageBubbleModel());
    messageBubbleModel3 = createModel(context, () => MessageBubbleModel());
    columnController = ScrollController();
    columnScrollController4 = ScrollController();
    integrityCardModel1 = createModel(context, () => IntegrityCardModel());
    integrityCardModel2 = createModel(context, () => IntegrityCardModel());
    integrityCardModel3 = createModel(context, () => IntegrityCardModel());
    integrityCardModel4 = createModel(context, () => IntegrityCardModel());
    hashRowModel1 = createModel(context, () => HashRowModel());
    hashRowModel2 = createModel(context, () => HashRowModel());
    hashRowModel3 = createModel(context, () => HashRowModel());
    hashRowModel4 = createModel(context, () => HashRowModel());
    hashRowModel5 = createModel(context, () => HashRowModel());
    hashRowModel6 = createModel(context, () => HashRowModel());
    buttonModel1 = createModel(context, () => Button19Model());
    buttonModel2 = createModel(context, () => Button19Model());
    columnScrollController5 = ScrollController();
    columnScrollController6 = ScrollController();
    buttonModel1 = createModel(context, () => Button20Model());
    columnScrollController7 = ScrollController();
    buttonModel2 = createModel(context, () => Button20Model());
    buttonModel3 = createModel(context, () => Button20Model());
    buttonModel4 = createModel(context, () => Button20Model());
    buttonModel5 = createModel(context, () => Button20Model());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    tabBarController?.dispose();
    columnScrollController1?.dispose();
    buttonModel.dispose();
    buttonModel1.dispose();
    rowScrollController?.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldModel.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
    columnScrollController2?.dispose();
    textFieldFocusNode4?.dispose();
    textController4?.dispose();

    columnScrollController3?.dispose();
    messageBubbleModel1.dispose();
    messageBubbleModel2.dispose();
    messageBubbleModel3.dispose();
    columnController?.dispose();
    columnScrollController4?.dispose();
    integrityCardModel1.dispose();
    integrityCardModel2.dispose();
    integrityCardModel3.dispose();
    integrityCardModel4.dispose();
    hashRowModel1.dispose();
    hashRowModel2.dispose();
    hashRowModel3.dispose();
    hashRowModel4.dispose();
    hashRowModel5.dispose();
    hashRowModel6.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    columnScrollController5?.dispose();
    columnScrollController6?.dispose();
    buttonModel1.dispose();
    columnScrollController7?.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
    buttonModel5.dispose();
  }
}
