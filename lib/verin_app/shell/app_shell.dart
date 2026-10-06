// Firm console shell — the Make's Sidebar + <main>, and the Profile drawer.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/auth/auth_shell.dart' show authErrorMessage;
import '/verin/verin_api.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import '../widgets/motion.dart';
import '../onboarding/tour.dart';
import 'demo_banner.dart';

enum ConsoleNav { matters, review, annotations }

const kMattersRoute = 'MattersList';
const kReviewRoute = 'ReviewQueue';
const kAnnotationsRoute = 'Annotations';
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
            if (firmSnap.connectionState != ConnectionState.waiting) DemoMode.update(firmSnap.data);
            final sidebar = ConsoleSidebar(nav: widget.nav, user: user, firm: firmSnap.data);
            return LayoutBuilder(
              builder: (context, box) {
                final narrow = box.maxWidth < 900.0;
                return Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: c.background,
                  appBar: isDemoFirm(firmSnap.data)
                      ? PreferredSize(preferredSize: const Size.fromHeight(34.0), child: DemoBanner(firm: firmSnap.data, user: user))
                      : null,
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
                                    const VWordmark(size: 20.0, anchor: true),
                                  ],
                                ),
                              ),
                              Expanded(child: widget.child),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StillHero(tag: 'console-sidebar', child: sidebar),
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
        child: TourTarget(
          id: 'nav_${id.name}',
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
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Align(alignment: Alignment.centerLeft, child: VWordmark(size: 24.0, anchor: true))),
          const SizedBox(height: 32.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  item(ConsoleNav.matters, Icons.folder_open_outlined, 'Matters', kMattersRoute),
                  item(ConsoleNav.review, Icons.checklist, 'Review queue', kReviewRoute),
                  item(ConsoleNav.annotations, Icons.comment_outlined, 'Annotations', kAnnotationsRoute),
                  if (user.isAdmin) ...[
                    const SizedBox(height: 20.0),
                    const VHairline(),
                    const SizedBox(height: 24.0),
                    TourTarget(
                      id: 'nav_admin',
                      child: VHover(
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
                    ),
                  ],
                ],
              ),
            ),
          ),
          const VThemeToggle(style: VThemeToggleStyle.row),
          const SizedBox(height: 4.0),
          TourTarget(
            id: 'nav_profile',
            child: VHover(
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

class ProfileDrawerBody extends StatefulWidget {
  const ProfileDrawerBody({super.key, required this.user, this.firm});

  /// What the opening screen had; replaced by live data as soon as it loads.
  final VUser user;
  final FirmAccountRecord? firm;

  @override
  State<ProfileDrawerBody> createState() => _ProfileDrawerBodyState();
}

class _ProfileDrawerBodyState extends State<ProfileDrawerBody> {
  late final Stream<UsersRecord?> _user = currentUserStream();
  late final Stream<FirmAccountRecord?> _firm = firmAccountStream();
  late final Stream<Map<String, dynamic>> _intg = integrationStatusStream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsersRecord?>(
      stream: _user,
      builder: (context, us) => StreamBuilder<FirmAccountRecord?>(
        stream: _firm,
        builder: (context, fs) => StreamBuilder<Map<String, dynamic>>(
          stream: _intg,
          builder: (context, snap) => _body(
            context,
            us.data != null ? VUser.fromRecord(us.data) : widget.user,
            fs.data ?? widget.firm,
            snap.data?['clioConnected'] == true,
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, VUser user, FirmAccountRecord? firm, bool clio) {
    final c = VC.of(context);
    final firmName = (firm?.firmName.isNotEmpty ?? false) ? firm!.firmName : user.firm;
    final plan = (firm?.planName.isNotEmpty ?? false) ? firm!.planName : '—';
    final roleLabel = user.roleLabel;
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
              if (roleLabel.isNotEmpty || user.isAdmin) ...[
                const SizedBox(height: 10.0),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: [
                    if (roleLabel.isNotEmpty) VBadge(label: roleLabel, icon: Icons.work_outline, bg: c.tealPale, fg: c.tealDeep, bold: true),
                    if (user.isAdmin && roleLabel.toLowerCase() != user.role.toLowerCase())
                      VBadge(label: 'Admin', icon: Icons.shield_outlined, bg: c.secondary, fg: c.tealDeep, bold: true),
                  ],
                ),
              ],
            ],
          ),
        ),
        _ProfileRow(label: 'Firm', value: firmName.isEmpty ? '—' : firmName, icon: Icons.apartment_outlined),
        _ProfileRow(label: 'Role', value: roleLabel.isEmpty ? '—' : roleLabel, icon: Icons.work_outline),
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
        TourTarget(
          id: 'profile_replay',
          child: VButton(
          label: 'Replay the walkthrough',
          icon: Icons.slideshow_outlined,
          kind: VButtonKind.tonal,
          fullWidth: true,
          onPressed: () async {
            final nav = Navigator.of(context);
            final router = GoRouter.of(context);
            TourProgress.reset();
            nav.pop();
            router.goNamed('GettingStarted');
          },
        ),
        ),
        const SizedBox(height: 12.0),
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
        const SizedBox(height: 12.0),
        Center(
          child: VButton(
            label: 'Delete account',
            kind: VButtonKind.link,
            size: VButtonSize.sm,
            onPressed: () => _confirmDelete(context, firmName),
          ),
        ),
        const SizedBox(height: 12.0),
        Text('Verin Evidence Record · v1.0', textAlign: TextAlign.center, style: VT.muted(context, size: 11.0)),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String firmName) async {
    final router = GoRouter.of(context);
    final nav = Navigator.of(context);
    final deleted = await showVDialog<bool>(context, builder: (ctx) => _DeleteAccountForm(firmName: firmName));
    if (deleted != true) return;
    nav.pop(); // close the profile drawer
    router.prepareAuthEvent();
    try {
      await authManager.signOut();
    } catch (_) {/* the account is already gone */}
    router.clearRedirectLocation();
    router.goNamed(kSignInRouteName);
  }
}

class _DeleteAccountForm extends StatefulWidget {
  const _DeleteAccountForm({required this.firmName});

  final String firmName;

  @override
  State<_DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<_DeleteAccountForm> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    if (user == null || email.isEmpty) {
      setState(() => _error = 'Sign in again, then try deleting your account.');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: _password.text));
      await user.getIdToken(true);
      await VerinApi.deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = authErrorMessage(e.code, e.message);
        });
      }
    } on VerinApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firm = widget.firmName.isEmpty ? 'your firm' : widget.firmName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Delete your account?', style: VT.body(context, size: 16.0, weight: FontWeight.w600)),
        const SizedBox(height: 8.0),
        Text(
          'This removes your sign-in and profile, and takes you off $firm\'s team list. It can\'t be undone.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Matters, evidence and annotations belong to the firm and stay in its record — deleting your account doesn\'t delete them.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 16.0),
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 12.0)],
        VTextField(
          controller: _password,
          label: 'Password',
          hint: '••••••••',
          obscure: true,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _delete(),
        ),
        const SizedBox(height: 20.0),
        Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Cancel',
                kind: VButtonKind.secondary,
                fullWidth: true,
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: VButton(
                label: 'Delete account',
                loadingLabel: 'Deleting…',
                kind: VButtonKind.danger,
                fullWidth: true,
                loading: _busy,
                onPressed: _delete,
              ),
            ),
          ],
        ),
      ],
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
