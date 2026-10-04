// Review queue — port of the Make's <ReviewQueue>: every item the system
// could not resolve on its own, across the firm's matters.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../matters/matters_screen.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import '../matter/receipt_detail_drawer.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final Stream<List<MattersRecord>> _matters = firmMattersStream();
  late final Stream<List<ReceiptsRecord>> _flagged = flaggedReceiptsStream();

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40.0, 36.0, 40.0, 48.0),
      child: Align(
  alignment: Alignment.topLeft,
  child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review queue', style: VT.h1(context, size: 30.0)),
            const SizedBox(height: 4.0),
            Text(
              'Items the system could not resolve on its own. Nothing is guessed silently — every flagged item waits here for a person.',
              style: VT.muted(context),
            ),
            const SizedBox(height: 28.0),
            StreamBuilder<List<MattersRecord>>(
              stream: _matters,
              builder: (context, ms) => StreamBuilder<List<ReceiptsRecord>>(
                stream: _flagged,
                builder: (context, rs) {
                  if (rs.hasError) return VErrorBox(message: 'The queue could not be loaded: ${rs.error}');
                  if (!ms.hasData || !rs.hasData) return const VLoading();
                  final byPath = {for (final m in ms.data!) m.reference.path: m};
                  final items = rs.data!
                      .where((r) => r.matterId != null && byPath.containsKey(r.matterId!.path))
                      .toList()
                    ..sort((a, b) => (b.receivedAt ?? DateTime(0)).compareTo(a.receivedAt ?? DateTime(0)));
                  if (items.isEmpty) {
                    return const VEmptyState(
                      icon: Icons.checklist,
                      title: 'Nothing waiting',
                      message: 'Every item is resolved. Anything the system cannot read or date on its own lands here for a person.',
                    );
                  }
                  return Column(
                    children: [
                      for (final r in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: VHover(
                            onTap: () {
                              final m = byPath[r.matterId!.path]!;
                              showReceiptDrawer(context, receipt: r, matter: m, onOpenMatter: () => openMatter(context, m));
                            },
                            builder: (context, hovered) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                              decoration: BoxDecoration(
                                color: hovered ? c.secondary : c.card,
                                border: Border.all(color: c.border),
                                borderRadius: BorderRadius.circular(VR.card),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8.0,
                                          runSpacing: 4.0,
                                          children: [StateBadge(state: itemStateOf(r)), ChannelBadge(channel: channelOf(r.channel))],
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(r.headline, style: VT.body(context, weight: FontWeight.w500)),
                                        const SizedBox(height: 2.0),
                                        Text('${byPath[r.matterId!.path]!.title} · received ${fmtWhen(r.receivedAt)}',
                                            style: VT.muted(context, size: 12.0)),
                                        if (r.reviewReason.isNotEmpty) ...[
                                          const SizedBox(height: 2.0),
                                          Text(r.reviewReason, style: VT.body(context, size: 12.0, color: c.pending)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Icon(Icons.chevron_right, size: 18.0, color: c.mutedFg),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
),
    );
  }
}
