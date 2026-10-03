import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'status_badge22_model.dart';
export 'status_badge22_model.dart';

class StatusBadge22Widget extends StatefulWidget {
  const StatusBadge22Widget({
    super.key,
    this.bgColor,
    String? label,
    Color? textColor,
  })  : this.label = label ?? 'Text',
        this.textColor = textColor ?? const Color(0x00000000);

  final Color? bgColor;
  final String label;
  final Color textColor;

  @override
  State<StatusBadge22Widget> createState() => _StatusBadge22WidgetState();
}

class _StatusBadge22WidgetState extends State<StatusBadge22Widget> {
  late StatusBadge22Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StatusBadge22Model());

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
      decoration: BoxDecoration(
        color: Color(0xFFE4EEEF),
        borderRadius: BorderRadius.circular(25.0),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
        child: Container(
          child: Text(
            valueOrDefault<String>(
              widget.label,
              'Text',
            ),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: valueOrDefault<Color>(
                    widget.textColor,
                    FlutterFlowTheme.of(context).secondaryText,
                  ),
                  fontSize: 10.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  lineHeight: 1.5,
                ),
          ),
        ),
      ),
    );
  }
}
