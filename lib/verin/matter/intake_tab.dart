// Verin Legal — Intake Channel tab (guide §4).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../thread_merge.dart';
import '../verin_format.dart';
import '../verin_ui.dart';
import 'screenshot_upload_card.dart';

class IntakeTab extends StatefulWidget {
  const IntakeTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<IntakeTab> createState() => _IntakeTabState();
}

class _IntakeTabState extends State<IntakeTab> {
  final _draftController = TextEditingController();
  final _followUpKey = GlobalKey();
  bool _draftDirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draftController.text = _defaultDraft();
  }

  @override
  void didUpdateWidget(covariant IntakeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the suggested draft current until the user starts editing it.
    if (!_draftDirty) {
      final d = _defaultDraft();
      if (d != _draftController.text) _draftController.text = d;
    }
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  String _gapDescription() {
    final range = widget.matter.detectedGapRange;
    if (range.isNotEmpty) return range;
    final gaps = threadGapCount(mergeThread(widget.receipts));
    return gaps > 0 ? pluralize(gaps, 'break') + ' in the extracted thread' : '';
  }

  String _defaultDraft() {
    final saved = widget.matter.suggestedFollowUpDraft;
    if (saved.isNotEmpty) return saved;
    final gap = _gapDescription();
    if (gap.isEmpty) return '';
    final name = widget.matter.clientName.isNotEmpty ? widget.matter.clientName.split(' ').first : 'there';
    return 'Hi $name, there is a gap in the messages we have ($gap). '
        'Could you send screenshots of the conversation covering that period, including the date and time stamps?';
  }

  Future<void> _saveRequest() async {
    final text = _draftController.text.trim();
    if (text.isEmpty) {
      showVerinSnack(context, 'Write the request first.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await FollowUpRequestsRecord.collection.doc().set(createFollowUpRequestsRecordData(
            matterId: widget.matter.reference,
            draftText: text,
            status: 'approved',
            sentAt: getCurrentTimestamp,
          ));
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      showVerinSnack(
        context,
        'Request saved and copied. Paste it into your message to the client — automatic sending isn\'t connected yet.',
      );
      setState(() => _draftDirty = false);
    } catch (e) {
      if (mounted) showVerinSnack(context, 'Could not save the request: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _scrollToFollowUp() {
    final ctx = _followUpKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final m = widget.matter;
    final gap = _gapDescription();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Evidence Collection Channels', style: VerinText.section(context)),
          const SizedBox(height: 8.0),
          Text(
            'Clients forward messages and photos from whatever device they already own. Nothing to install.',
            style: VerinText.bodyMuted(context),
          ),
          if (gap.isNotEmpty) ...[
            const SizedBox(height: 24.0),
            VerinCard(
              color: t.warning5,
              borderColor: t.warning30,
              child: Row(
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(color: t.warning10, shape: BoxShape.circle),
                    child: Icon(Icons.history_toggle_off_rounded, color: t.onSurface, size: 28.0),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detected evidence gap: $gap', style: VerinText.title(context)),
                        const SizedBox(height: 4.0),
                        Text(
                          'A break in message continuity was detected. Ask the client for the missing messages.',
                          style: VerinText.small(context, color: t.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  VerinButton(
                    label: 'Request missing data',
                    icon: Icons.forward_to_inbox_rounded,
                    size: VerinButtonSize.small,
                    onPressed: _scrollToFollowUp,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32.0),
          LayoutBuilder(
            builder: (context, c) {
              final cards = [
                _ChannelCard(
                  icon: Icon(Icons.mail_rounded, color: t.primary, size: 24.0),
                  title: 'Email Forwarding',
                  description: 'Best for bulk exports, PDF attachments, and email threads.',
                  value: m.emailAddress,
                ),
                _ChannelCard(
                  icon: Icon(Icons.chat_outlined, color: t.primary, size: 24.0),
                  title: 'SMS/Text Message',
                  description: 'Best for quick mobile exports and text messages.',
                  value: m.smsNumber,
                ),
                _ChannelCard(
                  icon: FaIcon(FontAwesomeIcons.whatsapp, color: t.secondary, size: 24.0),
                  title: 'WhatsApp',
                  description: 'Best for forwarding WhatsApp chats and voice notes.',
                  value: m.whatsAppAddress,
                ),
              ];
              if (c.maxWidth < 900.0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 16.0), child: card)],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16.0),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 16.0),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 24.0),
          ScreenshotUploadCard(matter: m),
          const SizedBox(height: 24.0),
          VerinCard(
            key: _followUpKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Missing-evidence follow-up', style: VerinText.title(context)),
                          const SizedBox(height: 4.0),
                          Text(
                            'Draft a request for specific missing context or continuity gaps.',
                            style: VerinText.small(context),
                          ),
                        ],
                      ),
                    ),
                    VerinTag(
                      label: 'Recipient: ${orDash(m.clientName)}',
                      background: t.secondary10,
                      foreground: t.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _draftController,
                  minLines: 3,
                  maxLines: 8,
                  onChanged: (_) => _draftDirty = true,
                  style: VerinText.body(context),
                  decoration: InputDecoration(
                    labelText: 'Request draft',
                    hintText: 'Type the request to the client…',
                    helperText: 'Saved to this matter and copied so you can send it from your usual channel.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide(color: t.alternate),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    VerinButton(
                      label: 'Reset',
                      variant: VerinButtonVariant.ghost,
                      size: VerinButtonSize.small,
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                                _draftController.text = _defaultDraft();
                                _draftDirty = false;
                              }),
                    ),
                    const SizedBox(width: 16.0),
                    VerinButton(
                      label: 'Approve & copy request',
                      icon: Icons.send_rounded,
                      variant: VerinButtonVariant.primary,
                      size: VerinButtonSize.small,
                      loading: _saving,
                      onPressed: _saving ? null : _saveRequest,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          _QuarantineCard(matter: m),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
  });

  final Widget icon;
  final String title;
  final String description;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return VerinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(color: t.primary5, borderRadius: BorderRadius.circular(6.0)),
                child: icon,
              ),
              const SizedBox(width: 8.0),
              Expanded(child: Text(title, style: VerinText.title(context))),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(description, style: VerinText.small(context)),
          const SizedBox(height: 16.0),
          VerinCard(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 4.0, 4.0),
            radius: 6.0,
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value.isEmpty ? 'Not assigned yet' : value,
                    maxLines: 1,
                    style: VerinText.body(context, color: value.isEmpty ? t.secondaryText : t.primaryText),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: Icon(Icons.content_copy_rounded, size: 18.0, color: value.isEmpty ? t.alternate : t.primary),
                  onPressed: value.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: value));
                          if (context.mounted) showVerinSnack(context, 'Copied.');
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuarantineCard extends StatelessWidget {
  const _QuarantineCard({required this.matter});

  final MattersRecord matter;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return StreamBuilder<List<ItemsRecord>>(
      stream: queryItemsRecord(
        queryBuilder: (q) =>
            q.where('matterID', isEqualTo: matter.reference).where('isQuarantined', isEqualTo: true),
      ),
      builder: (context, snap) {
        final n = snap.data?.length ?? 0;
        return VerinCard(
          color: t.info5,
          borderColor: t.info20,
          child: Row(
            children: [
              Icon(Icons.security_rounded, color: t.tertiary, size: 24.0),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secure Quarantine Active', style: VerinText.titleSmall(context)),
                    const SizedBox(height: 4.0),
                    Text(
                      'Messages from unknown senders are quarantined for one-click approval rather than rejected.',
                      style: VerinText.small(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              VerinButton(
                label: snap.hasData ? 'View quarantine ($n)' : 'View quarantine',
                size: VerinButtonSize.small,
                onPressed: () => context.pushNamed('ReviewQueue'),
              ),
            ],
          ),
        );
      },
    );
  }
}
