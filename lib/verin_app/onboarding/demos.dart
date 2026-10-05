// Short looping animations of Verin at work, drawn in code so they stay
// sharp and always look like the app. Each runs on its own clock; with
// "reduce motion" on they hold on a finished frame.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';

/// Progress of [t] through [a]..[b], eased.
double seg(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// Runs [builder] with a 0→1 value that loops every [period], fading the
/// last moments so the restart is soft.
class LoopDemo extends StatefulWidget {
  const LoopDemo({super.key, required this.period, required this.builder});

  final Duration period;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<LoopDemo> createState() => _LoopDemoState();
}

class _LoopDemoState extends State<LoopDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.88;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final fade = 1.0 - seg(t, 0.94, 1.0, Curves.easeIn);
          return Opacity(opacity: fade, child: widget.builder(context, t));
        },
      );
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// A small app "window" the demos draw inside.
class DemoWindow extends StatelessWidget {
  const DemoWindow({super.key, required this.child, this.title, this.width = 340.0});

  final Widget child;
  final String? title;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 40.0, offset: Offset(0, 18))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 10.0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: [
                for (final col in const [Color(0xFFE0716B), Color(0xFFE5B84E), Color(0xFF6CC17A)]) ...[
                  Container(width: 8.0, height: 8.0, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                  const SizedBox(width: 5.0),
                ],
                const SizedBox(width: 6.0),
                if (title != null)
                  Expanded(
                    child: Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 11.5, weight: FontWeight.w600, color: c.mutedFg)),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14.0), child: child),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.sub, this.badge});

  final IconData icon;
  final String title;
  final String sub;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 9.0),
      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(10.0), border: Border.all(color: c.border)),
      child: Row(
        children: [
          Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(color: c.tealPale, borderRadius: BorderRadius.circular(8.0)),
            child: Icon(icon, size: 15.0, color: c.tealDeep),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 12.0, weight: FontWeight.w600, height: 1.3)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.muted(context, size: 10.5, height: 1.3)),
              ],
            ),
          ),
          if (badge != null) badge!,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.icon, this.good = true});

  final String label;
  final IconData? icon;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final fg = good ? c.verified : c.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
      decoration: BoxDecoration(color: good ? c.verifiedBg : c.pendingBg, borderRadius: BorderRadius.circular(999.0)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? (good ? Icons.verified_outlined : Icons.help_outline), size: 11.0, color: fg),
          const SizedBox(width: 4.0),
          Text(label, style: VT.body(context, size: 10.0, weight: FontWeight.w600, color: fg, height: 1.2)),
        ],
      ),
    );
  }
}

/// Fades and lifts [child] in as [p] goes 0→1.
Widget rise(double p, Widget child, {double dy = 14.0}) => Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0.0, (1.0 - p) * dy), child: child),
    );

/// Scales [child] in with a little overshoot.
Widget pop(double p, Widget child) {
  final s = Curves.easeOutBack.transform(p.clamp(0.0, 1.0));
  return Opacity(opacity: p.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * s, child: child));
}

// ---------------------------------------------------------------------------
// 0 · Welcome: evidence arrives and files itself
// ---------------------------------------------------------------------------

class ArriveDemo extends StatelessWidget {
  const ArriveDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    const items = [
      (Icons.mail_outline, 'Email · Re: pickup schedule', 'From client · 3 attachments'),
      (Icons.sms_outlined, 'Text messages · 14 screenshots', 'From client · Mar 7–12'),
      (Icons.videocam_outlined, 'Video · driveway.mov', 'From client · 0:48'),
    ];
    return LoopDemo(
      period: const Duration(milliseconds: 6500),
      builder: (context, t) => SizedBox(
        width: 380.0,
        height: 300.0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            DemoWindow(
              title: 'Miller v. Miller · Custody',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Receipts', style: VT.h3(context, size: 13.0)),
                      const Spacer(),
                      Text('${[0.22, 0.42, 0.62].where((a) => t > a + 0.1).length} items', style: VT.muted(context, size: 11.0)),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8.0),
                    rise(
                      seg(t, 0.22 + i * 0.2, 0.34 + i * 0.2),
                      _Row(
                        icon: items[i].$1,
                        title: items[i].$2,
                        sub: items[i].$3,
                        badge: pop(seg(t, 0.32 + i * 0.2, 0.4 + i * 0.2), const _Pill('Sealed')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Items flying in from the client's phone.
            for (var i = 0; i < items.length; i++)
              _Flyer(
                p: seg(t, 0.08 + i * 0.2, 0.3 + i * 0.2, Curves.easeInOutCubic),
                from: Offset(-230.0 + i * 20.0, -150.0 + i * 120.0),
                to: Offset(0.0, -18.0 + i * 50.0),
                child: Container(
                  width: 34.0,
                  height: 34.0,
                  decoration: BoxDecoration(color: c.teal, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.teal.withValues(alpha: 0.5), blurRadius: 16.0)]),
                  child: Icon(items[i].$1, size: 17.0, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Flyer extends StatelessWidget {
  const _Flyer({required this.p, required this.from, required this.to, required this.child});

  final double p;
  final Offset from, to;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (p <= 0.0 || p >= 1.0) return const SizedBox.shrink();
    final pos = Offset.lerp(from, to, p)! + Offset(0.0, -math.sin(p * math.pi) * 40.0);
    final o = p < 0.15 ? p / 0.15 : (p > 0.8 ? (1.0 - p) / 0.2 : 1.0);
    return Transform.translate(offset: pos, child: Opacity(opacity: o, child: Transform.scale(scale: 1.0 - 0.4 * p, child: child)));
  }
}

// ---------------------------------------------------------------------------
// 1 · Intake: the client forwards to the matter's address
// ---------------------------------------------------------------------------

class IntakeDemo extends StatelessWidget {
  const IntakeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return LoopDemo(
      period: const Duration(milliseconds: 6000),
      builder: (context, t) {
        final sent = seg(t, 0.3, 0.5, Curves.easeInOutCubic);
        return SizedBox(
          width: 400.0,
          height: 300.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The client's phone.
              Positioned(
                left: 0.0,
                top: 20.0,
                child: Container(
                  width: 150.0,
                  height: 260.0,
                  padding: const EdgeInsets.fromLTRB(10.0, 18.0, 10.0, 10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111A1F),
                    borderRadius: BorderRadius.circular(26.0),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('To: miller-4821@in.verinlegal.com',
                          maxLines: 2, style: VT.body(context, size: 8.5, color: Colors.white.withValues(alpha: 0.7), height: 1.3)),
                      const SizedBox(height: 10.0),
                      rise(
                        seg(t, 0.05, 0.2),
                        Opacity(
                          opacity: 1.0 - sent * 0.6,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(color: c.teal, borderRadius: BorderRadius.circular(12.0)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fwd: screenshots from Saturday', style: VT.body(context, size: 9.5, weight: FontWeight.w600, color: Colors.white, height: 1.3)),
                                const SizedBox(height: 6.0),
                                Row(
                                  children: [
                                    for (var i = 0; i < 3; i++) ...[
                                      Container(
                                        width: 26.0,
                                        height: 34.0,
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4.0)),
                                      ),
                                      const SizedBox(width: 4.0),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: pop(seg(t, 0.2, 0.3), Text(t > 0.3 ? 'Sent ✓' : 'Sending…', style: VT.body(context, size: 9.0, color: Colors.white.withValues(alpha: 0.7)))),
                      ),
                    ],
                  ),
                ),
              ),
              // The envelope travelling across.
              if (sent > 0.0 && sent < 1.0)
                Positioned(
                  left: 130.0 + sent * 120.0,
                  top: 110.0 - math.sin(sent * math.pi) * 50.0,
                  child: Icon(Icons.mail, size: 26.0, color: c.paper.withValues(alpha: 1.0 - sent * 0.3)),
                ),
              // The matter's intake.
              Positioned(
                right: 0.0,
                top: 40.0,
                child: DemoWindow(
                  width: 200.0,
                  title: 'Intake channel',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MATTER ADDRESS', style: VT.eyebrow(context, size: 9.0)),
                      const SizedBox(height: 4.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        decoration: BoxDecoration(color: c.inputBg, borderRadius: BorderRadius.circular(8.0)),
                        child: Row(
                          children: [
                            Expanded(child: Text('miller-4821@in.verinlegal.com', maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.mono(context, size: 9.0))),
                            Icon(Icons.copy_rounded, size: 12.0, color: c.teal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      rise(
                        seg(t, 0.5, 0.62),
                        const _Row(icon: Icons.mail_outline, title: 'Fwd: screenshots…', sub: 'Received 2:14 PM', badge: null),
                      ),
                      const SizedBox(height: 8.0),
                      Align(alignment: Alignment.centerRight, child: pop(seg(t, 0.62, 0.72), const _Pill('3 files received'))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Sealed on arrival: fingerprint + independent timestamp
// ---------------------------------------------------------------------------

class SealDemo extends StatelessWidget {
  const SealDemo({super.key});

  static const _hash = '9f2c7a1e 44b0d39c e81f6a27 0b5d92e4 c3a18f70 6e2b5d11 a97c04f3 58e2b6d0';

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return LoopDemo(
      period: const Duration(milliseconds: 6000),
      builder: (context, t) {
        final typed = (seg(t, 0.12, 0.45, Curves.linear) * _hash.length).round();
        final stamp = seg(t, 0.5, 0.62);
        return DemoWindow(
          width: 360.0,
          title: 'Integrity · IMG_2041.jpg',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Row(icon: Icons.image_outlined, title: 'IMG_2041.jpg', sub: '2.4 MB · received Mar 12, 2:14 PM'),
              const SizedBox(height: 12.0),
              Text('SHA-256 FINGERPRINT', style: VT.eyebrow(context, size: 9.0)),
              const SizedBox(height: 4.0),
              Container(
                height: 46.0,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(color: c.inputBg, borderRadius: BorderRadius.circular(8.0)),
                child: Text(
                  '${_hash.substring(0, typed)}${typed < _hash.length && t > 0.1 ? '▌' : ''}',
                  style: VT.mono(context, size: 10.0, color: c.tealDeep),
                ),
              ),
              const SizedBox(height: 14.0),
              Row(
                children: [
                  pop(
                    stamp,
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.verified, width: 2.0),
                        color: c.verifiedBg,
                      ),
                      child: Icon(Icons.verified_rounded, color: c.verified, size: 28.0),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: rise(
                      seg(t, 0.56, 0.68),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time-stamped (RFC 3161)', style: VT.body(context, size: 12.5, weight: FontWeight.w600)),
                          Text('Independent authority · Mar 12, 2:14:07 PM', style: VT.muted(context, size: 10.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
              // The chain: each item linked to the one before.
              Row(
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i > 0)
                      Expanded(
                        child: Container(height: 2.0, color: Color.lerp(c.border, c.teal, seg(t, 0.66 + i * 0.04, 0.72 + i * 0.04))),
                      ),
                    Container(
                      width: 18.0,
                      height: 18.0,
                      decoration: BoxDecoration(
                        color: Color.lerp(c.muted, c.teal, seg(t, 0.64 + i * 0.04, 0.7 + i * 0.04)),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Icon(Icons.link_rounded, size: 11.0, color: Colors.white.withValues(alpha: seg(t, 0.64 + i * 0.04, 0.7 + i * 0.04))),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6.0),
              Opacity(opacity: seg(t, 0.84, 0.9), child: Text('Chain intact · 5 of 5 linked', style: VT.muted(context, size: 10.5))),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Thread: the conversation rebuilt in order, with gaps flagged
// ---------------------------------------------------------------------------

class ThreadDemo extends StatelessWidget {
  const ThreadDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    const lines = [
      (false, 'Can you have her ready by 5?'),
      (true, 'She has practice until 5:30.'),
      (false, "Then I'm keeping her Sunday."),
      (true, "That's not the schedule."),
    ];
    Widget bubble(bool client, String text, double p, {bool source = false}) => rise(
          p,
          Align(
            alignment: client ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 210.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
              decoration: BoxDecoration(
                color: client ? c.teal : c.muted,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12.0),
                  topRight: const Radius.circular(12.0),
                  bottomLeft: Radius.circular(client ? 12.0 : 3.0),
                  bottomRight: Radius.circular(client ? 3.0 : 12.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, style: VT.body(context, size: 11.5, color: client ? Colors.white : c.foreground, height: 1.35)),
                  if (source)
                    Opacity(
                      opacity: seg(p, 0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_outlined, size: 10.0, color: (client ? Colors.white : c.mutedFg).withValues(alpha: 0.8)),
                            const SizedBox(width: 3.0),
                            Text('IMG_2041.jpg', style: VT.body(context, size: 9.0, color: (client ? Colors.white : c.mutedFg).withValues(alpha: 0.8), height: 1.2)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          dy: 10.0,
        );
    return LoopDemo(
      period: const Duration(milliseconds: 7000),
      builder: (context, t) => DemoWindow(
        width: 360.0,
        title: 'Thread · reconstructed',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Other side', style: VT.eyebrow(context, size: 9.0, color: c.mutedFg)),
                const Spacer(),
                Text('Client', style: VT.eyebrow(context, size: 9.0)),
              ],
            ),
            const SizedBox(height: 8.0),
            Opacity(
              opacity: seg(t, 0.02, 0.1),
              child: _Divider(label: 'Sat, Mar 7'),
            ),
            const SizedBox(height: 6.0),
            bubble(lines[0].$1, lines[0].$2, seg(t, 0.08, 0.18)),
            const SizedBox(height: 6.0),
            bubble(lines[1].$1, lines[1].$2, seg(t, 0.18, 0.28), source: true),
            const SizedBox(height: 10.0),
            // A gap: days missing from the record.
            rise(
              seg(t, 0.36, 0.46),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: c.pendingBg,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: c.pending.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 13.0, color: c.pending),
                    const SizedBox(width: 6.0),
                    Expanded(child: Text('Gap · Mar 8–9 not in the record', style: VT.body(context, size: 10.5, weight: FontWeight.w600, color: c.pending, height: 1.3))),
                    Text('Ask client', style: VT.body(context, size: 10.0, weight: FontWeight.w600, color: c.teal, height: 1.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Opacity(opacity: seg(t, 0.5, 0.56), child: _Divider(label: 'Tue, Mar 10')),
            const SizedBox(height: 6.0),
            bubble(lines[2].$1, lines[2].$2, seg(t, 0.56, 0.66)),
            const SizedBox(height: 6.0),
            bubble(lines[3].$1, lines[3].$2, seg(t, 0.66, 0.76)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Row(
      children: [
        Expanded(child: Container(height: 1.0, color: c.border)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(label, style: VT.muted(context, size: 10.0))),
        Expanded(child: Container(height: 1.0, color: c.border)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4 · Verify: every line traced back to the original
// ---------------------------------------------------------------------------

class VerifyDemo extends StatelessWidget {
  const VerifyDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return LoopDemo(
      period: const Duration(milliseconds: 6500),
      builder: (context, t) {
        // Which line is being checked (moves down the screenshot).
        final step = t < 0.3 ? 0 : (t < 0.55 ? 1 : 2);
        final glide = seg(t, step == 0 ? 0.1 : (step == 1 ? 0.3 : 0.55), step == 0 ? 0.2 : (step == 1 ? 0.4 : 0.65), Curves.easeInOutCubic);
        final rows = [24.0, 70.0, 116.0];
        final prevTop = step == 0 ? rows[0] : rows[step - 1];
        final top = prevTop + (rows[step] - prevTop) * glide;
        final done = seg(t, 0.72, 0.82);
        return DemoWindow(
          width: 380.0,
          title: 'Verify against the original',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The original screenshot.
              Container(
                width: 130.0,
                height: 190.0,
                decoration: BoxDecoration(color: const Color(0xFF111A1F), borderRadius: BorderRadius.circular(14.0)),
                child: Stack(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        top: rows[i] + 6.0,
                        left: i.isOdd ? 40.0 : 10.0,
                        right: i.isOdd ? 10.0 : 40.0,
                        child: Container(height: 26.0, decoration: BoxDecoration(color: i.isOdd ? c.teal : const Color(0xFF3A464C), borderRadius: BorderRadius.circular(8.0))),
                      ),
                    Positioned(
                      top: top,
                      left: 4.0,
                      right: 4.0,
                      child: Container(
                        height: 38.0,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFF4C842), width: 2.0),
                          color: const Color(0x33F4C842),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: step == i && done == 0.0 ? const Color(0x26F4C842) : c.background,
                          border: Border.all(color: step == i && done == 0.0 ? const Color(0xFFF4C842) : c.border),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(const ['Can you have her ready by 5?', 'She has practice until 5:30.', "Then I'm keeping her Sunday."][i],
                                  style: VT.body(context, size: 10.5, height: 1.3)),
                            ),
                            if (step > i || done > 0.0) Icon(Icons.check_circle_rounded, size: 13.0, color: c.verified),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    const SizedBox(height: 4.0),
                    Align(alignment: Alignment.centerLeft, child: pop(done, const _Pill('Reviewed · matches original'))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 5 · Follow up and produce exhibits
// ---------------------------------------------------------------------------

class ProduceDemo extends StatelessWidget {
  const ProduceDemo({super.key});

  static const _ask = 'Hi Dana — could you send the messages from March 8–9? They are missing from what we have.';

  @override
  Widget build(BuildContext context) {
    return LoopDemo(
      period: const Duration(milliseconds: 7500),
      builder: (context, t) {
        final typed = (seg(t, 0.05, 0.3, Curves.linear) * _ask.length).round();
        final fan = seg(t, 0.48, 0.66, Curves.easeOutBack);
        return SizedBox(
          width: 400.0,
          height: 310.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0.0,
                top: 0.0,
                child: Opacity(
                  opacity: 1.0 - seg(t, 0.42, 0.5) * 0.45,
                  child: DemoWindow(
                    width: 260.0,
                    title: 'Follow-up · missing evidence',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To: client', style: VT.muted(context, size: 10.0)),
                        const SizedBox(height: 6.0),
                        SizedBox(
                          height: 44.0,
                          child: Text(_ask.substring(0, typed), style: VT.body(context, size: 10.5, height: 1.4)),
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            pop(seg(t, 0.3, 0.36), const _Pill('Opens in your email', icon: Icons.send_rounded)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Exhibit pages fanning out, Bates-stamped, one redaction.
              for (var i = 0; i < 3; i++)
                Positioned(
                  right: 10.0 + (2 - i) * 34.0 * fan,
                  top: 110.0 + (2 - i) * 6.0 * fan,
                  child: Transform.rotate(
                    angle: (i - 1) * 0.07 * fan,
                    child: Opacity(
                      opacity: seg(t, 0.44 + i * 0.03, 0.52 + i * 0.03),
                      child: Container(
                        width: 140.0,
                        height: 182.0,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.0),
                          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18.0, offset: Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EXHIBIT ${String.fromCharCode(65 + i)}', style: VT.eyebrow(context, size: 8.0, color: const Color(0xFF172024))),
                            const SizedBox(height: 8.0),
                            for (var l = 0; l < 6; l++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Stack(
                                  children: [
                                    Container(height: 5.0, width: l.isEven ? 110.0 : 86.0, color: const Color(0xFFE3E0D9)),
                                    if (i == 2 && l == 2)
                                      Container(
                                        height: 7.0,
                                        width: 70.0 * seg(t, 0.72, 0.8),
                                        color: const Color(0xFF111111),
                                      ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Opacity(
                                opacity: seg(t, 0.66 + i * 0.03, 0.72 + i * 0.03),
                                child: Text('VRN-00010${i + 1}', style: VT.mono(context, size: 8.5, color: const Color(0xFF172024), weight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0.0,
                bottom: 0.0,
                child: pop(seg(t, 0.82, 0.9), const _Pill('Production ready · ZIP + index')),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 6 · Ready: the three things to do first
// ---------------------------------------------------------------------------

class ReadyDemo extends StatelessWidget {
  const ReadyDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    const tasks = ['Create a matter', 'Send the client its intake address', 'Review the record as it fills in'];
    return LoopDemo(
      period: const Duration(milliseconds: 5000),
      builder: (context, t) => DemoWindow(
        width: 320.0,
        title: 'Getting started',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0) const SizedBox(height: 10.0),
              Row(
                children: [
                  pop(
                    seg(t, 0.15 + i * 0.18, 0.27 + i * 0.18),
                    Container(
                      width: 22.0,
                      height: 22.0,
                      decoration: BoxDecoration(color: c.verified, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 14.0, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      tasks[i],
                      style: VT.body(context, size: 13.0, weight: FontWeight.w500, color: Color.lerp(c.mutedFg, c.foreground, seg(t, 0.15 + i * 0.18, 0.27 + i * 0.18))),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(999.0),
              child: LinearProgressIndicator(
                value: seg(t, 0.1, 0.7, Curves.easeInOut),
                minHeight: 6.0,
                backgroundColor: c.muted,
                valueColor: AlwaysStoppedAnimation<Color>(c.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The brand mark building itself, for the first slide's corner.
class MarkBuildDemo extends StatefulWidget {
  const MarkBuildDemo({super.key, this.size = 56.0});

  final double size;

  @override
  State<MarkBuildDemo> createState() => _MarkBuildDemoState();
}

class _MarkBuildDemoState extends State<MarkBuildDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VMark(size: widget.size, onDark: true, reveal: _c);
}
