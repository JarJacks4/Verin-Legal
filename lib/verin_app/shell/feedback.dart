// Verin Legal — send feedback (profile drawer → Send feedback, and from the
// Help & support drawer).
//
// Four fields and a Send button. Everything else the report needs — where they
// were, which matter, which browser — the app attaches itself, so a firm never
// has to describe their way back to a bug.
//
// What it attaches is deliberately narrow: ids, route, browser and screen. Not
// the matter name, not the client name, not a line of any message, not a file
// name. A support report must never become a second copy of someone's evidence.
// The screenshot is the only way client detail can reach us, so it is always
// the firm's explicit choice and the panel says so before they pick one.

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import '/verin/verin_api.dart';
import '/verin/verin_config.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

/// The last error the app showed, if any — attached to a report so a "it broke"
/// arrives with the message the user saw. Set by the error surfaces.
String? lastAppError;

const _kinds = <(String, String, IconData)>[
  ('broken', "Something's broken", Icons.error_outline),
  ('confusing', 'This was confusing', Icons.help_outline),
  ('wish', 'I wish it did', Icons.lightbulb_outline),
  ('question', 'Question', Icons.chat_bubble_outline),
];

const _impacts = <(String, String)>[
  ('blocked', 'Blocked me'),
  ('slowed', 'Slowed me down'),
  ('noting', 'Just noting it'),
];

Future<void> showFeedbackSheet(BuildContext context, {String? kind}) => showVDrawer<void>(
      context,
      title: 'Send feedback',
      width: 540.0,
      builder: (_) => _FeedbackBody(initialKind: kind),
    );

/// Route, matter and browser — the context a report needs and nothing more.
Map<String, dynamic> _context(BuildContext context) {
  String route = '';
  String matterId = '';
  try {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    route = uri.path;
    // Matter routes carry the id as a path segment: /matter/<id>/<tab>.
    final seg = uri.pathSegments;
    final i = seg.indexOf('matter');
    if (i >= 0 && i + 1 < seg.length) matterId = seg[i + 1];
  } catch (_) {}
  String browser = '';
  int? w, h;
  try {
    browser = web.window.navigator.userAgent;
    w = web.window.innerWidth;
    h = web.window.innerHeight;
  } catch (_) {}
  return {
    'route': route,
    'matterId': matterId,
    'browser': browser,
    if (w != null) 'screenW': w,
    if (h != null) 'screenH': h,
    if (lastAppError != null) 'lastError': lastAppError,
  };
}

class _FeedbackBody extends StatefulWidget {
  const _FeedbackBody({this.initialKind});

  final String? initialKind;

  @override
  State<_FeedbackBody> createState() => _FeedbackBodyState();
}

class _FeedbackBodyState extends State<_FeedbackBody> {
  late String _kind = widget.initialKind ?? 'broken';
  String _impact = 'slowed';
  final _text = TextEditingController();
  String? _shotName;
  String? _shotB64;
  String? _shotType;
  bool _busy = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickShot() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    final f = res?.files.firstOrNull;
    if (f == null || f.bytes == null) return;
    if (f.bytes!.length > 4 * 1024 * 1024) {
      setState(() => _error = 'That image is over 4 MB. Crop it and try again.');
      return;
    }
    final ext = (f.extension ?? 'png').toLowerCase();
    setState(() {
      _shotName = f.name;
      _shotB64 = base64Encode(f.bytes!);
      _shotType = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : ext == 'webp' ? 'image/webp' : 'image/png';
      _error = null;
    });
  }

  Future<void> _send() async {
    if (_text.text.trim().length < 3) {
      setState(() => _error = 'Tell us what happened, in a sentence or two.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await VerinApi.submitFeedback(
        kind: _kind,
        impact: _impact,
        text: _text.text.trim(),
        context: _context(context),
        shotBase64: _shotB64,
        shotType: _shotType,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _sent = true;
      });
    } on VerinApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    if (_sent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 20.0, color: c.verified),
              const SizedBox(width: 10.0),
              Expanded(child: Text('Sent. Thank you.', style: VT.h2(context, size: 18.0))),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            'It reached the help desk with the page you were on attached. If it is something we can fix quickly, you will usually see it fixed the next day.',
            style: VT.muted(context, size: 13.0),
          ),
          const SizedBox(height: 20.0),
          VButton(
            label: 'Send another',
            kind: VButtonKind.secondary,
            onPressed: () => setState(() {
              _sent = false;
              _text.clear();
              _shotB64 = null;
              _shotName = null;
            }),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tell us what happened and we will take it from there. The page you are on is attached automatically.',
            style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 18.0),

        Text('WHAT KIND OF THING IS THIS?', style: VT.eyebrow(context)),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            for (final (id, label, icon) in _kinds)
              VHover(
                onTap: () => setState(() => _kind = id),
                builder: (context, hovered) => AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
                  decoration: BoxDecoration(
                    color: _kind == id ? c.teal.withValues(alpha: 0.10) : (hovered ? c.secondary : c.card),
                    border: Border.all(color: _kind == id ? c.teal : c.border),
                    borderRadius: BorderRadius.circular(VR.lg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15.0, color: _kind == id ? c.teal : c.mutedFg),
                      const SizedBox(width: 7.0),
                      Text(label, style: VT.body(context, size: 12.5, weight: _kind == id ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18.0),

        VTextField(
          controller: _text,
          label: 'What happened?',
          hint: 'What were you trying to do, and what did it do instead?',
          maxLines: 5,
        ),
        const SizedBox(height: 18.0),

        Text('HOW MUCH DID THIS GET IN YOUR WAY?', style: VT.eyebrow(context)),
        const SizedBox(height: 8.0),
        Row(
          children: [
            for (final (id, label) in _impacts)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: VHover(
                  onTap: () => setState(() => _impact = id),
                  builder: (context, hovered) => AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: _impact == id ? c.teal.withValues(alpha: 0.10) : (hovered ? c.secondary : c.card),
                      border: Border.all(color: _impact == id ? c.teal : c.border),
                      borderRadius: BorderRadius.circular(VR.lg),
                    ),
                    child: Text(label, style: VT.body(context, size: 12.5, weight: _impact == id ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18.0),

        // Said plainly, because the firm's duty of confidentiality is theirs to
        // keep and a screenshot is the one thing here that can carry a client's
        // details to us.
        VPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.image_outlined, size: 15.0, color: c.mutedFg),
                  const SizedBox(width: 8.0),
                  Text('Screenshot (optional)', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                'A screenshot of a matter may show client information. Attach one only if the screen holds nothing confidential, or blur it first. Nothing else in this form carries client detail — we attach the page and the matter number, never names, messages or files.',
                style: VT.muted(context, size: 12.0),
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [
                  VButton(
                    label: _shotName == null ? 'Attach a screenshot' : 'Replace',
                    icon: Icons.attach_file,
                    kind: VButtonKind.secondary,
                    size: VButtonSize.sm,
                    onPressed: _pickShot,
                  ),
                  if (_shotName != null) ...[
                    const SizedBox(width: 10.0),
                    Expanded(child: Text(_shotName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.mono(context, size: 11.5))),
                    VIconButton(
                      icon: Icons.close,
                      size: 13.0,
                      tooltip: 'Remove',
                      onPressed: () => setState(() {
                        _shotName = null;
                        _shotB64 = null;
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (_error != null) ...[const SizedBox(height: 14.0), VErrorBox(message: _error!)],
        const SizedBox(height: 20.0),
        VButton(
          label: 'Send to Verin',
          icon: Icons.send_outlined,
          fullWidth: true,
          loading: _busy,
          loadingLabel: 'Sending…',
          onPressed: _busy ? null : _send,
        ),
        const SizedBox(height: 10.0),
        Center(
          child: Text('Goes to $kSupportEmail', style: VT.muted(context, size: 11.5)),
        ),
      ],
    );
  }
}
