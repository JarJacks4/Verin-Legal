// Receipts tab — port of the Make's <ReceiptsTab>.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import 'manual_entry_drawer.dart';
import 'receipt_detail_drawer.dart';

/// How each kind of change is shown (Differentiator 3).
(String, Color) updateKindStyle(BuildContext context, String kind) {
  final c = VC.of(context);
  return switch (kind) {
    'new' => ('New', c.verified),
    'overlaps' => ('Overlaps the record', c.tealDeep),
    'already_in_record' => ('Already in the record', c.mutedFg),
    'duplicate' => ('Exact duplicate', c.mutedFg),
    'earlier_in_chronology' => ('Earlier in the chronology', c.pending),
    'redates' => ('Re-dates earlier entries', c.pending),
    'fills_gap' => ('Closes a gap', c.verified),
    _ => (kind, c.mutedFg),
  };
}

class ReceiptsTab extends StatefulWidget {
  const ReceiptsTab({super.key, required this.matter, required this.receipts, this.loading = false, this.error});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final bool loading;
  final Object? error;

  @override
  State<ReceiptsTab> createState() => _ReceiptsTabState();
}

class _ReceiptsTabState extends State<ReceiptsTab> {
  late Stream<List<MatterUpdate>> _updates = matterUpdatesStream(widget.matter.reference);
  bool _all = false;

  @override
  void didUpdateWidget(covariant ReceiptsTab old) {
    super.didUpdateWidget(old);
    if (old.matter.reference.path != widget.matter.reference.path) _updates = matterUpdatesStream(widget.matter.reference);
  }

  @override
  Widget build(BuildContext context) {
    final matter = widget.matter;
    final receipts = widget.receipts;
    final loading = widget.loading;
    final error = widget.error;
    return StreamBuilder<List<MatterUpdate>>(
      stream: _updates,
      builder: (context, us) {
        final updates = us.data ?? const <MatterUpdate>[];
        final byReceipt = {for (final u in updates) if (u.receiptRef != null) u.receiptRef!.id: u};
        return _body(context, matter, receipts, loading, error, updates, byReceipt);
      },
    );
  }

  Widget _whatsNew(BuildContext context, List<MatterUpdate> updates) {
    final c = VC.of(context);
    final shown = _all ? updates : updates.take(4).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.card)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20.0, 14.0, 16.0, 12.0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: [
                Icon(Icons.update, size: 16.0, color: c.tealDeep),
                const SizedBox(width: 8.0),
                Expanded(child: Text('What\'s new', style: VT.body(context, size: 14.0, weight: FontWeight.w600))),
                Text('each arrival compared with the record', style: VT.muted(context, size: 11.0)),
              ],
            ),
          ),
          for (var i = 0; i < shown.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 16.0, 12.0),
              decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(shown[i].headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.0, weight: FontWeight.w500))),
                      Text(fmtWhen(shown[i].at), style: VT.muted(context, size: 11.0)),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(shown[i].summary, style: VT.body(context, size: 12.5, height: 1.4)),
                  const SizedBox(height: 6.0),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      for (final k in shown[i].kinds)
                        Builder(builder: (context) {
                          final (label, tone) = updateKindStyle(context, k);
                          return VBadge(label: label, bg: tone.withValues(alpha: 0.12), fg: tone, size: 10.0);
                        }),
                    ],
                  ),
                ],
              ),
            ),
          if (updates.length > 4)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Center(
                child: VButton(
                  label: _all ? 'Show fewer' : 'Show all ${updates.length}',
                  kind: VButtonKind.link,
                  size: VButtonSize.sm,
                  onPressed: () => setState(() => _all = !_all),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, MattersRecord matter, List<ReceiptsRecord> receipts, bool loading, Object? error, List<MatterUpdate> updates, Map<String, MatterUpdate> byReceipt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Receipts', style: VT.h2(context, size: 20.0)),
        const SizedBox(height: 4.0),
        Text(
          'Everything the client has sent, in the order it arrived. Each item is hashed and timestamped at receipt, before anyone opens it. Click any receipt to inspect its full integrity record.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        if (updates.isNotEmpty) _whatsNew(context, updates),
        if (error != null)
          VErrorBox(
            message: '$error'.contains('index')
                ? 'Receipts need a Firestore index. Deploy firebase/firestore.indexes.json (firebase deploy --only firestore:indexes).'
                : 'Receipts could not be loaded: $error',
          )
        else if (loading)
          const VLoading()
        else if (receipts.isEmpty)
          VEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing received yet',
            message: 'Photos, videos, documents and emails appear here the moment they arrive — hashed and timestamped before anyone opens them.',
            action: VButton(
              label: 'Add manual entry',
              icon: Icons.edit_outlined,
              kind: VButtonKind.tonal,
              size: VButtonSize.sm,
              onPressed: () => showManualEntryDrawer(context, matter: matter),
            ),
          )
        else
          for (final r in receipts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ReceiptCard(receipt: r, update: byReceipt[r.reference.id], onTap: () => showReceiptDrawer(context, receipt: r, matter: matter)),
            ),
      ],
    );
  }
}

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt, required this.onTap, this.update});

  final ReceiptsRecord receipt;
  final VoidCallback onTap;

  /// What this item changed when it arrived, if known.
  final MatterUpdate? update;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final r = receipt;
    final meta = [
      r.kindLabel,
      if (r.durationLabel != null) r.durationLabel!,
      'from ${r.fromLabel}',
    ].join(' · ');
    final dated = r.resolvedDate != null
        ? ' · dated ${fmtDay(r.resolvedDate)}${r.dateConfidence.isNotEmpty ? ' (${r.dateConfidence} confidence)' : ''}'
        : '';
    final extras = <Widget>[
      if (r.originFidelity.isNotEmpty) OriginFidelityBadge(fidelity: r.originFidelity),
      if (r.isScreenRecordingItem) VBadge(label: 'Screen recording → thread', icon: Icons.layers_outlined, bg: c.secondary, fg: c.secondaryFg, size: 10.0),
      if (r.transcriptionState == 'complete') VBadge(label: 'Transcribed', bg: c.verified.withValues(alpha: 0.1), fg: c.verified, size: 10.0),
      if (r.transcriptionState == 'deferred') VBadge(label: 'Transcription deferred', bg: c.pending.withValues(alpha: 0.1), fg: c.pending, size: 10.0),
      if (r.transcriptionState == 'no_audio') VBadge(label: 'No audio track', bg: c.secondary, fg: c.mutedFg, size: 10.0),
      if (r.threadMessages.isNotEmpty)
        VBadge(label: '${r.threadMessages.where((m) => !m.isHeader).length} messages → thread', icon: Icons.chat_bubble_outline, bg: c.secondary, fg: c.secondaryFg, size: 10.0),
      if (r.isDuplicate) VBadge(label: 'Duplicate of an earlier item', bg: c.pending.withValues(alpha: 0.1), fg: c.pending, size: 10.0),
      if (update != null)
        for (final k in update!.kinds.where((k) => k != 'duplicate'))
          Builder(builder: (context) {
            final (label, tone) = updateKindStyle(context, k);
            return VBadge(label: label, bg: tone.withValues(alpha: 0.12), fg: tone, size: 10.0);
          }),
    ];

    return VHover(
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: hovered ? c.secondary : c.card,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(VR.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [ChannelBadge(channel: channelOf(r.channel)), StateBadge(state: itemStateOf(r))],
                  ),
                ),
                Text(fmtWhen(r.receivedAt), style: VT.muted(context, size: 12.0)),
                const SizedBox(width: 8.0),
                Icon(Icons.chevron_right, size: 16.0, color: c.mutedFg),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(r.headline, style: VT.body(context, weight: FontWeight.w500)),
            const SizedBox(height: 2.0),
            Text('$meta$dated', style: VT.muted(context, size: 12.0)),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 6.0),
              Wrap(spacing: 8.0, runSpacing: 4.0, children: extras),
            ],
            const SizedBox(height: 12.0),
            const VHairline(),
            const SizedBox(height: 12.0),
            VHashRow(label: 'SHA-256', value: r.itemHash.isEmpty ? '…' : r.itemHash, short: true),
          ],
        ),
      ),
    );
  }
}
