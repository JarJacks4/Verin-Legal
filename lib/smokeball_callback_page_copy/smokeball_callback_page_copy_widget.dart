import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'smokeball_callback_page_copy_model.dart';
export 'smokeball_callback_page_copy_model.dart';

class SmokeballCallbackPageCopyWidget extends StatefulWidget {
  const SmokeballCallbackPageCopyWidget({
    super.key,
    this.code,
  });

  final String? code;

  static String routeName = 'SmokeballCallbackPageCopy';
  static String routePath = '/smokeballCallbackPageCopy';

  @override
  State<SmokeballCallbackPageCopyWidget> createState() =>
      _SmokeballCallbackPageCopyWidgetState();
}

class _SmokeballCallbackPageCopyWidgetState
    extends State<SmokeballCallbackPageCopyWidget> {
  late SmokeballCallbackPageCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SmokeballCallbackPageCopyModel());

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
                        Icons.info_outline_rounded,
                        size: 40.0,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Smokeball isn\'t available yet',
                        textAlign: TextAlign.center,
                        style: VerinText.section(context),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Smokeball support is planned after Clio. Nothing was connected — return to Settings to see the integrations that are available.',
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
