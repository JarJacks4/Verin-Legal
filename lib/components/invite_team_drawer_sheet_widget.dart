import '/backend/backend.dart';
import '/components/button18_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'invite_team_drawer_sheet_model.dart';
export 'invite_team_drawer_sheet_model.dart';

/// Invite team member drawer (guide §10, opened from Admin → Team).
///
/// Records a TeamMembers doc with status "invited" and a 72-hour expiresAt.
/// Pops with the invited email on success. Sending the invitation email is
/// not connected yet (no email backend), and the copy says so.
class InviteTeamDrawerSheetWidget extends StatefulWidget {
  const InviteTeamDrawerSheetWidget({
    super.key,
    this.firmAccountRef,
  });

  /// The firm's firmAccount doc; looked up when not given.
  final DocumentReference? firmAccountRef;

  @override
  State<InviteTeamDrawerSheetWidget> createState() =>
      _InviteTeamDrawerSheetWidgetState();
}

class _InviteTeamDrawerSheetWidgetState
    extends State<InviteTeamDrawerSheetWidget> {
  late InviteTeamDrawerSheetModel _model;

  static const List<String> _roles = ['Paralegal', 'Attorney', 'Admin'];
  static final RegExp _emailRe =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InviteTeamDrawerSheetModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  Future<void> _send() async {
    if (_model.sending) return;
    final name = (_model.textFieldModel1.inputTextController?.text ?? '').trim();
    final email = (_model.textFieldModel2.inputTextController?.text ?? '')
        .trim()
        .toLowerCase();

    if (name.isEmpty) {
      safeSetState(() => _model.errorText = 'Enter the person\'s full name.');
      return;
    }
    if (!_emailRe.hasMatch(email)) {
      safeSetState(
          () => _model.errorText = 'Enter a valid work email address.');
      return;
    }

    safeSetState(() {
      _model.sending = true;
      _model.errorText = null;
    });

    try {
      final now = DateTime.now();
      final expiresAt = Timestamp.fromDate(now.add(Duration(hours: 72)));

      final existing = await queryTeamMembersRecordOnce(
        queryBuilder: (q) => q.where('email', isEqualTo: email),
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final member = existing.first;
        if (!member.inviteExpired) {
          safeSetState(() {
            _model.sending = false;
            _model.errorText = member.status.toLowerCase() == 'invited'
                ? '$email already has an open invitation.'
                : '$email is already on your team.';
          });
          return;
        }
        // Expired invitation: renew it instead of creating a duplicate.
        await member.reference.update({
          ...createTeamMembersRecordData(
            name: name,
            role: _model.selectedRole,
            status: 'invited',
            invitedAt: now,
          ),
          'expiresAt': expiresAt,
        });
      } else {
        var firmRef = widget.firmAccountRef;
        if (firmRef == null) {
          final firms = await queryFirmAccountRecordOnce(singleRecord: true);
          if (firms.isNotEmpty) firmRef = firms.first.reference;
        }
        await TeamMembersRecord.collection.doc().set({
          ...createTeamMembersRecordData(
            firmAccountI: firmRef,
            name: name,
            email: email,
            role: _model.selectedRole,
            status: 'invited',
            invitedAt: now,
          ),
          'expiresAt': expiresAt,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, email);
    } catch (e) {
      safeSetState(() {
        _model.sending = false;
        _model.errorText =
            'Couldn\'t save the invitation. Check your connection and try again.';
      });
    }
  }

  TextStyle _labelLarge(BuildContext context) =>
      FlutterFlowTheme.of(context).labelLarge.override(
            font: GoogleFonts.ibmPlexSans(
              fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
            ),
            color: FlutterFlowTheme.of(context).primaryText,
            letterSpacing: 0.0,
            fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
            fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
            lineHeight: 1.3,
          );

  Widget _roleChip(BuildContext context, String role) {
    final selected = _model.selectedRole == role;
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: _model.sending
          ? null
          : () => safeSetState(() {
                _model.selectedRole = role;
                _model.errorText = null;
              }),
      child: Container(
        height: 34.0,
        decoration: BoxDecoration(
          color: selected
              ? FlutterFlowTheme.of(context).secondary
              : Color(0xFFE8E6E1),
          borderRadius: BorderRadius.circular(9999.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selected)
                Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16.0,
                ),
              Text(
                role,
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.ibmPlexSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                      color: selected
                          ? Colors.white
                          : FlutterFlowTheme.of(context).primaryText,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      lineHeight: 1.3,
                    ),
              ),
            ].divide(SizedBox(width: 6.0)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(1.0, -1.0),
      child: Container(
        width: 440.0,
        height: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            width: 480.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(8.0),
              shape: BoxShape.rectangle,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    (FFMainAxisAlignment.spaceEvenly).flutterValue,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Invite team member',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.spectral(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                              ),
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 40.0,
                                fillColor: Colors.transparent,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 1.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).alternate,
                            shape: BoxShape.rectangle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'The invitation stays open for 72 hours. Invite emails aren\'t connected yet, so let your colleague know directly.',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                font: GoogleFonts.ibmPlexSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                                lineHeight: 1.5,
                              ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full name',
                                  style: _labelLarge(context),
                                ),
                                wrapWithModel(
                                  model: _model.textFieldModel1,
                                  updateCallback: () => safeSetState(() {}),
                                  child: TextField10Widget(
                                    label: 'Full Name',
                                    labelPresent: true,
                                    helper: 'Type Full Name Here...',
                                    helperPresent: true,
                                    leadingIconPresent: true,
                                    trailingIconPresent: false,
                                    hint: 'Jane Smith',
                                    value: '',
                                    onChange: '',
                                    onSubmit: '',
                                    variant: 'filled',
                                    error: false,
                                    leadingIcon: FaIcon(
                                      FontAwesomeIcons.pencilAlt,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(height: 4.0)),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Work email',
                                  style: _labelLarge(context),
                                ),
                                wrapWithModel(
                                  model: _model.textFieldModel2,
                                  updateCallback: () => safeSetState(() {}),
                                  child: TextField10Widget(
                                    label: 'Work Email',
                                    labelPresent: true,
                                    helper: 'Type Work email Here...',
                                    helperPresent: true,
                                    leadingIconPresent: false,
                                    trailingIconPresent: false,
                                    hint: 'j.smith@yourfirm.com',
                                    value: '',
                                    onChange: '',
                                    onSubmit: '',
                                    variant: 'filled',
                                    error: false,
                                  ),
                                ),
                              ].divide(SizedBox(height: 4.0)),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role',
                              style: _labelLarge(context),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _model.rowScrollController,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _roles
                                      .map((r) => _roleChip(context, r))
                                      .toList()
                                      .divide(SizedBox(width: 16.0)),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 8.0)),
                        ),
                        if (_model.errorText != null)
                          Text(
                            _model.errorText ?? '',
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  font: GoogleFonts.ibmPlexSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).error,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 25.0, 16.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: _model.sending ? null : _send,
                            child: wrapWithModel(
                              model: _model.buttonModel,
                              updateCallback: () => safeSetState(() {}),
                              child: Button18Widget(
                                icon: Icon(
                                  Icons.person_add_rounded,
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  size: 24.0,
                                ),
                                iconPresent: true,
                                iconEndPresent: false,
                                content: 'Send invitation',
                                variant: 'primary',
                                size: 'large',
                                fullWidth: true,
                                loading: _model.sending,
                                disabled: _model.sending,
                                iconEnd: Icon(
                                  Icons.arrow_forward,
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ].divide(SizedBox(height: 24.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
