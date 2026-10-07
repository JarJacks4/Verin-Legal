// Search across every matter's evidence from the Matters list: what the AI
// read, file names, and every message line. Opens the item itself.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../matter/receipt_detail_drawer.dart' show showReceiptDrawer;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';

/// The text of a receipt worth searching, with the best snippet for [q].
String? _snippet(ReceiptsRecord r, String q) {
  final parts = <String>[
    for (final m in r.threadMessages) m.text,
    r.aiSummary,
    r.content,
    r.description,
    r.fileName,
  ];
  for (final p in parts) {
    final i = p.toLowerCase().indexOf(q);
    if (i < 0) continue;
    final start = (i - 50).clamp(0, p.length);
    final end = (i + q.length + 70).clamp(0, p.length);
    return '${start > 0 ? '…' : ''}${p.substring(start, end).replaceAll(RegExp(r'\s+'), ' ')}${end < p.length ? '…' : ''}';
  }
  return null;
}

class EvidenceMatches extends StatelessWidget {
  const EvidenceMatches({super.key, required this.query, required this.matters, required this.receipts});

  final String query;
  final List<MattersRecord> matters;
  final Map<String, List<ReceiptsRecord>> receipts;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final q = query.trim().toLowerCase();
    if (q.length < 3) return const SizedBox.shrink();
    final byPath = {for (final m in matters) m.reference.path: m};
    final hits = <(MattersRecord, ReceiptsRecord, String)>[];
    for (final e in receipts.entries) {
      final m = byPath[e.key];
      if (m == null) continue;
      for (final r in e.value) {
        if (r.isDuplicate) continue;
        final s = _snippet(r, q);
        if (s != null) hits.add((m, r, s));
      }
    }
    hits.sort((a, b) => (b.$2.receivedAt ?? DateTime(2000)).compareTo(a.$2.receivedAt ?? DateTime(2000)));
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('IN THE EVIDENCE · ${hits.length} ${hits.length == 1 ? 'ITEM' : 'ITEMS'}', style: VT.eyebrow(context, size: 11.0)),
          const SizedBox(height: 8.0),
          if (hits.isEmpty) Text('No item in any matter mentions "$query".', style: VT.muted(context, size: 13.0)),
          if (hits.isNotEmpty)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (m, r, s)) in hits.take(40).indexed)
                    VHover(
                      onTap: () => showReceiptDrawer(context, receipt: r, matter: m),
                      builder: (context, hovered) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: hovered ? c.secondary.withValues(alpha: 0.6) : c.card,
                          border: i == 0 ? null : Border(top: BorderSide(color: c.border)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChannelBadge(channel: channelOf(r.channel)),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s, maxLines: 2, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.0)),
                                  const SizedBox(height: 2.0),
                                  Text('${m.title} · ${r.fileName.isEmpty ? r.kindLabel : r.fileName} · received ${fmtDay(r.receivedAt)}', style: VT.muted(context, size: 12.0)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (hits.length > 40) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Showing the 40 newest. Narrow the search to see others.', style: VT.muted(context, size: 12.0))),
        ],
      ),
    );
  }
}
