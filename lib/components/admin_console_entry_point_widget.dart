import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_console_entry_point_model.dart';
export 'admin_console_entry_point_model.dart';

/// A sidebar navigation item labeled "Admin console", styled like the other
/// sidebar items but with a small pill badge next to the label reading
/// "Annual" in a muted gold/amber tone.
///
/// Clicking it is a mode switch, not a
/// page navigation — the whole screen changes to a different sidebar color.
class AdminConsoleEntryPointWidget extends StatefulWidget {
  const AdminConsoleEntryPointWidget({
    super.key,
    bool? selected,
    this.icon,
    String? label,
    String? badgeText,
    bool? isAdminMode,
  })  : this.selected = selected ?? false,
        this.label = label ?? '',
        this.badgeText = badgeText ?? '',
        this.isAdminMode = isAdminMode ?? false;

  final bool selected;
  final Widget? icon;
  final String label;
  final String badgeText;
  final bool isAdminMode;

  @override
  State<AdminConsoleEntryPointWidget> createState() =>
      _AdminConsoleEntryPointWidgetState();
}

class _AdminConsoleEntryPointWidgetState
    extends State<AdminConsoleEntryPointWidget> {
  late AdminConsoleEntryPointModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminConsoleEntryPointModel());

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
      width: 703.6,
      height: 71.31,
      decoration: BoxDecoration(),
      child: Container(
        decoration: BoxDecoration(
          color: valueOrDefault<Color>(
            valueOrDefault<bool>(
              widget.selected,
              false,
            )
                ? FlutterFlowTheme.of(context).primary10
                : Colors.transparent,
            Color(0x00000000),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 40.0,
              color: Color(0xC4E2E0DB),
              offset: Offset(
                0.0,
                0.0,
              ),
            )
          ],
          borderRadius: BorderRadius.circular(25.0),
          shape: BoxShape.rectangle,
          border: Border.all(
            color: Color(0x2CE2E0DB),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
          child: Container(
            decoration: BoxDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.icon!,
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.ibmPlexSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                              color: valueOrDefault<Color>(
                                valueOrDefault<bool>(
                                  widget.selected,
                                  false,
                                )
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context).primaryText,
                                Color(0x00000000),
                              ),
                              fontSize: 14.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9999.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              2.0, 4.0, 2.0, 4.0),
                          child: Container(
                            child: Text(
                              widget.badgeText,
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).warning,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 4.0)),
                  ),
                ),
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).tertiary,
                    borderRadius: BorderRadius.circular(9999.0),
                    shape: BoxShape.rectangle,
                  ),
                ),
              ].divide(SizedBox(width: 16.0)),
            ),
          ),
        ),
      ),
    );
  }
}
