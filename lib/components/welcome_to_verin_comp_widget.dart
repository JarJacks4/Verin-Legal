import '/components/button19_copy_widget.dart';
import '/components/button19_widget.dart';
import '/verin/auth/auth_shell.dart';
import '/create_account_step1/create_account_step1_widget.dart';
import '/firm_workspace_sign_in/firm_workspace_sign_in_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_to_verin_comp_model.dart';
export 'welcome_to_verin_comp_model.dart';

class WelcomeToVerinCompWidget extends StatefulWidget {
  const WelcomeToVerinCompWidget({super.key});

  @override
  State<WelcomeToVerinCompWidget> createState() =>
      _WelcomeToVerinCompWidgetState();
}

class _WelcomeToVerinCompWidgetState extends State<WelcomeToVerinCompWidget> {
  late WelcomeToVerinCompModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeToVerinCompModel());

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: (FFMainAxisAlignment.center).flutterValue,
          crossAxisAlignment: (FFCrossAxisAlignment.center).flutterValue,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Welcome to Verin',
              style: FlutterFlowTheme.of(context).displaySmall.override(
                    font: GoogleFonts.spectral(
                      fontWeight:
                          FlutterFlowTheme.of(context).displaySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).displaySmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).displaySmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).displaySmall.fontStyle,
                    lineHeight: 1.2,
                  ),
            ),
            Text(
              'Your firm\'s evidence intake and record preparation console. Create an account or sign in to continue.',
              textAlign: TextAlign.center,
              maxLines: 3,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.ibmPlexSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                    lineHeight: 1.6,
                  ),
            ),
          ].divide(SizedBox(height: 16.0)),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerinTap(
              onTap: () {
                SignupDraft.clear();
                context.pushNamed(CreateAccountStep1Widget.routeName);
              },
              child: wrapWithModel(
              model: _model.buttonModel,
              updateCallback: () => safeSetState(() {}),
              child: Button19Widget(
                iconPresent: false,
                iconEnd: Icon(
                  Icons.arrow_forward,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
                iconEndPresent: true,
                content: 'Create account',
                variant: 'primary',
                size: 'large',
                fullWidth: false,
                loading: false,
                disabled: false,
              ),
            )),
            VerinTap(
              onTap: () => context.pushNamed(FirmWorkspaceSignInWidget.routeName),
              child: wrapWithModel(
              model: _model.button19CopyModel,
              updateCallback: () => safeSetState(() {}),
              child: Button19CopyWidget(
                iconPresent: false,
                iconEndPresent: false,
                content: 'Sign In to Existing Workspace',
                fullWidth: false,
                loading: false,
                disabled: false,
              ),
            )),
          ].divide(SizedBox(height: 16.0)),
        ),
        Align(
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.start,
            direction: Axis.horizontal,
            runAlignment: WrapAlignment.start,
            verticalDirection: VerticalDirection.down,
            clipBehavior: Clip.none,
            children: [
              Text(
                'By continuing, you agree to Verin\'s',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).accent3,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      lineHeight: 1.5,
                    ),
              ),
              Text(
                'Terms of Service',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondary,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      decoration: TextDecoration.underline,
                      lineHeight: 1.5,
                    ),
              ),
              Text(
                'and',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).accent3,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      lineHeight: 1.5,
                    ),
              ),
              Text(
                'Privacy Policy',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondary,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      decoration: TextDecoration.underline,
                      lineHeight: 1.5,
                    ),
              ),
              Text(
                '.',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).accent3,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      lineHeight: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ].divide(SizedBox(height: 32.0)),
    );
  }
}
