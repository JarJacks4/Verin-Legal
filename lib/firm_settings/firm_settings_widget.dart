import 'dart:async';

import '/backend/backend.dart';
import '/components/button21_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/components/switch_component5_widget.dart';
import '/components/text_field12_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/verin/matter/practice_tab.dart'
    show connectClio, firmIntegrationStatus;
import '/verin/verin_api.dart';
import '/verin/verin_config.dart';
import '/verin/verin_format.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'firm_settings_model.dart';
export 'firm_settings_model.dart';

class FirmSettingsWidget extends StatefulWidget {
  const FirmSettingsWidget({super.key});

  static String routeName = 'FirmSettings';
  static String routePath = '/firmSettings';

  @override
  State<FirmSettingsWidget> createState() => _FirmSettingsWidgetState();
}

/// The editable part of the firmAccount document, used both as the seeded
/// baseline and as the current form state (dirty = they differ).
///
/// primaryDomain, physicalAddress, requireMfa, restrictIpRange and
/// sessionTimeoutMinutes aren't in the generated FirmAccountRecord schema, so
/// they're read from / written to the raw document map.
class _FirmForm {
  const _FirmForm({
    required this.name,
    required this.domain,
    required this.address,
    required this.requireMfa,
    required this.restrictIp,
    required this.timeoutMinutes,
  });

  factory _FirmForm.fromRecord(FirmAccountRecord r) {
    final d = r.snapshotData;
    String str(String key) {
      final v = d[key];
      return v is String ? v.trim() : '';
    }

    final timeout = d['sessionTimeoutMinutes'];
    return _FirmForm(
      name: r.firmName.trim(),
      domain: str('primaryDomain'),
      address: str('physicalAddress'),
      requireMfa: d['requireMfa'] == true,
      restrictIp: d['restrictIpRange'] == true,
      timeoutMinutes:
          (timeout is num && timeout > 0) ? timeout.toInt() : null,
    );
  }

  final String name;
  final String domain;
  final String address;
  final bool requireMfa;
  final bool restrictIp;
  final int? timeoutMinutes;

  bool sameAs(_FirmForm o) =>
      name == o.name &&
      domain == o.domain &&
      address == o.address &&
      requireMfa == o.requireMfa &&
      restrictIp == o.restrictIp &&
      timeoutMinutes == o.timeoutMinutes;
}

class _FirmSettingsWidgetState extends State<FirmSettingsWidget> {
  late FirmSettingsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  StreamSubscription<List<FirmAccountRecord>>? _firmSub;
  StreamSubscription<List<MattersRecord>>? _mattersSub;
  late final Stream<Map<String, dynamic>> _integrationStream;

  bool _firmLoaded = false;
  FirmAccountRecord? _firm;
  _FirmForm? _baseline;
  bool _requireMfa = false;
  bool _restrictIp = false;
  bool _saving = false;
  bool _disconnecting = false;
  int? _activeMatters;

  static const List<int> _standardTimeouts = [60, 240, 480, 1440];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FirmSettingsModel());

    _model.firmNameController.addListener(_onFieldChanged);
    _model.primaryDomainController.addListener(_onFieldChanged);
    _model.physicalAddressController.addListener(_onFieldChanged);

    _integrationStream = firmIntegrationStatus();

    _firmSub = queryFirmAccountRecord(singleRecord: true).listen((records) {
      if (!mounted) return;
      final rec = records.isEmpty ? null : records.first;
      final firstLoad = !_firmLoaded;
      _firm = rec;
      _firmLoaded = true;
      if (rec != null) {
        final incoming = _FirmForm.fromRecord(rec);
        // Seed once on load; afterwards only follow outside changes while
        // the user has nothing unsaved.
        if (firstLoad ||
            _baseline == null ||
            (!_isDirty && !incoming.sameAs(_baseline!))) {
          _seedFrom(rec);
        }
      } else {
        _baseline = null;
      }
      safeSetState(() {});
    });

    _mattersSub = queryMattersRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()),
    ).listen((matters) {
      safeSetState(() {
        _activeMatters = matters
            .where((m) =>
                !m.isArchiveBuild && m.status.trim().toLowerCase() != 'archived')
            .length;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _firmSub?.cancel();
    _mattersSub?.cancel();
    _model.dispose();

    super.dispose();
  }

  void _onFieldChanged() => safeSetState(() {});

  _FirmForm get _currentForm => _FirmForm(
        name: _model.firmNameController.text.trim(),
        domain: _model.primaryDomainController.text.trim(),
        address: _model.physicalAddressController.text.trim(),
        requireMfa: _requireMfa,
        restrictIp: _restrictIp,
        timeoutMinutes: _minutesFromLabel(_model.dropdownValue),
      );

  bool get _isDirty => _baseline != null && !_currentForm.sameAs(_baseline!);

  void _seedFrom(FirmAccountRecord rec) {
    final f = _FirmForm.fromRecord(rec);
    _baseline = f;
    _model.firmNameController.text = f.name;
    _model.primaryDomainController.text = f.domain;
    _model.physicalAddressController.text = f.address;
    _requireMfa = f.requireMfa;
    _restrictIp = f.restrictIp;
    final label =
        f.timeoutMinutes == null ? null : _timeoutLabel(f.timeoutMinutes!);
    _model.dropdownValue = label;
    _model.dropdownValueController?.value = label;
    safeSetState(() {});
  }

  static String _timeoutLabel(int minutes) {
    if (minutes > 0 && minutes % 60 == 0) {
      final h = minutes ~/ 60;
      return h == 1 ? '1 Hour' : '$h Hours';
    }
    return minutes == 1 ? '1 Minute' : '$minutes Minutes';
  }

  static int? _minutesFromLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    final n = int.tryParse(label.split(' ').first);
    if (n == null) return null;
    return label.contains('Hour') ? n * 60 : n;
  }

  List<String> _timeoutOptions() {
    final minutes = <int>{..._standardTimeouts};
    final current = _minutesFromLabel(_model.dropdownValue);
    if (current != null) minutes.add(current);
    final baseline = _baseline?.timeoutMinutes;
    if (baseline != null) minutes.add(baseline);
    final sorted = minutes.toList()..sort();
    return sorted.map(_timeoutLabel).toList();
  }

  static double? _numField(Map<String, dynamic> data, String key) {
    final v = data[key];
    return v is num ? v.toDouble() : null;
  }

  static String _gb(double v) =>
      '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} GB';

  Future<void> _save() async {
    final firm = _firm;
    if (firm == null || _saving || !_isDirty) return;
    final v = _currentForm;
    if (v.name.isEmpty) {
      showVerinSnack(context, 'Firm name can\'t be empty.', error: true);
      return;
    }
    safeSetState(() => _saving = true);
    try {
      await firm.reference.update(<String, Object>{
        'firmName': v.name,
        'primaryDomain': v.domain,
        'physicalAddress': v.address,
        'requireMfa': v.requireMfa,
        'restrictIpRange': v.restrictIp,
        if (v.timeoutMinutes != null)
          'sessionTimeoutMinutes': v.timeoutMinutes!,
      });
      _baseline = v;
      if (mounted) showVerinSnack(context, 'Firm settings saved.');
    } catch (e) {
      if (mounted) {
        showVerinSnack(context, 'Couldn\'t save firm settings: $e',
            error: true);
      }
    } finally {
      safeSetState(() => _saving = false);
    }
  }

  void _discard() {
    final firm = _firm;
    if (firm == null || _saving) return;
    _seedFrom(firm);
  }

  Future<void> _disconnectClio() async {
    if (_disconnecting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Disconnect Clio?', style: VerinText.section(dialogContext)),
        content: Text(
          'Verin will stop uploading records to Clio until someone connects it again.',
          style: VerinText.body(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Disconnect',
              style: TextStyle(color: FlutterFlowTheme.of(dialogContext).error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    safeSetState(() => _disconnecting = true);
    try {
      await VerinApi.clioDisconnect();
      if (mounted) showVerinSnack(context, 'Clio disconnected.');
    } on VerinApiException catch (e) {
      if (mounted) {
        showVerinSnack(context, 'Couldn\'t disconnect Clio: ${e.message}',
            error: true);
      }
    } finally {
      safeSetState(() => _disconnecting = false);
    }
  }

  Widget _buildNoFirmAccount(BuildContext context) {
    return VerinCard(
      child: VerinEmptyState(
        icon: Icons.business_outlined,
        title: 'No firm account yet',
        message:
            'Firm settings live in the firm\'s firmAccount record, which has to be '
            'created by an administrator (from the Firebase console or a server '
            'script) — the app can\'t create it. Once it exists, this page loads '
            'it automatically.',
      ),
    );
  }

  Widget _buildClioStatus(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return StreamBuilder<Map<String, dynamic>>(
      stream: _integrationStream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Text('Checking connection…', style: VerinText.small(context));
        }
        final status = snap.data ?? const <String, dynamic>{};
        final connected = status['clioConnected'] == true;
        if (!connected) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Not connected', style: VerinText.mono(context)),
              const SizedBox(height: 12.0),
              InkWell(
                onTap: () => connectClio(context),
                borderRadius: BorderRadius.circular(4.0),
                child: Button21Widget(
                  iconPresent: false,
                  iconEndPresent: false,
                  content: 'Connect',
                  variant: 'secondary',
                  size: 'small',
                  fullWidth: false,
                  loading: false,
                  disabled: false,
                ),
              ),
            ],
          );
        }
        final user = (status['clioUserName'] ?? '').toString().trim();
        final rawAt = status['clioConnectedAt'];
        final DateTime? at = rawAt is Timestamp
            ? rawAt.toDate()
            : (rawAt is DateTime ? rawAt : null);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.isNotEmpty ? 'Connected as $user' : 'Connected'}'
              '${at != null ? ' · since ${fmtDate(at)}' : ''}',
              style: VerinText.mono(context, color: t.primaryText),
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                wrapWithModel(
                  model: _model.buttonModel1,
                  updateCallback: () => safeSetState(() {}),
                  child: Button21Widget(
                    icon: Icon(
                      Icons.check_circle_rounded,
                      color: t.primaryText,
                      size: 24.0,
                    ),
                    iconPresent: true,
                    iconEndPresent: false,
                    content: 'Sync Active',
                    variant: 'outline',
                    size: 'small',
                    fullWidth: false,
                    loading: false,
                    disabled: false,
                  ),
                ),
                InkWell(
                  onTap: _disconnecting ? null : _disconnectClio,
                  borderRadius: BorderRadius.circular(4.0),
                  child: Button21Widget(
                    iconPresent: false,
                    iconEndPresent: false,
                    content: _disconnecting ? 'Disconnecting…' : 'Disconnect',
                    variant: 'ghost',
                    size: 'small',
                    fullWidth: false,
                    loading: false,
                    disabled: _disconnecting,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firm = _firm;
    final firmData = firm?.snapshotData ?? const <String, dynamic>{};
    final dirty = _isDirty;
    final canEdit = dirty && !_saving;

    // Billing & usage values.
    final planName = firm == null ? '' : firm.planName.trim();
    final planStatus = firm == null ? '' : firm.planStatus.trim();
    final planLine =
        'Current Plan: ${planName.isEmpty ? kDash : planName}${planStatus.isEmpty ? '' : ' ($planStatus)'}';
    final renewsAt = firm?.planRenewsAt;
    final priceCents = firm?.planPriceCents ?? 0;
    final billingLine =
        'Next billing date: ${renewsAt == null ? kDash : fmtDate(renewsAt)}'
        '${priceCents > 0 ? ' · \$${(priceCents / 100).toStringAsFixed(2)}' : ''}';

    final storageUsed = _numField(firmData, 'storageUsedGb');
    final storageLimit = _numField(firmData, 'storageLimitGb');
    final showStorageBar = storageUsed != null &&
        storageLimit != null &&
        storageLimit > 0;
    final storageText = storageUsed == null
        ? kDash
        : (storageLimit != null && storageLimit > 0)
            ? '${_gb(storageUsed)} / ${_gb(storageLimit)}'
            : _gb(storageUsed);
    final storagePercent =
        (storageUsed != null && storageLimit != null && storageLimit > 0)
            ? (storageUsed / storageLimit).clamp(0.0, 1.0).toDouble()
            : 0.0;

    final matterLimit = _numField(firmData, 'matterLimit')?.toInt() ?? 0;
    final activeMatters = _activeMatters;
    final showMattersBar = activeMatters != null && matterLimit > 0;
    final mattersText = activeMatters == null
        ? kDash
        : matterLimit > 0
            ? '$activeMatters / $matterLimit'
            : '$activeMatters';
    final mattersPercent = (activeMatters != null && matterLimit > 0)
        ? (activeMatters / matterLimit).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 280.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                shape: BoxShape.rectangle,
              ),
              child: wrapWithModel(
                model: _model.sideNavAdminModel,
                updateCallback: () => safeSetState(() {}),
                child: SideNavAdminWidget(),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                child: SingleChildScrollView(
                  primary: false,
                  controller: _model.columnScrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
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
                                  Text(
                                    'Firm Settings',
                                    style: FlutterFlowTheme.of(context)
                                        .displaySmall
                                        .override(
                                          font: GoogleFonts.spectral(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .displaySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .displaySmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .displaySmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .displaySmall
                                                  .fontStyle,
                                          lineHeight: 1.2,
                                        ),
                                  ),
                                  Text(
                                    'Manage your firm\'s profile, security protocols, and third-party integrations.',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          font: GoogleFonts.ibmPlexSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLarge
                                                  .fontStyle,
                                          lineHeight: 1.6,
                                        ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                              if (!_firmLoaded) const VerinLoading(),
                              if (_firmLoaded && firm == null)
                                _buildNoFirmAccount(context),
                              if (firm != null)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Firm Profile',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          font: GoogleFonts.spectral(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: wrapWithModel(
                                                    model:
                                                        _model.textFieldModel1,
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child: TextField12Widget(
                                                      label: 'Firm Name',
                                                      labelPresent: true,
                                                      helper: '',
                                                      helperPresent: false,
                                                      leadingIconPresent: false,
                                                      trailingIconPresent:
                                                          false,
                                                      hint: 'Firm name',
                                                      value: '',
                                                      onChange: '',
                                                      onSubmit: '',
                                                      variant: 'outlined',
                                                      error: false,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: wrapWithModel(
                                                    model:
                                                        _model.textFieldModel2,
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child: TextField12Widget(
                                                      label: 'Primary Domain',
                                                      labelPresent: true,
                                                      helper: '',
                                                      helperPresent: false,
                                                      leadingIconPresent: false,
                                                      trailingIconPresent:
                                                          false,
                                                      hint: 'example.com',
                                                      value: '',
                                                      onChange: '',
                                                      onSubmit: '',
                                                      variant: 'outlined',
                                                      error: false,
                                                    ),
                                                  ),
                                                ),
                                              ].divide(SizedBox(width: 24.0)),
                                            ),
                                            wrapWithModel(
                                              model: _model.textFieldModel3,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: TextField12Widget(
                                                label: 'Physical Address',
                                                labelPresent: true,
                                                helper: '',
                                                helperPresent: false,
                                                leadingIconPresent: false,
                                                trailingIconPresent: false,
                                                hint: 'Street, city, state, ZIP',
                                                value: '',
                                                onChange: '',
                                                onSubmit: '',
                                                variant: 'outlined',
                                                error: false,
                                              ),
                                            ),
                                          ].divide(SizedBox(height: 24.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 24.0)),
                              ),
                              if (firm != null)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Security & Compliance',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          font: GoogleFonts.spectral(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            InkWell(
                                              onTap: () => safeSetState(() =>
                                                  _requireMfa = !_requireMfa),
                                              child: wrapWithModel(
                                                model: _model.switchModel1,
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child: SwitchComponent5Widget(
                                                  label:
                                                      'Require Multi-Factor Authentication (MFA)',
                                                  labelPresent: true,
                                                  variant: 'iOS 26+',
                                                  active: _requireMfa,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => safeSetState(() =>
                                                  _restrictIp = !_restrictIp),
                                              child: wrapWithModel(
                                                model: _model.switchModel2,
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child: SwitchComponent5Widget(
                                                  label:
                                                      'Restrict login to Firm IP Range',
                                                  labelPresent: true,
                                                  variant: 'iOS 26+',
                                                  active: _restrictIp,
                                                ),
                                              ),
                                            ),
                                            Divider(
                                              height: 16.0,
                                              thickness: 1.0,
                                              indent: 0.0,
                                              endIndent: 0.0,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Session Timeout',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.4,
                                                                ),
                                                      ),
                                                      Text(
                                                        'Automatically log out users after a period of inactivity.',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(height: 4.0)),
                                                  ),
                                                ),
                                                Container(
                                                  width: 200.0,
                                                  child: FlutterFlowDropDown<
                                                      String>(
                                                    controller: _model
                                                            .dropdownValueController ??=
                                                        FormFieldController<
                                                            String>(
                                                      _model.dropdownValue,
                                                    ),
                                                    options: _timeoutOptions(),
                                                    onChanged: (val) =>
                                                        safeSetState(() => _model
                                                                .dropdownValue =
                                                            val),
                                                    width: 200.0,
                                                    height: 40.0,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .ibmPlexSans(
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                              lineHeight: 1.5,
                                                            ),
                                                    hintText: 'Not set',
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 24.0,
                                                    ),
                                                    fillColor: FlutterFlowTheme
                                                            .of(context)
                                                        .secondaryBackground,
                                                    elevation: 2.0,
                                                    borderColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .alternate,
                                                    borderWidth: 1.0,
                                                    borderRadius: 6.0,
                                                    margin:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(16.0, 0.0,
                                                                16.0, 0.0),
                                                    hidesUnderline: true,
                                                    isOverButton: false,
                                                    isSearchable: false,
                                                    isMultiSelect: false,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'These preferences are saved to the firm record. Sign-in doesn\'t enforce MFA, IP restrictions or the session timeout yet.',
                                              style: VerinText.small(context),
                                            ),
                                          ].divide(SizedBox(height: 24.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 24.0)),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Integrations',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          font: GoogleFonts.spectral(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            shape: BoxShape.rectangle,
                                            border: Border.all(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(32.0),
                                            child: Container(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      SvgPicture.network(
                                                        'https://cdn.simpleicons.org/clio/ff6b00.svg',
                                                        width: 28.0,
                                                        height: 28.0,
                                                        fit: BoxFit.contain,
                                                      ),
                                                      Text(
                                                        'Clio Manage',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleLarge
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleLarge
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.3,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 8.0)),
                                                  ),
                                                  Text(
                                                    'Automatic write-back of evidence packages and metadata to Clio matters.',
                                                    maxLines: 2,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .ibmPlexSans(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.5,
                                                        ),
                                                  ),
                                                  _buildClioStatus(context),
                                                ].divide(
                                                    SizedBox(height: 16.0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            shape: BoxShape.rectangle,
                                            border: Border.all(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(32.0),
                                            child: Container(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      SvgPicture.network(
                                                        'https://cdn.simpleicons.org/dropbox/0061ff.svg',
                                                        width: 28.0,
                                                        height: 28.0,
                                                        fit: BoxFit.contain,
                                                      ),
                                                      Text(
                                                        'Dropbox',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleLarge
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleLarge
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.3,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 8.0)),
                                                  ),
                                                  Text(
                                                    'Export raw evidence files directly to shared firm folders.',
                                                    maxLines: 2,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .ibmPlexSans(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.5,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Not connected',
                                                    style: VerinText.mono(
                                                        context),
                                                  ),
                                                  // Dropbox has no backend
                                                  // yet: disabled, no fake
                                                  // connect flow.
                                                  wrapWithModel(
                                                    model: _model.buttonModel2,
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child: Button21Widget(
                                                      iconPresent: false,
                                                      iconEndPresent: false,
                                                      content: 'Coming soon',
                                                      variant: 'secondary',
                                                      size: 'small',
                                                      fullWidth: false,
                                                      loading: false,
                                                      disabled: true,
                                                    ),
                                                  ),
                                                ].divide(
                                                    SizedBox(height: 16.0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 24.0)),
                                  ),
                                ].divide(SizedBox(height: 24.0)),
                              ),
                              if (firm != null)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Billing & Usage',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          font: GoogleFonts.spectral(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      planLine,
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .ibmPlexSans(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                                lineHeight: 1.4,
                                                              ),
                                                    ),
                                                    Text(
                                                      billingLine,
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .ibmPlexSans(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                                lineHeight: 1.5,
                                                              ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(height: 4.0)),
                                                ),
                                                // Billing has no backend yet
                                                // (product decision): the
                                                // button stays disabled.
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Tooltip(
                                                      message:
                                                          'Billing isn\'t connected yet',
                                                      child: wrapWithModel(
                                                        model: _model
                                                            .buttonModel3,
                                                        updateCallback: () =>
                                                            safeSetState(
                                                                () {}),
                                                        child: Button21Widget(
                                                          iconPresent: false,
                                                          iconEndPresent:
                                                              false,
                                                          content:
                                                              'Upgrade Plan',
                                                          variant: 'ghost',
                                                          size: 'medium',
                                                          fullWidth: false,
                                                          loading: false,
                                                          disabled: true,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Billing isn\'t connected yet',
                                                      style: VerinText.small(
                                                          context),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Divider(
                                              height: 16.0,
                                              thickness: 1.0,
                                              indent: 0.0,
                                              endIndent: 0.0,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'Matter Storage',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.3,
                                                                ),
                                                          ),
                                                          Text(
                                                            storageText,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelSmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .spaceGrotesk(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (showStorageBar)
                                                      LinearPercentIndicator(
                                                        percent: storagePercent,
                                                        lineHeight: 8.0,
                                                        animation: true,
                                                        animateFromLastPercent:
                                                            true,
                                                        progressColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondary,
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .alternate,
                                                        barRadius:
                                                            Radius.circular(
                                                                4.0),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                    ].divide(
                                                        SizedBox(height: 8.0)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'Active Matters',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .ibmPlexSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.3,
                                                                ),
                                                          ),
                                                          Text(
                                                            mattersText,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelSmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .spaceGrotesk(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (showMattersBar)
                                                      LinearPercentIndicator(
                                                        percent: mattersPercent,
                                                        lineHeight: 8.0,
                                                        animation: true,
                                                        animateFromLastPercent:
                                                            true,
                                                        progressColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .alternate,
                                                        barRadius:
                                                            Radius.circular(
                                                                4.0),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                    ].divide(
                                                        SizedBox(height: 8.0)),
                                                  ),
                                                ),
                                              ].divide(SizedBox(width: 32.0)),
                                            ),
                                          ].divide(SizedBox(height: 24.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 24.0)),
                              ),
                              if (firm != null)
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 32.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (dirty)
                                      Text(
                                        'Unsaved changes',
                                        style: VerinText.small(context),
                                      ),
                                    InkWell(
                                      onTap: canEdit ? _discard : null,
                                      borderRadius: BorderRadius.circular(6.0),
                                      child: wrapWithModel(
                                        model: _model.buttonModel4,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: Button21Widget(
                                          iconPresent: false,
                                          iconEndPresent: false,
                                          content: 'Discard Changes',
                                          variant: 'ghost',
                                          size: 'medium',
                                          fullWidth: false,
                                          loading: false,
                                          disabled: !canEdit,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: canEdit ? _save : null,
                                      borderRadius: BorderRadius.circular(6.0),
                                      child: wrapWithModel(
                                        model: _model.buttonModel5,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: Button21Widget(
                                          iconPresent: false,
                                          iconEndPresent: false,
                                          content: _saving
                                              ? 'Saving…'
                                              : 'Save Settings',
                                          variant: 'primary',
                                          size: 'medium',
                                          fullWidth: false,
                                          loading: false,
                                          disabled: !canEdit,
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                              ),
                            ].divide(SizedBox(height: 48.0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
