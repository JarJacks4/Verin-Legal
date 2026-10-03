import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sidebar_nav_item_model.dart';
export 'sidebar_nav_item_model.dart';

class SidebarNavItemWidget extends StatefulWidget {
  const SidebarNavItemWidget({
    super.key,
    bool? selected,
    this.icon,
    String? label,
  })  : this.selected = selected ?? true,
        this.label = label ?? 'Dashboard';

  final bool selected;
  final Widget? icon;
  final String label;

  @override
  State<SidebarNavItemWidget> createState() => _SidebarNavItemWidgetState();
}

class _SidebarNavItemWidgetState extends State<SidebarNavItemWidget> {
  late SidebarNavItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SidebarNavItemModel());

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
      width: 228.0,
      height: 54.23,
      decoration: BoxDecoration(
        color: valueOrDefault<Color>(
          valueOrDefault<bool>(
            widget.selected,
            true,
          )
              ? Color(0x26FFFFFF)
              : Colors.transparent,
          Color(0x26FFFFFF),
        ),
        borderRadius: BorderRadius.circular(25.0),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 8.0, 16.0),
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: (FFMainAxisAlignment.start).flutterValue,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: valueOrDefault<double>(
                  valueOrDefault<bool>(
                    widget.selected,
                    true,
                  )
                      ? 1.0
                      : 0.7,
                  1.0,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 8.0, 0.0),
                  child: widget.icon!,
                ),
              ),
              Opacity(
                opacity: valueOrDefault<double>(
                  valueOrDefault<bool>(
                    widget.selected,
                    true,
                  )
                      ? 1.0
                      : 0.7,
                  1.0,
                ),
                child: Text(
                  valueOrDefault<String>(
                    widget.label,
                    'Dashboard',
                  ),
                  style: FlutterFlowTheme.of(context).labelLarge.override(
                        font: GoogleFonts.ibmPlexSans(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelLarge
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}
