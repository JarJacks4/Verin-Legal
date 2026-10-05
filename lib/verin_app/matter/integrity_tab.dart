// Integrity tab — port of the Make's <IntegrityTab>, <CertificateDrawer> and
// <StandaloneVerifyDrawer>, backed by the chainEntries collection and the
// export / verify Cloud Functions.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_api.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

String anchorLabel(DateTime? d) {
  if (d == null) return 'Not anchored yet';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  // 12-hour clock with the UTC offset: a timestamp in a legal record should
  // never leave the reader guessing which time zone it is in.
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final off = d.timeZoneOffset;
  final offH = off.inHours.abs();
  final offM = off.inMinutes.abs() % 60;
  final tz = off == Duration.zero ? 'UTC' : 'UTC${off.isNegative ? '−' : '+'}$offH${offM == 0 ? '' : ':${offM.toString().padLeft(2, '0')}'}';
  final hm = '$h12:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'} ($tz)';
  if (day == today) return 'Today, $hm';
  if (today.difference(day).inDays == 1) return 'Yesterday, $hm';
  return '${fmtDay(d)}, $hm';
}

DateTime? lastAnchor(MattersRecord m) => m.rfc3161LastTimestampedAt ?? m.hashChainLastAnchoredAt;

class IntegrityTab extends StatefulWidget {
  const IntegrityTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<IntegrityTab> createState() => _IntegrityTabState();
}

class _IntegrityTabState extends State<IntegrityTab> {
  Stream<List<ChainEntriesRecord>>? _chain;
  String? _chainFor;

  Stream<List<ChainEntriesRecord>> _chainStream() {
    if (_chain == null || _chainFor != widget.matter.reference.path) {
      _chainFor = widget.matter.reference.path;
      _chain = queryChainEntriesRecord(
        queryBuilder: (q) => q
            .where('matterID', isEqualTo: widget.matter.reference)
            .where('firmID', isEqualTo: currentFirmId())
            .orderBy('seq', descending: true),
        limit: 200,
      ).map((l) => l.reversed.toList());
    }
    return _chain!;
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final m = widget.matter;
    final status = chainStatusOf(m);
    final processed = widget.receipts.where((r) => itemStateOf(r) == VItemState.processed && !r.isDuplicate).length;
    final lags = recordLagsDays(widget.receipts.where((r) => !r.isDuplicate));
    final med = medianDays(lags);

    final stats = <Widget>[
      VStat(
        icon: Icons.verified_user_outlined,
        label: 'Chain status',
        value: switch (status) {
          VChainStatus.verified => 'Verified',
          VChainStatus.needsReview => 'Needs review',
          VChainStatus.notStarted => 'Not started',
        },
        tone: switch (status) {
          VChainStatus.verified => VTone.verified,
          VChainStatus.needsReview => VTone.pending,
          VChainStatus.notStarted => VTone.muted,
        },
      ),
      VStat(icon: Icons.anchor, label: 'Last external anchor', value: anchorLabel(lastAnchor(m)), tone: VTone.muted),
      med == null
          ? const VStat(icon: Icons.schedule, label: 'Record Lag', value: 'Insufficient data', tone: VTone.muted)
          : VStat(
              icon: Icons.schedule,
              label: 'Record Lag (median)',
              value: '$med days',
              tone: med > 180 ? VTone.broken : (med > 30 ? VTone.pending : VTone.verified),
            ),
      VStat(icon: Icons.description_outlined, label: 'The Standing Record', value: '$processed item${processed == 1 ? '' : 's'} built', tone: VTone.muted),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Integrity at receipt', style: VT.h2(context, size: 20.0)),
        const SizedBox(height: 4.0),
        Text(
          'A third party holding only an exported file and its manifest can verify the hash and the timestamp without any access to Verin.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        LayoutBuilder(builder: (context, box) {
          final two = box.maxWidth >= 560.0;
          if (!two) return Column(children: [for (final s in stats) Padding(padding: const EdgeInsets.only(bottom: 12.0), child: s)]);
          return Column(
            children: [
              Row(children: [Expanded(child: stats[0]), const SizedBox(width: 12.0), Expanded(child: stats[1])]),
              const SizedBox(height: 12.0),
              Row(children: [Expanded(child: stats[2]), const SizedBox(width: 12.0), Expanded(child: stats[3])]),
            ],
          );
        }),
        const SizedBox(height: 24.0),
        VCard(
          child: StreamBuilder<List<ChainEntriesRecord>>(
            stream: _chainStream(),
            builder: (context, snap) {
              final entries = snap.data ?? const <ChainEntriesRecord>[];
              final head = m.chainHeadHash.isNotEmpty ? m.chainHeadHash : (entries.isNotEmpty ? entries.last.entryHash : '');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('PER-MATTER HASH CHAIN', style: VT.eyebrow(context)),
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.lg)),
                    child: Text('entry = SHA256( prev_hash ‖ item_hash ‖ received_at ‖ origin_digest )', style: VT.mono(context, size: 12.0)),
                  ),
                  const SizedBox(height: 12.0),
                  if (snap.hasError)
                    Text(
                      '${snap.error}'.contains('index')
                          ? 'The chain needs a Firestore index. Deploy firebase/firestore.indexes.json.'
                          : 'The chain could not be loaded: ${snap.error}',
                      style: VT.body(context, size: 12.0, color: c.broken),
                    )
                  else if (!snap.hasData)
                    const VLoading(padding: 12.0)
                  else if (entries.isEmpty)
                    Text('No chain entries yet. The first item added to this matter becomes the chain root.', style: VT.muted(context, size: 12.0))
                  else
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 13.0, color: c.teal),
                            const SizedBox(width: 8.0),
                            Text('#${e.seq}', style: VT.muted(context, size: 11.0)),
                            const SizedBox(width: 8.0),
                            Expanded(child: Text(e.entryHash, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.mono(context, size: 11.0))),
                          ],
                        ),
                      ),
                  const SizedBox(height: 4.0),
                  const VHairline(),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Text('Chain head', style: VT.muted(context, size: 12.0)),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: SelectableText(head.isEmpty ? '—' : head, maxLines: 1, style: VT.mono(context, size: 12.0)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16.0),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            VButton(
              label: 'Certificate of preparation',
              icon: Icons.file_download_outlined,
              onPressed: () => showVDrawer<void>(
                context,
                title: 'Certificate of preparation',
                width: 560.0,
                builder: (_) => CertificateView(matter: m, receipts: widget.receipts),
              ),
            ),
            VButton(
              label: 'Standalone verify tool',
              icon: Icons.verified_user_outlined,
              kind: VButtonKind.secondary,
              onPressed: () => showVDrawer<void>(
                context,
                title: 'Standalone verify tool',
                width: 520.0,
                builder: (_) => VerifyView(matter: m, receipts: widget.receipts),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        Text(
          'Verin does not practice law. No opinion on authenticity, completeness, or admissibility is offered or implied — those determinations belong to counsel and the Court.',
          style: VT.muted(context, size: 11.0),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Certificate of preparation
// ---------------------------------------------------------------------------

class CertificateView extends StatefulWidget {
  const CertificateView({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<CertificateView> {
  bool _downloading = false;
  late final Stream<FirmAccountRecord?> _firm = firmAccountStream();

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final r = await VerinApi.exportMatterRecord(widget.matter.reference.id);
      final url = '${r['downloadUrl'] ?? ''}';
      if (url.isNotEmpty) await launchURL(url);
      if (mounted) showVToast(context, 'Record PDF ready', description: 'SHA-256 ${'${r['sha256'] ?? ''}'.padRight(12).substring(0, 12)}…');
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final m = widget.matter;
    final user = VUser.current();
    final items = widget.receipts.where((r) => !r.isDuplicate).toList();
    final processed = items.where((r) => itemStateOf(r) == VItemState.processed).length;
    final dates = items.map((r) => r.receivedAt).whereType<DateTime>().toList()..sort();
    final range = dates.isEmpty ? 'No receipts' : '${fmtDay(dates.first)} – ${fmtDay(dates.last)}';
    final today = fmtLongDay(DateTime.now());
    final head = m.chainHeadHash.isEmpty ? '—' : m.chainHeadHash;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 96.0, child: Text(label, style: VT.muted(context, size: 12.0))),
              const SizedBox(width: 12.0),
              Expanded(child: Text(value.isEmpty ? '—' : value, style: VT.body(context, size: 12.0, weight: FontWeight.w500))),
            ],
          ),
        );

    return StreamBuilder<FirmAccountRecord?>(
      stream: _firm,
      builder: (context, fs) {
        final firm = (fs.data?.firmName.isNotEmpty ?? false) ? fs.data!.firmName : user.firm;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Preview of the certificate to be exported with this matter's record. This document accompanies the exhibit set.",
              style: VT.muted(context),
            ),
            const SizedBox(height: 24.0),
            VCard(
              padding: const EdgeInsets.all(28.0),
              borderWidth: 2.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VERIN EVIDENCE RECORD', style: VT.eyebrow(context, size: 11.0, color: c.teal, spacing: 0.14)),
                              const SizedBox(height: 2.0),
                              Text('Prepared with Verin', style: VT.muted(context, size: 11.0)),
                            ],
                          ),
                        ),
                        VIconCircle(icon: Icons.verified_user_outlined, size: 32.0, iconSize: 16.0, bg: c.tealPale),
                      ],
                    ),
                  ),
                  Text('CERTIFICATE OF PREPARATION', textAlign: TextAlign.center, style: VT.h2(context, size: 18.0).copyWith(letterSpacing: 0.7)),
                  const SizedBox(height: 4.0),
                  Text('Prepared at the direction of counsel', textAlign: TextAlign.center, style: VT.muted(context, size: 12.0)),
                  const SizedBox(height: 4.0),
                  Text(
                    'The Standing Record — $processed item${processed == 1 ? '' : 's'} read, dated, deduplicated, and threaded',
                    textAlign: TextAlign.center,
                    style: VT.body(context, size: 11.0, color: c.tealDeep).copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24.0),
                  row('Firm', firm),
                  row('Prepared by', [user.name, user.role].where((s) => s.isNotEmpty).join(', ')),
                  row('Matter', m.title),
                  row('Client', m.clientName),
                  row('Cause no.', m.caseNumber),
                  row('Date prepared', today),
                  row('Items in record', '${items.length} receipt${items.length == 1 ? '' : 's'}'),
                  row('Date range', range),
                  const SizedBox(height: 14.0),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: c.border))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SHA-256 chain head at export', style: VT.muted(context, size: 11.0)),
                        const SizedBox(height: 8.0),
                        VHashBlock(value: head),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'I certify that the attached evidence record was prepared under the supervision of counsel, that each item was hashed upon receipt before review, and that the hash chain above represents the unmodified sequence of items as received. This certificate does not constitute a legal opinion on authenticity, completeness, or admissibility.',
                    style: VT.muted(context, size: 11.0, height: 1.6),
                  ),
                  const SizedBox(height: 24.0),
                  const VHairline(),
                  const SizedBox(height: 16.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 128.0, height: 1.0, color: c.border),
                            const SizedBox(height: 4.0),
                            Text(user.name.isEmpty ? '—' : user.name, style: VT.muted(context, size: 11.0)),
                            Text(today, style: VT.muted(context, size: 10.0)),
                          ],
                        ),
                      ),
                      if (chainStatusOf(m) == VChainStatus.verified)
                        VStatusInline(label: 'Chain verified', icon: Icons.verified_user_outlined, color: c.verified, size: 11.0),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Download PDF',
                    icon: Icons.file_download_outlined,
                    fullWidth: true,
                    loading: _downloading,
                    loadingLabel: 'Generating PDF…',
                    onPressed: _download,
                  ),
                ),
                const SizedBox(width: 12.0),
                VButton(label: 'Close', kind: VButtonKind.secondary, onPressed: () => Navigator.of(context).maybePop()),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Standalone verify tool
// ---------------------------------------------------------------------------

class VerifyView extends StatefulWidget {
  const VerifyView({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<VerifyView> createState() => _VerifyViewState();
}

class _VerifyViewState extends State<VerifyView> {
  String _zip = 'idle'; // idle | building | ready
  String? _zipUrl;
  bool _verifying = false;
  Map<String, dynamic>? _result;
  String? _verifyError;

  Future<void> _export() async {
    setState(() => _zip = 'building');
    try {
      final r = await VerinApi.exportRecordZip(widget.matter.reference.id);
      final url = '${r['downloadUrl'] ?? ''}';
      _zipUrl = url;
      if (url.isNotEmpty) await launchURL(url);
      if (mounted) setState(() => _zip = 'ready');
    } on VerinApiException catch (e) {
      if (mounted) {
        setState(() => _zip = 'idle');
        showVToast(context, e.message, error: true);
      }
    }
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _verifyError = null;
    });
    try {
      final r = await VerinApi.verifyMatterChain(widget.matter.reference.id);
      if (mounted) setState(() => _result = r);
    } on VerinApiException catch (e) {
      if (mounted) setState(() => _verifyError = e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final m = widget.matter;
    final processed = widget.receipts.where((r) => itemStateOf(r) == VItemState.processed && !r.isDuplicate).length;
    const steps = [
      ('Export the record', "Export this matter's record as a ZIP below. The ZIP contains the exhibit files exactly as received and a JSON manifest."),
      ('Run the verifier', 'The ZIP includes verify.py — a single Python 3 script with no dependencies. Anyone can read it and run it.'),
      ('Pass the manifest', 'The verifier reads the manifest, recomputes every SHA-256 over the exhibit files, and recomputes the hash chain entry by entry.'),
      ('Read the result', 'A pass means every item is intact and the chain is unbroken. A failure names the first broken link and the item involved.'),
    ];
    final ok = _result?['ok'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Anyone holding an exported evidence record can verify its integrity without logging into Verin — no account, no access required.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.0,
                  height: 28.0,
                  margin: const EdgeInsets.only(top: 2.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.tealPale, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: VT.body(context, size: 12.0, weight: FontWeight.w700, color: c.tealDeep)),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].$1, style: VT.body(context, weight: FontWeight.w600)),
                      const SizedBox(height: 2.0),
                      Text(steps[i].$2, style: VT.muted(context, size: 13.0, height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        VPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chain head for this matter', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: c.tealDeep)),
              const SizedBox(height: 8.0),
              VHashBlock(value: m.chainHeadHash),
              const SizedBox(height: 8.0),
              Text(
                'This hash is embedded in the Certificate of Preparation and the manifest. The verifier checks the recomputed chain head against this value.',
                style: VT.muted(context, size: 11.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.xl)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ARCHIVE CONTENTS', style: VT.eyebrow(context, size: 11.0, color: c.mutedFg, spacing: 0.07)),
              const SizedBox(height: 8.0),
              for (final f in [
                ('manifest.json', 'Hash chain + receipt metadata'),
                ('exhibits/ ($processed files)', 'Evidence files as received'),
                ('certificate.pdf', 'Certificate of Preparation'),
                ('verify.py', 'Standalone verifier (Python 3)'),
                ('README.txt', 'Verification instructions'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$1, style: VT.mono(context, size: 11.0, color: c.tealDeep)),
                      const SizedBox(width: 12.0),
                      Expanded(child: Text(f.$2, style: VT.muted(context, size: 11.0))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        if (_zip == 'ready') ...[
          const VNotice(text: 'Record ZIP downloaded — keep it with the certificate.', tone: VNoticeTone.verified),
          const SizedBox(height: 16.0),
        ],
        if (_result != null) ...[
          VNotice(
            tone: ok ? VNoticeTone.verified : VNoticeTone.broken,
            text: ok
                ? 'Chain recomputed on the server: ${_result!['verifiedEntries'] ?? 0} entr${(_result!['verifiedEntries'] ?? 0) == 1 ? 'y' : 'ies'} intact${(_result!['legacyEntries'] ?? 0) is num && (_result!['legacyEntries'] as num) > 0 ? ' (${_result!['legacyEntries']} earlier demo entries carry no inputs and were skipped)' : ''}.'
                : 'Chain check failed at entry #${_result!['brokenAt'] ?? '?'}: ${_result!['reason'] ?? 'unknown reason'}.',
          ),
          const SizedBox(height: 16.0),
        ],
        if (_verifyError != null) ...[VErrorBox(message: _verifyError!), const SizedBox(height: 16.0)],
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            VButton(
              label: _zip == 'ready' ? 'Download again' : 'Export record ZIP',
              icon: Icons.file_download_outlined,
              size: VButtonSize.sm,
              loading: _zip == 'building',
              loadingLabel: 'Building archive…',
              onPressed: () {
                if (_zip == 'ready' && (_zipUrl ?? '').isNotEmpty) {
                  launchURL(_zipUrl!);
                } else {
                  _export();
                }
              },
            ),
            VButton(
              label: 'Verify chain now',
              icon: Icons.verified_user_outlined,
              kind: VButtonKind.secondary,
              size: VButtonSize.sm,
              loading: _verifying,
              loadingLabel: 'Checking…',
              onPressed: _verify,
            ),
          ],
        ),
      ],
    );
  }
}
