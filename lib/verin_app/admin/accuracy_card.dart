// Admin → Dashboard: accuracy measured from reviewers' notes — wrong dates
// and wrong thread placements per 100 items, against the targets in
// verin_config.dart, and how many matters the measure covers.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/corrections.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';

class AccuracyCard extends StatefulWidget {
  const AccuracyCard({super.key, required this.receipts});

  /// The firm's items, duplicates excluded.
  final List<ReceiptsRecord> receipts;

  @override
  State<AccuracyCard> createState() => _AccuracyCardState();
}

class _AccuracyCardState extends State<AccuracyCard> {
  late final Stream<List<Correction>> _corr = firmCorrectionsStream();

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<List<Correction>>(
      stream: _corr,
      builder: (context, s) {
        final list = s.data ?? const <Correction>[];
        // One count per message, however many times it was noted.
        Set<String> targets(String f) => {for (final x in list) if (x.field == f) x.target};
        final dates = targets('date').length;
        final joins = targets('thread').length;
        final items = widget.receipts.length;
        final reviewed = widget.receipts.where((r) => r.snapshotData['reviewedAt'] != null || r.classificationLabel.toLowerCase() == 'processed');
        final matters = {for (final r in reviewed) r.matterId?.path}.whereType<String>().length;
        double? per100(int n) => items == 0 ? null : n * 100.0 / items;
        Widget tile(String label, double? v, double target) {
          final ok = v != null && v <= target;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(12.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v == null ? '—' : v.toStringAsFixed(1), style: VT.h2(context, size: 22.0, color: v == null ? null : (ok ? c.verified : c.pending))),
                  Text(label, style: VT.body(context, size: 12.0, weight: FontWeight.w600)),
                  Text('target ≤ ${target.toStringAsFixed(1)} per 100 items', style: VT.muted(context, size: 11.0)),
                ],
              ),
            ),
          );
        }

        return VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Accuracy', style: VT.h3(context, size: 16.0)),
              const SizedBox(height: 2.0),
              Text('From reviewers\' notes in Verify against the original ("Date is wrong", "Wrong place in thread").', style: VT.muted(context, size: 12.5)),
              const SizedBox(height: 14.0),
              Row(
                children: [
                  tile('Wrong dates', per100(dates), kTargetWrongDatesPer100),
                  const SizedBox(width: 12.0),
                  tile('Wrong thread placements', per100(joins), kTargetWrongJoinsPer100),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                '$items items · $dates wrong ${dates == 1 ? 'date' : 'dates'} · $joins wrong ${joins == 1 ? 'placement' : 'placements'} · '
                '$matters of $kAccuracyMattersNeeded matters measured${matters >= kAccuracyMattersNeeded ? '' : ' (keep reviewing before quoting these)'}',
                style: VT.muted(context, size: 12.0),
              ),
            ],
          ),
        );
      },
    );
  }
}
