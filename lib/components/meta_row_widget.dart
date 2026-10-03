import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'meta_row_model.dart';
export 'meta_row_model.dart';

class MetaRowWidget extends StatefulWidget {
  const MetaRowWidget({
    super.key,
    String? label,
    String? value,
    bool? bold,
  })  : this.label = label ?? 'Matter Name',
        this.value = value ?? 'Whitmore v. Whitmore',
        this.bold = bold ?? true;

  final String label;
  final String value;
  final bool bold;

  @override
  State<MetaRowWidget> createState() => _MetaRowWidgetState();
}

class _MetaRowWidgetState extends State<MetaRowWidget> {
  late MetaRowModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MetaRowModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              valueOrDefault<String>(
                widget.label,
                'Matter Name',
              ),
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.ibmPlexSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    lineHeight: 1.3,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              valueOrDefault<String>(
                widget.value,
                'Whitmore v. Whitmore',
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.ibmPlexSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    lineHeight: 1.5,
                  ),
            ),
          ),
        ].divide(SizedBox(width: 16.0)),
      ),
    );
  }
}
