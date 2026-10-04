// Verin Legal — Standalone Verify Tool (guide §10): recompute this matter's
// hash chain on the server and show whether it is intact.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import '../record_ext.dart';
import '../verin_api.dart';
import '../verin_format.dart';
import '../verin_ui.dart';

class VerifyChainSheet extends StatefulWidget {
  const VerifyChainSheet({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<VerifyChainSheet> createState() => _VerifyChainSheetState();
}

class _VerifyChainSheetState extends State<VerifyChainSheet> {
  Map<String, dynamic>? _result;
  String? _error;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final r = await VerinApi.verifyMatterChain(widget.matter.reference.id);
      if (mounted) setState(() => _result = r);
    } on VerinApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  int _n(String k) {
    final v = _result?[k];
    return v is num ? v.toInt() : 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final r = _result;
    final ok = r?['ok'] == true;
    final head = (r?['head'] ?? '').toString();
    final legacy = _n('legacyEntries');

    Widget status;
    if (_running && r == null) {
      status = const VerinLoading();
    } else if (_error != null) {
      status = Text('Verification could not run: $_error', style: VerinText.body(context, color: t.error));
    } else if (r == null) {
      status = const SizedBox.shrink();
    } else {
      status = VerinCard(
        color: ok ? t.success5 : const Color(0x0DB03A2E),
        borderColor: ok ? t.success40 : t.error,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ok ? Icons.verified_rounded : Icons.gpp_bad_rounded, color: ok ? t.success : t.error, size: 28.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ok
                        ? (_n('verifiedEntries') == 0 ? 'No verifiable entries yet' : 'Chain intact')
                        : 'Chain broken at entry #${r['brokenAt'] ?? '?'}',
                    style: VerinText.title(context, color: ok ? t.success : t.error),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    ok
                        ? 'Recomputed ${pluralize(_n('verifiedEntries'), 'entry', 'entries')} from their stored inputs; '
                            'every link matches.'
                        : (r['reason'] ?? 'An entry does not match its inputs.').toString(),
                    style: VerinText.small(context),
                  ),
                  if (legacy > 0) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      '${pluralize(legacy, 'earlier entry', 'earlier entries')} predate server-side chaining and '
                      'carry no inputs to recompute, so they were skipped.',
                      style: VerinText.small(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return VerinSheetFrame(
      title: 'Standalone verify tool',
      subtitle: widget.matter.title,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          VerinButton(
            label: 'Run again',
            icon: Icons.refresh_rounded,
            loading: _running,
            onPressed: _running ? null : _run,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          status,
          const SizedBox(height: 24.0),
          VerinHashLine(
            label: 'Chain head (recomputed)',
            value: head,
            onCopied: head.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: head));
                    if (context.mounted) showVerinSnack(context, 'Chain head copied.');
                  },
          ),
          if (r != null && r['headMatches'] == false) ...[
            const SizedBox(height: 8.0),
            Text(
              'The chain head stored on the matter (${shortHash((r['storedHead'] ?? '').toString())}) does not match '
              'the recomputed head.',
              style: VerinText.small(context, color: t.error),
            ),
          ],
          const SizedBox(height: 24.0),
          Text('HOW TO VERIFY WITHOUT VERIN', style: VerinText.label(context)),
          const SizedBox(height: 8.0),
          for (final step in const [
            '1. Hash each original file with SHA-256. It must equal that exhibit\'s item_hash.',
            '2. Starting from 64 zeros, compute SHA-256 of prev_hash|item_hash|received_at|origin_digest for each entry in order.',
            '3. Each result must equal that entry\'s entry_hash, and becomes the next entry\'s prev_hash.',
            '4. The last result must equal the chain head printed on the certificate.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(step, style: VerinText.small(context)),
            ),
          const SizedBox(height: 8.0),
          Text(
            'The exported record PDF lists every entry\'s inputs in its appendix, so these steps can be run with any '
            'standard SHA-256 tool.',
            style: VerinText.small(context),
          ),
        ],
      ),
    );
  }
}
