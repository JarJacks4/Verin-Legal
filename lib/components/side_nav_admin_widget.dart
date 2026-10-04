import '/auth/firebase_auth/auth_util.dart';
import '/components/sidebar_brand_capsule_widget.dart';
import '/components/sidebar_nav_item_widget.dart';
import '/components/user_profile_capsule_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/verin/admin/admin_common.dart';
import '/verin/verin_format.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'side_nav_admin_model.dart';
export 'side_nav_admin_model.dart';

class SideNavAdminWidget extends StatefulWidget {
  const SideNavAdminWidget({
    super.key,
    String? activePage,
  }) : this.activePage = activePage ?? '';

  /// routeName of the page showing this nav (e.g. 'AdminTeams'); that item is
  /// highlighted. Empty highlights nothing.
  final String activePage;

  @override
  State<SideNavAdminWidget> createState() => _SideNavAdminWidgetState();
}

class _SideNavAdminWidgetState extends State<SideNavAdminWidget> {
  late SideNavAdminModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SideNavAdminModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  void _open(String routeName) {
    if (widget.activePage == routeName) return;
    context.pushNamed(
      routeName,
      extra: <String, dynamic>{
        '__transition_info__': TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: Duration(milliseconds: 2),
        ),
      },
    );
  }

  Widget _navItem({
    required SidebarNavItemModel model,
    required String routeName,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap ?? () => _open(routeName),
      child: wrapWithModel(
        model: model,
        updateCallback: () => safeSetState(() {}),
        child: SidebarNavItemWidget(
          selected: routeName.isNotEmpty && widget.activePage == routeName,
          icon: Icon(
            icon,
            color: Colors.white,
            size: 20.0,
          ),
          label: label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(-1.0, -1.0),
      child: Container(
        width: 296.1,
        height: MediaQuery.sizeOf(context).height * 1.0,
        decoration: BoxDecoration(
          color: Color(0xFF093F49),
          shape: BoxShape.rectangle,
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: (FFMainAxisAlignment.spaceAround).flutterValue,
              crossAxisAlignment: (FFCrossAxisAlignment.start).flutterValue,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/images/verinlegal_linkedin_logo_1024.png',
                          width: 51.9,
                          height: 54.3,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        'Verin Legal',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.playfairDisplaySc(
                                fontWeight: FontWeight.normal,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: Colors.white,
                              fontSize: 20.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                ),
                Container(
                  width: 236.5,
                  decoration: BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment:
                        (FFCrossAxisAlignment.start).flutterValue,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      _navItem(
                        model: _model.sidebarNavItemModel1,
                        routeName: AdminDashBoardPageWidget.routeName,
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                      ),
                      _navItem(
                        model: _model.sidebarNavItemModel2,
                        routeName: AdminMattersListWidget.routeName,
                        icon: Icons.folder_shared_rounded,
                        label: 'Matters',
                      ),
                      _navItem(
                        model: _model.sidebarNavItemModel3,
                        routeName: AdminBillingAndPlanWidget.routeName,
                        icon: Icons.payments_rounded,
                        label: 'Billing',
                      ),
                      _navItem(
                        model: _model.sidebarNavItemModel4,
                        routeName: AdminTeamsWidget.routeName,
                        icon: Icons.group_rounded,
                        label: 'Team',
                      ),
                      _navItem(
                        model: _model.sidebarNavItemModel5,
                        routeName: AdminProgramPageWidget.routeName,
                        icon: Icons.assignment_rounded,
                        label: 'Program',
                      ),
                      _navItem(
                        model: _model.sidebarNavItemModel6,
                        routeName: FirmSettingsWidget.routeName,
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                      ),
                      _navItem(
                        model: _model.sidebarNavItemModel7,
                        routeName: '',
                        icon: Icons.arrow_back_rounded,
                        label: 'Back to app',
                        onTap: () => context.goNamed(MattersListWidget.routeName),
                      ),
                    ].divide(SizedBox(height: 4.0)),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.99),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Tooltip(
                          message: 'Admin dashboard',
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () =>
                                _open(AdminDashBoardPageWidget.routeName),
                            child: wrapWithModel(
                              model: _model.sidebarBrandCapsuleModel,
                              updateCallback: () => safeSetState(() {}),
                              child: SidebarBrandCapsuleWidget(),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: FirmAccountBuilder(
                          builder: (context, firm) => wrapWithModel(
                            model: _model.userProfileCapsuleModel,
                            updateCallback: () => safeSetState(() {}),
                            updateOnChange: true,
                            child: UserProfileCapsuleWidget(
                              email: orDash(currentUserEmail),
                              firmName: orDash(firm?.firmName),
                              initials: initialsFor(
                                currentUserDisplayName,
                                email: currentUserEmail,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ),
              ].divide(SizedBox(height: 24.0)),
            ),
          ),
        ),
      ),
    );
  }
}
