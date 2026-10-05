// Launch splash: the Verin Legal mark and name on the brand navy. It sits
// above the whole router (MaterialApp.router's builder) so it survives the
// first route changes, waits for sign-in state, then flies the mark into the
// logo on the first screen (any VMark with anchor: true) while the navy
// fades away.
//
// web/index.html paints the same layout before Flutter boots and fades out
// over it, so the hand-off is seamless.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/nav/nav.dart' show AppStateNotifier;
import '../widgets/atoms.dart';

const double kSplashMarkSize = 88.0;
const double kSplashGap = 28.0;
const double kSplashTitleSize = 34.0;

class VSplashOverlay extends StatefulWidget {
  const VSplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<VSplashOverlay> createState() => _VSplashOverlayState();
}

class _VSplashOverlayState extends State<VSplashOverlay> with TickerProviderStateMixin {
  // Gentle settle while waiting (the HTML splash already did the build-up).
  late final AnimationController _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));

  final _markKey = GlobalKey();
  final _app = AppStateNotifier.instance;

  bool _fontsReady = false;
  bool _minHeld = false;
  bool _exiting = false;
  bool _done = false;

  Rect? _from;
  ({Rect rect, Color base, Color accent})? _to;

  @override
  void initState() {
    super.initState();
    BrandAnchor.hidden.value = true;
    _app.addListener(_maybeExit);
    final title = _titleStyle();
    GoogleFonts.pendingFonts([title])
        .timeout(const Duration(milliseconds: 900), onTimeout: () => const [])
        .catchError((_) => const <void>[])
        .whenComplete(() {
      if (mounted) setState(() => _fontsReady = true);
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      _minHeld = true;
      _maybeExit();
    });
  }

  @override
  void dispose() {
    _app.removeListener(_maybeExit);
    _settle.dispose();
    _exit.dispose();
    super.dispose();
  }

  TextStyle _titleStyle() => GoogleFonts.spectral(
        fontSize: kSplashTitleSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        height: 1.2,
        color: kBrandPaper,
      );

  Future<void> _maybeExit() async {
    if (_exiting || _done || !_minHeld || _app.loading || !mounted) return;
    _exiting = true;
    _app.removeListener(_maybeExit);

    // Let the first screen build (and FirmGate settle), then find its logo.
    final screen = MediaQuery.sizeOf(context);
    ({Rect rect, Color base, Color accent})? target;
    for (var i = 0; i < 14 && target == null; i++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      target = BrandAnchor.find(screen);
    }

    final box = _markKey.currentContext?.findRenderObject();
    final from = box is RenderBox && box.attached ? box.localToGlobal(Offset.zero) & box.size : null;
    setState(() {
      _from = from;
      _to = target;
    });
    await _exit.forward();
    BrandAnchor.hidden.value = false;
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    // Same tree shape before and after, so the router is never rebuilt.
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_done)
          Positioned.fill(
          child: AbsorbPointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_settle, _exit]),
              builder: (context, _) => _layer(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _layer(BuildContext context) {
    final e = _exit.value;
    final fade = Curves.easeInOut.transform(const Interval(0.3, 1.0).transform(e));
    final textOut = Curves.easeIn.transform(const Interval(0.0, 0.3).transform(e));
    final settle = Curves.easeOutCubic.transform(_settle.value);
    final flying = _exiting && _from != null;

    final column = Center(
      child: Transform.scale(
        scale: 0.985 + 0.015 * settle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              key: _markKey,
              dimension: kSplashMarkSize,
              child: flying ? null : const VMark(size: kSplashMarkSize, baseColor: kBrandPaper, accentColor: kBrandTeal),
            ),
            const SizedBox(height: kSplashGap),
            Opacity(
              opacity: (1.0 - textOut) * (_fontsReady ? 1.0 : 0.0),
              child: Transform.translate(
                offset: Offset(0.0, -8.0 * textOut),
                child: Text('Verin Legal', textAlign: TextAlign.center, style: _titleStyle()),
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(opacity: 1.0 - fade, child: const ColoredBox(color: kBrandNavy)),
          column,
          if (flying) _flyingMark(e),
        ],
      ),
    );
  }

  Widget _flyingMark(double e) {
    final from = _from!;
    final to = _to;
    final t = const Cubic(0.65, 0.0, 0.35, 1.0).transform(const Interval(0.05, 0.9).transform(e));
    if (to == null) {
      // Nowhere to land: lift and fade with the navy.
      final s = 1.0 + 0.08 * t;
      final r = Rect.fromCenter(center: from.center, width: from.width * s, height: from.height * s);
      return Positioned.fromRect(
        rect: r,
        child: Opacity(
          opacity: 1.0 - Curves.easeIn.transform(e),
          child: const VMark(size: kSplashMarkSize, baseColor: kBrandPaper, accentColor: kBrandTeal),
        ),
      );
    }
    // A slight arc reads as a flight rather than a slide.
    final rect = Rect.lerp(from, to.rect, t)!;
    final lift = math.sin(t * math.pi) * math.min(40.0, (from.center - to.rect.center).distance * 0.08);
    return Positioned.fromRect(
      rect: rect.shift(Offset(0.0, -lift)),
      child: VMark(
        size: rect.width,
        baseColor: Color.lerp(kBrandPaper, to.base, t),
        accentColor: Color.lerp(kBrandTeal, to.accent, t),
      ),
    );
  }
}
