// Practice management tab — the Make's <PracticeManagementTab> layout with
// the real Clio integration (OAuth connect, matter link, document push, sync
// log). PracticePanther and Filevine have their own cards (practice_systems.dart);
// MyCase and Smokeball are shown as coming soon.

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
import '../widgets/badges.dart';
import '../widgets/drawer.dart';
import '../onboarding/tour.dart' show DemoMode;
import 'demo_practice.dart';
import 'practice_systems.dart';

/// Revokes Verin's current Clio grant, then starts a fresh sign-in so Clio
/// issues a token with the app's current permissions.
Future<void> reconnectClio(BuildContext context) async {
  try {
    await VerinApi.clioDisconnect();
  } on VerinApiException catch (e) {
    if (context.mounted) showVToast(context, e.message, error: true);
    return;
  }
  if (context.mounted) await connectClio(context);
}

Future<void> disconnectClio(BuildContext context) async {
  final ok = await showVDialog<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Disconnect Clio?', style: VT.body(ctx, size: 16.0, weight: FontWeight.w600)),
        const SizedBox(height: 8.0),
        Text('Verin stops pushing to Clio for the whole firm. Matter links are kept, so reconnecting picks up where you left off.',
            style: VT.muted(ctx, size: 13.0)),
        const SizedBox(height: 20.0),
        Row(
          children: [
            Expanded(child: VButton(label: 'Cancel', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => Navigator.of(ctx).pop(false))),
            const SizedBox(width: 12.0),
            Expanded(child: VButton(label: 'Disconnect', kind: VButtonKind.danger, fullWidth: true, onPressed: () => Navigator.of(ctx).pop(true))),
          ],
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await VerinApi.clioDisconnect();
    if (context.mounted) showVToast(context, 'Clio disconnected');
  } on VerinApiException catch (e) {
    if (context.mounted) showVToast(context, e.message, error: true);
  }
}

Future<void> connectClio(BuildContext context) async {
  try {
    final url = await VerinApi.clioAuthStart();
    await launchURL(url);
    if (context.mounted) {
      showVToast(context, "Finish signing in to Clio in the new tab", description: "This page updates by itself once you're connected.");
    }
  } on VerinApiException catch (e) {
    if (context.mounted) showVToast(context, e.message, error: true);
  }
}

Stream<List<ClioSyncLogRecord>> clioLogStream(DocumentReference matterRef) => queryClioSyncLogRecord(
      queryBuilder: (q) => q.where('matterID', isEqualTo: matterRef).where('firmID', isEqualTo: currentFirmId()).orderBy('pushedAt', descending: true),
      limit: 20,
    );

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key, required this.matter, required this.receipts, required this.firmConnected, required this.firmStatus});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final bool firmConnected;
  final Map<String, dynamic> firmStatus;

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  bool _busy = false;
  bool _moreSystems = false;
  Stream<List<ClioSyncLogRecord>>? _log;
  String? _logFor;

  Stream<List<ClioSyncLogRecord>> _logStream() {
    if (_log == null || _logFor != widget.matter.reference.path) {
      _logFor = widget.matter.reference.path;
      _log = clioLogStream(widget.matter.reference);
    }
    return _log!;
  }

  Future<void> _push() async {
    setState(() => _busy = true);
    try {
      final export = await VerinApi.exportMatterRecord(widget.matter.reference.id);
      final path = '${export['storagePath'] ?? ''}';
      if (path.isEmpty) throw VerinApiException('The record export did not return a file.');
      await VerinApi.clioPushDocument(
        matterId: widget.matter.reference.id,
        storagePath: path,
        documentName: '${export['fileName'] ?? ''}'.isEmpty ? null : '${export['fileName']}',
      );
      if (mounted) showVToast(context, 'Record uploaded to Clio');
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, 'Push to Clio failed', error: true, description: e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simulated in a demo workspace, unless it is connected to a real Clio sandbox (#6).
    if (DemoMode.active && widget.firmStatus['demo'] != false) return DemoPracticeTab(matter: widget.matter);
    final c = VC.of(context);
    final m = widget.matter;
    bool inUse(PracticeSystemInfo x) =>
        widget.firmStatus['${x.id}Connected'] == true || '${practiceLinkOf(m, x.id)['id'] ?? ''}'.isNotEmpty;
    final connectedSystems = kPracticeSystems.where(inUse).toList();
    final otherSystems = kPracticeSystems.where((x) => !inUse(x)).toList();
    final clio = clioStateOf(m, firmConnected: widget.firmConnected);
    final clioUser = '${widget.firmStatus['clioUserName'] ?? ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Practice management', style: VT.h2(context, size: 20.0))),
            const SizedBox(width: 16.0),
            VButton(
              label: 'Integration report',
              icon: Icons.file_download_outlined,
              kind: VButtonKind.tonal,
              size: VButtonSize.sm,
              onPressed: () => showVDrawer<void>(
                context,
                title: 'Integration report',
                width: 620.0,
                builder: (_) => IntegrationReportView(matter: m, receipts: widget.receipts, clioState: clio),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Finished records and exhibit sets appear inside your practice management system — the firm gets the benefit without anyone logging into Verin.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),

        // Clio
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const VIconCircle(icon: Icons.apartment_outlined, size: 36.0, iconSize: 18.0, square: true),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Clio Manage', style: VT.body(context, weight: FontWeight.w600)),
                        Text(
                          !widget.firmConnected
                              ? 'Not connected'
                              : m.isClioLinked
                                  ? 'Matched to ${m.clioMatterDisplayNumber.isNotEmpty ? m.clioMatterDisplayNumber : m.clioMatterRef}'
                                  : 'Connected${clioUser.isNotEmpty ? ' as $clioUser' : ''} · not matched',
                          style: VT.muted(context, size: 12.0),
                        ),
                      ],
                    ),
                  ),
                  ClioBadge(state: clio),
                ],
              ),
              if (widget.firmConnected) ...[
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 4.0,
                  children: [
                    VButton(label: 'Reconnect Clio', icon: Icons.refresh, kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => reconnectClio(context)),
                    VButton(label: 'Disconnect', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => disconnectClio(context)),
                  ],
                ),
              ],
              const SizedBox(height: 16.0),
              if (!widget.firmConnected) ...[
                Text(
                  "Connect your firm's Clio account once, then match each Verin matter to its Clio matter. Pushed records land in that matter's Documents.",
                  style: VT.muted(context, size: 13.0),
                ),
                const SizedBox(height: 12.0),
                Align(alignment: Alignment.centerLeft, child: VButton(label: 'Connect Clio', icon: Icons.open_in_new, onPressed: () => connectClio(context))),
              ] else if (!m.isClioLinked) ...[
                Text('Pick the Clio matter this record belongs to.', style: VT.muted(context, size: 13.0)),
                const SizedBox(height: 12.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VButton(
                    label: 'Match to a Clio matter',
                    icon: Icons.search,
                    onPressed: () => showVDrawer<void>(context, title: 'Match to a Clio matter', width: 500.0, builder: (_) => ClioLinkView(matter: m)),
                  ),
                ),
              ] else ...[
                _SyncLines(synced: clio == VClioState.synced),
                const SizedBox(height: 16.0),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    VButton(
                      label: clio == VClioState.synced ? 'Push latest record' : 'Push to Clio',
                      icon: Icons.apartment_outlined,
                      loading: _busy,
                      loadingLabel: 'Pushing to Clio…',
                      onPressed: _push,
                    ),
                    if (m.clioMatterUrl.isNotEmpty)
                      VButton(label: 'View in Clio', icon: Icons.open_in_new, kind: VButtonKind.tonal, onPressed: () => launchURL(m.clioMatterUrl)),
                    VButton(
                      label: 'Change match',
                      kind: VButtonKind.link,
                      size: VButtonSize.sm,
                      onPressed: () => showVDrawer<void>(context, title: 'Match to a Clio matter', width: 500.0, builder: (_) => ClioLinkView(matter: m)),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                StreamBuilder<List<ClioSyncLogRecord>>(
                  stream: _logStream(),
                  builder: (context, snap) {
                    final rows = snap.data ?? const <ClioSyncLogRecord>[];
                    if (snap.hasError) return Text('Sync log unavailable: ${snap.error}', style: VT.body(context, size: 12.0, color: c.broken));
                    if (rows.isEmpty) return const SizedBox.shrink();
                    return VPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SYNC LOG', style: VT.eyebrow(context, size: 11.0)),
                          const SizedBox(height: 8.0),
                          for (final r in rows)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    r.status == 'Synced' ? Icons.check_circle_outline : Icons.error_outline,
                                    size: 15.0,
                                    color: r.status == 'Synced' ? c.verified : c.broken,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.documentName.isEmpty ? '—' : r.documentName, style: VT.body(context, size: 12.0)),
                                        if (r.status != 'Synced' && r.error.isNotEmpty) Text(r.error, style: VT.body(context, size: 11.0, color: c.broken)),
                                      ],
                                    ),
                                  ),
                                  Text(fmtWhen(r.pushedAt), style: VT.muted(context, size: 11.0)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        // Systems this firm already uses come first; the rest fold away so the
        // tab isn't a wall of cards that don't apply.
        for (final sys in connectedSystems) ...[
          const SizedBox(height: 16.0),
          PracticeSystemCard(system: sys, matter: m, firmStatus: widget.firmStatus, isAdmin: VUser.current().isAdmin),
        ],
        const SizedBox(height: 12.0),
        VHover(
          onTap: () => setState(() => _moreSystems = !_moreSystems),
          builder: (context, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Icon(_moreSystems ? Icons.expand_less : Icons.expand_more, size: 18.0, color: c.mutedFg),
                const SizedBox(width: 6.0),
                Text(_moreSystems ? 'Hide other systems' : 'More systems', style: VT.body(context, size: 13.0, weight: FontWeight.w500, color: c.mutedFg)),
              ],
            ),
          ),
        ),
        if (_moreSystems) ...[
          for (final sys in otherSystems) ...[
            const SizedBox(height: 12.0),
            PracticeSystemCard(system: sys, matter: m, firmStatus: widget.firmStatus, isAdmin: VUser.current().isAdmin),
          ],
          const SizedBox(height: 12.0),
          const _ComingSoonCard(name: 'MyCase', icon: Icons.work_outline, note: 'MyCase write-back needs partner API approval from MyCase. It will appear here once approved. It needs the MyCase Advanced plan or above; firms on lower MyCase plans can still export records and upload them by hand.'),
          const SizedBox(height: 12.0),
          const _ComingSoonCard(name: 'Smokeball', icon: Icons.bolt_outlined, note: 'Smokeball write-back is planned after Clio.'),
        ],
        const SizedBox(height: 20.0),
        Text(
          'Each push uploads a newly generated record; earlier uploads stay in Clio. Any failure is surfaced here — a write-back that fails silently is a trust incident, not a bug.',
          style: VT.muted(context, size: 11.0),
        ),
      ],
    );
  }
}

class _SyncLines extends StatelessWidget {
  const _SyncLines({required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    Widget line(String label) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(synced ? Icons.check_circle_outline : Icons.schedule, size: 15.0, color: synced ? c.verified : c.pending),
              const SizedBox(width: 8.0),
              Expanded(child: Text(label, style: VT.body(context, size: 13.0))),
              Text(synced ? 'synced' : 'pending', style: VT.muted(context, size: 12.0)),
            ],
          ),
        );
    return Column(children: [line('Record document'), line('Certificate of preparation')]);
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.name, required this.icon, required this.note});

  final String name;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VIconCircle(icon: icon, size: 36.0, iconSize: 18.0, square: true),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: VT.body(context, weight: FontWeight.w600)),
                    Text('Not connected', style: VT.muted(context, size: 12.0)),
                  ],
                ),
              ),
              IntgBadge(state: VIntgState.comingSoon, name: name),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(note, style: VT.muted(context, size: 13.0)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clio matter match
// ---------------------------------------------------------------------------

class ClioLinkView extends StatefulWidget {
  const ClioLinkView({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<ClioLinkView> createState() => _ClioLinkViewState();
}

class _ClioLinkViewState extends State<ClioLinkView> {
  late final TextEditingController _q =
      TextEditingController(text: widget.matter.clientName.isNotEmpty ? widget.matter.clientName : widget.matter.title);
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String? _linking;
  String? _error;

  @override
  void initState() {
    super.initState();
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

  Future<void> _link(String id) async {
    setState(() => _linking = id);
    try {
      await VerinApi.clioLinkMatter(matterId: widget.matter.reference.id, clioMatterId: id);
      if (!mounted) return;
      showVToast(context, 'Matched to Clio');
      Navigator.of(context).maybePop();
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _linking = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final current = widget.matter.clioMatterRef;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Search your firm's Clio matters by client, matter number or description.", style: VT.muted(context)),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _q,
                onSubmitted: (_) => _search(),
                style: VT.body(context),
                decoration: vInputDecoration(context, hint: 'e.g. Whitmore', prefix: Icon(Icons.search, size: 16.0, color: c.mutedFg)),
              ),
            ),
            const SizedBox(width: 10.0),
            VButton(label: 'Search', loading: _searching, onPressed: _search),
          ],
        ),
        const SizedBox(height: 16.0),
        if (_error != null)
          VErrorBox(message: _error!)
        else if (_searching && _results.isEmpty)
          const VLoading()
        else if (_results.isEmpty)
          Text('No Clio matters found.', style: VT.muted(context, size: 13.0))
        else
          for (final r in _results)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r['displayNumber'] ?? ''}  ${r['description'] ?? ''}'.trim(), style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                        Text(
                          [
                            if ('${r['clientName'] ?? ''}'.isNotEmpty) '${r['clientName']}',
                            if ('${r['status'] ?? ''}'.isNotEmpty) '${r['status']}',
                          ].join(' · '),
                          style: VT.muted(context, size: 12.0),
                        ),
                      ],
                    ),
                  ),
                  if ('${r['id'] ?? ''}' == current)
                    VBadge(label: 'Matched', icon: Icons.check_circle_outline, bg: c.verifiedBg, fg: c.verified)
                  else
                    VButton(
                      label: 'Match',
                      size: VButtonSize.sm,
                      loading: _linking == '${r['id'] ?? ''}',
                      onPressed: _linking != null ? null : () => _link('${r['id'] ?? ''}'),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Integration report
// ---------------------------------------------------------------------------

class IntegrationReportView extends StatefulWidget {
  const IntegrationReportView({super.key, required this.matter, required this.receipts, required this.clioState});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final VClioState clioState;

  @override
  State<IntegrationReportView> createState() => _IntegrationReportViewState();
}

class _IntegrationReportViewState extends State<IntegrationReportView> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final r = await VerinApi.exportIntegrationReport(widget.matter.reference.id);
      final url = '${r['downloadUrl'] ?? ''}';
      if (url.isNotEmpty) await launchURL(url);
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
    final now = DateTime.now();
    final items = widget.receipts.where((r) => !r.isDuplicate).toList();
    final processed = items.where((r) => itemStateOf(r) == VItemState.processed).toList();
    final synced = widget.clioState == VClioState.synced;
    String h(String s) => s.isEmpty ? '—' : (s.length > 18 ? '${s.substring(0, 18)}…' : s);

    Widget meta(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: VT.eyebrow(context, size: 10.0, color: c.mutedFg, spacing: 0.07)),
            const SizedBox(height: 2.0),
            Text(value.isEmpty ? '—' : value, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
          ],
        );

    Widget integration(String name, IconData icon, bool on, String sub, String pendingNote) => Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: on ? c.verified.withValues(alpha: 0.04) : c.card,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    VIconCircle(icon: icon, size: 32.0, iconSize: 16.0, square: true, bg: on ? c.verifiedBg : c.secondary, fg: on ? c.verified : c.mutedFg),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: VT.body(context, weight: FontWeight.w600)),
                          Text(sub, style: VT.muted(context, size: 11.0)),
                        ],
                      ),
                    ),
                    on
                        ? VBadge(label: 'Synced', icon: Icons.check_circle_outline, bg: c.verifiedBg, fg: c.verified)
                        : VBadge(label: 'Not synced', icon: Icons.schedule, bg: c.secondary, fg: c.mutedFg),
                  ],
                ),
              ),
              if (on && processed.isNotEmpty)
                for (var i = 0; i < processed.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.border))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(processed[i].headline, style: VT.body(context, size: 12.0, weight: FontWeight.w500)),
                              Text('${channelLabel(channelOf(processed[i].channel))} · ${fmtWhen(processed[i].receivedAt)}', style: VT.muted(context, size: 10.0)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        SizedBox(width: 80.0, child: Text(processed[i].kindLabel, style: VT.muted(context, size: 10.0))),
                        const SizedBox(width: 12.0),
                        Expanded(child: Text(h(processed[i].itemHash), style: VT.mono(context, size: 10.0))),
                        const SizedBox(width: 12.0),
                        Expanded(child: Text(h(processed[i].entryHash), style: VT.mono(context, size: 10.0))),
                      ],
                    ),
                  )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                  child: Text(on ? 'No processed receipts in this matter yet.' : pendingNote, style: VT.muted(context, size: 12.0)),
                ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Every piece of evidence synced to each connected system — with its content description, SHA-256 hash, chain entry, and timestamp.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(border: Border.all(color: c.border, width: 2.0), borderRadius: BorderRadius.circular(VR.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: c.panel,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VERIN EVIDENCE RECORD', style: VT.eyebrow(context, size: 11.0, color: c.onPanel, spacing: 0.14)),
                          const SizedBox(height: 4.0),
                          Text('Integration Report', style: VT.h2(context, size: 18.0, color: c.paper)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Generated', style: VT.body(context, size: 11.0, color: c.onPanelA(0.6))),
                        Text(fmtLongDay(now), style: VT.body(context, size: 12.0, weight: FontWeight.w500, color: c.onPanel)),
                        Text(fmtTime(now), style: VT.body(context, size: 11.0, color: c.onPanelA(0.6))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: c.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Wrap(
                  runSpacing: 10.0,
                  children: [
                    for (final (l, v) in [
                      ('Matter', m.title),
                      ('Client', m.clientName),
                      ('Cause number', m.caseNumber),
                      ('Status', matterIsOpen(m) ? 'Open' : 'Closed'),
                      ('Evidence items', '${items.length} total · ${processed.length} processed'),
                      ('Systems synced', '${synced ? 1 : 0} of 1 connected'),
                    ])
                      FractionallySizedBox(widthFactor: 0.5, child: Padding(padding: const EdgeInsets.only(right: 16.0), child: meta(l, v))),
                  ],
                ),
              ),
              Container(
                color: c.secondary,
                padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 12.0),
                child: Row(
                  children: [
                    Text('CHAIN HEAD', style: VT.eyebrow(context, size: 10.0, spacing: 0.07)),
                    const SizedBox(width: 12.0),
                    Expanded(child: Text(m.chainHeadHash.isEmpty ? '—' : m.chainHeadHash, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.mono(context, size: 10.0))),
                  ],
                ),
              ),
              integration(
                'Clio Manage',
                Icons.apartment_outlined,
                synced,
                m.isClioLinked ? 'Matched to ${m.clioMatterDisplayNumber.isNotEmpty ? m.clioMatterDisplayNumber : m.clioMatterRef}' : 'Not matched',
                widget.clioState == VClioState.pending
                    ? 'Matched — push the record to sync it.'
                    : 'Not connected. Use Connect Clio on this tab to link your account and push evidence records.',
              ),
              integration('MyCase', Icons.work_outline, false, 'Coming soon', 'Coming soon — needs partner approval from MyCase, and the MyCase Advanced plan or above.'),
              integration('Smokeball', Icons.bolt_outlined, false, 'Coming soon', 'Coming soon.'),
              Container(
                color: c.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Text(
                  'Hashes shown are truncated for readability — the downloaded PDF contains full 64-character SHA-256 values. A failed push is treated as a trust incident and surfaced immediately in Verin.',
                  style: VT.muted(context, size: 11.0, height: 1.6),
                ),
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
  }
}
