// Team — the Make's <AdminTeam> and <InviteDrawer> over TeamMembers.
// Invitation emails aren't connected yet, so the invite gives the admin a
// sign-up link to send themselves.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import 'admin_shell.dart';

String signUpLink() {
  final base = Uri.base;
  return '${base.scheme}://${base.host}${base.hasPort && base.port != 80 && base.port != 443 ? ':${base.port}' : ''}/createAccountStep1';
}

String initialsOf(String name, String email) => VUser(name: name, email: email, firm: '', role: '').initials;

class AdminTeam extends StatefulWidget {
  const AdminTeam({super.key, required this.firm, required this.user});

  final FirmAccountRecord? firm;
  final VUser user;

  @override
  State<AdminTeam> createState() => _AdminTeamState();
}

class _AdminTeamState extends State<AdminTeam> {
  late final Stream<List<TeamMembersRecord>> _team = queryTeamMembersRecord();

  Future<void> _remove(TeamMembersRecord m) async {
    final who = m.name.isNotEmpty ? m.name : m.email;
    final ok = await showVDialog<bool>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Remove $who?', style: VT.body(ctx, size: 16.0, weight: FontWeight.w600)),
          const SizedBox(height: 8.0),
          Text(
            m.status.toLowerCase() == 'invited'
                ? 'The invitation is withdrawn.'
                : 'They lose their seat on the team list. To also block sign-in, disable their account in Firebase Authentication.',
            style: VT.muted(ctx, size: 13.0),
          ),
          const SizedBox(height: 20.0),
          Row(
            children: [
              Expanded(child: VButton(label: 'Cancel', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => Navigator.of(ctx).pop(false))),
              const SizedBox(width: 12.0),
              Expanded(
                child: VButton(label: 'Remove', kind: VButtonKind.danger, fullWidth: true, onPressed: () => Navigator.of(ctx).pop(true)),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await m.reference.delete();
      if (mounted) showVToast(context, '$who removed');
    } catch (e) {
      if (mounted) showVToast(context, 'Could not remove: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final seats = (widget.firm?.seatLimit ?? 0) > 0 ? widget.firm!.seatLimit : 10;
    return StreamBuilder<List<TeamMembersRecord>>(
      stream: _team,
      builder: (context, snap) {
        final all = snap.data ?? const <TeamMembersRecord>[];
        final firmRef = widget.firm?.reference;
        final team = all.where((m) => firmRef == null || m.firmAccountI == null || m.firmAccountI == firmRef).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        final active = team.where((m) => m.status.toLowerCase() == 'active').length;
        final used = team.where((m) => m.status.toLowerCase() != 'suspended').length;

        return AdminPage(
          maxWidth: 720.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                runSpacing: 12.0,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team', style: VT.h1(context, size: 28.0)),
                      const SizedBox(height: 4.0),
                      Text('$active active · ${(seats - used).clamp(0, seats)} seats remaining on your plan', style: VT.muted(context)),
                    ],
                  ),
                  VButton(
                    label: 'Invite member',
                    icon: Icons.person_add_alt_outlined,
                    size: VButtonSize.sm,
                    onPressed: () => showVDrawer<void>(
                      context,
                      title: 'Invite team member',
                      width: 440.0,
                      builder: (_) => InviteForm(firm: widget.firm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),
              VCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Seat usage', style: VT.body(context, size: 13.0, weight: FontWeight.w500))),
                        Text('$used / $seats', style: VT.muted(context, size: 13.0)),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: LinearProgressIndicator(value: seats == 0 ? 0 : (used / seats).clamp(0.0, 1.0).toDouble(), minHeight: 8.0, color: c.teal, backgroundColor: c.secondary),
                    ),
                    const SizedBox(height: 8.0),
                    Text('Your plan includes $seats seats. Contact Verin to increase.', style: VT.muted(context, size: 11.0)),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              VCard(
                padding: EdgeInsets.zero,
                clip: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!snap.hasData) const VLoading(),
                    if (snap.hasData && team.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('No team members yet. Invite your attorneys and paralegals.', style: VT.muted(context, size: 13.0)),
                      ),
                    for (var i = 0; i < team.length; i++) _memberRow(context, team[i], i),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _memberRow(BuildContext context, TeamMembersRecord m, int i) {
    final c = VC.of(context);
    final s = m.status.toLowerCase();
    final expired = m.inviteExpired;
    final (Color bg, Color fg) = s == 'active'
        ? (c.verified.withValues(alpha: 0.1), c.verified)
        : s == 'invited'
            ? (c.pending.withValues(alpha: 0.1), c.pending)
            : (c.broken.withValues(alpha: 0.1), c.broken);
    final isMe = m.email.toLowerCase() == currentUserEmail.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
      child: Row(
        children: [
          VAvatar(initials: initialsOf(m.name, m.email), size: 36.0, muted: s == 'invited'),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name.isEmpty ? m.email : m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, weight: FontWeight.w500)),
                Text(m.email, style: VT.muted(context, size: 12.0)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(m.role.isEmpty ? '—' : m.role, style: VT.body(context, size: 12.0, weight: FontWeight.w500)),
              const SizedBox(height: 2.0),
              VBadge(label: expired ? 'invite expired' : (s.isEmpty ? '—' : s), bg: bg, fg: fg),
            ],
          ),
          if (!isMe) ...[
            const SizedBox(width: 8.0),
            VHover(
              onTap: () => _remove(m),
              builder: (context, hovered) => Opacity(
                opacity: hovered ? 1.0 : 0.4,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('Remove', style: VT.body(context, size: 12.0, color: c.broken)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InviteForm extends StatefulWidget {
  const InviteForm({super.key, this.firm});

  final FirmAccountRecord? firm;

  @override
  State<InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<InviteForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _role = 'Paralegal';
  bool _saving = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter their name and work email.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await TeamMembersRecord.collection.doc().set({
        ...createTeamMembersRecordData(
          firmAccountI: widget.firm?.reference,
          name: name,
          email: email,
          role: _role,
          status: 'invited',
          invitedAt: DateTime.now(),
        ),
        'expiresAt': DateTime.now().add(const Duration(hours: 72)),
        'invitedByUid': currentUserUid,
      });
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save the invitation: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final link = signUpLink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VSuccessState(title: 'Invitation recorded', desc: '${_name.text.trim()} is on your team list. Send them this link to create their account with ${_email.text.trim()}:'),
          VPanel(child: SelectableText(link, style: VT.mono(context, size: 12.0))),
          const SizedBox(height: 12.0),
          VButton(label: 'Copy link', icon: Icons.content_copy, fullWidth: true, onPressed: () => copyToClipboard(context, link, what: 'Sign-up link copied')),
          const SizedBox(height: 8.0),
          Text("Invitation emails aren't connected yet, so Verin doesn't send this for you. The invite stays open for 72 hours.",
              textAlign: TextAlign.center, style: VT.muted(context, size: 11.0)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add them to your team, then send them the sign-up link. The invitation expires in 72 hours.', style: VT.muted(context)),
        const SizedBox(height: 24.0),
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 16.0)],
        VTextField(controller: _name, label: 'Full name', hint: 'Jane Smith'),
        const SizedBox(height: 16.0),
        VTextField(controller: _email, label: 'Work email', hint: 'j.smith@yourfirm.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16.0),
        VSegmented<String>(
          label: 'Role',
          value: _role,
          options: const ['Paralegal', 'Attorney', 'Admin'],
          labelFor: (r) => r,
          fontSize: 12.0,
          onChanged: (r) => setState(() => _role = r),
        ),
        const SizedBox(height: 24.0),
        VButton(label: 'Add invitation', icon: Icons.person_add_alt_outlined, size: VButtonSize.lg, fullWidth: true, loading: _saving, onPressed: _invite),
      ],
    );
  }
}
