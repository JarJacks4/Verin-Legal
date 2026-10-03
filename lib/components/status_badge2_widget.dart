import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'status_badge2_model.dart';
export 'status_badge2_model.dart';

class StatusBadge2Widget extends StatefulWidget {
  const StatusBadge2Widget({
    super.key,
    Color? bgColor,
    String? label,
    Color? textColor,
  })  : this.bgColor = bgColor ?? const Color(0x00000000),
        this.label = label ?? 'SlotValue(\$issue)',
        this.textColor = textColor ?? const Color(0x00000000);

  final Color bgColor;
  final String label;
  final Color textColor;

  @override
  State<StatusBadge2Widget> createState() => _StatusBadge2WidgetState();
}

class _StatusBadge2WidgetState extends State<StatusBadge2Widget> {
  late StatusBadge2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StatusBadge2Model());

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
        color: valueOrDefault<Color>(
          widget.bgColor,
          Color(0x00000000),
        ),
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(10.0, 4.0, 10.0, 4.0),
        child: Container(
          child: Text(
            valueOrDefault<String>(
              widget.label,
              'SlotValue(\$issue)',
            ),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: valueOrDefault<Color>(
                    widget.textColor,
                    Color(0x00000000),
                  ),
                  fontSize: 11.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  lineHeight: 1.5,
                ),
          ),
        ),
      ),
    );
  }
}
