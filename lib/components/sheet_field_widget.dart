import '/components/form_label_widget.dart';
import '/components/text_field10_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'sheet_field_model.dart';
export 'sheet_field_model.dart';

class SheetFieldWidget extends StatefulWidget {
  const SheetFieldWidget({
    super.key,
    String? hint,
    String? label,
    String? value,
  })  : this.hint = hint ?? 'e.g. Elena Whitmore',
        this.label = label ?? 'Client Name',
        this.value = value ?? '42';

  final String hint;
  final String label;
  final String value;

  @override
  State<SheetFieldWidget> createState() => _SheetFieldWidgetState();
}

class _SheetFieldWidgetState extends State<SheetFieldWidget> {
  late SheetFieldModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SheetFieldModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            wrapWithModel(
              model: _model.formLabelModel,
              updateCallback: () => safeSetState(() {}),
              child: FormLabelWidget(
                label: valueOrDefault<String>(
                  widget.label,
                  'Client Name',
                ),
              ),
            ),
            wrapWithModel(
              model: _model.textFieldModel,
              updateCallback: () => safeSetState(() {}),
              child: TextField10Widget(
                label: '',
                labelPresent: false,
                helper: '',
                helperPresent: false,
                leadingIconPresent: false,
                trailingIconPresent: false,
                hint: valueOrDefault<String>(
                  widget.hint,
                  'e.g. Elena Whitmore',
                ),
                value: valueOrDefault<String>(
                  widget.value,
                  '42',
                ),
                onChange: '',
                onSubmit: '',
                variant: 'outlined',
                error: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
