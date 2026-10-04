// Verin Legal — search the firm's Clio matters and link one to this matter.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import '../record_ext.dart';
import '../verin_api.dart';
import '../verin_ui.dart';

class ClioLinkSheet extends StatefulWidget {
  const ClioLinkSheet({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<ClioLinkSheet> createState() => _ClioLinkSheetState();
}

class _ClioLinkSheetState extends State<ClioLinkSheet> {
  late final TextEditingController _q;
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String? _linkingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.matter;
    _q = TextEditingController(text: m.clientName.isNotEmpty ? m.clientName : m.title);
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final r = await VerinApi.clioSearchMatters(_q.text.trim());
      if (mounted) setState(() => _results = r);
    } on VerinApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _link(String clioId) async {
    setState(() => _linkingId = clioId);
    try {
      await VerinApi.clioLinkMatter(matterId: widget.matter.reference.id, clioMatterId: clioId);
      if (!mounted) return;
      showVerinSnack(context, 'Linked to Clio.');
      Navigator.of(context).maybePop();
    } on VerinApiException catch (e) {
      if (mounted) showVerinSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _linkingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final current = widget.matter.clioMatterRef;
    return VerinSheetFrame(
      title: 'Link to a Clio matter',
      subtitle: 'Search your firm\'s Clio matters by client, matter number or description.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'e.g. Whitmore',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              VerinButton(label: 'Search', loading: _searching, onPressed: _searching ? null : _search),
            ],
          ),
          const SizedBox(height: 16.0),
          if (_error != null)
            Text(_error!, style: VerinText.small(context, color: t.error))
          else if (_searching && _results.isEmpty)
            const VerinLoading()
          else if (_results.isEmpty)
            Text('No Clio matters found.', style: VerinText.small(context))
          else
            for (final r in _results)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.alternate))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['displayNumber'] ?? ''}  ${r['description'] ?? ''}'.trim(),
                            style: VerinText.body(context),
                          ),
                          Text(
                            [
                              if ((r['clientName'] ?? '').toString().isNotEmpty) r['clientName'].toString(),
                              if ((r['status'] ?? '').toString().isNotEmpty) r['status'].toString(),
                            ].join(' · '),
                            style: VerinText.small(context),
                          ),
                        ],
                      ),
                    ),
                    if ((r['id'] ?? '').toString() == current)
                      VerinTag(label: 'Linked', background: t.success10, foreground: t.success)
                    else
                      VerinButton(
                        label: 'Link',
                        size: VerinButtonSize.small,
                        variant: VerinButtonVariant.primary,
                        loading: _linkingId == (r['id'] ?? '').toString(),
                        onPressed: _linkingId != null ? null : () => _link((r['id'] ?? '').toString()),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
