// Measured business value (Differentiator 6).
//
// What Verin did and what it saved, from the firm's own activity:
//   processing volume — items, messages, passages, minutes of recordings read
//   review time       — time staff actually spent in the verification view
//   corrections       — how often a reviewer had to fix a reading
//   time saved        — manual baseline for that same work, minus review time
//
// The manual baseline starts as an estimate and becomes measured when the firm
// times a manual sample (Measure baseline). The report always says which.

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

/// Minutes of manual work per unit, and the billing rate used for value.
class ValueBaseline {
  ValueBaseline(Map<String, dynamic>? b)
      : perMessage = _n(b?['perMessage'], 0.75),
        perItem = _n(b?['perItem'], 1.5),
        perDocument = _n(b?['perDocument'], 6.0),
        perPhoto = _n(b?['perPhoto'], 2.0),
        perRecordingMinute = _n(b?['perRecordingMinute'], 4.0),
        hourlyRate = _n(b?['hourlyRate'], 145.0),
        measured = b?['source'] == 'measured',
        measuredAt = (b?['measuredAt'] as Timestamp?)?.toDate(),
        sampleNote = '${b?['sampleNote'] ?? ''}';

  final double perMessage, perItem, perDocument, perPhoto, perRecordingMinute, hourlyRate;
  final bool measured;
  final DateTime? measuredAt;
  final String sampleNote;

  static double _n(Object? v, double d) => v is num && v > 0 ? v.toDouble() : d;

  static ValueBaseline of(FirmAccountRecord? f) {
    final b = f?.snapshotData['valueBaseline'];
    return ValueBaseline(b is Map ? Map<String, dynamic>.from(b) : null);
  }

  /// Manual minutes for one "read" event.
  double manualMinutes(Map<String, dynamic> e) {
    if (e['duplicate'] == true) return perItem; // someone would have had to spot it
    final msgs = (e['messages'] is num) ? (e['messages'] as num).toDouble() : 0.0;
    final secs = (e['durationSeconds'] is num) ? (e['durationSeconds'] as num).toDouble() : 0.0;
    final kind = '${e['itemKind'] ?? ''}';
    final type = '${e['evidenceType'] ?? ''}';
    if (msgs > 0) return perItem + msgs * perMessage;
    if (kind == 'video' || kind == 'audio' || kind == 'screen_recording') return perItem + (secs / 60.0) * perRecordingMinute;
    if (type == 'document' || type == 'email' || kind == 'document' || kind == 'email') return perDocument;
    return perPhoto;
  }
}

class _Totals {
  int items = 0, duplicates = 0, messages = 0, statements = 0, corrections = 0, reviews = 0, followUps = 0, exhibits = 0, pages = 0;
  double recordingMinutes = 0, manualMin = 0, reviewMin = 0;
  final Set<String> reviewedItems = {};
  double get savedMin => math.max(0, manualMin - reviewMin);
  double get correctionRate => (messages + statements) == 0 ? 0 : corrections / (messages + statements);
}

class ValueReport extends StatefulWidget {
  const ValueReport({super.key, required this.firm});
  final FirmAccountRecord? firm;

  @override
  State<ValueReport> createState() => _ValueReportState();
}

class _ValueReportState extends State<ValueReport> {
  int _days = 90;
  late Stream<List<Map<String, dynamic>>> _events = _stream();

  Stream<List<Map<String, dynamic>>> _stream() {
    var q = FirebaseFirestore.instance.collection('Activity').where('firmID', isEqualTo: currentFirmId());
    if (_days > 0) q = q.where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(Duration(days: _days))));
    return q.orderBy('at').limit(20000).snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  _Totals _sum(List<Map<String, dynamic>> events, ValueBaseline b) {
    final t = _Totals();
    for (final e in events) {
      switch (e['type']) {
        case 'read':
          t.items++;
          if (e['duplicate'] == true) t.duplicates++;
          t.messages += (e['messages'] as num?)?.toInt() ?? 0;
          t.statements += (e['statements'] as num?)?.toInt() ?? 0;
          t.recordingMinutes += ((e['durationSeconds'] as num?)?.toDouble() ?? 0) / 60.0;
          t.manualMin += b.manualMinutes(e);
        case 'review':
          t.reviews++;
          t.reviewMin += ((e['durationMs'] as num?)?.toDouble() ?? 0) / 60000.0;
          final r = e['receiptId'];
          if (r is DocumentReference) t.reviewedItems.add(r.id);
        case 'correction':
          t.corrections++;
        case 'follow_up_sent':
          t.followUps += (e['requests'] as num?)?.toInt() ?? 1;
        case 'export':
          t.exhibits += (e['exhibits'] as num?)?.toInt() ?? 0;
          t.pages += (e['pages'] as num?)?.toInt() ?? 0;
      }
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final b = ValueBaseline.of(widget.firm);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _events,
      builder: (context, snap) {
        final events = snap.data ?? const <Map<String, dynamic>>[];
        final t = _sum(events, b);
        final savedH = t.savedMin / 60.0;
        final perItemReview = t.reviewedItems.isEmpty ? 0.0 : t.reviewMin / t.reviewedItems.length;
        return VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10.0,
                spacing: 12.0,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Measured value', style: VT.body(context, size: 15.0, weight: FontWeight.w600)),
                      Text(
                        b.measured
                            ? 'Against your measured manual baseline${b.measuredAt != null ? ' (${fmtDay(b.measuredAt)})' : ''}'
                            : 'Against an estimated manual baseline — measure yours for figures you can take to a renewal',
                        style: VT.muted(context, size: 12.0),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 300.0,
                    child: VSegmented<int>(
                      value: _days,
                      options: const [30, 90, 365, 0],
                      labelFor: (d) => d == 0 ? 'All' : d == 365 ? '12 mo' : '$d days',
                      fontSize: 12.0,
                      onChanged: (d) => setState(() {
                        _days = d;
                        _events = _stream();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              if (snap.hasError)
                VErrorBox(
                  message: '${snap.error}'.contains('index')
                      ? 'The value report needs a Firestore index — deploy firestore:indexes.'
                      : 'Activity could not be loaded: ${snap.error}',
                )
              else if (!snap.hasData)
                const VLoading()
              else ...[
                LayoutBuilder(builder: (context, box) {
                  final cols = box.maxWidth >= 760 ? 4 : 2;
                  final w = (box.maxWidth - (cols - 1) * 12.0) / cols;
                  return Wrap(spacing: 12.0, runSpacing: 12.0, children: [
                    SizedBox(width: w, child: _tile(context, 'Hours saved', savedH.toStringAsFixed(savedH < 10 ? 1 : 0), '≈ \$${(savedH * b.hourlyRate).round()} of time at \$${b.hourlyRate.round()}/hr')),
                    SizedBox(width: w, child: _tile(context, 'Items processed', '${t.items}', '${t.messages} messages · ${t.statements} passages${t.recordingMinutes >= 1 ? ' · ${t.recordingMinutes.round()} min recorded' : ''}')),
                    SizedBox(width: w, child: _tile(context, 'Review time', '${t.reviewMin.toStringAsFixed(t.reviewMin < 10 ? 1 : 0)} min', t.reviewedItems.isEmpty ? 'no reviews yet' : '${perItemReview.toStringAsFixed(1)} min per item reviewed')),
                    SizedBox(width: w, child: _tile(context, 'Correction rate', '${(t.correctionRate * 100).toStringAsFixed(1)}%', '${t.corrections} correction${t.corrections == 1 ? '' : 's'} to the AI\'s reading')),
                  ]);
                }),
                const SizedBox(height: 12.0),
                Text(
                  '${t.duplicates} exact duplicate${t.duplicates == 1 ? '' : 's'} caught · ${t.followUps} follow-up request${t.followUps == 1 ? '' : 's'} sent · ${t.exhibits} exhibits (${t.pages} pages) produced',
                  style: VT.muted(context, size: 12.0),
                ),
                const SizedBox(height: 20.0),
                Text('Hours saved by month', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                const SizedBox(height: 8.0),
                SizedBox(height: 180.0, child: _SavedChart(events: events, baseline: b)),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(10.0)),
                  child: Text(
                    'Manual baseline: ${b.perMessage.toStringAsFixed(2)} min per message, ${b.perItem.toStringAsFixed(1)} min to file each item, '
                    '${b.perDocument.toStringAsFixed(0)} min per document, ${b.perPhoto.toStringAsFixed(0)} min per photo, '
                    '${b.perRecordingMinute.toStringAsFixed(0)} min per minute of recording. Time saved = that manual time − time spent reviewing in Verin.',
                    style: VT.body(context, size: 11.5, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12.0),
                Wrap(spacing: 10.0, runSpacing: 8.0, children: [
                  VButton(label: 'Measure our baseline', icon: Icons.timer_outlined, kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: () => _measure(b)),
                  VButton(label: 'Edit rates', kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: () => _editRates(b)),
                  VButton(
                    label: 'Copy report (CSV)',
                    icon: Icons.content_copy,
                    kind: VButtonKind.link,
                    size: VButtonSize.sm,
                    onPressed: () => copyToClipboard(context, _csv(events, b), what: 'Report copied — paste into a spreadsheet'),
                  ),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, String label, String value, String sub) {
    final c = VC.of(context);
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: VT.muted(context, size: 12.0)),
          const SizedBox(height: 6.0),
          Text(value, style: VT.h1(context, size: 28.0)),
          const SizedBox(height: 4.0),
          Text(sub, style: VT.muted(context, size: 11.0)),
        ],
      ),
    );
  }

  String _csv(List<Map<String, dynamic>> events, ValueBaseline b) {
    final byMonth = <String, List<Map<String, dynamic>>>{};
    for (final e in events) {
      final at = (e['at'] as Timestamp?)?.toDate();
      if (at == null) continue;
      byMonth.putIfAbsent('${at.year}-${at.month.toString().padLeft(2, '0')}', () => []).add(e);
    }
    final rows = ['month,items,duplicates,messages,passages,recording_minutes,review_minutes,corrections,correction_rate,manual_minutes,hours_saved,value_usd,baseline'];
    for (final m in byMonth.keys.toList()..sort()) {
      final t = _sum(byMonth[m]!, b);
      rows.add([
        m,
        t.items,
        t.duplicates,
        t.messages,
        t.statements,
        t.recordingMinutes.toStringAsFixed(1),
        t.reviewMin.toStringAsFixed(1),
        t.corrections,
        (t.correctionRate * 100).toStringAsFixed(2),
        t.manualMin.toStringAsFixed(1),
        (t.savedMin / 60).toStringAsFixed(2),
        (t.savedMin / 60 * b.hourlyRate).round(),
        b.measured ? 'measured' : 'estimated',
      ].join(','));
    }
    return rows.join('\n');
  }

  Future<void> _measure(ValueBaseline b) async {
    final saved = await showVDrawer<bool>(context, title: 'Measure the manual baseline', width: 520.0, builder: (_) => _MeasureForm(firm: widget.firm, baseline: b));
    if (saved == true && mounted) showVToast(context, 'Baseline measured', description: 'The report now uses your firm\'s own timing.');
  }

  Future<void> _editRates(ValueBaseline b) async {
    final saved = await showVDrawer<bool>(context, title: 'Baseline rates', width: 480.0, builder: (_) => _RatesForm(firm: widget.firm, baseline: b));
    if (saved == true && mounted) showVToast(context, 'Rates saved');
  }
}

class _SavedChart extends StatelessWidget {
  const _SavedChart({required this.events, required this.baseline});
  final List<Map<String, dynamic>> events;
  final ValueBaseline baseline;

  static const _m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1)];
    final manual = List<double>.filled(6, 0);
    final review = List<double>.filled(6, 0);
    for (final e in events) {
      final at = (e['at'] as Timestamp?)?.toDate();
      if (at == null) continue;
      final i = months.indexWhere((m) => m.year == at.year && m.month == at.month);
      if (i < 0) continue;
      if (e['type'] == 'read') manual[i] += baseline.manualMinutes(e);
      if (e['type'] == 'review') review[i] += ((e['durationMs'] as num?)?.toDouble() ?? 0) / 60000.0;
    }
    final hours = [for (var i = 0; i < 6; i++) math.max(0.0, manual[i] - review[i]) / 60.0];
    final maxV = hours.reduce(math.max);
    return BarChart(
      BarChartData(
        maxY: maxV <= 0 ? 1 : maxV * 1.25,
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) => Text(v == meta.max ? '' : v.toStringAsFixed(v < 10 ? 1 : 0), style: VT.muted(context, size: 10.0)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(_m[months[v.toInt()].month - 1], style: VT.muted(context, size: 10.0)),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.card,
            tooltipBorder: BorderSide(color: c.border),
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${_m[months[group.x].month - 1]} ${months[group.x].year}: ${rod.toY.toStringAsFixed(1)} h saved',
              VT.body(context, size: 12.0),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < 6; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: hours[i], color: c.teal, width: 18.0, borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0))),
            ]),
        ],
      ),
    );
  }
}

/// Time a real manual sample: start, transcribe some messages the old way,
/// stop, say how many. Minutes per message becomes the measured baseline.
class _MeasureForm extends StatefulWidget {
  const _MeasureForm({required this.firm, required this.baseline});
  final FirmAccountRecord? firm;
  final ValueBaseline baseline;

  @override
  State<_MeasureForm> createState() => _MeasureFormState();
}

class _MeasureFormState extends State<_MeasureForm> {
  DateTime? _start;
  Duration? _elapsed;
  final _count = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _count.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = int.tryParse(_count.text.trim()) ?? 0;
    if (_elapsed == null || n <= 0) {
      setState(() => _error = 'Time a sample and enter how many messages it covered.');
      return;
    }
    final perMsg = (_elapsed!.inSeconds / 60.0) / n;
    final f = widget.firm;
    if (f == null) return;
    setState(() => _busy = true);
    try {
      final cur = f.snapshotData['valueBaseline'];
      await f.reference.update({
        'valueBaseline': {
          if (cur is Map) ...Map<String, dynamic>.from(cur),
          'perMessage': double.parse(perMsg.toStringAsFixed(3)),
          'source': 'measured',
          'measuredAt': FieldValue.serverTimestamp(),
          'sampleMinutes': double.parse((_elapsed!.inSeconds / 60.0).toStringAsFixed(2)),
          'sampleMessages': n,
          'sampleNote': _note.text.trim(),
        },
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = _start != null && _elapsed == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Have someone do a real sample the way the firm did it before Verin: transcribe screenshots into a chronology, with dates and who said what. '
          'Start the timer, do the work, stop it, and enter how many messages were transcribed.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 20.0),
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 12.0)],
        Center(
          child: Text(
            _elapsed != null
                ? '${_elapsed!.inMinutes}:${(_elapsed!.inSeconds % 60).toString().padLeft(2, '0')}'
                : running
                    ? 'Timing… started ${TimeOfDay.fromDateTime(_start!).format(context)}'
                    : 'Not started',
            style: VT.h1(context, size: running ? 18.0 : 32.0),
          ),
        ),
        const SizedBox(height: 12.0),
        VButton(
          label: running ? 'Stop' : (_elapsed != null ? 'Time it again' : 'Start timer'),
          icon: running ? Icons.stop : Icons.play_arrow_rounded,
          kind: running ? VButtonKind.danger : VButtonKind.primary,
          fullWidth: true,
          onPressed: () => setState(() {
            if (running) {
              _elapsed = DateTime.now().difference(_start!);
            } else {
              _start = DateTime.now();
              _elapsed = null;
            }
          }),
        ),
        const SizedBox(height: 16.0),
        VTextField(controller: _count, label: 'Messages transcribed in the sample', hint: '40', keyboardType: TextInputType.number),
        const SizedBox(height: 12.0),
        VTextField(controller: _note, label: 'Note (optional)', hint: 'Paralegal, 6 screenshots of a WhatsApp thread'),
        const SizedBox(height: 8.0),
        Text('Current baseline: ${widget.baseline.perMessage.toStringAsFixed(2)} min per message (${widget.baseline.measured ? 'measured' : 'estimate'}).', style: VT.muted(context, size: 11.0)),
        const SizedBox(height: 20.0),
        VButton(label: 'Save as our baseline', size: VButtonSize.lg, fullWidth: true, loading: _busy, onPressed: _elapsed == null ? null : _save),
      ],
    );
  }
}

class _RatesForm extends StatefulWidget {
  const _RatesForm({required this.firm, required this.baseline});
  final FirmAccountRecord? firm;
  final ValueBaseline baseline;

  @override
  State<_RatesForm> createState() => _RatesFormState();
}

class _RatesFormState extends State<_RatesForm> {
  late final _item = TextEditingController(text: widget.baseline.perItem.toString());
  late final _doc = TextEditingController(text: widget.baseline.perDocument.toString());
  late final _photo = TextEditingController(text: widget.baseline.perPhoto.toString());
  late final _rec = TextEditingController(text: widget.baseline.perRecordingMinute.toString());
  late final _rate = TextEditingController(text: widget.baseline.hourlyRate.toStringAsFixed(0));
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_item, _doc, _photo, _rec, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final f = widget.firm;
    if (f == null) return;
    double v(TextEditingController c, double d) {
      final x = double.tryParse(c.text.trim());
      return x != null && x > 0 ? x : d;
    }

    setState(() => _busy = true);
    try {
      final cur = f.snapshotData['valueBaseline'];
      await f.reference.update({
        'valueBaseline': {
          if (cur is Map) ...Map<String, dynamic>.from(cur),
          'perItem': v(_item, widget.baseline.perItem),
          'perDocument': v(_doc, widget.baseline.perDocument),
          'perPhoto': v(_photo, widget.baseline.perPhoto),
          'perRecordingMinute': v(_rec, widget.baseline.perRecordingMinute),
          'hourlyRate': v(_rate, widget.baseline.hourlyRate),
        },
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showVToast(context, 'Could not save: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget f(TextEditingController c, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: VTextField(controller: c, label: label, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Minutes the same work takes by hand. Per-message time comes from Measure our baseline.', style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 16.0),
        f(_item, 'Minutes to file one item (open, name, log)'),
        f(_doc, 'Minutes to read and log one document or email'),
        f(_photo, 'Minutes to describe and log one photo'),
        f(_rec, 'Minutes to transcribe one minute of recording'),
        f(_rate, 'Hourly rate used for value (\$)'),
        const SizedBox(height: 8.0),
        VButton(label: 'Save rates', size: VButtonSize.lg, fullWidth: true, loading: _busy, onPressed: _save),
      ],
    );
  }
}
