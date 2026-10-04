import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/nav_item4_widget.dart';
import '/components/sidebar_brand_capsule_widget.dart';
import '/components/user_profile_capsule_widget.dart';
import '/components/user_profile_modal_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/verin/verin_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'side_nav_model.dart';
export 'side_nav_model.dart';

class SideNavWidget extends StatefulWidget {
  const SideNavWidget({super.key});

  @override
  State<SideNavWidget> createState() => _SideNavWidgetState();
}

class _SideNavWidgetState extends State<SideNavWidget> {
  late SideNavModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SideNavModel());

    // On component load action: the firm's name for the profile row.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final firms = await queryFirmAccountRecordOnce(singleRecord: true);
        _model.firmAccount = firms.isEmpty ? null : firms.first;
      } catch (_) {
        _model.firmAccount = null;
      }
      safeSetState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  /// Admin console entry is shown to Admin / Owner roles only.
  bool get _isAdmin {
    final role = (currentUserDocument?.role ?? '').trim().toLowerCase();
    return role == FFAppConstants.Admin.toLowerCase() || role == 'owner';
  }

  String get _firmName {
    final fromAccount = _model.firmAccount?.firmName.trim() ?? '';
    if (fromAccount.isNotEmpty) return fromAccount;
    return (currentUserDocument?.lawFirm ?? '').trim();
  }

  String _currentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return '';
    }
  }

  void _navigate(String routeName) {
    context.goNamed(
      routeName,
      extra: <String, dynamic>{
        '__transition_info__': TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: Duration(milliseconds: 0),
        ),
      },
    );
  }

  Future<void> _openProfile() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Padding(
          padding: MediaQuery.viewInsetsOf(context),
          child: UserProfileModalWidget(
            email: currentUserEmail,
            firm: _firmName,
            name: currentUserDisplayName,
            role: currentUserDocument?.role ?? '',
          ),
        );
      },
    );
    safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final path = _currentPath(context);
    final onMatters = path.startsWith(MattersListWidget.routePath) ||
        path.startsWith(MattersTabGroupHomeWidget.routePath);
    final onReview = path.startsWith(ReviewQueueWidget.routePath);
    final onSettings = path.startsWith(FirmSettingsWidget.routePath);
    return Container(
      width: 250.4,
      decoration: BoxDecoration(
        color: Color(0xFFFDFCFA),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Color(0x42F9F8F6),
        ),
      ),
      child: Stack(
        children: [
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 24.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.asset(
                                  'assets/images/Wordmark_(2).png',
                                  width: 207.9,
                                  height: 68.5,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                        ),
                      ].divide(SizedBox(width: 8.0)),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            _navigate(MattersListWidget.routeName);
                          },
                          child: wrapWithModel(
                            model: _model.navItemModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: NavItem4Widget(
                              icon: Icon(
                                Icons.folder_rounded,
                                color: FlutterFlowTheme.of(context).secondary,
                                size: 20.0,
                              ),
                              label: 'Matters',
                              selected: onMatters,
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            _navigate(ReviewQueueWidget.routeName);
                          },
                          child: wrapWithModel(
                            model: _model.navItemModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: NavItem4Widget(
                              icon: Icon(
                                Icons.assignment_late_rounded,
                                color: FlutterFlowTheme.of(context).tertiary,
                                size: 20.0,
                              ),
                              label: 'Review Queue',
                              selected: onReview,
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            _navigate(FirmSettingsWidget.routeName);
                          },
                          child: wrapWithModel(
                            model: _model.navItemModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: NavItem4Widget(
                              icon: Icon(
                                Icons.settings_rounded,
                                color: FlutterFlowTheme.of(context).warning,
                                size: 20.0,
                              ),
                              label: 'Settings',
                              selected: onSettings,
                            ),
                          ),
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
                    Divider(
                      thickness: 0.5,
                      color: Color(0x712D5A5E),
                    ),
                  ].divide(SizedBox(height: 24.0)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 2000.0,
                    child: VerticalDivider(
                      thickness: 2.0,
                      color: Color(0x98E2E0DB),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional(0.0, 0.99),
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Admin console pill: Admin / Owner only.
                      AuthUserStreamWidget(
                        builder: (context) => !_isAdmin
                            ? SizedBox.shrink()
                            : Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 16.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    _navigate(
                                        AdminDashBoardPageWidget.routeName);
                                  },
                                  child: wrapWithModel(
                                    model: _model.sidebarBrandCapsuleModel,
                                    updateCallback: () => safeSetState(() {}),
                                    updateOnChange: true,
                                    child: SidebarBrandCapsuleWidget(),
                                  ),
                                ),
                              ),
                      ),
                      Flexible(
                        flex: 1,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: _openProfile,
                          child: AuthUserStreamWidget(
                            builder: (context) => wrapWithModel(
                              model: _model.userProfileCapsuleModel,
                              updateCallback: () => safeSetState(() {}),
                              updateOnChange: true,
                              child: UserProfileCapsuleWidget(
                                email: currentUserEmail,
                                firmName: _firmName,
                                initials: initialsFor(
                                  currentUserDisplayName,
                                  email: currentUserEmail,
                                ),
                                onTap: _openProfile,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
