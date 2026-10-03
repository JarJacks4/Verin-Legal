import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'feature_item_model.dart';
export 'feature_item_model.dart';

class FeatureItemWidget extends StatefulWidget {
  const FeatureItemWidget({
    super.key,
    String? label,
  }) : this.label = label ?? 'Unlimited legal document templates';

  final String label;

  @override
  State<FeatureItemWidget> createState() => _FeatureItemWidgetState();
}

class _FeatureItemWidgetState extends State<FeatureItemWidget> {
  late FeatureItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeatureItemModel());

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
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: FlutterFlowTheme.of(context).success,
          size: 18.0,
        ),
        Text(
          valueOrDefault<String>(
            widget.label,
            'Unlimited legal document templates',
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.ibmPlexSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
      ].divide(SizedBox(width: 8.0)),
    );
  }
}
