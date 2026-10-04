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
import 'auth/auth_screens.dart';
import 'matter/matter_detail_screen.dart';
import 'matters/matters_screen.dart';
import 'review/review_screen.dart';
import 'shell/app_shell.dart';

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
  const VSignUpPage({super.key, required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => SignUpView(step: step);
}

class VMattersPage extends StatelessWidget {
  const VMattersPage({super.key});
  @override
  Widget build(BuildContext context) => const AppShell(nav: ConsoleNav.matters, child: MattersScreen());
}

class VReviewPage extends StatelessWidget {
  const VReviewPage({super.key});
  @override
  Widget build(BuildContext context) => const AppShell(nav: ConsoleNav.review, child: ReviewScreen());
}

class VMatterPage extends StatelessWidget {
  const VMatterPage({super.key, required this.matter, this.fromAdmin = false});
  final MattersRecord? matter;
  final bool fromAdmin;
  @override
  Widget build(BuildContext context) {
    if (fromAdmin) {
      return AdminShell(
        nav: AdminNav.matters,
        builder: (context, user, firm) => MatterDetailScreen(key: ValueKey(matter?.reference.path), matter: matter, admin: true),
      );
    }
    return AppShell(
      nav: ConsoleNav.matters,
      child: MatterDetailScreen(key: ValueKey(matter?.reference.path), matter: matter),
    );
  }
}

class VAdminPage extends StatelessWidget {
  const VAdminPage({super.key, required this.nav});
  final AdminNav nav;
  @override
  Widget build(BuildContext context) {
    return AdminShell(
      nav: nav,
      builder: (context, user, firm) => switch (nav) {
        AdminNav.dashboard => AdminDashboard(user: user, firm: firm),
        AdminNav.matters => const MattersScreen(admin: true),
        AdminNav.billing => AdminBilling(firm: firm),
        AdminNav.team => AdminTeam(firm: firm, user: user),
        AdminNav.program => AdminProgram(firm: firm, user: user),
        AdminNav.settings => AdminSettings(key: ValueKey(firm?.reference.path ?? 'no-firm'), firm: firm, user: user),
      },
    );
  }
}
