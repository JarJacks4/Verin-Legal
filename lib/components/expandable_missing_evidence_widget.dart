import '/components/button6_widget.dart';
import '/components/text_field4_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'expandable_missing_evidence_model.dart';
export 'expandable_missing_evidence_model.dart';

/// Design an expandable "Missing-evidence follow-up" panel for a legal intake
/// screen, light paper-and-teal theme (background #FBFAF8, panel surface pale
/// teal tint #E4EEEF, ink text #172024, teal primary #0E6E7D).
///
/// Sits below an Intake Channels card. Includes: a small header
/// "Missing-evidence follow-up" with a mail icon; a multi-line editable text
/// box pre-filled with a draft message (e.g. "Hi Elena, we noticed a gap in
/// the messages received between Apr 18 and Apr 20 — could you forward any
/// additional screenshots from that period?"); a bottom row with an outline
/// "Cancel" button left and a solid teal "Approve & Send Request" button
/// right. Rounded 12px corners, 16px internal padding, subtle top border
/// separating it from the card above.
class ExpandableMissingEvidenceWidget extends StatefulWidget {
  const ExpandableMissingEvidenceWidget({
    super.key,
    bool? isExpanded,
    String? draftMessage,
  })  : this.isExpanded = isExpanded ?? false,
        this.draftMessage = draftMessage ?? '';

  final bool isExpanded;
  final String draftMessage;

  @override
  State<ExpandableMissingEvidenceWidget> createState() =>
      _ExpandableMissingEvidenceWidgetState();
}

class _ExpandableMissingEvidenceWidgetState
    extends State<ExpandableMissingEvidenceWidget> {
  late ExpandableMissingEvidenceModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExpandableMissingEvidenceModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.5,
        height: MediaQuery.sizeOf(context).height * 0.281,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFE4EEEF),
            borderRadius: BorderRadius.circular(12.0),
            shape: BoxShape.rectangle,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 1.0,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.rectangle,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFF0E6E7D),
                            size: 18.0,
                          ),
                          Text(
                            'Missing-evidence follow-up',
                            style: FlutterFlowTheme.of(context)
                                .labelLarge
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF172024),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ].divide(SizedBox(width: 8.0)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(8.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: Color(0x330E6E7D),
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Container(
                            child: wrapWithModel(
                              model: _model.textFieldModel,
                              updateCallback: () => safeSetState(() {}),
                              child: TextField4Widget(
                                label: '',
                                labelPresent: false,
                                helper: '',
                                helperPresent: false,
                                leadingIconPresent: false,
                                trailingIconPresent: false,
                                hint: 'Enter follow-up message...',
                                value: widget.draftMessage,
                                onChange: '',
                                onSubmit: '',
                                variant: 'ghost',
                                error: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          wrapWithModel(
                            model: _model.buttonModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: Button6Widget(
                              iconPresent: false,
                              iconEndPresent: false,
                              content: 'Cancel',
                              variant: 'outline',
                              size: 'small',
                              fullWidth: false,
                              loading: false,
                              disabled: false,
                            ),
                          ),
                          wrapWithModel(
                            model: _model.buttonModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: Button6Widget(
                              iconPresent: false,
                              iconEndPresent: false,
                              content: 'Approve & Send Request',
                              variant: 'primary',
                              size: 'small',
                              fullWidth: false,
                              loading: false,
                              disabled: false,
                            ),
                          ),
                        ].divide(SizedBox(width: 16.0)),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
