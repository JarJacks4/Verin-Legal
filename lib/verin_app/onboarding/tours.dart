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
