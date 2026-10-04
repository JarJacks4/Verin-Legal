// Verin Legal — Certificate of Preparation (guide §13 bugs #2/#3).
//
// The on-screen preview binds every field to the matter; the court-facing
// document is the PDF built server-side by exportMatterRecord, which stamps
// its own generation time and SHA-256. Nothing here is AI-generated (§14g).

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../record_ext.dart';
import '../thread_merge.dart';
import '../verin_api.dart';
import '../verin_format.dart';
import '../verin_ui.dart';

class CertificateSheet extends StatefulWidget {
  const CertificateSheet({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<CertificateSheet> createState() => _CertificateSheetState();
}

class _CertificateSheetState extends State<CertificateSheet> {
  bool _exporting = false;
  Map<String, dynamic>? _export;

  Future<void> _download() async {
    setState(() => _exporting = true);
    try {
      final r = await VerinApi.exportMatterRecord(widget.matter.reference.id);
      if (!mounted) return;
      setState(() => _export = r);
      final url = (r['downloadUrl'] ?? '').toString();
      if (url.isNotEmpty) await launchURL(url);
    } on VerinApiException catch (e) {
      if (mounted) showVerinSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _row(BuildContext context, String label, String value) {
    final t = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 180.0, child: Text(label, style: VerinText.label(context))),
          Expanded(child: SelectableText(orDash(value), style: VerinText.body(context, color: t.primaryText))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final m = widget.matter;
    final ordered = [...widget.receipts]
      ..sort((a, b) => (a.receivedAt ?? DateTime(0)).compareTo(b.receivedAt ?? DateTime(0)));
    final gaps = threadGapCount(mergeThread(widget.receipts));
    final redactions = m.redactionCount > 0
        ? '${m.redactionCount}${m.redactionCategories.isNotEmpty ? ' (${m.redactionCategories})' : ''}'
        : 'None recorded';

    return VerinSheetFrame(
      title: 'Certificate of Preparation',
      subtitle: 'Preview · the exported PDF carries its own generation time and SHA-256',
      footer: Row(
        children: [
          Expanded(
            child: _export == null
                ? Text('The PDF is built from the same data shown here.', style: VerinText.small(context))
                : Text(
                    'Exported ${fmtDateTime(DateTime.tryParse((_export!['generatedAt'] ?? '').toString())?.toLocal())} · '
                    'SHA-256 ${shortHash((_export!['sha256'] ?? '').toString())}',
                    style: VerinText.small(context, color: t.success),
                  ),
          ),
          VerinButton(
            label: 'Download PDF',
            icon: Icons.picture_as_pdf_rounded,
            variant: VerinButtonVariant.primary,
            loading: _exporting,
            onPressed: _exporting ? null : _download,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MATTER OVERVIEW', style: VerinText.label(context)),
          const SizedBox(height: 8.0),
          _row(context, 'Matter', m.title),
          _row(context, 'Client', m.clientName),
          _row(context, 'Case number', m.caseNumber),
          _row(context, 'Assigned counsel', m.assignedCounsel),
          _row(context, 'Practice area', m.practiceArea),
          _row(context, 'Opened', fmtDate(m.openedAt)),
          const SizedBox(height: 16.0),
          Text('RECORD', style: VerinText.label(context)),
          const SizedBox(height: 8.0),
          _row(context, 'Items in record', '${ordered.length}'),
          _row(context, 'Chain entries', m.chainLength > 0 ? '${m.chainLength}' : ''),
          _row(context, 'Chain head', m.chainHeadHash),
          _row(context, 'Last external anchor', m.hashChainLastAnchoredAt == null ? 'Not anchored yet' : fmtDateTime(m.hashChainLastAnchoredAt)),
          _row(context, 'Continuity gaps detected', '$gaps'),
          _row(context, 'Redactions', redactions),
          const SizedBox(height: 16.0),
          Text('ITEMIZED EXHIBIT INDEX', style: VerinText.label(context)),
          const SizedBox(height: 8.0),
          if (ordered.isEmpty)
            Text('No items in this record yet.', style: VerinText.small(context))
          else
            for (var i = 0; i < ordered.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.alternate))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 44.0, child: Text('${i + 1}', style: VerinText.mono(context, weight: FontWeight.bold))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ordered[i].headline, style: VerinText.body(context)),
                          Text(
                            '${fmtDateTime(ordered[i].receivedAt)} · ${orDash(ordered[i].channel)} · '
                            'SHA-256 ${ordered[i].itemHash.isEmpty ? kDash : shortHash(ordered[i].itemHash)}',
                            style: VerinText.mono(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 24.0),
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
