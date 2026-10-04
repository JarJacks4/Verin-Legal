// Verin Legal — Receipt detail drawer (guide §10): the full integrity record
// for one receipt, the original image, and what the extraction read from it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../record_ext.dart';
import '../verin_api.dart';
import '../verin_format.dart';
import '../verin_ui.dart';

class ReceiptDetailSheet extends StatefulWidget {
  const ReceiptDetailSheet({super.key, required this.receipt, required this.matter});

  final ReceiptsRecord receipt;
  final MattersRecord matter;

  @override
  State<ReceiptDetailSheet> createState() => _ReceiptDetailSheetState();
}

class _ReceiptDetailSheetState extends State<ReceiptDetailSheet> {
  bool _retrying = false;

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) showVerinSnack(context, '$label copied.');
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      final r = await VerinApi.retryExtraction(widget.receipt.reference.id);
      if (!mounted) return;
      final status = (r['status'] ?? '').toString();
      showVerinSnack(
        context,
        status == 'extracted'
            ? 'Read ${r['messageCount'] ?? 0} messages.'
            : status == 'no_conversation_detected'
                ? 'No conversation found in this image.'
                : 'Extraction failed again: ${(r['errors'] is List && (r['errors'] as List).isNotEmpty) ? (r['errors'] as List).first : 'unknown error'}',
        error: status == 'extraction_failed',
      );
    } on VerinApiException catch (e) {
      if (mounted) showVerinSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    // Stream the receipt so a retry's result shows up here live.
    return StreamBuilder<ReceiptsRecord>(
      stream: ReceiptsRecord.getDocument(widget.receipt.reference),
      initialData: widget.receipt,
      builder: (context, snap) {
        final r = snap.data ?? widget.receipt;
        final state = r.extractionState;
        return VerinSheetFrame(
          title: r.headline,
          subtitle: [
            if (r.channel.isNotEmpty) r.channel,
            if (r.itemKind.isNotEmpty) r.itemKind.replaceAll('_', ' '),
            if (r.receivedAt != null) 'received ${fmtDateTime(r.receivedAt)}',
          ].join(' · '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (r.sourceUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    color: t.primaryBackground,
                    constraints: const BoxConstraints(maxHeight: 420.0),
                    child: Image.network(
                      r.sourceUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Original image could not be loaded.', style: VerinText.small(context)),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => launchURL(r.sourceUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16.0),
                    label: const Text('Open original'),
                  ),
                ),
                const SizedBox(height: 8.0),
              ],
              Text('INTEGRITY RECORD', style: VerinText.label(context)),
              const SizedBox(height: 12.0),
              VerinCard(
                padding: const EdgeInsets.all(16.0),
                color: t.primaryBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VerinHashLine(
                      label: 'item_hash (SHA-256 of the bytes as received)',
                      value: r.itemHash,
                      onCopied: () => _copy('Item hash', r.itemHash),
                    ),
                    const SizedBox(height: 12.0),
                    VerinHashLine(
                      label: r.chainSeq > 0 ? 'entry_hash · chain entry #${r.chainSeq}' : 'entry_hash',
                      value: r.entryHash,
                      onCopied: () => _copy('Entry hash', r.entryHash),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'entry = SHA256( prev_hash || item_hash || received_at || origin_digest )',
                      style: VerinText.mono(context),
                    ),
                  ],
                ),
              ),
              if (r.entryHash.isEmpty) ...[
                const SizedBox(height: 8.0),
                Text(
                  'This receipt was recorded before server-side chaining, so it has no chain entry of its own.',
                  style: VerinText.small(context),
                ),
              ],
              const SizedBox(height: 24.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  if (r.originFidelity.isNotEmpty)
                    VerinTag(
                      label: r.originFidelity == 'transcoded_in_transit'
                          ? 'Transcoded in transit'
                          : r.originFidelity == 'as_sent'
                              ? 'As sent (original fidelity)'
                              : r.originFidelity,
                      background: r.originFidelity == 'transcoded_in_transit' ? t.warning10 : t.success10,
                      foreground: r.originFidelity == 'transcoded_in_transit' ? t.warning : t.success,
                    ),
                  VerinTag(
                    label: r.isTranscribed ? 'Transcribed' : 'Not transcribed',
                    background: r.isTranscribed ? t.success10 : t.surfaceVariant,
                    foreground: r.isTranscribed ? t.success : t.secondaryText,
                  ),
                  if (r.isDuplicate)
                    VerinTag(label: 'Same file received earlier', background: t.surfaceVariant, foreground: t.secondaryText),
                ],
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(child: Text('EXTRACTED THREAD', style: VerinText.label(context))),
                  if (r.sourceStoragePath.isNotEmpty && state != 'pending')
                    VerinButton(
                      label: state == 'extraction_failed' ? 'Retry extraction' : 'Re-run extraction',
                      icon: Icons.refresh_rounded,
                      size: VerinButtonSize.small,
                      loading: _retrying,
                      onPressed: _retrying ? null : _retry,
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              if (state == 'pending')
                Text('Reading this image…', style: VerinText.small(context))
              else if (state == 'extraction_failed')
                Text(
                  'Extraction failed: ${r.extractionErrors.isEmpty ? 'unknown error' : r.extractionErrors.join('; ')}',
                  style: VerinText.small(context, color: t.error),
                )
              else if (state == 'no_conversation_detected')
                Text('No conversation was found in this image.', style: VerinText.small(context))
              else if (r.threadMessages.isEmpty)
                Text('No messages were extracted from this receipt.', style: VerinText.small(context))
              else ...[
                Text(
                  '${pluralize(r.threadMessages.length, 'message')}'
                  '${r.detectedPlatform.isNotEmpty ? ' · ${r.detectedPlatform}' : ''}'
                  '${r.extractionModel.isNotEmpty ? ' · read by ${r.extractionModel}' : ''}'
                  '${r.extractedAt != null ? ' on ${fmtDateTime(r.extractedAt)}' : ''}',
                  style: VerinText.small(context),
                ),
                const SizedBox(height: 8.0),
                for (final m in r.threadMessages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: m.isHeader ? '— ' : (m.speaker == 'client' ? 'Client: ' : 'Other: '),
                            style: VerinText.label(context, weight: FontWeight.bold),
                          ),
                          TextSpan(text: m.text, style: VerinText.body(context)),
                          if (m.timestampLabel.isNotEmpty)
                            TextSpan(text: '  ${m.timestampLabel}', style: VerinText.mono(context)),
                          if (!m.isHeader && m.hasConfidence() && m.confidence < 0.75)
                            TextSpan(
                              text: '  low confidence',
                              style: VerinText.mono(context, color: t.warning, weight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
