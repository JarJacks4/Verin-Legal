import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nav_item7_model.dart';
export 'nav_item7_model.dart';

class NavItem7Widget extends StatefulWidget {
  const NavItem7Widget({
    super.key,
    String? label,
    this.icon,
    String? target,
    bool? selected,
  })  : this.label = label ?? 'Dashboard',
        this.target = target ?? 'dashboard',
        this.selected = selected ?? false;

  final String label;
  final Widget? icon;
  final String target;
  final bool selected;

  @override
  State<NavItem7Widget> createState() => _NavItem7WidgetState();
}

class _NavItem7WidgetState extends State<NavItem7Widget> {
  late NavItem7Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NavItem7Model());

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
      padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.icon!,
          Text(
            valueOrDefault<String>(
              widget.label,
              'Dashboard',
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
                      widget.selected,
                      false,
                    )
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).secondaryText,
                    FlutterFlowTheme.of(context).secondaryText,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  lineHeight: 1.4,
                ),
          ),
        ].divide(SizedBox(height: 2.0)),
      ),
    );
  }
}
