import '/auth/firebase_auth/auth_util.dart';
import '/verin_app/auth/two_step.dart' show askTwoStepCode, kTwoStepNeeded;
import '/components/button19_widget.dart';
import '/components/text_field11_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/verin/auth/auth_actions.dart';
import '/verin/auth/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firm_workspace_sign_in_model.dart';
export 'firm_workspace_sign_in_model.dart';

/// Sign in to an existing Verin workspace (email + password). Same layout as
/// the Welcome and Create account pages.
class FirmWorkspaceSignInWidget extends StatefulWidget {
  const FirmWorkspaceSignInWidget({super.key});

  static String routeName = 'FirmWorkspaceSignIn';
  static String routePath = '/firmWorkspaceSignIn';

  @override
  State<FirmWorkspaceSignInWidget> createState() =>
      _FirmWorkspaceSignInWidgetState();
}

class _FirmWorkspaceSignInWidgetState extends State<FirmWorkspaceSignInWidget> {
  late FirmWorkspaceSignInModel _model;
  late TextField11Model _emailModel;
  late TextField11Model _passwordModel;

  String? _error;
  String? _info;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FirmWorkspaceSignInModel());
    _emailModel = createModel(context, () => TextField11Model());
    _passwordModel = createModel(context, () => TextField11Model());

    // Already signed in → straight to the matters list.
    if (currentUserUid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(MattersListWidget.routeName);
      });
    }
  }

  @override
  void dispose() {
    _emailModel.dispose();
    _passwordModel.dispose();
    _model.dispose();
    super.dispose();
  }

  String get _email => (_emailModel.inputTextController?.text ?? '').trim();
  String get _password => _passwordModel.inputTextController?.text ?? '';

  Future<void> _signIn() async {
    if (_busy) return;
    if (!looksLikeEmail(_email)) {
      setState(() => _error = 'Enter the email you signed up with.');
      return;
    }
    if (_password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    GoRouter.of(context).prepareAuthEvent();
    var err = await verinSignIn(email: _email, password: _password);
    if (!mounted) return;
    if (err == kTwoStepNeeded) {
      err = await askTwoStepCode(context);
      if (err == null) await finishTwoStepSignIn();
      if (!mounted) return;
    }
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    setState(() => _busy = false);
    context.goNamedAuth(MattersListWidget.routeName, context.mounted);
  }

  Future<void> _forgot() async {
    if (!looksLikeEmail(_email)) {
      setState(() {
        _info = null;
        _error = 'Enter your email above first, then tap "Forgot password?" again.';
      });
      return;
    }
    final err = await verinResetPassword(_email);
    if (!mounted) return;
    setState(() {
      _error = err;
      _info = err == null ? 'Password reset email sent to $_email.' : null;
    });
  }

  Widget _label(String text) {
    final t = FlutterFlowTheme.of(context);
    return Text(
      text,
      style: t.labelLarge.override(
        font: GoogleFonts.ibmPlexSans(fontWeight: t.labelLarge.fontWeight),
        color: t.primaryText,
        letterSpacing: 0.0,
        lineHeight: 1.3,
      ),
    );
  }

  Widget _link(String text, VoidCallback onTap) {
    final t = FlutterFlowTheme.of(context);
    return VerinTap(
      onTap: onTap,
      child: Text(
        text,
        style: t.bodySmall.override(
          font: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w500),
          color: t.secondary,
          letterSpacing: 0.0,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return VerinAuthShell(
      maxFormWidth: 480.0,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in',
                style: t.displaySmall.override(
                  font: GoogleFonts.spectral(fontWeight: t.displaySmall.fontWeight),
                  color: t.primaryText,
                  letterSpacing: 0.0,
                  lineHeight: 1.2,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Access your firm\'s matters and chain-of-custody records.',
                style: t.bodyLarge.override(
                  font: GoogleFonts.ibmPlexSans(fontWeight: t.bodyLarge.fontWeight),
                  color: t.secondaryText,
                  letterSpacing: 0.0,
                  lineHeight: 1.6,
                ),
              ),
              const SizedBox(height: 32.0),
              _label('Work email'),
              const SizedBox(height: 4.0),
              wrapWithModel(
                model: _emailModel,
                updateCallback: () => safeSetState(() {}),
                child: TextField11Widget(
                  hint: 'you@yourfirm.com',
                  variant: 'filled',
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(child: _label('Password')),
                  _link('Forgot password?', _forgot),
                ],
              ),
              const SizedBox(height: 4.0),
              wrapWithModel(
                model: _passwordModel,
                updateCallback: () => safeSetState(() {}),
                child: TextField11Widget(
                  hint: '••••••••',
                  variant: 'filled',
                  obscure: true,
                ),
              ),
              const SizedBox(height: 24.0),
              VerinAuthError(message: _error),
              if (_info != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(_info!, style: t.bodySmall.copyWith(color: t.success)),
                ),
              if (_error != null || _info != null) const SizedBox(height: 16.0),
              VerinTap(
                onTap: _busy ? null : _signIn,
                child: Button19Widget(
                  iconPresent: false,
                  iconEndPresent: false,
                  content: _busy ? 'Signing in…' : 'Sign in',
                  variant: 'primary',
                  size: 'large',
                  fullWidth: true,
                  loading: _busy,
                  disabled: false,
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(child: Divider(thickness: 1.0, color: t.alternate)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('or', style: t.labelMedium.copyWith(color: t.accent3)),
                  ),
                  Expanded(child: Divider(thickness: 1.0, color: t.alternate)),
                ],
              ),
              const SizedBox(height: 16.0),
              VerinTap(
                onTap: () {
                  SignupDraft.clear();
                  context.pushNamed(CreateAccountStep1Widget.routeName);
                },
                child: Button19Widget(
                  iconPresent: false,
                  iconEndPresent: false,
                  content: 'Create an account',
                  variant: 'secondary',
                  size: 'large',
                  fullWidth: true,
                  loading: false,
                  disabled: false,
                ),
              ),
              const SizedBox(height: 24.0),
              Center(
                child: _link('Back to welcome', () {
                  if (Navigator.of(context).canPop()) {
                    context.safePop();
                  } else {
                    context.goNamed(WelcomeScreenWidget.routeName);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
