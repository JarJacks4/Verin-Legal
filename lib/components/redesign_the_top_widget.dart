import '/components/button10_widget.dart';
import '/components/text_field6_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'redesign_the_top_model.dart';
export 'redesign_the_top_model.dart';

/// Redesign the top of this sheet: replace the evidence-type dropdown with a
/// row of 5 equally-sized clickable tiles — Photo, Video, Document, Email,
/// Physical — each with a representative icon above its label.
///
/// The selected
/// tile has a teal fill and white text/icon; unselected tiles are outlined
/// gray.
/// Below the tiles, an upload zone (dashed border, upload icon, hint text)
/// that changes its accepted-file hint per type: "Images (JPG, PNG, HEIC)"
/// for
/// Photo, "Videos (MP4, MOV)" for Video, "PDF, Word, or text files" for
/// Document, "A single .eml or .msg file" for Email. For the Physical tile,
/// replace the upload zone entirely with a large multi-line text area labeled
/// "Description and storage location".
/// Below the upload zone (all types except Physical), a staged-files list:
/// each file as a horizontal row with a small thumbnail or type icon on the
/// left, filename and size in the middle, and a trash icon on the right. An
/// "Add more files" text button sits below the list — hidden entirely for
/// Email, which only accepts one file.
/// Below all of that, the existing metadata fields: Source, "How was it
/// received" (renamed from "Channel"), Date received, Description, and Chain
/// of custody notes.
class RedesignTheTopWidget extends StatefulWidget {
  const RedesignTheTopWidget({
    super.key,
    String? activeType,
  }) : this.activeType = activeType ?? '';

  final String activeType;

  @override
  State<RedesignTheTopWidget> createState() => _RedesignTheTopWidgetState();
}

class _RedesignTheTopWidgetState extends State<RedesignTheTopWidget> {
  late RedesignTheTopModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RedesignTheTopModel());

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
      width: MediaQuery.sizeOf(context).width * 0.3,
      height: MediaQuery.sizeOf(context).height * 1.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: (FFMainAxisAlignment.center).flutterValue,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Evidence Type Picker',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.playfairDisplaySc(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    fontSize: 22.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
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
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        widget.activeType == 'Photo'
                            ? FlutterFlowTheme.of(context).secondary
                            : Colors.transparent,
                        Color(0x00000000),
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        child: Container(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_camera_rounded,
                                color: valueOrDefault<Color>(
                                  widget.activeType == 'Photo'
                                      ? FlutterFlowTheme.of(context).onSecondary
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  Color(0x00000000),
                                ),
                                size: 24.0,
                              ),
                              Text(
                                'Photo',
                                textAlign: TextAlign.center,
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
                                      color: valueOrDefault<Color>(
                                        widget.activeType == 'Photo'
                                            ? FlutterFlowTheme.of(context)
                                                .onSecondary
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        Color(0x00000000),
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        widget.activeType == 'Video'
                            ? FlutterFlowTheme.of(context).secondary
                            : Colors.transparent,
                        Color(0x00000000),
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        child: Container(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                color: valueOrDefault<Color>(
                                  widget.activeType == 'Video'
                                      ? FlutterFlowTheme.of(context).onSecondary
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  Color(0x00000000),
                                ),
                                size: 24.0,
                              ),
                              Text(
                                'Video',
                                textAlign: TextAlign.center,
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
                                      color: valueOrDefault<Color>(
                                        widget.activeType == 'Video'
                                            ? FlutterFlowTheme.of(context)
                                                .onSecondary
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        Color(0x00000000),
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        widget.activeType == 'Document'
                            ? FlutterFlowTheme.of(context).secondary
                            : Colors.transparent,
                        Color(0x00000000),
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        child: Container(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_rounded,
                                color: valueOrDefault<Color>(
                                  widget.activeType == 'Document'
                                      ? FlutterFlowTheme.of(context).onSecondary
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  Color(0x00000000),
                                ),
                                size: 24.0,
                              ),
                              Text(
                                'Document',
                                textAlign: TextAlign.center,
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
                                      color: valueOrDefault<Color>(
                                        widget.activeType == 'Document'
                                            ? FlutterFlowTheme.of(context)
                                                .onSecondary
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        Color(0x00000000),
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        widget.activeType == 'Email'
                            ? FlutterFlowTheme.of(context).secondary
                            : Colors.transparent,
                        Color(0x00000000),
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        child: Container(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_rounded,
                                color: valueOrDefault<Color>(
                                  widget.activeType == 'Email'
                                      ? FlutterFlowTheme.of(context).onSecondary
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  Color(0x00000000),
                                ),
                                size: 24.0,
                              ),
                              Text(
                                'Email',
                                textAlign: TextAlign.center,
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
                                      color: valueOrDefault<Color>(
                                        widget.activeType == 'Email'
                                            ? FlutterFlowTheme.of(context)
                                                .onSecondary
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        Color(0x00000000),
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        widget.activeType == 'Physical'
                            ? FlutterFlowTheme.of(context).secondary
                            : Colors.transparent,
                        Color(0x00000000),
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        child: Container(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                color: valueOrDefault<Color>(
                                  widget.activeType == 'Physical'
                                      ? FlutterFlowTheme.of(context).onSecondary
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  Color(0x00000000),
                                ),
                                size: 24.0,
                              ),
                              Text(
                                'Physical',
                                textAlign: TextAlign.center,
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
                                      color: valueOrDefault<Color>(
                                        widget.activeType == 'Physical'
                                            ? FlutterFlowTheme.of(context)
                                                .onSecondary
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        Color(0x00000000),
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                ),
              ].divide(SizedBox(width: 8.0)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  child: wrapWithModel(
                    model: _model.textFieldModel1,
                    updateCallback: () => safeSetState(() {}),
                    child: TextField6Widget(
                      label: 'Description and storage location',
                      labelPresent: true,
                      helper: '',
                      helperPresent: false,
                      leadingIconPresent: false,
                      trailingIconPresent: false,
                      hint: 'Specify room, shelf, or locker ID...',
                      value: '',
                      onChange: '',
                      onSubmit: '',
                      variant: 'outlined',
                      error: false,
                    ),
                  ),
                ),
                Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Container(
                            child: Container(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_rounded,
                                    color:
                                        FlutterFlowTheme.of(context).secondary,
                                    size: 32.0,
                                  ),
                                  Text(
                                    'Tap to upload or drag and drop',
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
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  Text(
                                    valueOrDefault<String>(
                                      () {
                                        if (widget.activeType == 'Photo') {
                                          return 'Images (JPG, PNG, HEIC)';
                                        } else if (widget.activeType ==
                                            'Video') {
                                          return 'Videos (MP4, MOV)';
                                        } else if (widget.activeType ==
                                            'Document') {
                                          return 'PDF, Word, or text files';
                                        } else {
                                          return 'A single .eml or .msg file';
                                        }
                                      }(),
                                      'ComparisonConditionalValue(\$active_type == Photo ? StringValue(\"Images (JPG, PNG, HEIC)\") : ComparisonConditionalValue(\$active_type == Video ? StringValue(\"Videos (MP4, MOV)\") : ComparisonConditionalValue(\$active_type == Document ? StringValue(\"PDF, Word, or text files\") : StringValue(\"A single .eml or .msg file\"))))',
                                    ),
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
                                              .accent3,
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
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40.0,
                                      height: 40.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Container(
                                        width: 20.0,
                                        height: 20.0,
                                        child: Stack(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          children: [
                                            Icon(
                                              Icons.image_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                              size: 20.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'evidence_file_01',
                                            maxLines: 1,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.ibmPlexSans(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '2.4 MB',
                                            style: FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font:
                                                      GoogleFonts.spaceGrotesk(
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
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
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
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FlutterFlowIconButton(
                                      borderRadius: 8.0,
                                      buttonSize: 40.0,
                                      fillColor: Colors.transparent,
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        size: 20.0,
                                      ),
                                      onPressed: () {
                                        print('IconButton pressed ...');
                                      },
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 8.0)),
                      ),
                      Container(
                        child: wrapWithModel(
                          model: _model.buttonModel,
                          updateCallback: () => safeSetState(() {}),
                          child: Button10Widget(
                            icon: Icon(
                              Icons.add_rounded,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            iconPresent: true,
                            iconEndPresent: false,
                            content: 'Add more files',
                            variant: 'ghost',
                            size: 'small',
                            fullWidth: false,
                            loading: false,
                            disabled: false,
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ),
              ].divide(SizedBox(height: 16.0)),
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
                        model: _model.textFieldModel2,
                        updateCallback: () => safeSetState(() {}),
                        child: TextField6Widget(
                          label: 'Source',
                          labelPresent: true,
                          helper: '',
                          helperPresent: false,
                          leadingIconPresent: false,
                          trailingIconPresent: false,
                          hint: 'e.g. Officer Smith',
                          value: '',
                          onChange: '',
                          onSubmit: '',
                          variant: 'outlined',
                          error: false,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: wrapWithModel(
                        model: _model.textFieldModel3,
                        updateCallback: () => safeSetState(() {}),
                        child: TextField6Widget(
                          label: 'How was it received',
                          labelPresent: true,
                          helper: '',
                          helperPresent: false,
                          leadingIconPresent: false,
                          trailingIconPresent: false,
                          hint: 'e.g. Hand-delivered',
                          value: '',
                          onChange: '',
                          onSubmit: '',
                          variant: 'outlined',
                          error: false,
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
                        model: _model.textFieldModel4,
                        updateCallback: () => safeSetState(() {}),
                        child: TextField6Widget(
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
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
                wrapWithModel(
                  model: _model.textFieldModel5,
                  updateCallback: () => safeSetState(() {}),
                  child: TextField6Widget(
                    label: 'Description',
                    labelPresent: true,
                    helper: '',
                    helperPresent: false,
                    leadingIconPresent: false,
                    trailingIconPresent: false,
                    hint: 'Brief summary of the evidence content',
                    value: '',
                    onChange: '',
                    onSubmit: '',
                    variant: 'outlined',
                    error: false,
                  ),
                ),
                wrapWithModel(
                  model: _model.textFieldModel6,
                  updateCallback: () => safeSetState(() {}),
                  child: TextField6Widget(
                    label: 'Chain of custody notes',
                    labelPresent: true,
                    helper: '',
                    helperPresent: false,
                    leadingIconPresent: false,
                    trailingIconPresent: false,
                    hint: 'Initial handling details...',
                    value: '',
                    onChange: '',
                    onSubmit: '',
                    variant: 'outlined',
                    error: false,
                  ),
                ),
              ].divide(SizedBox(height: 16.0)),
            ),
          ].divide(SizedBox(height: 24.0)),
        ),
      ),
    );
  }
}
