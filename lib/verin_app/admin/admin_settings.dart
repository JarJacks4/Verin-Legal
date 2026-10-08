// Settings — the Make's <AdminSettings>, <ApiAccessSheet> and
// <RetentionDialog>, saved on the firmAccount record.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/verin_api.dart';

import '../data/model.dart';
import '../shell/app_shell.dart' show kSignInRouteName;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import 'admin_shell.dart';
import 'exhibit_template_card.dart';
import 'records_settings.dart';
import '../shell/demo_banner.dart';
import '../demo/demo_runs.dart' show DemoRunsLog;
import '../onboarding/tour.dart' show TourTarget, demoType;

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key, required this.firm, required this.user});

  final FirmAccountRecord? firm;
  final VUser user;

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  late final _firmName = TextEditingController(text: _initialFirmName);
  late final _contact = TextEditingController(text: _str('primaryContact', widget.user.name));
  late final _billing = TextEditingController(text: _str('billingEmail', widget.user.email));
  late final _jurisdiction = TextEditingController(text: _str('jurisdiction', ''));
  late bool _nReceipt = _pref('newReceipt', true);
  late bool _nLag = _pref('recordLag', true);
  late bool _nTeam = _pref('teamActivity', false);
  bool _saving = false;
  bool _saved = false;
  String _export = 'idle';

  Map<String, dynamic> get _data => widget.firm?.snapshotData ?? const {};

  String get _initialFirmName {
    final f = widget.firm?.firmName ?? '';
    return f.isNotEmpty ? f : widget.user.firm;
  }

  String _str(String k, String fallback) {
    final v = rStr(_data, k);
    return v.isNotEmpty ? v : fallback;
  }

  bool _pref(String k, bool d) {
    final p = _data['notificationPrefs'];
    if (p is Map && p[k] is bool) return p[k] as bool;
    return d;
  }

  /// The NFR demo workspace is Verin's own sales tool: shown in a workspace
  /// that already is a demo, or to a Verin Legal sign-in setting one up.
  /// Law firms never see it.
  bool get _showDemoWorkspace =>
      isDemoFirm(widget.firm) || widget.user.email.trim().toLowerCase().endsWith('@verinlegal.com');

  @override
  void dispose() {
    _firmName.dispose();
    _contact.dispose();
    _billing.dispose();
    _jurisdiction.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _payload => {
        'firmName': _firmName.text.trim(),
        'primaryContact': _contact.text.trim(),
        'billingEmail': _billing.text.trim(),
        'jurisdiction': _jurisdiction.text.trim(),
        'notificationPrefs': {'newReceipt': _nReceipt, 'recordLag': _nLag, 'teamActivity': _nTeam},
      };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final f = widget.firm;
      if (f == null) {
        // The firm profile is created by the server at sign-up; it can only be
        // missing for a moment while an older workspace is upgraded.
        throw 'Your firm profile is still being set up. Reload the page and try again.';
      }
      await f.reference.update(_payload);
      if (!mounted) return;
      setState(() => _saved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save settings', error: true, description: '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportAll() async {
    if (_export != 'idle') return;
    setState(() => _export = 'building');
    showVToast(context, 'Preparing your export…', duration: const Duration(seconds: 30));
    try {
      final r = await VerinApi.exportFirmData();
      final url = '${r['downloadUrl'] ?? ''}';
      if (url.isNotEmpty) await launchURL(url);
      if (!mounted) return;
      setState(() => _export = 'done');
      showVToast(context, 'Export ready — download started', description: '${r['fileName'] ?? ''} · ${r['matters'] ?? 0} matters · ${r['files'] ?? 0} files with an index');
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _export = 'idle');
      });
    } on VerinApiException catch (e) {
      if (!mounted) return;
      setState(() => _export = 'idle');
      showVToast(context, 'Export failed', error: true, description: e.message);
    }
  }

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.toUpperCase(), style: VT.eyebrow(context, spacing: 0.08)),
            const SizedBox(height: 16.0),
            child,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final retention = _str('retentionPolicy', 'standard');
    final webhook = rStr(_data, 'webhookUrl');

    Widget toggleRow(String label, String sub, bool v, ValueChanged<bool> on, int i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                    Text(sub, style: VT.muted(context, size: 12.0)),
                  ],
                ),
              ),
              VSwitch(value: v, width: 40.0, onChanged: (x) => setState(() => on(x))),
            ],
          ),
        );

    return AdminPage(
      maxWidth: 680.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: VT.h1(context, size: 28.0)),
          const SizedBox(height: 4.0),
          Text('Firm profile, notifications, and API access.', style: VT.muted(context)),
          const SizedBox(height: 32.0),
          _section(
            'Firm profile',
            TourTarget(
              id: 'settings_profile',
              onDemoTour: () {
                demoType(_contact, 'Margaret Doe');
                demoType(_billing, 'billing@doefamilylaw.com');
                demoType(_jurisdiction, 'Indiana · IN Bar');
              },
              child: VCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VTextField(controller: _firmName, label: 'Firm name', hint: 'Harbor Family Law'),
                  const SizedBox(height: 16.0),
                  VTextField(controller: _contact, label: 'Primary contact', hint: 'Full name'),
                  const SizedBox(height: 16.0),
                  VTextField(controller: _billing, label: 'Billing email', hint: 'billing@yourfirm.com', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16.0),
                  VTextField(controller: _jurisdiction, label: 'State bar jurisdiction', hint: 'Indiana · IN Bar'),
                ],
              ),
            ),
            ),
          ),
          _section(
            'Notifications',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      toggleRow('New evidence receipt', 'Email when a new item arrives in any matter', _nReceipt, (v) => _nReceipt = v, 0),
                      toggleRow('Record Lag alert', 'Weekly summary if median lag exceeds 90 days', _nLag, (v) => _nLag = v, 1),
                      toggleRow('Team activity', 'When a member joins, is removed, or changes role', _nTeam, (v) => _nTeam = v, 2),
                    ],
                  ),
                ),
                const SizedBox(height: 8.0),
                Text("Preferences are saved now; notification emails start once email delivery is connected.", style: VT.muted(context, size: 11.0)),
              ],
            ),
          ),
          _section('Exhibit template', ExhibitTemplateCard(key: ValueKey(widget.firm?.reference.path ?? 'none'), firm: widget.firm)),
          _section('Records and delivery', RecordsSettingsCard(firm: widget.firm)),
          _section('Baseline Record Lag', BaselineCard(firm: widget.firm)),
          _section('Reports', ReportsCard(firm: widget.firm)),
          if (_showDemoWorkspace) _section('Demo workspace', TourTarget(id: 'settings_demo', child: DemoWorkspaceCard(firm: widget.firm))),
          if (isDemoFirm(widget.firm)) _section('Demo runs', const DemoRunsLog()),
          _section(
            'API access',
            VHover(
              onTap: () => showVDrawer<void>(context, title: 'API access', width: 520.0, builder: (_) => _ApiSheet(firm: widget.firm, initialWebhook: webhook)),
              builder: (context, hovered) => Opacity(
                opacity: hovered ? 0.8 : 1.0,
                child: VCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live secret key', style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                                Text('Manage keys, view usage, and configure webhooks.', style: VT.muted(context, size: 12.0)),
                              ],
                            ),
                          ),
                          VBadge(label: 'Coming Q1 2027', bg: c.pending.withValues(alpha: 0.1), fg: c.pending),
                          const SizedBox(width: 8.0),
                          Icon(Icons.chevron_right, size: 15.0, color: c.mutedFg),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      VPanel(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.vpn_key_outlined, size: 13.0, color: c.mutedFg),
                            const SizedBox(width: 8.0),
                            Expanded(child: Text('No key issued yet', style: VT.mono(context, size: 12.0, color: c.mutedFg))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _section(
            'Data & account',
            VCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  VHover(
                    onTap: () => showVDialog<void>(context, builder: (_) => _RetentionDialog(firm: widget.firm, current: retention)),
                    builder: (context, hovered) => Opacity(
                      opacity: hovered ? 0.8 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data retention', style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                                  Text('Evidence originals retained indefinitely · playback derivatives 90 days', style: VT.muted(context, size: 12.0)),
                                ],
                              ),
                            ),
                            Text(retention[0].toUpperCase() + retention.substring(1), style: VT.muted(context, size: 12.0)),
                            const SizedBox(width: 6.0),
                            Icon(Icons.chevron_right, size: 14.0, color: c.mutedFg),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export all data', style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                              Text('Download a ZIP of all matters, receipts, and manifests', style: VT.muted(context, size: 12.0)),
                            ],
                          ),
                        ),
                        VButton(
                          label: _export == 'done' ? 'Done' : 'Export',
                          icon: _export == 'done' ? Icons.check_circle_outline : Icons.file_download_outlined,
                          kind: VButtonKind.link,
                          size: VButtonSize.sm,
                          loading: _export == 'building',
                          loadingLabel: 'Building…',
                          onPressed: _export == 'idle' ? _exportAll : null,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sign out', style: VT.body(context, size: 13.0, weight: FontWeight.w500, color: c.broken)),
                              Text('Sign out of this device', style: VT.muted(context, size: 12.0)),
                            ],
                          ),
                        ),
                        VHover(
                          onTap: () async {
                            final router = GoRouter.of(context);
                            router.prepareAuthEvent();
                            await authManager.signOut();
                            router.clearRedirectLocation();
                            router.goNamed(kSignInRouteName);
                          },
                          builder: (context, _) => Row(
                            children: [
                              Icon(Icons.logout, size: 14.0, color: c.broken),
                              const SizedBox(width: 6.0),
                              Text('Sign out', style: VT.body(context, size: 13.0, weight: FontWeight.w500, color: c.broken)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          VButton(
            label: _saved ? 'Saved' : 'Save changes',
            icon: _saved ? Icons.check_circle_outline : null,
            size: VButtonSize.lg,
            fullWidth: true,
            loading: _saving,
            loadingLabel: 'Saving…',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ApiSheet extends StatefulWidget {
  const _ApiSheet({required this.firm, required this.initialWebhook});

  final FirmAccountRecord? firm;
  final String initialWebhook;

  @override
  State<_ApiSheet> createState() => _ApiSheetState();
}

class _ApiSheetState extends State<_ApiSheet> {
  late final _webhook = TextEditingController(text: widget.initialWebhook);
  bool _saved = false;

  @override
  void dispose() {
    _webhook.dispose();
    super.dispose();
  }

  Future<void> _saveWebhook() async {
    final url = _webhook.text.trim();
    if (!url.startsWith('https://')) {
      showVToast(context, 'Use an https:// URL', error: true);
      return;
    }
    final f = widget.firm;
    if (f == null) {
      showVToast(context, 'Save your firm profile first', error: true);
      return;
    }
    try {
      await f.reference.update({'webhookUrl': url});
      if (!mounted) return;
      setState(() => _saved = true);
      showVToast(context, 'Webhook endpoint saved');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(s, style: VT.muted(context, size: 12.0, weight: FontWeight.w600)),
        );
    return Padding(
      padding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Authenticate requests, manage webhooks, and monitor usage.', style: VT.muted(context)),
              const SizedBox(height: 20.0),
              const VNotice(
                text: 'The Verin REST API is in private beta — launching Q1 2027. A key is issued to your firm when access opens.',
              ),
              const SizedBox(height: 24.0),
              label('LIVE SECRET KEY'),
              VPanel(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, size: 13.0, color: c.mutedFg),
                    const SizedBox(width: 8.0),
                    Expanded(child: Text('No key issued yet', style: VT.mono(context, size: 12.0, color: c.mutedFg))),
                  ],
                ),
              ),
              const SizedBox(height: 6.0),
              Text('Never share a key. Treat it like a password — it grants full API access to your firm.', style: VT.muted(context, size: 11.0)),
              const SizedBox(height: 24.0),
              label('USAGE THIS MONTH'),
              Row(
                children: [
                  for (final (i, (l, v)) in const [('Requests', '—'), ('Rate limit', '500 / min'), ('Included', '10k / mo')].indexed) ...[
                    if (i > 0) const SizedBox(width: 12.0),
                    Expanded(
                      child: VPanel(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(v, style: VT.body(context, size: 15.0, weight: FontWeight.w600)),
                            const SizedBox(height: 2.0),
                            Text(l, style: VT.muted(context, size: 11.0)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24.0),
              label('WEBHOOK ENDPOINT'),
              Text(
                'Verin will POST a signed JSON payload to this URL on every intake receipt, status change, and integrity event once the API opens.',
                style: VT.muted(context, size: 12.0),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: TourTarget(
                      id: 'api_webhook',
                      onDemoTour: () => demoType(_webhook, 'https://example.com/verin-webhook'),
                      child: TextField(
                      controller: _webhook,
                      style: VT.body(context, size: 13.0),
                      decoration: vInputDecoration(context, hint: 'https://your-server.com/verin-webhook'),
                    ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  VButton(label: _saved ? 'Saved' : 'Save', size: VButtonSize.sm, onPressed: _saveWebhook),
                ],
              ),
              const SizedBox(height: 6.0),
              Text('Payloads will be signed with X-Verin-Signature using HMAC-SHA256.', style: VT.muted(context, size: 11.0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

const _plans = [
  ('standard', 'Standard', 'Current plan', 'Evidence originals retained indefinitely. Playback derivatives (transcripts, thumbnails) retained for 90 days.', 'Included'),
  ('extended', 'Extended', 'Add-on', 'All originals and derivatives retained for 7 years to satisfy most state bar record-keeping requirements.', r'$29 / mo'),
  ('custom', 'Custom', 'Enterprise', 'Define per-matter retention windows, litigation hold policies, and automatic purge schedules.', 'Contact us'),
];

class _RetentionDialog extends StatefulWidget {
  const _RetentionDialog({required this.firm, required this.current});

  final FirmAccountRecord? firm;
  final String current;

  @override
  State<_RetentionDialog> createState() => _RetentionDialogState();
}

class _RetentionDialogState extends State<_RetentionDialog> {
  late String _sel = widget.current;
  bool _saving = false;

  Future<void> _save() async {
    final f = widget.firm;
    if (f == null) {
      showVToast(context, 'Save your firm profile first', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      // Standard applies immediately; paid tiers are recorded as a request.
      await f.reference.update(_sel == 'standard'
          ? {'retentionPolicy': 'standard', 'retentionRequest': FieldValue.delete()}
          : {'retentionRequest': _sel, 'retentionRequestedAt': FieldValue.serverTimestamp()});
      if (!mounted) return;
      final label = _plans.firstWhere((p) => p.$1 == _sel).$2;
      Navigator.of(context).pop();
      showVToast(
        context,
        _sel == 'standard' ? 'Retention policy set to Standard' : '$label retention requested',
        description: _sel == 'standard' ? null : 'Verin will confirm the change and any billing before it applies.',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showVToast(context, 'Could not save: $e', error: true);
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
        Row(
          children: [
            Expanded(child: Text('Data retention policy', style: VT.body(context, size: 16.0, weight: FontWeight.w600))),
            VIconButton(icon: Icons.close, size: 14.0, filled: true, onPressed: () => Navigator.of(context).maybePop()),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Choose how long Verin stores your evidence files and derivatives. Originals are never automatically deleted on the Standard plan.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 20.0),
        for (final p in _plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: VHover(
              onTap: () => setState(() => _sel = p.$1),
              builder: (context, _) {
                final on = _sel == p.$1;
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: on ? c.verified.withValues(alpha: 0.05) : c.secondary,
                    borderRadius: BorderRadius.circular(VR.xl),
                    border: Border.all(color: on ? c.teal : c.border, width: on ? 2.0 : 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16.0,
                            height: 16.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? c.teal : c.border, width: 2.0)),
                            child: on ? Container(width: 8.0, height: 8.0, decoration: BoxDecoration(color: c.teal, shape: BoxShape.circle)) : null,
                          ),
                          const SizedBox(width: 8.0),
                          Text(p.$2, style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
                            decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(999)),
                            child: Text(p.$1 == widget.current ? 'Current plan' : p.$3, style: VT.muted(context, size: 10.0, weight: FontWeight.w500)),
                          ),
                          const Spacer(),
                          Text(p.$5, style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: c.tealDeep)),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Padding(padding: const EdgeInsets.only(left: 24.0), child: Text(p.$4, style: VT.muted(context, size: 12.0))),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(child: VButton(label: 'Cancel', kind: VButtonKind.secondary, fullWidth: true, size: VButtonSize.sm, onPressed: () => Navigator.of(context).maybePop())),
            const SizedBox(width: 12.0),
            Expanded(
              child: VButton(
                label: _sel == 'custom' ? 'Request upgrade' : (_sel == 'extended' ? 'Request add-on' : 'Save policy'),
                fullWidth: true,
                size: VButtonSize.sm,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
