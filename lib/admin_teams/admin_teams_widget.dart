import '/backend/backend.dart';
import '/components/button13_widget.dart';
import '/components/invite_team_drawer_sheet_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/admin/admin_common.dart';
import '/verin/record_ext.dart';
import '/verin/verin_format.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'admin_teams_model.dart';
export 'admin_teams_model.dart';

/// Admin Portal — Team (guide §12d): seat usage against firmAccount.seatLimit,
/// one row per TeamMembers doc with a status pill, invite and remove.
class AdminTeamsWidget extends StatefulWidget {
  const AdminTeamsWidget({super.key});

  static String routeName = 'AdminTeams';
  static String routePath = '/adminTeams';

  @override
  State<AdminTeamsWidget> createState() => _AdminTeamsWidgetState();
}

class _AdminTeamsWidgetState extends State<AdminTeamsWidget> {
  late AdminTeamsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late final Stream<List<TeamMembersRecord>> _membersStream;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminTeamsModel());

    _membersStream = queryTeamMembersRecord();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  bool _isActive(TeamMembersRecord m) =>
      m.status.trim().toLowerCase() == 'active';

  int _statusRank(TeamMembersRecord m) {
    final s = m.status.trim().toLowerCase();
    if (s == 'active') return 0;
    if (s == 'invited' || s == 'pending') return m.inviteExpired ? 2 : 1;
    return 3;
  }

  Future<void> _openInvite(FirmAccountRecord? firm) async {
    final result = await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (sheetContext) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(sheetContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(sheetContext),
            child: InviteTeamDrawerSheetWidget(
              firmAccountRef: firm?.reference,
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (result is String && result.isNotEmpty) {
      showVerinSnack(
        context,
        'Invitation recorded for $result (open for 72 hours). Invite emails aren\'t connected yet, so let them know directly.',
      );
    }
  }

  Future<void> _confirmRemove(TeamMembersRecord m) async {
    final theme = FlutterFlowTheme.of(context);
    final who = m.name.isNotEmpty
        ? m.name
        : (m.email.isNotEmpty ? m.email : 'this member');
    final s = m.status.trim().toLowerCase();
    final isInvite = s == 'invited' || s == 'pending';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isInvite ? 'Cancel invitation?' : 'Remove team member?',
            style: VerinText.section(dialogContext),
          ),
          content: Text(
            isInvite
                ? 'The invitation for $who will be deleted.'
                : '$who will be removed from your team list. This does not delete their sign-in account.',
            style: VerinText.body(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Keep',
                style: VerinText.titleSmall(dialogContext),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                isInvite ? 'Cancel invitation' : 'Remove',
                style: VerinText.titleSmall(dialogContext, color: theme.error),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await m.reference.delete();
      if (!mounted) return;
      showVerinSnack(
          context, isInvite ? 'Invitation cancelled.' : '$who was removed.');
    } catch (e) {
      if (!mounted) return;
      showVerinSnack(context, 'Couldn\'t remove $who. Please try again.',
          error: true);
    }
  }

  Widget _statusPill(BuildContext context, TeamMembersRecord m) {
    final theme = FlutterFlowTheme.of(context);
    final s = m.status.trim().toLowerCase();
    String label;
    Color bg = theme.secondaryBackground;
    Color border = theme.accent3;
    Color fg = theme.accent3;
    String? tip;
    if (s == 'active') {
      label = 'Active';
      bg = theme.success;
      border = theme.alternate;
      fg = theme.onPrimary;
    } else if ((s == 'invited' || s == 'pending') && m.inviteExpired) {
      label = 'Expired';
      border = theme.error;
      fg = theme.error;
      tip = 'Invitation expired ${fmtRelative(m.expiresAt)}';
    } else if (s == 'invited' || s == 'pending') {
      label = 'Invited';
      border = theme.warning;
      fg = theme.warning;
      final exp = m.expiresAt;
      tip = exp == null
          ? 'Invited ${orDash(fmtRelative(m.invitedAt))}'
          : 'Invitation expires ${fmtRelative(exp)}';
    } else if (s == 'suspended') {
      label = 'Suspended';
    } else {
      label = s.isEmpty ? kDash : humanizeStatus(m.status);
    }

    final pill = Container(
      height: 34.0,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: border,
          width: 1.0,
        ),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
        child: Text(
          label,
          style: adminText(theme.labelMedium, AdminFont.plex,
              color: fg, fontSize: 14.0, lineHeight: 1.4),
        ),
      ),
    );
    return tip == null ? pill : Tooltip(message: tip, child: pill);
  }

  Widget _memberRow(BuildContext context, TeamMembersRecord m, bool last) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(24.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: theme.secondary,
                  shape: BoxShape.circle,
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Text(
                  initialsFor(m.name, email: m.email),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: adminText(theme.labelMedium, AdminFont.plex,
                      color: theme.onSecondary,
                      fontSize: 15.2,
                      fontWeight: FontWeight.w600,
                      lineHeight: 1.4),
                  overflow: TextOverflow.clip,
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orDash(m.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: adminText(theme.titleSmall, AdminFont.plex,
                          color: theme.primaryText),
                    ),
                    Text(
                      orDash(m.email),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: adminText(theme.bodySmall, AdminFont.plex,
                          color: theme.secondaryText, lineHeight: 1.4),
                    ),
                  ].divide(SizedBox(height: 4.0)),
                ),
              ),
              Container(
                width: 100.0,
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Text(
                  m.role.trim().isEmpty ? kDash : humanizeStatus(m.role),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: adminText(theme.labelMedium, AdminFont.plex,
                      color: theme.secondaryText, lineHeight: 1.4),
                ),
              ),
              _statusPill(context, m),
              Tooltip(
                message: 'Remove',
                child: FlutterFlowIconButton(
                  borderRadius: 8.0,
                  buttonSize: 40.0,
                  fillColor: Colors.transparent,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.error,
                    size: 20.0,
                  ),
                  onPressed: () async {
                    await _confirmRemove(m);
                  },
                ),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
        if (!last)
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              color: theme.alternate,
              shape: BoxShape.rectangle,
            ),
          ),
      ],
    );
  }

  Widget _content(BuildContext context, FirmAccountRecord? firm,
      List<TeamMembersRecord>? allMembers) {
    final theme = FlutterFlowTheme.of(context);

    // Single-tenant: keep members linked to this firm, plus legacy docs that
    // have no firmAccountI link.
    final firmRef = firm?.reference;
    final members = (allMembers ?? const <TeamMembersRecord>[])
        .where((m) =>
            firmRef == null || m.firmAccountI == null || m.firmAccountI == firmRef)
        .toList()
      ..sort((a, b) {
        final r = _statusRank(a).compareTo(_statusRank(b));
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final loading = allMembers == null;
    final active = members.where(_isActive).length;
    final seatLimit = firm?.seatLimit ?? 0;
    final remaining = seatLimit - active < 0 ? 0 : seatLimit - active;
    final percent = seatLimit > 0
        ? (active / seatLimit).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final activeText = loading ? '$kDash Active' : '$active Active';
    final remainingText = loading
        ? kDash
        : (seatLimit > 0
            ? '${pluralize(remaining, 'seat')} remaining on your plan'
            : 'Seat limit not set on your plan');
    final usageText = loading
        ? kDash
        : (seatLimit > 0
            ? '$active of $seatLimit seats used'
            : '$active active · no seat limit set');

    final subStyle = adminText(theme.bodySmall, AdminFont.plex,
        color: theme.secondaryText, fontSize: 14.0, lineHeight: 1.5);

    Widget membersBody;
    if (loading) {
      membersBody = const VerinLoading();
    } else if (members.isEmpty) {
      membersBody = VerinEmptyState(
        icon: Icons.group_outlined,
        title: 'No team members yet',
        message: 'Invite a colleague to add them to your firm\'s team list.',
      );
    } else {
      membersBody = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List<Widget>.generate(
          members.length,
          (i) => _memberRow(context, members[i], i == members.length - 1),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: (FFCrossAxisAlignment.start).flutterValue,
                children: [
                  Text(
                    'Team',
                    style: adminText(theme.headlineMedium, AdminFont.spectral,
                        color: theme.primaryText,
                        fontSize: 28.0,
                        lineHeight: 1.4),
                  ),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 4.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(activeText, style: subStyle),
                      Text(
                        '•',
                        style: adminText(theme.bodyMedium, AdminFont.plex,
                            color: theme.onSurface, lineHeight: 1.5),
                      ),
                      Text(remainingText, style: subStyle),
                    ],
                  ),
                ].divide(SizedBox(height: 4.0)),
              ),
            ),
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                await _openInvite(firm);
              },
              child: wrapWithModel(
                model: _model.buttonModel,
                updateCallback: () => safeSetState(() {}),
                child: Button13Widget(
                  icon: Icon(
                    Icons.add_rounded,
                    color: theme.alternate,
                    size: 24.0,
                  ),
                  iconPresent: true,
                  iconEndPresent: false,
                  content: 'Invite member',
                  variant: 'primary',
                  size: 'medium',
                  fullWidth: false,
                  loading: false,
                  disabled: false,
                ),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(8.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: theme.alternate,
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Seat Usage',
                      style: adminText(theme.titleMedium, AdminFont.plex,
                          color: theme.primaryText, lineHeight: 1.4),
                    ),
                    Text(
                      usageText,
                      style: adminText(theme.labelLarge, AdminFont.plex,
                          color: theme.secondaryText, lineHeight: 1.4),
                    ),
                  ],
                ),
                LinearPercentIndicator(
                  percent: percent,
                  lineHeight: 8.0,
                  animation: true,
                  animateFromLastPercent: true,
                  progressColor: theme.secondary,
                  backgroundColor: Color(0x662D5A5E),
                  barRadius: Radius.circular(4.0),
                  padding: EdgeInsets.zero,
                ),
              ].divide(SizedBox(height: 16.0)),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8.0),
              shape: BoxShape.rectangle,
              border: Border.all(
                color: theme.alternate,
                width: 1.0,
              ),
            ),
            child: membersBody,
          ),
        ),
      ].divide(SizedBox(height: 24.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: AdminAccessGate(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional(-1.0, -1.0),
                child: Container(
                  width: 284.0,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  decoration: BoxDecoration(
                    color: Color(0xFF093F49),
                    shape: BoxShape.rectangle,
                  ),
                  child: wrapWithModel(
                    model: _model.sideNavAdminModel,
                    updateCallback: () => safeSetState(() {}),
                    child: SideNavAdminWidget(
                      activePage: AdminTeamsWidget.routeName,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    controller: _model.columnScrollController,
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: FirmAccountBuilder(
                        builder: (context, firm) =>
                            StreamBuilder<List<TeamMembersRecord>>(
                          stream: _membersStream,
                          builder: (context, snapshot) =>
                              _content(context, firm, snapshot.data),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
