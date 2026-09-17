import '/auth/firebase_auth/auth_util.dart';
import '/components/button8_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'delete_account_bottom_sheet_model.dart';
export 'delete_account_bottom_sheet_model.dart';

/// Design a small confirmation bottom sheet for signing out of a legal
/// evidence platform, light paper-and-teal theme (background #FBFAF8, ink
/// text #172024).
///
/// Centered heading "Sign out of Verin?" in Spectral. Below it, a two-button
/// row: an outline "Cancel" button on the left, and a solid
/// oxblood/destructive (#8C3A3F) "Sign Out" button on the right. Keep it
/// compact — roughly a third of screen height — with a drag handle at the top
/// matching the other bottom sheets (Create Matter, Filter & Sort).
class DeleteAccountBottomSheetWidget extends StatefulWidget {
  const DeleteAccountBottomSheetWidget({
    super.key,
    String? title,
    String? cancelLabel,
    String? confirmLabel,
  })  : this.title = title ?? '',
        this.cancelLabel = cancelLabel ?? '',
        this.confirmLabel = confirmLabel ?? '';

  final String title;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<DeleteAccountBottomSheetWidget> createState() =>
      _DeleteAccountBottomSheetWidgetState();
}

class _DeleteAccountBottomSheetWidgetState
    extends State<DeleteAccountBottomSheetWidget> {
  late DeleteAccountBottomSheetModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeleteAccountBottomSheetModel());

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
        width: MediaQuery.sizeOf(context).width * 0.4,
        height: MediaQuery.sizeOf(context).height * 0.416,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFBFAF8),
            borderRadius: BorderRadius.circular(24.0),
            shape: BoxShape.rectangle,
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: Color(0x1A172024),
                      borderRadius: BorderRadius.circular(9999.0),
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 40.0, 0.0, 0.0),
                        child: Text(
                          'Are You Sure You Would Like To Delete Your Account?',
                          textAlign: TextAlign.center,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.spectral(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF172024),
                                    fontSize: 22.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                        ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            Navigator.pop(context);
                          },
                          child: wrapWithModel(
                            model: _model.buttonModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: Button8Widget(
                              iconPresent: false,
                              iconEndPresent: false,
                              content: widget.cancelLabel,
                              variant: 'outline',
                              size: 'medium',
                              fullWidth: true,
                              loading: false,
                              disabled: false,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await authManager.deleteUser(context);

                            context.goNamedAuth(CreateAccount1Widget.routeName,
                                context.mounted);
                          },
                          child: wrapWithModel(
                            model: _model.buttonModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: Button8Widget(
                              iconPresent: false,
                              iconEndPresent: false,
                              content: 'Delete Account',
                              variant: 'primary',
                              size: 'medium',
                              fullWidth: true,
                              loading: false,
                              disabled: false,
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 25.0, 0.0, 0.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                      child: Image.asset(
                        'assets/images/verinlegal_linkedin_logo_1024.png',
                        width: 88.59,
                        height: 84.9,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ].divide(SizedBox(height: 24.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
