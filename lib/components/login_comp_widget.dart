import '/components/button18_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_comp_model.dart';
export 'login_comp_model.dart';

class LoginCompWidget extends StatefulWidget {
  const LoginCompWidget({super.key});

  @override
  State<LoginCompWidget> createState() => _LoginCompWidgetState();
}

class _LoginCompWidgetState extends State<LoginCompWidget> {
  late LoginCompModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginCompModel());

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
      width: 440.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CachedNetworkImage(
                    fadeInDuration: Duration(milliseconds: 0),
                    fadeOutDuration: Duration(milliseconds: 0),
                    imageUrl:
                        'https://firebasestorage.googleapis.com/v0/b/flutterflow-io-6f20.appspot.com/o/designer_assets%2Fd60933af-2324-436d-a10b-8ca8e24bd68f%2FedshCEFdZu0gT1rNzYpB?alt=media&token=e4d0e0eb-22c5-4344-928c-da03ac6f4bbf',
                    height: 48.0,
                    fit: BoxFit.contain,
                    alignment: Alignment(0.0, 0.0),
                  ),
                  Text(
                    'Evidence-record system for family and employment law.',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.ibmPlexSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.5,
                        ),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  wrapWithModel(
                    model: _model.textFieldModel1,
                    updateCallback: () => safeSetState(() {}),
                    child: TextField10Widget(
                      label: 'Workspace URL',
                      labelPresent: true,
                      helper: '',
                      helperPresent: false,
                      leadingIconPresent: false,
                      trailingIcon: Icon(
                        Icons.domain_rounded,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                      trailingIconPresent: true,
                      hint: 'firm-slug',
                      value: '',
                      onChange: '',
                      onSubmit: '',
                      variant: 'outlined',
                      error: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.textFieldModel2,
                    updateCallback: () => safeSetState(() {}),
                    child: TextField10Widget(
                      label: 'Email Address',
                      labelPresent: true,
                      helper: '',
                      helperPresent: false,
                      leadingIcon: Icon(
                        Icons.email_outlined,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                      leadingIconPresent: true,
                      trailingIconPresent: false,
                      hint: 'attorney@firm.com',
                      value: '',
                      onChange: '',
                      onSubmit: '',
                      variant: 'outlined',
                      error: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.buttonModel1,
                    updateCallback: () => safeSetState(() {}),
                    child: Button18Widget(
                      iconPresent: false,
                      iconEndPresent: false,
                      content: 'Continue to Workspace',
                      variant: 'primary',
                      size: 'large',
                      fullWidth: true,
                      loading: false,
                      disabled: false,
                    ),
                  ),
                ].divide(SizedBox(height: 24.0)),
              ),
              Divider(
                height: 16.0,
                thickness: 1.0,
                indent: 0.0,
                endIndent: 0.0,
                color: FlutterFlowTheme.of(context).alternate,
              ),
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(6.0),
                  shape: BoxShape.rectangle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
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
                            Icon(
                              Icons.info_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 16.0,
                            ),
                            Text(
                              'Environment: Production (v2.4.0)',
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.spaceGrotesk(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                        Text(
                          'Notice: You are accessing a demo workspace. All matters shown are fictional for training and demonstration purposes. No real client data is stored in this instance.',
                          maxLines: 4,
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.ibmPlexSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                                lineHeight: 1.5,
                              ),
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  wrapWithModel(
                    model: _model.buttonModel2,
                    updateCallback: () => safeSetState(() {}),
                    child: Button18Widget(
                      iconPresent: false,
                      iconEndPresent: false,
                      content: 'Privacy Policy',
                      variant: 'ghost',
                      size: 'small',
                      fullWidth: false,
                      loading: false,
                      disabled: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.buttonModel3,
                    updateCallback: () => safeSetState(() {}),
                    child: Button18Widget(
                      iconPresent: false,
                      iconEndPresent: false,
                      content: 'Security Audit',
                      variant: 'ghost',
                      size: 'small',
                      fullWidth: false,
                      loading: false,
                      disabled: false,
                    ),
                  ),
                ],
              ),
            ].divide(SizedBox(height: 32.0)),
          ),
        ),
      ),
    );
  }
}
