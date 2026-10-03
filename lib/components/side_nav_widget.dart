import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/nav_item4_widget.dart';
import '/components/sidebar_brand_capsule_widget.dart';
import '/components/user_profile_capsule_widget.dart';
import '/components/user_profile_modal_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
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

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.profileRead = await queryMattersRecordOnce();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            context.pushNamed(
                              MattersListWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 11),
                                ),
                              },
                            );
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
                              selected: false,
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
                              ReviewQueueWidget.routeName,
                              extra: <String, dynamic>{
                                '__transition_info__': TransitionInfo(
                                  hasTransition: true,
                                  transitionType: PageTransitionType.fade,
                                  duration: Duration(milliseconds: 11),
                                ),
                              },
                            );
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
                              selected: false,
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
                                  duration: Duration(milliseconds: 9),
                                ),
                              },
                            );
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
                              selected: false,
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
                      if (valueOrDefault(currentUserDocument?.role, '') ==
                          FFAppConstants.Admin)
                        Flexible(
                          flex: 1,
                          child: AuthUserStreamWidget(
                            builder: (context) => wrapWithModel(
                              model: _model.sidebarBrandCapsuleModel,
                              updateCallback: () => safeSetState(() {}),
                              updateOnChange: true,
                              child: SidebarBrandCapsuleWidget(),
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
                          onTap: () async {
                            await showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (context) {
                                return Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: UserProfileModalWidget(
                                    email: currentUserEmail,
                                    firm: valueOrDefault(
                                        currentUserDocument?.lawFirm, ''),
                                    name: currentUserDisplayName,
                                    role: valueOrDefault(
                                        currentUserDocument?.role, ''),
                                  ),
                                );
                              },
                            ).then((value) => safeSetState(() {}));
                          },
                          child: wrapWithModel(
                            model: _model.userProfileCapsuleModel,
                            updateCallback: () => safeSetState(() {}),
                            updateOnChange: true,
                            child: UserProfileCapsuleWidget(
                              email: currentUserEmail,
                              firmName: 'Harbor Family Law',
                              initials: 'SC',
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
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
