import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'archive_file_model.dart';
export 'archive_file_model.dart';

class ArchiveFileWidget extends StatefulWidget {
  const ArchiveFileWidget({
    super.key,
    String? meta,
    String? name,
    bool? isFolder,
  })  : this.meta = meta ?? 'Hash chain + receipt metadata',
        this.name = name ?? 'manifest.json',
        this.isFolder = isFolder ?? false;

  final String meta;
  final String name;
  final bool isFolder;

  @override
  State<ArchiveFileWidget> createState() => _ArchiveFileWidgetState();
}

class _ArchiveFileWidgetState extends State<ArchiveFileWidget> {
  late ArchiveFileModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ArchiveFileModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 14.0,
          height: 14.0,
          child: Stack(
            alignment: AlignmentDirectional(0.0, 0.0),
            children: [
              if (valueOrDefault<bool>(
                valueOrDefault<bool>(
                  widget.isFolder,
                  false,
                )
                    ? true
                    : false,
                false,
              ))
                Icon(
                  Icons.folder_open_rounded,
                  color: Color(0x992D5A5E),
                  size: 14.0,
                ),
              if (valueOrDefault<bool>(
                valueOrDefault<bool>(
                  widget.isFolder,
                  false,
                )
                    ? false
                    : true,
                true,
              ))
                Icon(
                  Icons.description_rounded,
                  color: Color(0x992D5A5E),
                  size: 14.0,
                ),
            ],
          ),
        ),
        Text(
          valueOrDefault<String>(
            widget.name,
            'manifest.json',
          ),
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.spaceGrotesk(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondary,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                lineHeight: 1.2,
              ),
        ),
        Text(
          valueOrDefault<String>(
            widget.meta,
            'Hash chain + receipt metadata',
          ),
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.spaceGrotesk(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                lineHeight: 1.2,
              ),
        ),
      ].divide(SizedBox(width: 8.0)),
    );
  }
}
