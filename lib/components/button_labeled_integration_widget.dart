import '/components/button11_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'button_labeled_integration_model.dart';
export 'button_labeled_integration_model.dart';

/// Add a button labeled "Integration report" to the top-right of the Practice
/// Management tab's header, same row as the tab title, matching the visual
/// style of the existing "Add manual entry" button on the Intake tab.
///
/// Tapping it opens a drawer sliding in from the right, full height:
///
/// Header: dark teal background, "Verin Evidence Record" in small caps above
/// "Integration Report" in large bold white text, with the generation date
/// and
/// time in smaller text beneath.
///
/// Matter summary: a light gray card below the header showing matter name,
/// client, cause number, status, total evidence item count, and how many of
/// the 3 systems are synced ("1 of 3"), laid out as a label/value grid.
///
/// Per-system sections: one block each for Clio, MyCase, and Smokeball, in
/// that order. Each block: the provider's icon and name, the matched matter
/// ID
/// if connected, and a status badge (filled teal "Synced", outlined amber
/// "Pending", or outlined gray "Not Connected"). Below that, a 4-column
/// table:
/// Content | Kind | SHA-256 | Chain entry — Content shows a short
/// description,
/// a small channel badge, and the received date; SHA-256 and Chain entry show
/// truncated hash values in monospace font. A block with no synced evidence
/// shows a single centered gray message instead of the table ("Use the
/// Connect button to link this system").
///
/// Above the per-system sections, a single strip showing the overall hash
/// chain's most recent entry ("Chain head") in monospace, small and
/// unobtrusive.
///
/// Footer: small gray disclaimer text about versioning and the trust-incident
/// policy, a "Download PDF" button (filled teal, shows a spinner while
/// "generating"), and a plain "Close" button beside it.
class ButtonLabeledIntegrationWidget extends StatefulWidget {
  const ButtonLabeledIntegrationWidget({
    super.key,
    String? matterName,
    String? client,
    String? causeNo,
    String? syncRatio,
    String? chainHead,
  })  : this.matterName = matterName ?? '',
        this.client = client ?? '',
        this.causeNo = causeNo ?? '',
        this.syncRatio = syncRatio ?? '',
        this.chainHead = chainHead ?? '';

  final String matterName;
  final String client;
  final String causeNo;
  final String syncRatio;
  final String chainHead;

  @override
  State<ButtonLabeledIntegrationWidget> createState() =>
      _ButtonLabeledIntegrationWidgetState();
}

class _ButtonLabeledIntegrationWidgetState
    extends State<ButtonLabeledIntegrationWidget> {
  late ButtonLabeledIntegrationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ButtonLabeledIntegrationModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          wrapWithModel(
            model: _model.buttonModel,
            updateCallback: () => safeSetState(() {}),
            child: Button11Widget(
              icon: Icon(
                Icons.assessment_rounded,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 24.0,
              ),
              iconPresent: true,
              iconEndPresent: false,
              content: 'Integration report',
              variant: 'outline',
              size: 'medium',
              fullWidth: false,
              loading: false,
              disabled: false,
            ),
          ),
          Container(
            width: 0.0,
            height: 0.0,
          ),
        ],
      ),
    );
  }
}
