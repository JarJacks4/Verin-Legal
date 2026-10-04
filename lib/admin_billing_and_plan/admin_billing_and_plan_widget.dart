import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/admin/admin_common.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'admin_billing_and_plan_model.dart';
export 'admin_billing_and_plan_model.dart';

/// Admin Portal — Billing & Subscription (guide §12c): the firm's plan card
/// (bound to firmAccount) and Invoice History. There is no invoices
/// collection or payment provider yet, so Invoice History is an honest empty
/// state rather than sample rows.
class AdminBillingAndPlanWidget extends StatefulWidget {
  const AdminBillingAndPlanWidget({super.key});

  static String routeName = 'AdminBillingAndPlan';
  static String routePath = '/adminBillingAndPlan';

  @override
  State<AdminBillingAndPlanWidget> createState() =>
      _AdminBillingAndPlanWidgetState();
}

class _AdminBillingAndPlanWidgetState extends State<AdminBillingAndPlanWidget> {
  late AdminBillingAndPlanModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminBillingAndPlanModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: AdminAccessGate(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional(-1.0, -1.0),
                child: Container(
                  width: 258.4,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  decoration: BoxDecoration(
                    color: Color(0xFF093F49),
                    shape: BoxShape.rectangle,
                  ),
                  child: wrapWithModel(
                    model: _model.sideNavAdminModel,
                    updateCallback: () => safeSetState(() {}),
                    child: SideNavAdminWidget(
                      activePage: AdminBillingAndPlanWidget.routeName,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    controller: _model.columnScrollController,
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment:
                              (FFCrossAxisAlignment.start).flutterValue,
                          children: [
                            Text(
                              'Billing & Subscription',
                              style: adminText(
                                  theme.headlineMedium, AdminFont.spectral,
                                  color: theme.primaryText,
                                  fontSize: 28.0,
                                  fontWeight: FontWeight.bold,
                                  lineHeight: 1.4),
                            ),
                            Text(
                              'Your plan, renewal date and billing history.',
                              style: adminText(theme.bodyMedium, AdminFont.plex,
                                  color: theme.secondaryText, lineHeight: 1.4),
                            ),
                          ].divide(SizedBox(height: 4.0)),
                        ),
                        FirmAccountBuilder(
                          builder: (context, firm) =>
                              AdminPlanCard(firm: firm, width: 640.0),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                width: 640.0,
                                decoration: BoxDecoration(
                                  color: theme.secondaryBackground,
                                  borderRadius: BorderRadius.circular(8.0),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color: theme.alternate,
                                    width: 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Invoice History',
                                        style: adminText(
                                            theme.titleLarge, AdminFont.plex,
                                            fontWeight: FontWeight.bold,
                                            lineHeight: 1.4),
                                      ),
                                      VerinEmptyState(
                                        icon: Icons.receipt_long_rounded,
                                        title: 'No invoices yet',
                                        message:
                                            'Invoices will appear here once billing is connected.',
                                      ),
                                    ].divide(SizedBox(height: 16.0)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ].divide(SizedBox(height: 24.0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
