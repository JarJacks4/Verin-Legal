import '/components/create_account_step1_comp_widget.dart';
import '/verin/auth/auth_shell.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'create_account_step1_model.dart';
export 'create_account_step1_model.dart';

class CreateAccountStep1Widget extends StatefulWidget {
  const CreateAccountStep1Widget({super.key});

  static String routeName = 'CreateAccountStep1';
  static String routePath = '/createAccountStep1';

  @override
  State<CreateAccountStep1Widget> createState() =>
      _CreateAccountStep1WidgetState();
}

class _CreateAccountStep1WidgetState extends State<CreateAccountStep1Widget> {
  late CreateAccountStep1Model _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateAccountStep1Model());

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
      maxFormWidth: 480.0,
      child: wrapWithModel(
        model: _model.createAccountStep1CompModel,
        updateCallback: () => safeSetState(() {}),
        child: CreateAccountStep1CompWidget(),
      ),
    );
  }
}
