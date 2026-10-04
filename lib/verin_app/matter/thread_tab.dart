// Thread tab — port of the Make's <ThreadTab>: every message the AI read
// from screenshots / screen recordings, merged into one conversation.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';
import '/verin/thread_merge.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import '../data/model.dart';
import 'receipt_detail_drawer.dart';

class ThreadTab extends StatelessWidget {
  const ThreadTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  String _sourceLabel(ThreadEntry e) {
    final r = e.receipt;
    final name = r.fileName.isNotEmpty ? r.fileName : r.headline;
    return '$name · #${e.indexInReceipt + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final entries = mergeThread(receipts.where((r) => !r.isDuplicate).toList());
    final visible = entries.where((e) => !e.isRepeat).toList();
    final repeats = entries.length - visible.length;
    final pending = receipts.where((r) => r.extractionState == 'pending').length;

    final header = [
      Text('Thread reconstruction', style: VT.h2(context, size: 20.0)),
      const SizedBox(height: 4.0),
    ];

    if (visible.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...header,
          Text(
            pending > 0
                ? 'Reading $pending item${pending == 1 ? '' : 's'} now — messages appear here as soon as they are read.'
                : 'No screenshot threads reconstructed for this matter yet. Add message screenshots or a screen recording with Add manual entry on the Intake channel tab.',
            style: VT.muted(context),
          ),
        ],
      );
    }

    final notes = <String>[
      if (repeats > 0)
        '$repeats overlapping message${repeats == 1 ? '' : 's'} appeared in more than one screenshot and ${repeats == 1 ? 'is' : 'are'} shown once.',
      for (final e in visible)
        if (e.isGap && !e.isHeader)
          'Contiguity could not be proved before "${_clip(e.text)}" (${_sourceLabel(e)}).',
      for (final e in visible)
        if (!e.isHeader && e.timestampLabel.trim().isEmpty && e.isLowConfidence)
          'No visible timestamp on "${_clip(e.text)}"; order inferred from position only.',
      if (pending > 0) 'Still reading $pending item${pending == 1 ? '' : 's'}.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,
        Text(
          "Overlapping screenshots merged into one continuous thread. Each message cites its source; where contiguity can't be proved, the gap is shown as its own entry rather than joined silently.",
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        for (final e in visible) ...[
          if (e.isGap && !e.isHeader) const _GapRow(),
          if (e.isHeader)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Center(child: Text(e.text, style: VT.muted(context, size: 11.0))),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Align(
                alignment: e.isFromClient ? Alignment.centerRight : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.76,
                  alignment: e.isFromClient ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: e.isFromClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: e.isFromClient ? c.teal : c.card,
                          border: e.isFromClient ? null : Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(VR.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: 0.8,
                              child: Text(
                                e.isFromClient ? (matter.clientName.isNotEmpty ? matter.clientName.split(' ').first : 'Client') : 'Other party',
                                style: VT.body(context, size: 11.0, weight: FontWeight.w500, color: e.isFromClient ? c.primaryFg : c.foreground),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(e.text, style: VT.body(context, height: 1.35, color: e.isFromClient ? c.primaryFg : c.foreground)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Wrap(
                          alignment: e.isFromClient ? WrapAlignment.end : WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            VHover(
                              onTap: () => showReceiptDrawer(context, receipt: e.receipt, matter: matter),
                              builder: (context, hovered) => Text(
                                '${e.timestampLabel.trim().isEmpty ? 'no timestamp' : e.timestampLabel} · ${_sourceLabel(e)}',
                                style: VT.body(context, size: 10.0, color: hovered ? c.teal : c.mutedFg),
                              ),
                            ),
                            if (e.isLowConfidence) const StateBadge(state: VItemState.uncertain),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          VPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final n in notes) Text('· $n', style: VT.body(context, size: 12.0, height: 1.6))],
            ),
          ),
        ],
      ],
    );
  }

  static String _clip(String s) {
    final t = s.trim().replaceAll('\n', ' ');
    return t.length > 40 ? '${t.substring(0, 40)}…' : t;
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow();

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: Row(
        children: [
          const Expanded(child: VHairline()),
          const SizedBox(width: 12.0),
          VBadge(label: 'Gap', icon: Icons.warning_amber_rounded, bg: c.pendingBg, fg: c.pending),
          const SizedBox(width: 12.0),
          const Expanded(child: VHairline()),
        ],
      ),
    );
  }
}
