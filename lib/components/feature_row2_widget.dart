import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'feature_row2_model.dart';
export 'feature_row2_model.dart';

class FeatureRow2Widget extends StatefulWidget {
  const FeatureRow2Widget({
    super.key,
    this.icon,
    String? text,
  }) : this.text = text ??
            'Per-matter intake by email, text, and WhatsApp — nothing for the client to install.';

  final Widget? icon;
  final String text;

  @override
  State<FeatureRow2Widget> createState() => _FeatureRow2WidgetState();
}

class _FeatureRow2WidgetState extends State<FeatureRow2Widget> {
  late FeatureRow2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeatureRow2Model());

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(9999.0),
            shape: BoxShape.rectangle,
          ),
          alignment: AlignmentDirectional(0.0, 0.0),
          child: widget.icon!,
        ),
        Expanded(
          flex: 1,
          child: Text(
            valueOrDefault<String>(
              widget.text,
              'Per-matter intake by email, text, and WhatsApp — nothing for the client to install.',
            ),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.ibmPlexSans(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: Color(0xCCFFFFFF),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  lineHeight: 1.5,
                ),
          ),
        ),
      ].divide(SizedBox(width: 16.0)),
    );
  }
}
