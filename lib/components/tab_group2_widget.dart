import '/components/tab_item3_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'tab_group2_model.dart';
export 'tab_group2_model.dart';

class TabGroup2Widget extends StatefulWidget {
  const TabGroup2Widget({
    super.key,
    String? label2,
    bool? label2Present,
    String? label3,
    bool? label3Present,
    String? label4,
    bool? label4Present,
    String? label5,
    bool? label5Present,
    String? label1,
  })  : this.label2 = label2 ?? 'Closed',
        this.label2Present = label2Present ?? true,
        this.label3 = label3 ?? 'Reports',
        this.label3Present = label3Present ?? true,
        this.label4 = label4 ?? '',
        this.label4Present = label4Present ?? false,
        this.label5 = label5 ?? '',
        this.label5Present = label5Present ?? false,
        this.label1 = label1 ?? 'Open';

  final String label2;
  final bool label2Present;
  final String label3;
  final bool label3Present;
  final String label4;
  final bool label4Present;
  final String label5;
  final bool label5Present;
  final String label1;

  @override
  State<TabGroup2Widget> createState() => _TabGroup2WidgetState();
}

class _TabGroup2WidgetState extends State<TabGroup2Widget> {
  late TabGroup2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TabGroup2Model());

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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: wrapWithModel(
                model: _model.tabItemModel1,
                updateCallback: () => safeSetState(() {}),
                child: TabItem3Widget(
                  label: valueOrDefault<String>(
                    widget.label1,
                    'Open',
                  ),
                  selected: true,
                ),
              ),
            ),
            if (valueOrDefault<bool>(
              widget.label2Present,
              true,
            ))
              Expanded(
                flex: 1,
                child: wrapWithModel(
                  model: _model.tabItemModel2,
                  updateCallback: () => safeSetState(() {}),
                  child: TabItem3Widget(
                    label: valueOrDefault<String>(
                      widget.label2,
                      'Closed',
                    ),
                    selected: false,
                  ),
                ),
              ),
            if (valueOrDefault<bool>(
              widget.label3Present,
              true,
            ))
              Expanded(
                flex: 1,
                child: wrapWithModel(
                  model: _model.tabItemModel3,
                  updateCallback: () => safeSetState(() {}),
                  child: TabItem3Widget(
                    label: valueOrDefault<String>(
                      widget.label3,
                      'Reports',
                    ),
                    selected: false,
                  ),
                ),
              ),
            if (valueOrDefault<bool>(
              widget.label4Present,
              false,
            ))
              Expanded(
                flex: 1,
                child: wrapWithModel(
                  model: _model.tabItemModel4,
                  updateCallback: () => safeSetState(() {}),
                  child: TabItem3Widget(
                    label: widget.label4,
                    selected: false,
                  ),
                ),
              ),
            if (valueOrDefault<bool>(
              widget.label5Present,
              false,
            ))
              Expanded(
                flex: 1,
                child: wrapWithModel(
                  model: _model.tabItemModel5,
                  updateCallback: () => safeSetState(() {}),
                  child: TabItem3Widget(
                    label: widget.label5,
                    selected: false,
                  ),
                ),
              ),
          ].divide(SizedBox(width: 0.0)),
        ),
      ),
    );
  }
}
