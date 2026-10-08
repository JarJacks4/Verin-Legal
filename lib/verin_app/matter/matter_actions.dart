// Matter header → "Record" menu: everything a firm does with a finished
// record, in one place.
//
//   Deliver the record      to Clio or as a download; Verin's copy of each
//                           finished file is removed once delivery is
//                           confirmed (checklist #16)
//   Standing Record (Word)  editable export (#69)
//   This week's digest      one page, written back to Clio when linked (#70)
//   Hearing / filing packet one per practice (#27, #71)
//   Import a closed matter  ZIP, mailbox or files, with the counts (#4)
//   Verify a file           does this file match an item exactly? (#16)
//   Delete demo material    NFR demo workspace only, with confirmation (#9)

import 'package:crypto/crypto.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_api.dart';

import '../data/evidence_upload.dart';
import '../data/format.dart';
import '../data/model.dart';
import '../onboarding/tour.dart' show DemoMode, TourTarget;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

class MatterActionsButton extends StatelessWidget {
  const MatterActionsButton({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final items = <(String, String, IconData)>[
      ('deliver', 'Deliver the record…', Icons.move_to_inbox_outlined),
      ('word', 'Standing Record (Word)', Icons.description_outlined),
      ('digest', "This week's digest", Icons.view_week_outlined),
      ('packet', 'Hearing / filing packet…', Icons.gavel_outlined),
      ('import', 'Import a closed matter…', Icons.unarchive_outlined),
      ('verify', 'Verify a file…', Icons.fingerprint),
      if (DemoMode.active) ('deleteDemo', 'Delete demo material…', Icons.delete_outline),
    ];
    return TourTarget(
      id: 'matter_actions',
      child: PopupMenuButton<String>(
        tooltip: 'Record actions',
        position: PopupMenuPosition.under,
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: c.border)),
        onSelected: (v) => _run(context, v),
        itemBuilder: (_) => [
          for (final (id, label, icon) in items)
            PopupMenuItem<String>(
              value: id,
              child: Row(
                children: [
                  Icon(icon, size: 16.0, color: id == 'deleteDemo' ? c.broken : c.mutedFg),
                  const SizedBox(width: 10.0),
                  Text(label, style: VT.body(context, size: 13.5, color: id == 'deleteDemo' ? c.broken : null)),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
          decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.pill), border: Border.all(color: c.border)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 14.0, color: c.tealDeep),
              const SizedBox(width: 6.0),
              Text('Record', style: VT.body(context, size: 12.5, weight: FontWeight.w600, color: c.tealDeep)),
              const SizedBox(width: 2.0),
              Icon(Icons.expand_more, size: 16.0, color: c.tealDeep),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, String id) async {
    switch (id) {
      case 'deliver':
        await showVDialog<void>(context, builder: (_) => _DeliverDialog(matter: matter));
      case 'word':
        await _download(context, 'Preparing the Word document…', () => VerinApi.exportStandingRecordDocx(matter.reference.id), 'Standing Record ready');
      case 'digest':
        await _download(
          context,
          matter.isClioLinked ? "Building this week's digest and adding it to Clio…" : "Building this week's digest…",
          () => VerinApi.buildMatterDigest(matter.reference.id, writeBack: matter.isClioLinked),
          'Digest ready',
        );
      case 'packet':
        await showVDrawer<void>(context, title: 'Hearing or filing packet', tour: 'practice_packet', builder: (_) => PracticePacketSheet(matter: matter));
      case 'import':
        await showVDrawer<void>(context, title: 'Import a closed matter', tour: 'closed_import', builder: (_) => ClosedMatterImportSheet(matter: matter));
      case 'verify':
        await showVDrawer<void>(context, title: 'Verify a file', tour: 'verify_file', builder: (_) => VerifyFileSheet(matter: matter, receipts: receipts));
      case 'deleteDemo':
        await showVDialog<void>(context, builder: (_) => _DeleteDemoDialog(matter: matter));
    }
  }
}

Future<void> _download(BuildContext context, String working, Future<Map<String, dynamic>> Function() call, String done) async {
  showVToast(context, working);
  try {
    final r = await call();
    final url = '${r['downloadUrl'] ?? ''}';
    if (!context.mounted) return;
    celebrate(context, title: done, subtitle: '${r['fileName'] ?? ''}');
    if (url.isNotEmpty) await launchURL(url);
  } catch (e) {
    if (context.mounted) showVToast(context, 'That did not finish', error: true, description: e is VerinApiException ? e.message : '$e');
  }
}

// ---------------------------------------------------------------------------
// Deliver
// ---------------------------------------------------------------------------

class _DeliverDialog extends StatefulWidget {
  const _DeliverDialog({required this.matter});

  final MattersRecord matter;

  @override
  State<_DeliverDialog> createState() => _DeliverDialogState();
}

class _DeliverDialogState extends State<_DeliverDialog> {
  String? _busy;
  Map<String, dynamic>? _download; // awaiting confirmation
  String? _error;

  Future<void> _go(String target) async {
    setState(() {
      _busy = target;
      _error = null;
    });
    try {
      final r = await VerinApi.deliverMatterRecord(widget.matter.reference.id, target: target);
      if (!mounted) return;
      if (target == 'download') {
        setState(() {
          _download = r;
          _busy = null;
        });
        final url = '${r['downloadUrl'] ?? ''}';
        if (url.isNotEmpty) await launchURL(url);
        return;
      }
      Navigator.of(context).pop();
      celebrate(
        context,
        title: 'Delivered to Clio',
        subtitle: '${r['items'] ?? 0} items · ${r['removed'] ?? 0} files removed from Verin',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = null;
          _error = e is VerinApiException ? e.message : '$e';
        });
      }
    }
  }

  Future<void> _confirm() async {
    final id = '${_download?['deliveryId'] ?? ''}';
    if (id.isEmpty) return;
    setState(() => _busy = 'confirm');
    try {
      final r = await VerinApi.confirmDelivery(widget.matter.reference.id, id);
      if (!mounted) return;
      Navigator.of(context).pop();
      celebrate(context, title: 'Delivery confirmed', subtitle: '${r['removed'] ?? 0} files removed from Verin; hashes and timestamps kept');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = null;
          _error = e is VerinApiException ? e.message : '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final linked = widget.matter.isClioLinked;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_download == null ? 'Deliver the record' : 'Saved it?', style: VT.h2(context, size: 18.0)),
        const SizedBox(height: 8.0),
        Text(
          _download == null
              ? "Verin packs every item exactly as received, with its certificate, manifest and a verify script, and delivers it to your firm's own system. "
                  "Once delivery is confirmed, Verin removes its copy of each finished file. Hashes, timestamps and the audit log stay, so any file can still be verified."
              : "The record is downloading (${_download!['fileName'] ?? 'ZIP'}). When it's saved in your firm's file system, confirm below and Verin removes its copy of the files.",
          style: VT.muted(context, size: 13.0),
        ),
        if (_error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: _error!)],
        const SizedBox(height: 18.0),
        if (_download == null) ...[
          VButton(
            label: linked ? 'Send to Clio' : 'Link this matter to Clio first',
            icon: Icons.upload_rounded,
            fullWidth: true,
            loading: _busy == 'clio',
            loadingLabel: 'Delivering…',
            onPressed: linked && _busy == null ? () => _go('clio') : null,
          ),
          const SizedBox(height: 8.0),
          VButton(
            label: 'Download the record',
            icon: Icons.download_outlined,
            kind: VButtonKind.secondary,
            fullWidth: true,
            loading: _busy == 'download',
            loadingLabel: 'Packing…',
            onPressed: _busy == null ? () => _go('download') : null,
          ),
        ] else ...[
          VButton(
            label: "It's saved — remove Verin's copy",
            icon: Icons.check_rounded,
            fullWidth: true,
            loading: _busy == 'confirm',
            onPressed: _busy == null ? _confirm : null,
          ),
          const SizedBox(height: 8.0),
          VButton(label: 'Download again', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => launchURL('${_download!['downloadUrl'] ?? ''}')),
        ],
        const SizedBox(height: 8.0),
        VButton(label: 'Not now', kind: VButtonKind.link, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Practice packets
// ---------------------------------------------------------------------------

const kPacketKinds = <(String, String, String)>[
  ('family_exhibit_packet', 'Family law — court exhibit packet', 'Bates-stamped production with index, from the Exhibits tab.'),
  ('pi_treatment_chronology', 'Personal injury — treatment chronology', 'Dated records, bills and photos: the demand support set.'),
  ('immigration_checklist', 'Immigration — checklist coverage', 'What the record holds for each common evidence category.'),
  ('civil_key_dates', 'Civil — key-date chronology', 'Dated items, hearings and items marked Key evidence.'),
  ('criminal_event_window', 'Criminal — event window report', 'Every message and item around an event, to the minute.'),
  ('criminal_mitigation', 'Criminal — mitigation packet', 'Marked documents and the team\'s notes, indexed.'),
];

/// The packet that fits a matter's practice area best.
String suggestedPacket(MattersRecord m) {
  final p = matterPractice(m).toLowerCase();
  if (p.contains('injury')) return 'pi_treatment_chronology';
  if (p.contains('immigra')) return 'immigration_checklist';
  if (p.contains('criminal')) return 'criminal_event_window';
  if (p.contains('civil')) return 'civil_key_dates';
  return 'family_exhibit_packet';
}

class PracticePacketSheet extends StatefulWidget {
  const PracticePacketSheet({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<PracticePacketSheet> createState() => _PracticePacketSheetState();
}

class _PracticePacketSheetState extends State<PracticePacketSheet> {
  late String _kind = suggestedPacket(widget.matter);
  final _when = TextEditingController();
  final _hours = TextEditingController(text: '24');
  final _label = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _when.dispose();
    _hours.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _make({bool confirmed = false}) async {
    if (_kind == 'family_exhibit_packet') {
      Navigator.of(context).pop();
      showVToast(context, 'Open the Exhibits tab', description: 'Family court packets are built there: choose items, review redactions, then Produce.');
      return;
    }
    DateTime? eventAt;
    if (_kind == 'criminal_event_window') {
      eventAt = DateTime.tryParse(_when.text.trim().replaceFirst(' ', 'T'));
      if (eventAt == null) {
        setState(() => _error = 'Enter the event as YYYY-MM-DD HH:MM, for example 2026-03-14 21:30.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await VerinApi.exportPracticePacket(
        matterId: widget.matter.reference.id,
        kind: _kind,
        redactionsConfirmed: confirmed,
        eventAt: eventAt,
        windowHours: int.tryParse(_hours.text.trim()),
        eventLabel: _label.text.trim().isEmpty ? null : _label.text.trim(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      celebrate(context, title: 'Packet ready', subtitle: '${r['fileName'] ?? ''}');
      await launchURL('${r['downloadUrl'] ?? ''}');
    } on VerinApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.code == 'failed-precondition' && e.message.contains('redaction')) {
        final ok = await showVDialog<bool>(
          context,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Confirm redactions', style: VT.h2(ctx, size: 18.0)),
              const SizedBox(height: 8.0),
              Text(e.message, style: VT.muted(ctx, size: 13.0)),
              const SizedBox(height: 18.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VButton(label: 'Review first', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
                  const SizedBox(width: 8.0),
                  VButton(label: 'Confirmed — export', onPressed: () => Navigator.of(ctx).pop(true)),
                ],
              ),
            ],
          ),
        );
        if (ok == true && mounted) await _make(confirmed: true);
      } else {
        setState(() => _error = e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('One packet per practice, built from the record. Flagged personal details are masked, and you confirm redactions before export.', style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 16.0),
        TourTarget(
          id: 'packet_kinds',
          child: Column(
            children: [
              for (final (id, label, hint) in kPacketKinds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: VHover(
                    onTap: () => setState(() => _kind = id),
                    builder: (context, hovered) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: _kind == id ? c.teal.withValues(alpha: 0.08) : (hovered ? c.secondary : c.card),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: _kind == id ? c.teal : c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(_kind == id ? Icons.radio_button_checked : Icons.radio_button_off, size: 18.0, color: _kind == id ? c.teal : c.mutedFg),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: VT.body(context, size: 13.5, weight: FontWeight.w600)),
                                Text(hint, style: VT.muted(context, size: 12.0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_kind == 'criminal_event_window') ...[
          const SizedBox(height: 8.0),
          VTextField(controller: _when, label: 'Event date and time', hint: '2026-03-14 21:30'),
          const SizedBox(height: 12.0),
          VTextField(controller: _hours, label: 'Hours either side', hint: '24', keyboardType: TextInputType.number),
          const SizedBox(height: 12.0),
          VTextField(controller: _label, label: 'What happened', hint: 'Alleged incident at the residence', optional: 'Optional'),
        ],
        if (_error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: _error!)],
        const SizedBox(height: 18.0),
        VButton(label: 'Build packet', icon: Icons.picture_as_pdf_outlined, fullWidth: true, loading: _busy, loadingLabel: 'Building…', onPressed: _busy ? null : () => _make()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Closed-matter import and counts
// ---------------------------------------------------------------------------

class ClosedMatterImportSheet extends StatefulWidget {
  const ClosedMatterImportSheet({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<ClosedMatterImportSheet> createState() => _ClosedMatterImportSheetState();
}

class _ClosedMatterImportSheetState extends State<ClosedMatterImportSheet> {
  bool _busy = false;
  String _status = '';
  double? _progress;
  String? _error;
  final Stopwatch _clock = Stopwatch();
  Map<String, dynamic>? _counts;
  int _filed = 0;

  Future<void> _pick() async {
    final res = await pickClosedMatterFiles();
    if (res.files.isEmpty) {
      if (res.skipped.isNotEmpty && mounted) showVToast(context, 'Some files were skipped', description: res.skipped.join('\n'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _counts = null;
    });
    _clock
      ..reset()
      ..start();
    try {
      for (final f in res.files) {
        final r = await uploadAndImportArchive(
          matterId: widget.matter.reference.id,
          file: f,
          onStatus: (s, p) {
            if (mounted) {
              setState(() {
                _status = s;
                _progress = p;
              });
            }
          },
        );
        _filed += r['filed'] ?? 0;
      }
      if (!mounted) return;
      setState(() => _status = 'Filed $_filed items. Verin is reading them now.');
      celebrate(context, title: 'Closed matter received', subtitle: '$_filed items hashed, chained and timestamped');
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = e is VerinApiException ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final c = await VerinApi.standingRecordCounts(widget.matter.reference.id);
      if (mounted) setState(() => _counts = c);
    } catch (e) {
      if (mounted) setState(() => _error = e is VerinApiException ? e.message : '$e');
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final k = _counts;
    int n(String key) => (k?[key] as num?)?.toInt() ?? 0;
    final elapsed = _clock.elapsed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Send everything from a closed matter at once: a ZIP of the folder, an email export (.mbox), single emails (.eml), or the files themselves. '
          'Each file becomes its own item — hashed, chained and timestamped — and is read like anything a client sends.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 16.0),
        TourTarget(
          id: 'import_pick',
          child: VButton(label: 'Choose files or a ZIP', icon: Icons.unarchive_outlined, fullWidth: true, loading: _busy, loadingLabel: 'Importing…', onPressed: _busy ? null : _pick),
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          Text(_status, style: VT.body(context, size: 13.0)),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.0),
            child: LinearProgressIndicator(value: _progress, minHeight: 6.0, backgroundColor: c.muted, valueColor: AlwaysStoppedAnimation<Color>(c.teal)),
          ),
          if (elapsed.inSeconds > 0) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text('${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s', style: VT.muted(context, size: 11.5))),
        ],
        if (_error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: _error!)],
        const SizedBox(height: 20.0),
        Row(
          children: [
            Expanded(child: Text('THE STANDING RECORD SO FAR', style: VT.eyebrow(context))),
            VButton(label: 'Refresh', icon: Icons.refresh, kind: VButtonKind.link, size: VButtonSize.sm, onPressed: _refresh),
          ],
        ),
        const SizedBox(height: 8.0),
        TourTarget(
          id: 'import_counts',
          child: Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              _CountTile(label: 'Items received', value: k == null ? '—' : '${n('itemsReceived')}'),
              _CountTile(label: 'Distinct dated items', value: k == null ? '—' : '${n('distinctDatedItems')}'),
              _CountTile(label: 'Conversations rebuilt', value: k == null ? '—' : '${n('conversationsRebuilt')}', note: k == null ? null : '${n('messagesRebuilt')} messages'),
              _CountTile(label: 'Items flagged', value: k == null ? '—' : '${n('itemsFlagged')}', note: 'for a person'),
            ],
          ),
        ),
        if (n('stillReading') > 0) ...[
          const SizedBox(height: 10.0),
          Text('${n('stillReading')} still being read — refresh in a minute.', style: VT.muted(context, size: 12.0)),
        ],
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: 200.0,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: VT.eyebrow(context, size: 10.5)),
          const SizedBox(height: 6.0),
          Text(value, style: VT.h1(context, size: 26.0)),
          if (note != null) Text(note!, style: VT.muted(context, size: 11.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verify a file
// ---------------------------------------------------------------------------

class VerifyFileSheet extends StatefulWidget {
  const VerifyFileSheet({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<VerifyFileSheet> createState() => _VerifyFileSheetState();
}

class _VerifyFileSheetState extends State<VerifyFileSheet> {
  String? _name;
  String? _hash;
  ReceiptsRecord? _match;
  bool _busy = false;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    final f = res?.files.firstOrNull;
    final bytes = f?.bytes;
    if (f == null || bytes == null) return;
    setState(() => _busy = true);
    // Hashing runs in the browser: the file never leaves this computer.
    final h = crypto.sha256.convert(bytes).toString();
    ReceiptsRecord? m;
    for (final r in widget.receipts) {
      if (r.itemHash == h) {
        m = r;
        break;
      }
    }
    setState(() {
      _name = f.name;
      _hash = h;
      _match = m;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final m = _match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Choose any copy of a file — from Clio, an email, a USB drive. Verin computes its SHA-256 fingerprint on this computer (the file isn't uploaded) "
          'and checks it against every item in this matter. A match means the bytes are identical to what Verin received.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 16.0),
        TourTarget(id: 'verify_pick', child: VButton(label: 'Choose a file', icon: Icons.fingerprint, fullWidth: true, loading: _busy, onPressed: _busy ? null : _pick)),
        if (_hash != null) ...[
          const SizedBox(height: 18.0),
          VCard(
            borderColor: m != null ? c.verified : c.pending,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(m != null ? Icons.verified_outlined : Icons.help_outline, color: m != null ? c.verified : c.pending, size: 20.0),
                    const SizedBox(width: 8.0),
                    Expanded(child: Text(m != null ? 'Matches an item exactly' : 'No item in this matter has these exact bytes', style: VT.body(context, weight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 10.0),
                Text(_name ?? '', style: VT.body(context, size: 13.0)),
                const SizedBox(height: 4.0),
                SelectableText(_hash!, style: VT.mono(context, size: 11.0, color: c.mutedFg)),
                if (m != null) ...[
                  const SizedBox(height: 10.0),
                  Text('${m.headline} · received ${fmtWhen(m.receivedAt)} · chain entry #${m.chainSeq}', style: VT.body(context, size: 13.0)),
                  if (m.tsaTime != null) Text('Independent timestamp: ${fmtWhen(m.tsaTime)} (${m.tsaName})', style: VT.muted(context, size: 12.0)),
                ] else ...[
                  const SizedBox(height: 10.0),
                  Text('A file that was edited, re-saved, resized or converted gets a different fingerprint, even if it looks the same.', style: VT.muted(context, size: 12.0)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Demo: delete a prospect's material
// ---------------------------------------------------------------------------

class _DeleteDemoDialog extends StatefulWidget {
  const _DeleteDemoDialog({required this.matter});

  final MattersRecord matter;

  @override
  State<_DeleteDemoDialog> createState() => _DeleteDemoDialogState();
}

class _DeleteDemoDialogState extends State<_DeleteDemoDialog> {
  final _prospect = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _confirmation;

  @override
  void dispose() {
    _prospect.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await VerinApi.deleteDemoMatter(widget.matter.reference.id, confirmTo: _email.text.trim(), prospect: _prospect.text.trim());
      if (!mounted) return;
      setState(() {
        _busy = false;
        _confirmation = '${r['confirmationText'] ?? ''}${r['emailed'] == true ? '\n\nEmailed to ${_email.text.trim()}.' : ''}';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is VerinApiException ? e.message : '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmation != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VSuccessState(title: 'Deleted', desc: 'Everything Verin held for this matter is gone. Copy the confirmation for the firm if it was not emailed.'),
          const SizedBox(height: 12.0),
          VPanel(child: SelectableText(_confirmation!, style: VT.body(context, size: 12.5))),
          const SizedBox(height: 14.0),
          VButton(
            label: 'Back to matters',
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed('MattersList');
            },
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Delete this demo material?', style: VT.h2(context, size: 18.0)),
        const SizedBox(height: 8.0),
        Text(
          "Deletes \"${widget.matter.title}\" and everything Verin holds for it: items, files, chain entries and notes. "
          'Verin keeps only a confirmation record with counts and times. This cannot be undone.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 14.0),
        VTextField(controller: _prospect, label: 'Firm', hint: 'Harbor Family Law', optional: 'Optional'),
        const SizedBox(height: 12.0),
        VTextField(controller: _email, label: 'Send the deletion confirmation to', hint: 'partner@firm.com', keyboardType: TextInputType.emailAddress, optional: 'Optional'),
        if (_error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: _error!)],
        const SizedBox(height: 18.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            VButton(label: 'Cancel', kind: VButtonKind.secondary, onPressed: _busy ? null : () => Navigator.of(context).pop()),
            const SizedBox(width: 8.0),
            VButton(label: 'Delete', icon: Icons.delete_outline, kind: VButtonKind.danger, loading: _busy, loadingLabel: 'Deleting…', onPressed: _busy ? null : _delete),
          ],
        ),
      ],
    );
  }
}
