// Intake channel tab — port of the Make's <IntakeTab>.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';

import '../data/format.dart';
import '../data/model.dart';
import 'client_card.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import 'manual_entry_drawer.dart';
import '/verin/verin_api.dart';
import '/verin/verin_config.dart' show currentFirmId;
import '../widgets/drawer.dart';
import '../onboarding/tour.dart' show DemoMode, TourTarget;

class IntakeTab extends StatefulWidget {
  const IntakeTab({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<IntakeTab> createState() => _IntakeTabState();
}

class _IntakeTabState extends State<IntakeTab> {
  static final Set<String> _asked = {};
  final _arrivalKey = GlobalKey<_DemoArrivalState>();
  bool _assigning = false;

  MattersRecord get matter => widget.matter;

  @override
  void initState() {
    super.initState();
    // Matters created before intake existed get their address on first visit.
    if ((matter.emailAddress.isEmpty || matter.smsNumber.isEmpty) && _asked.add(matter.reference.path)) _assign(quiet: true);
  }

  Future<void> _assign({bool quiet = false}) async {
    setState(() => _assigning = true);
    try {
      final r = await VerinApi.provisionIntake(matter.reference.id);
      if (!quiet && mounted && (r['emailAddress'] ?? '') == '' && (r['smsNumber'] ?? '') == '') {
        showVToast(context, 'Intake isn\'t switched on for Verin yet', error: true, description: 'An admin finishes the email and texting setup (see DEPLOYMENT.md).');
      }
    } catch (e) {
      if (!quiet && mounted) showVToast(context, 'Could not assign addresses', error: true, description: '$e');
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Map<String, dynamic> get _enabled {
    final v = matter.snapshotData['intakeEnabled'];
    return v is Map ? Map<String, dynamic>.from(v) : const {};
  }

  List<String> _list(String field) {
    final v = matter.snapshotData[field];
    return v is List ? v.whereType<String>().where((s) => s.trim().isNotEmpty).toList() : const [];
  }

  Future<void> _toggle(String key, bool on) async {
    try {
      await matter.reference.update({'intakeEnabled.$key': on});
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save: $e', error: true);
    }
  }

  Future<void> _addSender(String field, String label, String hint, TextInputType type) async {
    final ctl = TextEditingController();
    final value = await showVDialog<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add $label', style: VT.h2(ctx, size: 18.0)),
          const SizedBox(height: 6.0),
          Text(
            field == 'clientPhones'
                ? 'Texts from this number are filed to this matter automatically.'
                : 'Email from this address is read straight away instead of waiting in quarantine.',
            style: VT.muted(ctx, size: 13.0),
          ),
          const SizedBox(height: 16.0),
          VTextField(controller: ctl, hint: hint, keyboardType: type, onSubmitted: (v) => Navigator.of(ctx).pop(v)),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VButton(label: 'Cancel', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop()),
              const SizedBox(width: 8.0),
              VButton(label: 'Add', onPressed: () => Navigator.of(ctx).pop(ctl.text)),
            ],
          ),
        ],
      ),
    );
    final v = (value ?? '').trim();
    if (v.isEmpty) return;
    final ok = field == 'clientPhones' ? v.replaceAll(RegExp(r'\D'), '').length >= 10 : RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    if (!ok) {
      if (mounted) showVToast(context, field == 'clientPhones' ? 'Enter a full phone number with area code' : 'Enter a valid email address', error: true);
      return;
    }
    try {
      await matter.reference.update({
        field: FieldValue.arrayUnion([field == 'clientEmails' ? v.toLowerCase() : v]),
        if (field == 'clientPhones' && (matter.snapshotData['clientPhone'] ?? '') == '') 'clientPhone': v,
        if (field == 'clientEmails' && (matter.snapshotData['clientEmail'] ?? '') == '') 'clientEmail': v.toLowerCase(),
      });
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save: $e', error: true);
    }
  }

  Future<void> _removeSender(String field, String v) async {
    try {
      await matter.reference.update({
        field: FieldValue.arrayRemove([v]),
        if (field == 'clientPhones' && matter.snapshotData['clientPhone'] == v) 'clientPhone': '',
        if (field == 'clientEmails' && matter.snapshotData['clientEmail'] == v) 'clientEmail': '',
      });
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save: $e', error: true);
    }
  }

  static String _pretty(String e164) {
    final m = RegExp(r'^\+1(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
    return m == null ? e164 : '(${m[1]}) ${m[2]}-${m[3]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final rows = [
      (VChannel.email, 'email', matter.emailAddress, matter.emailAddress),
      (VChannel.sms, 'sms', matter.smsNumber, _pretty(matter.smsNumber)),
    ];
    final provisioned = rDate(matter.snapshotData, 'intakeProvisionedAt');
    final anyAssigned = rows.any((r) => r.$3.isNotEmpty);
    final phones = _list('clientPhones');
    final emails = _list('clientEmails');

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
          'This matter has its own address and number. The client forwards messages and photos from whatever device they already own — '
          'nothing to install, no account, no password. Hand them the card below.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        TourTarget(
          id: 'intake_channels',
          child: Container(
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
                            Text(rows[i].$2 == 'sms' ? 'Text (SMS / picture messages)' : 'Email', style: VT.muted(context, size: 12.0)),
                            Text(
                              rows[i].$3.isEmpty ? (_assigning ? 'Assigning…' : 'Not assigned yet') : rows[i].$4,
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
                        onPressed: rows[i].$3.isEmpty ? null : () => copyToClipboard(context, rows[i].$4, what: '${channelLabel(rows[i].$1)} copied'),
                      ),
                      const SizedBox(width: 8.0),
                      VSwitch(
                        value: _enabled[rows[i].$2] != false,
                        onChanged: (v) => _toggle(rows[i].$2, v),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 12.0),
        TourTarget(
          id: 'intake_card',
          child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            if (anyAssigned)
              VButton(
                label: 'Copy instructions for the client',
                icon: Icons.assignment_outlined,
                kind: VButtonKind.secondary,
                size: VButtonSize.sm,
                onPressed: () => copyToClipboard(context, clientInstructions(matter, CardLang.en), what: 'Client instructions copied'),
              ),
            if (anyAssigned)
              VButton(
                label: 'Copiar en español',
                icon: Icons.translate,
                kind: VButtonKind.secondary,
                size: VButtonSize.sm,
                onPressed: () => copyToClipboard(context, clientInstructions(matter, CardLang.es), what: 'Instrucciones copiadas'),
              ),
            if (rows.any((r) => r.$3.isEmpty))
              VButton(
                label: 'Assign now',
                icon: Icons.refresh,
                kind: VButtonKind.link,
                size: VButtonSize.sm,
                loading: _assigning,
                onPressed: _assigning ? null : () => _assign(),
              ),
          ],
        ),
        ),
        if (DemoMode.active) ...[
          const SizedBox(height: 20.0),
          TourTarget(
            id: 'intake_demo',
            onDemoTour: () {
              // The walkthrough sends one for them the first time.
              if (_DemoArrivalState._autoSent) return;
              _DemoArrivalState._autoSent = true;
              Future.delayed(const Duration(milliseconds: 900), () => _arrivalKey.currentState?._send());
            },
            child: _DemoArrival(key: _arrivalKey, matter: matter),
          ),
        ],
        const SizedBox(height: 24.0),
        Text('WHO THE CLIENT IS', style: VT.eyebrow(context)),
        const SizedBox(height: 4.0),
        Text(
          'Texts are matched to this matter by the sender\'s number. Email from these addresses is read right away; anyone else waits in quarantine for one click.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 12.0),
        TourTarget(
          id: 'intake_who',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
        _SenderList(
          icon: Icons.smartphone,
          label: 'Client mobile numbers',
          empty: 'Add the client\'s mobile so their texts land here.',
          values: phones.map(_pretty).toList(),
          raw: phones,
          onAdd: () => _addSender('clientPhones', 'a mobile number', '(317) 555-0142', TextInputType.phone),
          onRemove: (v) => _removeSender('clientPhones', v),
        ),
        const SizedBox(height: 10.0),
        _SenderList(
          icon: Icons.alternate_email,
          label: 'Client email addresses',
          empty: 'Add the client\'s email so their messages are read straight away.',
          values: emails,
          raw: emails,
          onAdd: () => _addSender('clientEmails', 'an email address', 'client@example.com', TextInputType.emailAddress),
          onRemove: (v) => _removeSender('clientEmails', v),
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
              ? 'Provisioned ${fmtDay(provisioned ?? matter.openedAt)} · the texting number is shared by your firm; messages are matched by the client\'s number.'
              : "Addresses are assigned when intake is switched on for your firm. Until then, add evidence with Add manual entry — it's hashed and chained the same way.",
          style: VT.muted(context, size: 11.0),
        ),
      ],
    );
  }
}

class _SenderList extends StatelessWidget {
  const _SenderList({
    required this.icon,
    required this.label,
    required this.empty,
    required this.values,
    required this.raw,
    required this.onAdd,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final String empty;
  final List<String> values;
  final List<String> raw;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(VR.card), border: Border.all(color: c.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 6.0), child: Icon(icon, size: 16.0, color: c.mutedFg)),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                const SizedBox(height: 6.0),
                if (values.isEmpty)
                  Text(empty, style: VT.muted(context, size: 12.5))
                else
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: [
                      for (var i = 0; i < values.length; i++)
                        Container(
                          padding: const EdgeInsets.fromLTRB(10.0, 4.0, 4.0, 4.0),
                          decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(999.0)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(values[i], style: VT.mono(context, size: 12.0)),
                              const SizedBox(width: 2.0),
                              InkWell(
                                borderRadius: BorderRadius.circular(999.0),
                                onTap: () => onRemove(raw[i]),
                                child: Padding(padding: const EdgeInsets.all(3.0), child: Icon(Icons.close, size: 13.0, color: c.mutedFg)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          VButton(label: 'Add', icon: Icons.add, kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: onAdd),
        ],
      ),
    );
  }
}

/// Demo workspaces only: the client "sends" the next sample message, so a
/// prospect can watch it arrive, get fingerprinted and read.
class _DemoArrival extends StatefulWidget {
  const _DemoArrival({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<_DemoArrival> createState() => _DemoArrivalState();
}

class _DemoArrivalState extends State<_DemoArrival> {
  static bool _autoSent = false;
  bool _busy = false;

  // "Text it now" (#3): watch for anything that arrives while this is open.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _lastSeen;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('Receipts')
        .where('matterId', isEqualTo: widget.matter.reference)
        .where('firmID', isEqualTo: currentFirmId())
        .orderBy('receivedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((q) {
      final d = q.docs.isEmpty ? null : q.docs.first;
      if (d == null) return;
      if (_lastSeen == null) {
        _lastSeen = d.id; // what was already there
        return;
      }
      if (d.id == _lastSeen) return;
      _lastSeen = d.id;
      if (_busy || !mounted) return; // the simulated one celebrates itself
      final ch = '${d.data()['channelKey'] ?? ''}';
      celebrate(context,
          title: ch == 'email' ? 'Your email just arrived' : 'Your text just arrived',
          subtitle: 'Received, fingerprinted and time-stamped live. Open Receipts or Thread to see it.');
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get _live => widget.matter.snapshotData['liveDemoTarget'] == true;

  /// The demo number when it's a real one (not the fictional 555-0000).
  String get _liveNumber {
    final n = widget.matter.smsNumber;
    return n.isEmpty || n == '+13175550000' ? '' : n;
  }

  static String _prettyNumber(String e164) {
    final m = RegExp(r'^\+1(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
    return m == null ? e164 : '(${m[1]}) ${m[2]}-${m[3]}';
  }

  Future<void> _makeLive() async {
    try {
      await widget.matter.reference.update({'liveDemoTarget': true, 'liveDemoTargetAt': FieldValue.serverTimestamp()});
      if (mounted) showVToast(context, 'This is the live case', description: 'Texts to the demo number from any phone, and emails to this address from anyone, land here.');
    } catch (e) {
      if (mounted) showVToast(context, 'Could not set it', error: true, description: '$e');
    }
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await VerinApi.demoSimulateArrival(widget.matter.reference.id);
      if (mounted) {
        celebrate(context,
            title: r['kind'] == 'email' ? 'An email just arrived' : 'A text just arrived',
            subtitle: 'Fingerprinted, time-stamped and read. Open Receipts or Thread to see it.');
      }
    } catch (e) {
      if (mounted) showVToast(context, 'Could not send the sample', error: true, description: e is VerinApiException ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: c.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VR.card),
        border: Border.all(color: c.teal.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 12.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRY IT LIVE', style: VT.eyebrow(context, size: 11.0)),
                const SizedBox(height: 4.0),
                Text(
                  _liveNumber.isNotEmpty
                      ? 'Text a screenshot to ${_prettyNumber(_liveNumber)} or forward an email to ${widget.matter.emailAddress.isEmpty ? 'this case' : widget.matter.emailAddress} — from your own phone. It appears here, dated and filed, while we talk.'
                      : 'Have the client send the next message to this case. It arrives through the same steps as a real one — stored, fingerprinted, time-stamped and read — in a few seconds.',
                  style: VT.body(context, size: 13.0),
                ),
                if (_liveNumber.isNotEmpty && !_live)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: VButton(label: 'Use this case for live messages', icon: Icons.podcasts, kind: VButtonKind.link, size: VButtonSize.sm, onPressed: _makeLive),
                  ),
              ],
            ),
          ),
          VButton(
            label: 'Simulate a client message',
            icon: Icons.send_rounded,
            loading: _busy,
            loadingLabel: 'Arriving…',
            onPressed: _busy ? null : _send,
          ),
        ],
      ),
    );
  }
}
