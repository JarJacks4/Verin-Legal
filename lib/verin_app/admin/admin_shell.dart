// Admin console shell — the Make's <AdminPortal> sidebar (dark brand panel)
// and the admin-only gate.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../data/model.dart';
import '../shell/app_shell.dart' show showProfileDrawer;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/motion.dart';
import '../onboarding/tour.dart';
import '../shell/demo_banner.dart';
import '../shell/help.dart' show SystemStatusBanner;
import '../onboarding/tours.dart';

enum AdminNav { dashboard, matters, billing, team, program, settings }

const _adminRoutes = {
  AdminNav.dashboard: 'AdminDashBoardPage',
  AdminNav.matters: 'AdminMattersList',
  AdminNav.billing: 'AdminBillingAndPlan',
  AdminNav.team: 'AdminTeams',
  AdminNav.program: 'AdminProgramPage',
  AdminNav.settings: 'FirmSettings',
};

String adminRoute(AdminNav n) => _adminRoutes[n]!;

/// Years since the firm joined, counting the current one ("Year 2").
int programYear(FirmAccountRecord? f) {
  final since = f?.memberSince;
  if (since == null) return 1;
  final days = DateTime.now().difference(since).inDays;
  return days < 0 ? 1 : (days ~/ 365) + 1;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.nav, required this.builder});

  final AdminNav nav;
  final Widget Function(BuildContext context, VUser user, FirmAccountRecord? firm) builder;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final Stream<UsersRecord?> _user = currentUserStream();
  late final Stream<FirmAccountRecord?> _firm = firmAccountStream();

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<UsersRecord?>(
      stream: _user,
      builder: (context, us) {
        final rec = us.data ?? currentUserDocument;
        final user = VUser.fromRecord(rec);
        return StreamBuilder<FirmAccountRecord?>(
          stream: _firm,
          builder: (context, fs) {
            final firm = fs.data;
            if (fs.connectionState != ConnectionState.waiting) DemoMode.update(firm);
            final waiting = rec == null && us.connectionState == ConnectionState.waiting;
            final Widget body;
            if (waiting) {
              body = const VLoading();
            } else if (!user.isAdmin) {
              body = const _NoAccess();
            } else {
              body = TourLauncher(
                key: ValueKey<String>('admin-tour-${widget.nav.name}'),
                tourId: 'admin_${widget.nav.name}',
                enabled: adminTours.containsKey(widget.nav.name),
                steps: adminTours[widget.nav.name] ?? const <TourStep>[],
                child: TourTarget(id: 'admin_body', child: widget.builder(context, user, firm)),
              );
            }
            final sidebar = AdminSidebar(nav: widget.nav, user: user, firm: firm);
            return LayoutBuilder(builder: (context, box) {
              final narrow = box.maxWidth < 900.0;
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: c.background,
                appBar: isDemoFirm(firm)
                    ? PreferredSize(preferredSize: const Size.fromHeight(34.0), child: DemoBanner(firm: firm, user: user))
                    : null,
                drawer: narrow ? Drawer(width: 270.0, backgroundColor: c.panel, child: sidebar) : null,
                body: SafeArea(
                  child: narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: c.panel,
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.menu, color: c.paper),
                                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                  ),
                                  const VWordmark(size: 20.0, onDark: true, anchor: true),
                                ],
                              ),
                            ),
                            const SystemStatusBanner(),
                            Expanded(child: body),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StillHero(tag: 'admin-sidebar', child: sidebar),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const SystemStatusBanner(), Expanded(child: body)])),
                          ],
                        ),
                ),
              );
            });
          },
        );
      },
    );
  }
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.nav, required this.user, this.firm});

  final AdminNav nav;
  final VUser user;
  final FirmAccountRecord? firm;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    const items = [
      (AdminNav.dashboard, Icons.dashboard_outlined, 'Dashboard'),
      (AdminNav.matters, Icons.folder_open_outlined, 'Matters'),
      (AdminNav.billing, Icons.credit_card, 'Billing & Plan'),
      (AdminNav.team, Icons.group_outlined, 'Team'),
      (AdminNav.program, Icons.emoji_events_outlined, 'Program'),
      (AdminNav.settings, Icons.settings_outlined, 'Settings'),
    ];
    final plan = firm?.planName ?? '';
    return Container(
      width: 260.0,
      color: c.panel,
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VHover(
            onTap: () => context.goNamed('MattersList'),
            builder: (context, hovered) => Opacity(
              opacity: hovered ? 1.0 : 0.7,
              child: Row(
                children: [
                  Icon(Icons.arrow_back, size: 13.0, color: c.onPanel),
                  const SizedBox(width: 8.0),
                  Text('Back to firm console', style: VT.body(context, size: 12.0, color: c.onPanel)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VWordmark(size: 22.0, onDark: true, anchor: true),
                const SizedBox(height: 6.0),
                Opacity(
                  opacity: 0.7,
                  child: Text('ADMIN CONSOLE', style: VT.eyebrow(context, size: 10.0, color: c.onPanel, spacing: 0.18)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          if (plan.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(VR.xl)),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14.0, color: Color(0xFFF4C842)),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text('$plan · Year ${programYear(firm)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 11.0, weight: FontWeight.w600, color: c.onPanel)),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16.0),
          Expanded(
            child: SingleChildScrollView(
              child: TourTarget(
                id: 'admin_nav',
                child: Column(
                children: [
                  for (final (id, icon, label) in items)
                    TourTarget(
                      id: 'admin_nav_${id.name}',
                      child: Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: VHover(
                        onTap: () => context.goNamed(adminRoute(id)),
                        builder: (context, hovered) {
                          final on = id == nav;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: on ? Colors.white.withValues(alpha: 0.14) : (hovered ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
                              borderRadius: BorderRadius.circular(VR.xl),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 16.0, color: on ? c.paper : c.onPanelA(0.65)),
                                const SizedBox(width: 12.0),
                                Text(label,
                                    style: VT.body(context, size: 13.5, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? c.paper : c.onPanelA(0.65))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    ),
                ],
              ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 16.0),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0.0, 0.0, 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text('Appearance', style: VT.body(context, size: 11.0, color: c.onPanelA(0.55)))),
                      const VThemeToggle(style: VThemeToggleStyle.onPanel),
                    ],
                  ),
                ),
                VHover(
                  onTap: () => showProfileDrawer(context, user: user, firm: firm),
                  builder: (context, hovered) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: hovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
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
                              Text(user.name.isEmpty ? user.email : user.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: c.onPanel)),
                              Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 10.0, color: c.onPanelA(0.55))),
                            ],
                          ),
                        ),
                        Icon(Icons.expand_more, size: 13.0, color: c.onPanelA(0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440.0),
          child: VCard(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VIconCircle(icon: Icons.lock_outline, size: 48.0, iconSize: 22.0),
                const SizedBox(height: 16.0),
                Text('Admin access required', style: VT.h3(context)),
                const SizedBox(height: 8.0),
                Text(
                  "The admin console is for firm admins and owners. Ask an admin to change your role to Admin.",
                  textAlign: TextAlign.center,
                  style: VT.muted(context),
                ),
                const SizedBox(height: 20.0),
                VButton(label: 'Back to matters', icon: Icons.arrow_back, kind: VButtonKind.tonal, onPressed: () => context.goNamed('MattersList')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page frame used by admin pages: padding + max width.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.child, this.maxWidth = 920.0});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: vPagePadding(context, top: 32.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      ),
    );
  }
}
