import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tab_item3_model.dart';
export 'tab_item3_model.dart';

class TabItem3Widget extends StatefulWidget {
  const TabItem3Widget({
    super.key,
    String? label,
    bool? selected,
  })  : this.label = label ?? 'SlotValue(\$label_1)',
        this.selected = selected ?? true;

  final String label;
  final bool selected;

  @override
  State<TabItem3Widget> createState() => _TabItem3WidgetState();
}

class _TabItem3WidgetState extends State<TabItem3Widget> {
  late TabItem3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TabItem3Model());

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
            true,
          )
              ? FlutterFlowTheme.of(context).secondary20
              : Colors.transparent,
          FlutterFlowTheme.of(context).secondary20,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              true,
            )
                ? 4.0
                : 6.0,
            4.0,
          )),
          topRight: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              true,
            )
                ? 4.0
                : 6.0,
            4.0,
          )),
          bottomLeft: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              true,
            )
                ? 4.0
                : 6.0,
            4.0,
          )),
          bottomRight: Radius.circular(valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.selected,
              true,
            )
                ? 4.0
                : 6.0,
            4.0,
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
                'SlotValue(\$label_1)',
              ),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                    color: valueOrDefault<Color>(
                      valueOrDefault<bool>(
                        widget.selected,
                        true,
                      )
                          ? FlutterFlowTheme.of(context).onSurface
                          : FlutterFlowTheme.of(context).secondaryText,
                      FlutterFlowTheme.of(context).onSurface,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
