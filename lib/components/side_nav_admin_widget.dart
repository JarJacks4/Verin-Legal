import '/components/sidebar_brand_capsule_widget.dart';
import '/components/sidebar_nav_item_widget.dart';
import '/components/user_profile_capsule_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'side_nav_admin_model.dart';
export 'side_nav_admin_model.dart';

class SideNavAdminWidget extends StatefulWidget {
  const SideNavAdminWidget({super.key});

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
                  height: 405.8,
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 75.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment:
                          (FFCrossAxisAlignment.start).flutterValue,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              AdminDashBoardPageWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 2),
                                ),
                              },
                            );
                          },
                          child: wrapWithModel(
                            model: _model.sidebarNavItemModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: SidebarNavItemWidget(
                              selected: true,
                              icon: Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              label: 'Dashboard',
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              AdminMattersListWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 2),
                                ),
                              },
                            );
                          },
                          child: wrapWithModel(
                            model: _model.sidebarNavItemModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: SidebarNavItemWidget(
                              selected: false,
                              icon: Icon(
                                Icons.folder_shared_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              label: 'Matters',
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              AdminBillingAndPlanWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 2),
                                ),
                              },
                            );
                          },
                          child: wrapWithModel(
                            model: _model.sidebarNavItemModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: SidebarNavItemWidget(
                              selected: false,
                              icon: Icon(
                                Icons.payments_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              label: 'Billing',
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              AdminTeamsWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 2),
                                ),
                              },
                            );
                          },
                          child: wrapWithModel(
                            model: _model.sidebarNavItemModel4,
                            updateCallback: () => safeSetState(() {}),
                            child: SidebarNavItemWidget(
                              selected: false,
                              icon: Icon(
                                Icons.group_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              label: 'Team',
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              AdminProgramPageWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 2),
                                ),
                              },
                            );
                          },
                          child: wrapWithModel(
                            model: _model.sidebarNavItemModel5,
                            updateCallback: () => safeSetState(() {}),
                            child: SidebarNavItemWidget(
                              selected: false,
                              icon: Icon(
                                Icons.assignment_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              label: 'Program',
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              FirmSettingsWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 2),
                                ),
                              },
                            );
                          },
                          child: wrapWithModel(
                            model: _model.sidebarNavItemModel6,
                            updateCallback: () => safeSetState(() {}),
                            child: SidebarNavItemWidget(
                              selected: false,
                              icon: Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              label: 'Settings',
                            ),
                          ),
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
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
                        child: wrapWithModel(
                          model: _model.sidebarBrandCapsuleModel,
                          updateCallback: () => safeSetState(() {}),
                          child: SidebarBrandCapsuleWidget(),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: wrapWithModel(
                          model: _model.userProfileCapsuleModel,
                          updateCallback: () => safeSetState(() {}),
                          updateOnChange: true,
                          child: UserProfileCapsuleWidget(
                            email: 'paralegal@harborlaw...',
                            firmName: 'Harbor Family Law',
                            initials: 'SC',
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
