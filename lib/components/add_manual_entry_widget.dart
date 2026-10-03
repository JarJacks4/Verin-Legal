import '/components/text_field9_widget.dart';
import '/components/upload_dropzone_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_manual_entry_model.dart';
export 'add_manual_entry_model.dart';

/// Build exactly what is described below and nothing more.
///
/// Do not add,
/// substitute, or invent any element, section, icon, label, field, or piece
/// of content beyond what is explicitly listed here.
///
/// A bottom sheet titled "Add Manual Entry".
///
/// Top row: 5 equally-sized clickable tiles — Photo, Video, Document, Email,
/// Physical — each with a representative icon above its label. One tile
/// shown selected with teal fill and white text/icon; the others outlined
/// gray.
///
/// Below the tiles, an upload zone with a dashed border, upload icon, and
/// hint text "Images (JPG, PNG, HEIC)".
///
/// Below the upload zone, a staged-files list: each file as a horizontal row
/// with a small thumbnail on the left, filename and size in the middle, and a
/// trash icon on the right. A text button "Add more files" below the list.
///
/// Below the list, exactly these metadata fields and no others: Source, "How
/// was it received", Date received, Description, and Chain of custody notes.
///
/// Nothing else belongs on this sheet.
class AddManualEntryWidget extends StatefulWidget {
  const AddManualEntryWidget({super.key});

  @override
  State<AddManualEntryWidget> createState() => _AddManualEntryWidgetState();
}

class _AddManualEntryWidgetState extends State<AddManualEntryWidget> {
  late AddManualEntryModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddManualEntryModel());

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
        width: 640.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
          shape: BoxShape.rectangle,
        ),
        child: Container(
          width: 100.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(),
              child: SingleChildScrollView(
                primary: false,
                controller: _model.columnScrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Manual Entry',
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                            font: GoogleFonts.ibmPlexSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .titleLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleLarge
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondary,
                              borderRadius: BorderRadius.circular(6.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).secondary,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_camera_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .onSecondary,
                                      size: 24.0,
                                    ),
                                    Text(
                                      'Photo',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.spaceGrotesk(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .onSecondary,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(6.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: Color(0xFFD1D5DB),
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      'Video',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.spaceGrotesk(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(6.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: Color(0xFFD1D5DB),
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      'Document',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.spaceGrotesk(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(6.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: Color(0xFFD1D5DB),
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      'Email',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.spaceGrotesk(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(6.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: Color(0xFFD1D5DB),
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      'Physical',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.spaceGrotesk(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ].divide(SizedBox(width: 8.0)),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        wrapWithModel(
                          model: _model.textFieldModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField9Widget(
                            label: 'Source',
                            labelPresent: true,
                            helper: '',
                            helperPresent: false,
                            leadingIconPresent: false,
                            trailingIconPresent: false,
                            hint: 'Enter source name',
                            value: '',
                            onChange: '',
                            onSubmit: '',
                            variant: 'outlined',
                            error: false,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.textFieldModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField9Widget(
                            label: 'How was it received',
                            labelPresent: true,
                            helper: '',
                            helperPresent: false,
                            leadingIconPresent: false,
                            trailingIconPresent: false,
                            hint: 'e.g. Hand-delivered, Email',
                            value: '',
                            onChange: '',
                            onSubmit: '',
                            variant: 'outlined',
                            error: false,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.textFieldModel3,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField9Widget(
                            label: 'Date received',
                            labelPresent: true,
                            helper: '',
                            helperPresent: false,
                            leadingIcon: Icon(
                              Icons.calendar_today_rounded,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            leadingIconPresent: true,
                            trailingIconPresent: false,
                            hint: 'YYYY-MM-DD',
                            value: '',
                            onChange: '',
                            onSubmit: '',
                            variant: 'outlined',
                            error: false,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.textFieldModel4,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField9Widget(
                            label: 'Description',
                            labelPresent: true,
                            helper: '',
                            helperPresent: false,
                            leadingIconPresent: false,
                            trailingIconPresent: false,
                            hint: 'Brief summary of the entry',
                            value: '',
                            onChange: '',
                            onSubmit: '',
                            variant: 'outlined',
                            error: false,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.textFieldModel5,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField9Widget(
                            label: 'Chain of custody notes',
                            labelPresent: true,
                            helper: '',
                            helperPresent: false,
                            leadingIconPresent: false,
                            trailingIconPresent: false,
                            hint: 'Log of possession and handling',
                            value: '',
                            onChange: '',
                            onSubmit: '',
                            variant: 'outlined',
                            error: false,
                          ),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                    wrapWithModel(
                      model: _model.uploadDropzoneModel,
                      updateCallback: () => safeSetState(() {}),
                      child: UploadDropzoneWidget(
                        formats: 'JPG, PNG, HEIC, MP4, MOV',
                        label: 'Drop photos & videos here',
                      ),
                    ),
                    Container(
                      width: 100.0,
                      height: 127.2,
                      decoration: BoxDecoration(
                        color: Color(0x87E2E0DB),
                        borderRadius: BorderRadius.circular(35.0),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment:
                              (FFMainAxisAlignment.end).flutterValue,
                          children: [
                            Align(
                              alignment: AlignmentDirectional(-1.0, -1.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    15.0, 0.0, 0.0, 0.0),
                                child: Icon(
                                  Icons.warning_amber,
                                  color: FlutterFlowTheme.of(context).warning,
                                  size: 24.0,
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, -1.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    50.0, 0.0, 20.0, 25.0),
                                child: Text(
                                  'Manual entries are stamped with current server time. \nThe date you enter is stored as metadata and is not cryptographically anchored to the timestamp.',
                                  textAlign: TextAlign.start,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.ibmPlexSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .warning,
                                        fontSize: 18.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: () {
                        print('Button pressed ...');
                      },
                      text: 'Add to Record',
                      icon: FaIcon(
                        FontAwesomeIcons.solidEdit,
                        size: 15.0,
                      ),
                      options: FFButtonOptions(
                        height: 57.6,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: Color(0xFF0E6E7D),
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.ibmPlexSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                  ].divide(SizedBox(height: 24.0)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
