import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/side_nav_widget.dart';
import '/components/tab_item_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'matter_detail_intake_channels_widget.dart'
    show MatterDetailIntakeChannelsWidget;
import 'package:flutter/material.dart';

class MatterDetailIntakeChannelsModel
    extends FlutterFlowModel<MatterDetailIntakeChannelsWidget> {
  ///  Local state fields for this page.

  bool? showFollowUpDraft;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in MatterDetailIntakeChannels widget.
  List<ItemsRecord>? quarantinedItems;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for TabItem.
  late TabItemModel tabItemModel1;
  // Model for TabItem.
  late TabItemModel tabItemModel2;
  // Model for TabItem.
  late TabItemModel tabItemModel3;
  // Model for TabItem.
  late TabItemModel tabItemModel4;
  // Model for Button.
  late ButtonModel buttonModel2;
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
  late ButtonModel buttonModel3;
  // Model for Button.
  late ButtonModel buttonModel4;
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  FollowUpRequestsRecord? requests;
  // Model for Button.
  late ButtonModel buttonModel5;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    tabItemModel1 = createModel(context, () => TabItemModel());
    tabItemModel2 = createModel(context, () => TabItemModel());
    tabItemModel3 = createModel(context, () => TabItemModel());
    tabItemModel4 = createModel(context, () => TabItemModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    textFieldModel = createModel(context, () => TextFieldModel());
    buttonModel3 = createModel(context, () => ButtonModel());
    buttonModel4 = createModel(context, () => ButtonModel());
    buttonModel5 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    buttonModel1.dispose();
    tabItemModel1.dispose();
    tabItemModel2.dispose();
    tabItemModel3.dispose();
    tabItemModel4.dispose();
    buttonModel2.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldModel.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
    buttonModel5.dispose();
  }
}
