// Shared motion: curves, durations, the page transition and shared-element
// heroes, so every screen moves the same way.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VMotion {
  static const Curve enter = Cubic(0.22, 1.0, 0.36, 1.0); // easeOutQuint-ish
  static const Curve exit = Cubic(0.55, 0.0, 1.0, 0.45);
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Duration page = Duration(milliseconds: 380);
  static const Duration pageReverse = Duration(milliseconds: 300);
}

/// Incoming page fades in and rises a few pixels; the outgoing page fades
/// back slightly. Shared heroes fly on top.
Widget vPageTransition(BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
  final inCurve = CurvedAnimation(parent: animation, curve: VMotion.enter, reverseCurve: VMotion.standard);
  final outCurve = CurvedAnimation(parent: secondary, curve: VMotion.standard);
  return FadeTransition(
    opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: outCurve, curve: const Interval(0.0, 0.6))),
    child: FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.0, 0.018), end: Offset.zero).animate(inCurve),
        child: child,
      ),
    ),
  );
}

/// A text that flies between two screens (e.g. a matter title from the list
/// to its detail page), cross-fading between the two styles on the way.
class TextHero extends StatelessWidget {
  const TextHero({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) => Hero(
        tag: tag,
        createRectTween: (a, b) => MaterialRectCenterArcTween(begin: a, end: b),
        flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
          final from = (fromContext.widget as Hero).child;
          final to = (toContext.widget as Hero).child;
          // Pop runs the animation 1 → 0; keep "to" fading in either way.
          final toIn = direction == HeroFlightDirection.push ? animation : ReverseAnimation(animation);
          Widget fit(Widget w) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: w);
          return Material(
            type: MaterialType.transparency,
            child: AnimatedBuilder(
              animation: toIn,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(toIn.value);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(opacity: 1.0 - t, child: fit(from)),
                    Opacity(opacity: t, child: fit(to)),
                  ],
                );
              },
            ),
          );
        },
        child: Material(type: MaterialType.transparency, child: child),
      );
}

String matterTitleTag(String path) => 'matter-title-$path';

/// Cross-fades (with a small rise) when [switchKey] changes, e.g. tab bodies.
class VFadeSwitch extends StatelessWidget {
  const VFadeSwitch({super.key, required this.switchKey, required this.child, this.duration = const Duration(milliseconds: 280)});

  final Object switchKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: duration,
        reverseDuration: const Duration(milliseconds: 140),
        switchInCurve: VMotion.enter,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [
            for (final p in previous) Positioned(left: 0.0, right: 0.0, top: 0.0, child: p),
            if (current != null) current,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 0.012), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey<Object>(switchKey), child: child),
      );
}

/// Holds a piece of chrome (sidebar, brand panel) perfectly still while the
/// page around it transitions, instead of fading it out and back in.
class StillHero extends StatelessWidget {
  const StillHero({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) => Hero(
        tag: tag,
        flightShuttleBuilder: (context, animation, direction, fromContext, toContext) => Material(
          type: MaterialType.transparency,
          child: (toContext.widget as Hero).child,
        ),
        child: child,
      );
}

/// Page padding: roomy on desktop, tight on phones.
EdgeInsets vPagePadding(BuildContext context, {double top = 36.0, double bottom = 48.0}) {
  final narrow = MediaQuery.sizeOf(context).width < 600.0;
  return EdgeInsets.fromLTRB(narrow ? 16.0 : 40.0, narrow ? 20.0 : top, narrow ? 16.0 : 40.0, bottom);
}

// ---------------------------------------------------------------------------
// Building blocks
//
// Every one of these shows its finished frame when the person has asked for
// less motion, so nothing is ever only visible mid-animation.
// ---------------------------------------------------------------------------

/// Fades in and rises a few pixels the first time it is built. [index] staggers
/// a list so it reads top to bottom instead of appearing all at once.
class VReveal extends StatefulWidget {
  const VReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.rise = 8.0,
    this.duration = const Duration(milliseconds: 280),
    this.step = const Duration(milliseconds: 40),
    this.maxStaggered = 8,
  });

  final Widget child;
  final int index;
  final double rise;
  final Duration duration, step;

  /// Rows past this many start together, so a long list doesn't crawl in.
  final int maxStaggered;

  @override
  State<VReveal> createState() => _VRevealState();
}

class _VRevealState extends State<VReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1.0;
    } else if (!_c.isAnimating && _c.value == 0.0) {
      final n = widget.index > widget.maxStaggered ? widget.maxStaggered : widget.index;
      Future.delayed(widget.step * n, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: VMotion.enter);
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0.0, widget.rise * (1.0 - t.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// A one-off wash of colour behind something that just arrived — used on a new
/// row so the eye lands on it, then fades and leaves the row as it was.
class VArriveGlow extends StatefulWidget {
  const VArriveGlow({super.key, required this.child, required this.on, this.radius = 12.0});

  final Widget child;

  /// Runs once each time this turns true.
  final bool on;
  final double radius;

  @override
  State<VArriveGlow> createState() => _VArriveGlowState();
}

class _VArriveGlowState extends State<VArriveGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.on) _run();
  }

  @override
  void didUpdateWidget(covariant VArriveGlow old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on) _run();
  }

  void _run() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _c.forward(from: 0.0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = VC.of(context).teal;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Up fast, then a slow fade out.
        final t = _c.value;
        final a = t == 0.0 ? 0.0 : (t < 0.18 ? t / 0.18 : 1.0 - (t - 0.18) / 0.82);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.10 * a.clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Counts up to [value] once, for the numbers on dashboards. Re-runs from the
/// old number whenever the value changes, so a refresh reads as a change.
class VCountUp extends StatelessWidget {
  const VCountUp({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 700),
  });

  final num value;
  final TextStyle style;
  final String suffix;
  final int decimals;
  final Duration duration;

  String _format(double v) => '${decimals == 0 ? v.round() : v.toStringAsFixed(decimals)}$suffix';

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Text(_format(value.toDouble()), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: VMotion.enter,
      builder: (context, v, _) => Text(_format(v), style: style),
    );
  }
}
