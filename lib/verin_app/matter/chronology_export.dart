// The chronology, built on the server as a branded PDF like every other
// document Verin hands a firm. Each line cites the exhibit it was read from,
// and breaks in continuity are printed as breaks rather than closed over.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/verin_api.dart';

import '../data/record_view.dart';
import '../widgets/atoms.dart';

class ChronologyExportButton extends StatefulWidget {
  const ChronologyExportButton({super.key, required this.matter, required this.thread, required this.receipts});

  final MattersRecord matter;
  final ThreadDoc? thread;
  final List<ReceiptsRecord> receipts;

  @override
  State<ChronologyExportButton> createState() => _ChronologyExportButtonState();
}

class _ChronologyExportButtonState extends State<ChronologyExportButton> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final r = await VerinApi.exportChronologyPdf(widget.matter.reference.id);
      final url = '${r['downloadUrl'] ?? ''}';
      if (url.isNotEmpty) await launchURL(url);
      if (!mounted) return;
      showVToast(context, 'Chronology ready', description: 'Every line cites the exhibit it was read from.');
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, 'Could not build the chronology', error: true, description: e.message);
    } catch (e) {
      if (mounted) showVToast(context, 'Could not build the chronology', error: true, description: '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => VButton(
        label: 'Chronology (PDF)',
        icon: Icons.picture_as_pdf_outlined,
        kind: VButtonKind.secondary,
        size: VButtonSize.sm,
        loading: _busy,
        loadingLabel: 'Building…',
        onPressed: _busy ? null : _export,
      );
}
