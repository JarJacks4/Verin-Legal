// Help & support (profile drawer → Help & support): how to reach Verin
// Legal, when, how fast, and short articles for firm staff. Also the
// service-status strip every screen shows while systemStatus/current is
// active (set in the Firebase console during an incident).

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/verin_config.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

const _articles = <(String, String)>[
  (
    'Open a matter and get its intake address',
    'Matters → New matter. Add the client\'s mobile and email. The matter gets its own email address and texting number on the Intake channel tab; anything sent there is filed to this matter only.',
  ),
  (
    'Give your client the instruction card',
    'Intake channel → Copy instructions for the client (or Copiar en español). Paste it into an email or text. It says where to send things, what to send for this kind of case, and what to do in an emergency.',
  ),
  (
    'What happens when an item arrives',
    'Verin keeps the item exactly as sent, takes its SHA-256 fingerprint, adds it to the matter\'s hash chain and gets an independent time-stamp. Then the AI reads it: dates, messages, statements. Nothing sent is ever turned away.',
  ),
  (
    'Work the Review queue',
    'Every item ends as processed, uncertain or unreadable — nothing is guessed silently. Review shows the uncertain and unreadable ones, email from unknown senders (approve with one click) and texts from numbers no matter knows (file them to a matter).',
  ),
  (
    'Check a line against the original',
    'On the Thread tab, click the file name on any message. The original opens beside the reading with the exact spot highlighted. If something was read wrong, note a discrepancy — the original and the AI\'s reading are never changed.',
  ),
  (
    'Ask for a cited summary',
    'Thread tab → Cited summary. Leave the topic empty for the whole conversation or type one (for example "pickup times"). Every line links to the messages it comes from; tap a number to check it.',
  ),
  (
    'Request what is missing',
    'Follow-ups suggests gaps worth asking about. Open a request in your own email, send it, and it closes by itself when the evidence arrives.',
  ),
  (
    'Produce exhibits',
    'Exhibits → New production. Pick items, review suggested redactions, and produce a Bates-stamped set with an index and a ZIP. A finished production can open a draft declaration covering the receipt records.',
  ),
  (
    'Send the record to Clio',
    'An admin connects Clio once in Admin → Settings. Then each matter\'s Practice mgmt tab links to its Clio matter and sends the finished record there; failures show in the sync log.',
  ),
  (
    'Export a record and verify it yourself',
    'Integrity → Export record ZIP. The ZIP holds every item, its time-stamp token and verify.py, which checks the fingerprints and the chain without Verin. Admins can export every matter from Admin → Settings.',
  ),
];

Future<void> showHelpCenter(BuildContext context) => showVDrawer<void>(
      context,
      title: 'Help & support',
      builder: (_) => const _HelpBody(),
    );

class _HelpBody extends StatefulWidget {
  const _HelpBody();

  @override
  State<_HelpBody> createState() => _HelpBodyState();
}

class _HelpBodyState extends State<_HelpBody> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONTACT SUPPORT', style: VT.eyebrow(context)),
              const SizedBox(height: 8.0),
              Text(kSupportEmail, style: VT.mono(context, size: 14.0, weight: FontWeight.w600)),
              const SizedBox(height: 4.0),
              Text(kSupportHours, style: VT.body(context, size: 13.0)),
              Text(kSupportResponse, style: VT.muted(context, size: 12.0)),
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  VButton(label: 'Email support', icon: Icons.mail_outline, size: VButtonSize.sm, onPressed: () => launchURL('mailto:$kSupportEmail?subject=Verin%20support')),
                  VButton(label: 'Copy address', icon: Icons.copy, kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: () => copyToClipboard(context, kSupportEmail, what: 'Support address copied')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24.0),
        Text('HOW TO', style: VT.eyebrow(context)),
        const SizedBox(height: 8.0),
        for (final (i, (title, body)) in _articles.indexed)
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VHover(
                  onTap: () => setState(() => _open = _open == i ? null : i),
                  builder: (context, hovered) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(title, style: VT.body(context, size: 13.5, weight: FontWeight.w600, color: hovered ? c.teal : null))),
                        Icon(_open == i ? Icons.expand_less : Icons.expand_more, size: 18.0, color: c.mutedFg),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  child: _open == i
                      ? Padding(padding: const EdgeInsets.only(bottom: 14.0), child: Text(body, style: VT.body(context, size: 13.0, height: 1.6)))
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20.0),
        Wrap(
          spacing: 8.0,
          children: [
            VButton(label: 'Terms of Service', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => launchURL(kTermsUrl)),
            VButton(label: 'Privacy Policy', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => launchURL(kPrivacyUrl)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Service status (systemStatus/current: { active, level: info|degraded|outage,
// message, updatedAt }) — written only from the Firebase console.
// ---------------------------------------------------------------------------

final Stream<Map<String, dynamic>?> _status = FirebaseFirestore.instance
    .collection('systemStatus')
    .doc('current')
    .snapshots()
    .map((s) => s.data())
    .handleError((_) {})
    .asBroadcastStream();

class SystemStatusBanner extends StatelessWidget {
  const SystemStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _status,
      builder: (context, s) {
        final d = s.data;
        final msg = d == null ? '' : rStr(d, 'message');
        if (d == null || d['active'] != true || msg.isEmpty) return const SizedBox.shrink();
        final level = rStr(d, 'level');
        final (Color bg, Color fg, IconData icon) = switch (level) {
          'outage' => (c.brokenBg, c.broken, Icons.error_outline),
          'degraded' => (c.pendingBg, c.pending, Icons.warning_amber_rounded),
          _ => (c.tealPale, c.tealDeep, Icons.info_outline),
        };
        final at = rDate(d, 'updatedAt');
        return Container(
          width: double.infinity,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 15.0, color: fg),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  '$msg${at == null ? '' : ' · updated ${fmtTimeShort(at)}'}',
                  style: VT.body(context, size: 12.5, weight: FontWeight.w500, color: fg),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: fg, minimumSize: const Size(0, 28.0)),
                onPressed: () => showHelpCenter(context),
                child: Text('Contact support', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: fg)),
              ),
            ],
          ),
        );
      },
    );
  }
}

String fmtTimeShort(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}
