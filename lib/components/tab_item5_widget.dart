import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tab_item5_model.dart';
export 'tab_item5_model.dart';

class TabItem5Widget extends StatefulWidget {
  const TabItem5Widget({
    super.key,
    String? label,
    bool? selected,
  })  : this.label = label ?? 'Intake channel',
        this.selected = selected ?? false;

  final String label;
  final bool selected;

  @override
  State<TabItem5Widget> createState() => _TabItem5WidgetState();
}

class _TabItem5WidgetState extends State<TabItem5Widget> {
  late TabItem5Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TabItem5Model());

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
            widget.selected,
            false,
          )
              ? Color(0x332D5A5E)
              : Colors.transparent,
          Colors.transparent,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              false,
            )
                ? 4.0
                : 6.0,
            6.0,
          )),
          topRight: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              false,
            )
                ? 4.0
                : 6.0,
            6.0,
          )),
          bottomLeft: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              false,
            )
                ? 4.0
                : 6.0,
            6.0,
          )),
          bottomRight: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              false,
            )
                ? 4.0
                : 6.0,
            6.0,
          )),
        ),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
        child: Container(
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Text(
              valueOrDefault<String>(
                widget.label,
                'Intake channel',
              ),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.ibmPlexSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                    color: valueOrDefault<Color>(
                      valueOrDefault<bool>(
                        widget.selected,
                        false,
                      )
                          ? Color(0xFF1A1A1A)
                          : FlutterFlowTheme.of(context).secondaryText,
                      FlutterFlowTheme.of(context).secondaryText,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    lineHeight: 1.3,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
