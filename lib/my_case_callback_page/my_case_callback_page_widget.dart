import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'my_case_callback_page_model.dart';
export 'my_case_callback_page_model.dart';

class MyCaseCallbackPageWidget extends StatefulWidget {
  const MyCaseCallbackPageWidget({
    super.key,
    this.code,
  });

  final String? code;

  static String routeName = 'MyCaseCallbackPage';
  static String routePath = '/myCaseCallbackPage';

  @override
  State<MyCaseCallbackPageWidget> createState() =>
      _MyCaseCallbackPageWidgetState();
}

class _MyCaseCallbackPageWidgetState extends State<MyCaseCallbackPageWidget> {
  late MyCaseCallbackPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyCaseCallbackPageModel());

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
