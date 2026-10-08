// Two-step sign-in with an authenticator app (TOTP) — checklist #31.
//
//   TwoStepCard        profile drawer: turn it on (QR code + 6-digit check)
//                      or off.
//   TwoStepRequired    shown instead of the app when the firm requires
//                      two-step sign-in and this account has not set it up.
//   askTwoStepCode     the code prompt during sign-in (verinSignIn hands the
//                      pending sign-in over through PendingTwoStep).
//
// Needs Firebase Authentication upgraded to Identity Platform with TOTP
// multi-factor enabled (DEPLOYMENT.md → "Two-step sign-in").

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

/// The sign-in waiting for a second step, set by verinSignIn.
class PendingTwoStep {
  static MultiFactorResolver? resolver;
}

/// Message verinSignIn returns when a code is needed.
const kTwoStepNeeded = '__two_step_needed__';

Future<bool> hasTwoStep() async {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) return false;
  try {
    return (await u.multiFactor.getEnrolledFactors()).isNotEmpty;
  } catch (_) {
    return false;
  }
}

String _authMessage(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-verification-code':
      case 'invalid-credential':
        return "That code didn't match. Use the current 6-digit code from your authenticator app.";
      case 'requires-recent-login':
        return 'For your security, sign out and sign in again, then turn on two-step sign-in.';
      case 'operation-not-allowed':
        return 'Two-step sign-in is not switched on for Verin yet. Ask your Verin contact to enable it.';
      default:
        return e.message ?? 'That did not work (${e.code}).';
    }
  }
  return '$e';
}

/// During sign-in: asks for the code and finishes signing in. Returns null on
/// success or a message to show.
Future<String?> askTwoStepCode(BuildContext context) async {
  final resolver = PendingTwoStep.resolver;
  if (resolver == null) return 'Sign in again.';
  final hint = resolver.hints.isEmpty ? null : resolver.hints.first;
  if (hint == null) return 'This account has no second step set up. Contact your firm admin.';
  final code = TextEditingController();
  String? error;
  var busy = false;
  final ok = await showVDialog<bool>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        Future<void> submit() async {
          if (busy) return;
          setLocal(() {
            busy = true;
            error = null;
          });
          try {
            final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(hint.uid, code.text.trim());
            await resolver.resolveSignIn(assertion);
            if (ctx.mounted) Navigator.of(ctx).pop(true);
          } catch (e) {
            setLocal(() {
              busy = false;
              error = _authMessage(e);
            });
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Two-step sign-in', style: VT.h2(ctx, size: 18.0)),
            const SizedBox(height: 8.0),
            Text('Enter the 6-digit code from your authenticator app.', style: VT.muted(ctx, size: 13.0)),
            const SizedBox(height: 14.0),
            VTextField(controller: code, label: 'Code', hint: '123456', keyboardType: TextInputType.number, onSubmitted: (_) => submit()),
            if (error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: error!)],
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VButton(label: 'Cancel', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
                const SizedBox(width: 8.0),
                VButton(label: 'Verify', loading: busy, onPressed: submit),
              ],
            ),
          ],
        );
      },
    ),
  );
  code.dispose();
  PendingTwoStep.resolver = null;
  return ok == true ? null : 'Sign-in cancelled.';
}

/// Turn two-step sign-in on: secret → QR code → first code.
Future<bool> enrollTwoStep(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  TotpSecret secret;
  String url;
  try {
    final session = await user.multiFactor.getSession();
    secret = await TotpMultiFactorGenerator.generateSecret(session);
    url = await secret.generateQrCodeUrl(accountName: user.email ?? 'Verin account', issuer: 'Verin Legal');
  } catch (e) {
    if (context.mounted) showVToast(context, 'Two-step sign-in could not start', error: true, description: _authMessage(e));
    return false;
  }
  if (!context.mounted) return false;
  final code = TextEditingController();
  final done = await showVDialog<bool>(
    context,
    maxWidth: 480.0,
    builder: (ctx) {
      String? error;
      var busy = false;
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final c = VC.of(ctx);
          Future<void> verify() async {
            if (busy) return;
            setLocal(() {
              busy = true;
              error = null;
            });
            try {
              final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(secret, code.text.trim());
              await user.multiFactor.enroll(assertion, displayName: 'Authenticator app');
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            } catch (e) {
              setLocal(() {
                busy = false;
                error = _authMessage(e);
              });
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Turn on two-step sign-in', style: VT.h2(ctx, size: 18.0)),
              const SizedBox(height: 8.0),
              Text(
                'Scan this with an authenticator app (Google Authenticator, Microsoft Authenticator, 1Password…), then enter the 6-digit code it shows.',
                style: VT.muted(ctx, size: 13.0),
              ),
              const SizedBox(height: 14.0),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  color: Colors.white,
                  child: QrImageView(data: url, size: 180.0, backgroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 10.0),
              Text("Can't scan? Enter this key in the app:", style: VT.muted(ctx, size: 12.0)),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Expanded(child: SelectableText(secret.secretKey, style: VT.mono(ctx, size: 13.0, color: c.foreground))),
                  IconButton(
                    tooltip: 'Copy key',
                    icon: Icon(Icons.copy, size: 16.0, color: c.mutedFg),
                    onPressed: () => Clipboard.setData(ClipboardData(text: secret.secretKey)),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              VTextField(controller: code, label: 'Code from the app', hint: '123456', keyboardType: TextInputType.number, onSubmitted: (_) => verify()),
              if (error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: error!)],
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VButton(label: 'Cancel', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
                  const SizedBox(width: 8.0),
                  VButton(label: 'Turn on', loading: busy, onPressed: verify),
                ],
              ),
            ],
          );
        },
      );
    },
  );
  code.dispose();
  if (done == true && context.mounted) celebrate(context, title: 'Two-step sign-in is on', subtitle: "You'll enter a code from your app when you sign in.");
  return done == true;
}

class TwoStepCard extends StatefulWidget {
  const TwoStepCard({super.key});

  @override
  State<TwoStepCard> createState() => _TwoStepCardState();
}

class _TwoStepCardState extends State<TwoStepCard> {
  bool? _on;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await hasTwoStep();
    if (mounted) setState(() => _on = on);
  }

  Future<void> _turnOff() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final factors = await user.multiFactor.getEnrolledFactors();
      for (final f in factors) {
        await user.multiFactor.unenroll(factorUid: f.uid);
      }
      if (mounted) showVToast(context, 'Two-step sign-in is off');
    } catch (e) {
      if (mounted) showVToast(context, 'Could not turn it off', error: true, description: _authMessage(e));
    }
    if (mounted) setState(() => _busy = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final on = _on == true;
    return VPanel(
      child: Row(
        children: [
          Icon(on ? Icons.verified_user_outlined : Icons.lock_outline, size: 18.0, color: on ? c.verified : c.mutedFg),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Two-step sign-in', style: VT.body(context, size: 13.5, weight: FontWeight.w600)),
                Text(on ? 'On — a code from your authenticator app is needed to sign in.' : 'Off — add a code from an authenticator app to every sign-in.', style: VT.muted(context, size: 12.0)),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          VButton(
            label: on ? 'Turn off' : 'Turn on',
            size: VButtonSize.sm,
            kind: on ? VButtonKind.secondary : VButtonKind.tonal,
            loading: _busy || _on == null,
            onPressed: () async {
              if (on) {
                await _turnOff();
              } else {
                await enrollTwoStep(context);
                await _load();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Full-screen prompt when the firm requires two-step sign-in.
class TwoStepRequired extends StatelessWidget {
  const TwoStepRequired({super.key, required this.onDone, required this.onSignOut});

  final VoidCallback onDone;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: VCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VIconCircle(icon: Icons.verified_user_outlined),
                const SizedBox(height: 14.0),
                Text('Your firm requires two-step sign-in', style: VT.h2(context, size: 20.0)),
                const SizedBox(height: 8.0),
                Text('Set up an authenticator app once. After that, signing in asks for a 6-digit code from it.', style: VT.muted(context, size: 13.5)),
                const SizedBox(height: 18.0),
                VButton(
                  label: 'Set it up now',
                  icon: Icons.qr_code_2,
                  fullWidth: true,
                  onPressed: () async {
                    if (await enrollTwoStep(context)) onDone();
                  },
                ),
                const SizedBox(height: 8.0),
                VButton(label: 'Sign out', kind: VButtonKind.link, onPressed: onSignOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
