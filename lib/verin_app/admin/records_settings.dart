// Admin → Settings: records, reports and security.
//
//   RecordsSettingsCard  delete-after-delivery and nightly Clio delivery (#16),
//                        weekly digests (#70), two-step sign-in for everyone (#31)
//   BaselineCard         the firm's own pre-Verin Record Lag (#23)
//   ReportsCard          Record Lag Audit (#67), monthly report (#74), cost to
//                        serve (#53)

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_api.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../onboarding/tour.dart' show TourTarget;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

bool _flag(FirmAccountRecord? f, String k, {bool fallback = true}) {
  final v = f?.snapshotData[k];
  return v is bool ? v : fallback;
}

class RecordsSettingsCard extends StatefulWidget {
  const RecordsSettingsCard({super.key, required this.firm});

  final FirmAccountRecord? firm;

  @override
  State<RecordsSettingsCard> createState() => _RecordsSettingsCardState();
}

class _RecordsSettingsCardState extends State<RecordsSettingsCard> {
  final Map<String, bool> _local = {};

  bool _v(String k, {bool fallback = true}) => _local[k] ?? _flag(widget.firm, k, fallback: fallback);

  Future<void> _set(String k, bool v) async {
    final f = widget.firm;
    if (f == null) return;
    setState(() => _local[k] = v);
    try {
      await f.reference.update({k: v});
    } catch (e) {
      if (mounted) {
        setState(() => _local.remove(k));
        showVToast(context, 'Could not save', error: true, description: '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    Widget row(String k, String label, String sub, {bool fallback = true, int i = 1}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                    Text(sub, style: VT.muted(context, size: 12.0)),
                  ],
                ),
              ),
              VSwitch(value: _v(k, fallback: fallback), width: 40.0, onChanged: (x) => _set(k, x)),
            ],
          ),
        );
    return TourTarget(
      id: 'settings_records',
      child: VCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            row('deleteAfterDelivery', "Remove Verin's copy after delivery",
                "Once Clio (or your own download) confirms it has the record, Verin deletes its copy of each finished file. Hashes, timestamps and the audit log stay.",
                i: 0),
            row('autoDeliver', 'Deliver to Clio every night', 'New, finished items on Clio-linked matters are delivered at 2:30 AM. Failures appear as an alert.'),
            row('weeklyDigests', 'Weekly matter digest', 'Monday morning: one page per open matter, added to the matter in Clio when linked.'),
            row('digestEmails', 'Email the digest', "Also emails it to the matter's responsible attorney when one is set."),
            row('requireTwoStep', 'Require two-step sign-in', 'Everyone in the firm must use an authenticator app code to sign in.', fallback: false),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Baseline
// ---------------------------------------------------------------------------

class BaselineCard extends StatelessWidget {
  const BaselineCard({super.key, required this.firm});

  final FirmAccountRecord? firm;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final raw = firm?.snapshotData['baselineRecordLag'];
    final Map<dynamic, dynamic> b = raw is Map ? raw : const {};
    final attempt = firm?.snapshotData['baselineRecordLagAttempt'];
    final has = b['medianDays'] is num;
    return TourTarget(
      id: 'settings_baseline',
      child: VCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VIconCircle(icon: has ? Icons.lock_clock_outlined : Icons.timelapse_outlined),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(has ? 'Your baseline: ${(b['medianDays'] as num).toStringAsFixed((b['medianDays'] as num) % 1 == 0 ? 0 : 1)} days' : 'Baseline Record Lag not captured yet',
                          style: VT.body(context, weight: FontWeight.w600)),
                      Text(
                        has
                            ? '${b['method'] ?? ''} ${b['sample'] != null ? '${b['sample']} items. ' : ''}Locked${b['capturedAt'] is String ? ' ${fmtDay(DateTime.tryParse(b['capturedAt'] as String))}' : ''}${b['capturedBeforeFirstItem'] == true ? ', before Verin received anything.' : '.'}'
                            : attempt is Map
                                ? 'Clio had ${attempt['sample'] ?? 0} dated documents — too few to stand on. Enter a dated sample by hand.'
                                : 'Captured automatically when you connect Clio, before Verin receives anything. Without Clio, enter a dated sample by hand.',
                        style: VT.muted(context, size: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!has) ...[
              const SizedBox(height: 14.0),
              VButton(
                label: 'Enter a dated sample',
                icon: Icons.edit_calendar_outlined,
                kind: VButtonKind.tonal,
                size: VButtonSize.sm,
                onPressed: () => showVDrawer<void>(context, title: 'Baseline Record Lag', tour: 'baseline_entry', builder: (_) => const _BaselineEntry()),
              ),
            ],
            if (has)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text('The baseline cannot be changed once locked, so every later comparison is against the same number.', style: VT.muted(context, size: 11.5).copyWith(color: c.mutedFg)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BaselineEntry extends StatefulWidget {
  const _BaselineEntry();

  @override
  State<_BaselineEntry> createState() => _BaselineEntryState();
}

class _BaselineEntryState extends State<_BaselineEntry> {
  final _rows = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _rows.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Map<String, String>> _parse() {
    final out = <Map<String, String>>[];
    for (final line in _rows.text.split('\n')) {
      final m = RegExp(r'(\d{4}-\d{2}-\d{2})\D+(\d{4}-\d{2}-\d{2})').firstMatch(line);
      if (m != null) out.add({'createdOn': m.group(1)!, 'enteredOn': m.group(2)!});
    }
    return out;
  }

  Future<void> _save() async {
    final items = _parse();
    if (items.length < 10) {
      setState(() => _error = 'Enter at least 10 lines, each with two dates (found ${items.length}).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await VerinApi.setBaselineRecordLag(items, note: _note.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      celebrate(context, title: 'Baseline locked', subtitle: '${items.length} dated items');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is VerinApiException ? e.message : '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _parse().length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pick items from matters handled before Verin. For each, enter the date the material was created (the text, photo or document date) '
          'and the date it entered your file, one item per line. The median becomes your baseline and is locked.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 14.0),
        TourTarget(
          id: 'baseline_rows',
          child: VTextField(controller: _rows, label: 'Created, entered file', hint: '2025-03-02, 2025-07-18\n2025-04-11, 2025-07-18', maxLines: 10, onChanged: (_) => setState(() {})),
        ),
        const SizedBox(height: 6.0),
        Text('$n dated item${n == 1 ? '' : 's'}', style: VT.muted(context, size: 12.0)),
        const SizedBox(height: 12.0),
        VTextField(controller: _note, label: 'Where the sample came from', hint: 'Five closed custody matters, 2025', optional: 'Optional'),
        if (_error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: _error!)],
        const SizedBox(height: 18.0),
        VButton(label: 'Lock baseline', icon: Icons.lock_outline, fullWidth: true, loading: _busy, onPressed: _busy ? null : _save),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

class ReportsCard extends StatelessWidget {
  const ReportsCard({super.key, required this.firm});

  final FirmAccountRecord? firm;

  Future<void> _run(BuildContext context, String working, Future<Map<String, dynamic>> Function() call, String done) async {
    showVToast(context, working);
    try {
      final r = await call();
      if (!context.mounted) return;
      celebrate(context, title: done, subtitle: '${r['fileName'] ?? ''}');
      final url = '${r['downloadUrl'] ?? ''}';
      if (url.isNotEmpty) await launchURL(url);
    } catch (e) {
      if (context.mounted) showVToast(context, 'That did not finish', error: true, description: e is VerinApiException ? e.message : '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    Widget line(IconData icon, String title, String sub, Widget action, {bool first = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
          child: Row(
            children: [
              Icon(icon, size: 18.0, color: c.mutedFg),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                    Text(sub, style: VT.muted(context, size: 12.0)),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              action,
            ],
          ),
        );
    return TourTarget(
      id: 'settings_reports',
      child: VCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            line(
              Icons.query_stats_rounded,
              'Record Lag Audit',
              'Pick matters (often closed ones): headline median, matter table, latest-arriving item and every item listed.',
              VButton(
                label: 'Build',
                size: VButtonSize.sm,
                kind: VButtonKind.tonal,
                onPressed: () => showVDrawer<void>(context, title: 'Record Lag Audit', tour: 'lag_audit', builder: (_) => const _AuditPicker()),
              ),
              first: true,
            ),
            line(
              Icons.calendar_month_outlined,
              'Monthly firm report',
              "Last month's Record Lag against the month before and your baseline, by practice; quiet matters; write-back failures. Built on the 1st automatically.",
              VButton(
                label: 'Last month',
                size: VButtonSize.sm,
                kind: VButtonKind.tonal,
                onPressed: () => _run(context, 'Building the monthly report…', () => VerinApi.exportFirmMonthlyReport(), 'Monthly report ready'),
              ),
            ),
            line(
              Icons.payments_outlined,
              'Cost to serve (this week)',
              'AI reading, messaging and storage for your firm, per active matter.',
              VButton(
                label: 'Show',
                size: VButtonSize.sm,
                kind: VButtonKind.tonal,
                onPressed: () async {
                  try {
                    final r = await VerinApi.costToServeNow();
                    if (!context.mounted) return;
                    final levers = r['levers'] is Map ? r['levers'] as Map : const {};
                    await showVDialog<void>(
                      context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Cost to serve — week from ${r['weekStart'] ?? ''}', style: VT.h2(ctx, size: 18.0)),
                          const SizedBox(height: 12.0),
                          Text('Active matters: ${r['activeMatters'] ?? 0} · items: ${r['items'] ?? 0}', style: VT.body(ctx, size: 13.0)),
                          Text('AI reading: \$${levers['ai'] ?? 0} · messaging: \$${levers['messaging'] ?? 0} · storage: \$${levers['storage'] ?? 0}', style: VT.body(ctx, size: 13.0)),
                          const SizedBox(height: 8.0),
                          Text('Total \$${r['total'] ?? 0} · per active matter ${r['perActiveMatter'] == null ? '—' : '\$${r['perActiveMatter']}'}', style: VT.body(ctx, weight: FontWeight.w600)),
                          const SizedBox(height: 8.0),
                          Text('Estimates from published rates (set in the server settings). Verin staff see every firm weekly.', style: VT.muted(ctx, size: 11.5)),
                          const SizedBox(height: 14.0),
                          VButton(label: 'Close', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop()),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (context.mounted) showVToast(context, 'Could not load', error: true, description: e is VerinApiException ? e.message : '$e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditPicker extends StatefulWidget {
  const _AuditPicker();

  @override
  State<_AuditPicker> createState() => _AuditPickerState();
}

class _AuditPickerState extends State<_AuditPicker> {
  late final Stream<List<MattersRecord>> _matters = firmMattersStream();
  final Set<String> _picked = {};
  bool _busy = false;

  Future<void> _build() async {
    setState(() => _busy = true);
    try {
      final r = await VerinApi.exportRecordLagAudit(_picked.toList());
      if (!mounted) return;
      setState(() => _busy = false);
      celebrate(context, title: 'Audit ready', subtitle: r['medianDays'] == null ? 'No dated items' : 'Median Record Lag ${r['medianDays']} days');
      await launchURL('${r['downloadUrl'] ?? ''}');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showVToast(context, 'The audit could not be built', error: true, description: e is VerinApiException ? e.message : '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MattersRecord>>(
      stream: _matters,
      builder: (context, s) {
        final list = s.data ?? const <MattersRecord>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose up to 25 matters. Closed matters show how late material has been reaching the firm.', style: VT.muted(context, size: 13.0)),
            const SizedBox(height: 12.0),
            TourTarget(
              id: 'audit_matters',
              child: Column(
                children: [
                  for (final m in list)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _picked.contains(m.reference.id),
                      onChanged: (v) => setState(() {
                        if (v == true && _picked.length < 25) {
                          _picked.add(m.reference.id);
                        } else {
                          _picked.remove(m.reference.id);
                        }
                      }),
                      title: Text(m.title.isEmpty ? 'Untitled matter' : m.title, style: VT.body(context, size: 13.5)),
                      subtitle: Text('${matterPractice(m)} · ${m.status.isEmpty ? 'Open' : m.status}', style: VT.muted(context, size: 12.0)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            VButton(
              label: _picked.isEmpty ? 'Choose matters' : 'Build the audit (${_picked.length})',
              icon: Icons.query_stats_rounded,
              fullWidth: true,
              loading: _busy,
              loadingLabel: 'Building…',
              onPressed: _picked.isEmpty || _busy ? null : _build,
            ),
          ],
        );
      },
    );
  }
}
