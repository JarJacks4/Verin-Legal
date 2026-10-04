import '/components/create_password_comp_widget.dart';
import '/verin/auth/auth_shell.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'create_account_step2_model.dart';
export 'create_account_step2_model.dart';

class CreateAccountStep2Widget extends StatefulWidget {
  const CreateAccountStep2Widget({super.key});

  static String routeName = 'CreateAccountStep2';
  static String routePath = '/createAccountStep2';

  @override
  State<CreateAccountStep2Widget> createState() =>
      _CreateAccountStep2WidgetState();
}

class _CreateAccountStep2WidgetState extends State<CreateAccountStep2Widget> {
  late CreateAccountStep2Model _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateAccountStep2Model());

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
        model: _model.createPasswordCompModel,
        updateCallback: () => safeSetState(() {}),
        child: CreatePasswordCompWidget(),
      ),
    );
  }
}
