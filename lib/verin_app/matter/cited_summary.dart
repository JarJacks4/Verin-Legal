// Cited summary on the Thread tab: a short summary of the conversation (or
// of one topic), where every line links to the messages it rests on. Tap a
// number to check that message against the original.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_api.dart';

import '../data/record_view.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import 'verification_view.dart';

class CitedSummaryCard extends StatefulWidget {
  const CitedSummaryCard({super.key, required this.matter, required this.receipts, required this.thread});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final ThreadDoc thread;

  @override
  State<CitedSummaryCard> createState() => _CitedSummaryCardState();
}

class _CitedSummaryCardState extends State<CitedSummaryCard> {
  final _topic = TextEditingController();
  List<(String, List<String>)>? _lines;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await VerinApi.summarizeThread(widget.matter.reference.id, topic: _topic.text.trim());
      final lines = <(String, List<String>)>[
        for (final l in (r['lines'] as List? ?? const []).whereType<Map>())
          ('${l['text'] ?? ''}', [for (final k in (l['cites'] as List? ?? const [])) '$k']),
      ];
      if (mounted) setState(() => _lines = lines);
    } catch (e) {
      if (mounted) setState(() => _error = e is VerinApiException ? e.message : '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _openCite(String key) {
    final e = widget.thread.entries.where((x) => x.key == key).firstOrNull;
    if (e == null) return;
    final r = widget.receipts.where((x) => x.reference.id == e.rid).firstOrNull;
    if (r == null) return;
    showVerificationView(context, receipt: r, matter: widget.matter, messageIndex: e.index);
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    // Citation numbers in order of first appearance.
    final numbers = <String, int>{};
    for (final (_, cites) in _lines ?? const <(String, List<String>)>[]) {
      for (final k in cites) {
        numbers.putIfAbsent(k, () => numbers.length + 1);
      }
    }
    return VPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('CITED SUMMARY', style: VT.eyebrow(context, size: 10.0)),
          const SizedBox(height: 6.0),
          Text('Every line links to the messages it comes from. Lines the AI can\'t tie to a message are left out.', style: VT.muted(context, size: 12.0)),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Expanded(child: VTextField(controller: _topic, hint: 'Optional topic, e.g. pickup times', onSubmitted: (_) => _busy ? null : _run())),
              const SizedBox(width: 8.0),
              VButton(label: _lines == null ? 'Summarize' : 'Again', icon: Icons.notes, kind: VButtonKind.tonal, size: VButtonSize.sm, loading: _busy, loadingLabel: 'Reading…', onPressed: _busy ? null : _run),
            ],
          ),
          if (_error != null) ...[const SizedBox(height: 10.0), VErrorBox(message: _error!)],
          if (_lines != null) ...[
            const SizedBox(height: 12.0),
            if (_lines!.isEmpty) Text('Nothing in the thread matches that topic.', style: VT.muted(context, size: 12.0)),
            for (final (text, cites) in _lines!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: [
                    Text(text, style: VT.body(context, size: 13.0, height: 1.5)),
                    for (final k in cites)
                      VHover(
                        onTap: () => _openCite(k),
                        builder: (context, h) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
                          decoration: BoxDecoration(
                            color: h ? c.teal : c.tealPale,
                            borderRadius: BorderRadius.circular(VR.pill),
                          ),
                          child: Text('${numbers[k]}', style: VT.mono(context, size: 10.5, weight: FontWeight.w600, color: h ? c.primaryFg : c.tealDeep)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
