// Receipt detail drawer — port of the Make's <ReceiptDetailDrawer>, plus
// what the AI read (summary / transcript) and a link to the original file.
// Video language follows the Video Intake spec §8 (never "original",
// "unaltered", "authentic").

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_api.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import '../widgets/drawer.dart';
import 'verification_view.dart';

Future<void> showReceiptDrawer(BuildContext context, {required ReceiptsRecord receipt, required MattersRecord matter, VoidCallback? onOpenMatter}) =>
    showVDrawer<void>(
      context,
      title: 'Receipt detail',
      width: 520.0,
      builder: (_) => ReceiptDetail(receipt: receipt, matter: matter, onOpenMatter: onOpenMatter),
    );

class ReceiptDetail extends StatefulWidget {
  const ReceiptDetail({super.key, required this.receipt, required this.matter, this.onOpenMatter});

  final ReceiptsRecord receipt;
  final MattersRecord matter;
  final VoidCallback? onOpenMatter;

  @override
  State<ReceiptDetail> createState() => _ReceiptDetailState();
}

class _ReceiptDetailState extends State<ReceiptDetail> {
  late final Stream<ReceiptsRecord> _stream = ReceiptsRecord.getDocument(widget.receipt.reference);
  bool _saving = false;
  bool _retrying = false;
  bool _showFullTranscript = false;

  Future<void> _setState(ReceiptsRecord r, VItemState s) async {
    setState(() => _saving = true);
    try {
      await r.reference.update({
        'classificationLabel': labelForState(s),
        'reviewedByUid': currentUserUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) showVToast(context, s == VItemState.processed ? 'Marked as processed' : 'Marked as unreadable');
    } catch (e) {
      if (mounted) showVToast(context, 'Could not update: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _retry(ReceiptsRecord r, {bool force = false}) async {
    setState(() => _retrying = true);
    try {
      await VerinApi.reprocessReceipt(r.reference.id, forceTranscription: force);
      if (mounted) showVToast(context, 'AI reading finished');
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReceiptsRecord>(
      stream: _stream,
      initialData: widget.receipt,
      builder: (context, snap) => _body(context, snap.data ?? widget.receipt),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children, {Color? border, bool card = false}) {
    final c = VC.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: card ? c.card : c.secondary,
        borderRadius: BorderRadius.circular(VR.xl),
        border: card ? Border.all(color: c.border) : (border == null ? null : Border.all(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: VT.eyebrow(context, size: 11.0)),
          SizedBox(height: card ? 12.0 : 8.0),
          ...children,
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ReceiptsRecord r) {
    final c = VC.of(context);
    final state = itemStateOf(r);
    final ch = channelOf(r.channel);
    final textPath = ch == VChannel.sms || ch == VChannel.whatsapp;
    final meta = [
      r.kindLabel,
      if (r.durationLabel != null) r.durationLabel!,
      'from ${r.fromLabel}',
      'received ${fmtWhen(r.receivedAt)}',
    ].join(' · ');
    final ex = r.extractionState;
    final transcript = r.transcript;
    final st = r.snapshotData['statements'];
    final statementCount = st is List ? st.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          children: [
            ChannelBadge(channel: ch),
            StateBadge(state: state),
            if (r.originFidelity.isNotEmpty) OriginFidelityBadge(fidelity: r.originFidelity),
            if (r.isDuplicate) VBadge(label: 'Duplicate', bg: c.pending.withValues(alpha: 0.1), fg: c.pending),
          ],
        ),
        const SizedBox(height: 12.0),
        Text(r.headline, style: VT.serif(context, size: 16.0, weight: FontWeight.w500)),
        const SizedBox(height: 4.0),
        Text(meta, style: VT.muted(context, size: 13.0)),
        if (r.sourceUrl.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          Align(
            alignment: Alignment.centerLeft,
            child: VButton(
              label: r.fileName.isNotEmpty ? 'Open ${r.fileName}' : 'Open the file as received',
              icon: Icons.open_in_new,
              kind: VButtonKind.link,
              size: VButtonSize.sm,
              onPressed: () => launchURL(r.sourceUrl),
            ),
          ),
        ],
        if (r.reviewReason.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          VNotice(text: r.reviewReason),
        ],
        const SizedBox(height: 16.0),

        // Video record (spec §8 language).
        if (r.isVideo)
          _section(
            context,
            'Video record',
            [
              Text(
                r.originFidelity == 'transcoded_in_transit'
                    ? 'Received by ${textPath ? 'text message' : 'email'} on ${fmtDay(r.receivedAt)} and recorded as transcoded in transit.'
                    : r.originFidelity == 'as_sent'
                        ? 'Received as sent — no evidence of an intermediary re-encode.'
                        : 'The fidelity of this file relative to its source could not be established.',
                style: VT.body(context, size: 13.0, height: 1.6),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Hashed at receipt and independently timestamped. The record shows what arrived and when. It does not describe what happened to the file before it arrived.',
                style: VT.muted(context, size: 12.0, height: 1.6),
              ),
              if (r.isScreenRecordingItem) _rule(context, 'Classified as a screen recording — routed to thread reconstruction. Individual messages extracted as separate dated items.', c.secondaryFg),
              if (r.transcriptionState == 'complete') _rule(context, 'Transcription complete — speaker-separated, timestamped to the second. A reading aid; the exhibit is the video file.', c.verified),
              if (r.transcriptionState == 'deferred') _rule(context, 'Transcription deferred — item exceeds the automatic threshold. Request transcription to generate a reading aid.', c.pending),
              if (r.transcriptionState == 'no_audio') _rule(context, 'No audio track — there is no transcript. An empty transcript is not silence in the room.', c.mutedFg),
              if (r.transcriptionState == 'deferred' || r.transcriptionState == 'failed') ...[
                const SizedBox(height: 10.0),
                VButton(
                  label: 'Request transcription',
                  icon: Icons.graphic_eq,
                  kind: VButtonKind.tonal,
                  size: VButtonSize.sm,
                  loading: _retrying,
                  loadingLabel: 'Transcribing…',
                  onPressed: () => _retry(r, force: true),
                ),
              ],
            ],
            border: r.originFidelity == 'transcoded_in_transit' ? c.pending.withValues(alpha: 0.3) : c.border,
          ),

        if (r.resolvedDate != null)
          _section(context, 'Evidence date', [
            Text(fmtDay(r.resolvedDate), style: VT.body(context, weight: FontWeight.w500)),
            const SizedBox(height: 2.0),
            Text(
              [
                if (r.dateConfidence.isNotEmpty) '${r.dateConfidence} confidence',
                if (r.dateSource.isNotEmpty) 'from ${r.dateSource}',
              ].join(' · '),
              style: VT.muted(context, size: 12.0),
            ),
          ]),

        // What the AI read.
        if (ex == 'pending' || ex == 'running')
          _section(context, 'AI reading', [
            Row(
              children: [
                SizedBox(width: 14.0, height: 14.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: c.teal)),
                const SizedBox(width: 10.0),
                Expanded(child: Text('Reading this item now. Results appear here automatically.', style: VT.body(context, size: 13.0))),
              ],
            ),
          ])
        else if (r.aiSummary.isNotEmpty || transcript.isNotEmpty || ex == 'extraction_failed' || r.threadMessages.isNotEmpty || statementCount > 0)
          _section(context, 'What the AI read', [
            if (r.aiSummary.isNotEmpty) Text(r.aiSummary, style: VT.body(context, size: 13.0, height: 1.6)),
            if (r.threadMessages.isNotEmpty) ...[
              const SizedBox(height: 6.0),
              Text(
                '${r.threadMessages.where((m) => !m.isHeader).length} messages read into the Thread tab${r.detectedPlatform.isNotEmpty ? ' · ${r.detectedPlatform}' : ''}.',
                style: VT.muted(context, size: 12.0),
              ),
            ],
            if (statementCount > 0) ...[
              const SizedBox(height: 6.0),
              Text('$statementCount key passage${statementCount == 1 ? '' : 's'} (dates, amounts, names, events) located in the original.', style: VT.muted(context, size: 12.0)),
            ],
            if (r.threadMessages.isNotEmpty || statementCount > 0) ...[
              const SizedBox(height: 10.0),
              VButton(
                label: 'Verify against the original',
                icon: Icons.compare,
                kind: VButtonKind.tonal,
                size: VButtonSize.sm,
                onPressed: () => showVerificationView(context, receipt: r, matter: widget.matter),
              ),
            ],
            if (transcript.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              for (final seg in (_showFullTranscript ? transcript : transcript.take(6)))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 44.0, child: Text(_ts(seg['startSeconds']), style: VT.mono(context, size: 11.0, color: c.mutedFg))),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${seg['speaker'] ?? 'Speaker'}: ', style: VT.body(context, size: 12.5, weight: FontWeight.w600)),
                            TextSpan(text: '${seg['text'] ?? ''}', style: VT.body(context, size: 12.5)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (transcript.length > 6)
                VButton(
                  label: _showFullTranscript ? 'Show less' : 'Show all ${transcript.length} lines',
                  kind: VButtonKind.link,
                  size: VButtonSize.sm,
                  onPressed: () => setState(() => _showFullTranscript = !_showFullTranscript),
                ),
            ],
            if (ex == 'extraction_failed') ...[
              const SizedBox(height: 6.0),
              Text(
                r.extractionErrors.isEmpty ? 'AI reading failed.' : 'AI reading failed: ${r.extractionErrors.first}',
                style: VT.body(context, size: 12.0, color: c.broken),
              ),
              const SizedBox(height: 8.0),
              VButton(
                label: 'Run AI reading again',
                icon: Icons.refresh,
                kind: VButtonKind.tonal,
                size: VButtonSize.sm,
                loading: _retrying,
                loadingLabel: 'Reading…',
                onPressed: () => _retry(r),
              ),
            ],
            const SizedBox(height: 8.0),
            Text('A reading aid generated by AI. It cites the file above and never replaces it.', style: VT.muted(context, size: 11.0)),
          ]),

        if (r.description.isNotEmpty || r.custodyNotes.isNotEmpty)
          _section(context, 'Entered by staff', [
            if (r.description.isNotEmpty) Text(r.description, style: VT.body(context, size: 13.0, height: 1.6)),
            if (r.custodyNotes.isNotEmpty) ...[
              const SizedBox(height: 6.0),
              Text('Chain of custody: ${r.custodyNotes}', style: VT.muted(context, size: 12.0)),
            ],
            if (r.dateReceivedClaimed != null) ...[
              const SizedBox(height: 6.0),
              Text('Date received (as entered): ${fmtDay(r.dateReceivedClaimed)} — metadata, not anchored to the timestamp.',
                  style: VT.muted(context, size: 12.0)),
            ],
          ]),

        _section(
          context,
          'Integrity record',
          [
            VHashRow(label: 'SHA-256 at receipt', value: r.itemHash.isEmpty ? 'Computing…' : r.itemHash),
            const SizedBox(height: 8.0),
            VHashRow(label: 'Chain entry hash', value: r.entryHash.isEmpty ? 'Computing…' : r.entryHash),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(Icons.schedule, size: 12.0, color: c.teal),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    r.tsaTime != null
                        ? 'RFC 3161 timestamp token · ${r.tsaName.isEmpty ? 'TSA' : r.tsaName} · ${fmtWhen(r.tsaTime)}'
                        : 'RFC 3161 timestamp pending',
                    style: VT.muted(context, size: 11.0),
                  ),
                ),
              ],
            ),
          ],
          card: true,
        ),

        _section(context, 'Chain position', [
          Text(
            r.chainSeq > 0
                ? "Entry #${r.chainSeq} in the matter's hash chain. The entry hash is derived from the previous entry, the item hash, the server timestamp, and the origin digest. Any alteration would break the chain."
                : "This receipt is linked in the matter's hash chain. The entry hash is derived from the previous entry, the item hash, the server timestamp, and the origin digest. Any alteration would break the chain.",
            style: VT.body(context, size: 13.0, height: 1.6),
          ),
        ]),
        const SizedBox(height: 8.0),

        if (state != VItemState.processed && state != VItemState.processing) ...[
          Text('Update state', style: VT.muted(context, size: 12.0, weight: FontWeight.w600)),
          const SizedBox(height: 8.0),
          VButton(
            label: 'Mark as processed',
            icon: Icons.check_circle_outline,
            fullWidth: true,
            loading: _saving,
            onPressed: () => _setState(r, VItemState.processed),
          ),
          if (state != VItemState.unreadable) ...[
            const SizedBox(height: 8.0),
            VButton(
              label: 'Mark as unreadable',
              icon: Icons.cancel_outlined,
              kind: VButtonKind.secondary,
              fullWidth: true,
              onPressed: _saving ? null : () => _setState(r, VItemState.unreadable),
            ),
          ],
        ] else if (state == VItemState.processed)
          VStatusInline(
            label: 'This item has been processed and is part of the verified record.',
            icon: Icons.check_circle_outline,
            color: c.verified,
            size: 13.0,
          ),

        if (widget.onOpenMatter != null) ...[
          const SizedBox(height: 16.0),
          VButton(
            label: 'Open ${widget.matter.title}',
            icon: Icons.folder_open_outlined,
            kind: VButtonKind.tonal,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).maybePop();
              widget.onOpenMatter!();
            },
          ),
        ],
      ],
    );
  }

  Widget _rule(BuildContext context, String text, Color color) {
    final c = VC.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Text(text, style: VT.body(context, size: 12.0, color: color, height: 1.6)),
    );
  }

  static String _ts(dynamic s) {
    final n = s is num ? s.toInt() : 0;
    final m = n ~/ 60;
    final sec = n % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }
}
