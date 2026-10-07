// Chronology export (opens in Excel): one row per message of the assembled
// thread, plus one per item that isn't a conversation (documents, emails,
// photos), in date order. Both dates on every row — when it happened and
// when the firm received it — with how the date was worked out, its
// confidence and flags. Reviewer notes sit in their own columns, apart from
// what Verin read.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/corrections.dart';
import '../data/format.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../data/save_file.dart';
import '../widgets/atoms.dart';

String _cell(Object? v) {
  final s = '${v ?? ''}';
  return RegExp(r'[",\n\r]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
}

String chronologyCsv({
  required MattersRecord matter,
  required ThreadDoc? thread,
  required List<ReceiptsRecord> receipts,
  required Map<String, Map<String, Correction>> corrections,
}) {
  final byId = {for (final r in receipts) r.reference.id: r};
  final header = [
    'Event date', 'Event time', 'How the date was found', 'Date confidence', 'Who', 'What it says', 'Flags',
    'Received by firm', 'Channel', 'Source file', 'Item SHA-256', 'Chain entry',
    'Reviewer: text', 'Reviewer: date', 'Reviewer: placement', 'Reviewer',
  ];
  final rows = <(String, List<Object?>)>[];
  final inThread = <String>{};
  for (final e in thread?.entries ?? const <TEntry>[]) {
    if (!e.isMessage && !e.isGap) continue;
    final r = byId[e.rid];
    if (r != null) inThread.add(e.rid);
    final fix = corrections[correctionTarget(e.rid, 'm', e.index)] ?? const <String, Correction>{};
    final who = e.isGap ? '' : (e.isClient ? (matter.clientName.isEmpty ? 'Client' : matter.clientName) : (e.person.isNotEmpty ? e.person : (e.sender.isNotEmpty ? e.sender : 'Other party')));
    rows.add((
      '${e.date} ${e.time}',
      [
        e.date.isEmpty ? '' : fmtYmd(e.date),
        e.time,
        e.isGap ? '' : e.dateBasisLabel,
        e.dateConfidence,
        who,
        e.isGap ? 'GAP — messages may be missing here${e.reason.isEmpty ? '' : ' (${e.reason})'}' : e.text,
        e.flags.join('; '),
        fmtWhen(r?.receivedAt),
        r == null ? '' : channelLabel(channelOf(r.channel)),
        r?.fileName ?? '',
        r?.itemHash ?? '',
        r == null || r.chainSeq == 0 ? '' : '#${r.chainSeq}',
        fix['text']?.corrected ?? '',
        fix['date']?.corrected ?? '',
        fix['thread']?.corrected ?? '',
        {for (final c in fix.values) c.byName}.where((n) => n.isNotEmpty).join('; '),
      ],
    ));
  }
  for (final r in receipts) {
    if (r.isDuplicate || inThread.contains(r.reference.id)) continue;
    final d = r.resolvedDate;
    final state = itemStateOf(r);
    rows.add((
      d == null ? '' : d.toIso8601String(),
      [
        d == null ? '' : fmtDay(d),
        '',
        r.dateSource.isEmpty ? (d == null ? 'no date found' : '') : r.dateSource,
        r.dateConfidence,
        '',
        r.aiSummary.isNotEmpty ? r.aiSummary : r.headline,
        state == VItemState.processed ? '' : labelForState(state).toLowerCase(),
        fmtWhen(r.receivedAt),
        channelLabel(channelOf(r.channel)),
        r.fileName,
        r.itemHash,
        r.chainSeq == 0 ? '' : '#${r.chainSeq}',
        '', '', '', '',
      ],
    ));
  }
  // Dated rows in order; undated rows last, in the order they came.
  final dated = rows.where((x) => x.$1.trim().isNotEmpty).toList()..sort((a, b) => a.$1.compareTo(b.$1));
  final undated = rows.where((x) => x.$1.trim().isEmpty);
  final title = [matter.title, if (matter.caseNumber.isNotEmpty) matter.caseNumber].join(' · ');
  return [
    _cell('Chronology — $title (exported ${fmtWhen(DateTime.now())})'),
    header.map(_cell).join(','),
    for (final r in [...dated, ...undated]) r.$2.map(_cell).join(','),
  ].join('\r\n');
}

class ChronologyExportButton extends StatefulWidget {
  const ChronologyExportButton({super.key, required this.matter, required this.thread, required this.receipts});

  final MattersRecord matter;
  final ThreadDoc? thread;
  final List<ReceiptsRecord> receipts;

  @override
  State<ChronologyExportButton> createState() => _ChronologyExportButtonState();
}

class _ChronologyExportButtonState extends State<ChronologyExportButton> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final corr = await matterCorrectionsStream(widget.matter.reference).first;
      final csv = chronologyCsv(matter: widget.matter, thread: widget.thread, receipts: widget.receipts, corrections: corr);
      final name = '${widget.matter.title.replaceAll(RegExp(r'[^A-Za-z0-9 ._-]'), '').trim()} chronology.csv';
      final saved = await saveTextFile(name, csv, mime: 'text/csv');
      if (!mounted) return;
      if (saved) {
        showVToast(context, 'Chronology downloaded', description: 'Opens in Excel. Reviewer notes are in their own columns.');
      } else {
        await copyToClipboard(context, csv, what: 'Chronology copied');
      }
    } catch (e) {
      if (mounted) showVToast(context, 'Could not export the chronology', error: true, description: '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => VButton(
        label: 'Chronology (Excel)',
        icon: Icons.table_view_outlined,
        kind: VButtonKind.secondary,
        size: VButtonSize.sm,
        loading: _busy,
        onPressed: _busy ? null : _export,
      );
}
