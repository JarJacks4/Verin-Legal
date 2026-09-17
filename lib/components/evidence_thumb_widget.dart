import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'evidence_thumb_model.dart';
export 'evidence_thumb_model.dart';

class EvidenceThumbWidget extends StatefulWidget {
  const EvidenceThumbWidget({
    super.key,
    String? idLabel,
    bool? selected,
  })  : this.idLabel = idLabel ?? 'IMG_8821.png',
        this.selected = selected ?? true;

  final String idLabel;
  final bool selected;

  @override
  State<EvidenceThumbWidget> createState() => _EvidenceThumbWidgetState();
}

class _EvidenceThumbWidgetState extends State<EvidenceThumbWidget> {
  late EvidenceThumbModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EvidenceThumbModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).surfaceVariant,
          borderRadius: BorderRadius.circular(6.0),
          shape: BoxShape.rectangle,
          border: Border.all(
            color: valueOrDefault<Color>(
              valueOrDefault<bool>(
                widget.selected,
                true,
              )
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).alternate,
              FlutterFlowTheme.of(context).primary,
            ),
            width: valueOrDefault<double>(
              valueOrDefault<bool>(
                widget.selected,
                true,
              )
                  ? 2.0
                  : 2.0,
              2.0,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120.0,
              decoration: BoxDecoration(
                color: Color(0xFFE5E7EB),
                shape: BoxShape.rectangle,
              ),
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Icon(
                Icons.image_outlined,
                color: FlutterFlowTheme.of(context).secondaryText40,
                size: 32.0,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                shape: BoxShape.rectangle,
              ),
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: Container(
                  child: Text(
                    valueOrDefault<String>(
                      widget.idLabel,
                      'IMG_8821.png',
                    ),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.spaceGrotesk(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
