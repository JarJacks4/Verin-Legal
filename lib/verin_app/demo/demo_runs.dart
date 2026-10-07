// Checklist #8 — every demo is timed and logged. A timer in the demo banner
// starts a run; ending it records items in and out, pipeline minutes (read
// from the receipts that arrived during the run), review-queue minutes,
// write-back time and the firm's own estimate of hours by hand. The log
// replaces illustrative figures with measured ones.

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import 'demo_store.dart';

String _mmss(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String fmtMinutes(double? m) {
  if (m == null) return '—';
  if (m < 1) return '${(m * 60).round()} s';
  return '${m.toStringAsFixed(m < 10 ? 1 : 0)} min';
}

/// Start / stop control shown in the demo banner.
class DemoRunTimer extends StatefulWidget {
  const DemoRunTimer({super.key, required this.fg, this.narrow = false});

  final Color fg;
  final bool narrow;

  @override
  State<DemoRunTimer> createState() => _DemoRunTimerState();
}

class _DemoRunTimerState extends State<DemoRunTimer> {
  late final Stream<List<DemoRun>> _runs = firmDemoRunsStream();
  Timer? _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.fg;
    final style = TextButton.styleFrom(foregroundColor: fg, padding: const EdgeInsets.symmetric(horizontal: 8.0), minimumSize: const Size(0, 28.0));
    return StreamBuilder<List<DemoRun>>(
      stream: _runs,
      builder: (context, snap) {
        final running = (snap.data ?? const <DemoRun>[]).where((r) => r.running).toList();
        final run = running.isEmpty ? null : running.first;
        if (_busy) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(width: 14.0, height: 14.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: fg)),
          );
        }
        if (run == null) {
          return TextButton.icon(
            style: style,
            onPressed: () async {
              setState(() => _busy = true);
              try {
                await startDemoRun();
              } catch (e) {
                if (context.mounted) showVToast(context, 'Could not start the timer', error: true, description: '$e');
              }
              if (mounted) setState(() => _busy = false);
            },
            icon: const Icon(Icons.timer_outlined, size: 15.0),
            label: Text(widget.narrow ? 'Time' : 'Time this demo', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: fg)),
          );
        }
        final started = run.startedAt ?? DateTime.now();
        final elapsed = DateTime.now().difference(started);
        final over = elapsed.inMinutes >= 20;
        return TextButton.icon(
          style: style,
          onPressed: () => showEndDemoRun(context, run),
          icon: Icon(Icons.stop_circle_outlined, size: 15.0, color: over ? const Color(0xFF8C3A3F) : fg),
          label: Text(
            widget.narrow ? _mmss(elapsed) : '${_mmss(elapsed)} · End demo',
            style: VT.mono(context, size: 12.0, weight: FontWeight.w600, color: over ? const Color(0xFF8C3A3F) : fg),
          ),
        );
      },
    );
  }
}

/// Ends a run: shows what was measured and asks for the rest.
Future<void> showEndDemoRun(BuildContext context, DemoRun run) async {
  final started = run.startedAt ?? DateTime.now();
  final counts = await measureDemoRun(started).catchError((_) => const DemoRunCounts(itemsIn: 0, itemsOut: 0, flagged: 0));
  if (!context.mounted) return;
  await showVDrawer<void>(
    context,
    title: 'End demo and log it',
    builder: (ctx) => _EndRunForm(run: run, counts: counts, started: started),
  );
}

class _EndRunForm extends StatefulWidget {
  const _EndRunForm({required this.run, required this.counts, required this.started});

  final DemoRun run;
  final DemoRunCounts counts;
  final DateTime started;

  @override
  State<_EndRunForm> createState() => _EndRunFormState();
}

class _EndRunFormState extends State<_EndRunForm> {
  final _prospect = TextEditingController();
  final _matter = TextEditingController();
  final _review = TextEditingController();
  final _writeBack = TextEditingController();
  final _hours = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_prospect, _matter, _review, _writeBack, _hours, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save({bool discard = false}) async {
    setState(() => _saving = true);
    try {
      if (discard) {
        await discardDemoRun(widget.run.id);
      } else {
        await finishDemoRun(widget.run.id, {
          'prospectFirm': _prospect.text.trim(),
          'matterName': _matter.text.trim(),
          'itemsIn': widget.counts.itemsIn,
          'itemsOut': widget.counts.itemsOut,
          'itemsFlagged': widget.counts.flagged,
          'pipelineMinutes': widget.counts.pipelineMinutes,
          'reviewMinutes': _num(_review),
          'writeBackSeconds': _num(_writeBack),
          'firmHoursByHand': _num(_hours),
          'notes': _notes.text.trim(),
        });
      }
      if (mounted) {
        Navigator.of(context).maybePop();
        showVToast(context, discard ? 'Run discarded' : 'Demo logged', description: discard ? null : 'See Admin → Settings → Demo runs.');
      }
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save the run', error: true, description: '$e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final k = widget.counts;
    final elapsed = DateTime.now().difference(widget.started);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Measured automatically', style: VT.eyebrow(context)),
        const SizedBox(height: 10.0),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: [
            _Fact('Demo length', _mmss(elapsed), warn: elapsed.inMinutes >= 20),
            _Fact('Items in', '${k.itemsIn}'),
            _Fact('Processed', '${k.itemsOut}'),
            _Fact('Flagged', '${k.flagged}'),
            _Fact('Pipeline time', fmtMinutes(k.pipelineMinutes)),
          ],
        ),
        const SizedBox(height: 6.0),
        Text('Counts are items that arrived in this workspace since the timer started.', style: VT.muted(context, size: 12.0)),
        const SizedBox(height: 20.0),
        VTextField(controller: _prospect, label: 'Prospect firm', hint: 'e.g. Smith & Lane LLP'),
        const SizedBox(height: 12.0),
        VTextField(controller: _matter, label: 'Matter shown', hint: 'Their closed matter, or which sample matter'),
        const SizedBox(height: 12.0),
        VTextField(controller: _review, label: 'Review-queue minutes', hint: 'Time spent clearing uncertain items', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12.0),
        VTextField(controller: _writeBack, label: 'Write-back time (seconds)', hint: 'Push to Clio until it appeared on the matter', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12.0),
        VTextField(controller: _hours, label: "Firm's estimate of hours by hand", hint: 'Ask: how long would this take your staff?', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12.0),
        VTextField(controller: _notes, label: 'Notes', hint: 'Questions asked, anything that failed', maxLines: 3),
        const SizedBox(height: 20.0),
        VButton(label: 'Save to demo log', icon: Icons.check, loading: _saving, onPressed: _saving ? null : () => _save()),
        const SizedBox(height: 8.0),
        VButton(label: 'Discard this run', kind: VButtonKind.link, onPressed: _saving ? null : () => _save(discard: true)),
        Divider(color: c.border, height: 32.0),
        Text('Rehearsal gate (#14): five runs on five different closed matters, each inside 20 minutes.', style: VT.muted(context, size: 12.0)),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: 132.0,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: warn ? c.brokenBg : c.secondary,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: VT.h3(context, size: 18.0, color: warn ? c.broken : null)),
          Text(label, style: VT.muted(context, size: 11.5)),
        ],
      ),
    );
  }
}

/// Admin → Settings in a demo workspace: this workspace's logged runs.
class DemoRunsLog extends StatefulWidget {
  const DemoRunsLog({super.key});

  @override
  State<DemoRunsLog> createState() => _DemoRunsLogState();
}

class _DemoRunsLogState extends State<DemoRunsLog> {
  late final Stream<List<DemoRun>> _runs = firmDemoRunsStream();

  @override
  Widget build(BuildContext context) => StreamBuilder<List<DemoRun>>(
        stream: _runs,
        builder: (context, s) => DemoRunsCard(runs: s.data ?? const <DemoRun>[]),
      );
}

/// The run log with medians — the numbers to quote instead of illustrative ones.
class DemoRunsCard extends StatelessWidget {
  const DemoRunsCard({super.key, required this.runs});

  final List<DemoRun> runs;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final done = runs.where((r) => rStatus(r) == 'done').toList();
    List<double> pick(double? Function(DemoRun) f) => [for (final r in done) f(r)].whereType<double>().toList();
    final under20 = done.where((r) => (r.totalMinutes ?? 99) <= 20).length;
    final distinctMatters = done.map((r) => r.matter.trim().toLowerCase()).where((m) => m.isNotEmpty).toSet().length;
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const VIconCircle(icon: Icons.timer_outlined),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demo runs', style: VT.body(context, weight: FontWeight.w600)),
                    Text('Start the timer from the yellow demo banner. Medians of logged runs:', style: VT.muted(context, size: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              _Fact('Runs logged', '${done.length}'),
              _Fact('Inside 20 min', '$under20 of ${done.length}', warn: done.isNotEmpty && under20 < done.length),
              _Fact('Distinct matters', '$distinctMatters'),
              _Fact('Demo length', fmtMinutes(median(pick((r) => r.totalMinutes)))),
              _Fact('Pipeline', fmtMinutes(median(pick((r) => r.pipelineMinutes)))),
              _Fact('Review queue', fmtMinutes(median(pick((r) => r.reviewMinutes)))),
              _Fact('Write-back', fmtMinutes(median(pick((r) => r.writeBackSeconds == null ? null : r.writeBackSeconds! / 60.0)))),
              _Fact('Firm est. by hand', median(pick((r) => r.firmHoursByHand)) == null ? '—' : '${median(pick((r) => r.firmHoursByHand))!.toStringAsFixed(1)} h'),
            ],
          ),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            for (final r in done.take(12))
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [r.prospect.isEmpty ? 'Internal run' : r.prospect, if (r.matter.isNotEmpty) r.matter].join(' · '),
                            style: VT.body(context, size: 13.0, weight: FontWeight.w600),
                          ),
                          Text(
                            '${r.startedAt == null ? '' : _date(r.startedAt!)} · ${r.ranBy} · ${r.itemsIn} in, ${r.itemsOut} processed, ${r.itemsFlagged} flagged'
                            '${r.notes.isEmpty ? '' : ' · ${r.notes}'}',
                            style: VT.muted(context, size: 12.0),
                          ),
                        ],
                      ),
                    ),
                    Text(fmtMinutes(r.totalMinutes), style: VT.mono(context, size: 12.0, color: (r.totalMinutes ?? 0) > 20 ? c.broken : null)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String rStatus(DemoRun r) => (r.d['status'] is String) ? r.d['status'] as String : '';

String _date(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}
