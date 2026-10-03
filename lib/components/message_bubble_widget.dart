import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'message_bubble_model.dart';
export 'message_bubble_model.dart';

class MessageBubbleWidget extends StatefulWidget {
  const MessageBubbleWidget({
    super.key,
    String? content,
    String? time,
    String? repeated,
    bool? repeatedPresent,
    bool? isClient,
    bool? lowConfidence,
  })  : this.content = content ?? 'Are you picking up the kids at 4?',
        this.time = time ?? 'Feb 14, 2024 · 2:15 PM',
        this.repeated = repeated ?? 'Repeated',
        this.repeatedPresent = repeatedPresent ?? true,
        this.isClient = isClient ?? true,
        this.lowConfidence = lowConfidence ?? true;

  final String content;
  final String time;
  final String repeated;
  final bool repeatedPresent;
  final bool isClient;
  final bool lowConfidence;

  @override
  State<MessageBubbleWidget> createState() => _MessageBubbleWidgetState();
}

class _MessageBubbleWidgetState extends State<MessageBubbleWidget> {
  late MessageBubbleModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MessageBubbleModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: 320.0,
              ),
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  valueOrDefault<bool>(
                    widget.isClient,
                    true,
                  )
                      ? FlutterFlowTheme.of(context).secondaryBackground
                      : FlutterFlowTheme.of(context).primary,
                  FlutterFlowTheme.of(context).secondaryBackground,
                ),
                borderRadius: BorderRadius.circular(8.0),
                shape: BoxShape.rectangle,
                border: Border.all(
                  color: valueOrDefault<Color>(
                    valueOrDefault<bool>(
                      widget.lowConfidence,
                      true,
                    )
                        ? valueOrDefault<Color>(
                            valueOrDefault<bool>(
                              widget.isClient,
                              true,
                            )
                                ? FlutterFlowTheme.of(context).warning
                                : FlutterFlowTheme.of(context).primary,
                            FlutterFlowTheme.of(context).warning,
                          )
                        : FlutterFlowTheme.of(context).alternate,
                    FlutterFlowTheme.of(context).warning,
                  ),
                  width: valueOrDefault<double>(
                    valueOrDefault<bool>(
                      widget.lowConfidence,
                      true,
                    )
                        ? valueOrDefault<double>(
                            valueOrDefault<bool>(
                              widget.isClient,
                              true,
                            )
                                ? 1.0
                                : 1.0,
                            1.0,
                          )
                        : 1.0,
                    1.0,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        valueOrDefault<String>(
                          widget.content,
                          'Are you picking up the kids at 4?',
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.ibmPlexSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: valueOrDefault<Color>(
                                valueOrDefault<bool>(
                                  widget.isClient,
                                  true,
                                )
                                    ? FlutterFlowTheme.of(context).primaryText
                                    : FlutterFlowTheme.of(context).onPrimary,
                                FlutterFlowTheme.of(context).primaryText,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.5,
                            ),
                      ),
                      if (valueOrDefault<bool>(
                        widget.repeatedPresent,
                        true,
                      ))
                        Text(
                          valueOrDefault<String>(
                            widget.time,
                            'Feb 14, 2024 · 2:15 PM',
                          ),
                          style: FlutterFlowTheme.of(context)
                              .labelSmall
                              .override(
                                font: GoogleFonts.spaceGrotesk(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .fontStyle,
                                lineHeight: 1.2,
                              ),
                        ),
                    ].divide(SizedBox(height: 4.0)),
                  ),
                ),
              ),
            ),
            if (valueOrDefault<bool>(
              widget.lowConfidence,
              true,
            ))
              Icon(
                Icons.report_problem_rounded,
                color: FlutterFlowTheme.of(context).warning,
                size: 18.0,
              ),
          ].divide(SizedBox(width: 8.0)),
        ),
        Text(
          valueOrDefault<String>(
            widget.time,
            'Feb 14, 2024 · 2:15 PM',
          ),
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.spaceGrotesk(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                lineHeight: 1.2,
              ),
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
