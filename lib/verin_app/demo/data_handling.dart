// Checklist #9 — demo data-handling terms: the one-page note for a firm that
// sends a closed matter for a demo. Opens from the demo banner ("Data
// handling") so it can be shown on the call, and from Admin → Settings.
//
// Until counsel has reviewed it, admins see a DRAFT label. When counsel
// signs off, set kDemoTermsCounselReviewed = true and mark #9 Done.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import '../data/model.dart';

const bool kDemoTermsCounselReviewed = false;

/// Plain text of the note, for copying into an email to the firm.
const kDemoTermsSections = <(String, String)>[
  (
    'What we receive',
    'One closed matter that you choose: a folder, an export, or an email thread. Closed matters only — '
        'please do not send anything from an open or active matter. You can remove anything you prefer we not see before sending.',
  ),
  (
    'Where it goes',
    'Into a demonstration workspace that is separate from every firm\'s production workspace. '
        'Nothing you send is filed to, or visible from, any other firm\'s account.',
  ),
  (
    'How it is processed',
    'Each item is hashed (SHA-256) and logged on arrival. Only that hash — never the file — is sent to an independent '
        'time-stamp authority. Items are read by AI models used through their providers\' business APIs '
        '(Anthropic Claude for documents and images; Google Gemini on Vertex AI for audio and video), which do not use API '
        'content to train their models. Files are held in Google Cloud (United States) for the length of the demo.',
  ),
  (
    'Deletion',
    'As soon as the demo is done, we reset the demonstration workspace, which deletes every item, its readings, its hashes '
        'and the record built from it. We do not keep copies.',
  ),
  (
    'Confirmation',
    'We email you a deletion confirmation the same day, listing the matter and the number of items deleted.',
  ),
  (
    'Questions',
    'Write to support@verinlegal.com at any time, before or after the demo.',
  ),
];

String demoTermsPlainText() => [
      'Verin Legal — how we handle the closed matter you send for a demo',
      '',
      for (final (h, b) in kDemoTermsSections) ...['$h\n$b', ''],
    ].join('\n');

Future<void> showDataHandling(BuildContext context) => showVDrawer<void>(
      context,
      title: 'How we handle demo material',
      builder: (ctx) => const _DataHandlingBody(),
    );

class _DataHandlingBody extends StatelessWidget {
  const _DataHandlingBody();

  @override
  Widget build(BuildContext context) {
    final staff = VUser.current().isAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (staff && !kDemoTermsCounselReviewed) ...[
          const VNotice(
            tone: VNoticeTone.pending,
            text: 'DRAFT — not yet reviewed by counsel Only admins see this label.',
          ),
          const SizedBox(height: 16.0),
        ],
        Text('For firms that send a closed matter so we can demonstrate Verin on their own material.', style: VT.muted(context, size: 13.0)),
        const SizedBox(height: 16.0),
        for (final (h, b) in kDemoTermsSections) ...[
          Text(h, style: VT.body(context, weight: FontWeight.w600)),
          const SizedBox(height: 4.0),
          Text(b, style: VT.body(context, size: 13.5)),
          const SizedBox(height: 14.0),
        ],
        const SizedBox(height: 6.0),
        VButton(
          label: 'Copy as text for an email',
          icon: Icons.copy,
          kind: VButtonKind.tonal,
          onPressed: () => copyToClipboard(context, demoTermsPlainText(), what: 'Data-handling note copied'),
        ),
      ],
    );
  }
}
