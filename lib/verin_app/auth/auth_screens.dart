// Verin onboarding — Welcome, Sign in, Create account (steps 1 and 2).
// Port of the Make's WelcomeScreen / SignInScreen / SignUpScreen, wired to
// Firebase Auth through lib/verin/auth/auth_actions.dart.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/auth/auth_actions.dart';
import '/verin/auth/auth_shell.dart' show SignupDraft, looksLikeEmail;

import '../theme/tokens.dart';
import '../widgets/atoms.dart';

const kWelcomeRoute = 'WelcomeScreen';
const kSignInRoute = 'FirmWorkspaceSignIn';
const kSignUp1Route = 'CreateAccountStep1';
const kSignUp2Route = 'CreateAccountStep2';
const kHomeRoute = 'MattersList';

const kRoles = ['Attorney', 'Paralegal', 'Case Manager', 'Administrator'];

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

class AuthLeftPanel extends StatelessWidget {
  const AuthLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    const points = [
      (Icons.inbox_outlined, 'Per-matter intake by email, text, and WhatsApp — nothing for the client to install.'),
      (Icons.verified_user_outlined, 'SHA-256 + RFC 3161 at receipt — integrity sealed before anyone opens the file.'),
      (Icons.apartment_outlined, 'Finished records write back to Clio, MyCase, and Smokeball automatically.'),
    ];
    return Container(
      color: c.panel,
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const VWordmark(size: 32.0, onDark: true),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evidence organized\nfrom the moment\nit arrives.',
                style: VT.h2(context, size: 38.0, color: c.paper),
              ),
              const SizedBox(height: 32.0),
              for (final (icon, text) in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28.0,
                        height: 28.0,
                        margin: const EdgeInsets.only(top: 2.0),
                        decoration: BoxDecoration(color: c.onPanelA(0.15), shape: BoxShape.circle),
                        child: Icon(icon, size: 15.0, color: c.onPanel),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(text, style: VT.body(context, color: c.onPanelA(0.82), height: 1.55)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Text(
            '© ${DateTime.now().year} Verin Evidence Record',
            style: VT.body(context, size: 11.0, color: c.onPanelA(0.35)),
          ),
        ],
      ),
    );
  }
}

/// 55 / 45 split on wide screens; form only (with the wordmark on top) on
/// narrow ones. The form side always scrolls.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: c.background,
        body: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 1024.0;
            final form = LayoutBuilder(
              builder: (context, b) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: b.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!wide) ...[
                              const Align(alignment: Alignment.centerLeft, child: VWordmark(size: 28.0)),
                              const SizedBox(height: 32.0),
                            ],
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(flex: 55, child: AuthLeftPanel()),
                            Expanded(flex: 45, child: form),
                          ],
                        )
                      : form,
                ),
                const Positioned(top: 16.0, right: 16.0, child: VThemeToggle()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: VT.h2(context, size: 26.0)),
        const SizedBox(height: 6.0),
        Text(subtitle, style: VT.muted(context, size: 14.0)),
        const SizedBox(height: 28.0),
      ],
    );
  }
}

/// Signed-in users never see the auth pages.
mixin _RedirectIfSignedIn<T extends StatefulWidget> on State<T> {
  void redirectIfSignedIn() {
    if (currentUserUid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(kHomeRoute);
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Welcome
// ---------------------------------------------------------------------------

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> with _RedirectIfSignedIn {
  @override
  void initState() {
    super.initState();
    redirectIfSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: VBadge(label: 'FIRM CONSOLE', icon: Icons.shield_outlined, bg: c.tealPale, fg: c.tealDeep, bold: true),
          ),
          const SizedBox(height: 12.0),
          Text('Welcome to Verin', style: VT.h2(context, size: 28.0)),
          const SizedBox(height: 8.0),
          Text(
            "Your firm's evidence intake and record preparation console. Create an account or sign in to continue.",
            style: VT.muted(context, size: 15.0, height: 1.55),
          ),
          const SizedBox(height: 36.0),
          VButton(
            label: 'Create account',
            trailingIcon: Icons.arrow_forward,
            size: VButtonSize.lg,
            fullWidth: true,
            onPressed: () {
              SignupDraft.clear();
              context.pushNamed(kSignUp1Route);
            },
          ),
          const SizedBox(height: 12.0),
          VButton(
            label: 'Sign in to existing workspace',
            kind: VButtonKind.tonal,
            size: VButtonSize.lg,
            fullWidth: true,
            onPressed: () => context.pushNamed(kSignInRoute),
          ),
          const SizedBox(height: 32.0),
          Text.rich(
            TextSpan(
              style: VT.muted(context, size: 12.0),
              children: [
                const TextSpan(text: "By continuing, you agree to Verin's "),
                TextSpan(text: 'Terms of Service', style: VT.body(context, size: 12.0, color: c.teal)),
                const TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: VT.body(context, size: 12.0, color: c.teal)),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign in
// ---------------------------------------------------------------------------

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> with _RedirectIfSignedIn {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  String? _info;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    redirectIfSignedIn();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!looksLikeEmail(email)) {
      setState(() => _error = 'Enter the work email you signed up with.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    GoRouter.of(context).prepareAuthEvent();
    final err = await verinSignIn(email: email, password: _password.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    context.goNamedAuth(kHomeRoute, context.mounted);
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() {
        _info = null;
        _error = 'Enter your work email above, then choose "Forgot password?" again.';
      });
      return;
    }
    final err = await verinResetPassword(email);
    if (!mounted) return;
    setState(() {
      _error = err;
      _info = err == null ? 'Password reset email sent to $email.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Heading(title: 'Sign in', subtitle: 'Enter your work email and password to continue.'),
            if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 16.0)],
            if (_info != null) ...[VNotice(text: _info!, tone: VNoticeTone.verified), const SizedBox(height: 16.0)],
            VTextField(
              controller: _email,
              label: 'Work email',
              hint: 'you@yourfirm.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16.0),
            VTextField(
              controller: _password,
              label: 'Password',
              hint: '••••••••',
              obscure: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: VButton(label: 'Forgot password?', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: _forgot),
              ),
            ),
            const SizedBox(height: 16.0),
            VButton(
              label: 'Sign in',
              loadingLabel: 'Signing in…',
              loading: _busy,
              size: VButtonSize.lg,
              fullWidth: true,
              onPressed: _submit,
            ),
            const SizedBox(height: 20.0),
            const VOrDivider(),
            const SizedBox(height: 16.0),
            VButton(
              label: 'Create a new account',
              kind: VButtonKind.tonal,
              fullWidth: true,
              onPressed: () {
                SignupDraft.clear();
                context.pushNamed(kSignUp1Route);
              },
            ),
            const SizedBox(height: 24.0),
            Center(
              child: VButton(
                label: '← Back to welcome',
                kind: VButtonKind.link,
                size: VButtonSize.sm,
                onPressed: () => context.goNamed(kWelcomeRoute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create account
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    Widget dot(int s) {
      final on = s <= step;
      return Container(
        width: 24.0,
        height: 24.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? c.primary : c.secondary, shape: BoxShape.circle),
        child: s < step
            ? Icon(Icons.check_circle_outline, size: 13.0, color: c.primaryFg)
            : Text('$s', style: VT.body(context, size: 11.0, weight: FontWeight.w600, color: on ? c.primaryFg : c.mutedFg)),
      );
    }

    return Row(
      children: [
        dot(1),
        const SizedBox(width: 8.0),
        Container(width: 32.0, height: 1.0, color: step > 1 ? c.primary : c.border),
        const SizedBox(width: 8.0),
        dot(2),
        const SizedBox(width: 16.0),
        Text('Step $step of 2', style: VT.muted(context, size: 12.0)),
      ],
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key, required this.step});

  final int step;

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with _RedirectIfSignedIn {
  late final _name = TextEditingController(text: SignupDraft.fullName);
  late final _firm = TextEditingController(text: SignupDraft.firmName);
  late String _role = kRoles.contains(SignupDraft.role) ? SignupDraft.role : 'Paralegal';
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.step == 1) redirectIfSignedIn();
    if (widget.step == 2 && !SignupDraft.isComplete) {
      // Landed on step 2 directly (refresh / bookmark): details are missing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(kSignUp1Route);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _firm.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _continue() {
    if (_name.text.trim().isEmpty || _firm.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in your name and firm.');
      return;
    }
    SignupDraft.fullName = _name.text.trim();
    SignupDraft.firmName = _firm.text.trim();
    SignupDraft.role = _role;
    setState(() => _error = null);
    context.pushNamed(kSignUp2Route);
  }

  Future<void> _create() async {
    if (_busy) return;
    final email = _email.text.trim();
    String? err;
    if (email.isEmpty || _password.text.isEmpty || _confirm.text.isEmpty) {
      err = 'Please fill in all fields.';
    } else if (!looksLikeEmail(email)) {
      err = 'Enter a valid work email.';
    } else if (_password.text.length < 8) {
      err = 'Use at least 8 characters for your password.';
    } else if (_password.text != _confirm.text) {
      err = 'Passwords do not match.';
    } else if (!SignupDraft.isComplete) {
      err = 'Your details are missing — go back to step 1.';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    GoRouter.of(context).prepareAuthEvent();
    final result = await verinSignUp(
      email: email,
      password: _password.text,
      fullName: SignupDraft.fullName,
      firmName: SignupDraft.firmName,
      role: SignupDraft.role,
    );
    if (!mounted) return;
    if (result != null && currentUserUid.isEmpty) {
      setState(() {
        _busy = false;
        _error = result;
      });
      return;
    }
    if (result != null) showVToast(context, result, error: true);
    context.goNamedAuth(kHomeRoute, context.mounted);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    return AuthLayout(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(step: step),
            const SizedBox(height: 24.0),
            _Heading(
              title: step == 1 ? 'Your details' : 'Create password',
              subtitle: step == 1 ? 'Tell us about yourself and your firm.' : 'Set a password for your account.',
            ),
            if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 16.0)],
            if (step == 1) ...[
              VTextField(controller: _name, label: 'Full name', hint: 'Sarah Chen', autofillHints: const [AutofillHints.name]),
              const SizedBox(height: 16.0),
              VTextField(controller: _firm, label: 'Firm name', hint: 'Harbor Family Law', autofillHints: const [AutofillHints.organizationName]),
              const SizedBox(height: 16.0),
              VSelect<String>(
                label: 'Role',
                value: _role,
                items: kRoles,
                labelFor: (r) => r,
                onChanged: (r) => setState(() => _role = r),
              ),
            ] else ...[
              VTextField(
                controller: _email,
                label: 'Work email',
                hint: 'you@yourfirm.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16.0),
              VTextField(controller: _password, label: 'Password', hint: '••••••••', obscure: true, autofillHints: const [AutofillHints.newPassword]),
              const SizedBox(height: 16.0),
              VTextField(
                controller: _confirm,
                label: 'Confirm password',
                hint: '••••••••',
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _create(),
              ),
            ],
            const SizedBox(height: 24.0),
            if (step == 1)
              VButton(label: 'Continue', trailingIcon: Icons.arrow_forward, size: VButtonSize.lg, fullWidth: true, onPressed: _continue)
            else
              VButton(
                label: 'Create account',
                loadingLabel: 'Creating account…',
                loading: _busy,
                size: VButtonSize.lg,
                fullWidth: true,
                onPressed: _create,
              ),
            if (step == 1) ...[
              const SizedBox(height: 20.0),
              const VOrDivider(),
              const SizedBox(height: 16.0),
              VButton(
                label: 'Sign in to existing workspace',
                kind: VButtonKind.tonal,
                fullWidth: true,
                onPressed: () => context.pushNamed(kSignInRoute),
              ),
            ] else ...[
              const SizedBox(height: 12.0),
              Center(
                child: VButton(
                  label: '← Back',
                  kind: VButtonKind.link,
                  size: VButtonSize.sm,
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(kSignUp1Route);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
