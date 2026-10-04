// Firm console shell — the Make's Sidebar + <main>, and the Profile drawer.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

enum ConsoleNav { matters, review }

const kMattersRoute = 'MattersList';
const kReviewRoute = 'ReviewQueue';
const kAdminHomeRoute = 'AdminDashBoardPage';
const kSignInRouteName = 'FirmWorkspaceSignIn';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.nav, required this.child});

  final ConsoleNav nav;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final Stream<UsersRecord?> _user = currentUserStream();
  late final Stream<FirmAccountRecord?> _firm = firmAccountStream();

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<UsersRecord?>(
      stream: _user,
      builder: (context, snap) {
        final user = VUser.fromRecord(snap.data ?? currentUserDocument);
        return StreamBuilder<FirmAccountRecord?>(
          stream: _firm,
          builder: (context, firmSnap) {
            final sidebar = ConsoleSidebar(nav: widget.nav, user: user, firm: firmSnap.data);
            return LayoutBuilder(
              builder: (context, box) {
                final narrow = box.maxWidth < 900.0;
                return Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: c.background,
                  drawer: narrow ? Drawer(width: 260.0, backgroundColor: c.card, child: sidebar) : null,
                  body: SafeArea(
                    child: narrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                decoration: BoxDecoration(color: c.card, border: Border(bottom: BorderSide(color: c.border))),
                                child: Row(
                                  children: [
                                    VIconButton(icon: Icons.menu, tooltip: 'Menu', onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                                    const SizedBox(width: 8.0),
                                    const VWordmark(size: 20.0),
                                  ],
                                ),
                              ),
                              Expanded(child: widget.child),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              sidebar,
                              Expanded(child: widget.child),
                            ],
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ConsoleSidebar extends StatelessWidget {
  const ConsoleSidebar({super.key, required this.nav, required this.user, this.firm});

  final ConsoleNav nav;
  final VUser user;
  final FirmAccountRecord? firm;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    Widget item(ConsoleNav id, IconData icon, String label, String route) {
      final on = nav == id;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: VHover(
          onTap: () => context.goNamed(route),
          builder: (context, hovered) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: on ? c.secondary : (hovered ? c.secondary.withValues(alpha: 0.5) : Colors.transparent),
              borderRadius: BorderRadius.circular(VR.xl),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18.0, color: on ? c.tealDeep : c.mutedFg),
                const SizedBox(width: 12.0),
                Text(label, style: VT.body(context, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? c.tealDeep : c.mutedFg)),
              ],
            ),
          ),
        ),
      );
    }

    final firmName = (firm?.firmName.isNotEmpty ?? false) ? firm!.firmName : user.firm;
    final plan = firm?.planName ?? '';

    return Container(
      width: 248.0,
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
      decoration: BoxDecoration(color: c.card, border: Border(right: BorderSide(color: c.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Align(alignment: Alignment.centerLeft, child: VWordmark(size: 24.0))),
          const SizedBox(height: 32.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  item(ConsoleNav.matters, Icons.folder_open_outlined, 'Matters', kMattersRoute),
                  item(ConsoleNav.review, Icons.checklist, 'Review queue', kReviewRoute),
                  if (user.isAdmin) ...[
                    const SizedBox(height: 20.0),
                    const VHairline(),
                    const SizedBox(height: 24.0),
                    VHover(
                      onTap: () => context.goNamed(kAdminHomeRoute),
                      builder: (context, hovered) => Opacity(
                        opacity: hovered ? 0.92 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(VR.xl)),
                          child: Row(
                            children: [
                              Icon(Icons.dashboard_outlined, size: 15.0, color: c.paper),
                              const SizedBox(width: 10.0),
                              Expanded(child: Text('Admin console', style: VT.body(context, size: 13.0, weight: FontWeight.w500, color: c.paper))),
                              if (plan.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                                  child: Text(_shortPlan(plan), style: VT.body(context, size: 10.0, weight: FontWeight.w600, color: c.paper)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const VThemeToggle(style: VThemeToggleStyle.row),
          const SizedBox(height: 4.0),
          VHover(
            onTap: () => showProfileDrawer(context, user: user, firm: firm),
            builder: (context, hovered) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: hovered ? Color.alphaBlend(c.foreground.withValues(alpha: 0.04), c.secondary) : c.secondary,
                borderRadius: BorderRadius.circular(VR.xl),
              ),
              child: Row(
                children: [
                  VAvatar(initials: user.initials, size: 32.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(firmName.isEmpty ? user.name : firmName,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: c.tealDeep)),
                        Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.muted(context, size: 11.0)),
                      ],
                    ),
                  ),
                  Icon(Icons.settings_outlined, size: 14.0, color: c.mutedFg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortPlan(String plan) {
    final p = plan.trim();
    if (p.toLowerCase().contains('annual')) return 'Annual';
    return p.length > 10 ? p.substring(0, 10) : p;
  }
}

// ---------------------------------------------------------------------------
// Profile drawer
// ---------------------------------------------------------------------------

Future<void> showProfileDrawer(BuildContext context, {required VUser user, FirmAccountRecord? firm}) {
  return showVDrawer(context, title: 'Profile', width: 420.0, builder: (ctx) => ProfileDrawerBody(user: user, firm: firm));
}

Future<void> signOutAndLeave(BuildContext context) async {
  final router = GoRouter.of(context);
  router.prepareAuthEvent();
  await authManager.signOut();
  router.clearRedirectLocation();
  router.goNamed(kSignInRouteName);
}

class ProfileDrawerBody extends StatelessWidget {
  const ProfileDrawerBody({super.key, required this.user, this.firm});

  final VUser user;
  final FirmAccountRecord? firm;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final firmName = (firm?.firmName.isNotEmpty ?? false) ? firm!.firmName : user.firm;
    final plan = (firm?.planName.isNotEmpty ?? false) ? firm!.planName : '—';
    return StreamBuilder<Map<String, dynamic>>(
      stream: integrationStatusStream(),
      builder: (context, snap) {
        final clio = snap.data?['clioConnected'] == true;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 28.0),
              margin: const EdgeInsets.only(bottom: 28.0),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
              child: Column(
                children: [
                  VAvatar(initials: user.initials, size: 80.0),
                  const SizedBox(height: 16.0),
                  Text(user.name.isEmpty ? '—' : user.name, textAlign: TextAlign.center, style: VT.h2(context, size: 22.0)),
                  const SizedBox(height: 4.0),
                  Text(user.email, style: VT.muted(context)),
                  if (user.role.isNotEmpty) ...[
                    const SizedBox(height: 10.0),
                    VBadge(label: user.role, icon: Icons.work_outline, bg: c.tealPale, fg: c.tealDeep, bold: true),
                  ],
                ],
              ),
            ),
            _ProfileRow(label: 'Firm', value: firmName.isEmpty ? '—' : firmName, icon: Icons.apartment_outlined),
            _ProfileRow(label: 'Role', value: user.role.isEmpty ? '—' : user.role, icon: Icons.work_outline),
            _ProfileRow(label: 'Email', value: user.email, icon: Icons.mail_outline),
            _ProfileRow(label: 'Plan', value: plan, icon: Icons.bolt_outlined),
            const SizedBox(height: 24.0),
            VPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORKSPACE', style: VT.eyebrow(context)),
                  const SizedBox(height: 8.0),
                  Text('${firmName.isEmpty ? 'Your firm' : firmName} · family-law practice', style: VT.body(context, size: 13.0)),
                  const SizedBox(height: 2.0),
                  Text(
                    clio ? 'Integrations: Clio connected · MyCase and Smokeball coming soon' : 'Integrations: Clio available · MyCase and Smokeball coming soon',
                    style: VT.muted(context, size: 12.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            VButton(
              label: 'Sign out',
              icon: Icons.logout,
              kind: VButtonKind.danger,
              fullWidth: true,
              onPressed: () async {
                final nav = Navigator.of(context);
                final router = GoRouter.of(context);
                nav.pop();
                router.prepareAuthEvent();
                await authManager.signOut();
                router.clearRedirectLocation();
                router.goNamed(kSignInRouteName);
              },
            ),
            const SizedBox(height: 16.0),
            Text('Verin Evidence Record · v1.0', textAlign: TextAlign.center, style: VT.muted(context, size: 11.0)),
          ],
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          Icon(icon, size: 15.0, color: c.mutedFg),
          const SizedBox(width: 12.0),
          SizedBox(width: 56.0, child: Text(label, style: VT.muted(context, size: 12.0))),
          const SizedBox(width: 12.0),
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, weight: FontWeight.w500))),
        ],
      ),
    );
  }
}
