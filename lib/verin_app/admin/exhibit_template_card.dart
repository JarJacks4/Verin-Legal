// Admin → Settings → Exhibit template: how this firm's productions look.
// Saved on the firm account as productionTemplate; the produceExhibits
// function reads it (and falls back to safe defaults).

import 'package:flutter/material.dart';

import '/backend/backend.dart';

import '../matter/exhibits_tab.dart' show ExhibitTemplate;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../onboarding/tour.dart' show TourTarget, demoType;

class ExhibitTemplateCard extends StatefulWidget {
  const ExhibitTemplateCard({super.key, required this.firm});
  final FirmAccountRecord? firm;

  @override
  State<ExhibitTemplateCard> createState() => _ExhibitTemplateCardState();
}

class _ExhibitTemplateCardState extends State<ExhibitTemplateCard> {
  late final ExhibitTemplate _t = ExhibitTemplate.of(widget.firm);
  late final _prefix = TextEditingController(text: _t.batesPrefix);
  late final _word = TextEditingController(text: _t.exhibitWord);
  late final _legend = TextEditingController(text: _t.legend);
  late final _title = TextEditingController(text: _t.indexTitle);
  late int _digits = _t.batesDigits;
  late String _style = _t.exhibitStyle;
  late String _position = _t.stampPosition;
  late bool _slips = _t.slipSheets;
  bool _saving = false;

  @override
  void dispose() {
    _prefix.dispose();
    _word.dispose();
    _legend.dispose();
    _title.dispose();
    super.dispose();
  }

  ExhibitTemplate get _preview => ExhibitTemplate({
        'batesPrefix': _prefix.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_-]'), ''),
        'batesDigits': _digits,
        'exhibitStyle': _style,
        'exhibitWord': _word.text.trim(),
      });

  Future<void> _save() async {
    final f = widget.firm;
    if (f == null) {
      showVToast(context, 'Your firm profile is still being set up. Reload and try again.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await f.reference.update({
        'productionTemplate': {
          'batesPrefix': _prefix.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_-]'), ''),
          'batesDigits': _digits,
          'exhibitStyle': _style,
          'exhibitWord': _word.text.trim(),
          'stampPosition': _position,
          'legend': _legend.text.trim(),
          'slipSheets': _slips,
          'indexTitle': _title.text.trim(),
        },
      });
      if (mounted) showVToast(context, 'Exhibit template saved');
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save the template: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final p = _preview;
    return TourTarget(
      id: 'settings_exhibits',
      onDemoTour: () async {
        await demoType(_prefix, 'DOE');
        await demoType(_legend, 'CONFIDENTIAL — SUBJECT TO PROTECTIVE ORDER', step: const Duration(milliseconds: 14));
        await demoType(_title, 'Exhibit Index');
        if (mounted) setState(() {});
      },
      child: VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How exhibits are numbered and stamped in this firm\'s productions.', style: VT.muted(context, size: 13.0)),
          const SizedBox(height: 16.0),
          Row(children: [
            Expanded(child: VTextField(controller: _prefix, label: 'Bates prefix', hint: 'HARBOW', onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12.0),
            SizedBox(
              width: 140.0,
              child: VSelect<int>(label: 'Digits', value: _digits, items: const [3, 4, 5, 6, 7, 8, 9, 10], labelFor: (d) => '$d', onChanged: (d) => setState(() => _digits = d)),
            ),
          ]),
          const SizedBox(height: 14.0),
          Row(children: [
            Expanded(child: VTextField(controller: _word, label: 'Exhibit word', hint: 'Exhibit', onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12.0),
            Expanded(
              child: VSegmented<String>(
                label: 'Numbering',
                value: _style,
                options: const ['number', 'letter'],
                labelFor: (s) => s == 'number' ? '1, 2, 3' : 'A, B, C',
                fontSize: 12.0,
                onChanged: (s) => setState(() => _style = s),
              ),
            ),
          ]),
          const SizedBox(height: 14.0),
          VSegmented<String>(
            label: 'Bates stamp position',
            value: _position,
            options: const ['bottom-left', 'bottom-center', 'bottom-right'],
            labelFor: (s) => s.replaceAll('bottom-', '').replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase()),
            fontSize: 12.0,
            onChanged: (s) => setState(() => _position = s),
          ),
          const SizedBox(height: 14.0),
          VTextField(controller: _legend, label: 'Confidentiality legend (optional)', hint: 'CONFIDENTIAL — SUBJECT TO PROTECTIVE ORDER'),
          const SizedBox(height: 14.0),
          VTextField(controller: _title, label: 'Index title', hint: 'Exhibit Index'),
          const SizedBox(height: 14.0),
          Row(children: [
            Expanded(child: Text('Slip sheet before each exhibit (with its source reference)', style: VT.body(context, size: 13.0))),
            VSwitch(value: _slips, onChanged: (v) => setState(() => _slips = v)),
          ]),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(10.0)),
            child: Text('Preview: ${p.exhibit(1)} · ${p.bates(1)} … ${p.exhibit(3)} · ${p.bates(27)}', style: VT.mono(context, size: 12.0)),
          ),
          const SizedBox(height: 16.0),
          Align(alignment: Alignment.centerRight, child: VButton(label: 'Save template', size: VButtonSize.sm, loading: _saving, onPressed: _save)),
        ],
      ),
    ),
    );
  }
}
