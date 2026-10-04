// Verin Legal — Thread tab (guide §6): source screenshots on the left, the
// reconstructed conversation on the right.

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import '../record_ext.dart';
import '../sheets/receipt_detail_sheet.dart';
import '../thread_merge.dart';
import '../verin_format.dart';
import '../verin_ui.dart';
import 'screenshot_upload_card.dart';

class ThreadTab extends StatefulWidget {
  const ThreadTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<ThreadTab> createState() => _ThreadTabState();
}

class _ThreadTabState extends State<ThreadTab> {
  /// Reference path of the selected source screenshot, or null for all.
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final sources = threadSources(widget.receipts);
    if (_selected != null && !sources.any((r) => r.reference.path == _selected)) {
      _selected = null;
    }
    final all = mergeThread(widget.receipts);
    final entries = _selected == null ? all : all.where((e) => e.receipt.reference.path == _selected).toList();
    final accuracy = threadAccuracy(entries);
    final gaps = threadGapCount(entries);

    final platforms = entries.map((e) => e.platform).where((p) => p.isNotEmpty && p != 'Unknown').toSet();
    final platformLabel = platforms.isEmpty ? kDash : platforms.join(', ');

    final pending = widget.receipts.where((r) => r.extractionState == 'pending').length;

    return LayoutBuilder(
      builder: (context, c) {
        final rail = _SourceRail(
          matter: widget.matter,
          sources: sources,
          selected: _selected,
          pending: pending,
          onSelect: (path) => setState(() => _selected = (_selected == path) ? null : path),
          onShowAll: () => setState(() => _selected = null),
        );

        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: t.info10,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Wrap(
                spacing: 24.0,
                runSpacing: 8.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.devices_rounded, size: 18.0, color: t.tertiary),
                      const SizedBox(width: 8.0),
                      Text('Platform: $platformLabel', style: VerinText.label(context)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        accuracy == null ? 'Accuracy —' : 'Accuracy ${(accuracy * 100).round()}%',
                        style: VerinText.label(context, color: t.secondary, weight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8.0),
                      LinearPercentIndicator(
                        percent: (accuracy ?? 0.0).clamp(0.0, 1.0).toDouble(),
                        width: 100.0,
                        lineHeight: 8.0,
                        animation: false,
                        progressColor: (accuracy ?? 1.0) >= 0.85 ? const Color(0xFF68BE5C) : t.warning,
                        backgroundColor: const Color(0x1D545454),
                        barRadius: const Radius.circular(50.0),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  if (gaps > 0)
                    VerinTag(label: pluralize(gaps, 'gap'), background: t.warning10, foreground: t.warning),
                  if (_selected != null)
                    TextButton(onPressed: () => setState(() => _selected = null), child: const Text('Show all sources')),
                ],
              ),
            ),
            Divider(height: 1.0, thickness: 1.0, color: t.alternate),
            Expanded(
              child: entries.isEmpty
                  ? VerinEmptyState(
                      icon: Icons.forum_outlined,
                      title: pending > 0 ? 'Reading screenshots…' : 'No thread yet',
                      message: pending > 0
                          ? 'Messages appear here as soon as extraction finishes.'
                          : 'Upload screenshots of the conversation and the messages are reconstructed here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24.0),
                      itemCount: entries.length,
                      itemBuilder: (context, i) => _ThreadItem(
                        entry: entries[i],
                        onOpenSource: () => showVerinSheet(
                          context,
                          ReceiptDetailSheet(receipt: entries[i].receipt, matter: widget.matter),
                        ),
                      ),
                    ),
            ),
          ],
        );

        if (c.maxWidth < 860.0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 260.0, child: rail),
              Divider(height: 1.0, thickness: 1.0, color: t.alternate),
              Expanded(child: main),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 380.0, child: rail),
            VerticalDivider(width: 1.0, thickness: 1.0, color: t.alternate),
            Expanded(child: main),
          ],
        );
      },
    );
  }
}

class _SourceRail extends StatelessWidget {
  const _SourceRail({
    required this.matter,
    required this.sources,
    required this.selected,
    required this.pending,
    required this.onSelect,
    required this.onShowAll,
  });

  final MattersRecord matter;
  final List<ReceiptsRecord> sources;
  final String? selected;
  final int pending;
  final ValueChanged<String> onSelect;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      color: t.secondaryBackground,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Evidence sources: ${sources.length}${pending > 0 ? ' (+$pending reading)' : ''}',
                  style: VerinText.titleSmall(context),
                ),
              ),
              if (selected != null)
                IconButton(
                  tooltip: 'Show all',
                  icon: Icon(Icons.filter_list_off_rounded, size: 20.0, color: t.secondaryText),
                  onPressed: onShowAll,
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          ScreenshotUploadCard(matter: matter, compact: true),
          const SizedBox(height: 16.0),
          if (sources.isEmpty)
            Text('No screenshots with extracted messages yet.', style: VerinText.small(context))
          else
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final r in sources)
                  _Thumb(
                    receipt: r,
                    selected: selected == r.reference.path,
                    onTap: () => onSelect(r.reference.path),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.receipt, required this.selected, required this.onTap});

  final ReceiptsRecord receipt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: t.primaryBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: selected ? t.secondary : t.alternate, width: selected ? 2.0 : 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (receipt.sourceUrl.isNotEmpty)
              Image.network(
                receipt.sourceUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: t.secondaryText),
              )
            else
              Icon(Icons.image_outlined, color: t.secondaryText),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: const Color(0xB3FFFFFF),
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Text(
                  receipt.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VerinText.mono(context, color: t.primaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadItem extends StatelessWidget {
  const _ThreadItem({required this.entry, required this.onOpenSource});

  final ThreadEntry entry;
  final VoidCallback onOpenSource;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final e = entry;

    if (e.isHeader) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(e.text.isEmpty ? e.timestampLabel : e.text, style: VerinText.mono(context)),
        ),
      );
    }

    // Guide §6c: client on the left in a light bubble, the other party on the
    // right in a dark one.
    final client = e.isFromClient;
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420.0),
      child: InkWell(
        onTap: onOpenSource,
        borderRadius: BorderRadius.circular(8.0),
        child: Opacity(
          opacity: e.isRepeat ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: client ? t.secondaryBackground : t.primary,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: e.isLowConfidence ? t.warning : (client ? t.alternate : t.primary),
                width: 1.0,
              ),
            ),
            child: Text(
              e.text.isEmpty ? '[empty]' : e.text,
              style: VerinText.body(context, color: client ? t.primaryText : t.onPrimary),
            ),
          ),
        ),
      ),
    );

    final meta = <String>[
      if (e.timestampLabel.isNotEmpty) e.timestampLabel,
      if (e.isRepeat) 'repeated in a later screenshot',
      if (e.isLowConfidence) 'low confidence (${(e.confidence * 100).round()}%)',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (e.isGap)
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: t.secondaryBackground,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: t.alternate),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off_rounded, size: 16.0, color: t.secondaryText),
                  const SizedBox(width: 8.0),
                  Text(
                    'Gap — continuity not established',
                    style: VerinText.mono(context, weight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Align(
            alignment: client ? Alignment.centerLeft : Alignment.centerRight,
            child: Column(
              crossAxisAlignment: client ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!client && e.isLowConfidence) ...[
                      Icon(Icons.report_problem_rounded, size: 18.0, color: t.warning),
                      const SizedBox(width: 8.0),
                    ],
                    Flexible(child: bubble),
                    if (client && e.isLowConfidence) ...[
                      const SizedBox(width: 8.0),
                      Icon(Icons.report_problem_rounded, size: 18.0, color: t.warning),
                    ],
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(meta, style: VerinText.mono(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
