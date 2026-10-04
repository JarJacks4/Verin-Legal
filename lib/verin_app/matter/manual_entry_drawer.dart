// Add manual entry — port of the Make's <ManualEntryDrawer>. Real uploads:
// photos, videos/voice notes, documents, email files, or a physical item.
// Every file is hashed, timestamped and chained server-side, then read by AI.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_api.dart';

import '../data/evidence_upload.dart';
import '../data/format.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import '../widgets/upload_zone.dart';

Future<void> showManualEntryDrawer(BuildContext context, {required MattersRecord matter, EvidenceKind initialKind = EvidenceKind.photo}) =>
    showVDrawer<void>(context, title: 'Add manual entry', width: 500.0, builder: (_) => ManualEntryForm(matter: matter, initialKind: initialKind));

const _channels = [
  ('email', 'Email (out of band)'),
  ('sms', 'SMS / Text'),
  ('whatsapp', 'WhatsApp'),
  ('in_person', 'In-person / hand-off'),
  ('mail', 'Physical mail'),
  ('other', 'Other'),
];

class ManualEntryForm extends StatefulWidget {
  const ManualEntryForm({super.key, required this.matter, this.initialKind = EvidenceKind.photo});

  final MattersRecord matter;
  final EvidenceKind initialKind;

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  late EvidenceKind _kind = widget.initialKind;
  final List<StagedFile> _staged = [];
  final Map<int, double> _progress = {};
  final Map<int, String> _errors = {};
  final _source = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  String _channel = 'email';
  DateTime _date = DateTime.now();
  String _clientSide = 'right';
  bool _submitting = false;
  bool _done = false;
  String _doneDesc = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _source.addListener(() => setState(() {}));
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _source.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _needsUpload => _kind != EvidenceKind.physical;

  bool get _valid {
    if (_source.text.trim().isEmpty) return false;
    if (_needsUpload) return _staged.isNotEmpty;
    return _description.text.trim().isNotEmpty;
  }

  void _setKind(EvidenceKind k) {
    if (_submitting) return;
    setState(() {
      _kind = k;
      _staged.clear();
      _progress.clear();
      _errors.clear();
    });
  }

  Future<void> _pick() async {
    final res = await pickEvidence(kind: _kind, multiple: _kind != EvidenceKind.email);
    if (!mounted) return;
    setState(() {
      if (_kind == EvidenceKind.email) _staged.clear();
      _staged.addAll(res.files);
    });
    if (res.skipped.isNotEmpty) showVToast(context, 'Skipped: ${res.skipped.join(', ')}', error: true);
  }

  Future<void> _pickDate() async {
    final c = VC.of(context);
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: (c.dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(primary: c.teal, onPrimary: c.primaryFg, surface: c.card),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  String get _dateIso =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
      _errors.clear();
    });
    final nav = Navigator.of(context);
    var ok = 0;
    try {
      if (!_needsUpload) {
        await VerinApi.ingestEvidence(
          matterId: widget.matter.reference.id,
          kind: 'physical',
          channel: _channel,
          fromLabel: _source.text.trim(),
          dateReceived: _dateIso,
          description: _description.text.trim(),
          custodyNotes: _notes.text.trim(),
        );
        ok = 1;
      } else {
        for (var i = 0; i < _staged.length; i++) {
          try {
            await uploadAndIngest(
              matterId: widget.matter.reference.id,
              file: _staged[i],
              channel: _channel,
              fromLabel: _source.text.trim(),
              dateReceived: _dateIso,
              description: _description.text.trim(),
              custodyNotes: _notes.text.trim(),
              clientSide: _clientSide,
              onProgress: (p) {
                if (mounted) setState(() => _progress[i] = p);
              },
            );
            ok++;
          } catch (e) {
            final msg = e is VerinApiException ? e.message : 'Upload failed: $e';
            if (mounted) setState(() => _errors[i] = msg);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e is VerinApiException ? e.message : 'Could not add the entry: $e';
        });
      }
      return;
    }
    if (!mounted) return;
    if (_errors.isNotEmpty) {
      // Keep the drawer open so the failures are visible; drop the ones that worked.
      setState(() {
        _submitting = false;
        _error = '$ok of ${_staged.length} filed. The others failed — see below, then try again.';
        final keep = <StagedFile>[];
        final keepErr = <int, String>{};
        for (var i = 0; i < _staged.length; i++) {
          if (_errors.containsKey(i)) {
            keepErr[keep.length] = _errors[i]!;
            keep.add(_staged[i]);
          }
        }
        _staged
          ..clear()
          ..addAll(keep);
        _errors
          ..clear()
          ..addAll(keepErr);
        _progress.clear();
      });
      return;
    }
    setState(() {
      _done = true;
      _doneDesc = _needsUpload
          ? '${ok == 1 ? 'The file has' : '$ok files have'} been hashed, timestamped and added to the chain. AI reading runs next — results appear on the Receipts and Thread tabs.'
          : 'The manual entry has been recorded and hashed into the chain.';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (nav.mounted) nav.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    if (_done) return VSuccessState(title: 'Entry added', desc: _doneDesc);
    final label = evidenceKindLabel(_kind).toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Record evidence received outside the automated intake channels — hand-offs, physical items, or out-of-band files.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 20.0),
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 16.0)],
        Text('What are you adding?', style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
        const SizedBox(height: 8.0),
        Row(
          children: [
            for (var i = 0; i < EvidenceKind.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 8.0),
              Expanded(
                child: VHover(
                  onTap: () => _setKind(EvidenceKind.values[i]),
                  builder: (context, hovered) {
                    final k = EvidenceKind.values[i];
                    final on = k == _kind;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(color: on ? c.teal : c.secondary, borderRadius: BorderRadius.circular(VR.xl)),
                      child: Column(
                        children: [
                          Icon(iconForKind(k), size: 18.0, color: on ? c.primaryFg : c.mutedFg),
                          const SizedBox(height: 6.0),
                          Text(evidenceKindLabel(k),
                              style: VT.body(context, size: 11.0, weight: FontWeight.w500, color: on ? c.primaryFg : c.mutedFg, height: 1.2)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6.0),
        Text(evidenceKindHint(_kind), style: VT.muted(context, size: 11.0)),
        const SizedBox(height: 20.0),
        if (_needsUpload) ...[
          Text(
            'Upload $label${_kind == EvidenceKind.email ? ' file' : _kind == EvidenceKind.document ? '' : 's'}',
            style: VT.body(context, size: 13.0, weight: FontWeight.w500),
          ),
          const SizedBox(height: 8.0),
          UploadZone(
            compact: true,
            title: 'Choose $label file${_kind != EvidenceKind.email ? 's' : ''}',
            hint: evidenceKindHint(_kind).split(' — ').first,
            onTap: _submitting ? () {} : _pick,
          ),
          if (_staged.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            StagedList(
              files: _staged,
              progress: _progress,
              errors: _errors,
              onRemove: (i) {
                if (_submitting) return;
                setState(() {
                  _staged.removeAt(i);
                  _errors.remove(i);
                });
              },
            ),
            if (_kind != EvidenceKind.email)
              VButton(label: 'Add more files', icon: Icons.add, kind: VButtonKind.tonal, size: VButtonSize.sm, fullWidth: true, onPressed: _submitting ? null : _pick),
          ],
          if (_kind == EvidenceKind.photo || _kind == EvidenceKind.video) ...[
            const SizedBox(height: 16.0),
            VSegmented<String>(
              label: _kind == EvidenceKind.photo ? "In message screenshots, the client's messages are on the" : "In screen recordings of messages, the client's messages are on the",
              value: _clientSide,
              options: const ['right', 'left'],
              labelFor: (s) => s == 'right' ? 'Right side' : 'Left side',
              onChanged: (s) => setState(() => _clientSide = s),
            ),
          ],
          const SizedBox(height: 20.0),
        ],
        VTextField(controller: _source, label: 'Source / from', hint: 'Client name, opposing counsel, etc.'),
        const SizedBox(height: 16.0),
        VSelect<String>(
          label: 'How was it received?',
          value: _channel,
          items: _channels.map((e) => e.$1).toList(),
          labelFor: (v) => _channels.firstWhere((e) => e.$1 == v).$2,
          onChanged: (v) => setState(() => _channel = v),
        ),
        const SizedBox(height: 16.0),
        const VFieldLabel('Date received'),
        VHover(
          onTap: _pickDate,
          builder: (context, hovered) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
            decoration: BoxDecoration(color: c.inputBg, border: Border.all(color: hovered ? c.teal.withValues(alpha: 0.5) : c.border), borderRadius: BorderRadius.circular(VR.xl)),
            child: Row(
              children: [
                Expanded(child: Text(fmtDay(_date), style: VT.body(context))),
                Icon(Icons.calendar_today_outlined, size: 15.0, color: c.mutedFg),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        VTextField(
          controller: _description,
          label: _kind == EvidenceKind.physical ? 'Description of item' : 'Description (optional)',
          hint: _kind == EvidenceKind.physical
              ? 'Describe the physical item — what it is, its condition, and where it is now being stored…'
              : 'Any additional context about this evidence…',
          maxLines: _kind == EvidenceKind.physical ? 4 : 2,
        ),
        const SizedBox(height: 16.0),
        VTextField(controller: _notes, label: 'Chain of custody notes (optional)', hint: 'Who handled it, when, and where it is stored…', maxLines: 2),
        const SizedBox(height: 20.0),
        const VNotice(
          text: 'Manual entries are stamped with current server time. The date you enter is stored as metadata and is not cryptographically anchored to the timestamp.',
        ),
        const SizedBox(height: 20.0),
        VButton(
          label: 'Add to record',
          icon: Icons.edit_outlined,
          size: VButtonSize.lg,
          fullWidth: true,
          loading: _submitting,
          loadingLabel: 'Adding to record…',
          onPressed: _valid ? _submit : null,
        ),
        if (!_valid && !_submitting) ...[
          const SizedBox(height: 8.0),
          Text(
            _source.text.trim().isEmpty
                ? 'Enter who it came from to continue.'
                : _needsUpload
                    ? 'Choose at least one file to continue.'
                    : 'Describe the item to continue.',
            textAlign: TextAlign.center,
            style: VT.muted(context, size: 11.0),
          ),
        ],
      ],
    );
  }
}
