// Billing & Plan — the Make's <AdminBilling> layout over the firmAccount
// record. Card payments are not connected, so payment-method editing says so
// instead of pretending to save a card.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import 'admin_shell.dart';

String money(int cents) {
  final d = cents / 100.0;
  final whole = d.round() == d;
  final s = whole ? d.toStringAsFixed(0) : d.toStringAsFixed(2);
  final parts = s.split('.');
  final buf = StringBuffer();
  final digits = parts[0];
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '\$${buf.toString()}${parts.length > 1 ? '.${parts[1]}' : ''}';
}

class AdminBilling extends StatelessWidget {
  const AdminBilling({super.key, required this.firm});

  final FirmAccountRecord? firm;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final f = firm;
    final hasPlan = f != null && f!.planName.isNotEmpty;
    final status = (f?.planStatus ?? '').trim();
    final active = status.isEmpty || status.toLowerCase() == 'active';
    final integrations = (f?.connectedIntegrations ?? const <String>[]);

    return AdminPage(
      maxWidth: 720.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Billing & Plan', style: VT.h1(context, size: 28.0)),
          const SizedBox(height: 4.0),
          Text('Manage your subscription and payment details.', style: VT.muted(context)),
          const SizedBox(height: 32.0),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(VR.card)),
            child: !hasPlan
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NO PLAN ON FILE', style: VT.eyebrow(context, color: c.onPanel, spacing: 0.14)),
                      const SizedBox(height: 8.0),
                      Text('Your plan will appear here once Verin sets up your account.', style: VT.body(context, color: c.onPanelA(0.75))),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14.0, color: Color(0xFFF4C842)),
                                    const SizedBox(width: 8.0),
                                    Text(f!.planName.toUpperCase(), style: VT.eyebrow(context, color: c.onPanel, spacing: 0.14)),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Text.rich(
                                  TextSpan(children: [
                                    TextSpan(text: f!.planPriceCents > 0 ? money(f!.planPriceCents) : '—', style: VT.h2(context, size: 32.0, color: c.paper)),
                                    if (f!.planPriceCents > 0) TextSpan(text: '/year', style: VT.body(context, size: 16.0, color: c.paper)),
                                  ]),
                                ),
                                const SizedBox(height: 4.0),
                                Text(f!.planRenewsAt == null ? 'Renewal date not set' : 'Next renewal ${fmtLongDay(f!.planRenewsAt)}',
                                    style: VT.body(context, size: 13.0, color: c.onPanelA(0.7))),
                              ],
                            ),
                          ),
                          VBadge(
                            label: status.isEmpty ? 'Active' : status,
                            icon: active ? Icons.check_circle_outline : Icons.schedule,
                            bg: active ? const Color(0x4D2F7D5B) : const Color(0x4DB0791C),
                            fg: active ? const Color(0xFF7FD4A8) : const Color(0xFFF2C77A),
                            bold: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      Container(height: 1.0, color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 20.0),
                      Row(
                        children: [
                          for (final (l, v) in [
                            ('Matters', 'Unlimited'),
                            ('Team seats', f!.seatLimit > 0 ? 'Up to ${f!.seatLimit}' : '—'),
                            ('Integrations', integrations.isEmpty ? 'Clio' : integrations.join(' · ')),
                          ])
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.toUpperCase(), style: VT.eyebrow(context, size: 10.0, color: c.onPanelA(0.5), spacing: 0.08)),
                                  const SizedBox(height: 2.0),
                                  Text(v, style: VT.body(context, size: 13.0, weight: FontWeight.w500, color: c.onPanel)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24.0),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Payment method', style: VT.body(context, weight: FontWeight.w600))),
                    VButton(
                      label: 'Update',
                      kind: VButtonKind.link,
                      size: VButtonSize.sm,
                      onPressed: () => showVDrawer<void>(context, title: 'Update payment method', width: 460.0, builder: (_) => const _PaymentInfo()),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 32.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(8.0)),
                      child: Icon(Icons.receipt_long_outlined, size: 16.0, color: c.tealDeep),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoiced annually', style: VT.body(context, weight: FontWeight.w500)),
                          Text('No card on file · ${f?.firmName.isNotEmpty == true ? f!.firmName : 'your firm'}', style: VT.muted(context, size: 12.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          _Invoices(firm: f),
        ],
      ),
    );
  }
}

class _PaymentInfo extends StatelessWidget {
  const _PaymentInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Changes take effect at the next billing cycle.', style: VT.muted(context)),
        const SizedBox(height: 20.0),
        const VNotice(
          tone: VNoticeTone.teal,
          icon: Icons.lock_outline,
          text: "Card payments aren't connected in Verin yet, so a card can't be saved here. Your plan is invoiced directly — reply to your latest invoice email to change how you pay.",
        ),
        const SizedBox(height: 24.0),
        VButton(label: 'Close', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => Navigator.of(context).maybePop()),
      ],
    );
  }
}

class _Invoices extends StatelessWidget {
  const _Invoices({required this.firm});

  final FirmAccountRecord? firm;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final f = firm;
    final Stream<QuerySnapshot<Map<String, dynamic>>>? stream =
        f == null ? null : f.reference.collection('invoices').orderBy('date', descending: true).snapshots();
    return VCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          final docs = snap.data?.docs ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                child: Row(
                  children: [
                    Expanded(child: Text('Invoice history', style: VT.body(context, weight: FontWeight.w600))),
                    Text('${docs.length} invoice${docs.length == 1 ? '' : 's'}', style: VT.muted(context, size: 12.0)),
                  ],
                ),
              ),
              if (docs.isEmpty)
                Padding(padding: const EdgeInsets.all(24.0), child: Text('No invoices yet.', style: VT.muted(context, size: 13.0))),
              for (var i = 0; i < docs.length; i++)
                () {
                  final d = docs[i].data();
                  final paid = rStr(d, 'status').toLowerCase() == 'paid';
                  final url = rStr(d, 'pdfUrl');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                    child: Row(
                      children: [
                        VIconCircle(
                          icon: Icons.receipt_long_outlined,
                          size: 36.0,
                          iconSize: 16.0,
                          square: true,
                          bg: c.verified.withValues(alpha: 0.1),
                          fg: c.verified,
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rStr(d, 'description').isEmpty ? 'Invoice' : rStr(d, 'description'), style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                              Text(fmtDay(rDate(d, 'date')), style: VT.muted(context, size: 11.0)),
                            ],
                          ),
                        ),
                        Text(money(rInt(d, 'amountCents')), style: VT.body(context, weight: FontWeight.w600)),
                        const SizedBox(width: 16.0),
                        VBadge(
                          label: rStr(d, 'status').isEmpty ? '—' : rStr(d, 'status'),
                          bg: paid ? c.verified.withValues(alpha: 0.1) : c.pending.withValues(alpha: 0.1),
                          fg: paid ? c.verified : c.pending,
                        ),
                        if (url.isNotEmpty) ...[
                          const SizedBox(width: 12.0),
                          VButton(label: 'PDF', icon: Icons.file_download_outlined, kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => launchURL(url)),
                        ],
                      ],
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    );
  }
}
