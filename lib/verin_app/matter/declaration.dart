// Draft declaration for a finished production: covers Verin's own receipt
// records only (when each item arrived and that it hasn't changed since),
// with instructions for checking them. The attorney edits and signs it;
// counsel reviews the template before first use.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import 'exhibits_tab.dart' show Production;

String declarationText({required MattersRecord matter, required Production p, required List<ReceiptsRecord> receipts, required VUser user}) {
  final byId = {for (final r in receipts) r.reference.id: r};
  final firm = user.firm.isEmpty ? '[FIRM]' : user.firm;
  final rows = <String>[];
  for (final e in p.exhibits) {
    final r = byId['${e['receiptId'] ?? ''}'];
    final bates = [e['firstBates'], e['lastBates']].where((v) => v != null && '$v'.isNotEmpty).join(' – ');
    rows.add([
      'Exhibit ${e['label'] ?? ''}${bates.isEmpty ? '' : ' (Bates $bates)'}',
      '   Received: ${fmtWhen(r?.receivedAt)}${r == null || r.fileName.isEmpty ? '' : ' · file "${r.fileName}"'}',
      '   SHA-256 at receipt: ${r == null || r.itemHash.isEmpty ? '[not available]' : r.itemHash}',
      if (r != null && r.chainSeq > 0) "   Entry #${r.chainSeq} in the matter's hash chain",
      if (r != null && r.tsaTime != null) '   RFC 3161 timestamp: ${r.tsaName.isEmpty ? 'time-stamp authority' : r.tsaName}, ${fmtWhen(r.tsaTime)}',
      if ((e['redactions'] is num) && (e['redactions'] as num) > 0) '   Produced with ${e['redactions']} redaction(s); the SHA-256 above is of the item as received.',
    ].join('\n'));
  }
  final caseLine = [matter.title, if (matter.caseNumber.isNotEmpty) 'Cause No. ${matter.caseNumber}'].join(', ');
  return [
    'DECLARATION REGARDING RECEIPT RECORDS',
    caseLine,
    '',
    'I, [NAME], declare:',
    '',
    '1. I am [TITLE] at $firm, counsel for [PARTY] in this matter. I have personal knowledge of the facts below and of how this firm receives material from its client.',
    '',
    '2. This firm receives client material for this matter through Verin Legal, a records service. When an item arrives, the service computes a SHA-256 hash of the exact bytes received, records the time of receipt, adds the hash to a hash chain kept for this matter, and obtains an RFC 3161 timestamp token for the hash from an independent time-stamp authority.',
    '',
    '3. The exhibits listed below, produced as "${p.name.isEmpty ? 'Production' : p.name}" (version ${p.version}, Bates ${p.batesStart} – ${p.batesEnd}), are true copies of items as this firm received them:',
    '',
    ...rows.expand((r) => [r, '']),
    '4. This declaration concerns only these receipt records: when each item reached this firm and that it has not changed since. It does not state who created any item, whether its contents are true, or when the events it shows took place.',
    '',
    '5. Anyone can check these records. Computing the SHA-256 hash of an item and comparing it with the value above confirms it is unchanged. The production ZIP includes each timestamp token and a script (verify.py) that checks the tokens and the hash chain without Verin Legal\'s involvement.',
    '',
    'I declare under penalty of perjury under the laws of [STATE] that the foregoing is true and correct.',
    '',
    'Executed on [DATE] at [CITY, STATE].',
    '',
    '______________________________',
    '[NAME]',
  ].join('\n');
}

Future<void> showDeclarationDraft(BuildContext context, {required MattersRecord matter, required Production production, required List<ReceiptsRecord> receipts}) =>
    showVDrawer<void>(
      context,
      title: 'Draft declaration',
      width: 620.0,
      builder: (_) => _DeclarationEditor(text: declarationText(matter: matter, p: production, receipts: receipts, user: VUser.current())),
    );

class _DeclarationEditor extends StatefulWidget {
  const _DeclarationEditor({required this.text});

  final String text;

  @override
  State<_DeclarationEditor> createState() => _DeclarationEditorState();
}

class _DeclarationEditorState extends State<_DeclarationEditor> {
  late final _ctrl = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VNotice(
          tone: VNoticeTone.pending,
          text: 'A starting draft, not legal advice. Fill in the bracketed fields, check every line against the production index, and adapt it to your court\'s rules before signing.',
        ),
        const SizedBox(height: 16.0),
        VTextField(controller: _ctrl, maxLines: 28),
        const SizedBox(height: 16.0),
        VButton(
          label: 'Copy declaration',
          icon: Icons.copy,
          onPressed: () => copyToClipboard(context, _ctrl.text, what: 'Declaration copied'),
        ),
      ],
    );
  }
}
