import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'button22_model.dart';
export 'button22_model.dart';

class Button22Widget extends StatefulWidget {
  const Button22Widget({
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
        this.content = content ?? 'Sign out',
        this.variant = variant ?? 'destructive',
        this.size = size ?? 'medium',
        this.fullWidth = fullWidth ?? true,
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
  State<Button22Widget> createState() => _Button22WidgetState();
}

class _Button22WidgetState extends State<Button22Widget> {
  late Button22Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Button22Model());

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
        decoration: BoxDecoration(
          color: valueOrDefault<Color>(
            () {
              if (valueOrDefault<String>(
                    widget.variant,
                    'destructive',
                  ) ==
                  'secondary') {
                return FlutterFlowTheme.of(context).secondary;
              } else if (valueOrDefault<String>(
                    widget.variant,
                    'destructive',
                  ) ==
                  'outline') {
                return Colors.transparent;
              } else if (valueOrDefault<String>(
                    widget.variant,
                    'destructive',
                  ) ==
                  'ghost') {
                return Colors.transparent;
              } else if (valueOrDefault<String>(
                    widget.variant,
                    'destructive',
                  ) ==
                  'destructive') {
                return FlutterFlowTheme.of(context).error;
              } else {
                return FlutterFlowTheme.of(context).primary;
              }
            }(),
            FlutterFlowTheme.of(context).error,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(valueOrDefault<double>(
              () {
                if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'small') {
                  return 4.0;
                } else if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'large') {
                  return 8.0;
                } else {
                  return 6.0;
                }
              }(),
              6.0,
            )),
            topRight: Radius.circular(valueOrDefault<double>(
              () {
                if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'small') {
                  return 4.0;
                } else if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'large') {
                  return 8.0;
                } else {
                  return 6.0;
                }
              }(),
              6.0,
            )),
            bottomLeft: Radius.circular(valueOrDefault<double>(
              () {
                if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'small') {
                  return 4.0;
                } else if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'large') {
                  return 8.0;
                } else {
                  return 6.0;
                }
              }(),
              6.0,
            )),
            bottomRight: Radius.circular(valueOrDefault<double>(
              () {
                if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'small') {
                  return 4.0;
                } else if (valueOrDefault<String>(
                      widget.size,
                      'medium',
                    ) ==
                    'large') {
                  return 8.0;
                } else {
                  return 6.0;
                }
              }(),
              6.0,
            )),
          ),
          shape: BoxShape.rectangle,
          border: Border.all(
            color: valueOrDefault<Color>(
              valueOrDefault<String>(
                        widget.variant,
                        'destructive',
                      ) ==
                      'outline'
                  ? FlutterFlowTheme.of(context).alternate
                  : Colors.transparent,
              Colors.transparent,
            ),
            width: valueOrDefault<double>(
              valueOrDefault<String>(
                        widget.variant,
                        'destructive',
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
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    valueOrDefault<double>(
                      () {
                        if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'small') {
                          return 16.0;
                        } else if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'large') {
                          return 32.0;
                        } else {
                          return 24.0;
                        }
                      }(),
                      24.0,
                    ),
                    valueOrDefault<double>(
                      () {
                        if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'small') {
                          return 4.0;
                        } else if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'large') {
                          return 16.0;
                        } else {
                          return 8.0;
                        }
                      }(),
                      8.0,
                    ),
                    valueOrDefault<double>(
                      () {
                        if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'small') {
                          return 16.0;
                        } else if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'large') {
                          return 32.0;
                        } else {
                          return 24.0;
                        }
                      }(),
                      24.0,
                    ),
                    valueOrDefault<double>(
                      () {
                        if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'small') {
                          return 4.0;
                        } else if (valueOrDefault<String>(
                              widget.size,
                              'medium',
                            ) ==
                            'large') {
                          return 16.0;
                        } else {
                          return 8.0;
                        }
                      }(),
                      8.0,
                    )),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (valueOrDefault<bool>(
                      widget.iconPresent,
                      true,
                    ))
                      widget.icon!,
                    Text(
                      valueOrDefault<String>(
                        widget.content,
                        'Sign out',
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
                                      'destructive',
                                    ) ==
                                    'secondary') {
                                  return Colors.white;
                                } else if (valueOrDefault<String>(
                                      widget.variant,
                                      'destructive',
                                    ) ==
                                    'outline') {
                                  return FlutterFlowTheme.of(context)
                                      .primaryText;
                                } else if (valueOrDefault<String>(
                                      widget.variant,
                                      'destructive',
                                    ) ==
                                    'ghost') {
                                  return FlutterFlowTheme.of(context).primary;
                                } else if (valueOrDefault<String>(
                                      widget.variant,
                                      'destructive',
                                    ) ==
                                    'destructive') {
                                  return Colors.white;
                                } else {
                                  return Colors.white;
                                }
                              }(),
                              Colors.white,
                            ),
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
                  ].divide(SizedBox(width: 8.0)),
                ),
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
                          'destructive',
                        ) ==
                        'secondary') {
                      return Colors.white;
                    } else if (valueOrDefault<String>(
                          widget.variant,
                          'destructive',
                        ) ==
                        'outline') {
                      return FlutterFlowTheme.of(context).primaryText;
                    } else if (valueOrDefault<String>(
                          widget.variant,
                          'destructive',
                        ) ==
                        'ghost') {
                      return FlutterFlowTheme.of(context).primary;
                    } else if (valueOrDefault<String>(
                          widget.variant,
                          'destructive',
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
