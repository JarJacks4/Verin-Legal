// Verin Legal — Integrity tab (guide §7): chain status tiles, the per-matter
// hash chain, and the certificate / verify / export entry points.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/components/hash_row_widget.dart';
import '/components/integrity_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../record_ext.dart';
import '../sheets/certificate_sheet.dart';
import '../sheets/verify_chain_sheet.dart';
import '../verin_api.dart';
import '../verin_config.dart';
import '../verin_format.dart';
import '../verin_ui.dart';

/// Median days between when an item is dated (resolvedDate) and when Verin
/// received it, over this matter's receipts. Null when nothing is dated.
double? medianRecordLagDays(List<ReceiptsRecord> receipts) {
  final lags = <num>[];
  for (final r in receipts) {
    final dated = r.resolvedDate;
    final received = r.receivedAt;
    if (dated == null || received == null) continue;
    final days = received.difference(dated).inHours / 24.0;
    if (days >= 0) lags.add(days);
  }
  return median(lags);
}

class IntegrityTab extends StatefulWidget {
  const IntegrityTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<IntegrityTab> createState() => _IntegrityTabState();
}

class _IntegrityTabState extends State<IntegrityTab> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final r = await VerinApi.exportMatterRecord(widget.matter.reference.id);
      final url = (r['downloadUrl'] ?? '').toString();
      if (!mounted) return;
      if (url.isNotEmpty) await launchURL(url);
      if (mounted) showVerinSnack(context, 'Record exported. SHA-256 of the PDF: ${shortHash((r['sha256'] ?? '').toString())}');
    } on VerinApiException catch (e) {
      if (mounted) showVerinSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final m = widget.matter;

    final chainValue = m.chainVerified ? 'Verified' : (m.hasChainRoot ? 'Needs review' : 'Not started');
    final chainTone = m.chainVerified ? t.success : (m.hasChainRoot ? t.warning : t.secondaryText);

    final anchored = m.hashChainLastAnchoredAt;
    final lag = medianRecordLagDays(widget.receipts);
    final lagValue = lag == null ? 'No dated items' : '${lag.round()} days';
    final lagTone = lag == null ? t.secondaryText : (lag <= kBaselineRecordLagDays ? t.success : t.error);

    final tiles = [
      IntegrityCardWidget(
        icon: Icon(Icons.shield_rounded, color: t.secondary, size: 24.0),
        label: 'Chain status',
        tone: chainTone,
        value: chainValue,
      ),
      IntegrityCardWidget(
        icon: Icon(Icons.anchor_rounded, color: t.secondary, size: 24.0),
        label: 'Last external anchor',
        tone: anchored == null ? t.warning : t.success,
        value: anchored == null ? 'Not anchored yet' : fmtRelative(anchored),
      ),
      IntegrityCardWidget(
        icon: Icon(Icons.history_rounded, color: t.secondary, size: 24.0),
        label: 'Record lag (median) · baseline $kBaselineRecordLagDays days',
        tone: lagTone,
        value: lagValue,
      ),
      IntegrityCardWidget(
        icon: Icon(Icons.description_rounded, color: t.secondary, size: 24.0),
        label: 'The Standing Record',
        tone: t.success,
        value: '${pluralize(widget.receipts.length, 'item')} built',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Integrity at receipt', style: VerinText.heading(context)),
          const SizedBox(height: 8.0),
          Text(
            'A third party holding only an exported file and its manifest can verify the hash and the timestamp '
            'without any access to Verin.',
            style: VerinText.bodyMuted(context),
          ),
          const SizedBox(height: 32.0),
          Row(children: [Expanded(child: tiles[0]), const SizedBox(width: 16.0), Expanded(child: tiles[1])]),
          const SizedBox(height: 16.0),
          Row(children: [Expanded(child: tiles[2]), const SizedBox(width: 16.0), Expanded(child: tiles[3])]),
          const SizedBox(height: 32.0),
          VerinCard(
            padding: const EdgeInsets.all(32.0),
            child: StreamBuilder<List<ChainEntriesRecord>>(
              stream: queryChainEntriesRecord(
                queryBuilder: (q) =>
                    q.where('matterID', isEqualTo: m.reference).orderBy('seq', descending: true),
                limit: 50,
              ),
              builder: (context, snap) {
                final entries = snap.data ?? const <ChainEntriesRecord>[];
                final head = m.chainHeadHash.isNotEmpty
                    ? m.chainHeadHash
                    : (entries.isNotEmpty ? entries.first.entryHash : '');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('PER-MATTER HASH CHAIN', style: VerinText.label(context))),
                        if (m.chainLength > 0)
                          Text(pluralize(m.chainLength, 'entry', 'entries'), style: VerinText.label(context)),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4EEEF),
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: Text(
                        'entry = SHA256( prev_hash || item_hash || received_at || origin_digest )',
                        style: VerinText.mono(context),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    if (snap.hasError)
                      Text(
                        'The chain could not be loaded (${snap.error}). If this mentions an index, deploy '
                        'firebase/firestore.indexes.json.',
                        style: VerinText.small(context, color: t.error),
                      )
                    else if (!snap.hasData)
                      const VerinLoading()
                    else if (entries.isEmpty)
                      Text(
                        'No chain entries yet. The first receipt added to this matter becomes the chain root.',
                        style: VerinText.small(context),
                      )
                    else
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: HashRowWidget(
                            key: ValueKey(e.reference.path),
                            hash: e.entryHash.isEmpty ? kDash : e.entryHash,
                            index: '${e.seq}',
                          ),
                        ),
                    Divider(height: 32.0, thickness: 1.0, color: t.alternate),
                    Row(
                      children: [
                        Text('Chain head', style: VerinText.mono(context)),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: SelectableText(
                            head.isEmpty ? kDash : head,
                            style: VerinText.mono(context, color: t.primaryText),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 12.0,
            children: [
              VerinButton(
                label: 'Certificate of preparation',
                icon: Icons.description_rounded,
                variant: VerinButtonVariant.primary,
                size: VerinButtonSize.large,
                onPressed: () => showVerinSheet(
                  context,
                  CertificateSheet(matter: m, receipts: widget.receipts),
                  maxWidth: 760.0,
                ),
              ),
              VerinButton(
                label: 'Standalone verify tool',
                icon: Icons.verified_rounded,
                size: VerinButtonSize.large,
                onPressed: () => showVerinSheet(context, VerifyChainSheet(matter: m)),
              ),
              VerinButton(
                label: 'Export record (PDF)',
                icon: Icons.picture_as_pdf_rounded,
                size: VerinButtonSize.large,
                loading: _exporting,
                onPressed: _exporting ? null : _export,
              ),
            ],
          ),
          const SizedBox(height: 32.0),
          Text(
            'Verin does not practice law. No opinion on authenticity, completeness, or admissibility is offered or '
            'implied — those determinations belong to counsel and the Court.',
            style: VerinText.small(context, color: t.accent3),
          ),
        ],
      ),
    );
  }
}
