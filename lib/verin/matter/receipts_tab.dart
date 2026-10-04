// Verin Legal — Reciepts tab (guide §5): search, filter chips, receipt list.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import '../record_ext.dart';
import '../sheets/receipt_detail_sheet.dart';
import '../verin_format.dart';
import '../verin_ui.dart';
import 'screenshot_upload_card.dart';

const _filters = ['All', 'Photo', 'Video', 'Document', 'Email', 'Physical'];

bool _matchesFilter(ReceiptsRecord r, String f) {
  final kind = r.itemKind.toLowerCase();
  switch (f) {
    case 'Photo':
      return const {'photo', 'screenshot', 'image'}.contains(kind);
    case 'Video':
      return kind == 'video' || kind == 'screen_recording';
    case 'Document':
      return const {'document', 'pdf', 'file'}.contains(kind);
    case 'Email':
      return r.channel.toLowerCase() == 'email' || kind == 'email';
    case 'Physical':
      return kind == 'physical';
    default:
      return true;
  }
}

bool _matchesSearch(ReceiptsRecord r, String q) {
  if (q.isEmpty) return true;
  final hay = [
    r.content,
    r.itemKind,
    r.channel,
    r.classificationLabel,
    r.detectedPlatform,
    r.itemHash,
    ...r.threadMessages.map((m) => m.text),
  ].join(' ').toLowerCase();
  return hay.contains(q.toLowerCase());
}

class ReceiptsTab extends StatefulWidget {
  const ReceiptsTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<ReceiptsTab> createState() => _ReceiptsTabState();
}

class _ReceiptsTabState extends State<ReceiptsTab> {
  final _search = TextEditingController();
  String _filter = 'All';
  bool _showUpload = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final q = _search.text.trim();
    final visible = widget.receipts.where((r) => _matchesFilter(r, _filter) && _matchesSearch(r, q)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipts', style: VerinText.heading(context)),
                    const SizedBox(height: 4.0),
                    Text(
                      'Everything the client has sent, in the order it arrived. Each item is hashed and timestamped '
                      'at receipt, before anyone opens it. Click any receipt to inspect its full integrity record.',
                      style: VerinText.bodyMuted(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24.0),
              VerinButton(
                label: _showUpload ? 'Hide upload' : 'Add evidence',
                icon: _showUpload ? Icons.close_rounded : Icons.add_rounded,
                onPressed: () => setState(() => _showUpload = !_showUpload),
              ),
            ],
          ),
          if (_showUpload) ...[
            const SizedBox(height: 16.0),
            ScreenshotUploadCard(matter: widget.matter),
          ],
          const SizedBox(height: 24.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 12.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320.0,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: VerinText.body(context),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search receipts and messages…',
                    prefixIcon: Icon(Icons.search_rounded, size: 18.0, color: t.secondary),
                    filled: true,
                    fillColor: const Color(0x2D2D5A5E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (final f in _filters)
                    _FilterChip(
                      label: f,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          if (widget.receipts.isEmpty)
            const VerinEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No receipts yet',
              message: 'Anything the client sends, or you upload with "Add evidence", appears here.',
            )
          else if (visible.isEmpty)
            const VerinEmptyState(icon: Icons.filter_alt_off_rounded, title: 'Nothing matches this search or filter')
          else
            for (final r in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ReceiptRow(
                  receipt: r,
                  onTap: () => showVerinSheet(context, ReceiptDetailSheet(receipt: r, matter: widget.matter)),
                ),
              ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      child: Container(
        height: 34.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: selected ? t.secondary10 : t.secondaryBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: selected ? t.secondary : t.alternate, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 16.0, color: t.primaryText),
              const SizedBox(width: 6.0),
            ],
            Text(label, style: VerinText.label(context, color: t.primaryText)),
          ],
        ),
      ),
    );
  }
}

/// One receipt in the list (also reused by the Review Queue if wanted).
class ReceiptRow extends StatelessWidget {
  const ReceiptRow({super.key, required this.receipt, required this.onTap});

  final ReceiptsRecord receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final r = receipt;

    final meta = <String>[
      if (r.itemKind.isNotEmpty) r.itemKind.replaceAll('_', ' '),
      if (r.isVideo && r.durationSeconds > 0) fmtDuration(r.durationSeconds),
      if (r.detectedPlatform.isNotEmpty && r.detectedPlatform != 'Unknown') r.detectedPlatform,
      if (r.threadMessages.isNotEmpty) pluralize(r.threadMessages.length, 'message'),
      if (r.resolvedDate != null) 'dated ${fmtDate(r.resolvedDate)}',
    ];

    final state = r.extractionState;

    return Material(
      color: t.secondaryBackground,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: t.alternate, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 6.0,
                      children: [
                        if (r.channel.isNotEmpty)
                          VerinTag(label: r.channel, background: const Color(0xFFE4EEEF), foreground: t.secondary),
                        if (r.classificationLabel.isNotEmpty)
                          VerinTag(
                            label: r.classificationLabel,
                            background: r.classificationLabel == 'Uncertain' ? t.warning10 : const Color(0x1E2F7D5B),
                            foreground: r.classificationLabel == 'Uncertain' ? t.warning : t.secondary,
                          ),
                      ],
                    ),
                  ),
                  Text(fmtDateTime(r.receivedAt), style: VerinText.label(context, color: t.secondary)),
                  const SizedBox(width: 4.0),
                  Icon(Icons.chevron_right_rounded, size: 16.0, color: t.accent3),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(r.headline, style: VerinText.title(context).copyWith(fontWeight: FontWeight.w500)),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text(meta.join(' · '), style: VerinText.small(context)),
              ],
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  if (r.originFidelity == 'transcoded_in_transit')
                    VerinTag(label: 'Transcoded in transit', background: const Color(0x1EB0791C), foreground: t.warning),
                  if (r.originFidelity == 'as_sent')
                    VerinTag(label: 'As sent', background: t.success10, foreground: t.success),
                  if (r.isTranscribed)
                    VerinTag(label: 'Transcribed', background: const Color(0x2C2F7D5B), foreground: t.success),
                  if (r.isDuplicate)
                    VerinTag(label: 'Duplicate', background: t.surfaceVariant, foreground: t.secondaryText),
                  if (r.hasChronologyShift)
                    VerinTag(label: 'Chronology shift', background: t.warning10, foreground: t.warning),
                  if (state == 'pending')
                    VerinTag(label: 'Reading…', background: t.info10, foreground: t.info),
                  if (state == 'extraction_failed')
                    VerinTag(label: 'Extraction failed', background: const Color(0x1AB03A2E), foreground: t.error),
                ],
              ),
              Divider(height: 24.0, thickness: 1.0, color: t.alternate),
              Row(
                children: [
                  Text('SHA-256', style: VerinText.mono(context, color: t.accent3)),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      r.itemHash.isEmpty ? 'not recorded' : r.itemHash,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VerinText.mono(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
