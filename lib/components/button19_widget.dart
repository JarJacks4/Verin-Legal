import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'button19_model.dart';
export 'button19_model.dart';

class Button19Widget extends StatefulWidget {
  const Button19Widget({
    super.key,
    this.icon,
    bool? iconPresent,
    this.iconEnd,
    bool? iconEndPresent,
    String? content,
    String? variant,
    String? size,
    bool? fullWidth,
    bool? loading,
    bool? disabled,
  })  : this.iconPresent = iconPresent ?? true,
        this.iconEndPresent = iconEndPresent ?? false,
        this.content = content ?? 'New Matter',
        this.variant = variant ?? 'primary',
        this.size = size ?? 'large',
        this.fullWidth = fullWidth ?? false,
        this.loading = loading ?? false,
        this.disabled = disabled ?? false;

  final Widget? icon;
  final bool iconPresent;
  final Widget? iconEnd;
  final bool iconEndPresent;
  final String content;
  final String variant;
  final String size;
  final bool fullWidth;
  final bool loading;
  final bool disabled;

  @override
  State<Button19Widget> createState() => _Button19WidgetState();
}

class _Button19WidgetState extends State<Button19Widget> {
  late Button19Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Button19Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: valueOrDefault<double>(
        valueOrDefault<bool>(
          widget.disabled,
          false,
        )
            ? 0.55
            : 1.0,
        1.0,
      ),
      child: Container(
        width: 380.0,
        height: 46.5,
        decoration: BoxDecoration(
          color: Color(0xFF0E6E7D),
          borderRadius: BorderRadius.circular(50.0),
          shape: BoxShape.rectangle,
          border: Border.all(
            color: valueOrDefault<Color>(
              valueOrDefault<String>(
                        widget.variant,
                        'primary',
                      ) ==
                      'outline'
                  ? FlutterFlowTheme.of(context).alternate
                  : Colors.transparent,
              Colors.transparent,
            ),
            width: valueOrDefault<double>(
              valueOrDefault<String>(
                        widget.variant,
                        'primary',
                      ) ==
                      'outline'
                  ? 1.0
                  : 0.0,
              0.0,
            ),
          ),
        ),
        child: Stack(
          alignment: AlignmentDirectional(0.0, 0.0),
          children: [
            Opacity(
              opacity: valueOrDefault<double>(
                valueOrDefault<bool>(
                  widget.loading,
                  false,
                )
                    ? 0.0
                    : 1.0,
                1.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: (FFMainAxisAlignment.start).flutterValue,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    valueOrDefault<String>(
                      widget.content,
                      'New Matter',
                    ),
                    maxLines: 1,
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.ibmPlexSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          color: valueOrDefault<Color>(
                            () {
                              if (valueOrDefault<String>(
                                    widget.variant,
                                    'primary',
                                  ) ==
                                  'secondary') {
                                return Colors.white;
                              } else if (valueOrDefault<String>(
                                    widget.variant,
                                    'primary',
                                  ) ==
                                  'outline') {
                                return FlutterFlowTheme.of(context).primaryText;
                              } else if (valueOrDefault<String>(
                                    widget.variant,
                                    'primary',
                                  ) ==
                                  'ghost') {
                                return FlutterFlowTheme.of(context).primary;
                              } else if (valueOrDefault<String>(
                                    widget.variant,
                                    'primary',
                                  ) ==
                                  'destructive') {
                                return Colors.white;
                              } else {
                                return Colors.white;
                              }
                            }(),
                            Colors.white,
                          ),
                          fontSize: 15.0,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                          lineHeight: 1.3,
                        ),
                    overflow: TextOverflow.clip,
                  ),
                  if (valueOrDefault<bool>(
                    widget.iconEndPresent,
                    false,
                  ))
                    widget.iconEnd!,
                  if (valueOrDefault<bool>(
                    widget.iconPresent,
                    true,
                  ))
                    widget.icon!,
                ].divide(SizedBox(width: 8.0)),
              ),
            ),
            if (valueOrDefault<bool>(
              valueOrDefault<bool>(
                widget.loading,
                false,
              )
                  ? true
                  : false,
              false,
            ))
              CircularPercentIndicator(
                percent: 0.0,
                radius: 7.0,
                lineWidth: 2.0,
                animation: true,
                animateFromLastPercent: true,
                progressColor: valueOrDefault<Color>(
                  () {
                    if (valueOrDefault<String>(
                          widget.variant,
                          'primary',
                        ) ==
                        'secondary') {
                      return Colors.white;
                    } else if (valueOrDefault<String>(
                          widget.variant,
                          'primary',
                        ) ==
                        'outline') {
                      return FlutterFlowTheme.of(context).primaryText;
                    } else if (valueOrDefault<String>(
                          widget.variant,
                          'primary',
                        ) ==
                        'ghost') {
                      return FlutterFlowTheme.of(context).primary;
                    } else if (valueOrDefault<String>(
                          widget.variant,
                          'primary',
                        ) ==
                        'destructive') {
                      return Colors.white;
                    } else {
                      return Colors.white;
                    }
                  }(),
                  Colors.white,
                ),
                backgroundColor: FlutterFlowTheme.of(context).alternate,
              ),
          ],
        ),
      ),
    );
  }
}
