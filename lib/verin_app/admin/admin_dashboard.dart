// Admin dashboard — port of the Make's <AdminDashboard> with live numbers:
// KPIs, Record Lag trend, evidence volume, recent intake activity.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../matters/matters_screen.dart' show receiptsByMatterStream;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import 'admin_shell.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Last [n] calendar months, oldest first, as (year, month).
List<(int, int)> lastMonths(int n) {
  final now = DateTime.now();
  return [
    for (var i = n - 1; i >= 0; i--) DateTime(now.year, now.month - i, 1),
  ].map((d) => (d.year, d.month)).toList();
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.user, required this.firm});

  final VUser user;
  final FirmAccountRecord? firm;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final Stream<List<MattersRecord>> _matters = firmMattersStream();
  late final Stream<Map<String, List<ReceiptsRecord>>> _receipts = receiptsByMatterStream();

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<List<MattersRecord>>(
      stream: _matters,
      builder: (context, ms) => StreamBuilder<Map<String, List<ReceiptsRecord>>>(
        stream: _receipts,
        builder: (context, rs) {
          if (!ms.hasData || !rs.hasData) return const VLoading();
          final matters = ms.data!;
          final byMatter = rs.data!;
          final paths = {for (final m in matters) m.reference.path: m};
          final receipts = [
            for (final e in byMatter.entries)
              if (paths.containsKey(e.key)) ...e.value.where((r) => !r.isDuplicate),
          ];
          final open = matters.where(matterIsOpen).length;
          final processed = receipts.where((r) => itemStateOf(r) == VItemState.processed).length;
          final videos = receipts.where((r) => r.isVideo).length;
          final lag = medianDays(recordLagsDays(receipts));
          final failing = receipts.where((r) => r.extractionState == 'extraction_failed').length;
          final firmName = (widget.firm?.firmName.isNotEmpty ?? false) ? widget.firm!.firmName : widget.user.firm;
          final plan = widget.firm?.planName ?? '';

          final months = lastMonths(9);
          final volume = <double>[];
          final lagByMonth = <double?>[];
          for (final (y, mo) in months) {
            final inMonth = receipts.where((r) => r.receivedAt != null && r.receivedAt!.year == y && r.receivedAt!.month == mo).toList();
            volume.add(inMonth.length.toDouble());
            final md = medianDays(recordLagsDays(inMonth));
            lagByMonth.add(md?.toDouble());
          }

          final recent = [...receipts]..sort((a, b) => (b.receivedAt ?? DateTime(0)).compareTo(a.receivedAt ?? DateTime(0)));

          final kpis = [
            _Kpi(label: 'Active matters', value: '$open', sub: '${matters.length} total', icon: Icons.folder_open_outlined),
            _Kpi(label: 'Evidence items', value: '${receipts.length}', sub: '$processed processed', icon: Icons.description_outlined),
            _Kpi(
              label: 'Record Lag',
              value: lag == null ? '—' : '${lag}d',
              sub: 'median, all time',
              icon: Icons.trending_down,
              tone: lag == null ? null : (lag < 60 ? VTone.verified : VTone.pending),
            ),
            _Kpi(label: 'Video items', value: '$videos', sub: 'hashed at receipt', icon: Icons.movie_outlined),
          ];

          return AdminPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
  width: double.infinity,
  child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  runSpacing: 12.0,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.firstName.isEmpty ? '$_greeting.' : '$_greeting, ${widget.user.firstName}.',
                          style: VT.h1(context, size: 28.0),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          [if (firmName.isNotEmpty) firmName, if (plan.isNotEmpty) plan, if (plan.isNotEmpty) 'Year ${programYear(widget.firm)}'].join(' · '),
                          style: VT.muted(context),
                        ),
                      ],
                    ),
                    failing == 0
                        ? VBadge(label: 'All systems normal', icon: Icons.check_circle_outline, bg: c.verified.withValues(alpha: 0.1), fg: c.verified, size: 12.0, bold: true)
                        : VBadge(
                            label: '$failing item${failing == 1 ? '' : 's'} need AI reading again',
                            icon: Icons.warning_amber_rounded,
                            bg: c.pending.withValues(alpha: 0.1),
                            fg: c.pending,
                            size: 12.0,
                            bold: true,
                          ),
                  ],
                ),
),
                const SizedBox(height: 32.0),
                LayoutBuilder(builder: (context, box) {
                  final cols = box.maxWidth >= 760 ? 4 : 2;
                  const gap = 16.0;
                  final w = (box.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(spacing: gap, runSpacing: gap, children: [for (final k in kpis) SizedBox(width: w, child: k)]);
                }),
                const SizedBox(height: 32.0),
                LayoutBuilder(builder: (context, box) {
                  final lagCard = _ChartCard(
                    title: 'Record Lag trend',
                    subtitle: 'Days from creation to firm file · median by month received',
                    pill: lag == null
                        ? null
                        : VBadge(
                            label: lag <= kBaselineRecordLagDays ? '−${kBaselineRecordLagDays - lag}d vs baseline' : '+${lag - kBaselineRecordLagDays}d vs baseline',
                            bg: c.verified.withValues(alpha: 0.1),
                            fg: c.verified,
                          ),
                    chart: _LagChart(months: months, values: lagByMonth),
                    legend: Row(
                      children: [
                        _LegendSwatch(color: c.broken.withValues(alpha: 0.4), label: 'Industry baseline ($kBaselineRecordLagDays d)'),
                        const SizedBox(width: 16.0),
                        _LegendSwatch(color: c.teal, label: 'With Verin', textColor: c.tealDeep),
                      ],
                    ),
                  );
                  final volCard = _ChartCard(
                    title: 'Evidence volume',
                    subtitle: 'Items received per month across all matters',
                    chart: _VolumeChart(months: months, values: volume),
                  );
                  if (box.maxWidth < 760) {
                    return Column(children: [lagCard, const SizedBox(height: 24.0), volCard]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Expanded(child: lagCard), const SizedBox(width: 24.0), Expanded(child: volCard)],
                  );
                }),
                const SizedBox(height: 32.0),
                VCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                        child: Text('Recent intake activity', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                      ),
                      if (recent.isEmpty)
                        Padding(padding: const EdgeInsets.all(24.0), child: Text('Nothing received yet.', style: VT.muted(context, size: 13.0))),
                      for (var i = 0; i < recent.length && i < 6; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                          decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                          child: LayoutBuilder(builder: (context, box) {
                            final r = recent[i];
                            final title = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                                Text(paths[r.matterId?.path]?.title ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.muted(context, size: 11.0)),
                              ],
                            );
                            final when = Text(fmtWhen(r.receivedAt), style: VT.muted(context, size: 11.0));
                            if (box.maxWidth < 560.0) {
                              // Phone: badges + date on one line, the item underneath.
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 6.0,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [ChannelBadge(channel: channelOf(r.channel)), StateBadge(state: itemStateOf(r)), when],
                                  ),
                                  const SizedBox(height: 8.0),
                                  title,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                ChannelBadge(channel: channelOf(r.channel)),
                                const SizedBox(width: 16.0),
                                Expanded(child: title),
                                const SizedBox(width: 12.0),
                                StateBadge(state: itemStateOf(r)),
                                const SizedBox(width: 12.0),
                                when,
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.sub, required this.icon, this.tone});

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final VTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final accent = switch (tone) {
      VTone.verified => c.verified,
      VTone.pending => c.pending,
      VTone.broken => c.broken,
      _ => c.tealDeep,
    };
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: VT.muted(context, size: 12.0))),
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(10.0)),
                child: Icon(icon, size: 14.0, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(value, style: VT.body(context, size: 28.0, weight: FontWeight.w700, color: accent, height: 1.0)),
          const SizedBox(height: 4.0),
          Text(sub, style: VT.muted(context, size: 11.0)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.subtitle, required this.chart, this.pill, this.legend});

  final String title;
  final String subtitle;
  final Widget chart;
  final Widget? pill;
  final Widget? legend;

  @override
  Widget build(BuildContext context) {
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: VT.body(context, size: 13.0, weight: FontWeight.w600))),
              if (pill != null) pill!,
            ],
          ),
          const SizedBox(height: 4.0),
          Text(subtitle, style: VT.muted(context, size: 12.0)),
          const SizedBox(height: 16.0),
          SizedBox(height: 160.0, child: chart),
          if (legend != null) ...[const SizedBox(height: 12.0), legend!],
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label, this.textColor});

  final Color color;
  final String label;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12.0, height: 2.0, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.0))),
        const SizedBox(width: 6.0),
        Text(label, style: VT.body(context, size: 11.0, color: textColor ?? VC.of(context).mutedFg)),
      ],
    );
  }
}

FlTitlesData _titles(BuildContext context, List<(int, int)> months) {
  final c = VC.of(context);
  final style = VT.body(context, size: 10.0, color: c.mutedFg);
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30.0,
        getTitlesWidget: (v, meta) => Text(meta.formattedValue, style: style),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        reservedSize: 22.0,
        getTitlesWidget: (v, meta) {
          final i = v.round();
          if (i < 0 || i >= months.length || (v - i).abs() > 0.01) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(_months[months[i].$2 - 1], style: style));
        },
      ),
    ),
  );
}

FlGridData _grid(BuildContext context, {bool vertical = true}) {
  final c = VC.of(context);
  return FlGridData(
    show: true,
    drawVerticalLine: vertical,
    getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1.0, dashArray: const [3, 3]),
    getDrawingVerticalLine: (_) => FlLine(color: c.border, strokeWidth: 1.0, dashArray: const [3, 3]),
  );
}

class _LagChart extends StatelessWidget {
  const _LagChart({required this.months, required this.values});

  final List<(int, int)> months;
  final List<double?> values;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        if (values[i] != null) FlSpot(i.toDouble(), values[i]!),
    ];
    final maxY = [kBaselineRecordLagDays.toDouble(), ...spots.map((s) => s.y)].reduce((a, b) => a > b ? a : b) * 1.1;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: _grid(context),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, months),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.card,
            tooltipBorder: BorderSide(color: c.border),
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  s.barIndex == 0 ? 'Baseline ${s.y.round()}d' : '${_months[months[s.x.round()].$2 - 1]}: ${s.y.round()}d median',
                  VT.body(context, size: 12.0),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, kBaselineRecordLagDays.toDouble()), FlSpot((months.length - 1).toDouble(), kBaselineRecordLagDays.toDouble())],
            color: c.broken.withValues(alpha: 0.3),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
            show: spots.isNotEmpty,
            isCurved: true,
            preventCurveOverShooting: true,
            color: c.teal,
            barWidth: 2.0,
            dotData: FlDotData(show: spots.length < 3),
          ),
        ],
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.months, required this.values});

  final List<(int, int)> months;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final maxV = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxV <= 0 ? 4 : maxV * 1.2,
        gridData: _grid(context, vertical: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, months),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.card,
            tooltipBorder: BorderSide(color: c.border),
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${_months[months[group.x].$2 - 1]}: ${rod.toY.round()} item${rod.toY.round() == 1 ? '' : 's'}',
              VT.body(context, size: 12.0),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: c.teal,
                  width: 14.0,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
