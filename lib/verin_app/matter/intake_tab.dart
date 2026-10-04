// Intake channel tab — port of the Make's <IntakeTab>.

import 'package:flutter/material.dart';

import '/backend/backend.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import 'manual_entry_drawer.dart';

class IntakeTab extends StatelessWidget {
  const IntakeTab({super.key, required this.matter});

  final MattersRecord matter;

  Map<String, dynamic> get _enabled {
    final v = matter.snapshotData['intakeEnabled'];
    return v is Map ? Map<String, dynamic>.from(v) : const {};
  }

  Future<void> _toggle(BuildContext context, String key, bool on) async {
    try {
      await matter.reference.update({'intakeEnabled.$key': on});
    } catch (e) {
      if (context.mounted) showVToast(context, 'Could not save: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final rows = [
      (VChannel.email, 'email', matter.emailAddress),
      (VChannel.sms, 'sms', matter.smsNumber),
      (VChannel.whatsapp, 'whatsapp', matter.whatsAppAddress),
    ];
    final provisioned = rDate(matter.snapshotData, 'intakeProvisionedAt');
    final anyAssigned = rows.any((r) => r.$3.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Intake channel', style: VT.h2(context, size: 20.0))),
            const SizedBox(width: 16.0),
            VButton(
              label: 'Add manual entry',
              icon: Icons.edit_outlined,
              kind: VButtonKind.tonal,
              size: VButtonSize.sm,
              onPressed: () => showManualEntryDrawer(context, matter: matter),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'This matter has its own addresses. The client forwards messages and photos from whatever device they already own — '
          'nothing to install, no account, no password. Hand them the card below.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.card)),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(color: c.card, border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                  child: Row(
                    children: [
                      VIconCircle(icon: channelIcon(rows[i].$1), size: 36.0, iconSize: 17.0),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(channelLabel(rows[i].$1), style: VT.muted(context, size: 12.0)),
                            Text(
                              rows[i].$3.isEmpty ? 'Not assigned yet' : rows[i].$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: rows[i].$3.isEmpty ? VT.muted(context) : VT.mono(context, size: 14.0),
                            ),
                          ],
                        ),
                      ),
                      VIconButton(
                        icon: Icons.content_copy,
                        size: 15.0,
                        tooltip: 'Copy',
                        onPressed: rows[i].$3.isEmpty ? null : () => copyToClipboard(context, rows[i].$3, what: '${channelLabel(rows[i].$1)} copied'),
                      ),
                      const SizedBox(width: 8.0),
                      VSwitch(
                        value: _enabled[rows[i].$2] != false,
                        onChanged: (v) => _toggle(context, rows[i].$2, v),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24.0),
        const VInfoPanel(
          title: 'How receiving works',
          radius: VR.card,
          padding: EdgeInsets.all(20.0),
          body: 'Mail and messages from unknown senders are accepted, not rejected — a client emailing from a second address, or a '
              "grandmother forwarding a photo, is normal. Anything the firm hasn't seen is routed to a one-click quarantine. "
              'Every raw payload is written to immutable storage and hashed before it is opened.',
        ),
        const SizedBox(height: 20.0),
        Text(
          anyAssigned
              ? 'Provisioned ${fmtDay(provisioned ?? matter.openedAt)} · number released 90 days after the matter closes, then quarantined before reuse.'
              : "Addresses are assigned when intake is switched on for your firm. Until then, add evidence with Add manual entry — it's hashed and chained the same way.",
          style: VT.muted(context, size: 11.0),
        ),
      ],
    );
  }
}
