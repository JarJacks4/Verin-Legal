// Route entry points for the Verin UI. lib/flutter_flow/nav/nav.dart points
// each existing route name at one of these.

import 'package:flutter/material.dart';

import '/backend/backend.dart';

import 'admin/admin_billing.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_program.dart';
import 'admin/admin_settings.dart';
import 'admin/admin_shell.dart';
import 'admin/admin_team.dart';
import 'annotations/annotations_screen.dart';
import 'auth/auth_screens.dart';
import 'matter/matter_detail_screen.dart';
import 'matters/matters_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'review/review_screen.dart';
import 'shell/app_shell.dart';
import 'shell/firm_gate.dart';

class VWelcomePage extends StatelessWidget {
  const VWelcomePage({super.key});
  @override
  Widget build(BuildContext context) => const WelcomeView();
}

class VSignInPage extends StatelessWidget {
  const VSignInPage({super.key});
  @override
  Widget build(BuildContext context) => const SignInView();
}

class VSignUpPage extends StatelessWidget {
  const VSignUpPage({super.key, required this.step, this.invite = ''});
  final int step;
  final String invite;
  @override
  Widget build(BuildContext context) => SignUpView(step: step, invite: invite);
}

class VMattersPage extends StatelessWidget {
  const VMattersPage({super.key});
  @override
  Widget build(BuildContext context) => const FirmGate(child: AppShell(nav: ConsoleNav.matters, child: MattersScreen()));
}

class VOnboardingPage extends StatelessWidget {
  const VOnboardingPage({super.key});
  @override
  Widget build(BuildContext context) => const FirmGate(child: OnboardingScreen());
}

class VAnnotationsPage extends StatelessWidget {
  const VAnnotationsPage({super.key});
  @override
  Widget build(BuildContext context) => const FirmGate(child: AppShell(nav: ConsoleNav.annotations, child: AnnotationsScreen()));
}

class VReviewPage extends StatelessWidget {
  const VReviewPage({super.key});
  @override
  Widget build(BuildContext context) => const FirmGate(child: AppShell(nav: ConsoleNav.review, child: ReviewScreen()));
}

class VMatterPage extends StatelessWidget {
  const VMatterPage({super.key, required this.matter, this.fromAdmin = false, this.initialTab = ''});
  final MattersRecord? matter;
  final bool fromAdmin;
  final String initialTab;
  @override
  Widget build(BuildContext context) {
    if (fromAdmin) {
      return FirmGate(
        child: AdminShell(
        nav: AdminNav.matters,
          builder: (context, user, firm) => MatterDetailScreen(key: ValueKey(matter?.reference.path), matter: matter, admin: true, initialTab: initialTab),
        ),
      );
    }
    return FirmGate(
      child: AppShell(
        nav: ConsoleNav.matters,
        child: MatterDetailScreen(key: ValueKey(matter?.reference.path), matter: matter, initialTab: initialTab),
      ),
    );
  }
}

class VAdminPage extends StatelessWidget {
  const VAdminPage({super.key, required this.nav});
  final AdminNav nav;
  @override
  Widget build(BuildContext context) {
    return FirmGate(
      child: AdminShell(
      nav: nav,
      builder: (context, user, firm) => switch (nav) {
        AdminNav.dashboard => AdminDashboard(user: user, firm: firm),
        AdminNav.matters => const MattersScreen(admin: true),
        AdminNav.billing => AdminBilling(firm: firm),
        AdminNav.team => AdminTeam(firm: firm, user: user),
        AdminNav.program => AdminProgram(firm: firm, user: user),
        AdminNav.settings => AdminSettings(key: ValueKey(firm?.reference.path ?? 'no-firm'), firm: firm, user: user),
      },
      ),
    );
  }
}
