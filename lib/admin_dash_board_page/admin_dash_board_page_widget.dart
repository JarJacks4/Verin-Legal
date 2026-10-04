import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/activity_row_widget.dart';
import '/components/kpi_card_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/admin/admin_common.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';
import '/verin/verin_format.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'admin_dash_board_page_model.dart';
export 'admin_dash_board_page_model.dart';

/// Admin Portal — Dashboard (guide §12a).
///
/// Greeting + firm/plan line, four stat tiles (active matters, evidence items,
/// median record lag, video items), the record-lag trend and evidence-volume
/// charts (fed by the bucketRecordLagTrendByMonth / bucketEvidenceVolumeByMonth
/// custom actions), and the five most recent receipts.
class AdminDashBoardPageWidget extends StatefulWidget {
  const AdminDashBoardPageWidget({super.key});

  static String routeName = 'AdminDashBoardPage';
  static String routePath = '/adminDashBoardPage';

  @override
  State<AdminDashBoardPageWidget> createState() =>
      _AdminDashBoardPageWidgetState();
}

/// One chart point parsed from a custom action's "Mon YYYY|n" string.
class _ChartPoint {
  const _ChartPoint(this.label, this.value);

  final String label;
  final double value;
}

class _DashData {
  const _DashData(this.receipts, this.lagTrend, this.volume);

  final List<ReceiptsRecord> receipts;
  final List<_ChartPoint> lagTrend;
  final List<_ChartPoint> volume;
}

/// "Feb 2026" -> "Feb '26".
String _shortMonth(String label) {
  final parts = label.split(' ');
  if (parts.length == 2 && parts[1].length == 4) {
    return "${parts[0]} '${parts[1].substring(2)}";
  }
  return label;
}

/// Parses "Mon YYYY|n" rows, keeping the most recent [keepLast] months.
List<_ChartPoint> _parseBuckets(List<String> rows, {int keepLast = 12}) {
  final out = <_ChartPoint>[];
  for (final row in rows) {
    final i = row.lastIndexOf('|');
    if (i <= 0) continue;
    final v = double.tryParse(row.substring(i + 1).trim());
    if (v == null) continue;
    out.add(_ChartPoint(_shortMonth(row.substring(0, i).trim()), v));
  }
  return out.length > keepLast ? out.sublist(out.length - keepLast) : out;
}

class _AdminDashBoardPageWidgetState extends State<AdminDashBoardPageWidget> {
  late AdminDashBoardPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late final Stream<List<MattersRecord>> _mattersStream;
  late final Stream<_DashData> _dataStream;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminDashBoardPageModel());

    _mattersStream = queryMattersRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()),
    );
    // Receipts have no firm field; the app is single-tenant, so every receipt
    // belongs to this firm.
    _dataStream = queryReceiptsRecord().asyncMap((receipts) async {
      final lag = await actions.bucketRecordLagTrendByMonth(receipts);
      final volume = await actions.bucketEvidenceVolumeByMonth(receipts);
      return _DashData(receipts, _parseBuckets(lag), _parseBuckets(volume));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  TextStyle _axisStyle(BuildContext context) => adminText(
        FlutterFlowTheme.of(context).bodySmall,
        AdminFont.plex,
        color: FlutterFlowTheme.of(context).secondaryText,
        fontSize: 10.0,
        lineHeight: 1.0,
      );

  TextStyle _cardTitleStyle(BuildContext context) => adminText(
        FlutterFlowTheme.of(context).titleMedium,
        AdminFont.inter,
        fontWeight: FontWeight.bold,
        lineHeight: 1.4,
      );

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      );

  Widget _chartMessage(BuildContext context, String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: VerinText.small(context),
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label,
      {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.0,
          height: dashed ? 2.0 : 3.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        SizedBox(width: 6.0),
        Text(label, style: _axisStyle(context)),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final first = firstNameOf(currentUserDisplayName, email: currentUserEmail);
    final greeting = greetingFor(DateTime.now());
    final subStyle = adminText(theme.bodySmall, AdminFont.plex,
        color: theme.secondaryText, fontSize: 14.0, lineHeight: 1.5);
    final bulletStyle = adminText(theme.bodyMedium, AdminFont.plex,
        color: theme.onSurface, lineHeight: 1.5);

    return Padding(
      padding: EdgeInsets.all(25.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: (FFMainAxisAlignment.spaceBetween).flutterValue,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: (FFCrossAxisAlignment.start).flutterValue,
              children: [
                Text(
                  first.isEmpty ? '$greeting.' : '$greeting, $first.',
                  style: adminText(theme.headlineMedium, AdminFont.roboto,
                      color: theme.primaryText,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      lineHeight: 1.25),
                  overflow: TextOverflow.ellipsis,
                ),
                FirmAccountBuilder(
                  builder: (context, firm) => Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          orDash(firm?.firmName),
                          style: subStyle,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      Text('•', style: bulletStyle),
                      Flexible(
                        child: Text(
                          orDash(firm?.planName),
                          style: subStyle,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      Text('•', style: bulletStyle),
                      Text(
                        fmtPlanYear(firm?.memberSince),
                        style: subStyle,
                        overflow: TextOverflow.fade,
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ),
              ].divide(SizedBox(height: 4.0)),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: 'Notifications aren\'t available yet',
                child: Opacity(
                  opacity: 0.45,
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: theme.secondaryText,
                      size: 24.0,
                    ),
                  ),
                ),
              ),
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Text(
                  initialsFor(currentUserDisplayName, email: currentUserEmail),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: adminText(theme.labelMedium, AdminFont.plex,
                      color: Colors.white,
                      fontSize: 13.68,
                      fontWeight: FontWeight.w600,
                      lineHeight: 1.4),
                  overflow: TextOverflow.clip,
                ),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ].divide(SizedBox(width: 8.0)),
      ),
    );
  }

  Widget _kpiRow(List<MattersRecord>? matters, _DashData? data) {
    final active = matters == null
        ? kDash
        : matters
            .where((m) => m.status.trim().toLowerCase() != 'closed')
            .length
            .toString();
    final total = data == null
        ? kDash
        : NumberFormat.decimalPattern().format(data.receipts.length);
    final lag =
        data == null ? kDash : fmtLagShort(firmMedianRecordLagDays(data.receipts));
    final videos = data == null
        ? kDash
        : NumberFormat.decimalPattern().format(data.receipts
            .where((r) => r.itemKind.trim().toLowerCase() == 'video')
            .length);

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: wrapWithModel(
            model: _model.kpiCardModel1,
            updateCallback: () => safeSetState(() {}),
            child: KpiCardWidget(
              value: active,
              label: 'Active Matters',
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: wrapWithModel(
            model: _model.kpiCardModel2,
            updateCallback: () => safeSetState(() {}),
            child: KpiCardWidget(
              value: total,
              label: 'Total Evidence Items',
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: wrapWithModel(
            model: _model.kpiCardModel3,
            updateCallback: () => safeSetState(() {}),
            child: KpiCardWidget(
              value: lag,
              label: 'Record Lag (median)',
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: wrapWithModel(
            model: _model.kpiCardModel4,
            updateCallback: () => safeSetState(() {}),
            child: KpiCardWidget(
              value: videos,
              label: 'Video Items',
            ),
          ),
        ),
      ].divide(SizedBox(width: 24.0)),
    );
  }

  Widget _lagChart(BuildContext context, _DashData? data) {
    final theme = FlutterFlowTheme.of(context);
    if (data == null) return const VerinLoading();
    final pts = data.lagTrend;
    if (pts.isEmpty) {
      return _chartMessage(context,
          'No received items have a resolved date yet, so there is no record lag to chart.');
    }
    final baseline = kBaselineRecordLagDays.toDouble();
    final xs = List<double>.generate(pts.length, (i) => i.toDouble());
    final ys = pts.map((p) => p.value).toList();
    final baseX = pts.length > 1 ? xs : <double>[0.0, 1.0];
    final baseY = List<double>.filled(baseX.length, baseline);
    final maxVal = ys.fold<double>(baseline, (m, v) => v > m ? v : m);

    return FlutterFlowLineChart(
      data: [
        FFLineChartData(
          xData: baseX,
          yData: baseY,
          settings: LineChartBarData(
            color: theme.warning,
            barWidth: 1.5,
            dashArray: [6, 4],
            dotData: FlDotData(show: false),
          ),
        ),
        FFLineChartData(
          xData: xs,
          yData: ys,
          settings: LineChartBarData(
            color: Color(0xFF004D40),
            barWidth: 2.0,
            isCurved: true,
            preventCurveOverShooting: true,
            belowBarData: BarAreaData(
              show: true,
              color: Color(0x1A004D40),
            ),
          ),
        ),
      ],
      chartStylingInfo: ChartStylingInfo(
        backgroundColor: Colors.transparent,
        showBorder: false,
        enableTooltip: true,
        tooltipBackgroundColor: theme.primary,
      ),
      axisBounds: AxisBounds(
        minX: 0.0,
        minY: 0.0,
        maxX: pts.length > 1 ? (pts.length - 1).toDouble() : 1.0,
        maxY: (maxVal * 1.15).ceilToDouble(),
      ),
      xLabels: pts.map((p) => p.label).toList(),
      xAxisLabelInfo: AxisLabelInfo(
        showLabels: true,
        labelTextStyle: _axisStyle(context),
        labelInterval: 1.0,
        reservedSize: 28.0,
      ),
      yAxisLabelInfo: AxisLabelInfo(
        showLabels: true,
        labelTextStyle: _axisStyle(context),
        reservedSize: 36.0,
      ),
    );
  }

  Widget _volumeChart(BuildContext context, _DashData? data) {
    final theme = FlutterFlowTheme.of(context);
    if (data == null) return const VerinLoading();
    final pts = data.volume;
    if (pts.isEmpty) {
      return _chartMessage(context, 'No evidence received yet.');
    }
    final maxVal = pts.fold<double>(0.0, (m, p) => p.value > m ? p.value : m);

    return FlutterFlowBarChart(
      barData: [
        FFBarChartData(
          yData: pts.map((p) => p.value).toList(),
          color: Color(0xFF1A237E),
        )
      ],
      xLabels: pts.map((p) => p.label).toList(),
      barWidth: 20.0,
      barBorderRadius: BorderRadius.circular(4.0),
      groupSpace: 12.0,
      alignment: BarChartAlignment.spaceEvenly,
      chartStylingInfo: ChartStylingInfo(
        backgroundColor: Colors.transparent,
        showBorder: false,
        enableTooltip: true,
        tooltipBackgroundColor: theme.primary,
      ),
      axisBounds: AxisBounds(
        minY: 0.0,
        maxY: maxVal <= 0.0 ? 1.0 : (maxVal * 1.2).ceilToDouble(),
      ),
      xAxisLabelInfo: AxisLabelInfo(
        showLabels: true,
        labelTextStyle: _axisStyle(context),
        reservedSize: 20.0,
      ),
      yAxisLabelInfo: AxisLabelInfo(
        showLabels: true,
        labelTextStyle: _axisStyle(context),
        reservedSize: 32.0,
      ),
    );
  }

  Widget _chartsRow(BuildContext context, _DashData? data) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: _cardDecoration(context),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Record Lag Trend', style: _cardTitleStyle(context)),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 4.0,
                    children: [
                      _legendItem(
                          context, Color(0xFF004D40), 'Median lag (days)'),
                      _legendItem(context, theme.warning,
                          '$kBaselineRecordLagDays-day baseline (before Verin)',
                          dashed: true),
                    ],
                  ),
                  Container(
                    height: 220.0,
                    child: _lagChart(context, data),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: _cardDecoration(context),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Evidence Volume', style: _cardTitleStyle(context)),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 4.0,
                    children: [
                      _legendItem(
                          context, Color(0xFF1A237E), 'Items received per month'),
                    ],
                  ),
                  Container(
                    height: 220.0,
                    child: _volumeChart(context, data),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
            ),
          ),
        ),
      ].divide(SizedBox(width: 24.0)),
    );
  }

  IconData _iconFor(ReceiptsRecord r) {
    final kind = r.itemKind.trim().toLowerCase();
    if (r.isVideo) return Icons.videocam_rounded;
    if (kind == 'screenshot' || kind == 'photo' || kind == 'image') {
      return Icons.image_rounded;
    }
    if (kind == 'email') return Icons.email_rounded;
    if (kind == 'document') return Icons.description_rounded;
    return Icons.upload_file_rounded;
  }

  Widget _activityCard(BuildContext context, _DashData? data) {
    final theme = FlutterFlowTheme.of(context);
    Widget body;
    if (data == null) {
      body = const VerinLoading();
    } else {
      final recent = [...data.receipts]..sort((a, b) {
          final ad = a.receivedAt;
          final bd = b.receivedAt;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
      final top = recent.take(5).toList();
      if (top.isEmpty) {
        body = VerinEmptyState(
          icon: Icons.inbox_rounded,
          title: 'No activity yet',
          message:
              'Evidence your clients send will show up here as it arrives.',
        );
      } else {
        body = Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List<Widget>.generate(top.length, (i) {
            final r = top[i];
            return ActivityRowWidget(
              key: ValueKey('activity_${r.reference.id}'),
              icon: Icon(
                _iconFor(r),
                color: theme.primary,
                size: 18.0,
              ),
              description: orDash(r.headline),
              time: orDash(fmtRelative(r.receivedAt)),
              last: i == top.length - 1,
            );
          }).divide(SizedBox(height: 16.0)),
        );
      }
    }

    return Container(
      decoration: _cardDecoration(context),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent Activity',
              style: adminText(theme.titleMedium, AdminFont.plex,
                  fontWeight: FontWeight.bold, lineHeight: 1.4),
            ),
            body,
          ].divide(SizedBox(height: 16.0)).around(SizedBox(height: 16.0)),
        ),
      ),
    );
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
        body: AdminAccessGate(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional(-1.0, -1.0),
                child: wrapWithModel(
                  model: _model.sideNavAdminModel,
                  updateCallback: () => safeSetState(() {}),
                  child: SideNavAdminWidget(
                    activePage: AdminDashBoardPageWidget.routeName,
                  ),
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
                        _header(context),
                        Padding(
                          padding: EdgeInsets.all(32.0),
                          child: StreamBuilder<List<MattersRecord>>(
                            stream: _mattersStream,
                            builder: (context, mattersSnapshot) {
                              return StreamBuilder<_DashData>(
                                stream: _dataStream,
                                builder: (context, dataSnapshot) {
                                  final matters = mattersSnapshot.data;
                                  final data = dataSnapshot.data;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _kpiRow(matters, data),
                                      _chartsRow(context, data),
                                      _activityCard(context, data),
                                    ].divide(SizedBox(height: 32.0)),
                                  );
                                },
                              );
                            },
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
      ),
    );
  }
}
