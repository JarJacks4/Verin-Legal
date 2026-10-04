import '/components/button19_widget.dart';
import '/components/step_indicator_widget.dart';
import '/components/text_field11_widget.dart';
import '/verin/auth/auth_shell.dart';
import '/create_account_step2/create_account_step2_widget.dart';
import '/firm_workspace_sign_in/firm_workspace_sign_in_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_account_step1_comp_model.dart';
export 'create_account_step1_comp_model.dart';

class CreateAccountStep1CompWidget extends StatefulWidget {
  const CreateAccountStep1CompWidget({super.key});

  @override
  State<CreateAccountStep1CompWidget> createState() =>
      _CreateAccountStep1CompWidgetState();
}

class _CreateAccountStep1CompWidgetState
    extends State<CreateAccountStep1CompWidget> {
  late CreateAccountStep1CompModel _model;
  String? _error;

  String _text(TextField11Model m) => (m.inputTextController?.text ?? '').trim();

  void _continue() {
    final name = _text(_model.textFieldModel1);
    final firm = _text(_model.textFieldModel2);
    final role = _text(_model.textFieldModel3);
    if (name.isEmpty || firm.isEmpty || role.isEmpty) {
      setState(() => _error = 'Enter your full name, firm name and role to continue.');
      return;
    }
    SignupDraft.fullName = name;
    SignupDraft.firmName = firm;
    SignupDraft.role = role;
    setState(() => _error = null);
    context.pushNamed(CreateAccountStep2Widget.routeName);
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateAccountStep1CompModel());

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
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(
              height: 16.0,
              thickness: 1.0,
              indent: 0.0,
              endIndent: 0.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                wrapWithModel(
                  model: _model.stepIndicatorModel,
                  updateCallback: () => safeSetState(() {}),
                  child: StepIndicatorWidget(
                    activeStep: '1',
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your details',
                      style: FlutterFlowTheme.of(context).displaySmall.override(
                            font: GoogleFonts.spectral(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .displaySmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .displaySmall
                                .fontStyle,
                            lineHeight: 1.2,
                          ),
                    ),
                    Text(
                      'Tell us about yourself and your firm.',
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            font: GoogleFonts.ibmPlexSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                            lineHeight: 1.6,
                          ),
                    ),
                  ].divide(SizedBox(height: 4.0)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Full name',
                          style: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
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
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                                lineHeight: 1.3,
                              ),
                        ),
                        wrapWithModel(
                          model: _model.textFieldModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField11Widget(
                            label: '',
                            labelPresent: false,
                            helper: '',
                            helperPresent: false,
                            leadingIconPresent: false,
                            trailingIconPresent: false,
                            hint: 'Sarah Chen',
                            value: SignupDraft.fullName,
                            onChange: '',
                            onSubmit: '',
                            variant: 'filled',
                            error: false,
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
                          'Firm name',
                          style: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
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
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                                lineHeight: 1.3,
                              ),
                        ),
                        wrapWithModel(
                          model: _model.textFieldModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField11Widget(
                            label: '',
                            labelPresent: false,
                            helper: '',
                            helperPresent: false,
                            leadingIconPresent: false,
                            trailingIconPresent: false,
                            hint: 'Harbor Family Law',
                            value: SignupDraft.firmName,
                            onChange: '',
                            onSubmit: '',
                            variant: 'filled',
                            error: false,
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
                          'Role',
                          style: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
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
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                                lineHeight: 1.3,
                              ),
                        ),
                        wrapWithModel(
                          model: _model.textFieldModel3,
                          updateCallback: () => safeSetState(() {}),
                          child: TextField11Widget(
                            label: '',
                            labelPresent: false,
                            helper: '',
                            helperPresent: false,
                            leadingIconPresent: false,
                            trailingIconPresent: false,
                            hint: 'Paralegal',
                            value: SignupDraft.role,
                            onChange: '',
                            onSubmit: '',
                            variant: 'filled',
                            error: false,
                          ),
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
                  ].divide(SizedBox(height: 24.0)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VerinTap(
                      onTap: _continue,
                      child: wrapWithModel(
                      model: _model.buttonModel1,
                      updateCallback: () => safeSetState(() {}),
                      child: Button19Widget(
                        iconPresent: false,
                        iconEnd: Icon(
                          Icons.arrow_forward,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 24.0,
                        ),
                        iconEndPresent: true,
                        content: 'Continue',
                        variant: 'primary',
                        size: 'large',
                        fullWidth: false,
                        loading: false,
                        disabled: false,
                      ),
                    )),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Divider(
                            height: 16.0,
                            thickness: 1.0,
                            indent: 0.0,
                            endIndent: 0.0,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                        ),
                        Text(
                          'or',
                          style:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.ibmPlexSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent3,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                    lineHeight: 1.3,
                                  ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Divider(
                            height: 16.0,
                            thickness: 1.0,
                            indent: 0.0,
                            endIndent: 0.0,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                        ),
                      ].divide(SizedBox(width: 16.0)),
                    ),
                    VerinTap(
                      onTap: () => context.pushNamed(FirmWorkspaceSignInWidget.routeName),
                      child: wrapWithModel(
                      model: _model.buttonModel2,
                      updateCallback: () => safeSetState(() {}),
                      child: Button19Widget(
                        iconPresent: false,
                        iconEndPresent: false,
                        content: 'Sign in to existing workspace',
                        variant: 'secondary',
                        size: 'large',
                        fullWidth: false,
                        loading: false,
                        disabled: false,
                      ),
                    )),
                  ].divide(SizedBox(height: 16.0)),
                ),
                VerinAuthError(message: _error),
              ].divide(SizedBox(height: 32.0)),
            ),
          ].divide(SizedBox(height: 32.0)),
        ),
      ),
    );
  }
}
