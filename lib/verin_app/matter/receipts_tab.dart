// Receipts tab — port of the Make's <ReceiptsTab>.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import 'manual_entry_drawer.dart';
import 'receipt_detail_drawer.dart';

class ReceiptsTab extends StatelessWidget {
  const ReceiptsTab({super.key, required this.matter, required this.receipts, this.loading = false, this.error});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
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
              child: ReceiptCard(receipt: r, onTap: () => showReceiptDrawer(context, receipt: r, matter: matter)),
            ),
      ],
    );
  }
}

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt, required this.onTap});

  final ReceiptsRecord receipt;
  final VoidCallback onTap;

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
