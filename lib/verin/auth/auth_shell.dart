// Verin Legal — shared layout for the signed-out pages (Welcome, Create
// account steps 1–2, Sign in). Brand panel on the left (hidden on narrow
// screens), form on the right. The form side always scrolls, so nothing is
// cut off on short windows or phones.

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Details collected on Create account step 1, carried to step 2.
class SignupDraft {
  static String fullName = '';
  static String firmName = '';
  static String role = '';

  static bool get isComplete =>
      fullName.trim().isNotEmpty && firmName.trim().isNotEmpty && role.trim().isNotEmpty;

  static void clear() {
    fullName = '';
    firmName = '';
    role = '';
  }
}

class VerinAuthShell extends StatelessWidget {
  const VerinAuthShell({
    super.key,
    required this.child,
    this.maxFormWidth = 440.0,
  });

  final Widget child;
  final double maxFormWidth;

  static const Color _panel = Color(0xFF083F49);

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: t.secondaryBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900.0;
              final form = LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 48.0 : 20.0,
                          vertical: 40.0,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxFormWidth),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              if (!wide) {
                return Container(color: t.secondaryBackground, child: form);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(25.0),
                          bottomRight: Radius.circular(25.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(32.0),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/AuthLeftPanel.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(color: t.secondaryBackground, child: form),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Makes a FlutterFlow display-only button (Button19 etc.) tappable.
class VerinTap extends StatelessWidget {
  const VerinTap({super.key, required this.onTap, required this.child, this.enabled = true});

  final VoidCallback? onTap;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled && onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: child,
      ),
    );
  }
}

/// Inline error line used under auth forms.
class VerinAuthError extends StatelessWidget {
  const VerinAuthError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m == null || m.isEmpty) return const SizedBox.shrink();
    final t = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: t.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: t.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18.0, color: t.error),
          const SizedBox(width: 8.0),
          Expanded(child: Text(m, style: t.bodySmall.copyWith(color: t.error))),
        ],
      ),
    );
  }
}

/// Human message for a Firebase Auth error code.
String authErrorMessage(String code, [String? fallback]) {
  switch (code) {
    case 'invalid-email':
      return 'That email address doesn\'t look right.';
    case 'user-disabled':
      return 'This account has been disabled. Contact your firm administrator.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return 'Email or password is incorrect.';
    case 'email-already-in-use':
      return 'An account already exists for that email. Sign in instead.';
    case 'weak-password':
      return 'Choose a stronger password (at least 8 characters).';
    case 'operation-not-allowed':
      return 'Email/password sign-in is not enabled for this workspace yet. '
          'In Firebase Console → Authentication → Sign-in method, enable Email/Password.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a minute and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    default:
      return fallback ?? 'Something went wrong ($code). Please try again.';
  }
}

final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool looksLikeEmail(String s) => _emailRe.hasMatch(s.trim());
