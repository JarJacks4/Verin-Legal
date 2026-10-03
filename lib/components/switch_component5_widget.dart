import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'switch_component5_model.dart';
export 'switch_component5_model.dart';

class SwitchComponent5Widget extends StatefulWidget {
  const SwitchComponent5Widget({
    super.key,
    String? label,
    bool? labelPresent,
    String? variant,
    bool? active,
  })  : this.label = label ?? 'Require Multi-Factor Authentication (MFA)',
        this.labelPresent = labelPresent ?? true,
        this.variant = variant ?? 'iOS 26+',
        this.active = active ?? true;

  final String label;
  final bool labelPresent;
  final String variant;
  final bool active;

  @override
  State<SwitchComponent5Widget> createState() => _SwitchComponent5WidgetState();
}

class _SwitchComponent5WidgetState extends State<SwitchComponent5Widget> {
  late SwitchComponent5Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SwitchComponent5Model());

    _model.switchValue = valueOrDefault<bool>(
      valueOrDefault<bool>(
        widget.active,
        true,
      )
          ? true
          : false,
      true,
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
                    'iOS 26+',
                  ) ==
                  'iOS') {
                return true;
              } else if (valueOrDefault<String>(
                    widget.variant,
                    'iOS 26+',
                  ) ==
                  'iOS 26+') {
                return false;
              } else {
                return true;
              }
            }(),
            false,
          ))
            Switch(
              value: _model.switchValue!,
              onChanged: (newValue) async {
                safeSetState(() => _model.switchValue = newValue);
              },
              activeTrackColor: FlutterFlowTheme.of(context).primary,
              inactiveTrackColor: FlutterFlowTheme.of(context).alternate,
              inactiveThumbColor: FlutterFlowTheme.of(context).secondaryText,
            ),
          if (valueOrDefault<bool>(
            () {
              if (valueOrDefault<String>(
                    widget.variant,
                    'iOS 26+',
                  ) ==
                  'iOS') {
                return false;
              } else if (valueOrDefault<String>(
                    widget.variant,
                    'iOS 26+',
                  ) ==
                  'iOS 26+') {
                return true;
              } else {
                return false;
              }
            }(),
            true,
          ))
            Container(
              width: valueOrDefault<double>(
                valueOrDefault<String>(
                          widget.variant,
                          'iOS 26+',
                        ) ==
                        'iOS 26+'
                    ? 64.0
                    : 56.0,
                64.0,
              ),
              height: valueOrDefault<double>(
                valueOrDefault<String>(
                          widget.variant,
                          'iOS 26+',
                        ) ==
                        'iOS 26+'
                    ? 28.0
                    : 32.0,
                28.0,
              ),
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  valueOrDefault<bool>(
                    widget.active,
                    true,
                  )
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context).alternate,
                  FlutterFlowTheme.of(context).primary,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS 26+',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    9999.0,
                  )),
                  topRight: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS 26+',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    9999.0,
                  )),
                  bottomLeft: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS 26+',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    9999.0,
                  )),
                  bottomRight: Radius.circular(valueOrDefault<double>(
                    valueOrDefault<String>(
                              widget.variant,
                              'iOS 26+',
                            ) ==
                            'iOS 26+'
                        ? 9999.0
                        : 16.0,
                    9999.0,
                  )),
                ),
                shape: BoxShape.rectangle,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS 26+',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      2.0,
                    ),
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS 26+',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      2.0,
                    ),
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS 26+',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      2.0,
                    ),
                    valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS 26+',
                              ) ==
                              'iOS 26+'
                          ? 2.0
                          : 3.0,
                      2.0,
                    )),
                child: Container(
                  child: Container(
                    width: valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS 26+',
                              ) ==
                              'iOS 26+'
                          ? 39.0
                          : 26.0,
                      39.0,
                    ),
                    height: valueOrDefault<double>(
                      valueOrDefault<String>(
                                widget.variant,
                                'iOS 26+',
                              ) ==
                              'iOS 26+'
                          ? 24.0
                          : 26.0,
                      24.0,
                    ),
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        () {
                          if (valueOrDefault<bool>(
                            widget.active,
                            true,
                          )) {
                            return Colors.white;
                          } else if (valueOrDefault<String>(
                                widget.variant,
                                'iOS 26+',
                              ) ==
                              'iOS 26+') {
                            return FlutterFlowTheme.of(context)
                                .secondaryBackground;
                          } else {
                            return FlutterFlowTheme.of(context)
                                .primaryBackground;
                          }
                        }(),
                        Colors.white,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS 26+',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          9999.0,
                        )),
                        topRight: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS 26+',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          9999.0,
                        )),
                        bottomLeft: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS 26+',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          9999.0,
                        )),
                        bottomRight: Radius.circular(valueOrDefault<double>(
                          valueOrDefault<String>(
                                    widget.variant,
                                    'iOS 26+',
                                  ) ==
                                  'iOS 26+'
                              ? 9999.0
                              : 13.0,
                          9999.0,
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
                    'Require Multi-Factor Authentication (MFA)',
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
                        lineHeight: 1.5,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
