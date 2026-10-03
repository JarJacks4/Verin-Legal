import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [],
          ),
        ),
      ),
    );
  }
}
