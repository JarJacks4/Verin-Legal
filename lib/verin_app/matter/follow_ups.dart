// Missing-evidence follow-ups (Differentiator 4).
//
// Verin drafts specific requests from the record's gaps — the messages either
// side of a break, a screenshot that shows the date, a clearer copy. Staff
// pick, edit and approve the recipient and the wording; approving opens the
// request in their own email app, so it goes from the firm's address. Verin
// never sends anything. A sent request closes itself when the evidence that
// answers it arrives.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

final _col = FirebaseFirestore.instance.collection('FollowUps');

bool _validEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

String _firstName(String full) {
  final t = full.trim();
  return t.isEmpty ? '' : t.split(RegExp(r'\s+')).first;
}

/// Opens the composer for one or more requests. Returns true when sent.
Future<bool> showFollowUpComposer(BuildContext context, {required MattersRecord matter, required List<Suggestion> requests}) async {
  final r = await showVDrawer<bool>(
    context,
    title: requests.length == 1 ? 'Request missing evidence' : 'Request ${requests.length} items',
    width: 560.0,
    tour: 'followup_composer',
    builder: (_) => _Composer(matter: matter, requests: requests),
  );
  return r == true;
}

class _Composer extends StatefulWidget {
  const _Composer({required this.matter, required this.requests});
  final MattersRecord matter;
  final List<Suggestion> requests;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  late final _to = TextEditingController(text: matterClientEmail(widget.matter));
  late final _subject = TextEditingController(text: 'A few more items for your file${widget.matter.title.isNotEmpty ? ' — ${widget.matter.title}' : ''}');
  late final _body = TextEditingController(text: _draft());
  bool _busy = false;
  String? _error;

  String _draft() {
    final me = VUser.current();
    final first = _firstName(widget.matter.clientName);
    final reqs = widget.requests.map((s) => s.request.trim()).where((s) => s.isNotEmpty).toList();
    final list = reqs.length == 1 ? reqs.first : [for (var i = 0; i < reqs.length; i++) '${i + 1}. ${reqs[i]}'].join('\n\n');
    return [
      first.isNotEmpty ? 'Hi $first,' : 'Hello,',
      '',
      reqs.length == 1
          ? 'Thank you for the screenshots so far. To complete the record, could you send one more thing?'
          : 'Thank you for the screenshots so far. To complete the record, could you send the following?',
      '',
      list,
      '',
      'You can reply to this email with the files or send them to your usual Verin intake address.',
      '',
      'Thank you,',
      me.name.isNotEmpty ? me.name : '',
      if (me.firm.isNotEmpty) me.firm,
    ].join('\n').trimRight();
  }

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final to = _to.text.trim();
    if (!_validEmail(to)) {
      setState(() => _error = 'Enter the email address this should go to.');
      return;
    }
    if (_body.text.trim().isEmpty) {
      setState(() => _error = 'The request is empty.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final firm = currentFirmId();
      final me = VUser.current();
      final batch = FirebaseFirestore.instance.batch();
      // One record per request so each closes on its own when answered.
      final existing = await _col.where('matterId', isEqualTo: widget.matter.reference).where('firmID', isEqualTo: firm).get();
      for (final s in widget.requests) {
        final prior = existing.docs.where((d) => d.data()['key'] == s.key).toList();
        final data = {
          'status': 'sent',
          'recipient': to,
          'subject': _subject.text.trim(),
          'body': _body.text,
          'title': s.title,
          'kind': s.kind,
          'request': s.request,
          'sentBy': currentUserUid,
          'sentByName': me.name,
          'sentAt': FieldValue.serverTimestamp(),
        };
        if (prior.isNotEmpty) {
          batch.update(prior.first.reference, data);
        } else {
          batch.set(_col.doc(), {
            ...data,
            'firmID': firm,
            'matterId': widget.matter.reference,
            'key': s.key,
            'createdBy': currentUserUid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      batch.set(FirebaseFirestore.instance.collection('Activity').doc(), {
        'firmID': firm,
        'matterId': widget.matter.reference,
        'uid': currentUserUid,
        'type': 'follow_up_sent',
        'requests': widget.requests.length,
        'at': FieldValue.serverTimestamp(),
      });
      if (to != matterClientEmail(widget.matter)) batch.update(widget.matter.reference, {'clientEmail': to});
      await batch.commit();
      final uri = Uri(scheme: 'mailto', path: to, query: _encode({'subject': _subject.text.trim(), 'body': _body.text}));
      await launchURL(uri.toString());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not record the request: $e';
        });
      }
    }
  }

  // mailto needs %20 for spaces, not "+".
  static String _encode(Map<String, String> q) => q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Check the wording and who it goes to. Approving opens it in your email app to send from your own address — Verin doesn\'t send it.',
            style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 20.0),
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 14.0)],
        VTextField(controller: _to, label: 'To', hint: 'client@example.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14.0),
        VTextField(controller: _subject, label: 'Subject'),
        const SizedBox(height: 14.0),
        VTextField(controller: _body, label: 'Message', maxLines: 16),
        const SizedBox(height: 10.0),
        Text('Sent requests close themselves when the evidence that answers them arrives.', style: VT.muted(context, size: 11.0)),
        const SizedBox(height: 20.0),
        VButton(
          label: 'Approve & open in email',
          icon: Icons.send_outlined,
          size: VButtonSize.lg,
          fullWidth: true,
          loading: _busy,
          onPressed: _send,
        ),
        const SizedBox(height: 10.0),
        VButton(
          label: 'Copy message',
          icon: Icons.content_copy,
          kind: VButtonKind.secondary,
          fullWidth: true,
          onPressed: () => copyToClipboard(context, _body.text, what: 'Message copied'),
        ),
      ],
    );
  }
}

/// The Follow-ups tab.
class FollowUpsTab extends StatefulWidget {
  const FollowUpsTab({super.key, required this.matter, required this.receipts, this.onShowInThread});
  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final VoidCallback? onShowInThread;

  @override
  State<FollowUpsTab> createState() => _FollowUpsTabState();
}

class _FollowUpsTabState extends State<FollowUpsTab> {
  late final Stream<ThreadDoc?> _thread = matterThreadStream(widget.matter.reference);
  late final Stream<List<FollowUp>> _sent = matterFollowUpsStream(widget.matter.reference);
  final Set<String> _picked = {};
  bool _showDismissed = false;

  Future<void> _dismiss(Suggestion s) async {
    try {
      await _col.add({
        'firmID': currentFirmId(),
        'matterId': widget.matter.reference,
        'key': s.key,
        'kind': s.kind,
        'title': s.title,
        'request': s.request,
        'status': 'dismissed',
        'createdBy': currentUserUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _picked.remove(s.key));
    } catch (e) {
      if (mounted) showVToast(context, 'Could not dismiss: $e', error: true);
    }
  }

  Future<void> _custom() async {
    final s = Suggestion({
      'key': 'custom:${DateTime.now().millisecondsSinceEpoch}',
      'kind': 'custom',
      'title': 'Request',
      'request': '',
    });
    await showFollowUpComposer(context, matter: widget.matter, requests: [s]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ThreadDoc?>(
      stream: _thread,
      builder: (context, ts) => StreamBuilder<List<FollowUp>>(
        stream: _sent,
        builder: (context, fs) => _build(context, ts.data, fs.data ?? const [], loading: !ts.hasData && ts.connectionState == ConnectionState.waiting),
      ),
    );
  }

  Widget _build(BuildContext context, ThreadDoc? thread, List<FollowUp> records, {required bool loading}) {
    final c = VC.of(context);
    final acted = {for (final f in records) f.key: f};
    final suggestions = (thread?.suggestions ?? const <Suggestion>[]).where((s) => !acted.containsKey(s.key)).toList();
    final sent = records.where((f) => f.status == 'sent').toList();
    final answered = records.where((f) => f.status == 'resolved').toList();
    final dismissed = records.where((f) => f.status == 'dismissed').toList();
    final picked = suggestions.where((s) => _picked.contains(s.key)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Follow-ups', style: VT.h2(context, size: 20.0))),
            VButton(label: 'New request', icon: Icons.add, kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: _custom),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Specific requests for what\'s missing, drafted from the record. Nothing goes to the client until you approve it — it opens in your own email.',
          style: VT.muted(context),
        ),
        const SizedBox(height: 24.0),
        if (loading)
          const VLoading()
        else ...[
          Row(
            children: [
              Expanded(child: Text('SUGGESTED (${suggestions.length})', style: VT.eyebrow(context, color: c.mutedFg))),
              if (picked.isNotEmpty)
                VButton(
                  label: 'Review & send ${picked.length}',
                  icon: Icons.send_outlined,
                  size: VButtonSize.sm,
                  onPressed: () async {
                    final ok = await showFollowUpComposer(context, matter: widget.matter, requests: picked);
                    if (ok && mounted) setState(() => _picked.clear());
                  },
                ),
            ],
          ),
          const SizedBox(height: 10.0),
          if (suggestions.isEmpty)
            const VEmptyState(
              compact: true,
              icon: Icons.task_alt,
              title: 'Nothing missing right now',
              message: 'When the record has a gap, an undated run or an unreadable screenshot, a request for it appears here.',
            )
          else
            for (final s in suggestions) _suggestionCard(context, s),
          if (sent.isNotEmpty) ...[
            const SizedBox(height: 28.0),
            Text('SENT — WAITING FOR THE CLIENT (${sent.length})', style: VT.eyebrow(context, color: c.mutedFg)),
            const SizedBox(height: 10.0),
            for (final f in sent) _recordCard(context, f),
          ],
          if (answered.isNotEmpty) ...[
            const SizedBox(height: 28.0),
            Text('ANSWERED (${answered.length})', style: VT.eyebrow(context, color: c.mutedFg)),
            const SizedBox(height: 10.0),
            for (final f in answered) _recordCard(context, f),
          ],
          if (dismissed.isNotEmpty) ...[
            const SizedBox(height: 20.0),
            Align(
              alignment: Alignment.centerLeft,
              child: VButton(
                label: _showDismissed ? 'Hide dismissed' : 'Show ${dismissed.length} dismissed',
                kind: VButtonKind.link,
                size: VButtonSize.sm,
                onPressed: () => setState(() => _showDismissed = !_showDismissed),
              ),
            ),
            if (_showDismissed) for (final f in dismissed) _recordCard(context, f),
          ],
        ],
      ],
    );
  }

  IconData _icon(String kind) => switch (kind) {
        'gap' || 'cut_off' => Icons.more_horiz,
        'date' => Icons.event_outlined,
        'clarity' => Icons.blur_on,
        'resend' => Icons.refresh,
        'identity' => Icons.person_search_outlined,
        _ => Icons.mail_outline,
      };

  Widget _suggestionCard(BuildContext context, Suggestion s) {
    final c = VC.of(context);
    final on = _picked.contains(s.key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14.0, 14.0, 16.0, 14.0),
        decoration: BoxDecoration(
          color: on ? c.tealPale : c.card,
          border: Border.all(color: on ? c.teal : c.border),
          borderRadius: BorderRadius.circular(VR.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: on,
              activeColor: c.teal,
              onChanged: (v) => setState(() => v == true ? _picked.add(s.key) : _picked.remove(s.key)),
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(_icon(s.kind), size: 14.0, color: c.pending),
                    const SizedBox(width: 6.0),
                    Expanded(child: Text(s.title, style: VT.body(context, size: 13.0, weight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 6.0),
                  Text(s.request, style: VT.body(context, size: 13.0, height: 1.45)),
                  const SizedBox(height: 10.0),
                  Wrap(spacing: 14.0, runSpacing: 6.0, children: [
                    VButton(
                      label: 'Review & send',
                      size: VButtonSize.sm,
                      onPressed: () => showFollowUpComposer(context, matter: widget.matter, requests: [s]),
                    ),
                    if (s.kind != 'identity' && widget.onShowInThread != null)
                      VButton(label: 'See in thread', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: widget.onShowInThread),
                    VButton(label: 'Dismiss', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => _dismiss(s)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(BuildContext context, FollowUp f) {
    final c = VC.of(context);
    final (String label, Color tone) = switch (f.status) {
      'sent' => ('Sent', c.pending),
      'resolved' => ('Answered', c.verified),
      'dismissed' => ('Dismissed', c.mutedFg),
      _ => (f.status, c.mutedFg),
    };
    final when = f.status == 'resolved'
        ? 'answered ${fmtWhen(f.resolvedAt)}'
        : f.status == 'sent'
            ? 'sent ${fmtWhen(f.sentAt)}${f.sentByName.isNotEmpty ? ' by ${f.sentByName}' : ''}${f.recipient.isNotEmpty ? ' to ${f.recipient}' : ''}'
            : 'dismissed ${fmtWhen(f.createdAt)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              VBadge(label: label, bg: tone.withValues(alpha: 0.12), fg: tone, size: 10.0),
              const SizedBox(width: 8.0),
              Expanded(child: Text(f.title.isEmpty ? 'Request' : f.title, style: VT.body(context, size: 13.0, weight: FontWeight.w600))),
            ]),
            const SizedBox(height: 4.0),
            Text(when, style: VT.muted(context, size: 11.0)),
            if (f.status == 'sent') ...[
              const SizedBox(height: 8.0),
              Wrap(spacing: 14.0, children: [
                VButton(
                  label: 'Mark answered',
                  kind: VButtonKind.link,
                  size: VButtonSize.sm,
                  onPressed: () => f.ref.update({'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp(), 'resolvedBy': currentUserUid}),
                ),
                VButton(
                  label: 'Send again',
                  kind: VButtonKind.link,
                  size: VButtonSize.sm,
                  onPressed: () => showFollowUpComposer(context, matter: widget.matter, requests: [
                    Suggestion({'key': f.key, 'kind': f.kind, 'title': f.title, 'request': f.request.isNotEmpty ? f.request : f.title}),
                  ]),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
