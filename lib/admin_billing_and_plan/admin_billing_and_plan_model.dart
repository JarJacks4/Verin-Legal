import '/components/invoice_row_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_billing_and_plan_widget.dart' show AdminBillingAndPlanWidget;
import 'package:flutter/material.dart';

class AdminBillingAndPlanModel
    extends FlutterFlowModel<AdminBillingAndPlanWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SideNavAdmin component.
  late SideNavAdminModel sideNavAdminModel;
  // Model for InvoiceRow.
  late InvoiceRowModel invoiceRowModel1;
  // Model for InvoiceRow.
  late InvoiceRowModel invoiceRowModel2;
  // Model for InvoiceRow.
  late InvoiceRowModel invoiceRowModel3;

  @override
  void initState(BuildContext context) {
    sideNavAdminModel = createModel(context, () => SideNavAdminModel());
    invoiceRowModel1 = createModel(context, () => InvoiceRowModel());
    invoiceRowModel2 = createModel(context, () => InvoiceRowModel());
    invoiceRowModel3 = createModel(context, () => InvoiceRowModel());
  }

  @override
  void dispose() {
    sideNavAdminModel.dispose();
    invoiceRowModel1.dispose();
    invoiceRowModel2.dispose();
    invoiceRowModel3.dispose();
  }
}
