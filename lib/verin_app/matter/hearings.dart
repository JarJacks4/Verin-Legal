// Hearing and filing dates on a matter (Matters/{id}.hearings: [{ at, title }]),
// the "next hearing" line in the matter header, and the upcoming-hearings
// card on the Matters list. In-app reminders: a hearing within a week is
// highlighted wherever it shows.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

class Hearing {
  const Hearing(this.at, this.title);
  final DateTime at;
  final String title;

  Map<String, dynamic> toMap() => {'at': Timestamp.fromDate(at), 'title': title};

  int daysAway(DateTime now) => DateTime(at.year, at.month, at.day).difference(DateTime(now.year, now.month, now.day)).inDays;
}

List<Hearing> hearingsOf(MattersRecord m) {
  final v = m.snapshotData['hearings'];
  if (v is! List) return const [];
  final out = <Hearing>[];
  for (final h in v.whereType<Map>()) {
    final d = rDate(Map<String, dynamic>.from(h), 'at');
    if (d != null) out.add(Hearing(d, '${h['title'] ?? ''}'.trim()));
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

Hearing? nextHearing(MattersRecord m, [DateTime? now]) {
  final n = now ?? DateTime.now();
  for (final h in hearingsOf(m)) {
    if (h.daysAway(n) >= 0) return h;
  }
  return null;
}

String _away(int d) => d == 0 ? 'today' : (d == 1 ? 'tomorrow' : 'in $d days');

/// Header line: "Next: Custody hearing · Oct 21, 2026 (in 14 days) · Edit".
class HearingLine extends StatelessWidget {
  const HearingLine({super.key, required this.matter});

  final MattersRecord matter;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final h = nextHearing(matter);
    final soon = h != null && h.daysAway(DateTime.now()) <= 7;
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: VHover(
        onTap: () => showHearingsEditor(context, matter),
        builder: (context, hovered) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, size: 14.0, color: soon ? c.pending : (hovered ? c.teal : c.mutedFg)),
            const SizedBox(width: 6.0),
            Flexible(
              child: Text(
                h == null
                    ? 'Add a hearing or filing date'
                    : '${h.title.isEmpty ? 'Hearing' : h.title} · ${fmtDay(h.at)} (${_away(h.daysAway(DateTime.now()))})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VT.body(context, size: 12.5, weight: soon ? FontWeight.w600 : FontWeight.w400, color: soon ? c.pending : (hovered ? c.teal : c.mutedFg)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showHearingsEditor(BuildContext context, MattersRecord matter) => showVDrawer<void>(
      context,
      title: 'Hearing and filing dates',
      builder: (_) => _HearingsEditor(matter: matter),
    );

class _HearingsEditor extends StatefulWidget {
  const _HearingsEditor({required this.matter});

  final MattersRecord matter;

  @override
  State<_HearingsEditor> createState() => _HearingsEditorState();
}

class _HearingsEditorState extends State<_HearingsEditor> {
  late List<Hearing> _list = hearingsOf(widget.matter);
  final _title = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save(List<Hearing> next) async {
    setState(() => _saving = true);
    try {
      next.sort((a, b) => a.at.compareTo(b.at));
      await widget.matter.reference.update({'hearings': [for (final h in next) h.toMap()]});
      if (mounted) setState(() => _list = next);
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save', error: true, description: '$e');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _add() async {
    final d = _date;
    if (d == null) {
      showVToast(context, 'Pick a date first', error: true);
      return;
    }
    final t = _time ?? const TimeOfDay(hour: 9, minute: 0);
    final at = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    await _save([..._list, Hearing(at, _title.text.trim().isEmpty ? 'Hearing' : _title.text.trim())]);
    if (mounted) {
      _title.clear();
      setState(() {
        _date = null;
        _time = null;
      });
      showVToast(context, 'Date added');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Shown on the matter and in Upcoming hearings on the Matters list. Dates within a week are highlighted.', style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 16.0),
        if (_list.isEmpty) Text('No dates yet.', style: VT.muted(context, size: 13.0)),
        for (final h in _list)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.title, style: VT.body(context, size: 13.5, weight: FontWeight.w600, color: h.daysAway(now) < 0 ? c.mutedFg : null)),
                      Text('${fmtWhen(h.at)}${h.daysAway(now) >= 0 ? ' · ${_away(h.daysAway(now))}' : ' · past'}', style: VT.muted(context, size: 12.0)),
                    ],
                  ),
                ),
                VIconButton(icon: Icons.delete_outline, tooltip: 'Remove', onPressed: _saving ? null : () => _save([..._list]..remove(h))),
              ],
            ),
          ),
        const SizedBox(height: 20.0),
        Text('ADD A DATE', style: VT.eyebrow(context, size: 11.0)),
        const SizedBox(height: 8.0),
        VTextField(controller: _title, label: 'What', hint: 'e.g. Custody hearing, Response due'),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: VButton(
                label: _date == null ? 'Pick date' : fmtDay(_date),
                icon: Icons.calendar_today_outlined,
                kind: VButtonKind.secondary,
                size: VButtonSize.sm,
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _date ?? now, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 5));
                  if (d != null) setState(() => _date = d);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: VButton(
                label: _time == null ? 'Time (optional)' : _time!.format(context),
                icon: Icons.schedule,
                kind: VButtonKind.secondary,
                size: VButtonSize.sm,
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0));
                  if (t != null) setState(() => _time = t);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        VButton(label: 'Add date', icon: Icons.add, loading: _saving, onPressed: _saving ? null : _add),
      ],
    );
  }
}

/// Matters list: hearings in the next 30 days across the firm's open matters.
class UpcomingHearingsCard extends StatelessWidget {
  const UpcomingHearingsCard({super.key, required this.matters, required this.onOpen});

  final List<MattersRecord> matters;
  final void Function(MattersRecord) onOpen;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final now = DateTime.now();
    final rows = <(MattersRecord, Hearing)>[
      for (final m in matters)
        if (matterIsOpen(m))
          for (final h in hearingsOf(m))
            if (h.daysAway(now) >= 0 && h.daysAway(now) <= 30) (m, h),
    ]..sort((a, b) => a.$2.at.compareTo(b.$2.at));
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: VCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('UPCOMING HEARINGS · NEXT 30 DAYS', style: VT.eyebrow(context, size: 11.0)),
            const SizedBox(height: 8.0),
            for (final (m, h) in rows.take(6))
              VHover(
                onTap: () => onOpen(m),
                builder: (context, hovered) {
                  final soon = h.daysAway(now) <= 7;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined, size: 15.0, color: soon ? c.pending : c.mutedFg),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: h.title, style: VT.body(context, size: 13.0, weight: FontWeight.w600, color: hovered ? c.teal : null)),
                              TextSpan(text: ' · ${m.title}', style: VT.muted(context, size: 13.0)),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${fmtDay(h.at)} · ${_away(h.daysAway(now))}', style: VT.body(context, size: 12.0, weight: soon ? FontWeight.w600 : FontWeight.w400, color: soon ? c.pending : c.mutedFg)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
