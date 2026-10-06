// First-time walkthroughs: a spotlight that moves from one part of the page
// to the next with a short card explaining it.
//
//   TourTarget(id: 'matters_new', child: ...)   marks something to point at
//   TourLauncher(tourId: 'matters', steps: [...], child: ...)
//                                               runs the tour the first time
//                                               this person sees the page
//
// What each person has seen is kept on users/{uid}.onboarding, so it follows
// them across devices. "Replay the walkthrough" in Profile clears it.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import 'tours.dart' show demoTours;

// ---------------------------------------------------------------------------
// What has been seen
// ---------------------------------------------------------------------------

class TourProgress {
  static String _uid = '';
  static final Set<String> _seen = {};
  static Future<void>? _loading;

  /// Tours shown during this session (even before the write lands).
  static final Set<String> _shownThisSession = {};

  static Future<void> load() {
    final uid = currentUserUid;
    if (uid != _uid) {
      _uid = uid;
      _seen.clear();
      _shownThisSession.clear();
      _loading = null;
    }
    return _loading ??= _fetch();
  }

  static Future<void> _fetch() async {
    final ref = currentUserReference;
    if (ref == null) return;
    try {
      final snap = await ref.get();
      final data = snap.data();
      final o = data is Map ? data['onboarding'] : null;
      if (o is Map) _seen.addAll(o.keys.whereType<String>());
    } catch (_) {
      // Offline or not readable yet: treat as unseen, but only once.
    }
  }

  static bool seen(String id) {
    final k = DemoMode.key(id);
    return _seen.contains(k) || _shownThisSession.contains(k);
  }

  static Future<void> mark(String id) async {
    id = DemoMode.key(id);
    _shownThisSession.add(id);
    _seen.add(id);
    final ref = currentUserReference;
    if (ref == null) return;
    try {
      await ref.set({
        'onboarding': {id: FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Shows the welcome and every walkthrough again.
  static Future<void> reset() async {
    _seen.clear();
    _shownThisSession.clear();
    final ref = currentUserReference;
    if (ref == null) return;
    try {
      await ref.update({'onboarding': FieldValue.delete()});
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// NFR demo workspaces
// ---------------------------------------------------------------------------

/// In a demo workspace the tips speak to a prospective customer (tours.dart,
/// [demoTours]) and come back after every reset, so each demo starts fresh.
class DemoMode {
  static bool known = false;
  static bool active = false;
  static String _stamp = '';

  /// Called by the app and admin shells whenever the firm record loads.
  static void update(FirmAccountRecord? firm) {
    known = true;
    active = firm?.snapshotData['isDemo'] == true;
    final at = firm?.snapshotData['demoSeededAt'];
    _stamp = at is Timestamp ? '${at.millisecondsSinceEpoch}' : '0';
  }

  /// Progress key for a tour: per demo reset in a demo workspace.
  static String key(String id) => active ? 'demo_${_stamp}_$id' : id;
}

// ---------------------------------------------------------------------------
// Targets
// ---------------------------------------------------------------------------

class TourTarget extends StatefulWidget {
  const TourTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  static final Map<String, Set<_TourTargetState>> _live = {};

  static _TourTargetState? _visible(String id) {
    for (final s in _live[id] ?? const <_TourTargetState>{}) {
      final ctx = s._key.currentContext;
      if (ctx == null) continue;
      final r = s._route;
      if (r != null && !r.isCurrent) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize || box.size.isEmpty) continue;
      return s;
    }
    return null;
  }

  /// The target's rect on screen, or null when it isn't showing.
  static Rect? rectOf(String id) {
    final s = _visible(id);
    final box = s?._key.currentContext?.findRenderObject();
    if (box is! RenderBox) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static BuildContext? contextOf(String id) => _visible(id)?._key.currentContext;

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  final _key = GlobalKey();
  ModalRoute<dynamic>? _route;
  late String _id = widget.id;

  @override
  void initState() {
    super.initState();
    TourTarget._live.putIfAbsent(_id, () => {}).add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(TourTarget old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      TourTarget._live[_id]?.remove(this);
      _id = widget.id;
      TourTarget._live.putIfAbsent(_id, () => {}).add(this);
    }
  }

  @override
  void dispose() {
    TourTarget._live[_id]?.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

// ---------------------------------------------------------------------------
// Steps and launching
// ---------------------------------------------------------------------------

class TourStep {
  const TourStep({this.target, required this.title, required this.body, this.icon, this.optional = false});

  /// Leave the step out when its target isn't on screen (e.g. a quarantine
  /// panel that only some items have).
  final bool optional;

  /// TourTarget id to spotlight; null (or not on screen) shows a centred card.
  final String? target;
  final String title;
  final String body;
  final IconData? icon;
}

/// Runs [steps] the first time this person opens the page. Put a new key on
/// it (or change [tourId]) to run a different tour in the same place.
class TourLauncher extends StatefulWidget {
  const TourLauncher({
    super.key,
    required this.tourId,
    required this.steps,
    required this.child,
    this.enabled = true,
    this.delay = const Duration(milliseconds: 700),
    this.beforeStart,
  });

  final String tourId;
  final List<TourStep> steps;
  final Widget child;
  final bool enabled;
  final Duration delay;

  /// Return false to skip starting (e.g. to send the person somewhere first).
  final Future<bool> Function(BuildContext context)? beforeStart;

  @override
  State<TourLauncher> createState() => _TourLauncherState();
}

class _TourLauncherState extends State<TourLauncher> {
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(TourLauncher old) {
    super.didUpdateWidget(old);
    if (old.tourId != widget.tourId || (!old.enabled && widget.enabled)) _schedule();
  }

  void _schedule() {
    final attempt = ++_attempt;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run(attempt));
  }

  Future<void> _run(int attempt) async {
    if (!widget.enabled || currentUserUid.isEmpty) return;
    await TourProgress.load();
    // Demo workspaces have their own tips; wait until we know which this is.
    await _until(() => DemoMode.known, tries: 20);
    if (!mounted || attempt != _attempt) return;
    if (TourProgress.seen(widget.tourId)) return;
    if (widget.beforeStart != null && !await widget.beforeStart!(context)) return;
    if (!mounted) return;

    // Wait for the launch splash, the page transition and the first data.
    await _until(() => !BrandAnchor.hidden.value);
    await Future.delayed(widget.delay);
    // One tour at a time (e.g. a tab's tips wait for the page's tour).
    await _until(() => !VTour.active, tries: 2400);
    // Something on top (a drawer, a dialog)? Wait for it to close.
    await _until(() => ModalRoute.of(context)?.isCurrent ?? true, tries: 120);
    if (!mounted || attempt != _attempt || TourProgress.seen(widget.tourId)) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final steps = DemoMode.active ? (demoTours[widget.tourId] ?? widget.steps) : widget.steps;
    VTour.show(context, tourId: widget.tourId, steps: steps);
  }

  Future<void> _until(bool Function() ok, {int tries = 40}) async {
    for (var i = 0; i < tries; i++) {
      if (!mounted) return;
      if (ok()) return;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class VTour {
  /// Tours on screen, oldest first. One whose page is covered (a drawer was
  /// opened on top) hides and lets the drawer's own tour run above it.
  static final List<(OverlayEntry, ValueNotifier<bool>)> _open = [];

  /// A tour is showing (not counting ones hidden under a drawer).
  static bool get active => _open.any((t) => !t.$2.value);

  static void show(BuildContext context, {required String tourId, required List<TourStep> steps}) {
    steps = steps.where((s) => !s.optional || (s.target != null && TourTarget.rectOf(s.target!) != null)).toList();
    if (active || steps.isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    TourProgress._shownThisSession.add(DemoMode.key(tourId));
    final route = ModalRoute.of(context);
    final covered = ValueNotifier<bool>(false);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        steps: steps,
        route: route,
        covered: covered,
        onClose: () {
          if (entry.mounted) entry.remove();
          _open.removeWhere((t) => identical(t.$1, entry));
          TourProgress.mark(tourId);
        },
      ),
    );
    _open.add((entry, covered));
    overlay.insert(entry);
  }
}

// ---------------------------------------------------------------------------
// The overlay
// ---------------------------------------------------------------------------

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.route, required this.covered, required this.onClose});

  final List<TourStep> steps;
  final ModalRoute<dynamic>? route;
  final ValueNotifier<bool> covered;
  final VoidCallback onClose;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..forward();
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final Ticker _ticker;
  final _focus = FocusNode(debugLabel: 'tour');

  int _i = 0;
  Rect? _from; // hole at the start of a move (null = no hole)
  Rect? _to; // hole at the end of a move
  bool _moving = true; // until the first step has moved in
  bool _closing = false;
  bool _covered = false;

  TourStep get _step => widget.steps[_i];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _go(0);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fade.dispose();
    _move.dispose();
    _focus.dispose();
    super.dispose();
  }

  Rect? get _hole {
    final t = Curves.easeInOutCubic.transform(_move.value);
    if (_from == null && _to == null) return null;
    if (_from == null) return _to;
    if (_to == null) return _from;
    return Rect.lerp(_from, _to, t);
  }

  /// Keeps the spotlight on its target while the page scrolls or resizes,
  /// and closes the tour if its page goes away.
  void _tick(Duration _) {
    final r = widget.route;
    if (r != null && !r.isActive) {
      _close();
      return;
    }
    final covered = r != null && !r.isCurrent;
    if (covered != _covered) {
      widget.covered.value = covered;
      setState(() => _covered = covered);
      return;
    }
    if (_moving || _closing) {
      if (mounted) setState(() {});
      return;
    }
    final id = _step.target;
    final now = id == null ? null : TourTarget.rectOf(id);
    final cur = _to;
    if (_differs(now, cur)) {
      setState(() {
        _from = now;
        _to = now;
      });
    }
  }

  static bool _differs(Rect? a, Rect? b) {
    if (a == null || b == null) return a != b;
    return (a.left - b.left).abs() > 0.5 ||
        (a.top - b.top).abs() > 0.5 ||
        (a.width - b.width).abs() > 0.5 ||
        (a.height - b.height).abs() > 0.5;
  }

  Future<void> _go(int i) async {
    if (i < 0) return;
    if (i >= widget.steps.length) {
      _close();
      return;
    }
    final start = _hole;
    setState(() {
      _i = i;
      _moving = true;
    });
    final id = widget.steps[i].target;
    final ctx = id == null ? null : TourTarget.contextOf(id);
    if (ctx != null && ctx.mounted) {
      try {
        await Scrollable.ensureVisible(ctx, alignment: 0.25, duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic);
      } catch (_) {}
    }
    if (!mounted) return;
    final target = id == null ? null : TourTarget.rectOf(id);
    _from = start ?? (target == null ? null : target.inflate(60.0));
    _to = target;
    await _move.forward(from: 0.0);
    if (!mounted) return;
    setState(() {
      _from = _to;
      _moving = false;
    });
    _focus.requestFocus();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _ticker.stop();
    if (mounted) await _fade.reverse();
    widget.onClose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent || _covered || _closing) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.escape) {
      _close();
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.enter) {
      _go(_i + 1);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _go(_i - 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final covered = _covered; // e.g. a drawer opened on top
    final hole = _hole;
    final screen = MediaQuery.sizeOf(context);
    final spot = hole == null ? null : _clampToScreen(hole.inflate(8.0), screen);
    return IgnorePointer(
      ignoring: covered || _closing,
      child: Opacity(
        opacity: covered ? 0.0 : 1.0,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _onKey,
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Taps outside the card do nothing (no accidental skips).
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: CustomPaint(painter: _ScrimPainter(spot: spot, ring: VC.of(context).teal)),
                  ),
                  CustomSingleChildLayout(
                    delegate: _CardLayout(spot: spot, padding: MediaQuery.paddingOf(context)),
                    child: _card(context, screen),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Rect _clampToScreen(Rect r, Size s) {
    final b = Offset.zero & s;
    final c = r.intersect(b.deflate(4.0));
    return c.isEmpty ? r : c;
  }

  Widget _card(BuildContext context, Size screen) {
    final c = VC.of(context);
    final n = widget.steps.length;
    final last = _i == n - 1;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: math.min(380.0, screen.width - 32.0)),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(VR.card),
          border: Border.all(color: c.border),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 40.0, offset: Offset(0, 16))],
        ),
        padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 16.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.04, 0.0), end: Offset.zero).animate(a), child: child),
                ),
                layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, if (cur != null) cur]),
                child: Column(
                  key: ValueKey<int>(_i),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_step.icon != null) ...[
                          Container(
                            width: 30.0,
                            height: 30.0,
                            decoration: BoxDecoration(color: c.tealPale, shape: BoxShape.circle),
                            child: Icon(_step.icon, size: 16.0, color: c.tealDeep),
                          ),
                          const SizedBox(width: 10.0),
                        ],
                        Expanded(child: Text(_step.title, style: VT.h3(context, size: 16.0))),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(_step.body, style: VT.muted(context, size: 13.5, height: 1.55)),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  if (n > 1) _Dots(count: n, index: _i),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      onPressed: _close,
                      child: Text('Skip', style: VT.body(context, size: 13.0, color: c.mutedFg)),
                    ),
                  if (_i > 0) ...[
                    const SizedBox(width: 4.0),
                    VButton(label: 'Back', kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: () => _go(_i - 1)),
                  ],
                  const SizedBox(width: 8.0),
                  VButton(
                    label: last ? 'Got it' : 'Next',
                    trailingIcon: last ? null : Icons.arrow_forward,
                    size: VButtonSize.sm,
                    onPressed: () => _go(_i + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 5.0),
            width: i == index ? 18.0 : 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              color: i == index ? c.teal : c.mutedFg.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999.0),
            ),
          ),
      ],
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.spot, required this.ring});

  final Rect? spot;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    final scrim = Paint()..color = const Color(0x99091216);
    final s = spot;
    if (s == null) {
      canvas.drawPath(all, scrim);
      return;
    }
    final rr = RRect.fromRectAndRadius(s, const Radius.circular(14.0));
    canvas.drawPath(Path.combine(PathOperation.difference, all, Path()..addRRect(rr)), scrim);
    canvas.drawRRect(rr, Paint()
      ..color = ring.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0));
    canvas.drawRRect(rr, Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.spot != spot || old.ring != ring;
}

/// Puts the card below the spotlight if it fits, else above, else at the
/// bottom of the screen; centred when there is no spotlight.
class _CardLayout extends SingleChildLayoutDelegate {
  _CardLayout({required this.spot, required this.padding});

  final Rect? spot;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    const gap = 14.0;
    const margin = 16.0;
    final s = spot;
    double clampX(double x) => x.clamp(margin, math.max(margin, size.width - child.width - margin)).toDouble();
    double clampY(double y) => y.clamp(margin + padding.top, math.max(margin + padding.top, size.height - child.height - margin - padding.bottom)).toDouble();
    if (s == null) return Offset((size.width - child.width) / 2.0, (size.height - child.height) / 2.0);
    final x = clampX(s.left);
    if (size.height - s.bottom - padding.bottom >= child.height + gap + margin) return Offset(x, s.bottom + gap);
    if (s.top - padding.top >= child.height + gap + margin) return Offset(x, s.top - gap - child.height);
    // Big target: beside it if there's room, else over its lower part.
    if (size.width - s.right >= child.width + gap + margin) return Offset(s.right + gap, clampY(s.top));
    if (s.left >= child.width + gap + margin) return Offset(s.left - gap - child.width, clampY(s.top));
    return Offset(clampX((size.width - child.width) / 2.0), clampY(size.height - child.height - margin - padding.bottom));
  }

  @override
  bool shouldRelayout(_CardLayout old) => old.spot != spot || old.padding != padding;
}
