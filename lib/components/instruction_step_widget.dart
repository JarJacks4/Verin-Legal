import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'instruction_step_model.dart';
export 'instruction_step_model.dart';

class InstructionStepWidget extends StatefulWidget {
  const InstructionStepWidget({
    super.key,
    String? description,
    String? number,
    String? title,
  })  : this.description = description ??
            'From the Integrity tab, export this matter\'s record as a ZIP. The ZIP contains the exhibit files and a JSON manifest.',
        this.number = number ?? '1',
        this.title = title ?? 'Export the record';

  final String description;
  final String number;
  final String title;

  @override
  State<InstructionStepWidget> createState() => _InstructionStepWidgetState();
}

class _InstructionStepWidgetState extends State<InstructionStepWidget> {
  late InstructionStepModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InstructionStepModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.0,
          height: 28.0,
          decoration: BoxDecoration(
            color: Color(0x1A2D5A5E),
            borderRadius: BorderRadius.circular(9999.0),
            shape: BoxShape.rectangle,
          ),
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Text(
            valueOrDefault<String>(
              '${widget.number}',
              '1',
            ),
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.ibmPlexSans(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondary,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                  lineHeight: 1.3,
                ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                valueOrDefault<String>(
                  widget.title,
                  'Export the record',
                ),
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).titleSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              Text(
                valueOrDefault<String>(
                  widget.description,
                  'From the Integrity tab, export this matter\'s record as a ZIP. The ZIP contains the exhibit files and a JSON manifest.',
                ),
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      lineHeight: 1.5,
                    ),
              ),
            ].divide(SizedBox(height: 4.0)),
          ),
        ),
      ].divide(SizedBox(width: 16.0)),
    );
  }
}
