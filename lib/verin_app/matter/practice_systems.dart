// Practice mgmt tab → PracticePanther and Filevine cards (Clio has its own).
//
// Each card walks the same path: connect the firm (PracticePanther: approve
// Verin in PracticePanther; Filevine: paste the service-account token), link
// this matter to the matching one there, then deliver the record. Delivery
// uploads the record ZIP and, once the system accepts it, Verin removes its
// copy of each finished file (same as Clio).

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/verin_api.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

class PracticeSystemInfo {
  const PracticeSystemInfo(this.id, this.label, this.icon, this.where, this.connectNote);
  final String id;
  final String label;
  final IconData icon;
  final String where;
  final String connectNote;
}

const kPracticeSystems = [
  PracticeSystemInfo('practicepanther', 'PracticePanther', Icons.pets_outlined, 'Files',
      'An admin approves Verin in PracticePanther once; every matter can then be linked.'),
  PracticeSystemInfo('filevine', 'Filevine', Icons.account_tree_outlined, 'Documents',
      "An admin creates a Filevine service account for Verin and pastes its access token here once."),
];

/// Cached for the session: which systems Verin has keys for.
Future<Map<String, dynamic>>? _availability;
Future<Map<String, dynamic>> practiceAvailability() => _availability ??= VerinApi.practiceAvailability().catchError((_) => <String, dynamic>{});

Map<String, dynamic> practiceLinkOf(MattersRecord m, String provider) {
  final links = m.snapshotData['practiceLinks'];
  final l = links is Map ? links[provider] : null;
  return l is Map ? Map<String, dynamic>.from(l) : const {};
}

class PracticeSystemCard extends StatefulWidget {
  const PracticeSystemCard({super.key, required this.system, required this.matter, required this.firmStatus, required this.isAdmin});

  final PracticeSystemInfo system;
  final MattersRecord matter;
  final Map<String, dynamic> firmStatus;
  final bool isAdmin;

  @override
  State<PracticeSystemCard> createState() => _PracticeSystemCardState();
}

class _PracticeSystemCardState extends State<PracticeSystemCard> {
  late final Future<Map<String, dynamic>> _avail = practiceAvailability();
  bool _busy = false;

  String get _id => widget.system.id;
  bool get _connected => widget.firmStatus['${_id}Connected'] == true;

  Future<void> _connect(Map<String, dynamic> avail) async {
    if (_id == 'practicepanther') {
      setState(() => _busy = true);
      try {
        final url = await VerinApi.practicePantherAuthStart();
        if (url.isNotEmpty) await launchURL(url);
        if (mounted) showVToast(context, 'Finish in PracticePanther', description: 'Approve Verin there, then come back to this tab.');
      } on VerinApiException catch (e) {
        if (mounted) showVToast(context, 'Could not start', error: true, description: e.message);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    await showVDrawer<void>(context, title: 'Connect Filevine', tour: 'filevine_connect', builder: (_) => _FilevineConnect(partner: avail['filevinePartner'] == true));
  }

  Future<void> _deliver() async {
    setState(() => _busy = true);
    try {
      final r = await VerinApi.deliverMatterRecord(widget.matter.reference.id, target: _id);
      if (mounted) celebrate(context, title: 'Delivered to ${widget.system.label}', subtitle: '${r['items'] ?? 0} items · ${r['removed'] ?? 0} files removed from Verin');
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, 'Delivery failed — nothing was removed', error: true, description: e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final link = practiceLinkOf(widget.matter, _id);
    final linked = '${link['id'] ?? ''}'.isNotEmpty;
    final user = '${widget.firmStatus['${_id}UserName'] ?? ''}';
    return FutureBuilder<Map<String, dynamic>>(
      future: _avail,
      builder: (context, a) {
        final avail = a.data ?? const <String, dynamic>{};
        final ready = avail[_id] == true;
        final state = !ready && !_connected ? 'Awaiting API access' : (!_connected ? 'Not connected' : (linked ? 'Linked' : 'Connected'));
        return VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  VIconCircle(icon: widget.system.icon, size: 36.0, iconSize: 18.0, square: true),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.system.label, style: VT.body(context, weight: FontWeight.w600)),
                        Text(
                          linked
                              ? 'Linked to ${[link['display'], link['name']].where((x) => '${x ?? ''}'.isNotEmpty).join(' · ')}'
                              : (_connected ? 'Connected${user.isNotEmpty ? ' as $user' : ''}' : widget.system.connectNote),
                          style: VT.muted(context, size: 12.0),
                        ),
                      ],
                    ),
                  ),
                  VBadge(
                    label: state,
                    bg: (linked ? c.verified : (_connected ? c.teal : c.mutedFg)).withValues(alpha: 0.12),
                    fg: linked ? c.verified : (_connected ? c.tealDeep : c.mutedFg),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  if (!_connected && ready && widget.isAdmin)
                    VButton(label: 'Connect ${widget.system.label}', icon: Icons.link, size: VButtonSize.sm, loading: _busy, onPressed: _busy ? null : () => _connect(avail)),
                  if (!_connected && ready && !widget.isAdmin) Text('Ask a firm admin to connect ${widget.system.label}.', style: VT.muted(context, size: 12.0)),
                  if (!_connected && !ready)
                    Text('Verin is waiting on ${widget.system.label} to grant API access. It switches on here when it does.', style: VT.muted(context, size: 12.0)),
                  if (_connected && !linked)
                    VButton(
                      label: 'Link this matter',
                      icon: Icons.search,
                      size: VButtonSize.sm,
                      onPressed: () => showVDrawer<void>(context, title: 'Link to ${widget.system.label}', builder: (_) => _LinkSearch(system: widget.system, matter: widget.matter)),
                    ),
                  if (_connected && linked) ...[
                    VButton(label: 'Deliver the record', icon: Icons.upload_rounded, size: VButtonSize.sm, loading: _busy, loadingLabel: 'Delivering…', onPressed: _busy ? null : _deliver),
                    if ('${link['url'] ?? ''}'.isNotEmpty)
                      VButton(label: 'Open in ${widget.system.label}', icon: Icons.open_in_new, kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: () => launchURL('${link['url']}')),
                    VButton(
                      label: 'Change link',
                      kind: VButtonKind.link,
                      size: VButtonSize.sm,
                      onPressed: () => showVDrawer<void>(context, title: 'Link to ${widget.system.label}', builder: (_) => _LinkSearch(system: widget.system, matter: widget.matter)),
                    ),
                  ],
                  if (_connected && widget.isAdmin)
                    VButton(
                      label: 'Disconnect',
                      kind: VButtonKind.link,
                      size: VButtonSize.sm,
                      onPressed: () async {
                        try {
                          await VerinApi.practiceDisconnect(_id);
                        } on VerinApiException catch (e) {
                          if (context.mounted) showVToast(context, 'Could not disconnect', error: true, description: e.message);
                        }
                      },
                    ),
                ],
              ),
              if (linked) ...[
                const SizedBox(height: 8.0),
                Text('Records land in ${widget.system.where}. Once ${widget.system.label} accepts a delivery, Verin removes its copy of each finished file; hashes and timestamps stay.',
                    style: VT.muted(context, size: 11.5)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LinkSearch extends StatefulWidget {
  const _LinkSearch({required this.system, required this.matter});

  final PracticeSystemInfo system;
  final MattersRecord matter;

  @override
  State<_LinkSearch> createState() => _LinkSearchState();
}

class _LinkSearchState extends State<_LinkSearch> {
  late final _q = TextEditingController(text: widget.matter.snapshotData['clientName'] is String ? widget.matter.snapshotData['clientName'] as String : '');
  List<Map<String, dynamic>>? _results;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await VerinApi.practiceSearchMatters(widget.system.id, _q.text.trim());
      if (mounted) setState(() => _results = r);
    } on VerinApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _link(Map<String, dynamic> m) async {
    try {
      await VerinApi.practiceLinkMatter(
        provider: widget.system.id,
        matterId: widget.matter.reference.id,
        externalId: '${m['id']}',
        display: '${m['display'] ?? ''}',
        name: '${m['name'] ?? ''}',
        url: '${m['url'] ?? ''}',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      celebrate(context, title: 'Linked to ${widget.system.label}', subtitle: '${m['name'] ?? ''}');
    } on VerinApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final results = _results ?? const <Map<String, dynamic>>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Find the matching ${widget.system.label} ${widget.system.id == 'filevine' ? 'project' : 'matter'}. Verin also adds the client\'s intake details there as a note.',
            style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 12.0),
        VTextField(controller: _q, label: 'Search', hint: 'Client or matter name', onSubmitted: (_) => _search()),
        const SizedBox(height: 8.0),
        VButton(label: 'Search', icon: Icons.search, kind: VButtonKind.tonal, size: VButtonSize.sm, loading: _busy, onPressed: _busy ? null : _search),
        if (_error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: _error!)],
        const SizedBox(height: 12.0),
        if (_results != null && results.isEmpty && !_busy) Text('Nothing found. Try the client\'s last name.', style: VT.muted(context, size: 12.5)),
        for (final m in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: VHover(
              onTap: () => _link(m),
              builder: (context, hovered) => Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(color: hovered ? c.secondary : c.card, borderRadius: BorderRadius.circular(10.0), border: Border.all(color: c.border)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m['name'] ?? ''}', style: VT.body(context, size: 13.5, weight: FontWeight.w500)),
                          Text([m['display'], m['client']].where((x) => '${x ?? ''}'.isNotEmpty).join(' · '), style: VT.muted(context, size: 12.0)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16.0, color: c.mutedFg),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilevineConnect extends StatefulWidget {
  const _FilevineConnect({required this.partner});

  /// True when Verin has Filevine partner keys (the firm only pastes a token).
  final bool partner;

  @override
  State<_FilevineConnect> createState() => _FilevineConnectState();
}

class _FilevineConnectState extends State<_FilevineConnect> {
  final _token = TextEditingController();
  final _id = TextEditingController();
  final _secret = TextEditingController();
  bool _canada = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await VerinApi.filevineConnect(token: _token.text.trim(), clientId: _id.text.trim(), clientSecret: _secret.text.trim(), region: _canada ? 'ca' : 'us');
      if (!mounted) return;
      Navigator.of(context).pop();
      celebrate(context, title: 'Filevine connected', subtitle: '${r['name'] ?? ''}');
    } on VerinApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'In Filevine: Main menu → Advanced → Service Accounts → create one for Verin (type "Adhoc"), then an Account Admin creates a personal access token for it. '
          'Paste that token below. Verin stores it encrypted and uses it only to file records on matters you link.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 14.0),
        VTextField(controller: _token, label: 'Personal access token', obscure: true),
        if (!widget.partner) ...[
          const SizedBox(height: 12.0),
          Text('Also from Account Manager → Access Tokens → Client Secrets:', style: VT.muted(context, size: 12.0)),
          const SizedBox(height: 8.0),
          VTextField(controller: _id, label: 'Client ID'),
          const SizedBox(height: 12.0),
          VTextField(controller: _secret, label: 'Client secret', obscure: true),
        ],
        const SizedBox(height: 12.0),
        Row(
          children: [
            VSwitch(value: _canada, width: 40.0, onChanged: (v) => setState(() => _canada = v)),
            const SizedBox(width: 10.0),
            Text('Our Filevine account is in Canada (filevine.ca)', style: VT.body(context, size: 13.0)),
          ],
        ),
        if (_error != null) ...[const SizedBox(height: 12.0), VErrorBox(message: _error!)],
        const SizedBox(height: 18.0),
        VButton(label: 'Connect', icon: Icons.link, fullWidth: true, loading: _busy, loadingLabel: 'Checking…', onPressed: _busy ? null : _save),
      ],
    );
  }
}
