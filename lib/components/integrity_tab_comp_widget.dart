import '/components/button19_widget.dart';
import '/components/hash_row_widget.dart';
import '/components/integrity_card_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'integrity_tab_comp_model.dart';
export 'integrity_tab_comp_model.dart';

class IntegrityTabCompWidget extends StatefulWidget {
  const IntegrityTabCompWidget({super.key});

  @override
  State<IntegrityTabCompWidget> createState() => _IntegrityTabCompWidgetState();
}

class _IntegrityTabCompWidgetState extends State<IntegrityTabCompWidget> {
  late IntegrityTabCompModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => IntegrityTabCompModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 1.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          primary: false,
          controller: _model.columnScrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: (FFCrossAxisAlignment.start).flutterValue,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Integrity at receipt',
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                          font: GoogleFonts.spectral(
                            fontWeight: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .fontStyle,
                          lineHeight: 1.25,
                        ),
                  ),
                  Text(
                    'A third party holding only an exported file and its manifest can verify the hash and the timestamp without any access to Verin.',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.ibmPlexSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.5,
                        ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: wrapWithModel(
                          model: _model.integrityCardModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: IntegrityCardWidget(
                            icon: Icon(
                              Icons.shield_rounded,
                              color: FlutterFlowTheme.of(context).secondary,
                              size: 24.0,
                            ),
                            label: 'Chain status',
                            tone: FlutterFlowTheme.of(context).success,
                            value: 'Verified',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: wrapWithModel(
                          model: _model.integrityCardModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: IntegrityCardWidget(
                            icon: Icon(
                              Icons.anchor_rounded,
                              color: FlutterFlowTheme.of(context).secondary,
                              size: 24.0,
                            ),
                            label: 'Last external anchor',
                            tone: FlutterFlowTheme.of(context).success,
                            value: 'Today, 04:00',
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: wrapWithModel(
                          model: _model.integrityCardModel3,
                          updateCallback: () => safeSetState(() {}),
                          child: IntegrityCardWidget(
                            icon: Icon(
                              Icons.history_rounded,
                              color: FlutterFlowTheme.of(context).secondary,
                              size: 24.0,
                            ),
                            label: 'Record Lag (median)',
                            tone: FlutterFlowTheme.of(context).error,
                            value: '461 days',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: wrapWithModel(
                          model: _model.integrityCardModel4,
                          updateCallback: () => safeSetState(() {}),
                          child: IntegrityCardWidget(
                            icon: Icon(
                              Icons.description_rounded,
                              color: FlutterFlowTheme.of(context).secondary,
                              size: 24.0,
                            ),
                            label: 'The Standing Record',
                            tone: FlutterFlowTheme.of(context).success,
                            value: '4 items built',
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).alternate,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'PER-MATTER HASH CHAIN',
                          style: FlutterFlowTheme.of(context)
                              .labelMedium
                              .override(
                                font: GoogleFonts.ibmPlexSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                                lineHeight: 1.3,
                              ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFE4EEEF),
                            borderRadius: BorderRadius.circular(50.0),
                            shape: BoxShape.rectangle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Container(
                              child: Text(
                                'entry = SHA256( prev_hash || item_hash || received_at || origin_digest )',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.spaceGrotesk(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                      lineHeight: 1.2,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            wrapWithModel(
                              model: _model.hashRowModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: HashRowWidget(
                                hash:
                                    '5d8dd7378ced61bf0fe1e3f570094c80ac89d09ce99fab2eaac5636c78b49155',
                                index: '1',
                              ),
                            ),
                            wrapWithModel(
                              model: _model.hashRowModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: HashRowWidget(
                                hash:
                                    '65c3ec5933b2e285e874bda5849861d7cfd5b24142cfacd217b24360f1fb0456',
                                index: '2',
                              ),
                            ),
                            wrapWithModel(
                              model: _model.hashRowModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: HashRowWidget(
                                hash:
                                    '46021ae74f588206d7f6e18e49edfe2d7374bafbf1d8b19455f0be4e2cf86bad',
                                index: '3',
                              ),
                            ),
                            wrapWithModel(
                              model: _model.hashRowModel4,
                              updateCallback: () => safeSetState(() {}),
                              child: HashRowWidget(
                                hash:
                                    '90545124a41d32d03420892646307918b5d6d5bf3be3424a4a9613373478a476',
                                index: '4',
                              ),
                            ),
                            wrapWithModel(
                              model: _model.hashRowModel5,
                              updateCallback: () => safeSetState(() {}),
                              child: HashRowWidget(
                                hash:
                                    '25567ef5ea476c5d9f6065b3804545630041394358b1bcc6a427d3d36255ee1d',
                                index: '5',
                              ),
                            ),
                            wrapWithModel(
                              model: _model.hashRowModel6,
                              updateCallback: () => safeSetState(() {}),
                              child: HashRowWidget(
                                hash:
                                    '9640ba21bd428e01f7714dcd3ee9eac36b72ed9092854e7c4bd70bae1897981e',
                                index: '6',
                              ),
                            ),
                          ].divide(SizedBox(height: 8.0)),
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
                              'Chain head',
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.spaceGrotesk(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Text(
                              '9640ba21bd428e01f7714dcd3ee9eac36b72ed9092854e7c4bd70bae1897981e',
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.spaceGrotesk(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                          ].divide(SizedBox(width: 16.0)),
                        ),
                      ].divide(SizedBox(height: 24.0)),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  wrapWithModel(
                    model: _model.buttonModel1,
                    updateCallback: () => safeSetState(() {}),
                    child: Button19Widget(
                      icon: Icon(
                        Icons.description_rounded,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                      iconPresent: true,
                      iconEndPresent: false,
                      content: 'Certificate of preparation',
                      variant: 'primary',
                      size: 'large',
                      fullWidth: false,
                      loading: false,
                      disabled: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.buttonModel2,
                    updateCallback: () => safeSetState(() {}),
                    child: Button19Widget(
                      icon: Icon(
                        Icons.verified_rounded,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                      iconPresent: true,
                      iconEndPresent: false,
                      content: 'Standalone verify tool',
                      variant: 'outline',
                      size: 'large',
                      fullWidth: false,
                      loading: false,
                      disabled: false,
                    ),
                  ),
                ].divide(SizedBox(width: 16.0)),
              ),
              Text(
                'Verin does not practice law. No opinion on authenticity, completeness, or admissibility is offered or implied — those determinations belong to counsel and the Court.',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).accent3,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      lineHeight: 1.5,
                    ),
              ),
            ].divide(SizedBox(height: 32.0)),
          ),
        ),
      ),
    );
  }
}
