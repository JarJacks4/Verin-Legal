import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'clio_callback_page_model.dart';
export 'clio_callback_page_model.dart';

class ClioCallbackPageWidget extends StatefulWidget {
  const ClioCallbackPageWidget({
    super.key,
    this.code,
  });

  final String? code;

  static String routeName = 'ClioCallbackPage';
  static String routePath = '/clioCallbackPage';

  @override
  State<ClioCallbackPageWidget> createState() => _ClioCallbackPageWidgetState();
}

class _ClioCallbackPageWidgetState extends State<ClioCallbackPageWidget> {
  late ClioCallbackPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ClioCallbackPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
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
        body: SafeArea(
          top: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480.0),
                child: VerinCard(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 40.0,
                        color: FlutterFlowTheme.of(context).secondary,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Clio connections now finish automatically',
                        textAlign: TextAlign.center,
                        style: VerinText.section(context),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'After you sign in to Clio, the connection completes on its own — return to Settings to check its status.',
                        textAlign: TextAlign.center,
                        style: VerinText.bodyMuted(context),
                      ),
                      const SizedBox(height: 24.0),
                      VerinButton(
                        label: 'Back to Settings',
                        icon: Icons.settings_outlined,
                        variant: VerinButtonVariant.primary,
                        onPressed: () => context.goNamed('FirmSettings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
