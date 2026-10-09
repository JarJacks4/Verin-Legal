// One place for everything that happened while you were away:
//
//   the bell       in the sidebar, with a count of what is new since your
//                  last look
//   the feed       evidence that arrived, and anything that needs attention
//                  (provisioning, oversize sends, a delivery that failed)
//   live arrivals  a toast with Open while the app is in front of you
//
// What is "new" is one timestamp per person: users/{uid}.notificationsSeenAt,
// written when the feed is opened. Alerts stay in the count until someone
// marks them done, since they are work, not news.

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../matters/matters_screen.dart' show openMatter;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import '../widgets/motion.dart';

/// How far back the feed looks. Beyond this, a matter's own pages are the
/// place to look rather than a notification list.
const _kFeedLimit = 30;

class VEvent {
  VEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.at,
    this.matter,
    this.alertRef,
    this.severity = 'info',
  });

  final String id, title, subtitle, severity;
  final IconData icon;
  final DateTime? at;
  final DocumentReference? matter;
  final DocumentReference? alertRef;

  bool get needsAttention => alertRef != null;
}

String _kindLabel(String kind) {
  switch (kind) {
    case 'photo':
      return 'A photo';
    case 'video':
      return 'A video';
    case 'audio':
      return 'An audio message';
    case 'document':
      return 'A document';
    case 'message':
      return 'A message';
    default:
      return 'An item';
  }
}

/// Matter names for the feed, looked up once per matter and kept for the
/// session — the feed shows a handful of matters over and over.
final Map<String, String> _matterNames = {};

Future<String> matterNameOf(DocumentReference ref) async {
  final hit = _matterNames[ref.path];
  if (hit != null) return hit;
  try {
    final m = await MattersRecord.getDocumentOnce(ref);
    final name = m.matterName.isNotEmpty ? m.matterName : 'Untitled matter';
    _matterNames[ref.path] = name;
    return name;
  } catch (_) {
    return 'A matter';
  }
}

Stream<List<ReceiptsRecord>> _arrivals() => queryReceiptsRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()).orderBy('receivedAt', descending: true),
      limit: _kFeedLimit,
    );

Stream<List<VEvent>> _alertEvents(DocumentReference? firmRef) {
  if (firmRef == null) return Stream.value(const <VEvent>[]);
  return firmRef.collection('alerts').where('resolved', isEqualTo: false).limit(20).snapshots().map((s) => s.docs.map((d) {
        final data = d.data();
        final raised = data['raisedAt'];
        return VEvent(
          id: d.reference.path,
          title: data['message'] is String ? data['message'] as String : 'Something needs attention',
          subtitle: 'Needs attention',
          icon: Icons.notification_important_outlined,
          at: raised is Timestamp ? raised.toDate() : null,
          alertRef: d.reference,
          severity: data['severity'] is String ? data['severity'] as String : 'warning',
        );
      }).toList());
}

/// One listener per firm, shared by the bell, the open drawer and the live
/// watcher — they all want the same thirty documents.
Stream<List<ReceiptsRecord>>? _sharedArrivals;
String _sharedArrivalsFirm = '';

Stream<List<ReceiptsRecord>> sharedArrivals() {
  final firm = currentFirmId();
  if (_sharedArrivals == null || _sharedArrivalsFirm != firm) {
    _sharedArrivalsFirm = firm;
    _sharedArrivals = _arrivals().asBroadcastStream();
  }
  return _sharedArrivals!;
}

final Map<String, Stream<List<VEvent>>> _sharedAlerts = {};

Stream<List<VEvent>> sharedAlertEvents(DocumentReference? firmRef) {
  if (firmRef == null) return Stream.value(const <VEvent>[]);
  return _sharedAlerts[firmRef.path] ??= _alertEvents(firmRef).asBroadcastStream();
}

Stream<List<VEvent>> _arrivalEvents() => sharedArrivals().asyncMap((receipts) async {
      final events = <VEvent>[];
      for (final r in receipts) {
        final ref = r.matterId;
        events.add(VEvent(
          id: r.reference.path,
          title: '${_kindLabel(r.itemKind)} arrived',
          subtitle: ref == null ? '' : await matterNameOf(ref),
          icon: Icons.inbox_outlined,
          at: r.receivedAt,
          matter: ref,
        ));
      }
      return events;
    });

/// Anything needing attention stays on top; the rest run newest first.
List<VEvent> _ordered(List<VEvent> alerts, List<VEvent> arrivals) {
  final events = [...alerts, ...arrivals];
  events.sort((a, b) {
    if (a.needsAttention != b.needsAttention) return a.needsAttention ? -1 : 1;
    final x = a.at, y = b.at;
    if (x == null || y == null) return 0;
    return y.compareTo(x);
  });
  return events;
}

/// Everything the bell counts and the feed shows, newest first. The two
/// sources are kept apart so an alert being marked done doesn't restart the
/// arrivals listener.
class FeedBuilder extends StatefulWidget {
  const FeedBuilder({super.key, required this.firmRef, required this.builder});

  final DocumentReference? firmRef;
  final Widget Function(BuildContext context, List<VEvent>? events) builder;

  @override
  State<FeedBuilder> createState() => _FeedBuilderState();
}

class _FeedBuilderState extends State<FeedBuilder> {
  late Stream<List<VEvent>> _alerts = sharedAlertEvents(widget.firmRef);
  final Stream<List<VEvent>> _arrivalsStream = _arrivalEvents();

  @override
  void didUpdateWidget(covariant FeedBuilder old) {
    super.didUpdateWidget(old);
    if (old.firmRef?.path != widget.firmRef?.path) _alerts = sharedAlertEvents(widget.firmRef);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<VEvent>>(
        stream: _alerts,
        builder: (context, a) => StreamBuilder<List<VEvent>>(
          stream: _arrivalsStream,
          builder: (context, r) {
            if (a.hasError || r.hasError) return widget.builder(context, const <VEvent>[]);
            if (!a.hasData && !r.hasData) return widget.builder(context, null);
            return widget.builder(context, _ordered(a.data ?? const [], r.data ?? const []));
          },
        ),
      );
}

Future<DateTime?> _readSeenAt() async {
  final uid = currentUserUid;
  if (uid.isEmpty) return null;
  try {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final v = snap.data()?['notificationsSeenAt'];
    return v is Timestamp ? v.toDate() : null;
  } catch (_) {
    return null;
  }
}

Future<void> _markSeen() async {
  final uid = currentUserUid;
  if (uid.isEmpty) return;
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'notificationsSeenAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  } catch (_) {
    // Not essential: the count simply stays up until the next successful write.
  }
}

// ---------------------------------------------------------------------------
// The bell
// ---------------------------------------------------------------------------

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, required this.firm});

  final FirmAccountRecord? firm;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  DateTime? _seenAt;
  bool _loadedSeen = false;

  @override
  void initState() {
    super.initState();
    _readSeenAt().then((v) {
      if (mounted) setState(() {
        _seenAt = v;
        _loadedSeen = true;
      });
    });
  }

  int _unread(List<VEvent> events) {
    final seen = _seenAt;
    return events.where((e) {
      if (e.needsAttention) return true;
      final at = e.at;
      if (at == null) return false;
      return seen == null || at.isAfter(seen);
    }).length;
  }

  Future<void> _open() async {
    await showVDrawer<void>(
      context,
      title: 'Notifications',
      width: 460.0,
      builder: (_) => NotificationFeedBody(firm: widget.firm, seenAt: _seenAt),
    );
    await _markSeen();
    if (mounted) setState(() => _seenAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return FeedBuilder(
      firmRef: widget.firm?.reference,
      builder: (context, data) {
        final events = data ?? const <VEvent>[];
        // Until the last-look time is read, nothing is called new — better a
        // quiet bell for a moment than a wrong number.
        final n = _loadedSeen ? _unread(events) : 0;
        final urgent = events.any((e) => e.needsAttention && e.severity == 'error');
        return VHover(
          onTap: _open,
          builder: (context, hovered) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: hovered ? Color.alphaBlend(c.foreground.withValues(alpha: 0.04), c.secondary) : Colors.transparent,
              borderRadius: BorderRadius.circular(VR.xl),
            ),
            child: Row(
              children: [
                _BellIcon(count: n, ready: _loadedSeen, tone: urgent ? c.broken : c.teal),
                const SizedBox(width: 10.0),
                Expanded(child: Text('Notifications', style: VT.body(context, size: 13.0, weight: FontWeight.w500))),
                if (n > 0)
                  VPop(
                    trigger: n,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                      decoration: BoxDecoration(color: urgent ? c.broken : c.teal, borderRadius: BorderRadius.circular(999)),
                      child: Text(n > 99 ? '99+' : '$n', style: VT.body(context, size: 10.0, weight: FontWeight.w700, color: c.paper)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The bell itself: it bumps once whenever the count goes up, so an arrival
/// is noticed without a sound or a popup.
class _BellIcon extends StatefulWidget {
  const _BellIcon({required this.count, required this.ready, required this.tone});

  final int count;

  /// False until the last-look time is known. The first count to land is the
  /// backlog, not an arrival, so it must not ring.
  final bool ready;
  final Color tone;

  @override
  State<_BellIcon> createState() => _BellIconState();
}

class _BellIconState extends State<_BellIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

  @override
  void didUpdateWidget(covariant _BellIcon old) {
    super.didUpdateWidget(old);
    if (widget.ready && old.ready && widget.count > old.count && !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Two decaying swings, then still.
        final t = _c.value;
        final angle = t == 0.0 ? 0.0 : 0.22 * (1.0 - t) * math.sin(t * 3.0 * 2 * math.pi);
        return Transform.rotate(angle: angle, alignment: Alignment.topCenter, child: child);
      },
      child: Icon(
        widget.count > 0 ? Icons.notifications_active_outlined : Icons.notifications_none_rounded,
        size: 16.0,
        color: widget.count > 0 ? widget.tone : c.mutedFg,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The feed
// ---------------------------------------------------------------------------

class NotificationFeedBody extends StatefulWidget {
  const NotificationFeedBody({super.key, required this.firm, required this.seenAt});

  final FirmAccountRecord? firm;
  final DateTime? seenAt;

  @override
  State<NotificationFeedBody> createState() => _NotificationFeedBodyState();
}

class _NotificationFeedBodyState extends State<NotificationFeedBody> {
  Future<void> _resolve(VEvent e) async {
    final ref = e.alertRef;
    if (ref == null) return;
    try {
      await ref.update({'resolved': true, 'resolvedByUid': currentUserUid, 'resolvedAt': FieldValue.serverTimestamp()});
    } catch (err) {
      if (mounted) showVToast(context, 'Could not mark it done', error: true, description: '$err');
    }
  }

  Future<void> _open(VEvent e) async {
    final ref = e.matter;
    if (ref == null) return;
    try {
      final m = await MattersRecord.getDocumentOnce(ref);
      if (!mounted) return;
      Navigator.of(context).maybePop();
      openMatter(context, m);
    } catch (_) {
      if (mounted) showVToast(context, 'Could not open that matter', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return FeedBuilder(
      firmRef: widget.firm?.reference,
      builder: (context, data) {
        if (data == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
          );
        }
        final events = data;
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Column(
              children: [
                Icon(Icons.notifications_none_rounded, size: 28.0, color: c.mutedFg),
                const SizedBox(height: 12.0),
                Text('Nothing new', style: VT.body(context, size: 14.0, weight: FontWeight.w600)),
                const SizedBox(height: 4.0),
                Text('Evidence arriving in any matter shows up here.', style: VT.muted(context, size: 12.0), textAlign: TextAlign.center),
              ],
            ),
          );
        }
        final seen = widget.seenAt;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, e) in events.indexed)
              _EventRow(
                event: e,
                first: i == 0,
                isNew: !e.needsAttention && e.at != null && (seen == null || e.at!.isAfter(seen)),
                onOpen: e.matter == null ? null : () => _open(e),
                onDone: e.needsAttention ? () => _resolve(e) : null,
                index: i,
              ),
          ],
        );
      },
    );
  }
}

/// One row. It reveals with a short stagger so a full feed reads top to
/// bottom, and anything new since your last look gets one wash of teal.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.first,
    required this.isNew,
    required this.index,
    this.onOpen,
    this.onDone,
  });

  final VEvent event;
  final bool first, isNew;
  final int index;
  final VoidCallback? onOpen, onDone;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final e = event;
    final tone = e.needsAttention ? (e.severity == 'error' ? c.broken : c.pending) : c.teal;
    return VReveal(
      index: index,
      slide: 14.0,
      child: VArriveGlow(
        on: isNew,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.0,
                height: 28.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tone.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(VR.lg)),
                child: Icon(e.icon, size: 15.0, color: tone),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.title, style: VT.body(context, size: 13.0, weight: FontWeight.w500))),
                        if (isNew)
                          Container(
                            margin: const EdgeInsets.only(left: 6.0),
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(color: c.teal, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    if (e.subtitle.isNotEmpty) Text(e.subtitle, style: VT.muted(context, size: 12.0)),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(fmtWhen(e.at), style: VT.muted(context, size: 11.0)),
                        if (onOpen != null) ...[
                          const SizedBox(width: 10.0),
                          VHover(
                            onTap: onOpen,
                            builder: (context, hovered) => Text(
                              'Open',
                              style: VT.body(context, size: 11.5, weight: FontWeight.w600, color: hovered ? c.tealDeep : c.teal),
                            ),
                          ),
                        ],
                        if (onDone != null) ...[
                          const SizedBox(width: 10.0),
                          VHover(
                            onTap: onDone,
                            builder: (context, hovered) => Text(
                              'Mark done',
                              style: VT.body(context, size: 11.5, weight: FontWeight.w600, color: hovered ? c.foreground : c.mutedFg),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live arrivals
// ---------------------------------------------------------------------------

/// Watches the firm's receipts while the app is open and raises one toast per
/// arrival, with Open to go straight to the matter. It never speaks for items
/// that were already there when the page loaded.
class ArrivalWatcher extends StatefulWidget {
  const ArrivalWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<ArrivalWatcher> createState() => _ArrivalWatcherState();
}

class _ArrivalWatcherState extends State<ArrivalWatcher> {
  late final Stream<List<ReceiptsRecord>> _stream = sharedArrivals();
  final Set<String> _known = {};
  bool _primed = false;

  void _onData(List<ReceiptsRecord> list) {
    if (!_primed) {
      // First snapshot is the backlog, not news.
      _known.addAll(list.map((r) => r.reference.path));
      _primed = true;
      return;
    }
    final fresh = list.where((r) => !_known.contains(r.reference.path)).toList();
    _known.addAll(fresh.map((r) => r.reference.path));
    if (fresh.isEmpty || !mounted) return;
    // One toast, however many landed together.
    final first = fresh.first;
    final more = fresh.length - 1;
    final ref = first.matterId;
    final title = more > 0 ? '${fresh.length} new items arrived' : '${_kindLabel(first.itemKind)} arrived';
    if (ref == null) {
      showVToast(context, title, duration: const Duration(seconds: 6));
      return;
    }
    matterNameOf(ref).then((name) {
      if (mounted) showVToast(context, title, description: name, duration: const Duration(seconds: 6));
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReceiptsRecord>>(
      stream: _stream,
      builder: (context, s) {
        final list = s.data;
        if (list != null) {
          // Toasts are a side effect, so they wait for the frame to finish.
          WidgetsBinding.instance.addPostFrameCallback((_) => _onData(list));
        }
        return widget.child;
      },
    );
  }
}
