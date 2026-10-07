// Matter detail — port of the Make's <MatterDetail>: header with the matter
// summary, video strip, chain + Clio status, and the five-tab bar.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import 'intake_tab.dart';
import 'integrity_tab.dart';
import 'practice_tab.dart';
import 'receipts_tab.dart';
import 'exhibits_tab.dart';
import 'follow_ups.dart';
import 'thread_tab.dart';

enum MatterTab { intake, receipts, thread, followups, exhibits, integrity, practice }

class MatterDetailScreen extends StatefulWidget {
  const MatterDetailScreen({super.key, required this.matter, this.admin = false});

  final MattersRecord? matter;
  final bool admin;

  @override
  State<MatterDetailScreen> createState() => _MatterDetailScreenState();
}

class _MatterDetailScreenState extends State<MatterDetailScreen> {
  MatterTab _tab = MatterTab.intake;
  Stream<MattersRecord>? _matter;
  Stream<List<ReceiptsRecord>>? _receipts;
  late final Stream<Map<String, dynamic>> _intg = integrationStatusStream();

  @override
  void initState() {
    super.initState();
    final m = widget.matter;
    if (m != null) {
      _matter = matterStream(m.reference);
      _receipts = matterReceiptsStream(m.reference);
    }
  }

  void _back() {
    final route = widget.admin ? 'AdminMattersList' : 'MattersList';
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.goNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    if (widget.matter == null || _matter == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This matter could not be found.', style: VT.muted(context)),
              const SizedBox(height: 12.0),
              VButton(label: 'All matters', icon: Icons.arrow_back, kind: VButtonKind.tonal, onPressed: () => context.goNamed('MattersList')),
            ],
          ),
        ),
      );
    }
    return StreamBuilder<MattersRecord>(
      stream: _matter,
      initialData: widget.matter,
      builder: (context, ms) {
        final m = ms.data ?? widget.matter!;
        return StreamBuilder<List<ReceiptsRecord>>(
          stream: _receipts,
          builder: (context, rs) {
            final receipts = rs.data ?? const <ReceiptsRecord>[];
            return StreamBuilder<Map<String, dynamic>>(
              stream: _intg,
              builder: (context, ig) {
                final firmClio = ig.data?['clioConnected'] == true;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                        padding: const EdgeInsets.fromLTRB(40.0, 32.0, 40.0, 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VHover(
                              onTap: _back,
                              builder: (context, hovered) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back, size: 15.0, color: hovered ? c.foreground : c.mutedFg),
                                  const SizedBox(width: 6.0),
                                  Text('All matters', style: VT.body(context, size: 13.0, color: hovered ? c.foreground : c.mutedFg)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            SizedBox(
  width: double.infinity,
  child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              runSpacing: 12.0,
                              spacing: 16.0,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 680.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.title.isEmpty ? 'Untitled matter' : m.title, style: VT.h1(context, size: 28.0)),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        [
                                          if (m.clientName.isNotEmpty) m.clientName,
                                          if (m.caseNumber.isNotEmpty) m.caseNumber,
                                          matterPractice(m),
                                          if (m.openedAt != null) 'opened ${fmtDay(m.openedAt)}',
                                        ].join(' · '),
                                        style: VT.muted(context, size: 13.0),
                                      ),
                                      VideoSummaryStrip(receipts: receipts),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ChainStatusInline(status: chainStatusOf(m), long: true),
                                      const SizedBox(width: 8.0),
                                      ClioBadge(state: clioStateOf(m, firmConnected: firmClio)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
),
                            const SizedBox(height: 24.0),
                            _TabBar(value: _tab, onChanged: (t) => setState(() => _tab = t)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40.0, 32.0, 40.0, 48.0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 880.0),
                            child: switch (_tab) {
                              MatterTab.intake => IntakeTab(matter: m),
                              MatterTab.receipts => ReceiptsTab(matter: m, receipts: receipts, loading: !rs.hasData, error: rs.error),
                              MatterTab.thread => ThreadTab(matter: m, receipts: receipts),
                              MatterTab.exhibits => ExhibitsTab(matter: m, receipts: receipts),
                              MatterTab.followups => FollowUpsTab(matter: m, receipts: receipts, onShowInThread: () => setState(() => _tab = MatterTab.thread)),
                              MatterTab.integrity => IntegrityTab(matter: m, receipts: receipts),
                              MatterTab.practice => PracticeTab(matter: m, receipts: receipts, firmConnected: firmClio, firmStatus: ig.data ?? const {}),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.value, required this.onChanged});

  final MatterTab value;
  final ValueChanged<MatterTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    const tabs = [
      (MatterTab.intake, 'Intake channel', Icons.inbox_outlined),
      (MatterTab.receipts, 'Receipts', Icons.description_outlined),
      (MatterTab.thread, 'Thread', Icons.layers_outlined),
      (MatterTab.followups, 'Follow-ups', Icons.mark_email_unread_outlined),
      (MatterTab.exhibits, 'Exhibits', Icons.folder_copy_outlined),
      (MatterTab.integrity, 'Integrity', Icons.verified_user_outlined),
      (MatterTab.practice, 'Practice mgmt', Icons.apartment_outlined),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (id, label, icon) in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: VHover(
                onTap: () => onChanged(id),
                builder: (context, hovered) {
                  final on = id == value;
                  final color = on ? c.tealDeep : (hovered ? c.foreground : c.mutedFg);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: on ? c.teal : Colors.transparent, width: 2.0)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 15.0, color: color),
                        const SizedBox(width: 8.0),
                        Text(label, style: VT.body(context, size: 13.5, weight: FontWeight.w500, color: color)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// "3 videos · 4m 1s total" + transcoded + screen recording pills.
class VideoSummaryStrip extends StatelessWidget {
  const VideoSummaryStrip({super.key, required this.receipts});

  final List<ReceiptsRecord> receipts;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final videos = receipts.where((r) => r.isVideo && !r.isDuplicate).toList();
    if (videos.isEmpty) return const SizedBox.shrink();
    final total = videos.fold<int>(0, (s, r) => s + r.durationSeconds);
    final transcoded = videos.where((r) => r.originFidelity == 'transcoded_in_transit').length;
    final screen = videos.where((r) => r.isScreenRecordingItem).length;
    final dur = total > 0 ? (total >= 60 ? '${total ~/ 60}m ${total % 60}s' : '${total}s') : null;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 6.0,
        children: [
          VBadge(
            label: '${videos.length} video${videos.length == 1 ? '' : 's'}${dur != null ? ' · $dur total' : ''}',
            icon: Icons.movie_outlined,
            bg: c.teal.withValues(alpha: 0.1),
            fg: c.tealDeep,
          ),
          if (transcoded > 0)
            VBadge(label: '$transcoded transcoded in transit', icon: Icons.warning_amber_rounded, bg: c.pending.withValues(alpha: 0.1), fg: c.pending),
          if (screen > 0)
            VBadge(
              label: '$screen screen recording${screen == 1 ? '' : 's'} → thread reconstruction',
              icon: Icons.layers_outlined,
              bg: c.secondary,
              fg: c.secondaryFg,
            ),
        ],
      ),
    );
  }
}
