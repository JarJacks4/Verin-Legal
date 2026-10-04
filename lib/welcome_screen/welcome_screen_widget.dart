import '/components/status_badge3_widget.dart';
import '/components/welcome_to_verin_comp_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/matters_list/matters_list_widget.dart';
import '/verin/auth/auth_shell.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'welcome_screen_model.dart';
export 'welcome_screen_model.dart';

class WelcomeScreenWidget extends StatefulWidget {
  const WelcomeScreenWidget({super.key});

  static String routeName = 'WelcomeScreen';
  static String routePath = '/welcomeScreen';

  @override
  State<WelcomeScreenWidget> createState() => _WelcomeScreenWidgetState();
}

class _WelcomeScreenWidgetState extends State<WelcomeScreenWidget> {
  late WelcomeScreenModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeScreenModel());

    // Already signed in → straight to the matters list.
    if (currentUserUid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(MattersListWidget.routeName);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VerinAuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: wrapWithModel(
              model: _model.statusBadgeModel,
              updateCallback: () => safeSetState(() {}),
              child: StatusBadge3Widget(
                bgColor: Color(0x1A2D5A5E),
                label: 'FIRM CONSOLE',
                textColor: FlutterFlowTheme.of(context).secondary,
              ),
            ),
          ),
          const SizedBox(height: 32.0),
          wrapWithModel(
            model: _model.welcomeToVerinCompModel,
            updateCallback: () => safeSetState(() {}),
            child: WelcomeToVerinCompWidget(),
          ),
        ],
      ),
    );
  }
}
