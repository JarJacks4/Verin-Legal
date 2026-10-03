import '/backend/backend.dart';
import '/components/button3_widget.dart';
import '/components/switch_component2_widget.dart';
import '/components/text_field3_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_matter_a_model.dart';
export 'edit_matter_a_model.dart';

/// Edit Matter
///
/// A bottom sheet modal titled "Edit Matter" with the same drag handle and
/// navy-and-slate styling as the Create Matter sheet, pre-populated with
/// existing values so it reads as an edit rather than a blank form; it
/// includes labeled text inputs for Client Name, Matter Name, and Case
/// Number, a Matter Type dropdown, a Status segmented control ("Open" /
/// "Closed"), a text input for Assigned Counsel (placeholder "Marcus Thorne,
/// Esq."), and a labeled toggle switch for "Active Monitoring" with a short
/// caption underneath explaining it controls whether new evidence keeps
/// syncing into this matter; the sheet closes with a full-width primary "Save
/// Changes" button and a secondary "Cancel" link, plus a small
/// destructive-styled "Close Matter" text button set apart in the bottom-left
/// corner.
class EditMatterAWidget extends StatefulWidget {
  const EditMatterAWidget({
    super.key,
    String? clientName,
    String? matterName,
    String? caseNumber,
    String? matterType,
    bool? isActiveMonitoring,
    this.matterDoc,
    this.matterRecord,
    this.status,
    this.assignedCounsel,
  })  : this.clientName = clientName ?? '',
        this.matterName = matterName ?? '',
        this.caseNumber = caseNumber ?? '',
        this.matterType = matterType ?? '',
        this.isActiveMonitoring = isActiveMonitoring ?? false;

  final String clientName;
  final String matterName;
  final String caseNumber;
  final String matterType;
  final bool isActiveMonitoring;
  final DocumentReference? matterDoc;
  final ThreadMessagesStruct? matterRecord;
  final String? status;
  final String? assignedCounsel;

  @override
  State<EditMatterAWidget> createState() => _EditMatterAWidgetState();
}

class _EditMatterAWidgetState extends State<EditMatterAWidget> {
  late EditMatterAModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditMatterAModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(1.0, -1.0),
      child: Container(
        width: 640.0,
        height: 897.19,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.561,
          constraints: BoxConstraints(
            maxHeight: 85.0,
          ),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
            shape: BoxShape.rectangle,
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.circular(9999.0),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Text(
                          'Edit Matter',
                          maxLines: 1,
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                                font: GoogleFonts.spectral(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FlutterFlowIconButton(
                        borderRadius: 8.0,
                        buttonSize: 40.0,
                        fillColor: Colors.transparent,
                        icon: Icon(
                          Icons.close_rounded,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 24.0,
                        ),
                        onPressed: () {
                          print('IconButton pressed ...');
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      primary: false,
                      controller: _model.columnScrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          wrapWithModel(
                            model: _model.textFieldModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: TextField3Widget(
                              label: 'Client Name',
                              labelPresent: true,
                              helperPresent: false,
                              leadingIconPresent: false,
                              trailingIconPresent: false,
                              hint: 'Type here...',
                              value: widget.clientName,
                              onChange: '',
                              onSubmit: '',
                              variant: 'outlined',
                              error: false,
                            ),
                          ),
                          wrapWithModel(
                            model: _model.textFieldModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: TextField3Widget(
                              label: 'Matter Name',
                              labelPresent: true,
                              helper: '',
                              helperPresent: false,
                              leadingIconPresent: false,
                              trailingIconPresent: false,
                              hint: 'Type here...',
                              value: widget.matterName,
                              onChange: '',
                              onSubmit: '',
                              variant: 'outlined',
                              error: false,
                            ),
                          ),
                          wrapWithModel(
                            model: _model.textFieldModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: TextField3Widget(
                              label: 'Case Number',
                              labelPresent: true,
                              helper: '',
                              helperPresent: false,
                              leadingIconPresent: false,
                              trailingIconPresent: false,
                              hint: 'Type here...',
                              value: widget.caseNumber,
                              onChange: '',
                              onSubmit: '',
                              variant: 'outlined',
                              error: false,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Matter Type',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.ibmPlexSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              FlutterFlowDropDown<String>(
                                controller: _model.dropdownValueController ??=
                                    FormFieldController<String>(
                                  _model.dropdownValue ??= widget.matterType,
                                ),
                                options: [
                                  'Litigation',
                                  'Corporate',
                                  'Intellectual Property',
                                  'Real Estate'
                                ],
                                onChanged: (val) => safeSetState(
                                    () => _model.dropdownValue = val),
                                width: 200.0,
                                height: 62.43,
                                textStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.ibmPlexSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                                hintText: 'Click for Dropdown Menu',
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                                fillColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                elevation: 2.0,
                                borderColor:
                                    FlutterFlowTheme.of(context).alternate,
                                borderWidth: 1.0,
                                borderRadius: 6.0,
                                margin: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 8.0, 16.0, 0.0),
                                hidesUnderline: true,
                                isOverButton: false,
                                isSearchable: false,
                                isMultiSelect: false,
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                          wrapWithModel(
                            model: _model.textFieldModel4,
                            updateCallback: () => safeSetState(() {}),
                            child: TextField3Widget(
                              label: 'Assigned Counsel',
                              labelPresent: true,
                              helper: '',
                              helperPresent: false,
                              leadingIconPresent: false,
                              trailingIconPresent: false,
                              hint: 'Marcus Thorne, Esq.',
                              value: widget.assignedCounsel,
                              onChange: '',
                              onSubmit: '',
                              variant: 'outlined',
                              error: false,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                              borderRadius: BorderRadius.circular(8.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    wrapWithModel(
                                      model: _model.switchModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: SwitchComponent2Widget(
                                        label: 'Active Monitoring',
                                        labelPresent: true,
                                        variant: 'iOS',
                                        active: valueOrDefault<bool>(
                                          widget.isActiveMonitoring,
                                          false,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Controls whether new evidence keeps syncing into this matter automatically.',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.ibmPlexSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          await widget.matterDoc!
                              .update(createMattersRecordData(
                            clientName: widget.clientName,
                            caseNumber: widget.caseNumber,
                            assignedCounsel: widget.assignedCounsel,
                            activeMonitoring: widget.isActiveMonitoring,
                            matterType: widget.matterType,
                            status: widget.status,
                            caseTitle: widget.matterName,
                          ));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Matter updated.',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 5550),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                        },
                        child: wrapWithModel(
                          model: _model.buttonModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: Button3Widget(
                            iconPresent: false,
                            iconEndPresent: false,
                            content: 'Save Changes',
                            variant: 'primary',
                            size: 'medium',
                            fullWidth: false,
                            loading: false,
                            disabled: false,
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          Navigator.pop(context);
                        },
                        child: wrapWithModel(
                          model: _model.buttonModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: Button3Widget(
                            iconPresent: false,
                            iconEndPresent: false,
                            content: 'Cancel',
                            variant: 'ghost',
                            size: 'medium',
                            fullWidth: true,
                            loading: false,
                            disabled: false,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              Navigator.pop(context);
                            },
                            child: wrapWithModel(
                              model: _model.buttonModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: Button3Widget(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 24.0,
                                ),
                                iconPresent: true,
                                iconEndPresent: false,
                                content: 'Close Matter',
                                variant: 'destructive',
                                size: 'small',
                                fullWidth: false,
                                loading: false,
                                disabled: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ].divide(SizedBox(height: 24.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
