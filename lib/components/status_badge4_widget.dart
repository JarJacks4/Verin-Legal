import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'status_badge4_model.dart';
export 'status_badge4_model.dart';

class StatusBadge4Widget extends StatefulWidget {
  const StatusBadge4Widget({
    super.key,
    String? bgColor,
    String? label,
    Color? textColor,
  })  : this.bgColor = bgColor ?? 'primary',
        this.label = label ?? 'SlotValue(\$status)',
        this.textColor = textColor ?? const Color(0x00000000);

  final String bgColor;
  final String label;
  final Color textColor;

  @override
  State<StatusBadge4Widget> createState() => _StatusBadge4WidgetState();
}

class _StatusBadge4WidgetState extends State<StatusBadge4Widget> {
  late StatusBadge4Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StatusBadge4Model());

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
        color: FlutterFlowTheme.of(context).primary,
        borderRadius: BorderRadius.circular(2.0),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
        child: Container(
          child: Text(
            valueOrDefault<String>(
              widget.label,
              'SlotValue(\$status)',
            ),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: valueOrDefault<Color>(
                    widget.textColor,
                    Color(0x00000000),
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
