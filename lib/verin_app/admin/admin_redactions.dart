// Admin → Redactions: the firm-wide view a founding customer asked for.
//
// The staff page answers "what has Verin flagged in my matters?". This one
// answers the questions a firm's admin, managing partner or risk counsel ask
// instead:
//
//   how much of this is there, and in what
//   what leaves the firm, and does anyone confirm it first
//   what do we always mask, everywhere
//   what can Verin not mask at all
//
// The last one matters most. Video and audio leave in their original form, so
// a firm that assumes everything can be redacted will produce something it
// meant to hold back. This page says so before that happens.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/model.dart';
import '../matter/exhibits_tab.dart' show sensitiveOf, categoryLabel;
import '../onboarding/tour.dart';
import '../redactions/redactions_screen.dart' show AlwaysRedactCard, flaggedIn;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/motion.dart';
import 'admin_shell.dart';

class AdminRedactions extends StatefulWidget {
  const AdminRedactions({super.key, required this.firm, required this.user});

  final FirmAccountRecord? firm;
  final VUser user;

  @override
  State<AdminRedactions> createState() => _AdminRedactionsState();
}

class _AdminRedactionsState extends State<AdminRedactions> {
  late final Stream<List<ReceiptsRecord>> _receipts = queryReceiptsRecord(
    queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()),
    limit: 600,
  );

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return AdminPage(
      maxWidth: 900.0,
      child: StreamBuilder<List<ReceiptsRecord>>(
        stream: _receipts,
        builder: (context, snap) {
          final loading = !snap.hasData;
          final all = snap.data ?? const <ReceiptsRecord>[];
          final flags = flaggedIn(all);

          // Items that leave as they arrived, so nothing in them can be masked.
          final unmaskable = all.where((r) => r.itemKind == 'video' || r.itemKind == 'audio').toList();
          final unmaskableFlagged = unmaskable.where((r) => sensitiveOf(r).isNotEmpty).toList();

          final byCategory = <String, int>{};
          for (final f in flags) {
            byCategory[f.category] = (byCategory[f.category] ?? 0) + 1;
          }
          final matters = <String>{for (final f in flags) f.matterRef?.path ?? ''}..remove('');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Redactions', style: VT.h1(context, size: 28.0)),
              const SizedBox(height: 4.0),
              Text('What Verin has flagged across the firm, what is always masked, and what cannot be masked at all.',
                  style: VT.muted(context)),
              const SizedBox(height: 28.0),

              TourTarget(
                id: 'admin_redaction_counts',
                child: Row(
                  children: [
                    Expanded(child: _Tile(label: 'Flagged details', value: flags.length, loading: loading, icon: Icons.flag_outlined)),
                    const SizedBox(width: 12.0),
                    Expanded(child: _Tile(label: 'Matters affected', value: matters.length, loading: loading, icon: Icons.folder_open_outlined)),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: _Tile(
                        label: 'Cannot be masked',
                        value: unmaskable.length,
                        loading: loading,
                        icon: Icons.videocam_off_outlined,
                        tone: unmaskableFlagged.isNotEmpty ? 'warn' : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28.0),

              if (unmaskableFlagged.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: c.pending.withValues(alpha: 0.1),
                    border: Border.all(color: c.pending.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(VR.xl),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18.0, color: c.pending),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${unmaskableFlagged.length} recording${unmaskableFlagged.length == 1 ? '' : 's'} with flagged details',
                                style: VT.body(context, size: 13.5, weight: FontWeight.w600)),
                            const SizedBox(height: 2.0),
                            Text(
                              'Video and audio go out in their original form, so nothing inside them can be masked by a production. '
                              'Redact them in the matter first, or hand the original over separately. Verin stops a production that would include one of these.',
                              style: VT.muted(context, size: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28.0),
              ],

              Text('ALWAYS REDACTED, FIRM-WIDE', style: VT.eyebrow(context)),
              const SizedBox(height: 10.0),
              TourTarget(id: 'admin_always_redact', child: AlwaysRedactCard(firm: widget.firm)),
              const SizedBox(height: 28.0),

              Text('WHAT VERIN FINDS', style: VT.eyebrow(context)),
              const SizedBox(height: 10.0),
              if (loading)
                const VShimmer(height: 120.0, radius: 16.0)
              else if (byCategory.isEmpty)
                VCard(
                  child: Text('Nothing flagged yet. Verin marks personal details as evidence arrives.',
                      style: VT.muted(context, size: 12.5)),
                )
              else
                VCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, e) in (byCategory.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .indexed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                          decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                          child: Row(
                            children: [
                              Expanded(child: Text(categoryLabel(e.key), style: VT.body(context, size: 13.0))),
                              Text('${e.value}', style: VT.mono(context, size: 13.0, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 10.0),
              Text(
                'A flag is a prompt to look, not a finding. Nothing is masked or removed until someone at the firm confirms it, '
                'and the original item is never altered.',
                style: VT.muted(context, size: 11.5),
              ),
              const SizedBox(height: 28.0),

              Text('HOW REDACTION WORKS HERE', style: VT.eyebrow(context)),
              const SizedBox(height: 10.0),
              TourTarget(
                id: 'admin_redaction_policy',
                child: VCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final row in const [
                        ('Photos and screenshots', 'Black boxes are burned into the pixels, so nothing under them survives.'),
                        ('Documents and email', 'Flagged text is removed wherever it appears; pages with redactions are re-rendered.'),
                        ('Video and audio', 'Redacted in the matter: boxes burned in, marked spans silenced, saved as a new file. The original is kept and still verifies.'),
                        ('Record extracts and reports', 'Flagged values are masked, and someone confirms the redactions before anything is exported.'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 180.0,
                                child: Text(row.$1, style: VT.body(context, size: 12.5, weight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(child: Text(row.$2, style: VT.muted(context, size: 12.5))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40.0),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.loading, required this.icon, this.tone});

  final String label;
  final int value;
  final bool loading;
  final IconData icon;
  final String? tone;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final accent = tone == 'warn' ? c.pending : c.tealDeep;
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.0, color: accent),
              const SizedBox(width: 6.0),
              Expanded(child: Text(label.toUpperCase(), style: VT.eyebrow(context, size: 10.0))),
            ],
          ),
          const SizedBox(height: 10.0),
          if (loading)
            const VShimmer(width: 48.0, height: 26.0, radius: 6.0)
          else
            VCountUp(value: value, style: VT.h1(context, size: 26.0)),
        ],
      ),
    );
  }
}
