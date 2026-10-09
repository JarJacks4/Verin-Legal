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
        body: 'Search by matter name, client or case number — or any word in the evidence. Matching messages and documents from every case show under In the evidence.',
      ),
      const TourStep(
        target: 'matters_hearings',
        icon: Icons.event_outlined,
        title: 'Hearings coming up',
        body: 'Every hearing or filing date in the next 30 days, across all your cases. Anything within a week is highlighted.',
        optional: true,
      ),
      const TourStep(
        target: 'nav_review',
        icon: Icons.checklist_rounded,
        title: 'Review queue',
        body: 'When Verin is not sure how to read something, it waits here for a quick human check. Nothing is guessed silently.',
      ),
      if (admin)
        const TourStep(
          target: 'nav_admin',
          icon: Icons.dashboard_outlined,
          title: 'Admin console',
          body: 'Invite your team, connect Clio, set your exhibit template and see the value Verin is adding.',
        ),
    ];

const matterTour = [
  TourStep(
    target: 'matter_header',
    icon: Icons.gavel_rounded,
    title: 'This is the matter',
    body: 'Name, client and case details, and the next hearing date — click it to add or change dates. Everything on this page belongs to this matter only.',
  ),
  TourStep(
    target: 'matter_tabs',
    icon: Icons.east_rounded,
    title: 'Work from left to right',
    body: 'Intake → Receipts → Thread → Timeline → Follow-ups → Exhibits. Integrity and Practice mgmt are there when you need them.',
  ),
  TourStep(
    target: 'matter_actions',
    icon: Icons.inventory_2_outlined,
    title: 'Everything you do with the record',
    body: 'Deliver it to Clio or download it, export it to Word, build this week\'s digest or a hearing packet, import a closed matter, or check that a file matches an item exactly.',
    optional: true,
  ),
];

const intakeTour = [
  TourStep(
    target: 'intake_channels',
    icon: Icons.inbox_outlined,
    title: 'This case\'s own address and number',
    body: 'Anything the client sends here is filed to this matter only. The switches turn email or text intake off for this case.',
  ),
  TourStep(
    target: 'intake_card',
    icon: Icons.assignment_outlined,
    title: 'Give the client one card',
    body: 'Copy instructions for the client puts the address, number, what to send for this kind of case and a short how-to on your clipboard — in English, or in Spanish with Copiar en español. Paste it into an email or text to them.',
    optional: true,
  ),
  TourStep(
    target: 'intake_who',
    icon: Icons.person_search_outlined,
    title: 'Tell Verin who the client is',
    body: 'Add their mobile so texts land in this case, and their email so messages are read straight away. Anyone else is held for one-click approval.',
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
  'timeline': TourStep(
    target: 'matter_body',
    icon: Icons.timeline,
    title: 'Timeline',
    body: 'Every item on one dated line, with both dates: the date the item carries and the day it reached you. Before and after shows what the client sent next to the record Verin assembled from it — every line cites its item, and gaps stay visible.',
  ),
  'thread': TourStep(
    target: 'matter_body',
    icon: Icons.forum_outlined,
    title: 'Thread',
    body: 'The conversation assembled in date order — your client on the right, the other side on the left. Click the file name on a bubble to see the original. Set who is who in the names card, ask for a cited summary where every line links to its messages, download the chronology for Excel, and use Annotate on any bubble to add a note — every note also collects on the Annotations page.',
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
    body: 'Pick items, review redactions, and produce a Bates-stamped set with an index — ready to file or serve. A finished set can start a draft declaration about when each item was received.',
  ),
  'integrity': TourStep(
    target: 'matter_body',
    icon: Icons.verified_user_outlined,
    title: 'Integrity',
    body: "Shows each item is exactly what was received: its fingerprint, the chain linking them, and the independent time-stamp.",
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
    target: 'review_unrouted',
    icon: Icons.sms_outlined,
    title: 'Texts from numbers no case knows',
    body: 'They are already stored and fingerprinted. Choose File to matter, and leave "File future texts here" on so the next one goes straight in.',
    optional: true,
  ),
  TourStep(
    target: 'review_list',
    icon: Icons.checklist_rounded,
    title: 'Items waiting for a person',
    body: 'Unreadable files, or readings Verin is unsure about. Open one, compare it with the original, then confirm the reading or note a discrepancy.',
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
      body: 'Intake volume, items waiting for review, accuracy against our targets, and Measured value — the time Verin is saving your firm.',
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
    TourStep(
      target: 'settings_records',
      icon: Icons.move_to_inbox_outlined,
      title: 'Delivery and digests',
      body: "Verin delivers each record to your firm's system, then removes its copy of the files. Choose nightly Clio delivery, weekly digests and whether everyone must use two-step sign-in.",
      optional: true,
    ),
    TourStep(
      target: 'settings_baseline',
      icon: Icons.lock_clock_outlined,
      title: 'Your starting point',
      body: 'Your Record Lag before Verin, captured when you connect Clio and locked, so every later comparison is against the same number.',
      optional: true,
    ),
    TourStep(
      target: 'settings_reports',
      icon: Icons.query_stats_rounded,
      title: 'Reports for the partners',
      body: 'A Record Lag Audit over any matters, the monthly firm report and this week\'s cost to serve.',
      optional: true,
    ),
    TourStep(
      target: 'settings_demo',
      icon: Icons.slideshow_outlined,
      title: 'Demo workspace',
      body: 'For showing Verin to other firms: use a separate account, make it a demo here, and reset it between demos.',
      optional: true,
    ),
  ],
};

const annotationsTour = [
  TourStep(
    target: 'ann_tags',
    icon: Icons.label_outline,
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
    icon: Icons.comment_outlined,
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
  'practice_packet': [
    TourStep(
      target: 'packet_kinds',
      icon: Icons.gavel_outlined,
      title: 'One packet per practice',
      body: 'Pick the packet for this kind of case. Flagged personal details are masked, and you confirm redactions before anything is exported.',
    ),
  ],
  'closed_import': [
    TourStep(
      target: 'import_pick',
      icon: Icons.unarchive_outlined,
      title: 'A whole closed matter at once',
      body: 'Choose a ZIP of the folder, an email export or the files themselves. Each file becomes its own fingerprinted, time-stamped item.',
    ),
    TourStep(
      target: 'import_counts',
      icon: Icons.insights_rounded,
      title: 'The four numbers',
      body: 'Items received, distinct dated items, conversations rebuilt and items flagged for a person. Refresh while Verin reads.',
    ),
  ],
  'baseline_entry': [
    TourStep(
      target: 'baseline_rows',
      icon: Icons.edit_calendar_outlined,
      title: 'Two dates per item',
      body: 'For each sample item: the date it was created, then the date it entered your file. Ten or more lines; the median is locked as your baseline.',
    ),
  ],
  'lag_audit': [
    TourStep(
      target: 'audit_matters',
      icon: Icons.query_stats_rounded,
      title: 'Pick the matters',
      body: 'Closed matters work best: the audit shows how late material reached the firm, matter by matter, with every item listed.',
    ),
  ],
  'verify_file': [
    TourStep(
      target: 'verify_pick',
      icon: Icons.fingerprint,
      title: 'Is this the same file?',
      body: 'Choose any copy. Its fingerprint is computed on this computer and compared with every item in the matter. A match means the bytes are identical.',
    ),
  ],
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
    TourStep(
      target: 'receipt_access',
      icon: Icons.visibility_outlined,
      title: 'Who has opened it',
      body: 'Admins see each time someone on the team opened or checked this item.',
      optional: true,
    ),
  ],
  'verify': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.compare,
      title: 'Original on one side, record on the other',
      body: 'Click a line to see where it sits in the original. If a word was misread, note the discrepancy; if the date or its place in the thread is wrong, say so with Date is wrong or Wrong place in thread. The original is never changed and every reviewer note is kept.',
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
      body: "Give each sender a real name and say which side they're on. The thread is re-assembled with your choices.",
    ),
  ],
  'certificate': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.verified_outlined,
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
      icon: Icons.vpn_key_outlined,
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
  'demo_run': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.timer_outlined,
      title: 'Log this demo',
      body: 'Items in, items processed and pipeline time are measured for you. Add the firm, the review and write-back times, and their estimate of hours by hand — the log gives you real numbers to quote.',
    ),
  ],
  'data_handling': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.privacy_tip_outlined,
      title: 'What happens to their files',
      body: 'Show this when a firm asks before sending a closed matter. Copy it into an email so they have it in writing.',
    ),
  ],
  'declaration': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.history_edu_outlined,
      title: 'A starting draft',
      body: 'Filled in from this production: each exhibit, when it arrived, its fingerprint and time-stamp. It covers the receipt records only. Complete the bracketed fields and review it before signing.',
    ),
  ],
  'help': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.support_agent_outlined,
      title: 'Help when you need it',
      body: 'How to reach us, when, and how fast we answer — plus short how-tos for the things you do most.',
    ),
  ],
  'hearings': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.event_outlined,
      title: 'Hearing and filing dates',
      body: 'Add each date once. The next one shows under the matter name, and the Matters list shows everything in the next 30 days.',
    ),
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
  'End demo and log it': 'demo_run',
  'How we handle demo material': 'data_handling',
  'Draft declaration': 'declaration',
  'Hearing and filing dates': 'hearings',
  'Help & support': 'help',
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
      title: 'Seven cases, already in motion',
      body: 'One sample case for every practice — family, personal injury, immigration, civil and criminal. Reyes v. Reyes is a custody modification where the client has forwarded texts, an email and a school record over a month. Open it to see what Verin built from them — without anyone retyping a word.',
    ),
    TourStep(
      target: 'matters_search',
      icon: Icons.search,
      title: 'Find a case — or a word in the evidence',
      body: 'Type a client or case name — here, Reyes. Try a word like "adjuster" and the matching texts from every case show under In the evidence.',
      optional: true,
    ),
    TourStep(
      target: 'matters_hearings',
      icon: Icons.event_outlined,
      title: 'What\'s on the calendar',
      body: 'The Reyes custody hearing and the Holloway pretrial conference, with how many days are left. Dates within a week turn amber.',
      optional: true,
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
      icon: Icons.comment_outlined,
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
    TourStep(
      target: 'demo_strip',
      icon: Icons.restart_alt,
      title: 'Sample data, reset any time',
      body: 'Everything here is fictional. Time this demo logs how long it takes and what came through; Data handling answers "what happens to our files?". Reset demo puts it all back for the next firm; Replay tips starts this walkthrough again.',
      optional: true,
    ),
  ],
  'matter': [
    TourStep(
      target: 'matter_header',
      icon: Icons.gavel_rounded,
      title: 'A typical custody file',
      body: 'Usually this is a folder of screenshots on someone\'s phone and an afternoon of retyping. Here, every item is already received, fingerprinted and read.',
    ),
    TourStep(
      target: 'matter_tabs',
      icon: Icons.east_rounded,
      title: 'The whole case, left to right',
      body: 'Intake → Receipts → Thread → Follow-ups → Exhibits. Start with Intake below, then open Thread — that\'s where four screenshots become one conversation.',
    ),
  ],
  'tab_timeline': [
    TourStep(
      target: 'timeline_status',
      icon: Icons.speed_rounded,
      title: 'The case at a glance',
      body: 'How many items, how late they reached the firm (Record Lag), what needs a person and what\'s new since you last looked.',
    ),
    TourStep(
      target: 'timeline_switch',
      icon: Icons.compare_arrows,
      title: 'Before and after',
      body: 'Left: what Dana actually sent, in the order it came in. Right: the record Verin assembled — every line cites its screenshot, and the gaps are shown, not hidden.',
    ),
    TourStep(
      target: 'before_after',
      icon: Icons.layers_outlined,
      title: 'Nothing retyped',
      body: 'This is the difference a partner sees in one glance: a phone full of screenshots on one side, a dated, cited record on the other.',
      optional: true,
    ),
  ],
  'tab_intake': [
    TourStep(
      target: 'intake_channels',
      icon: Icons.inbox_outlined,
      title: 'One address and one number per case',
      body: 'Dana forwards texts, photos and emails here from her own phone. Nothing to install, no login — and nothing lands on your cell.',
    ),
    TourStep(
      target: 'intake_demo',
      icon: Icons.send_rounded,
      title: 'Watch one arrive',
      body: 'Watch one come in now: in a few seconds it\'s stored, fingerprinted, time-stamped and read. Open Receipts or Thread afterwards to see it.',
      optional: true,
    ),
    TourStep(
      target: 'intake_card',
      icon: Icons.assignment_outlined,
      title: 'The only thing you send the client',
      body: 'Copy instructions for the client gives them the address, number and what to send for this kind of case — in English or Spanish.',
      optional: true,
    ),
    TourStep(
      target: 'intake_who',
      icon: Icons.person_search_outlined,
      title: 'Grandma forwards photos too',
      body: 'Dana\'s mobile and email are known, so her messages are read right away. Anyone else is stored and held for your one-click approval.',
    ),
  ],
  'tab_receipts': [
    TourStep(
      target: 'matter_body',
      icon: Icons.verified_outlined,
      title: 'Fingerprinted the moment it arrived',
      body: 'Every item was fingerprinted and independently time-stamped before anyone opened it. Open one to see who sent it, when, and what Verin read.',
    ),
  ],
  'tab_thread': [
    TourStep(
      target: 'matter_body',
      icon: Icons.forum_outlined,
      title: 'Four screenshots, one conversation',
      body: 'In date order, the repeated message shown once (both copies kept), and the days with nothing flagged — the questions opposing counsel will ask. Click a file name on any bubble to see it on the original screenshot. Cited summary writes a short summary where every line links back to its messages.',
    ),
    TourStep(
      target: 'matter_body',
      icon: Icons.comment_outlined,
      title: 'Annotate the moments that matter',
      body: 'Use Annotate on any bubble to tag it Key evidence, Follow up or Question. The notes from this case are already here — and every note also collects on the Annotations page.',
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
      body: 'Pick items, check the suggested redactions — a child\'s name, account numbers — and produce Bates-stamped PDFs with an index. Try it on the Carter bank statement. Once produced, Draft declaration fills in when each exhibit arrived.',
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
      target: 'practice_cards',
      icon: Icons.apartment_outlined,
      title: 'Clio, MyCase or Smokeball',
      body: 'Connected once by an admin, then each case is matched to its matter there. These use sample accounts in the demo.',
    ),
    TourStep(
      target: 'practice_send',
      icon: Icons.upload_rounded,
      title: 'Send the finished record',
      body: 'Watch: the record builds, uploads and files into the matter\'s Documents in Clio — no downloading and re-uploading.'
    ),
    TourStep(
      target: 'practice_log',
      icon: Icons.history_rounded,
      title: 'Every filing, accounted for',
      body: 'Each version sent, where it went and when. Earlier versions stay in Clio; nothing is overwritten.',
    ),
  ],
  'review': [
    TourStep(
      target: 'review_unrouted',
      icon: Icons.sms_outlined,
      title: 'A text from a number no case knows',
      body: 'Dana\'s mom texted the firm\'s number. It\'s already stored and fingerprinted — File to matter puts it in Reyes, and future texts from her go straight there.',
      optional: true,
    ),
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
      icon: Icons.label_outline,
      title: 'Your team\'s case notes',
      body: 'Key evidence, follow-ups and open questions from every case. Clicking a tile focuses the list — here, Key evidence. "Follow up" is your to-do list before the hearing.',
    ),
    TourStep(
      target: 'ann_list',
      icon: Icons.comment_outlined,
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
  'admin_settings': [
    TourStep(
      target: 'settings_profile',
      icon: Icons.business_outlined,
      title: 'Your firm, set up once',
      body: 'Primary contact, billing email and bar jurisdiction — filled in here for the sample firm. They appear on every record Verin produces.',
    ),
    TourStep(
      target: 'settings_exhibits',
      icon: Icons.folder_copy_outlined,
      title: 'Exhibits in your house style',
      body: 'Bates prefix, confidentiality legend and index title, filled in with samples. Every production uses them, so nobody re-stamps a page by hand.',
    ),
    TourStep(
      target: 'settings_demo',
      icon: Icons.slideshow_outlined,
      title: 'Start each demo fresh',
      body: 'Reset sample data puts the seven sample cases back the way they started. Your demo-run log stays.',
      optional: true,
    ),
  ],
  'sheet_production_editor': [
    TourStep(
      target: 'prod_name',
      icon: Icons.folder_copy_outlined,
      title: 'Name the production',
      body: 'A sample name is filled in. Next, tick the items to produce and set their order — exhibit numbers and Bates labels follow it.',
    ),
    TourStep(
      target: 'drawer_body',
      icon: Icons.gavel_outlined,
      title: 'One click to a court-ready set',
      body: 'Produce gives you Bates-stamped PDFs, an index and a ZIP. The originals are never changed.',
    ),
  ],
  'sheet_new_matter': [
    TourStep(
      target: 'nm_fields',
      icon: Icons.create_new_folder_outlined,
      title: 'Opening a new case',
      body: 'Matter name, client and cause number — we\'ve filled in a sample custody case so you can see it.',
    ),
    TourStep(
      target: 'nm_phone',
      icon: Icons.smartphone,
      title: 'The client\'s phone and email',
      body: 'Her texts will land in this case automatically, and her emails are read right away.',
    ),
    TourStep(
      target: 'nm_create',
      icon: Icons.check_rounded,
      title: 'One click and it\'s receiving',
      body: 'Create matter gives the case its own address and number straight away. Try it — Reset demo clears it later.',
      optional: true,
    ),
  ],
  'sheet_manual': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.edit_outlined,
      title: 'Evidence that arrives another way',
      body: 'A printout at the front desk, a USB drive, a file on your laptop — it gets the same fingerprint and time-stamp as a forwarded text.',
    ),
    TourStep(
      target: 'me_fields',
      icon: Icons.inventory_2_outlined,
      title: 'Who gave it to you, and how',
      body: 'Source and custody notes, filled in here for a sample pickup log. They stay with the item in the record.',
    ),
  ],
  'sheet_invite': [
    TourStep(
      target: 'invite_fields',
      icon: Icons.group_add_outlined,
      title: 'Bring in a paralegal',
      body: 'Name and work email, filled in with a sample. They get a link and join your firm\'s workspace with their own login.',
    ),
  ],
  'sheet_baseline_measure': [
    TourStep(
      target: 'measure_fields',
      icon: Icons.timer_outlined,
      title: 'Measure the old way once',
      body: 'Time a paralegal transcribing a sample by hand — here, 40 messages in 18 minutes. Verin compares every case against it.',
    ),
  ],
  'sheet_api': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.vpn_key_outlined,
      title: 'For firms with their own systems',
      body: 'Keys and a webhook for connecting a document system or data warehouse. Most firms never need this.',
    ),
    TourStep(
      target: 'api_webhook',
      icon: Icons.link_rounded,
      title: 'Where Verin sends updates',
      body: 'A sample address is filled in — Verin would notify it whenever evidence arrives or a record changes.',
      optional: true,
    ),
  ],
  'sheet_redactions': [
    TourStep(
      target: 'drawer_body',
      icon: Icons.format_strikethrough,
      title: 'Redactions you review, not guess',
      body: 'Verin suggests a child\'s name, account numbers and addresses. Drag on the page to add a box; click one to remove it.',
    ),
    TourStep(
      target: 'redact_add',
      icon: Icons.text_fields_rounded,
      title: 'Or redact a phrase everywhere',
      body: 'Type the exact text — here, a student ID — and it\'s blacked out wherever it appears in the exhibit.',
      optional: true,
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
      body: 'Unknown senders aren\'t rejected — they wait here, stored and fingerprinted, until you approve them. Try it.',
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
      body: 'Click a line and it lights up on the original. If a word was misread, note it — the original is never changed, and every reviewer note is kept with your name.',
    ),
  ],
};
