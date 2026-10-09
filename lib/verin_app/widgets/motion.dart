// Shared motion: curves, durations, the page transition and shared-element
// heroes, so every screen moves the same way.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VMotion {
  static const Curve enter = Cubic(0.22, 1.0, 0.36, 1.0); // easeOutQuint-ish
  static const Curve exit = Cubic(0.55, 0.0, 1.0, 0.45);
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Duration page = Duration(milliseconds: 380);

  /// Overshoots a little and settles — the curve for anything that should
  /// read as arriving rather than merely appearing.
  static const Curve spring = Cubic(0.17, 0.89, 0.32, 1.28);
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
    this.rise = 18.0,
    this.slide = 0.0,
    this.scaleFrom = 0.96,
    this.duration = const Duration(milliseconds: 460),
    this.step = const Duration(milliseconds: 55),
    this.maxStaggered = 10,
  });

  final Widget child;
  final int index;

  /// Pixels it travels up into place.
  final double rise;

  /// Pixels it travels in from the right — for rows that should read as
  /// arriving from somewhere, not fading up in place.
  final double slide;

  /// Starting scale. 1.0 turns the grow-into-place off.
  final double scaleFrom;
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
    final t = CurvedAnimation(parent: _c, curve: VMotion.spring);
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) {
        final v = t.value;
        // Opacity leads the movement, so nothing is ever a ghost mid-flight.
        final fade = (v * 1.6).clamp(0.0, 1.0);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(widget.slide * (1.0 - v), widget.rise * (1.0 - v)),
            child: widget.scaleFrom == 1.0
                ? child
                : Transform.scale(scale: widget.scaleFrom + (1.0 - widget.scaleFrom) * v, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A one-off wash of colour behind something that just arrived — used on a new
/// row so the eye lands on it, then fades and leaves the row as it was.
class VArriveGlow extends StatefulWidget {
  const VArriveGlow({super.key, required this.child, required this.on, this.pulses = 3});

  final Widget child;

  /// Runs once each time this turns true.
  final bool on;

  /// How many times it breathes before settling.
  final int pulses;

  @override
  State<VArriveGlow> createState() => _VArriveGlowState();
}

class _VArriveGlowState extends State<VArriveGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

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
        final t = _c.value;
        if (t == 0.0 || t == 1.0) return child!;
        // Breathes [pulses] times, each one fainter, then settles to nothing.
        final wave = 0.5 - 0.5 * math.cos(t * widget.pulses * 2 * math.pi);
        final a = (wave * (1.0 - t)).clamp(0.0, 1.0);
        // A one-sided border and a corner radius can't be painted together,
        // and the glowed row is square anyway.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.16 * a),
            border: Border(left: BorderSide(color: tone.withValues(alpha: a), width: 3.0)),
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

/// Springs in from nothing, overshooting slightly — for a badge, a count or a
/// tick that should land rather than fade up. Re-runs whenever [trigger]
/// changes, so the same widget can pop again on each new value.
class VPop extends StatefulWidget {
  const VPop({super.key, required this.child, this.trigger, this.from = 0.6, this.duration = const Duration(milliseconds: 420)});

  final Widget child;
  final Object? trigger;
  final double from;
  final Duration duration;

  @override
  State<VPop> createState() => _VPopState();
}

class _VPopState extends State<VPop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1.0;
    } else if (_c.value == 0.0) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(covariant VPop old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && !MediaQuery.disableAnimationsOf(context)) _c.forward(from: 0.0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: VMotion.spring);
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Transform.scale(
        scale: widget.from + (1.0 - widget.from) * t.value,
        child: Opacity(opacity: (t.value * 2.0).clamp(0.0, 1.0), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Lifts and brightens under the pointer. Cards that do something when
/// clicked should feel like they are waiting to be clicked.
class VLift extends StatefulWidget {
  const VLift({super.key, required this.child, this.lift = 3.0, this.onTap});

  final Widget child;
  final double lift;
  final VoidCallback? onTap;

  @override
  State<VLift> createState() => _VLiftState();
}

class _VLiftState extends State<VLift> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _on = true),
      onExit: (_) => setState(() => _on = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: still ? Duration.zero : const Duration(milliseconds: 180),
          curve: VMotion.standard,
          transform: Matrix4.translationValues(0.0, _on && !still ? -widget.lift : 0.0, 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VR.card),
            boxShadow: _on && !still
                ? [BoxShadow(color: c.teal.withValues(alpha: 0.18), blurRadius: 18.0, offset: const Offset(0.0, 6.0))]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A band of light travelling across a placeholder block while real content
/// loads, instead of a spinner that says nothing about what is coming.
class VShimmer extends StatefulWidget {
  const VShimmer({super.key, this.width, this.height = 14.0, this.radius = 6.0});

  final double? width;
  final double height, radius;

  @override
  State<VShimmer> createState() => _VShimmerState();
}

class _VShimmerState extends State<VShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-3.0 + 4.0 * _c.value, 0.0),
              end: Alignment(-1.0 + 4.0 * _c.value, 0.0),
              colors: [c.secondary, c.border, c.secondary],
            ),
          ),
        ),
      ),
    );
  }
}
