// New matter drawer — port of the Make's <NewMatterDrawer>, writing the
// matter to Firestore and filing any initial evidence through ingestEvidence.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/verin_api.dart';
import '/verin/verin_config.dart';

import '../data/evidence_upload.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import '../widgets/upload_zone.dart';
import '../onboarding/tour.dart';

Future<MattersRecord?> showNewMatterDrawer(BuildContext context) =>
    showVDrawer<MattersRecord>(context, title: 'New matter', width: 500.0, builder: (_) => const NewMatterForm());

/// Practice areas offered when opening a matter. Verin is built for family
/// law, so its common matter types come first.
const kPracticeAreas = [
  'Family law',
  'Divorce',
  'Child custody',
  'Child support',
  'Protective / restraining order',
  'Domestic violence',
  'Adoption',
  'Guardianship',
  'Estate & probate',
  'Personal injury',
  'Employment',
  'Criminal defense',
  'Immigration',
  'Other',
];

class NewMatterForm extends StatefulWidget {
  const NewMatterForm({super.key});

  @override
  State<NewMatterForm> createState() => _NewMatterFormState();
}

class _NewMatterFormState extends State<NewMatterForm> {
  final _name = TextEditingController();
  final _client = TextEditingController();
  final _cause = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _status = 'Open';
  String _practiceArea = kPracticeAreas.first;
  bool _archive = false;
  final List<StagedFile> _staged = [];
  final Map<int, double> _progress = {};
  bool _submitting = false;
  bool _done = false;
  String? _error;
  String _doneMessage = '';

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _client, _cause]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    _cause.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty && _client.text.trim().isNotEmpty && _cause.text.trim().isNotEmpty;

  Future<void> _pick() async {
    final res = await pickEvidence();
    if (!mounted) return;
    setState(() => _staged.addAll(res.files));
    if (res.skipped.isNotEmpty) showVToast(context, 'Skipped: ${res.skipped.join(', ')}', error: true);
  }

  Future<void> _create() async {
    if (!_valid || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    try {
      final ref = MattersRecord.collection.doc();
      await ref.set({
        ...createMattersRecordData(
          firmID: currentFirmId(),
          matterName: _name.text.trim(),
          caseTitle: _name.text.trim(),
          clientName: _client.text.trim(),
          caseNumber: _cause.text.trim(),
          matterType: 'Family law',
          practiceArea: _practiceArea,
          status: _status,
          openedAt: getCurrentTimestamp,
          isArchiveBuild: _archive,
          hasChronologyShift: false,
        ),
        // Used to match the client's texts and recognise their email.
        if (_phone.text.trim().isNotEmpty) ...{'clientPhone': _phone.text.trim(), 'clientPhones': [_phone.text.trim()]},
        if (_email.text.trim().isNotEmpty) ...{'clientEmail': _email.text.trim().toLowerCase(), 'clientEmails': [_email.text.trim().toLowerCase()]},
      });

      final failures = <String>[];
      for (var i = 0; i < _staged.length; i++) {
        try {
          await uploadAndIngest(
            matterId: ref.id,
            file: _staged[i],
            channel: 'upload',
            fromLabel: 'Initial upload',
            description: _archive ? 'Archive Build — existing material' : '',
            onProgress: (p) {
              if (mounted) setState(() => _progress[i] = p);
            },
          );
        } catch (e) {
          failures.add('${_staged[i].name}: ${e is VerinApiException ? e.message : e}');
        }
      }
      final matter = await MattersRecord.getDocumentOnce(ref);
      final ok = _staged.length - failures.length;
      if (mounted) setState(() {
        _done = true;
        _doneMessage = _staged.isEmpty
            ? 'The matter is ready. Add evidence from its Intake channel tab.'
            : '$ok of ${_staged.length} file${_staged.length == 1 ? '' : 's'} hashed and added to the record.';
      });
      if (failures.isNotEmpty && mounted) {
        showVToast(context, 'Some files were not filed', error: true, description: failures.join('\n'));
      }
      await Future.delayed(const Duration(milliseconds: 1200));
      if (nav.mounted) nav.pop(matter);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'The matter could not be created: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    if (_done) return VSuccessState(title: 'Matter created', desc: _doneMessage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Creates a new matter with its own record and hash chain. Evidence you add is hashed and timestamped the moment it arrives.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 16.0)],
        VTextField(controller: _name, label: 'Matter name', hint: 'Smith v. Jones'),
        const SizedBox(height: 16.0),
        VTextField(controller: _client, label: 'Client name', hint: 'Jane Smith'),
        const SizedBox(height: 16.0),
        VTextField(controller: _cause, label: 'Cause number', hint: '49D08-2026-DR-XXXXXX'),
        const SizedBox(height: 16.0),
        TourTarget(
          id: 'nm_phone',
          child: VTextField(controller: _phone, label: 'Client mobile', optional: 'for texts', hint: '(317) 555-0142', keyboardType: TextInputType.phone),
        ),
        const SizedBox(height: 16.0),
        VTextField(controller: _email, label: 'Client email', optional: 'optional', hint: 'client@example.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16.0),
        VSelect<String>(
          label: 'Practice area',
          value: _practiceArea,
          items: kPracticeAreas,
          labelFor: (a) => a,
          onChanged: (a) => setState(() => _practiceArea = a),
        ),
        const SizedBox(height: 16.0),
        VSegmented<String>(
          label: 'Status',
          value: _status,
          options: const ['Open', 'Closed'],
          labelFor: (s) => s,
          onChanged: (s) => setState(() => _status = s),
        ),
        const SizedBox(height: 24.0),
        // Archive Build toggle
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: _archive ? c.teal.withValues(alpha: 0.07) : c.secondary,
            borderRadius: BorderRadius.circular(VR.xl),
            border: Border.all(color: _archive ? c.teal : c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VHover(
                onTap: () => setState(() => _archive = !_archive),
                builder: (context, _) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20.0,
                      height: 20.0,
                      margin: const EdgeInsets.only(top: 2.0),
                      decoration: BoxDecoration(
                        color: _archive ? c.teal : c.card,
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(color: _archive ? c.teal : c.border, width: 1.5),
                      ),
                      child: _archive ? Icon(Icons.check, size: 13.0, color: c.primaryFg) : null,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Archive Build', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                          const SizedBox(height: 2.0),
                          Text(
                            'This matter includes material that already exists — months or years of it — none of which came through a Verin intake address. We assemble it into a record after the fact.',
                            style: VT.muted(context, size: 12.0, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_archive) ...[
                const SizedBox(height: 12.0),
                const VHairline(),
                const SizedBox(height: 12.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 13.0, color: c.pending),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        "Archive Build items carry higher Record Lag by design — the gap between when material was created and when it entered the firm's file may span months. This is expected and reported accurately.",
                        style: VT.muted(context, size: 11.0, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        const VFieldLabel('Initial evidence upload', optional: 'optional'),
        const SizedBox(height: 2.0),
        if (_staged.isEmpty)
          UploadZone(title: 'Add photos, videos & documents', hint: 'JPG, PNG, HEIC, MP4, MOV, PDF, Word', onTap: _submitting ? () {} : _pick)
        else ...[
          StagedGrid(
            files: _staged,
            progress: _progress,
            onRemove: (i) {
              if (_submitting) return;
              setState(() => _staged.removeAt(i));
            },
            onAddMore: _submitting ? () {} : _pick,
          ),
          const SizedBox(height: 8.0),
          Text(
            '${_staged.length} file${_staged.length == 1 ? '' : 's'} staged · each will be SHA-256 hashed at intake',
            style: VT.muted(context, size: 11.0),
          ),
        ],
        const SizedBox(height: 24.0),
        const VInfoPanel(
          title: 'Intake channels',
          body: 'Each matter gets its own email address, and texts from the client\'s mobile are matched to it. Both appear on the Intake channel tab as soon as the matter is created.',
        ),
        const SizedBox(height: 24.0),
        TourTarget(
          id: 'nm_create',
          child: VButton(
          label: 'Create matter',
          icon: Icons.add,
          size: VButtonSize.lg,
          fullWidth: true,
          loading: _submitting,
          loadingLabel: _staged.isEmpty ? 'Creating…' : 'Creating and filing evidence…',
          onPressed: _valid ? _create : null,
          ),
        ),
      ],
    );
  }
}
