// Domain badges from the Make: channel, item state, Clio state, integration
// state, origin fidelity, chain status.

import 'package:flutter/material.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import 'atoms.dart';

IconData channelIcon(VChannel c) => switch (c) {
      VChannel.email => Icons.mail_outline,
      VChannel.sms => Icons.chat_bubble_outline,
      VChannel.whatsapp => Icons.phone_outlined,
      VChannel.upload => Icons.file_upload_outlined,
      VChannel.inPerson => Icons.back_hand_outlined,
      VChannel.mail => Icons.markunread_mailbox_outlined,
      VChannel.other => Icons.more_horiz,
    };

class ChannelBadge extends StatelessWidget {
  const ChannelBadge({super.key, required this.channel});

  final VChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return VBadge(label: channelLabel(channel), icon: channelIcon(channel), bg: c.secondary, fg: c.secondaryFg);
  }
}

class StateBadge extends StatelessWidget {
  const StateBadge({super.key, required this.state});

  final VItemState state;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return switch (state) {
      VItemState.processed => VBadge(label: 'Processed', icon: Icons.check_circle_outline, bg: c.verifiedBg, fg: c.verified),
      VItemState.uncertain => VBadge(label: 'Uncertain', icon: Icons.help_outline, bg: c.pendingBg, fg: c.pending),
      VItemState.unreadable => VBadge(label: 'Unreadable', icon: Icons.cancel_outlined, bg: c.brokenBg, fg: c.broken),
      VItemState.processing => VBadge(label: 'Reading…', icon: Icons.auto_awesome_outlined, bg: c.tealPale, fg: c.tealDeep),
    };
  }
}

class ClioBadge extends StatelessWidget {
  const ClioBadge({super.key, required this.state});

  final VClioState state;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return switch (state) {
      VClioState.synced => VBadge(label: 'In Clio', icon: Icons.check_circle_outline, bg: c.verifiedBg, fg: c.verified),
      VClioState.pending => VBadge(label: 'Sync pending', icon: Icons.schedule, bg: c.pendingBg, fg: c.pending),
      VClioState.failed => VBadge(label: 'Sync failed', icon: Icons.warning_amber_rounded, bg: c.brokenBg, fg: c.broken),
      VClioState.notConnected => VBadge(label: 'Not connected', icon: Icons.apartment_outlined, bg: c.secondary, fg: c.mutedFg),
    };
  }
}

enum VIntgState { connected, pending, notConnected, comingSoon }

class IntgBadge extends StatelessWidget {
  const IntgBadge({super.key, required this.state, required this.name});

  final VIntgState state;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return switch (state) {
      VIntgState.connected => VBadge(label: 'In $name', icon: Icons.check_circle_outline, bg: c.verifiedBg, fg: c.verified),
      VIntgState.pending => VBadge(label: 'Connecting…', icon: Icons.schedule, bg: c.pendingBg, fg: c.pending),
      VIntgState.notConnected => VBadge(label: 'Not connected', icon: Icons.open_in_new, bg: c.secondary, fg: c.mutedFg),
      VIntgState.comingSoon => VBadge(label: 'Coming soon', icon: Icons.schedule, bg: c.pendingBg, fg: c.pending),
    };
  }
}

class OriginFidelityBadge extends StatelessWidget {
  const OriginFidelityBadge({super.key, required this.fidelity});

  final String fidelity;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return switch (fidelity) {
      'as_sent' => VBadge(label: 'As sent', icon: Icons.check_circle_outline, bg: c.verified.withValues(alpha: 0.1), fg: c.verified, size: 10.0),
      'transcoded_in_transit' => VBadge(
          label: 'Transcoded in transit', icon: Icons.warning_amber_rounded, bg: c.pending.withValues(alpha: 0.1), fg: c.pending, size: 10.0),
      'undetermined' => VBadge(label: 'Fidelity undetermined', bg: c.secondary, fg: c.mutedFg, size: 10.0),
      _ => const SizedBox.shrink(),
    };
  }
}

/// "Verified" / "No chain yet" / "Needs review" in the matters list and header.
class ChainStatusInline extends StatelessWidget {
  const ChainStatusInline({super.key, required this.status, this.long = false});

  final VChainStatus status;

  /// "Chain verified" (header) vs "Verified" (list).
  final bool long;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return switch (status) {
      VChainStatus.verified =>
        VStatusInline(label: long ? 'Chain verified' : 'Verified', icon: Icons.verified_user_outlined, color: c.verified),
      VChainStatus.needsReview =>
        VStatusInline(label: 'Needs review', icon: Icons.warning_amber_rounded, color: c.pending),
      VChainStatus.notStarted => VStatusInline(label: 'No chain yet', icon: Icons.schedule, color: c.mutedFg),
    };
  }
}
