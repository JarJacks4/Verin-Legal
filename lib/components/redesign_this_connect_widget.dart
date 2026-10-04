import '/components/button9_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/matter/practice_tab.dart' show connectClio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemMouseCursors;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'redesign_this_connect_model.dart';
export 'redesign_this_connect_model.dart';

/// Redesign this Connect drawer to feel simple and reassuring rather than
/// technical, while keeping a single "Connect [Provider]" button as the only
/// action (do not add email or password input fields to this design).
///
/// Top of the drawer: a brand tile — a rounded square icon container in a
/// light tint of the provider's color, holding a simple icon (briefcase for
/// MyCase, a lightning bolt for Smokeball, whatever mark represents Clio) —
/// next to the provider's name in bold and a one-line description beneath it
/// ("Practice management and billing", etc.).
///
/// Below that, one short reassuring paragraph in a teal-tinted callout box:
/// "You'll be taken to [Provider]'s own sign-in page to connect your account.
/// Verin never sees or stores your [Provider] password."
///
/// Below the callout, a single field: "How does this matter appear in
/// [Provider]?" with small gray helper text beneath the label ("the matter
/// name or file number as it shows in your account") and a placeholder
/// example like "Whitmore v. Whitmore".
///
/// Below the field, a short checklist using teal checkmarks instead of bullet
/// points, listing what gets synced (e.g. "Matter documents", "Billing
/// records", "Contact details" — adjust per provider).
///
/// Bottom: a single full-width "Connect to [Provider]" button. Design both
/// its
/// idle state and a loading state (a spinner replacing the button's text)
/// since only one shows at a time.
class RedesignThisConnectWidget extends StatefulWidget {
  const RedesignThisConnectWidget({
    super.key,
    Color? providerColor,
    this.providerIcon,
    String? providerName,
    String? providerDesc,
    bool? isLoading,
  })  : this.providerColor = providerColor ?? const Color(0x00000000),
        this.providerName = providerName ?? '',
        this.providerDesc = providerDesc ?? '',
        this.isLoading = isLoading ?? false;

  final Color providerColor;
  final Widget? providerIcon;
  final String providerName;
  final String providerDesc;
  final bool isLoading;

  @override
  State<RedesignThisConnectWidget> createState() =>
      _RedesignThisConnectWidgetState();
}

class _RedesignThisConnectWidgetState extends State<RedesignThisConnectWidget> {
  late RedesignThisConnectModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RedesignThisConnectModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  bool _connecting = false;

  String get _name {
    final n = widget.providerName.trim();
    return n.isEmpty ? 'Clio' : n;
  }

  /// Only Clio has a working (server-side OAuth) connection today.
  bool get _isClio => _name.toLowerCase().contains('clio');

  Future<void> _connect() async {
    if (!_isClio || _connecting) return;
    safeSetState(() => _connecting = true);
    await connectClio(context);
    if (!mounted) return;
    safeSetState(() => _connecting = false);
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.3,
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: (FFMainAxisAlignment.center).flutterValue,
            crossAxisAlignment: (FFCrossAxisAlignment.stretch).flutterValue,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                      color: widget.providerColor,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 40.0,
                          color: Color(0x442D5A5E),
                          offset: Offset(
                            0.0,
                            0.0,
                          ),
                          spreadRadius: 5.0,
                        )
                      ],
                      borderRadius: BorderRadius.circular(50.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: Color(0x101A1A1A),
                      ),
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: widget.providerIcon ??
                        Icon(
                          _isClio
                              ? Icons.business_center_rounded
                              : Icons.link_rounded,
                          color: FlutterFlowTheme.of(context).secondary,
                          size: 28.0,
                        ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment:
                          (FFCrossAxisAlignment.start).flutterValue,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _name,
                          textAlign: TextAlign.end,
                          style: FlutterFlowTheme.of(context)
                              .titleLarge
                              .override(
                                font: GoogleFonts.ibmPlexSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                          overflow: TextOverflow.fade,
                        ),
                        if (widget.providerDesc.trim().isNotEmpty)
                        Text(
                          widget.providerDesc,
                          textAlign: TextAlign.end,
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.ibmPlexSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                          overflow: TextOverflow.fade,
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 24.0,
                      ),
                    ),
                  ),
                ].divide(SizedBox(width: 16.0)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondary8,
                  borderRadius: BorderRadius.circular(8.0),
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).secondary20,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: FlutterFlowTheme.of(context).secondary,
                          size: 20.0,
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _isClio
                                ? 'You\'ll be taken to $_name\'s own sign-in page to connect your firm\'s account. Verin never sees or stores your $_name password.'
                                : '$_name isn\'t available yet. Verin can only connect to Clio today.',
                            maxLines: 4,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.ibmPlexSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).secondary,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                      ].divide(SizedBox(width: 16.0)),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'How do matters link to $_name?',
                    style: FlutterFlowTheme.of(context).labelLarge.override(
                          font: GoogleFonts.ibmPlexSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelLarge
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Text(
                    'You connect the firm\'s $_name account once. Then open each matter\'s Practice tab and pick the $_name matter it belongs to.',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.ibmPlexSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).accent3,
                          letterSpacing: 0.0,
                          fontWeight:
                              FlutterFlowTheme.of(context).bodySmall.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                ].divide(SizedBox(height: 4.0)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'What gets synced:',
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.ibmPlexSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Column(
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
                            Icons.check_circle_rounded,
                            color: FlutterFlowTheme.of(context).secondary,
                            size: 16.0,
                          ),
                          Text(
                            'Finished evidence record (PDF)',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.ibmPlexSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ].divide(SizedBox(width: 8.0)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: FlutterFlowTheme.of(context).secondary,
                            size: 16.0,
                          ),
                          Text(
                            'Certificate of preparation & exhibit index',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.ibmPlexSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ].divide(SizedBox(width: 8.0)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: FlutterFlowTheme.of(context).secondary,
                            size: 16.0,
                          ),
                          Text(
                            'Hash-chain appendix',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.ibmPlexSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ].divide(SizedBox(width: 8.0)),
                      ),
                    ].divide(SizedBox(height: 4.0)),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Container(
                  child: MouseRegion(
                    cursor: (_isClio && !_connecting && !widget.isLoading)
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                    // Only Clio can be connected; other providers keep the
                    // button disabled.
                    onTap: (_isClio && !_connecting && !widget.isLoading)
                        ? _connect
                        : null,
                    child: wrapWithModel(
                      model: _model.buttonModel,
                      updateCallback: () => safeSetState(() {}),
                      child: Button9Widget(
                        iconPresent: false,
                        iconEndPresent: false,
                        content: _isClio
                            ? 'Connect to $_name'
                            : 'Not available yet',
                        variant: 'primary',
                        size: 'large',
                        fullWidth: true,
                        loading: widget.isLoading || _connecting,
                        disabled: !_isClio,
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ].divide(SizedBox(height: 24.0)),
          ),
        ),
      ),
    );
  }
}
