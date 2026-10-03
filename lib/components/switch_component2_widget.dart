import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'switch_component2_model.dart';
export 'switch_component2_model.dart';

class SwitchComponent2Widget extends StatefulWidget {
  const SwitchComponent2Widget({
    super.key,
    String? label,
    bool? labelPresent,
    String? variant,
    bool? active,
  })  : this.label = label ?? 'Active Monitoring',
        this.labelPresent = labelPresent ?? true,
        this.variant = variant ?? 'iOS',
        this.active = active ?? false;

  final String label;
  final bool labelPresent;
  final String variant;
  final bool active;

  @override
  State<SwitchComponent2Widget> createState() => _SwitchComponent2WidgetState();
}

class _SwitchComponent2WidgetState extends State<SwitchComponent2Widget> {
  late SwitchComponent2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SwitchComponent2Model());

    _model.switchValue = valueOrDefault<bool>(
      valueOrDefault<bool>(
        widget.active,
        false,
      )
          ? true
          : false,
      false,
    );
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
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (valueOrDefault<bool>(
            () {
              if (valueOrDefault<String>(
                    widget.variant,
                    'iOS',
                  ) ==
                  'iOS') {
                return true;
              } else if (valueOrDefault<String>(
                    widget.variant,
                    'iOS',
                  ) ==
                  'iOS 26+') {
                return false;
              } else {
                return true;
              }
            }(),
            true,
          ))
            Switch.adaptive(
              value: _model.switchValue!,
              onChanged: (newValue) async {
                safeSetState(() => _model.switchValue = newValue);
              },
              activeTrackColor: FlutterFlowTheme.of(context).primary,
              inactiveTrackColor: FlutterFlowTheme.of(context).alternate,
              inactiveThumbColor:
                  FlutterFlowTheme.of(context).primaryBackground,
            ),
          if (valueOrDefault<bool>(
            () {
              if (valueOrDefault<String>(
                    widget.variant,
                    'iOS',
                  ) ==
                  'iOS') {
                return false;
              } else if (valueOrDefault<String>(
                    widget.variant,
                    'iOS',
                  ) ==
                  'iOS 26+') {
                return true;
              } else {
                return false;
              }
            }(),
            false,
          ))
            Container(
              width: valueOrDefault<double>(
                valueOrDefault<String>(
                          widget.variant,
                          'iOS',
                        ) ==
                        'iOS 26+'
                    ? 64.0
                    : 56.0,
                56.0,
              ),
              height: valueOrDefault<double>(
                valueOrDefault<String>(
                          widget.variant,
                          'iOS',
                        ) ==
                        'iOS 26+'
                    ? 28.0
                    : 32.0,
                32.0,
              ),
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  valueOrDefault<bool>(
                    widget.active,
                    false,
                  )
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context).alternate,
                  FlutterFlowTheme.of(context).alternate,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    16.0,
                  )),
                  topRight: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    16.0,
                  )),
                  bottomLeft: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    16.0,
                  )),
                  bottomRight: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    16.0,
                  )),
                ),
                shape: BoxShape.rectangle,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      3.0,
                    ),
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      3.0,
                    ),
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      3.0,
                    ),
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      3.0,
                    )),
                child: Container(
                  child: Container(
                    width: valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS',
                              ) ==
                              'iOS 26+'
                          ? 39.0
                          : 26.0,
                      26.0,
                    ),
                    height: valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS',
                              ) ==
                              'iOS 26+'
                          ? 24.0
                          : 26.0,
                      26.0,
                    ),
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        () {
                          if (valueOrDefault<bool>(
                            widget.active,
                            false,
                          )) {
                            return FlutterFlowTheme.of(context).onPrimary;
                          } else if (valueOrDefault<String>(
                                widget.variant,
                                'iOS',
                              ) ==
                              'iOS 26+') {
                            return FlutterFlowTheme.of(context)
                                .secondaryBackground;
                          } else {
                            return FlutterFlowTheme.of(context)
                                .primaryBackground;
                          }
                        }(),
                        FlutterFlowTheme.of(context).primaryBackground,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          13.0,
                        )),
                        topRight: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          13.0,
                        )),
                        bottomLeft: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          13.0,
                        )),
                        bottomRight: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          13.0,
                        )),
                      ),
                      shape: BoxShape.rectangle,
                    ),
                  ),
                ),
              ),
            ),
          if (valueOrDefault<bool>(
            widget.labelPresent,
            true,
          ))
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
              child: Container(
                child: Text(
                  valueOrDefault<String>(
                    widget.label,
                    'Active Monitoring',
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.ibmPlexSans(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
