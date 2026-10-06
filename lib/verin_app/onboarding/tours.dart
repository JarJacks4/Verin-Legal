// The words for every first-time walkthrough, in one place so they stay
// short and consistent. Targets are TourTarget ids placed on each page.

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';

import 'onboarding_screen.dart';
import 'tour.dart';

/// Sends someone who hasn't seen the welcome slides there first.
Future<bool> sendToIntroIfNew(BuildContext context) async {
  if (TourProgress.seen(kIntroTourId)) return true;
  if (context.mounted) context.goNamed(kOnboardingRoute);
  return false;
}

List<TourStep> mattersTour({required bool admin}) => [
      const TourStep(
        target: 'matters_new',
        icon: Icons.add_rounded,
        title: 'Start here: create a matter',
        body: 'Make one matter per case. Verin gives it a private intake address that you send to your client.',
      ),
      const TourStep(
        target: 'matters_list',
        icon: Icons.folder_open_outlined,
        title: 'Your matters at a glance',
        body: 'Each row shows how many items arrived, whether the record is intact, and whether it is synced to Clio. Click a matter to open it.',
      ),
      const TourStep(
        target: 'matters_search',
        icon: Icons.search_rounded,
        title: 'Find anything fast',
        body: 'Search by matter name, client or case number.',
      ),
      const TourStep(
        target: 'nav_review',
        icon: Icons.checklist_rounded,
        title: 'Review queue',
        body: 'When Verin is not sure how to read something, it waits here for a quick human check. Nothing is guessed silently.',
      ),
      const TourStep(
        target: 'nav_annotations',
        icon: Icons.sticky_note_2_outlined,
        title: 'Annotations',
        body: 'Every note your firm adds to thread messages, in one place — filter by tag or matter and jump back to the message.',
      ),
      if (admin)
        const TourStep(
          target: 'nav_admin',
          icon: Icons.dashboard_outlined,
          title: 'Admin console',
          body: 'Invite your team, connect Clio, set your exhibit template and see the value Verin is adding.',
        ),
      const TourStep(
        target: 'nav_profile',
        icon: Icons.person_outline_rounded,
        title: 'Your profile',
        body: 'Update your details, switch light or dark, or replay these tips any time.',
      ),
    ];

const matterTour = [
  TourStep(
    target: 'matter_header',
    icon: Icons.gavel_rounded,
    title: 'This is the matter',
    body: 'Name, client and case details. Everything on this page belongs to this matter only.',
  ),
  TourStep(
    target: 'matter_tabs',
    icon: Icons.east_rounded,
    title: 'Work from left to right',
    body: 'Intake → Receipts → Thread → Follow-ups → Exhibits. Integrity and Practice mgmt are there when you need them.',
  ),
  TourStep(
    target: 'matter_body',
    icon: Icons.inbox_outlined,
    title: 'First, share the intake address',
    body: 'Copy the address below and send it to your client. Anything they forward shows up in Receipts within moments.',
  ),
];

/// One tip the first time each tab is opened (Intake is covered above).
const Map<String, TourStep> tabTips = {
  'receipts': TourStep(
    target: 'matter_body',
    icon: Icons.description_outlined,
    title: 'Receipts',
    body: 'Every item that arrived, newest first, with its status. Click one to see details or check it against the original. You can also drop files here to add them yourself.',
  ),
  'thread': TourStep(
    target: 'matter_body',
    icon: Icons.forum_outlined,
    title: 'Thread',
    body: 'The conversation rebuilt in date order — your client on the right, the other side on the left. Click the file name on a bubble to see the original. Fix who is who in the names card.',
  ),
  'followups': TourStep(
    target: 'matter_body',
    icon: Icons.mark_email_unread_outlined,
    title: 'Follow-ups',
    body: 'Verin suggests what is missing. Open a request in your own email and send it; it closes by itself when the evidence arrives.',
  ),
  'exhibits': TourStep(
    target: 'matter_body',
    icon: Icons.folder_copy_outlined,
    title: 'Exhibits',
    body: 'Pick items, review redactions, and produce a Bates-stamped set with an index — ready to file or serve.',
  ),
  'integrity': TourStep(
    target: 'matter_body',
    icon: Icons.verified_user_outlined,
    title: 'Integrity',
    body: "Proof the record hasn't changed: each item's fingerprint, the chain linking them, and the independent time-stamp.",
  ),
  'practice': TourStep(
    target: 'matter_body',
    icon: Icons.apartment_outlined,
    title: 'Practice management',
    body: 'Send the finished record to Clio. An admin connects Clio once in Admin → Settings.',
  ),
};

const reviewTour = [
  TourStep(
    target: 'review_list',
    icon: Icons.checklist_rounded,
    title: 'Items waiting for a person',
    body: 'Unreadable files, or readings Verin is unsure about. Open one, compare it with the original, then confirm or correct it.',
  ),
];

/// Keyed by AdminNav name.
const Map<String, List<TourStep>> adminTours = {
  'dashboard': [
    TourStep(
      target: 'admin_nav',
      icon: Icons.dashboard_outlined,
      title: 'Admin console',
      body: 'Everything about your firm: billing, team, program and settings.',
    ),
    TourStep(
      target: 'admin_body',
      icon: Icons.insights_rounded,
      title: 'Firm dashboard',
      body: 'Intake volume, items waiting for review, and Measured value — the time Verin is saving your firm.',
    ),
    TourStep(
      target: 'admin_nav_team',
      icon: Icons.group_add_outlined,
      title: 'Invite your team',
      body: 'Add attorneys and staff. They join your firm with their own login.',
    ),
    TourStep(
      target: 'admin_nav_settings',
      icon: Icons.settings_outlined,
      title: 'Settings',
      body: 'Connect Clio, set your exhibit template and manage data retention.',
    ),
  ],
  'matters': [
    TourStep(target: 'admin_body', icon: Icons.folder_open_outlined, title: 'All firm matters', body: 'Every matter in the firm, for oversight. Click one to open it.'),
  ],
  'billing': [
    TourStep(target: 'admin_body', icon: Icons.credit_card, title: 'Billing & plan', body: 'Your plan, invoices and payment details.'),
  ],
  'team': [
    TourStep(
      target: 'admin_body',
      icon: Icons.group_outlined,
      title: 'Team',
      body: 'Invite people by email and choose who is an Admin. You can also copy an invite link to send yourself.',
    ),
  ],
  'program': [
    TourStep(target: 'admin_body', icon: Icons.emoji_events_outlined, title: 'Program', body: 'Your membership year and what it includes.'),
  ],
  'settings': [
    TourStep(
      target: 'admin_body',
      icon: Icons.settings_outlined,
      title: 'Settings',
      body: 'Connections like Clio, your exhibit template, API access and retention. Changes apply to the whole firm.',
    ),
  ],
};

const annotationsTour = [
  TourStep(
    target: 'ann_tags',
    icon: Icons.sell_outlined,
    title: 'Your notes by tag',
    body: 'Key evidence, Follow up, Question and Note. Click a tile to show only that tag; click it again to clear.',
  ),
  TourStep(
    target: 'ann_filters',
    icon: Icons.filter_list_rounded,
    title: 'Narrow it down',
    body: 'Switch between your notes and everyone\'s, pick a matter, or search the note, the message or the author.',
  ),
  TourStep(
    target: 'ann_list',
    icon: Icons.sticky_note_2_outlined,
    title: 'Edit, remove or jump back',
    body: 'Edit or delete your own notes here. "Open in thread" takes you to the conversation the note belongs to.',
    optional: true,
  ),
  TourStep(
    target: 'ann_copy',
    icon: Icons.content_copy,
    title: 'Take them with you',
    body: 'Copy what you are looking at, grouped by matter, to paste into a brief, a memo or an email.',
  ),
];

/// Sheet tips, keyed by tour id. Sheets find theirs by title
/// ([drawerTourForTitle]) or pass `tour:` to showVDrawer.
const Map<String, List<TourStep>> drawerTours = {
  'new_matter': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.create_new_folder_outlined,
      title: 'Create a matter',
      body: 'Name it, add the client and the cause number. Each matter gets its own record and its own hash chain.',
    ),
    TourStep(
      target: 'nm_phone',
      icon: Icons.smartphone,
      title: "Add the client's mobile",
      body: 'Texts from this number go straight into this matter. Adding their email means their messages are read right away.',
      optional: true,
    ),
    TourStep(
      target: 'nm_create',
      icon: Icons.check_rounded,
      title: 'Create it',
      body: 'Verin gives the matter its intake email and texting number straight away. Files you add here are hashed on arrival.',
      optional: true,
    ),
  ],
  'receipt': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.description_outlined,
      title: 'Everything about one item',
      body: 'What it is, who sent it, when it arrived and what Verin read from it. You can open the file exactly as received.',
    ),
    TourStep(
      target: 'receipt_quarantine',
      icon: Icons.shield_outlined,
      title: 'From someone new',
      body: 'Items from unknown senders wait here, stored and hashed but unread. Approve the sender to read them.',
      optional: true,
    ),
    TourStep(
      target: 'receipt_verify',
      icon: Icons.compare,
      title: 'Check it against the original',
      body: 'See the original beside what Verin read, with each line highlighted where it came from.',
      optional: true,
    ),
  ],
  'verify': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.compare,
      title: 'Original on one side, record on the other',
      body: 'Click a line to see where it sits in the original. If a word is wrong, correct it — the original never changes and every correction is kept.',
    ),
  ],
  'manual': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.edit_outlined,
      title: 'Add evidence yourself',
      body: 'For files you already have, or physical items like a printed letter or a USB drive. It is hashed and chained just like client uploads.',
    ),
  ],
  'followup_composer': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.mark_email_unread_outlined,
      title: 'Ask for what is missing',
      body: 'Check the wording, then open it in your own email to send. Verin marks it sent and closes it when the evidence arrives.',
    ),
  ],
  'production_editor': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.folder_copy_outlined,
      title: 'Build the exhibit set',
      body: 'Choose items and their order, review redactions, then produce. You get Bates-stamped PDFs, an index and a ZIP.',
    ),
  ],
  'redactions': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.format_strikethrough,
      title: 'Review redactions',
      body: 'Verin suggests things like account numbers and addresses. Drag to add a box, click one to remove it. Redactions are burned in, not just covered.',
    ),
  ],
  'who_is_who': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.people_outline,
      title: 'Who is who',
      body: "Give each sender a real name and say which side they're on. The thread rebuilds with your choices.",
    ),
  ],
  'certificate': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.workspace_premium_outlined,
      title: 'Certificate of preparation',
      body: 'A plain-language statement of how this record was received and kept, ready to attach to a filing.',
    ),
  ],
  'verify_tool': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.verified_outlined,
      title: 'Standalone verify tool',
      body: "Lets anyone — opposing counsel or the court — check the record's fingerprints without using Verin.",
    ),
  ],
  'integration_report': [
    TourStep(target: 'drawer_body', icon: Icons.apartment_outlined, title: 'Integration report', body: 'Exactly what was sent to Clio, and when.'),
  ],
  'clio_link': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.link_rounded,
      title: 'Match to a Clio matter',
      body: 'Find the same matter in Clio so finished records are filed there automatically.',
    ),
  ],
  'invite': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.group_add_outlined,
      title: 'Invite a team member',
      body: "Enter their work email and role. They get a link to join your firm's workspace.",
    ),
  ],
  'api': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.key_outlined,
      title: 'API access',
      body: 'Keys and a webhook for connecting your own systems. Treat keys like passwords.',
    ),
  ],
  'profile': [
    TourStep(target: 'drawer_body', icon: Icons.person_outline_rounded, title: 'Your profile', body: 'Your details, your firm and your plan.'),
    TourStep(
      target: 'profile_replay',
      icon: Icons.slideshow_outlined,
      title: 'Replay the walkthrough',
      body: "Shows the welcome slides and every page's tips again, whenever you like.",
      optional: true,
    ),
  ],
  'baseline_measure': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.timer_outlined,
      title: 'Measure the manual baseline',
      body: 'Time a typical task done by hand. Verin compares it with how long the same work takes now, to show real savings.',
    ),
  ],
  'baseline_rates': [
    TourStep(target: 'drawer_body', icon: Icons.payments_outlined, title: 'Baseline rates', body: 'The hourly rates used to turn time saved into dollars.'),
  ],
  'payment': [
    TourStep(target: 'drawer_body', icon: Icons.credit_card, title: 'Payment method', body: 'Change the card or account your firm is billed to.'),
  ],
};

const Map<String?, String> drawerTourForTitle = {
  'New matter': 'new_matter',
  'Receipt detail': 'receipt',
  'Verify against the original': 'verify',
  'Add manual entry': 'manual',
  'Review redactions': 'redactions',
  'Who is who': 'who_is_who',
  'Certificate of preparation': 'certificate',
  'Standalone verify tool': 'verify_tool',
  'Integration report': 'integration_report',
  'Match to a Clio matter': 'clio_link',
  'Invite team member': 'invite',
  'API access': 'api',
  'Profile': 'profile',
  'Measure the manual baseline': 'baseline_measure',
  'Baseline rates': 'baseline_rates',
  'Update payment method': 'payment',
};

// ---------------------------------------------------------------------------
// NFR demo workspace: the same tips, told to the person we're selling to —
// a family-law attorney or paralegal at a small or mid-size firm whose
// clients send evidence as screenshots, and who has to turn it into a
// record they can stand behind in a hearing. Each one names the sample data
// on screen and says what it saves them. (Keys = TourLauncher ids.)
// ---------------------------------------------------------------------------

const Map<String, List<TourStep>> demoTours = {
  'matters': [
    TourStep(
      target: 'matters_list',
      icon: Icons.folder_open_outlined,
      title: 'Three cases, already in motion',
      body: 'Reyes v. Reyes is a custody modification where the client has forwarded texts, an email and a school record over a month. Open it to see what Verin built from them — without anyone retyping a word.',
    ),
    TourStep(
      target: 'matters_new',
      icon: Icons.add_rounded,
      title: 'Open a case, start receiving',
      body: 'Each new matter gets its own intake address the day you open it. Clients forward evidence there — not to your cell phone or a shared inbox.',
    ),
    TourStep(
      target: 'nav_review',
      icon: Icons.checklist_rounded,
      title: 'Only what needs a person',
      body: 'Nobody reads every screenshot. Verin flags only the items that need a human: a hard-to-read line, an unknown sender, a text it can\'t match to a case.',
    ),
    TourStep(
      target: 'nav_annotations',
      icon: Icons.sticky_note_2_outlined,
      title: 'Case notes where the evidence is',
      body: 'Attorney and paralegal notes sit on the exact message they\'re about — then collect here, ready to paste into a brief or a prep memo.',
    ),
    TourStep(
      target: 'nav_admin',
      icon: Icons.insights_rounded,
      title: 'What it\'s worth to the firm',
      body: 'The value report shows hours saved against doing this by hand — the number a managing partner wants before renewal.',
      optional: true,
    ),
  ],
  'matter': [
    TourStep(
      target: 'matter_header',
      icon: Icons.gavel_rounded,
      title: 'A typical custody file',
      body: 'Usually this is a folder of screenshots on someone\'s phone and an afternoon of retyping. Here, every item is already received, sealed and read.',
    ),
    TourStep(
      target: 'matter_tabs',
      icon: Icons.east_rounded,
      title: 'The whole case, left to right',
      body: 'Intake → Receipts → Thread → Follow-ups → Exhibits. Open Thread next — that\'s where four screenshots become one conversation.',
    ),
    TourStep(
      target: 'matter_body',
      icon: Icons.inbox_outlined,
      title: 'Nothing for your client to install',
      body: 'Clients forward texts, photos and emails from the phone they already have, to this case\'s own address and number. You hand them one card, once.',
    ),
  ],
  'tab_receipts': [
    TourStep(
      target: 'matter_body',
      icon: Icons.verified_outlined,
      title: 'Sealed the moment it arrived',
      body: 'Every item was fingerprinted and independently time-stamped before anyone opened it. Open one to see who sent it, when, and what Verin read.',
    ),
  ],
  'tab_thread': [
    TourStep(
      target: 'matter_body',
      icon: Icons.forum_outlined,
      title: 'Four screenshots, one conversation',
      body: 'In date order, the repeated message removed, and the days with nothing flagged — the questions opposing counsel will ask. Click a file name on any bubble to see it on the original screenshot.',
    ),
  ],
  'tab_followups': [
    TourStep(
      target: 'matter_body',
      icon: Icons.mark_email_unread_outlined,
      title: 'Ask before the hearing, not at it',
      body: 'That gap became a ready-to-send request to the client. It opens in your own email, and closes itself when the missing texts arrive.',
    ),
  ],
  'tab_exhibits': [
    TourStep(
      target: 'matter_body',
      icon: Icons.folder_copy_outlined,
      title: 'Exhibits without the afternoon',
      body: 'Pick items, check the suggested redactions — a child\'s name, account numbers — and produce Bates-stamped PDFs with an index. Try it on the Carter bank statement.',
    ),
  ],
  'tab_integrity': [
    TourStep(
      target: 'matter_body',
      icon: Icons.verified_user_outlined,
      title: '"How do we know it wasn\'t changed?"',
      body: 'Each item\'s fingerprint and time-stamp, linked in order. Give opposing counsel the verify tool and they can check the record themselves.',
    ),
  ],
  'tab_practice': [
    TourStep(
      target: 'matter_body',
      icon: Icons.apartment_outlined,
      title: 'It ends up in Clio',
      body: 'Finished records file into the same matter in Clio, so nothing lives in two places.',
    ),
  ],
  'review': [
    TourStep(
      target: 'review_list',
      icon: Icons.checklist_rounded,
      title: 'A few minutes, not a few hours',
      body: 'Here: a line Verin couldn\'t read with confidence, an email from the client\'s sister held until you approve it, and a text from a number no case knows. Each is one click.',
    ),
  ],
  'annotations': [
    TourStep(
      target: 'ann_tags',
      icon: Icons.sell_outlined,
      title: 'Your team\'s case notes',
      body: 'Key evidence, follow-ups and open questions from every case. Click a tile to focus — "Follow up" is your to-do list before the hearing.',
    ),
    TourStep(
      target: 'ann_list',
      icon: Icons.sticky_note_2_outlined,
      title: 'Back to the exact message',
      body: '"Open in thread" jumps to the message the note is about, beside the original screenshot.',
      optional: true,
    ),
    TourStep(
      target: 'ann_copy',
      icon: Icons.content_copy,
      title: 'Straight into your brief',
      body: 'Copy the notes you\'re looking at, grouped by case, and paste them into a brief or prep memo.',
    ),
  ],
  'admin_dashboard': [
    TourStep(
      target: 'admin_body',
      icon: Icons.insights_rounded,
      title: 'The number for the partners',
      body: 'Measured value: hours Verin saved this firm over the last quarter, against reading, retyping and organizing the same evidence by hand.',
    ),
    TourStep(
      target: 'admin_nav_team',
      icon: Icons.group_add_outlined,
      title: 'Bring in the paralegals',
      body: 'Invite your team; everyone works from the same record, with their own login.',
    ),
  ],
  'sheet_receipt': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.description_outlined,
      title: 'One item, fully accounted for',
      body: 'Who sent it, when it arrived, its fingerprint, and what Verin read — the questions you\'d be asked about it on the stand.',
    ),
    TourStep(
      target: 'receipt_quarantine',
      icon: Icons.shield_outlined,
      title: 'Grandma forwarded photos',
      body: 'Unknown senders aren\'t rejected — they wait here, stored and sealed, until you approve them. Try it.',
      optional: true,
    ),
    TourStep(
      target: 'receipt_verify',
      icon: Icons.compare,
      title: 'See it on the original',
      body: 'Every line traced back to where it sits on the screenshot.',
      optional: true,
    ),
  ],
  'sheet_verify': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.compare,
      title: 'Check the reading in seconds',
      body: 'Click a line and it lights up on the original. Fix a word if you need to — the original never changes, and every correction is kept.',
    ),
  ],
};
