// Success moments, drawn in code (no animation files to license or load):
//
//   VSuccessBurst   a ring that pops in, a check that draws itself, and a
//                   small burst of brand-coloured sparks. Used in every
//                   success toast (small) and success screen (large).
//   celebrate()     a brief centred card with a large burst, for the bigger
//                   moments: evidence arriving, an upload finishing, a
//                   record filed. It never blocks a click and fades by itself.
//
// With "reduce motion" on, the burst shows its finished frame.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VSuccessBurst extends StatefulWidget {
  const VSuccessBurst({super.key, this.size = 56.0, this.sparks = true, this.delay = Duration.zero});

  final double size;
  final bool sparks;
  final Duration delay;

  @override
  State<VSuccessBurst> createState() => _VSuccessBurstState();
}

class _VSuccessBurstState extends State<VSuccessBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1.0;
    } else if (!_c.isAnimating && _c.value == 0.0) {
      Future.delayed(widget.delay, () {
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
    final c = VC.of(context);
    // Sparks reach past the ring, so the painter gets extra room.
    final box = widget.sparks ? widget.size * 1.9 : widget.size;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: OverflowBox(
        maxWidth: box,
        maxHeight: box,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.square(box),
            painter: _BurstPainter(
              t: _c,
              ring: c.verified,
              fill: c.verifiedBg,
              spark: [c.teal, c.verified, c.pending, c.tealDeep],
              ringSize: widget.size,
              sparks: widget.sparks,
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.t, required this.ring, required this.fill, required this.spark, required this.ringSize, required this.sparks})
      : super(repaint: t);

  final Animation<double> t;
  final Color ring, fill;
  final List<Color> spark;
  final double ringSize;
  final bool sparks;

  static double _seg(double v, double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final center = size.center(Offset.zero);
    final r = ringSize / 2.0;

    // Ring pops in with a little overshoot.
    final pop = _seg(v, 0.0, 0.35, Curves.easeOutBack);
    if (pop > 0.0) {
      canvas.drawCircle(center, r * pop, Paint()..color = fill);
      canvas.drawCircle(
        center,
        r * pop - r * 0.05,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, r * 0.1),
      );
    }

    // The check draws itself.
    final draw = _seg(v, 0.25, 0.6, Curves.easeInOutCubic);
    if (draw > 0.0) {
      final p1 = center + Offset(-r * 0.38, r * 0.02);
      final p2 = center + Offset(-r * 0.1, r * 0.3);
      final p3 = center + Offset(r * 0.42, -r * 0.3);
      final l1 = (p2 - p1).distance;
      final l2 = (p3 - p2).distance;
      final len = (l1 + l2) * draw;
      final path = Path()..moveTo(p1.dx, p1.dy);
      if (len <= l1) {
        final q = Offset.lerp(p1, p2, len / l1)!;
        path.lineTo(q.dx, q.dy);
      } else {
        path.lineTo(p2.dx, p2.dy);
        final q = Offset.lerp(p2, p3, (len - l1) / l2)!;
        path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = math.max(2.0, r * 0.16),
      );
    }

    // Sparks fly out and fade.
    if (sparks) {
      final s = _seg(v, 0.3, 1.0, Curves.easeOutQuart);
      if (s > 0.0 && s < 1.0) {
        const n = 10;
        for (var i = 0; i < n; i++) {
          final a = (i / n) * math.pi * 2 + 0.3;
          final dist = r * (1.05 + 0.75 * s) * (i.isEven ? 1.0 : 0.82);
          final p = center + Offset(math.cos(a), math.sin(a)) * dist;
          final paint = Paint()..color = spark[i % spark.length].withValues(alpha: (1.0 - s).clamp(0.0, 1.0));
          if (i % 3 == 0) {
            canvas.drawCircle(p, math.max(1.2, r * 0.07) * (1.0 - s * 0.5), paint);
          } else {
            final d = Offset(math.cos(a), math.sin(a)) * (r * 0.16 * (1.0 - s));
            canvas.drawLine(p - d, p + d, paint
              ..strokeWidth = math.max(1.2, r * 0.06)
              ..strokeCap = StrokeCap.round);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.ring != ring || old.ringSize != ringSize || old.sparks != sparks;
}

/// A brief centred success card for the bigger moments. Never blocks input.
void celebrate(BuildContext context, {required String title, String? subtitle}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Celebration(
      title: title,
      subtitle: subtitle,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.title, this.subtitle, required this.onDone});

  final String title;
  final String? subtitle;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final v = _c.value;
          final inT = Curves.easeOutBack.transform((v / 0.18).clamp(0.0, 1.0));
          final outT = Curves.easeIn.transform(((v - 0.8) / 0.2).clamp(0.0, 1.0));
          return Opacity(
            opacity: (1.0 - outT) * (v / 0.12).clamp(0.0, 1.0),
            child: Center(
              child: Transform.translate(
                offset: Offset(0.0, -12.0 * outT),
                child: Transform.scale(scale: 0.85 + 0.15 * inT, child: child),
              ),
            ),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320.0),
            margin: const EdgeInsets.all(24.0),
            padding: const EdgeInsets.fromLTRB(28.0, 28.0, 28.0, 24.0),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(VR.card),
              border: Border.all(color: c.border),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40.0, offset: Offset(0, 16))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VSuccessBurst(size: 72.0),
                const SizedBox(height: 18.0),
                Text(widget.title, textAlign: TextAlign.center, style: VT.h3(context, size: 17.0)),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 6.0),
                  Text(widget.subtitle!, textAlign: TextAlign.center, style: VT.muted(context, size: 13.0)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
