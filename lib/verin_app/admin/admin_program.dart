// Program — the Make's <AdminProgram>: the firm's impact (Record Lag against
// the industry baseline, items built, matters with records) and what the
// program includes.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../matters/matters_screen.dart' show receiptsByMatterStream;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import 'admin_shell.dart';

class AdminProgram extends StatefulWidget {
  const AdminProgram({super.key, required this.firm, required this.user});

  final FirmAccountRecord? firm;
  final VUser user;

  @override
  State<AdminProgram> createState() => _AdminProgramState();
}

class _AdminProgramState extends State<AdminProgram> {
  late final Stream<List<MattersRecord>> _matters = firmMattersStream();
  late final Stream<Map<String, List<ReceiptsRecord>>> _receipts = receiptsByMatterStream();

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final f = widget.firm;
    final firmName = (f?.firmName.isNotEmpty ?? false) ? f!.firmName : widget.user.firm;
    final plan = (f?.planName.isNotEmpty ?? false) ? f!.planName : 'Program';
    final since = f?.memberSince;
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final now = DateTime.now();

    return StreamBuilder<List<MattersRecord>>(
      stream: _matters,
      builder: (context, ms) => StreamBuilder<Map<String, List<ReceiptsRecord>>>(
        stream: _receipts,
        builder: (context, rs) {
          final matters = ms.data ?? const <MattersRecord>[];
          final paths = {for (final m in matters) m.reference.path};
          final receipts = [
            for (final e in (rs.data ?? const <String, List<ReceiptsRecord>>{}).entries)
              if (paths.contains(e.key)) ...e.value.where((r) => !r.isDuplicate),
          ];
          final processed = receipts.where((r) => itemStateOf(r) == VItemState.processed).length;
          final lag = medianDays(recordLagsDays(receipts));
          final withRecords = matters.where((m) => receipts.any((r) => r.matterId?.path == m.reference.path)).length;
          final reduction = lag == null ? null : kBaselineRecordLagDays - lag;

          final stats = [
            (
              'Record Lag vs baseline',
              reduction == null ? '—' : '${reduction >= 0 ? '−' : '+'}${reduction.abs()} days',
              lag == null ? 'needs dated items' : '${kBaselineRecordLagDays}d → ${lag}d median',
              Icons.trending_down
            ),
            ('Evidence items built', '${receipts.length}', '$processed processed, standing', Icons.description_outlined),
            ('Matters with records', '$withRecords', 'of ${matters.length} matters', Icons.folder_open_outlined),
          ];

          return AdminPage(
            maxWidth: 800.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(VR.card)),
                      child: const Icon(Icons.emoji_events_outlined, size: 22.0, color: Color(0xFFF4C842)),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan, style: VT.h1(context, size: 28.0)),
                          const SizedBox(height: 4.0),
                          Text(
                            [
                              if (firmName.isNotEmpty) firmName,
                              if (since != null) 'Member since ${months[since.month - 1]} ${since.year}',
                              'Year ${programYear(f)}',
                            ].join(' · '),
                            style: VT.muted(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(VR.card)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR IMPACT · ${months[now.month - 1].toUpperCase()} ${now.year}', style: VT.eyebrow(context, size: 11.0, color: c.onPanel, spacing: 0.14)),
                      const SizedBox(height: 16.0),
                      LayoutBuilder(builder: (context, box) {
                        final narrow = box.maxWidth < 520.0;
                        final tiles = [
                          for (final (label, value, sub, icon) in stats)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, size: 14.0, color: c.onPanel),
                                    const SizedBox(width: 8.0),
                                    Flexible(child: Text(label, style: VT.body(context, size: 11.0, color: c.onPanelA(0.6)))),
                                  ],
                                ),
                                const SizedBox(height: 6.0),
                                Text(value, style: VT.h2(context, size: 28.0, color: c.paper)),
                                const SizedBox(height: 2.0),
                                Text(sub, style: VT.body(context, size: 11.0, color: c.onPanelA(0.5))),
                              ],
                            ),
                        ];
                        if (narrow) {
                          return Column(children: [for (final t in tiles) Padding(padding: const EdgeInsets.only(bottom: 16.0), child: SizedBox(width: double.infinity, child: t))]);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [for (final t in tiles) Expanded(child: Padding(padding: const EdgeInsets.only(right: 24.0), child: t))],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                VCard(
                  padding: EdgeInsets.zero,
                  clip: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                        child: Text('What your program includes', style: VT.body(context, weight: FontWeight.w600)),
                      ),
                      for (final (i, b) in const [
                        ('Unlimited matters', 'No cap on active matters or archived records.', true),
                        ('Team seats', 'Attorneys, paralegals, and admin in one workspace.', true),
                        ('Clio write-back', 'Finished records pushed into the matching Clio matter.', true),
                        ('Archive Build', 'Retroactive assembly of pre-Verin material.', true),
                        ('AI reading', 'Screenshots, documents and video read into a dated record.', true),
                        ('MyCase and Smokeball', 'Write-back to the other two practice systems.', false),
                        ('API access', 'REST API for custom integrations and automation.', false),
                      ].indexed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Icon(b.$3 ? Icons.check_circle_outline : Icons.schedule, size: 16.0, color: b.$3 ? c.verified : c.pending),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.$1, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                                    const SizedBox(height: 2.0),
                                    Text(b.$2, style: VT.muted(context, size: 12.0)),
                                  ],
                                ),
                              ),
                              if (!b.$3) VBadge(label: 'Coming soon', bg: c.pending.withValues(alpha: 0.1), fg: c.pending),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                VPanel(
                  radius: VR.card,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 15.0, color: c.teal),
                          const SizedBox(width: 8.0),
                          Text('The Record Lag argument', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Text.rich(
                        TextSpan(
                          style: VT.body(context, size: 13.0, height: 1.6),
                          children: [
                            const TextSpan(text: 'The industry baseline gap between when client material is created and when it enters the firm\'s file is '),
                            TextSpan(text: '$kBaselineRecordLagDays days', style: VT.body(context, size: 13.0, weight: FontWeight.w700, height: 1.6)),
                            TextSpan(text: lag == null ? '. Once items carry evidence dates, your median shows here.' : '. Your median today is '),
                            if (lag != null) TextSpan(text: '$lag days', style: VT.body(context, size: 13.0, weight: FontWeight.w700, height: 1.6)),
                            if (lag != null) const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'That number is your answer to every question about why a firm should pay for evidence infrastructure. Computed from ${receipts.length} item${receipts.length == 1 ? '' : 's'} as of ${fmtDay(now)}.',
                        style: VT.muted(context, size: 13.0, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
