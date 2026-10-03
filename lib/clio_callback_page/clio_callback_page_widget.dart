import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [],
          ),
        ),
      ),
    );
  }
}
