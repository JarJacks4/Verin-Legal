// Verin Legal — Matter Detail header (guide §3b–§3d): back link, title,
// client · case · practice area · opened date, chain/Clio pills, video chips.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../record_ext.dart';
import '../verin_format.dart';
import '../verin_ui.dart';

class MatterHeader extends StatelessWidget {
  const MatterHeader({
    super.key,
    required this.matter,
    required this.receipts,
    required this.onOpenThread,
  });

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final VoidCallback onOpenThread;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    // §3d: one pass over the receipts instead of three chained actions.
    var videoCount = 0;
    var videoSeconds = 0;
    var transcoded = 0;
    var screenRecordings = 0;
    for (final r in receipts) {
      if (r.itemKind == 'video') {
        videoCount++;
        videoSeconds += r.durationSeconds;
        if (r.originFidelity == 'transcoded_in_transit') transcoded++;
      } else if (r.itemKind == 'screen_recording') {
        screenRecordings++;
      }
    }

    final subtitleParts = <String>[
      if (matter.clientName.isNotEmpty) matter.clientName,
      if (matter.caseNumber.isNotEmpty) matter.caseNumber,
      if (matter.practiceArea.isNotEmpty) matter.practiceArea,
      if (matter.openedAt != null) 'opened ${fmtDate(matter.openedAt)}',
    ];

    final chainOk = matter.chainVerified;

    return Container(
      width: double.infinity,
      color: t.secondaryBackground,
      padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('MattersList');
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 18.0, color: t.secondaryText),
                const SizedBox(width: 8.0),
                Text('All matters', style: VerinText.label(context)),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 12.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orDash(matter.title), style: VerinText.display(context)),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitleParts.isEmpty ? kDash : subtitleParts.join(' · '),
                      style: VerinText.small(context),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12.0,
                runSpacing: 8.0,
                children: [
                  VerinPill(
                    label: chainOk
                        ? 'Chain verified'
                        : (matter.hasChainRoot ? 'Needs review' : 'No chain yet'),
                    icon: chainOk ? Icons.verified_user_rounded : Icons.report_problem_rounded,
                    background: chainOk ? t.success10 : t.warning10,
                    foreground: chainOk ? t.success : t.warning,
                    border: chainOk ? t.success40 : t.warning30,
                  ),
                  if (matter.clioSyncedAt != null)
                    VerinPill(
                      label: 'In Clio',
                      icon: Icons.check_circle_rounded,
                      background: t.secondary10,
                      foreground: t.secondary,
                    ),
                ],
              ),
            ],
          ),
          if (videoCount > 0 || screenRecordings > 0) ...[
            const SizedBox(height: 20.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                if (videoCount > 0)
                  _Chip(
                    icon: Icons.slow_motion_video_rounded,
                    label: '${pluralize(videoCount, 'video')} · ${fmtDuration(videoSeconds)} total',
                    color: t.secondary,
                    background: const Color(0x190E6E7D),
                    border: t.alternate,
                  ),
                if (transcoded > 0)
                  _Chip(
                    icon: Icons.warning_amber_rounded,
                    label: '$transcoded transcoded in transit',
                    color: t.warning,
                    background: const Color(0x1EB0791C),
                    border: const Color(0x4DC98D26),
                  ),
                if (screenRecordings > 0)
                  _Chip(
                    icon: Icons.layers_rounded,
                    label: '${pluralize(screenRecordings, 'screen recording')} → thread reconstruction',
                    color: t.secondary,
                    background: const Color(0x190E6E7D),
                    border: t.alternate,
                    onTap: onOpenThread,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.border,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(25.0),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: color),
          const SizedBox(width: 4.0),
          Text(label, style: VerinText.label(context, color: color, weight: FontWeight.bold)),
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(borderRadius: BorderRadius.circular(25.0), onTap: onTap, child: chip);
  }
}
