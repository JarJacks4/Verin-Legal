import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nav_item22_model.dart';
export 'nav_item22_model.dart';

class NavItem22Widget extends StatefulWidget {
  const NavItem22Widget({
    super.key,
    this.icon,
    String? label,
    bool? active,
  })  : this.label = label ?? 'Matters',
        this.active = active ?? false;

  final Widget? icon;
  final String label;
  final bool active;

  @override
  State<NavItem22Widget> createState() => _NavItem22WidgetState();
}

class _NavItem22WidgetState extends State<NavItem22Widget> {
  late NavItem22Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NavItem22Model());

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
          valueOrDefault<bool>(
            widget.active,
            false,
          )
              ? Color(0x141A2B3C)
              : Colors.transparent,
          Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(6.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Color(0x3B2D5A5E),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              widget.icon!,
              Text(
                valueOrDefault<String>(
                  widget.label,
                  'Matters',
                ),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: valueOrDefault<Color>(
                        valueOrDefault<bool>(
                          widget.active,
                          false,
                        )
                            ? FlutterFlowTheme.of(context).primaryText
                            : FlutterFlowTheme.of(context).secondary,
                        FlutterFlowTheme.of(context).secondaryText,
                      ),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      lineHeight: 1.5,
                    ),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}
