// Practice management, as it looks in an NFR demo workspace: Clio, MyCase and
// Smokeball shown connected with sample accounts, and "Send record" playing
// the real steps (build, upload, file) without calling any outside system.

import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import '../onboarding/tour.dart' show TourTarget;

class _Provider {
  const _Provider(this.name, this.icon, this.account, this.where);
  final String name;
  final IconData icon;
  final String account;
  final String where; // where documents land in that system
}

const _providers = [
  _Provider('Clio Manage', Icons.apartment_outlined, 'Doe Family Law · Clio (US)', 'Documents'),
  _Provider('MyCase', Icons.work_outline, 'Doe Family Law · MyCase', 'Case documents'),
  _Provider('Smokeball', Icons.bolt_outlined, 'Doe Family Law · Smokeball', 'Matter files'),
];

class _Sync {
  _Sync(this.provider, this.file, this.at, this.size);
  final String provider;
  final String file;
  final DateTime at;
  final String size;
}

class DemoPracticeTab extends StatefulWidget {
  const DemoPracticeTab({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<DemoPracticeTab> createState() => _DemoPracticeTabState();
}

class _DemoPracticeTabState extends State<DemoPracticeTab> {
  late final List<_Sync> _log = _history();
  String? _busy; // provider name being sent to
  int _step = 0;
  int _version = 3;
  Timer? _timer;

  static const _steps = ['Building the record PDF', 'Uploading', 'Filing in the matter'];

  String get _title => widget.matter.title.isEmpty ? 'Matter' : widget.matter.title;

  String get _matchNo {
    final d = widget.matter.clioMatterDisplayNumber;
    return d.isNotEmpty ? d : '00417-${widget.matter.clientName.split(' ').last}';
  }

  List<_Sync> _history() {
    final now = DateTime.now();
    return [
      _Sync('Clio Manage', '$_title — Evidence Record v3.pdf', now.subtract(const Duration(days: 1, hours: 2)), '2.1 MB'),
      _Sync('Smokeball', '$_title — Exhibit set A–F.zip', now.subtract(const Duration(days: 4, hours: 5)), '6.8 MB'),
      _Sync('MyCase', '$_title — Evidence Record v2.pdf', now.subtract(const Duration(days: 9, hours: 1)), '1.7 MB'),
      _Sync('Clio Manage', '$_title — Evidence Record v1.pdf', now.subtract(const Duration(days: 16)), '0.9 MB'),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _send(_Provider p) {
    if (_busy != null) return;
    setState(() {
      _busy = p.name;
      _step = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (t) {
      if (!mounted) return t.cancel();
      if (_step < _steps.length - 1) {
        setState(() => _step++);
        return;
      }
      t.cancel();
      setState(() {
        _version++;
        _log.insert(0, _Sync(p.name, '$_title — Evidence Record v$_version.pdf', DateTime.now(), '2.3 MB'));
        _busy = null;
      });
      celebrate(context, title: 'Filed in ${p.name}', subtitle: 'Matter $_matchNo → ${p.where}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Practice management', style: VT.h2(context, size: 20.0)),
        const SizedBox(height: 4.0),
        Text(
          'Finished records and exhibit sets file straight into your practice management system — the firm gets the benefit without anyone logging in to Verin.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 20.0),
        TourTarget(
          id: 'practice_cards',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in _providers) ...[
                _card(context, p),
                const SizedBox(height: 12.0),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Text('RECENT FILINGS', style: VT.eyebrow(context)),
        const SizedBox(height: 8.0),
        TourTarget(
          id: 'practice_log',
          child: VCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _log.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  color: i == 0 && DateTime.now().difference(_log[0].at).inSeconds < 4 ? c.teal.withValues(alpha: 0.08) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16.0, color: c.verified),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_log[i].file, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                            Text('${_log[i].provider} · ${fmtWhen(_log[i].at)} · ${_log[i].size}', style: VT.muted(context, size: 11.5)),
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
        const SizedBox(height: 12.0),
        Text(
          'Demo workspace: these connections use sample accounts. In your workspace each one is connected once by an admin.',
          style: VT.muted(context, size: 11.0),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, _Provider p) {
    final c = VC.of(context);
    final busy = _busy == p.name;
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VIconCircle(icon: p.icon, size: 36.0, iconSize: 18.0, square: true),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: VT.body(context, weight: FontWeight.w600)),
                    Text(p.account, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.muted(context, size: 12.0)),
                  ],
                ),
              ),
              IntgBadge(state: VIntgState.connected, name: p.name.split(' ').first),
            ],
          ),
          const SizedBox(height: 12.0),
          Text('Matched to $_matchNo · records land in ${p.where}', style: VT.body(context, size: 13.0)),
          const SizedBox(height: 12.0),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: busy
                ? Column(
                    key: const ValueKey('busy'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999.0),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / _steps.length,
                          minHeight: 6.0,
                          backgroundColor: c.muted,
                          valueColor: AlwaysStoppedAnimation<Color>(c.teal),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text('${_steps[_step]}…', style: VT.muted(context, size: 12.0)),
                    ],
                  )
                : Wrap(
                    key: const ValueKey('idle'),
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      VButton(
                        label: 'Send record to ${p.name.split(' ').first}',
                        icon: Icons.upload_rounded,
                        size: VButtonSize.sm,
                        onPressed: _busy == null ? () => _send(p) : null,
                      ),
                      VButton(
                        label: 'View in ${p.name.split(' ').first}',
                        icon: Icons.open_in_new,
                        kind: VButtonKind.tonal,
                        size: VButtonSize.sm,
                        onPressed: () => showVToast(context, 'Opens the matter in ${p.name}', description: 'Not available in the demo workspace.'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
