import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/button18_widget.dart';
import '/components/button19_widget.dart';
import '/components/button20_widget.dart';
import '/components/button_widget.dart';
import '/components/create_new_matter_bottom_sheet_widget.dart';
import '/components/evidence_thumb_widget.dart';
import '/components/expandable_missing_evidence_widget.dart';
import '/components/hash_row_widget.dart';
import '/components/integrity_card_widget.dart';
import '/components/message_bubble_widget.dart';
import '/components/receipt_details_drawer_sheet_widget.dart';
import '/components/side_nav_widget.dart';
import '/components/status_badge22_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'matters_tab_group_home_model.dart';
export 'matters_tab_group_home_model.dart';

class MattersTabGroupHomeWidget extends StatefulWidget {
  const MattersTabGroupHomeWidget({
    super.key,
    this.matterDoc,
  });

  final MattersRecord? matterDoc;

  static String routeName = 'MattersTabGroupHome';
  static String routePath = '/mattersTabGroupHome';

  @override
  State<MattersTabGroupHomeWidget> createState() =>
      _MattersTabGroupHomeWidgetState();
}

class _MattersTabGroupHomeWidgetState extends State<MattersTabGroupHomeWidget>
    with TickerProviderStateMixin {
  late MattersTabGroupHomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MattersTabGroupHomeModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.matterReceipts = await queryReceiptsRecordOnce(
        queryBuilder: (receiptsRecord) => receiptsRecord.where(
          'matterId',
          isEqualTo: widget.matterDoc?.reference,
        ),
      );
      _model.videoStats = await actions.summarizeVideoReceipts(
        _model.matterReceipts!.toList(),
      );
      _model.screenRecCount = await actions.countScreenRecordingReceipts(
        _model.matterReceipts!.toList(),
      );
      _model.intakeAddresses = await actions.buildIntakeAddresses(
        widget.matterDoc!.providerMatterReference,
      );
      _model.itemsQuery = await queryItemsRecordOnce();
      _model.gapResult = await actions.computeGapsAndAccuracy(
        _model.itemsQuery!.toList(),
      );
      _model.matterReceipt = _model.matterReceipts!
          .map((e) => e.matterId?.id)
          .withoutNulls
          .toList()
          .toList()
          .cast<String>();
      _model.videoStat = _model.videoStats?.length;
      _model.screenRecCountState = _model.screenRecCount?.toString();
      _model.gapResults = _model.itemsQuery!.toList().cast<ItemsRecord>();
      safeSetState(() {});
    });

    _model.tabBarController = TabController(
      vsync: this,
      length: 5,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController(text: _model.searchText);
    _model.textFieldFocusNode4 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFFDFCFA),
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              wrapWithModel(
                model: _model.sideNavModel,
                updateCallback: () => safeSetState(() {}),
                child: SideNavWidget(),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width * 0.827,
                      height: 243.2,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              32.0, 48.0, 32.0, 24.0),
                          child: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment:
                                  (FFCrossAxisAlignment.start).flutterValue,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        context.pop();
                                      },
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        size: 18.0,
                                      ),
                                    ),
                                    Text(
                                      'All matters',
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.ibmPlexSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          (FFCrossAxisAlignment.start)
                                              .flutterValue,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Align(
                                          alignment:
                                              AlignmentDirectional(-1.0, 0.0),
                                          child: Text(
                                            valueOrDefault<String>(
                                              widget.matterDoc?.caseTitle,
                                              'Whitmore v. Whitmore',
                                            ),
                                            textAlign: TextAlign.start,
                                            style: FlutterFlowTheme.of(context)
                                                .displaySmall
                                                .override(
                                                  font: GoogleFonts.spectral(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .displaySmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .displaySmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .displaySmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .displaySmall
                                                          .fontStyle,
                                                  lineHeight: 1.2,
                                                ),
                                          ),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional(-1.0, 0.0),
                                          child: Text(
                                            valueOrDefault<String>(
                                              '${widget.matterDoc?.clientName}-${widget.matterDoc?.caseNumber}-${widget.matterDoc?.practiceArea}-${widget.matterDoc?.openedAt?.toString()}',
                                              'Elena Whitmore · 49D08-2404-DR-014922 · Family law · opened Jul 21, 2026',
                                            ),
                                            textAlign: TextAlign.start,
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.ibmPlexSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                  lineHeight: 1.5,
                                                ),
                                          ),
                                        ),
                                      ].divide(SizedBox(height: 4.0)),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: (widget.matterDoc
                                                            ?.hasChainRoot ==
                                                        null) &&
                                                    (widget.matterDoc
                                                            ?.hasChronologyShift ==
                                                        false)
                                                ? FFAppConstants.Brandteal
                                                : FFAppConstants
                                                    .BrandLightBackground,
                                            borderRadius:
                                                BorderRadius.circular(9999.0),
                                            shape: BoxShape.rectangle,
                                            border: Border.all(
                                              color: Colors.transparent,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 8.0, 16.0, 8.0),
                                            child: Container(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.verified_user_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondary,
                                                    size: 14.0,
                                                  ),
                                                  Text(
                                                    'Chain verified',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .spaceGrotesk(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: valueOrDefault<
                                                              Color>(
                                                            (widget.matterDoc
                                                                            ?.hasChainRoot ==
                                                                        null) &&
                                                                    (widget.matterDoc
                                                                            ?.hasChronologyShift ==
                                                                        false)
                                                                ? FFAppConstants
                                                                    .Brandteal
                                                                : FFAppConstants
                                                                    .BrandLightBackground,
                                                            Color(0xFF3E6B4F),
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                          lineHeight: 1.2,
                                                        ),
                                                  ),
                                                ].divide(SizedBox(width: 4.0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (widget.matterDoc?.clioSyncedAt ==
                                            null)
                                          AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 170),
                                            curve: Curves.easeIn,
                                            decoration: BoxDecoration(
                                              color: valueOrDefault<Color>(
                                                (widget.matterDoc
                                                                ?.hasChainRoot ==
                                                            null) &&
                                                        (widget.matterDoc
                                                                ?.hasChronologyShift ==
                                                            false)
                                                    ? FFAppConstants.Brandteal
                                                    : FFAppConstants
                                                        .BrandLightBackground,
                                                Color(0x2A3E6B4F),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(9999.0),
                                              shape: BoxShape.rectangle,
                                              border: Border.all(
                                                color: Color(0x002D5A5E),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 8.0, 16.0, 8.0),
                                              child: Container(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondary,
                                                      size: 14.0,
                                                    ),
                                                    Text(
                                                      'In Clio',
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelSmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .spaceGrotesk(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontStyle,
                                                                ),
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  (widget.matterDoc?.hasChainRoot ==
                                                                              null) &&
                                                                          (widget.matterDoc?.hasChronologyShift ==
                                                                              false)
                                                                      ? FFAppConstants
                                                                          .Brandteal
                                                                      : FFAppConstants
                                                                          .BrandLightBackground,
                                                                  Color(
                                                                      0xFF3E6B4F),
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                                lineHeight: 1.2,
                                                              ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 4.0)),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ].divide(SizedBox(width: 16.0)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Color(0x190E6E7D),
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                        shape: BoxShape.rectangle,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 4.0, 16.0, 4.0),
                                        child: Container(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.slow_motion_video_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                size: 14.0,
                                              ),
                                              Text(
                                                '${_model.videoStat?.toString()} · videos ·${_model.videoStats?.length.toString()} total',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .ibmPlexSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondary,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                          lineHeight: 1.2,
                                                        ),
                                              ),
                                            ].divide(SizedBox(width: 4.0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_model.videoStat! > 0)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Color(0x1EB0791C),
                                          borderRadius:
                                              BorderRadius.circular(25.0),
                                          shape: BoxShape.rectangle,
                                          border: Border.all(
                                            color: Color(0x4DC98D26),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 4.0, 16.0, 4.0),
                                          child: Container(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .warning,
                                                  size: 14.0,
                                                ),
                                                Text(
                                                  '${_model.videoStat.toString()} transcoded in transit',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .ibmPlexSans(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .warning,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontStyle,
                                                        lineHeight: 1.2,
                                                      ),
                                                ),
                                              ].divide(SizedBox(width: 4.0)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (_model.screenRecCount! > 0)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Color(0x190E6E7D),
                                          borderRadius:
                                              BorderRadius.circular(25.0),
                                          shape: BoxShape.rectangle,
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 4.0, 16.0, 4.0),
                                          child: Container(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.layers_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondary,
                                                  size: 14.0,
                                                ),
                                                Text(
                                                  '${_model.screenRecCountState} screen recording → thread reconstruction',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .ibmPlexSans(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondary,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontStyle,
                                                        lineHeight: 1.2,
                                                      ),
                                                ),
                                              ].divide(SizedBox(width: 4.0)),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ].divide(SizedBox(height: 24.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          width: 1187.0,
                          height: 800.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment(0.0, 0),
                                child: TabBar(
                                  labelColor:
                                      FlutterFlowTheme.of(context).secondary,
                                  unselectedLabelColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  labelStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.ibmPlexSans(
                                          fontWeight: FontWeight.w800,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        fontSize: 13.5,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                  unselectedLabelStyle:
                                      FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.ibmPlexSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                  indicatorColor:
                                      FlutterFlowTheme.of(context).secondary,
                                  tabs: [
                                    Tab(
                                      text: 'Intake Channel',
                                    ),
                                    Tab(
                                      text: 'Reciepts',
                                    ),
                                    Tab(
                                      text: 'Thread',
                                    ),
                                    Tab(
                                      text: 'Integrity',
                                    ),
                                    Tab(
                                      text: 'Practice',
                                    ),
                                  ],
                                  controller: _model.tabBarController,
                                  onTap: (i) async {
                                    [
                                      () async {},
                                      () async {},
                                      () async {},
                                      () async {},
                                      () async {}
                                    ][i]();
                                  },
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _model.tabBarController,
                                  children: [
                                    KeepAliveWidgetWrapper(
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            height: 1.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              shape: BoxShape.rectangle,
                                            ),
                                          ),
                                          Flexible(
                                            flex: 1,
                                            child: SingleChildScrollView(
                                              primary: false,
                                              controller: _model
                                                  .columnScrollController1,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Flexible(
                                                    flex: 1,
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              1.0, -1.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    25.0,
                                                                    45.0,
                                                                    0.0),
                                                        child: InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            await showModalBottomSheet(
                                                              isScrollControlled:
                                                                  true,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return GestureDetector(
                                                                  onTap: () {
                                                                    FocusScope.of(
                                                                            context)
                                                                        .unfocus();
                                                                    FocusManager
                                                                        .instance
                                                                        .primaryFocus
                                                                        ?.unfocus();
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding: MediaQuery
                                                                        .viewInsetsOf(
                                                                            context),
                                                                    child:
                                                                        CreateNewMatterBottomSheetWidget(),
                                                                  ),
                                                                );
                                                              },
                                                            ).then((value) =>
                                                                safeSetState(
                                                                    () {}));
                                                          },
                                                          child: wrapWithModel(
                                                            model: _model
                                                                .buttonModel,
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                Button18Widget(
                                                              icon: Icon(
                                                                Icons
                                                                    .add_rounded,
                                                                color: Color(
                                                                    0x313E6B4F),
                                                                size: 24.0,
                                                              ),
                                                              iconPresent: true,
                                                              iconEndPresent:
                                                                  false,
                                                              content:
                                                                  'Add manual entry',
                                                              variant:
                                                                  'outline',
                                                              size: 'medium',
                                                              fullWidth: false,
                                                              loading: false,
                                                              disabled: false,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(32.0),
                                                    child: Container(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                (FFCrossAxisAlignment
                                                                        .start)
                                                                    .flutterValue,
                                                            textBaseline:
                                                                TextBaseline
                                                                    .alphabetic,
                                                            children: [
                                                              Text(
                                                                'Evidence Collection Channels',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .spectral(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .titleLarge
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .titleLarge
                                                                          .fontStyle,
                                                                      lineHeight:
                                                                          1.3,
                                                                    ),
                                                              ),
                                                              Text(
                                                                'Clients forward messages and photos from whatever device they already own. Nothing to install.',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .ibmPlexSans(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 8.0)),
                                                          ),
                                                          if (_model
                                                                  .gapResult ??
                                                              true)
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .warning5,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0),
                                                                shape: BoxShape
                                                                    .rectangle,
                                                                border:
                                                                    Border.all(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .warning30,
                                                                  width: 1.0,
                                                                ),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            24.0),
                                                                child:
                                                                    Container(
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            48.0,
                                                                        height:
                                                                            48.0,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).warning10,
                                                                          borderRadius:
                                                                              BorderRadius.circular(9999.0),
                                                                          shape:
                                                                              BoxShape.rectangle,
                                                                        ),
                                                                        alignment: AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .history_toggle_off_rounded,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).onSurface,
                                                                          size:
                                                                              28.0,
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              'Detected Evidence Gap: ${_model.gapResult?.toString()}',
                                                                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                    lineHeight: 1.4,
                                                                                  ),
                                                                            ),
                                                                            Text(
                                                                              'A significant gap in message continuity was detected between ${_model.gapResult?.toString()} gap‑start piece, and ${_model.gapResult?.toString()}\'s gap-end piece.',
                                                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).onSurface,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                          ].divide(SizedBox(height: 4.0)),
                                                                        ),
                                                                      ),
                                                                      InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          await showModalBottomSheet(
                                                                            isScrollControlled:
                                                                                true,
                                                                            backgroundColor:
                                                                                Colors.transparent,
                                                                            enableDrag:
                                                                                false,
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (context) {
                                                                              return GestureDetector(
                                                                                onTap: () {
                                                                                  FocusScope.of(context).unfocus();
                                                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                                                },
                                                                                child: Padding(
                                                                                  padding: MediaQuery.viewInsetsOf(context),
                                                                                  child: ExpandableMissingEvidenceWidget(
                                                                                    isExpanded: false,
                                                                                    draftMessage: '',
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ).then((value) =>
                                                                              safeSetState(() {}));
                                                                        },
                                                                        child:
                                                                            wrapWithModel(
                                                                          model:
                                                                              _model.buttonModel1,
                                                                          updateCallback: () =>
                                                                              safeSetState(() {}),
                                                                          child:
                                                                              Hero(
                                                                            tag:
                                                                                'RequestMissingDataButton',
                                                                            transitionOnUserGestures:
                                                                                true,
                                                                            child:
                                                                                Material(
                                                                              color: Colors.transparent,
                                                                              child: ButtonWidget(
                                                                                icon: Icon(
                                                                                  Icons.forward_to_inbox_rounded,
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  size: 24.0,
                                                                                ),
                                                                                iconPresent: true,
                                                                                iconEndPresent: false,
                                                                                content: 'Request Missing Data',
                                                                                variant: 'outline',
                                                                                size: 'small',
                                                                                fullWidth: false,
                                                                                loading: false,
                                                                                disabled: false,
                                                                                iconEnd: Icon(
                                                                                  Icons.data_exploration,
                                                                                  color: FlutterFlowTheme.of(context).tertiary,
                                                                                  size: 14.0,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        width:
                                                                            24.0)),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          Expanded(
                                                            flex: 1,
                                                            child:
                                                                SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              controller: _model
                                                                  .rowScrollController,
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    (FFMainAxisAlignment
                                                                            .spaceAround)
                                                                        .flutterValue,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Container(
                                                                    width: MediaQuery.sizeOf(context)
                                                                            .width *
                                                                        0.22,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      shape: BoxShape
                                                                          .rectangle,
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              24.0),
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children:
                                                                              [
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                Container(
                                                                                  decoration: BoxDecoration(
                                                                                    color: FlutterFlowTheme.of(context).primary5,
                                                                                    borderRadius: BorderRadius.circular(6.0),
                                                                                    shape: BoxShape.rectangle,
                                                                                  ),
                                                                                  child: Padding(
                                                                                    padding: EdgeInsets.all(8.0),
                                                                                    child: Container(
                                                                                      child: Icon(
                                                                                        Icons.mail_rounded,
                                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                                        size: 24.0,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  'Email Forwarding',
                                                                                  style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                        font: GoogleFonts.ibmPlexSans(
                                                                                          fontWeight: FontWeight.bold,
                                                                                          fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                        ),
                                                                                        color: FlutterFlowTheme.of(context).primaryText,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                        lineHeight: 1.4,
                                                                                      ),
                                                                                ),
                                                                              ].divide(SizedBox(width: 8.0)),
                                                                            ),
                                                                            Text(
                                                                              'Best for bulk exports, PDF attachments, and email threads.',
                                                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            Container(
                                                                              decoration: BoxDecoration(
                                                                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                borderRadius: BorderRadius.circular(6.0),
                                                                                shape: BoxShape.rectangle,
                                                                                border: Border.all(
                                                                                  color: FlutterFlowTheme.of(context).alternate,
                                                                                  width: 1.0,
                                                                                ),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: EdgeInsets.all(16.0),
                                                                                child: Container(
                                                                                  child: Row(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: [
                                                                                      Container(
                                                                                        width: 200.0,
                                                                                        child: Container(
                                                                                          width: 200.0,
                                                                                          child: TextFormField(
                                                                                            controller: _model.textController1,
                                                                                            focusNode: _model.textFieldFocusNode1,
                                                                                            autofocus: false,
                                                                                            enabled: true,
                                                                                            obscureText: false,
                                                                                            decoration: InputDecoration(
                                                                                              isDense: true,
                                                                                              labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                    ),
                                                                                                    letterSpacing: 0.0,
                                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                  ),
                                                                                              hintText: 'evidence+whitmore@verin.legal',
                                                                                              hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                    ),
                                                                                                    letterSpacing: 0.0,
                                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                  ),
                                                                                              enabledBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  color: Color(0x00000000),
                                                                                                  width: 1.0,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                              ),
                                                                                              focusedBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  color: Color(0x00000000),
                                                                                                  width: 1.0,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                              ),
                                                                                              errorBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  color: FlutterFlowTheme.of(context).error,
                                                                                                  width: 1.0,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                              ),
                                                                                              focusedErrorBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  color: FlutterFlowTheme.of(context).error,
                                                                                                  width: 1.0,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                              ),
                                                                                              filled: true,
                                                                                              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                            ),
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  ),
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                ),
                                                                                            cursorColor: FlutterFlowTheme.of(context).primaryText,
                                                                                            enableInteractiveSelection: true,
                                                                                            validator: _model.textController1Validator.asValidator(context),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      FlutterFlowIconButton(
                                                                                        borderRadius: 8.0,
                                                                                        buttonSize: 40.0,
                                                                                        fillColor: Colors.transparent,
                                                                                        icon: Icon(
                                                                                          Icons.content_copy_rounded,
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          size: 18.0,
                                                                                        ),
                                                                                        onPressed: () async {
                                                                                          await Clipboard.setData(ClipboardData(text: ''));
                                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                'Copied.',
                                                                                                style: TextStyle(
                                                                                                  color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                                ),
                                                                                              ),
                                                                                              duration: Duration(milliseconds: 4000),
                                                                                              backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(height: 16.0)),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Flexible(
                                                                    flex: 1,
                                                                    child:
                                                                        Container(
                                                                      width: MediaQuery.sizeOf(context)
                                                                              .width *
                                                                          0.22,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                        shape: BoxShape
                                                                            .rectangle,
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).alternate,
                                                                          width:
                                                                              1.0,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            EdgeInsets.all(24.0),
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.start,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children:
                                                                                [
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                children: [
                                                                                  Container(
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).primary5,
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                      shape: BoxShape.rectangle,
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(8.0),
                                                                                      child: Container(
                                                                                        child: Icon(
                                                                                          Icons.chat_outlined,
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          size: 24.0,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  Text(
                                                                                    'SMS/Text Message',
                                                                                    style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                          font: GoogleFonts.ibmPlexSans(
                                                                                            fontWeight: FontWeight.bold,
                                                                                            fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.bold,
                                                                                          fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                          lineHeight: 1.4,
                                                                                        ),
                                                                                  ),
                                                                                ].divide(SizedBox(width: 8.0)),
                                                                              ),
                                                                              Text(
                                                                                'Best for quick mobile exports, PDF attachments, and text message.',
                                                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                      font: GoogleFonts.ibmPlexSans(
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                      ),
                                                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                              Container(
                                                                                decoration: BoxDecoration(
                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                  borderRadius: BorderRadius.circular(6.0),
                                                                                  shape: BoxShape.rectangle,
                                                                                  border: Border.all(
                                                                                    color: FlutterFlowTheme.of(context).alternate,
                                                                                    width: 1.0,
                                                                                  ),
                                                                                ),
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(16.0),
                                                                                  child: Container(
                                                                                    child: Row(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                                      children: [
                                                                                        Container(
                                                                                          width: 200.0,
                                                                                          child: Container(
                                                                                            width: 200.0,
                                                                                            child: TextFormField(
                                                                                              controller: _model.textController2,
                                                                                              focusNode: _model.textFieldFocusNode2,
                                                                                              autofocus: false,
                                                                                              enabled: true,
                                                                                              obscureText: false,
                                                                                              decoration: InputDecoration(
                                                                                                isDense: true,
                                                                                                labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                      font: GoogleFonts.ibmPlexSans(
                                                                                                        fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                      ),
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                    ),
                                                                                                hintText: 'evidence+whitmore@verin.legal',
                                                                                                hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                      font: GoogleFonts.ibmPlexSans(
                                                                                                        fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                      ),
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                    ),
                                                                                                enabledBorder: OutlineInputBorder(
                                                                                                  borderSide: BorderSide(
                                                                                                    color: Color(0x00000000),
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.circular(8.0),
                                                                                                ),
                                                                                                focusedBorder: OutlineInputBorder(
                                                                                                  borderSide: BorderSide(
                                                                                                    color: Color(0x00000000),
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.circular(8.0),
                                                                                                ),
                                                                                                errorBorder: OutlineInputBorder(
                                                                                                  borderSide: BorderSide(
                                                                                                    color: FlutterFlowTheme.of(context).error,
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.circular(8.0),
                                                                                                ),
                                                                                                focusedErrorBorder: OutlineInputBorder(
                                                                                                  borderSide: BorderSide(
                                                                                                    color: FlutterFlowTheme.of(context).error,
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.circular(8.0),
                                                                                                ),
                                                                                                filled: true,
                                                                                                fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              ),
                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                    ),
                                                                                                    letterSpacing: 0.0,
                                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  ),
                                                                                              cursorColor: FlutterFlowTheme.of(context).primaryText,
                                                                                              enableInteractiveSelection: true,
                                                                                              validator: _model.textController2Validator.asValidator(context),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        FlutterFlowIconButton(
                                                                                          borderRadius: 8.0,
                                                                                          buttonSize: 40.0,
                                                                                          fillColor: Colors.transparent,
                                                                                          icon: Icon(
                                                                                            Icons.content_copy_rounded,
                                                                                            color: FlutterFlowTheme.of(context).primary,
                                                                                            size: 18.0,
                                                                                          ),
                                                                                          onPressed: () async {
                                                                                            await Clipboard.setData(ClipboardData(text: ''));
                                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                                              SnackBar(
                                                                                                content: Text(
                                                                                                  'Copied.',
                                                                                                  style: TextStyle(
                                                                                                    color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                                  ),
                                                                                                ),
                                                                                                duration: Duration(milliseconds: 4000),
                                                                                                backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                              ),
                                                                                            );
                                                                                          },
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ].divide(SizedBox(height: 16.0)),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    flex: 1,
                                                                    child:
                                                                        Align(
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              1.0,
                                                                              0.0),
                                                                      child:
                                                                          Container(
                                                                        width: MediaQuery.sizeOf(context).width *
                                                                            0.22,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryBackground,
                                                                          borderRadius:
                                                                              BorderRadius.circular(8.0),
                                                                          shape:
                                                                              BoxShape.rectangle,
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                FlutterFlowTheme.of(context).alternate,
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              EdgeInsets.all(24.0),
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                BoxDecoration(),
                                                                            child:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Row(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                                  children: [
                                                                                    Container(
                                                                                      decoration: BoxDecoration(
                                                                                        color: FlutterFlowTheme.of(context).primary5,
                                                                                        borderRadius: BorderRadius.circular(6.0),
                                                                                        shape: BoxShape.rectangle,
                                                                                      ),
                                                                                      child: Padding(
                                                                                        padding: EdgeInsets.all(8.0),
                                                                                        child: Container(
                                                                                          child: FaIcon(
                                                                                            FontAwesomeIcons.whatsapp,
                                                                                            color: FlutterFlowTheme.of(context).secondary,
                                                                                            size: 24.0,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    Text(
                                                                                      'WhatsApp',
                                                                                      style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                            font: GoogleFonts.ibmPlexSans(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                            ),
                                                                                            color: FlutterFlowTheme.of(context).primaryText,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.bold,
                                                                                            fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                            lineHeight: 1.4,
                                                                                          ),
                                                                                    ),
                                                                                  ].divide(SizedBox(width: 8.0)),
                                                                                ),
                                                                                Expanded(
                                                                                  flex: 1,
                                                                                  child: Text(
                                                                                    'Best for bulk exports, PDF attachments, and email threads.',
                                                                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                          font: GoogleFonts.ibmPlexSans(
                                                                                            fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                          ),
                                                                                          color: FlutterFlowTheme.of(context).secondaryText,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                                Container(
                                                                                  decoration: BoxDecoration(
                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                    borderRadius: BorderRadius.circular(6.0),
                                                                                    shape: BoxShape.rectangle,
                                                                                    border: Border.all(
                                                                                      color: FlutterFlowTheme.of(context).alternate,
                                                                                      width: 1.0,
                                                                                    ),
                                                                                  ),
                                                                                  child: Padding(
                                                                                    padding: EdgeInsets.all(16.0),
                                                                                    child: Container(
                                                                                      child: Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        children: [
                                                                                          Container(
                                                                                            width: 200.0,
                                                                                            child: Container(
                                                                                              width: 200.0,
                                                                                              child: TextFormField(
                                                                                                controller: _model.textController3,
                                                                                                focusNode: _model.textFieldFocusNode3,
                                                                                                autofocus: false,
                                                                                                enabled: true,
                                                                                                obscureText: false,
                                                                                                decoration: InputDecoration(
                                                                                                  isDense: true,
                                                                                                  labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                        font: GoogleFonts.ibmPlexSans(
                                                                                                          fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                        ),
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                      ),
                                                                                                  hintText: 'evidence+whitmore@verin.legal',
                                                                                                  hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                        font: GoogleFonts.ibmPlexSans(
                                                                                                          fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                        ),
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                      ),
                                                                                                  enabledBorder: OutlineInputBorder(
                                                                                                    borderSide: BorderSide(
                                                                                                      color: Color(0x00000000),
                                                                                                      width: 1.0,
                                                                                                    ),
                                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                                  ),
                                                                                                  focusedBorder: OutlineInputBorder(
                                                                                                    borderSide: BorderSide(
                                                                                                      color: Color(0x00000000),
                                                                                                      width: 1.0,
                                                                                                    ),
                                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                                  ),
                                                                                                  errorBorder: OutlineInputBorder(
                                                                                                    borderSide: BorderSide(
                                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                                      width: 1.0,
                                                                                                    ),
                                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                                  ),
                                                                                                  focusedErrorBorder: OutlineInputBorder(
                                                                                                    borderSide: BorderSide(
                                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                                      width: 1.0,
                                                                                                    ),
                                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                                  ),
                                                                                                  filled: true,
                                                                                                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                ),
                                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                      font: GoogleFonts.ibmPlexSans(
                                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                      ),
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                    ),
                                                                                                cursorColor: FlutterFlowTheme.of(context).primaryText,
                                                                                                enableInteractiveSelection: true,
                                                                                                validator: _model.textController3Validator.asValidator(context),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          FlutterFlowIconButton(
                                                                                            borderRadius: 8.0,
                                                                                            buttonSize: 40.0,
                                                                                            fillColor: Colors.transparent,
                                                                                            icon: Icon(
                                                                                              Icons.content_copy_rounded,
                                                                                              color: FlutterFlowTheme.of(context).primary,
                                                                                              size: 18.0,
                                                                                            ),
                                                                                            onPressed: () async {
                                                                                              await Clipboard.setData(ClipboardData(text: ''));
                                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text(
                                                                                                    'Copied.',
                                                                                                    style: TextStyle(
                                                                                                      color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                                    ),
                                                                                                  ),
                                                                                                  duration: Duration(milliseconds: 4000),
                                                                                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                                ),
                                                                                              );
                                                                                            },
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ].divide(SizedBox(height: 16.0)),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        11.0)),
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                              shape: BoxShape
                                                                  .rectangle,
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                width: 1.0,
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          24.0),
                                                              child: Container(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .stretch,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              'Missing-evidence follow-up',
                                                                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                    lineHeight: 1.4,
                                                                                  ),
                                                                            ),
                                                                            Text(
                                                                              'Draft a request for specific missing context or continuity gaps.',
                                                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                      fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                          ].divide(SizedBox(height: 4.0)),
                                                                        ),
                                                                        Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                FlutterFlowTheme.of(context).secondary10,
                                                                            borderRadius:
                                                                                BorderRadius.circular(4.0),
                                                                            shape:
                                                                                BoxShape.rectangle,
                                                                          ),
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                8.0,
                                                                                4.0,
                                                                                8.0,
                                                                                4.0),
                                                                            child:
                                                                                Container(
                                                                              child: Text(
                                                                                'Recipient: ',
                                                                                style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                      font: GoogleFonts.spaceGrotesk(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                      ),
                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                      lineHeight: 1.2,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
                                                                        borderRadius:
                                                                            BorderRadius.circular(6.0),
                                                                        shape: BoxShape
                                                                            .rectangle,
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).alternate,
                                                                          width:
                                                                              1.0,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            EdgeInsets.all(16.0),
                                                                        child:
                                                                            Container(
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.start,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            children:
                                                                                [
                                                                              wrapWithModel(
                                                                                model: _model.textFieldModel,
                                                                                updateCallback: () => safeSetState(() {}),
                                                                                child: TextFieldWidget(
                                                                                  label: 'Request Draft',
                                                                                  labelPresent: true,
                                                                                  helper: 'This will be sent via the client\'s preferred channel.',
                                                                                  helperPresent: true,
                                                                                  leadingIconPresent: false,
                                                                                  trailingIconPresent: false,
                                                                                  hint: 'Type here...',
                                                                                  value: ' Please send messages immediately before this exchange (Oct 14, 2:00 PM). There is a gap in the conversation continuity.',
                                                                                  onChange: '',
                                                                                  onSubmit: '',
                                                                                  variant: 'ghost',
                                                                                  error: false,
                                                                                ),
                                                                              ),
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                children: [
                                                                                  InkWell(
                                                                                    splashColor: Colors.transparent,
                                                                                    focusColor: Colors.transparent,
                                                                                    hoverColor: Colors.transparent,
                                                                                    highlightColor: Colors.transparent,
                                                                                    onTap: () async {
                                                                                      safeSetState(() {});

                                                                                      await currentUserReference!.update(createUsersRecordData());
                                                                                    },
                                                                                    child: wrapWithModel(
                                                                                      model: _model.buttonModel2,
                                                                                      updateCallback: () => safeSetState(() {}),
                                                                                      child: ButtonWidget(
                                                                                        iconPresent: false,
                                                                                        iconEndPresent: false,
                                                                                        content: 'Cancel',
                                                                                        variant: 'ghost',
                                                                                        size: 'small',
                                                                                        fullWidth: false,
                                                                                        loading: false,
                                                                                        disabled: false,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  InkWell(
                                                                                    splashColor: Colors.transparent,
                                                                                    focusColor: Colors.transparent,
                                                                                    hoverColor: Colors.transparent,
                                                                                    highlightColor: Colors.transparent,
                                                                                    onTap: () async {
                                                                                      var followUpRequestsRecordReference = FollowUpRequestsRecord.collection.doc();
                                                                                      await followUpRequestsRecordReference.set(createFollowUpRequestsRecordData(
                                                                                        matterId: widget.matterDoc?.reference,
                                                                                        draftText: _model.textFieldModel.inputTextController.text,
                                                                                        status: 'Sent',
                                                                                        sentAt: getCurrentTimestamp,
                                                                                      ));
                                                                                      _model.requests = FollowUpRequestsRecord.getDocumentFromData(
                                                                                          createFollowUpRequestsRecordData(
                                                                                            matterId: widget.matterDoc?.reference,
                                                                                            draftText: _model.textFieldModel.inputTextController.text,
                                                                                            status: 'Sent',
                                                                                            sentAt: getCurrentTimestamp,
                                                                                          ),
                                                                                          followUpRequestsRecordReference);

                                                                                      safeSetState(() {});

                                                                                      await widget.matterDoc!.reference.update(createMattersRecordData());
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text(
                                                                                            'Request Sent.',
                                                                                            style: TextStyle(
                                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                                            ),
                                                                                          ),
                                                                                          duration: Duration(milliseconds: 4000),
                                                                                          backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                                        ),
                                                                                      );

                                                                                      safeSetState(() {});
                                                                                    },
                                                                                    child: wrapWithModel(
                                                                                      model: _model.buttonModel3,
                                                                                      updateCallback: () => safeSetState(() {}),
                                                                                      child: ButtonWidget(
                                                                                        icon: Icon(
                                                                                          Icons.send_rounded,
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                          size: 24.0,
                                                                                        ),
                                                                                        iconPresent: true,
                                                                                        iconEndPresent: false,
                                                                                        content: 'Approve & Send Request',
                                                                                        variant: 'primary',
                                                                                        size: 'small',
                                                                                        fullWidth: false,
                                                                                        loading: false,
                                                                                        disabled: false,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ].divide(SizedBox(width: 16.0)),
                                                                              ),
                                                                            ].divide(SizedBox(height: 16.0)),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      height:
                                                                          24.0)),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .info5,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                              shape: BoxShape
                                                                  .rectangle,
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .info20,
                                                                width: 1.0,
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          24.0),
                                                              child: Container(
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .security_rounded,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                    Expanded(
                                                                      flex: 1,
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Text(
                                                                            'Secure Quarantine Active',
                                                                            style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                  lineHeight: 1.4,
                                                                                ),
                                                                          ),
                                                                          Text(
                                                                            'Messages from unknown senders are quarantined for one-click approval rather than rejected.',
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  lineHeight: 1.5,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(height: 4.0)),
                                                                      ),
                                                                    ),
                                                                    wrapWithModel(
                                                                      model: _model
                                                                          .buttonModel4,
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          ButtonWidget(
                                                                        iconPresent:
                                                                            false,
                                                                        iconEndPresent:
                                                                            false,
                                                                        content:
                                                                            'View Quarantine (0)',
                                                                        variant:
                                                                            'outline',
                                                                        size:
                                                                            'small',
                                                                        fullWidth:
                                                                            false,
                                                                        loading:
                                                                            false,
                                                                        disabled:
                                                                            false,
                                                                      ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      width:
                                                                          16.0)),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 32.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    KeepAliveWidgetWrapper(
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            height: 1.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              shape: BoxShape.rectangle,
                                            ),
                                          ),
                                          SingleChildScrollView(
                                            primary: false,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            controller:
                                                _model.columnScrollController2,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(48.0),
                                                  child: Container(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Expanded(
                                                              flex: 1,
                                                              child: Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        100.0,
                                                                        0.0),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      (FFCrossAxisAlignment
                                                                              .start)
                                                                          .flutterValue,
                                                                  textBaseline:
                                                                      TextBaseline
                                                                          .alphabetic,
                                                                  children: [
                                                                    Text(
                                                                      'Receipts',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .headlineMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.spectral(
                                                                              fontWeight: FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                                                                            lineHeight:
                                                                                1.25,
                                                                          ),
                                                                    ),
                                                                    Text(
                                                                      'Everything the client has sent, in the order it arrived. \nEach item is hashed and timestamped at receipt, before anyone opens it. Click any receipt to inspect its full integrity record.',
                                                                      maxLines:
                                                                          2,
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.ibmPlexSans(
                                                                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).secondaryText,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            lineHeight:
                                                                                1.5,
                                                                          ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      height:
                                                                          4.0)),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              (FFMainAxisAlignment
                                                                      .start)
                                                                  .flutterValue,
                                                          crossAxisAlignment:
                                                              (FFCrossAxisAlignment
                                                                      .center)
                                                                  .flutterValue,
                                                          textBaseline:
                                                              TextBaseline
                                                                  .alphabetic,
                                                          children: [
                                                            Container(
                                                              width: 320.0,
                                                              child: Container(
                                                                width: 200.0,
                                                                child:
                                                                    TextFormField(
                                                                  controller: _model
                                                                      .textController4,
                                                                  focusNode: _model
                                                                      .textFieldFocusNode4,
                                                                  autofocus:
                                                                      false,
                                                                  enabled: true,
                                                                  obscureText:
                                                                      false,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    isDense:
                                                                        true,
                                                                    labelStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.ibmPlexSans(
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondary,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontStyle,
                                                                        ),
                                                                    hintText:
                                                                        'Search Here...',
                                                                    hintStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.ibmPlexSans(
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondary,
                                                                          fontSize:
                                                                              14.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontStyle,
                                                                        ),
                                                                    enabledBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        color: Color(
                                                                            0x00000000),
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              11.0),
                                                                    ),
                                                                    focusedBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        color: Color(
                                                                            0x00000000),
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              11.0),
                                                                    ),
                                                                    errorBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .error,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              11.0),
                                                                    ),
                                                                    focusedErrorBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .error,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              11.0),
                                                                    ),
                                                                    filled:
                                                                        true,
                                                                    fillColor:
                                                                        Color(
                                                                            0x2D2D5A5E),
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .ibmPlexSans(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                  cursorColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  enableInteractiveSelection:
                                                                      true,
                                                                  validator: _model
                                                                      .textController4Validator
                                                                      .asValidator(
                                                                          context),
                                                                ),
                                                              ),
                                                            ),
                                                            Wrap(
                                                              spacing: 8.0,
                                                              runSpacing: 0.0,
                                                              alignment:
                                                                  WrapAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  WrapCrossAlignment
                                                                      .start,
                                                              direction: Axis
                                                                  .horizontal,
                                                              runAlignment:
                                                                  WrapAlignment
                                                                      .start,
                                                              verticalDirection:
                                                                  VerticalDirection
                                                                      .down,
                                                              clipBehavior:
                                                                  Clip.none,
                                                              children: [
                                                                InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.activeFilter =
                                                                        'All';
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height:
                                                                        34.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          12.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Icon(
                                                                            Icons.check_rounded,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            size:
                                                                                16.0,
                                                                          ),
                                                                          Text(
                                                                            'All',
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  lineHeight: 1.3,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 6.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.activeFilter =
                                                                        'Photo';
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height:
                                                                        34.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          12.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Text(
                                                                            'Photo',
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  lineHeight: 1.3,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 6.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.activeFilter =
                                                                        'Video';
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height:
                                                                        34.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          12.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Text(
                                                                            'Video',
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  lineHeight: 1.3,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 6.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.activeFilter =
                                                                        'Document';
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height:
                                                                        34.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          12.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Text(
                                                                            'Document',
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  lineHeight: 1.3,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 6.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.activeFilter =
                                                                        'Email';
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height:
                                                                        34.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          12.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Text(
                                                                            'Email',
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  lineHeight: 1.3,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 6.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.activeFilter =
                                                                        'Physical';
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height:
                                                                        34.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          12.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Text(
                                                                            'Physical',
                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                  lineHeight: 1.3,
                                                                                ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 6.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 16.0)),
                                                        ),
                                                        InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            await showModalBottomSheet(
                                                              isScrollControlled:
                                                                  true,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return GestureDetector(
                                                                  onTap: () {
                                                                    FocusScope.of(
                                                                            context)
                                                                        .unfocus();
                                                                    FocusManager
                                                                        .instance
                                                                        .primaryFocus
                                                                        ?.unfocus();
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding: MediaQuery
                                                                        .viewInsetsOf(
                                                                            context),
                                                                    child:
                                                                        ReceiptDetailsDrawerSheetWidget(),
                                                                  ),
                                                                );
                                                              },
                                                            ).then((value) =>
                                                                safeSetState(
                                                                    () {}));
                                                          },
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              StreamBuilder<
                                                                  List<
                                                                      ReceiptsRecord>>(
                                                                stream:
                                                                    queryReceiptsRecord(
                                                                  queryBuilder: (receiptsRecord) =>
                                                                      receiptsRecord
                                                                          .where(
                                                                            'matterId',
                                                                            isEqualTo:
                                                                                widget.matterDoc?.reference,
                                                                          )
                                                                          .orderBy(
                                                                              'receivedAt',
                                                                              descending: true),
                                                                ),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  // Customize what your widget looks like when it's loading.
                                                                  if (!snapshot
                                                                      .hasData) {
                                                                    return Center(
                                                                      child:
                                                                          SizedBox(
                                                                        width:
                                                                            50.0,
                                                                        height:
                                                                            50.0,
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          valueColor:
                                                                              AlwaysStoppedAnimation<Color>(
                                                                            FlutterFlowTheme.of(context).tertiary,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                  List<ReceiptsRecord>
                                                                      listViewReceiptsRecordList =
                                                                      snapshot
                                                                          .data!;

                                                                  return Builder(
                                                                    builder:
                                                                        (context) {
                                                                      if (!_model
                                                                          .listViewItemPositionsAttached1) {
                                                                        _model.listViewItemPositionsAttached1 =
                                                                            true;
                                                                        _model
                                                                            .listViewItemPositionsListener1
                                                                            .itemPositions
                                                                            .addListener(() {
                                                                          final positions = _model
                                                                              .listViewItemPositionsListener1
                                                                              .itemPositions
                                                                              .value;
                                                                          // An emptied list (a filter that matches nothing, a query returning
                                                                          // no rows) reports no positions. Returning early would leave the last
                                                                          // populated indexes on screen, so clear them instead -- an empty list
                                                                          // has no visible items, and 0/0/[] says so.
                                                                          if (positions
                                                                              .isEmpty) {
                                                                            if (_model.listViewVisibleIndexes1.isNotEmpty) {
                                                                              safeSetState(() {
                                                                                _model.listViewFirstVisibleIndex1 = 0;
                                                                                _model.listViewLastVisibleIndex1 = 0;
                                                                                _model.listViewVisibleIndexes1 = [];
                                                                              });
                                                                            }
                                                                            return;
                                                                          }
                                                                          final indexes = positions
                                                                              .map((position) => position.index)
                                                                              .toList()
                                                                            ..sort();
                                                                          if (indexes.length == _model.listViewVisibleIndexes1.length &&
                                                                              indexes.first == _model.listViewFirstVisibleIndex1 &&
                                                                              indexes.last == _model.listViewLastVisibleIndex1) {
                                                                            return;
                                                                          }
                                                                          safeSetState(
                                                                              () {
                                                                            _model.listViewFirstVisibleIndex1 =
                                                                                indexes.first;
                                                                            _model.listViewLastVisibleIndex1 =
                                                                                indexes.last;
                                                                            _model.listViewVisibleIndexes1 =
                                                                                indexes;
                                                                          });
                                                                        });
                                                                      }
                                                                      return ScrollablePositionedList
                                                                          .builder(
                                                                        itemScrollController:
                                                                            _model.listViewItemScrollController1,
                                                                        itemPositionsListener:
                                                                            _model.listViewItemPositionsListener1,
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        shrinkWrap:
                                                                            true,
                                                                        scrollDirection:
                                                                            Axis.vertical,
                                                                        itemCount:
                                                                            listViewReceiptsRecordList.length,
                                                                        itemBuilder:
                                                                            (context,
                                                                                listViewIndex) {
                                                                          final listViewReceiptsRecord =
                                                                              listViewReceiptsRecordList[listViewIndex];
                                                                          return Container(
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                              borderRadius: BorderRadius.circular(8.0),
                                                                              shape: BoxShape.rectangle,
                                                                              border: Border.all(
                                                                                color: FlutterFlowTheme.of(context).alternate,
                                                                                width: 1.0,
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.all(24.0),
                                                                              child: Container(
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                                  children: [
                                                                                    Row(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                                      children: [
                                                                                        Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            StatusBadge22Widget(
                                                                                              key: Key('Keyeqp_${listViewIndex}_of_${listViewReceiptsRecordList.length}'),
                                                                                              bgColor: Color(0xFFE4EEEF),
                                                                                              label: listViewReceiptsRecord.channel,
                                                                                              textColor: FlutterFlowTheme.of(context).secondary,
                                                                                            ),
                                                                                            StatusBadge22Widget(
                                                                                              key: Key('Keyjze_${listViewIndex}_of_${listViewReceiptsRecordList.length}'),
                                                                                              bgColor: Color(0x1E2F7D5B),
                                                                                              label: listViewReceiptsRecord.classificationLabel,
                                                                                              textColor: FlutterFlowTheme.of(context).secondary,
                                                                                            ),
                                                                                          ].divide(SizedBox(width: 8.0)),
                                                                                        ),
                                                                                        Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Text(
                                                                                              dateTimeFormat(
                                                                                                "MMM d, yyyy, h:mm a",
                                                                                                listViewReceiptsRecord.receivedAt!,
                                                                                                locale: FFLocalizations.of(context).languageCode,
                                                                                              ),
                                                                                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                    ),
                                                                                                    color: FlutterFlowTheme.of(context).secondary,
                                                                                                    letterSpacing: 0.0,
                                                                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                                    lineHeight: 1.3,
                                                                                                  ),
                                                                                            ),
                                                                                            Icon(
                                                                                              Icons.chevron_right_rounded,
                                                                                              color: FlutterFlowTheme.of(context).accent3,
                                                                                              size: 16.0,
                                                                                            ),
                                                                                          ].divide(SizedBox(width: 4.0)),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    Column(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                                      children: [
                                                                                        Text(
                                                                                          valueOrDefault<String>(
                                                                                            listViewReceiptsRecord.content,
                                                                                            'Doorbell clip 0001 — exchange 4/18, arrived 6:12pm',
                                                                                          ),
                                                                                          style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                                font: GoogleFonts.ibmPlexSans(
                                                                                                  fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                                ),
                                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                                lineHeight: 1.4,
                                                                                              ),
                                                                                        ),
                                                                                        Text(
                                                                                          '${listViewReceiptsRecord.itemKind}·${listViewReceiptsRecord.durationSeconds.toString()}·${dateTimeFormat(
                                                                                            "M/d h:mm a",
                                                                                            _model.requests?.sentAt,
                                                                                            locale: FFLocalizations.of(context).languageCode,
                                                                                          )}· Dated ${listViewReceiptsRecord.resolvedDate?.toString()}· confidence',
                                                                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                                font: GoogleFonts.ibmPlexSans(
                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                                ),
                                                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                                lineHeight: 1.5,
                                                                                              ),
                                                                                        ),
                                                                                      ].divide(SizedBox(height: 4.0)),
                                                                                    ),
                                                                                    Row(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                                      children: [
                                                                                        if ((widget.matterDoc?.hasChainRoot == null) && (listViewReceiptsRecord.hasChronologyShift == false))
                                                                                          StatusBadge22Widget(
                                                                                            key: Key('Keysuy_${listViewIndex}_of_${listViewReceiptsRecordList.length}'),
                                                                                            bgColor: Color(0x1EB0791C),
                                                                                            label: listViewReceiptsRecord.originFidelity,
                                                                                            textColor: FlutterFlowTheme.of(context).warning,
                                                                                          ),
                                                                                        if (listViewReceiptsRecord.isTranscribed == true)
                                                                                          StatusBadge22Widget(
                                                                                            key: Key('Keynty_${listViewIndex}_of_${listViewReceiptsRecordList.length}'),
                                                                                            bgColor: Color(0x2C2F7D5B),
                                                                                            label: valueOrDefault<String>(
                                                                                              listViewReceiptsRecord.isTranscribed.toString(),
                                                                                              'Transcribed',
                                                                                            ),
                                                                                            textColor: FlutterFlowTheme.of(context).success,
                                                                                          ),
                                                                                      ].divide(SizedBox(width: 8.0)),
                                                                                    ),
                                                                                    Divider(
                                                                                      height: 16.0,
                                                                                      thickness: 1.0,
                                                                                      indent: 0.0,
                                                                                      endIndent: 0.0,
                                                                                      color: FlutterFlowTheme.of(context).alternate,
                                                                                    ),
                                                                                    Row(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                                      children: [
                                                                                        Text(
                                                                                          'SHA-256',
                                                                                          style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                                font: GoogleFonts.spaceGrotesk(
                                                                                                  fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                ),
                                                                                                color: FlutterFlowTheme.of(context).accent3,
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                lineHeight: 1.2,
                                                                                              ),
                                                                                        ),
                                                                                        Text(
                                                                                          listViewReceiptsRecord.itemHash,
                                                                                          style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                                font: GoogleFonts.spaceGrotesk(
                                                                                                  fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                ),
                                                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                lineHeight: 1.2,
                                                                                              ),
                                                                                          overflow: TextOverflow.fade,
                                                                                        ),
                                                                                      ].divide(SizedBox(width: 4.0)),
                                                                                    ),
                                                                                  ].divide(SizedBox(height: 16.0)),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 16.0)),
                                                          ),
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 24.0)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    KeepAliveWidgetWrapper(
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            height: 1.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              shape: BoxShape.rectangle,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Container(
                                                  width: 380.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    shape: BoxShape.rectangle,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(24.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Evidence Source: ${_model.listViewVisibleIndexes1.length.toString()}',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .titleSmall
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .ibmPlexSans(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .titleSmall
                                                                          .fontStyle,
                                                                    ),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontStyle,
                                                                    lineHeight:
                                                                        1.4,
                                                                  ),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .filter_list_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              size: 20.0,
                                                            ),
                                                          ],
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        24.0),
                                                            child: Container(
                                                              child: StreamBuilder<
                                                                  List<
                                                                      ReceiptsRecord>>(
                                                                stream:
                                                                    queryReceiptsRecord(
                                                                  queryBuilder: (receiptsRecord) =>
                                                                      receiptsRecord
                                                                          .where(
                                                                            'matterId',
                                                                            isEqualTo:
                                                                                widget.matterDoc?.reference,
                                                                          )
                                                                          .where(
                                                                            'itemKind',
                                                                            isEqualTo:
                                                                                'photo',
                                                                          ),
                                                                ),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  // Customize what your widget looks like when it's loading.
                                                                  if (!snapshot
                                                                      .hasData) {
                                                                    return Center(
                                                                      child:
                                                                          SizedBox(
                                                                        width:
                                                                            50.0,
                                                                        height:
                                                                            50.0,
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          valueColor:
                                                                              AlwaysStoppedAnimation<Color>(
                                                                            FlutterFlowTheme.of(context).tertiary,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                  List<ReceiptsRecord>
                                                                      gridReceiptsRecordList =
                                                                      snapshot
                                                                          .data!;

                                                                  return GridView
                                                                      .builder(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    gridDelegate:
                                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                                      crossAxisCount:
                                                                          2,
                                                                      crossAxisSpacing:
                                                                          16.0,
                                                                      mainAxisSpacing:
                                                                          0.0,
                                                                      childAspectRatio:
                                                                          1.0,
                                                                    ),
                                                                    primary:
                                                                        false,
                                                                    shrinkWrap:
                                                                        true,
                                                                    scrollDirection:
                                                                        Axis.vertical,
                                                                    physics:
                                                                        const AlwaysScrollableScrollPhysics(),
                                                                    itemCount:
                                                                        gridReceiptsRecordList
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            gridIndex) {
                                                                      final gridReceiptsRecord =
                                                                          gridReceiptsRecordList[
                                                                              gridIndex];
                                                                      return InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          safeSetState(
                                                                              () {});
                                                                        },
                                                                        child:
                                                                            EvidenceThumbWidget(
                                                                          key: Key(
                                                                              'Keyte8_${gridIndex}_of_${gridReceiptsRecordList.length}'),
                                                                          idLabel: _model
                                                                              .matterReceipts
                                                                              ?.lastOrNull
                                                                              ?.matterId
                                                                              ?.id,
                                                                          selected:
                                                                              true,
                                                                          selectedSourceIndex: _model
                                                                              .listViewVisibleIndexes1
                                                                              .length,
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 16.0)),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .info10,
                                                          shape: BoxShape
                                                              .rectangle,
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          24.0,
                                                                          8.0,
                                                                          24.0,
                                                                          8.0),
                                                              child: Container(
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children:
                                                                          [
                                                                        Icon(
                                                                          Icons
                                                                              .devices_rounded,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).tertiary,
                                                                          size:
                                                                              18.0,
                                                                        ),
                                                                        Text(
                                                                          'Platform: ${_model.matterReceipts?.lastOrNull?.detectedPlatform}',
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .override(
                                                                                font: GoogleFonts.ibmPlexSans(
                                                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                ),
                                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                lineHeight: 1.3,
                                                                              ),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 16.0)),
                                                                    ),
                                                                    Expanded(
                                                                      flex: 1,
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children:
                                                                            [
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                8.0,
                                                                                0.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                Text(
                                                                              '${_model.gapResult?.toString()} Accuracy',
                                                                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                    font: GoogleFonts.ibmPlexSans(
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).secondary,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                                                    lineHeight: 1.3,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            width:
                                                                                100.0,
                                                                            height:
                                                                                8.0,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).info20,
                                                                              borderRadius: BorderRadius.circular(9999.0),
                                                                              shape: BoxShape.rectangle,
                                                                            ),
                                                                            child:
                                                                                LinearPercentIndicator(
                                                                              percent: _model.gapResult!,
                                                                              width: 100.0,
                                                                              lineHeight: 12.0,
                                                                              animation: true,
                                                                              animateFromLastPercent: true,
                                                                              progressColor: Color(0xFF68BE5C),
                                                                              backgroundColor: Color(0x1D545454),
                                                                              center: Text(
                                                                                '50%',
                                                                                style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                                      font: GoogleFonts.spectral(
                                                                                        fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                      ),
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                                    ),
                                                                              ),
                                                                              barRadius: Radius.circular(50.0),
                                                                              padding: EdgeInsets.zero,
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 8.0)),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              height: 1.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                shape: BoxShape
                                                                    .rectangle,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Container(
                                                          child:
                                                              SingleChildScrollView(
                                                            primary: false,
                                                            controller: _model
                                                                .columnScrollController3,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              24.0),
                                                                  child:
                                                                      Container(
                                                                    child:
                                                                        ListView(
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      shrinkWrap:
                                                                          true,
                                                                      scrollDirection:
                                                                          Axis.vertical,
                                                                      children: [
                                                                        Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.stretch,
                                                                          children:
                                                                              [
                                                                            Builder(
                                                                              builder: (context) {
                                                                                if (widget.matterDoc?.hasFirmID() ?? false) {
                                                                                  return Container(
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                      shape: BoxShape.rectangle,
                                                                                      border: Border.all(
                                                                                        color: FlutterFlowTheme.of(context).alternate,
                                                                                        width: 1.0,
                                                                                      ),
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(16.0),
                                                                                      child: Container(
                                                                                        child: Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Icon(
                                                                                              Icons.link_off_rounded,
                                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                                              size: 16.0,
                                                                                            ),
                                                                                            Text(
                                                                                              'Gap — continuity not established',
                                                                                              style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                                    font: GoogleFonts.spaceGrotesk(
                                                                                                      fontWeight: FontWeight.bold,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                    ),
                                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                    letterSpacing: 0.0,
                                                                                                    fontWeight: FontWeight.bold,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                    lineHeight: 1.2,
                                                                                                  ),
                                                                                            ),
                                                                                          ].divide(SizedBox(width: 8.0)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                } else {
                                                                                  return Align(
                                                                                    alignment: AlignmentDirectional(1.0, 0.0),
                                                                                    child: wrapWithModel(
                                                                                      model: _model.messageBubbleModel1,
                                                                                      updateCallback: () => safeSetState(() {}),
                                                                                      child: MessageBubbleWidget(
                                                                                        repeated: 'Repeated',
                                                                                        repeatedPresent: false,
                                                                                        isClient: false,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                            ),
                                                                            Builder(
                                                                              builder: (context) {
                                                                                if (widget.matterDoc?.isArchiveBuild ?? false) {
                                                                                  return Container(
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                      shape: BoxShape.rectangle,
                                                                                      border: Border.all(
                                                                                        color: FlutterFlowTheme.of(context).alternate,
                                                                                        width: 1.0,
                                                                                      ),
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(16.0),
                                                                                      child: Container(
                                                                                        child: Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Icon(
                                                                                              Icons.link_off_rounded,
                                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                                              size: 16.0,
                                                                                            ),
                                                                                            Text(
                                                                                              'Gap — continuity not established',
                                                                                              style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                                    font: GoogleFonts.spaceGrotesk(
                                                                                                      fontWeight: FontWeight.bold,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                    ),
                                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                    letterSpacing: 0.0,
                                                                                                    fontWeight: FontWeight.bold,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                    lineHeight: 1.2,
                                                                                                  ),
                                                                                            ),
                                                                                          ].divide(SizedBox(width: 8.0)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                } else {
                                                                                  return Align(
                                                                                    alignment: AlignmentDirectional(-1.0, 0.0),
                                                                                    child: wrapWithModel(
                                                                                      model: _model.messageBubbleModel2,
                                                                                      updateCallback: () => safeSetState(() {}),
                                                                                      child: MessageBubbleWidget(
                                                                                        repeated: 'Repeated',
                                                                                        repeatedPresent: false,
                                                                                        isClient: false,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                            ),
                                                                            Builder(
                                                                              builder: (context) {
                                                                                if (widget.matterDoc?.hasChainRoot ?? false) {
                                                                                  return Container(
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                      shape: BoxShape.rectangle,
                                                                                      border: Border.all(
                                                                                        color: FlutterFlowTheme.of(context).alternate,
                                                                                        width: 1.0,
                                                                                      ),
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(16.0),
                                                                                      child: Container(
                                                                                        child: Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Icon(
                                                                                              Icons.link_off_rounded,
                                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                                              size: 16.0,
                                                                                            ),
                                                                                            Text(
                                                                                              'Gap — continuity not established',
                                                                                              style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                                    font: GoogleFonts.spaceGrotesk(
                                                                                                      fontWeight: FontWeight.bold,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                    ),
                                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                    letterSpacing: 0.0,
                                                                                                    fontWeight: FontWeight.bold,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                    lineHeight: 1.2,
                                                                                                  ),
                                                                                            ),
                                                                                          ].divide(SizedBox(width: 8.0)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                } else {
                                                                                  return Align(
                                                                                    alignment: AlignmentDirectional(1.0, 0.0),
                                                                                    child: wrapWithModel(
                                                                                      model: _model.messageBubbleModel3,
                                                                                      updateCallback: () => safeSetState(() {}),
                                                                                      child: MessageBubbleWidget(
                                                                                        repeated: 'Repeated',
                                                                                        repeatedPresent: false,
                                                                                        isClient: false,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                            ),
                                                                          ].divide(SizedBox(height: 24.0)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    KeepAliveWidgetWrapper(
                                      builder: (context) =>
                                          SingleChildScrollView(
                                        primary: false,
                                        controller: _model.columnController,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              height: 1.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                shape: BoxShape.rectangle,
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              height: MediaQuery.sizeOf(context)
                                                      .height *
                                                  1.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(32.0),
                                                child: SingleChildScrollView(
                                                  primary: false,
                                                  controller: _model
                                                      .columnScrollController4,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            (FFCrossAxisAlignment
                                                                    .start)
                                                                .flutterValue,
                                                        textBaseline:
                                                            TextBaseline
                                                                .alphabetic,
                                                        children: [
                                                          Text(
                                                            'Integrity at receipt',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .headlineMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .spectral(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.25,
                                                                ),
                                                          ),
                                                          Text(
                                                            'A third party holding only an exported file and its manifest can verify the hash and the timestamp without any access to Verin.',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 8.0)),
                                                      ),
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    wrapWithModel(
                                                                  model: _model
                                                                      .integrityCardModel1,
                                                                  updateCallback: () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                  child:
                                                                      IntegrityCardWidget(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .shield_rounded,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                    label:
                                                                        'Chain status',
                                                                    tone: FlutterFlowTheme.of(
                                                                            context)
                                                                        .success,
                                                                    value:
                                                                        'Verified',
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    wrapWithModel(
                                                                  model: _model
                                                                      .integrityCardModel2,
                                                                  updateCallback: () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                  child:
                                                                      IntegrityCardWidget(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .anchor_rounded,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                    label:
                                                                        'Last external anchor',
                                                                    tone: FlutterFlowTheme.of(
                                                                            context)
                                                                        .success,
                                                                    value:
                                                                        'Today, 04:00',
                                                                  ),
                                                                ),
                                                              ),
                                                            ].divide(SizedBox(
                                                                width: 16.0)),
                                                          ),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    wrapWithModel(
                                                                  model: _model
                                                                      .integrityCardModel3,
                                                                  updateCallback: () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                  child:
                                                                      IntegrityCardWidget(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .history_rounded,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                    label:
                                                                        'Record Lag (median)',
                                                                    tone: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    value:
                                                                        '461 days',
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    wrapWithModel(
                                                                  model: _model
                                                                      .integrityCardModel4,
                                                                  updateCallback: () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                  child:
                                                                      IntegrityCardWidget(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .description_rounded,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                    label:
                                                                        'The Standing Record',
                                                                    tone: FlutterFlowTheme.of(
                                                                            context)
                                                                        .success,
                                                                    value:
                                                                        '4 items built',
                                                                  ),
                                                                ),
                                                              ),
                                                            ].divide(SizedBox(
                                                                width: 16.0)),
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 16.0)),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          shape: BoxShape
                                                              .rectangle,
                                                          border: Border.all(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .alternate,
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  32.0),
                                                          child: Container(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Text(
                                                                  'PER-MATTER HASH CHAIN',
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .ibmPlexSans(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontStyle,
                                                                        lineHeight:
                                                                            1.3,
                                                                      ),
                                                                ),
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Color(
                                                                        0xFFE4EEEF),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            50.0),
                                                                    shape: BoxShape
                                                                        .rectangle,
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            16.0),
                                                                    child:
                                                                        Container(
                                                                      child:
                                                                          Text(
                                                                        'entry = SHA256( prev_hash || item_hash || received_at || origin_digest )',
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .labelSmall
                                                                            .override(
                                                                              font: GoogleFonts.spaceGrotesk(
                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                              ),
                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                              lineHeight: 1.2,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    wrapWithModel(
                                                                      model: _model
                                                                          .hashRowModel1,
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          HashRowWidget(
                                                                        hash:
                                                                            '5d8dd7378ced61bf0fe1e3f570094c80ac89d09ce99fab2eaac5636c78b49155',
                                                                        index:
                                                                            '1',
                                                                      ),
                                                                    ),
                                                                    wrapWithModel(
                                                                      model: _model
                                                                          .hashRowModel2,
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          HashRowWidget(
                                                                        hash:
                                                                            '65c3ec5933b2e285e874bda5849861d7cfd5b24142cfacd217b24360f1fb0456',
                                                                        index:
                                                                            '2',
                                                                      ),
                                                                    ),
                                                                    wrapWithModel(
                                                                      model: _model
                                                                          .hashRowModel3,
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          HashRowWidget(
                                                                        hash:
                                                                            '46021ae74f588206d7f6e18e49edfe2d7374bafbf1d8b19455f0be4e2cf86bad',
                                                                        index:
                                                                            '3',
                                                                      ),
                                                                    ),
                                                                    wrapWithModel(
                                                                      model: _model
                                                                          .hashRowModel4,
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          HashRowWidget(
                                                                        hash:
                                                                            '90545124a41d32d03420892646307918b5d6d5bf3be3424a4a9613373478a476',
                                                                        index:
                                                                            '4',
                                                                      ),
                                                                    ),
                                                                    wrapWithModel(
                                                                      model: _model
                                                                          .hashRowModel5,
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          HashRowWidget(
                                                                        hash:
                                                                            '25567ef5ea476c5d9f6065b3804545630041394358b1bcc6a427d3d36255ee1d',
                                                                        index:
                                                                            '5',
                                                                      ),
                                                                    ),
                                                                    wrapWithModel(
                                                                      model: _model
                                                                          .hashRowModel6,
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          HashRowWidget(
                                                                        hash:
                                                                            '9640ba21bd428e01f7714dcd3ee9eac36b72ed9092854e7c4bd70bae1897981e',
                                                                        index:
                                                                            '6',
                                                                      ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      height:
                                                                          8.0)),
                                                                ),
                                                                Divider(
                                                                  height: 16.0,
                                                                  thickness:
                                                                      1.0,
                                                                  indent: 0.0,
                                                                  endIndent:
                                                                      0.0,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .alternate,
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      'Chain head',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.spaceGrotesk(
                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).secondaryText,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                            lineHeight:
                                                                                1.2,
                                                                          ),
                                                                    ),
                                                                    Text(
                                                                      '9640ba21bd428e01f7714dcd3ee9eac36b72ed9092854e7c4bd70bae1897981e',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.spaceGrotesk(
                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                            lineHeight:
                                                                                1.2,
                                                                          ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      width:
                                                                          16.0)),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  height:
                                                                      24.0)),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          wrapWithModel(
                                                            model: _model
                                                                .buttonModel1,
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                Button19Widget(
                                                              icon: Icon(
                                                                Icons
                                                                    .description_rounded,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                size: 24.0,
                                                              ),
                                                              iconPresent: true,
                                                              iconEndPresent:
                                                                  false,
                                                              content:
                                                                  'Certificate of preparation',
                                                              variant:
                                                                  'primary',
                                                              size: 'large',
                                                              fullWidth: false,
                                                              loading: false,
                                                              disabled: false,
                                                            ),
                                                          ),
                                                          wrapWithModel(
                                                            model: _model
                                                                .buttonModel2,
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                Button19Widget(
                                                              icon: Icon(
                                                                Icons
                                                                    .verified_rounded,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                size: 24.0,
                                                              ),
                                                              iconPresent: true,
                                                              iconEndPresent:
                                                                  false,
                                                              content:
                                                                  'Standalone verify tool',
                                                              variant:
                                                                  'outline',
                                                              size: 'large',
                                                              fullWidth: false,
                                                              loading: false,
                                                              disabled: false,
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 16.0)),
                                                      ),
                                                      Text(
                                                        'Verin does not practice law. No opinion on authenticity, completeness, or admissibility is offered or implied — those determinations belong to counsel and the Court.',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .accent3,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(height: 32.0)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    KeepAliveWidgetWrapper(
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            height: 1.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              shape: BoxShape.rectangle,
                                            ),
                                          ),
                                          SingleChildScrollView(
                                            primary: false,
                                            controller:
                                                _model.columnScrollController5,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  (FFCrossAxisAlignment.end)
                                                      .flutterValue,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(32.0),
                                                  child: Container(
                                                    child:
                                                        SingleChildScrollView(
                                                      primary: false,
                                                      controller: _model
                                                          .columnScrollController6,
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                crossAxisAlignment:
                                                                    (FFCrossAxisAlignment
                                                                            .start)
                                                                        .flutterValue,
                                                                textBaseline:
                                                                    TextBaseline
                                                                        .alphabetic,
                                                                children: [
                                                                  Text(
                                                                    'Practice management',
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .headlineMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.spectral(
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .headlineMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .headlineMedium
                                                                              .fontStyle,
                                                                          lineHeight:
                                                                              1.25,
                                                                        ),
                                                                  ),
                                                                  Text(
                                                                    'Finished records and exhibit sets appear inside your practice management system.',
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.ibmPlexSans(
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryText,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        4.0)),
                                                              ),
                                                              wrapWithModel(
                                                                model: _model
                                                                    .buttonModel1,
                                                                updateCallback: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                                child:
                                                                    Button20Widget(
                                                                  icon: Icon(
                                                                    Icons
                                                                        .download,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    size: 24.0,
                                                                  ),
                                                                  iconPresent:
                                                                      true,
                                                                  iconEndPresent:
                                                                      false,
                                                                  content:
                                                                      'Integration report',
                                                                  variant:
                                                                      'outline',
                                                                  size:
                                                                      'medium',
                                                                  fullWidth:
                                                                      false,
                                                                  loading:
                                                                      false,
                                                                  disabled:
                                                                      false,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SingleChildScrollView(
                                                            primary: false,
                                                            controller: _model
                                                                .columnScrollController7,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryBackground,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                    shape: BoxShape
                                                                        .rectangle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            24.0),
                                                                    child:
                                                                        Container(
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.stretch,
                                                                        children:
                                                                            [
                                                                          Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 40.0,
                                                                                    height: 40.0,
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                      shape: BoxShape.rectangle,
                                                                                    ),
                                                                                    alignment: AlignmentDirectional(0.0, 0.0),
                                                                                    child: Icon(
                                                                                      Icons.business_center,
                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                      size: 24.0,
                                                                                    ),
                                                                                  ),
                                                                                  Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        'Clio Manage',
                                                                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                              font: GoogleFonts.ibmPlexSans(
                                                                                                fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                              ),
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                              lineHeight: 1.4,
                                                                                            ),
                                                                                      ),
                                                                                      Text(
                                                                                        'Matched to CLIO-8841 (Whitmore v. Whitmore)',
                                                                                        style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                              font: GoogleFonts.spaceGrotesk(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              ),
                                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              lineHeight: 1.2,
                                                                                            ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ].divide(SizedBox(width: 16.0)),
                                                                              ),
                                                                              Container(
                                                                                decoration: BoxDecoration(
                                                                                  color: Color(0x1A3E6B4F),
                                                                                  borderRadius: BorderRadius.circular(9999.0),
                                                                                  shape: BoxShape.rectangle,
                                                                                ),
                                                                                child: Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                                                                  child: Container(
                                                                                    child: Row(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                                      children: [
                                                                                        Icon(
                                                                                          Icons.check_circle,
                                                                                          color: Colors.white,
                                                                                          size: 12.0,
                                                                                        ),
                                                                                        Text(
                                                                                          'In Clio',
                                                                                          style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                                font: GoogleFonts.spaceGrotesk(
                                                                                                  fontWeight: FontWeight.bold,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                ),
                                                                                                color: Colors.white,
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FontWeight.bold,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                                lineHeight: 1.2,
                                                                                              ),
                                                                                        ),
                                                                                      ].divide(SizedBox(width: 4.0)),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Container(
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Color(0x4DF1EFEA),
                                                                              borderRadius: BorderRadius.circular(6.0),
                                                                              shape: BoxShape.rectangle,
                                                                            ),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.all(16.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                children: [
                                                                                  Row(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: [
                                                                                      Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        children: [
                                                                                          Icon(
                                                                                            Icons.check_circle_outline,
                                                                                            color: FlutterFlowTheme.of(context).success,
                                                                                            size: 16.0,
                                                                                          ),
                                                                                          Text(
                                                                                            'Record document (PDF/A)',
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  ),
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  lineHeight: 1.5,
                                                                                                ),
                                                                                          ),
                                                                                        ].divide(SizedBox(width: 8.0)),
                                                                                      ),
                                                                                      Text(
                                                                                        'synced 2m ago',
                                                                                        style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                              font: GoogleFonts.spaceGrotesk(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              ),
                                                                                              color: Color(0xFF1A1A1A),
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              lineHeight: 1.2,
                                                                                            ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  Row(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: [
                                                                                      Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        children: [
                                                                                          Icon(
                                                                                            Icons.check_circle_outline,
                                                                                            color: FlutterFlowTheme.of(context).success,
                                                                                            size: 16.0,
                                                                                          ),
                                                                                          Text(
                                                                                            'Exhibit set (Zip Archive)',
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  ),
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  lineHeight: 1.5,
                                                                                                ),
                                                                                          ),
                                                                                        ].divide(SizedBox(width: 8.0)),
                                                                                      ),
                                                                                      Text(
                                                                                        'synced 2m ago',
                                                                                        style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                              font: GoogleFonts.spaceGrotesk(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              ),
                                                                                              color: Color(0xFF1A1A1A),
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              lineHeight: 1.2,
                                                                                            ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  Row(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: [
                                                                                      Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        children: [
                                                                                          Icon(
                                                                                            Icons.check_circle_outline,
                                                                                            color: FlutterFlowTheme.of(context).success,
                                                                                            size: 16.0,
                                                                                          ),
                                                                                          Text(
                                                                                            'Certificate of preparation',
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  ),
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                  lineHeight: 1.5,
                                                                                                ),
                                                                                          ),
                                                                                        ].divide(SizedBox(width: 8.0)),
                                                                                      ),
                                                                                      Text(
                                                                                        'synced 2m ago',
                                                                                        style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                              font: GoogleFonts.spaceGrotesk(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              ),
                                                                                              color: Color(0xFF1A1A1A),
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              lineHeight: 1.2,
                                                                                            ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ].divide(SizedBox(height: 8.0)),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.start,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            children:
                                                                                [
                                                                              wrapWithModel(
                                                                                model: _model.buttonModel2,
                                                                                updateCallback: () => safeSetState(() {}),
                                                                                child: Button20Widget(
                                                                                  icon: Icon(
                                                                                    Icons.cloud_done,
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    size: 24.0,
                                                                                  ),
                                                                                  iconPresent: true,
                                                                                  iconEndPresent: false,
                                                                                  content: 'Up to date in Clio',
                                                                                  variant: 'secondary',
                                                                                  size: 'medium',
                                                                                  fullWidth: false,
                                                                                  loading: false,
                                                                                  disabled: false,
                                                                                ),
                                                                              ),
                                                                              wrapWithModel(
                                                                                model: _model.buttonModel3,
                                                                                updateCallback: () => safeSetState(() {}),
                                                                                child: Button20Widget(
                                                                                  icon: Icon(
                                                                                    Icons.open_in_new,
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    size: 24.0,
                                                                                  ),
                                                                                  iconPresent: true,
                                                                                  iconEndPresent: false,
                                                                                  content: 'View in Clio',
                                                                                  variant: 'outline',
                                                                                  size: 'medium',
                                                                                  fullWidth: false,
                                                                                  loading: false,
                                                                                  disabled: false,
                                                                                ),
                                                                              ),
                                                                            ].divide(SizedBox(width: 16.0)),
                                                                          ),
                                                                        ].divide(SizedBox(height: 16.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryBackground,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                    shape: BoxShape
                                                                        .rectangle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            24.0),
                                                                    child:
                                                                        Container(
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.stretch,
                                                                        children:
                                                                            [
                                                                          Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 40.0,
                                                                                    height: 40.0,
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                      shape: BoxShape.rectangle,
                                                                                    ),
                                                                                    alignment: AlignmentDirectional(0.0, 0.0),
                                                                                    child: Icon(
                                                                                      Icons.business,
                                                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                                                      size: 24.0,
                                                                                    ),
                                                                                  ),
                                                                                  Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        'MyCase',
                                                                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                              font: GoogleFonts.ibmPlexSans(
                                                                                                fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                              ),
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                              lineHeight: 1.4,
                                                                                            ),
                                                                                      ),
                                                                                      Text(
                                                                                        'Not connected',
                                                                                        style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                              font: GoogleFonts.spaceGrotesk(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              ),
                                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              lineHeight: 1.2,
                                                                                            ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ].divide(SizedBox(width: 16.0)),
                                                                              ),
                                                                              Container(
                                                                                decoration: BoxDecoration(
                                                                                  color: FlutterFlowTheme.of(context).alternate,
                                                                                  borderRadius: BorderRadius.circular(9999.0),
                                                                                  shape: BoxShape.rectangle,
                                                                                ),
                                                                                child: Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                                                                  child: Container(
                                                                                    child: Text(
                                                                                      'Not connected',
                                                                                      style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                            font: GoogleFonts.spaceGrotesk(
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                            ),
                                                                                            color: FlutterFlowTheme.of(context).secondaryText,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                            lineHeight: 1.2,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Text(
                                                                            'Connect MyCase to automatically sync finished records and exhibit sets when you push.',
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  lineHeight: 1.5,
                                                                                ),
                                                                          ),
                                                                          wrapWithModel(
                                                                            model:
                                                                                _model.buttonModel4,
                                                                            updateCallback: () =>
                                                                                safeSetState(() {}),
                                                                            child:
                                                                                Button20Widget(
                                                                              icon: Icon(
                                                                                Icons.link,
                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                                size: 24.0,
                                                                              ),
                                                                              iconPresent: true,
                                                                              iconEndPresent: false,
                                                                              content: 'Connect MyCase',
                                                                              variant: 'outline',
                                                                              size: 'medium',
                                                                              fullWidth: false,
                                                                              loading: false,
                                                                              disabled: false,
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(height: 16.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryBackground,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                    shape: BoxShape
                                                                        .rectangle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            24.0),
                                                                    child:
                                                                        Container(
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.stretch,
                                                                        children:
                                                                            [
                                                                          Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.center,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                children: [
                                                                                  Container(
                                                                                    width: 40.0,
                                                                                    height: 40.0,
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                      borderRadius: BorderRadius.circular(6.0),
                                                                                      shape: BoxShape.rectangle,
                                                                                    ),
                                                                                    alignment: AlignmentDirectional(0.0, 0.0),
                                                                                    child: Icon(
                                                                                      Icons.bolt,
                                                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                                                      size: 24.0,
                                                                                    ),
                                                                                  ),
                                                                                  Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        'Smokeball',
                                                                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                              font: GoogleFonts.ibmPlexSans(
                                                                                                fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                              ),
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).titleMedium.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                                                                              lineHeight: 1.4,
                                                                                            ),
                                                                                      ),
                                                                                      Text(
                                                                                        'Not connected',
                                                                                        style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                              font: GoogleFonts.spaceGrotesk(
                                                                                                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              ),
                                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                              lineHeight: 1.2,
                                                                                            ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ].divide(SizedBox(width: 16.0)),
                                                                              ),
                                                                              Container(
                                                                                decoration: BoxDecoration(
                                                                                  color: FlutterFlowTheme.of(context).alternate,
                                                                                  borderRadius: BorderRadius.circular(9999.0),
                                                                                  shape: BoxShape.rectangle,
                                                                                ),
                                                                                child: Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                                                                  child: Container(
                                                                                    child: Text(
                                                                                      'Not connected',
                                                                                      style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                                            font: GoogleFonts.spaceGrotesk(
                                                                                              fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                            ),
                                                                                            color: FlutterFlowTheme.of(context).secondaryText,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                                                                                            lineHeight: 1.2,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Text(
                                                                            'Connect Smokeball to automatically sync finished records and exhibit sets when you push.',
                                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                                  font: GoogleFonts.ibmPlexSans(
                                                                                    fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                                  lineHeight: 1.5,
                                                                                ),
                                                                          ),
                                                                          wrapWithModel(
                                                                            model:
                                                                                _model.buttonModel5,
                                                                            updateCallback: () =>
                                                                                safeSetState(() {}),
                                                                            child:
                                                                                Button20Widget(
                                                                              icon: Icon(
                                                                                Icons.link,
                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                                size: 24.0,
                                                                              ),
                                                                              iconPresent: true,
                                                                              iconEndPresent: false,
                                                                              content: 'Connect Smokeball',
                                                                              variant: 'outline',
                                                                              size: 'medium',
                                                                              fullWidth: false,
                                                                              loading: false,
                                                                              disabled: false,
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(height: 16.0)),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  height:
                                                                      24.0)),
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Color(
                                                                  0x80F1EFEA),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                              shape: BoxShape
                                                                  .rectangle,
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          24.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    'On a second push the existing document is versioned, never duplicated. Any failure is surfaced here — a write-back that fails silently is a trust incident, not a bug.',
                                                                    maxLines: 3,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.ibmPlexSans(
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryText,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .fontStyle,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        4.0)),
                                                              ),
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 32.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
