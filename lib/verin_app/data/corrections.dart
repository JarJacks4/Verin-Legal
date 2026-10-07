// Reviewer corrections to what the AI read. A correction never edits the
// receipt: the AI's reading stays as it was, the correction sits beside it
// with who made it and when, and both are shown. Each one is also logged for
// the firm's value report (correction rate).

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

final _col = FirebaseFirestore.instance.collection('Corrections');

/// What a correction applies to: a message ("m") or a statement ("s") of a receipt.
String correctionTarget(String receiptId, String type, int index) => '$receiptId#$type$index';

class Correction {
  Correction(this.ref, Map<String, dynamic> d)
      : target = '${d['target'] ?? ''}',
        field = '${d['field'] ?? ''}',
        original = '${d['original'] ?? ''}',
        corrected = '${d['corrected'] ?? ''}',
        byName = '${d['byName'] ?? ''}',
        byUid = '${d['byUid'] ?? ''}',
        at = (d['at'] as Timestamp?)?.toDate();
  final DocumentReference ref;
  final String target, field, original, corrected, byName, byUid;
  final DateTime? at;
}

/// Latest correction per target and field: { target: { field: Correction } }.
Stream<Map<String, Map<String, Correction>>> matterCorrectionsStream(DocumentReference matter) => _col
        .where('matterId', isEqualTo: matter)
        .where('firmID', isEqualTo: currentFirmId())
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => Correction(d.reference, d.data())).toList()
        ..sort((a, b) => (a.at ?? DateTime(2100)).compareTo(b.at ?? DateTime(2100)));
      final out = <String, Map<String, Correction>>{};
      for (final c in list) {
        (out[c.target] ??= {})[c.field] = c;
      }
      return out;
    });

Future<void> saveCorrection({
  required DocumentReference matter,
  required DocumentReference receipt,
  required String target,
  required String field,
  required String original,
  required String corrected,
}) async {
  final firm = currentFirmId();
  final batch = FirebaseFirestore.instance.batch();
  batch.set(_col.doc(), {
    'firmID': firm,
    'matterId': matter,
    'receiptId': receipt,
    'target': target,
    'field': field,
    'original': original,
    'corrected': corrected,
    'byUid': currentUserUid,
    'byName': VUser.current().name,
    'at': FieldValue.serverTimestamp(),
  });
  batch.set(FirebaseFirestore.instance.collection('Activity').doc(), {
    'firmID': firm,
    'matterId': matter,
    'receiptId': receipt,
    'uid': currentUserUid,
    'type': 'correction',
    'field': field,
    'at': FieldValue.serverTimestamp(),
  });
  await batch.commit();
}

/// Dialog to correct one field. Returns true when saved.
Future<bool> showCorrectionDialog(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  required String aiValue,
  String? current,
  required Future<void> Function(String value) onSave,
  bool multiline = true,
}) async {
  final r = await showVDialog<bool>(
    context,
    builder: (ctx) => _CorrectionForm(
      title: title,
      fieldLabel: fieldLabel,
      aiValue: aiValue,
      current: current ?? aiValue,
      onSave: onSave,
      multiline: multiline,
    ),
  );
  return r == true;
}

class _CorrectionForm extends StatefulWidget {
  const _CorrectionForm({required this.title, required this.fieldLabel, required this.aiValue, required this.current, required this.onSave, required this.multiline});
  final String title, fieldLabel, aiValue, current;
  final Future<void> Function(String value) onSave;
  final bool multiline;

  @override
  State<_CorrectionForm> createState() => _CorrectionFormState();
}

class _CorrectionFormState extends State<_CorrectionForm> {
  late final _c = TextEditingController(text: widget.current);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _c.text.trim();
    if (v.isEmpty || v == widget.current.trim()) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(v);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save the reviewer note: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: VT.body(context, size: 16.0, weight: FontWeight.w600)),
        const SizedBox(height: 8.0),
        Text('The original file and the AI reading are never changed. Your reading is recorded beside them, with your name and the time.',
            style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 16.0),
        Text('AI READ', style: VT.eyebrow(context, size: 10.0)),
        const SizedBox(height: 4.0),
        Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(10.0)),
          child: SelectableText(widget.aiValue.isEmpty ? '—' : widget.aiValue, style: VT.body(context, size: 13.0)),
        ),
        const SizedBox(height: 14.0),
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 12.0)],
        VTextField(controller: _c, label: widget.fieldLabel, maxLines: widget.multiline ? 4 : 1),
        const SizedBox(height: 20.0),
        Row(
          children: [
            Expanded(child: VButton(label: 'Cancel', kind: VButtonKind.secondary, fullWidth: true, onPressed: _busy ? null : () => Navigator.of(context).pop(false))),
            const SizedBox(width: 12.0),
            Expanded(child: VButton(label: 'Save reviewer note', fullWidth: true, loading: _busy, onPressed: _save)),
          ],
        ),
      ],
    );
  }
}

/// Every correction in the firm (Admin → Dashboard accuracy measure).
Stream<List<Correction>> firmCorrectionsStream() => _col
    .where('firmID', isEqualTo: currentFirmId())
    .snapshots()
    .map((s) => s.docs.map((d) => Correction(d.reference, d.data())).toList());
