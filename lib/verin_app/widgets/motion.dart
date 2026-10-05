// Shared motion: curves, durations, the page transition and shared-element
// heroes, so every screen moves the same way.

import 'package:flutter/material.dart';

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
