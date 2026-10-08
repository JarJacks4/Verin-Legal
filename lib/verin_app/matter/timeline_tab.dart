// Timeline tab — the live Standing Record (checklist #21, #69, #5).
//
//   Status strip      items, needs a person, gaps, Record Lag with its trend,
//                     open requests, and what's new since you last looked.
//   Timeline          every item on one dated line, with both dates (the
//                     item's own date and when it reached the firm), hearings
//                     as milestones, and flags.
//   Before and after  as-sent items on one side, the Standing Record on the
//                     other: every assembled line cites the item it came
//                     from; gaps and unreadable items stay visible.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/record_ext.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../onboarding/tour.dart' show TourTarget;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import 'hearings.dart';

class TimelineTab extends StatefulWidget {
  const TimelineTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  late final Stream<ThreadDoc?> _thread = matterThreadStream(widget.matter.reference);
  late final Stream<List<FollowUp>> _requests = matterFollowUpsStream(widget.matter.reference);
  bool _beforeAfter = false;
  DateTime? _lastView;

  @override
  void initState() {
    super.initState();
    _markViewed();
  }

  /// "New since your last view": read the last visit, then record this one.
  Future<void> _markViewed() async {
    final uid = currentUserUid;
    if (uid.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      final snap = await ref.get();
      final views = snap.data()?['matterViews'];
      final v = views is Map ? views[widget.matter.reference.id] : null;
      if (mounted && v is Timestamp) setState(() => _lastView = v.toDate());
      await ref.set({
        'matterViews': {widget.matter.reference.id: FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    } catch (_) {
      // Not essential: the strip simply leaves out "new since".
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ThreadDoc?>(
      stream: _thread,
      builder: (context, ts) {
        final thread = ts.data;
        return StreamBuilder<List<FollowUp>>(
          stream: _requests,
          builder: (context, fs) {
            final open = (fs.data ?? const <FollowUp>[]).where((f) => f.status == 'sent').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TourTarget(
                  id: 'timeline_status',
                  child: _StatusStrip(receipts: widget.receipts, thread: thread, openRequests: open, lastView: _lastView),
                ),
                const SizedBox(height: 20.0),
                TourTarget(
                  id: 'timeline_switch',
                  // Demo walkthrough: open the before-and-after view as the tip reaches it.
                  onDemoTour: () => Future.delayed(const Duration(milliseconds: 700), () {
                    if (mounted) setState(() => _beforeAfter = true);
                  }),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, icon: Icon(Icons.timeline, size: 16.0), label: Text('Timeline')),
                        ButtonSegment(value: true, icon: Icon(Icons.compare_arrows, size: 16.0), label: Text('Before and after')),
                      ],
                      selected: {_beforeAfter},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _beforeAfter = s.first),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (_beforeAfter)
                  _BeforeAfter(matter: widget.matter, receipts: widget.receipts, thread: thread)
                else
                  _Timeline(matter: widget.matter, receipts: widget.receipts, lastView: _lastView),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Status strip
// ---------------------------------------------------------------------------

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.receipts, required this.thread, required this.openRequests, required this.lastView});

  final List<ReceiptsRecord> receipts;
  final ThreadDoc? thread;
  final int openRequests;
  final DateTime? lastView;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final now = DateTime.now();
    final lag = medianDays(recordLagsDays(receipts.where((r) => !r.isDuplicate)));
    // Trend: this month's arrivals against the 30 days before.
    final recent = receipts.where((r) => !r.isDuplicate && r.receivedAt != null && now.difference(r.receivedAt!).inDays < 30);
    final prior = receipts.where((r) => !r.isDuplicate && r.receivedAt != null && now.difference(r.receivedAt!).inDays >= 30 && now.difference(r.receivedAt!).inDays < 60);
    final lagNow = medianDays(recordLagsDays(recent));
    final lagPrior = medianDays(recordLagsDays(prior));
    String trend = '';
    if (lagNow != null && lagPrior != null) {
      final d = lagNow - lagPrior;
      trend = d == 0 ? 'same as the month before' : (d < 0 ? '${-d} d faster than the month before' : '$d d slower than the month before');
    }
    final review = receipts.where((r) => const ['Uncertain', 'Unreadable', 'Quarantined'].contains(r.classificationLabel)).length;
    final gaps = (thread?.stats['gaps'] as num?)?.toInt() ?? 0;
    final fresh = lastView == null ? null : receipts.where((r) => r.receivedAt != null && r.receivedAt!.isAfter(lastView!)).length;

    Widget tile(String label, String value, {String? note, Color? tone}) => Container(
          constraints: const BoxConstraints(minWidth: 150.0),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: c.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(), style: VT.eyebrow(context, size: 10.5)),
              const SizedBox(height: 6.0),
              Text(value, style: VT.h1(context, size: 24.0, color: tone)),
              if (note != null && note.isNotEmpty) Text(note, style: VT.muted(context, size: 11.5)),
            ],
          ),
        );

    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        tile('Items', '${receipts.length}', note: fresh == null ? null : (fresh == 0 ? 'nothing new since you last looked' : '$fresh new since you last looked')),
        tile('Record Lag', lag == null ? '—' : '$lag d', note: trend.isNotEmpty ? trend : 'median, item date → received'),
        tile('Needs a person', '$review', tone: review > 0 ? c.pending : null, note: 'review queue'),
        tile('Gaps', '$gaps', note: 'continuity not shown'),
        tile('Open requests', '$openRequests', note: 'waiting on the client'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

class _Row {
  _Row.item(this.receipt, this.at, this.dated) : hearing = null;
  _Row.hearing(Hearing h)
      : hearing = h,
        receipt = null,
        at = h.at,
        dated = true;

  final ReceiptsRecord? receipt;
  final Hearing? hearing;
  final DateTime at;
  final bool dated; // true when [at] is the item's own date
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.matter, required this.receipts, required this.lastView});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final DateTime? lastView;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final rows = <_Row>[
      for (final r in receipts)
        if (r.resolvedDate != null || r.receivedAt != null) _Row.item(r, r.resolvedDate ?? r.receivedAt!, r.resolvedDate != null),
      for (final h in hearingsOf(matter)) _Row.hearing(h),
    ]..sort((a, b) => a.at.compareTo(b.at));
    if (rows.isEmpty) {
      return const VEmptyState(icon: Icons.timeline, title: 'Nothing on the timeline yet', message: 'Items appear here, placed on the date they carry, as soon as they arrive.');
    }
    final opened = matter.openedAt;
    String? lastMonth;
    final children = <Widget>[];
    for (final row in rows) {
      final month = '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][row.at.month - 1]} ${row.at.year}';
      if (month != lastMonth) {
        lastMonth = month;
        children.add(Padding(padding: const EdgeInsets.only(top: 14.0, bottom: 6.0), child: Text(month.toUpperCase(), style: VT.eyebrow(context))));
      }
      if (row.hearing != null) {
        children.add(_Line(
          dot: c.oxblood,
          icon: Icons.gavel_outlined,
          title: row.hearing!.title.isEmpty ? 'Hearing' : row.hearing!.title,
          sub: fmtWhen(row.hearing!.at),
        ));
        continue;
      }
      final r = row.receipt!;
      final lag = (r.resolvedDate != null && r.receivedAt != null) ? r.receivedAt!.difference(r.resolvedDate!).inDays : null;
      final preIntake = r.resolvedDate != null && opened != null && r.resolvedDate!.isBefore(opened);
      final isNew = lastView != null && r.receivedAt != null && r.receivedAt!.isAfter(lastView!);
      children.add(_Line(
        dot: r.classificationLabel == 'Uncertain' || r.classificationLabel == 'Unreadable' ? c.pending : c.teal,
        icon: r.isVideo ? Icons.movie_outlined : (r.isImage ? Icons.image_outlined : Icons.description_outlined),
        title: r.headline,
        sub: [
          row.dated ? 'Dated ${fmtDay(r.resolvedDate)}${r.dateSource.isNotEmpty ? ' (${r.dateSource.replaceAll('_', ' ')})' : ''}' : 'No date in the item — placed by arrival',
          'received ${fmtDay(r.receivedAt)}${r.channel.isNotEmpty ? ' by ${r.channel}' : ''}',
          if (lag != null && lag >= 0) 'Record Lag $lag d',
        ].join(' · '),
        badges: [
          if (isNew) ('New', c.teal),
          if (preIntake) ('Pre-intake', c.secondaryFg),
          if (r.isDuplicate) ('Duplicate', c.mutedFg),
          if (r.classificationLabel == 'Uncertain' || r.classificationLabel == 'Unreadable') (r.classificationLabel, c.pending),
        ],
      ));
    }
    return TourTarget(id: 'timeline_list', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.dot, required this.icon, required this.title, required this.sub, this.badges = const []});

  final Color dot;
  final IconData icon;
  final String title;
  final String sub;
  final List<(String, Color)> badges;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22.0,
            child: Column(
              children: [
                Container(width: 10.0, height: 10.0, margin: const EdgeInsets.only(top: 6.0), decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                Expanded(child: Container(width: 1.5, color: c.border)),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 14.0, color: c.mutedFg),
                      const SizedBox(width: 6.0),
                      Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.5, weight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(sub, style: VT.muted(context, size: 12.0)),
                  if (badges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Wrap(
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: [for (final (l, col) in badges) VBadge(label: l, bg: col.withValues(alpha: 0.12), fg: col)],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Before and after
// ---------------------------------------------------------------------------

class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({required this.matter, required this.receipts, required this.thread});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final ThreadDoc? thread;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final arrived = receipts.where((r) => r.receivedAt != null).toList()..sort((a, b) => a.receivedAt!.compareTo(b.receivedAt!));
    final number = {for (var i = 0; i < arrived.length; i++) arrived[i].reference.id: i + 1};
    final unreadable = arrived.where((r) => r.classificationLabel == 'Unreadable' || r.extractionState == 'extraction_failed').toList();
    final entries = (thread?.entries ?? const <TEntry>[]).where((e) => e.isMessage || e.isGap).toList();

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('AS SENT', style: VT.eyebrow(context)),
        const SizedBox(height: 4.0),
        Text('${arrived.length} items, in the order they arrived', style: VT.muted(context, size: 12.0)),
        const SizedBox(height: 10.0),
        for (final r in arrived)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: VCard(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(8.0)),
                    child: r.isImage && r.sourceUrl.isNotEmpty
                        ? Image.network(r.sourceUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: c.mutedFg))
                        : Icon(r.isVideo ? Icons.movie_outlined : Icons.description_outlined, color: c.mutedFg),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${number[r.reference.id]} · ${r.headline}', maxLines: 2, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 12.5, weight: FontWeight.w500)),
                        Text('${fmtWhen(r.receivedAt)}${r.channel.isNotEmpty ? ' · ${r.channel}' : ''}', style: VT.muted(context, size: 11.5)),
                        if (r.sourceUrl.isEmpty && r.sourceStoragePath.isNotEmpty) Text("Delivered to the firm's system; Verin keeps the fingerprint", style: VT.muted(context, size: 11.0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('THE STANDING RECORD', style: VT.eyebrow(context)),
        const SizedBox(height: 4.0),
        Text('${(thread?.stats['messages'] as num?)?.toInt() ?? 0} messages assembled; each cites its item', style: VT.muted(context, size: 12.0)),
        const SizedBox(height: 10.0),
        if (thread == null) VEmptyState(icon: Icons.layers_outlined, title: 'Not assembled yet', message: 'Verin assembles the record as items are read.', compact: true),
        for (final e in entries)
          if (e.isGap)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Expanded(child: Divider(color: c.pending.withValues(alpha: 0.6))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('gap — continuity not shown', style: VT.body(context, size: 11.5, color: c.pending))),
                  Expanded(child: Divider(color: c.pending.withValues(alpha: 0.6))),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: e.isClient ? c.teal.withValues(alpha: 0.07) : c.card,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: e.has('hard_to_read') ? c.pending : c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.text, style: VT.body(context, size: 13.0)),
                    const SizedBox(height: 4.0),
                    Text(
                      [
                        e.person.isNotEmpty ? e.person : (e.isClient ? 'Client' : 'Other side'),
                        e.whenLabel,
                        if (number[e.rid] != null) 'from item #${number[e.rid]}',
                        if (e.alsoIn.isNotEmpty) 'also in ${e.alsoIn.length} more',
                        if (e.has('hard_to_read')) 'hard to read',
                      ].join(' · '),
                      style: VT.muted(context, size: 11.0),
                    ),
                  ],
                ),
              ),
            ),
        if (unreadable.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          Text('COULD NOT BE READ', style: VT.eyebrow(context, color: c.pending)),
          const SizedBox(height: 6.0),
          for (final r in unreadable) Text('• #${number[r.reference.id]} ${r.headline}', style: VT.body(context, size: 12.5)),
        ],
      ],
    );

    return TourTarget(
      id: 'before_after',
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 720.0
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 24.0), right])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Icon(Icons.arrow_forward, color: c.mutedFg)),
                  Expanded(child: right),
                ],
              ),
      ),
    );
  }
}
