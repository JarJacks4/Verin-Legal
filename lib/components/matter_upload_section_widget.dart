import '/components/button2_widget.dart';
import '/components/tab_group_widget.dart';
import '/components/text_field2_widget.dart';
import '/components/upload_dropzone_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'matter_upload_section_model.dart';
export 'matter_upload_section_model.dart';

/// Add a media upload section to this form, below the existing fields, styled
/// consistently with the rest of the drawer (same card background, same
/// spacing rhythm as other sections).
///
/// Drop zone: a rectangular tile with a dashed border, rounded corners,
/// centered upload-cloud icon, and text "Click to upload or drag files here"
/// /
/// "Photos and videos" in muted gray beneath it.
///
/// Staged file grid: below the drop zone, a 3-column grid of square thumbnail
/// tiles (only appears once at least one file is staged — hidden entirely
/// before that). Each tile: rounded corners, light gray background. An image
/// file shows an actual photo thumbnail filling the tile. A video file shows
/// a
/// centered film-strip icon with the filename in small text beneath it. Each
/// tile has a small pill badge in the top-left corner reading "Photo" or
/// "Video" (teal for photo, navy for video), and a small circular trash-can
/// button in the top-right corner that only appears on hover.
///
/// Add-more tile: the last cell in the grid is always a dashed-border square
/// with a centered "+" icon, same visual weight as the drop zone but smaller.
///
/// Below the grid, one line of small muted gray text: "[N] files staged ·
/// each
/// will be SHA-256 hashed at intake" — this text only appears once files are
/// staged.
///
/// Do not build any upload logic, file handling, or data bindings — this is
/// layout and static appearance only.
class MatterUploadSectionWidget extends StatefulWidget {
  const MatterUploadSectionWidget({
    super.key,
    String? fileCount,
  }) : this.fileCount = fileCount ?? '';

  final String fileCount;

  @override
  State<MatterUploadSectionWidget> createState() =>
      _MatterUploadSectionWidgetState();
}

class _MatterUploadSectionWidgetState extends State<MatterUploadSectionWidget> {
  late MatterUploadSectionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MatterUploadSectionModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(1.0, -1.0),
      child: Container(
        width: 477.6,
        height: 904.8,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
        child: Visibility(
          visible: responsiveVisibility(
            context: context,
            phone: false,
            tablet: false,
            tabletLandscape: false,
          ),
          child: Container(
            width: 100.0,
            height: 648.8,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 16.0),
                    child: Container(
                      child: Text(
                        'New Matter',
                        style: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .override(
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
                              lineHeight: 1.4,
                            ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    child: SingleChildScrollView(
                      primary: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: _model.columnScrollController1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  24.0, 0.0, 24.0, 0.0),
                              child: Container(
                                decoration: BoxDecoration(),
                                child: SingleChildScrollView(
                                  primary: false,
                                  controller: _model.columnScrollController2,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: wrapWithModel(
                                          model: _model.textFieldModel1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: TextField2Widget(
                                            label: 'Client Name',
                                            labelPresent: true,
                                            helper: '',
                                            helperPresent: false,
                                            leadingIconPresent: false,
                                            trailingIconPresent: false,
                                            hint: 'Elena Whitmore',
                                            value: '',
                                            onChange: '',
                                            onSubmit: '',
                                            variant: 'outlined',
                                            error: false,
                                          ),
                                        ),
                                      ),
                                      wrapWithModel(
                                        model: _model.textFieldModel2,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: TextField2Widget(
                                          label: 'Matter Name',
                                          labelPresent: true,
                                          helper: '',
                                          helperPresent: false,
                                          leadingIconPresent: false,
                                          trailingIconPresent: false,
                                          hint: 'Whitmore v. Whitmore',
                                          value: '',
                                          onChange: '',
                                          onSubmit: '',
                                          variant: 'outlined',
                                          error: false,
                                        ),
                                      ),
                                      wrapWithModel(
                                        model: _model.textFieldModel3,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: TextField2Widget(
                                          label: 'Case Number',
                                          labelPresent: true,
                                          helper: '',
                                          helperPresent: false,
                                          leadingIconPresent: false,
                                          trailingIconPresent: false,
                                          hint: '49D08-2404-DR-014922',
                                          value: '',
                                          onChange: '',
                                          onSubmit: '',
                                          variant: 'outlined',
                                          error: false,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Matter Type',
                                            style: FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .override(
                                                  font: GoogleFonts.ibmPlexSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                          FlutterFlowDropDown<String>(
                                            controller: _model
                                                    .dropdownValueController ??=
                                                FormFieldController<String>(
                                              _model.dropdownValue ??=
                                                  'Family Law',
                                            ),
                                            options: [
                                              'Family Law',
                                              'Criminal Defense',
                                              'Corporate',
                                              'Real Estate',
                                              'Estate Planning'
                                            ],
                                            onChanged: (val) => safeSetState(
                                                () =>
                                                    _model.dropdownValue = val),
                                            width: 200.0,
                                            height: 40.0,
                                            textStyle: FlutterFlowTheme.of(
                                                    context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.ibmPlexSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                            hintText: 'Family Law',
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 24.0,
                                            ),
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            elevation: 2.0,
                                            borderColor:
                                                FlutterFlowTheme.of(context)
                                                    .alternate,
                                            borderWidth: 1.0,
                                            borderRadius: 8.0,
                                            margin:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            hidesUnderline: true,
                                            isOverButton: false,
                                            isSearchable: false,
                                            isMultiSelect: false,
                                          ),
                                        ].divide(SizedBox(height: 4.0)),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Status',
                                            style: FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .override(
                                                  font: GoogleFonts.ibmPlexSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                          wrapWithModel(
                                            model: _model.tabGroupModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: TabGroupWidget(
                                              label2: 'Pending',
                                              label2Present: true,
                                              label3: 'Closed',
                                              label3Present: true,
                                              label4: '',
                                              label4Present: false,
                                              label5: '',
                                              label5Present: false,
                                              label1: 'Open',
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 4.0)),
                                      ),
                                      wrapWithModel(
                                        model: _model.uploadDropzoneModel,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: UploadDropzoneWidget(
                                          formats: 'JPG, PNG, HEIC, MP4, MOV',
                                          label: 'Drop photos & videos here',
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          wrapWithModel(
                                            model: _model.buttonModel1,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: Button2Widget(
                                              iconPresent: false,
                                              iconEndPresent: false,
                                              content: 'Create Matter',
                                              variant: 'primary',
                                              size: 'large',
                                              fullWidth: true,
                                              loading: false,
                                              disabled: false,
                                            ),
                                          ),
                                          wrapWithModel(
                                            model: _model.buttonModel2,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: Button2Widget(
                                              iconPresent: false,
                                              iconEndPresent: false,
                                              content: 'Cancel',
                                              variant: 'ghost',
                                              size: 'medium',
                                              fullWidth: false,
                                              loading: false,
                                              disabled: false,
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 16.0)),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  valueOrDefault<String>(
                                                    ' files staged — each will be SHA-256 hashed at intake',
                                                    ' files staged — each will be SHA-256 hashed at intake',
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodySmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .ibmPlexSans(
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
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .accent3,
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
                                                        lineHeight: 1.4,
                                                      ),
                                                ),
                                              ].divide(SizedBox(height: 16.0)),
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 16.0)),
                                      ),
                                    ].divide(SizedBox(height: 24.0)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: (FFMainAxisAlignment.end).flutterValue,
                    crossAxisAlignment:
                        (FFCrossAxisAlignment.center).flutterValue,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary5,
                          borderRadius: BorderRadius.circular(8.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).primary10,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 18.0,
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'A unique email, SMS, and WhatsApp intake address will be generated automatically for this matter once created',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.ibmPlexSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
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
        ),
      ),
    );
  }
}
