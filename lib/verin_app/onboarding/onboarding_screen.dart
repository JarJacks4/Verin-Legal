// Getting started: six short slides shown once after an account is created
// (and from Profile → Replay the walkthrough). Each slide pairs one plain
// sentence with a looping animation of that part of Verin.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/motion.dart';
import 'demos.dart';
import 'tour.dart';

const kOnboardingRoute = 'GettingStarted';
const kIntroTourId = 'intro';

class _Slide {
  const _Slide({required this.eyebrow, required this.title, required this.body, required this.demo, this.points = const []});

  final String eyebrow;
  final String title;
  final String body;
  final List<String> points;
  final Widget Function() demo;
}

List<_Slide> _slides(bool admin) => [
      _Slide(
        eyebrow: 'WELCOME',
        title: 'Welcome to Verin',
        body: 'Verin turns what your clients send you — emails, texts, photos and videos — into one organized record, ready for your review. Here is how it works, in about a minute.',
        demo: () => const ArriveDemo(),
      ),
      _Slide(
        eyebrow: 'STEP 1 · RECEIVE',
        title: 'Every matter gets its own inbox',
        body: 'Create a matter and Verin gives it a private intake address. Your client forwards evidence there — nothing to install, no accounts for them.',
        points: const ['Email and text messages (with photos) both work', 'You can also upload files yourself'],
        demo: () => const IntakeDemo(),
      ),
      _Slide(
        eyebrow: 'STEP 2 · FINGERPRINT',
        title: 'Fingerprinted the moment it arrives',
        body: 'Before anyone opens a file, Verin fingerprints it and has an independent authority time-stamp it. You can always show it is exactly what was received.',
        points: const ['SHA-256 fingerprint for every item', 'Each item linked to the one before'],
        demo: () => const SealDemo(),
      ),
      _Slide(
        eyebrow: 'STEP 3 · READ',
        title: 'Read and put in order for you',
        body: 'Verin reads screenshots, documents and video, then assembles the conversation in date order — your client on one side, the other party on the other — and points out any gaps.',
        points: const ['Duplicates are recognized, not repeated', 'Anything uncertain goes to the Review queue'],
        demo: () => const ThreadDemo(),
      ),
      _Slide(
        eyebrow: 'STEP 4 · CHECK',
        title: 'Check any line against the original',
        body: 'Click a message to see exactly where it came from in the original file. Note a transcription discrepancy, add a note, or mark it reviewed — the original is never changed and every note is kept.',
        demo: () => const VerifyDemo(),
      ),
      _Slide(
        eyebrow: 'STEP 5 · FINISH',
        title: 'Ask for what is missing, then produce',
        body: 'When something is missing, send a follow-up from your own email in one click. When you are ready, build a Bates-stamped exhibit set with redactions.',
        demo: () => const ProduceDemo(),
      ),
      _Slide(
        eyebrow: "YOU'RE SET",
        title: 'Start with your first matter',
        body: admin
            ? "We will point things out the first time you open each page. As an admin you can invite your team and connect Clio from the Admin console. Replay this any time from your profile."
            : 'We will point things out the first time you open each page. Replay this any time from your profile.',
        demo: () => const ReadyDemo(),
      ),
    ];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  final _focus = FocusNode(debugLabel: 'onboarding');
  int _index = 0;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    TourProgress.load();
    _pages.addListener(() {
      final i = (_pages.page ?? 0.0).round();
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _to(int i, int count) {
    if (i < 0) return;
    if (i >= count) {
      _finish();
      return;
    }
    _pages.animateToPage(i, duration: const Duration(milliseconds: 520), curve: VMotion.enter);
  }

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    await TourProgress.load();
    TourProgress.mark(kIntroTourId);
    if (mounted) context.goNamed('MattersList');
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final user = VUser.fromRecord(currentUserDocument);
    final slides = _slides(user.isAdmin);
    final last = _index == slides.length - 1;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _to(_index + 1, slides.length);
        } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _to(_index - 1, slides.length);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 960.0;
              final text = _TextPager(controller: _pages, slides: slides);
              final nav = _NavBar(
                index: _index,
                count: slides.length,
                onBack: () => _to(_index - 1, slides.length),
                onNext: () => _to(_index + 1, slides.length),
                onDot: (i) => _to(i, slides.length),
                last: last,
              );
              final skip = AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: last ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: last,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text('Skip intro', style: VT.body(context, size: 13.0, weight: FontWeight.w500, color: c.mutedFg)),
                  ),
                ),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 55,
                      child: StillHero(
                        tag: 'auth-panel',
                        child: _DemoPanel(slides: slides, index: _index, controller: _pages),
                      ),
                    ),
                    Expanded(
                      flex: 45,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(48.0, 24.0, 48.0, 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(alignment: Alignment.centerRight, child: skip),
                            Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440.0, maxHeight: 420.0), child: text))),
                            nav,
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const VWordmark(size: 24.0, brand: true),
                        const Spacer(),
                        skip,
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      height: box.maxHeight < 700.0 ? 240.0 : 300.0,
                      decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(VR.card)),
                      clipBehavior: Clip.antiAlias,
                      child: _DemoStage(slides: slides, index: _index, scaleDown: true),
                    ),
                    const SizedBox(height: 20.0),
                    Expanded(child: text),
                    nav,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The brand panel with the current slide's animation.
class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.slides, required this.index, required this.controller});

  final List<_Slide> slides;
  final int index;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      color: c.panel,
      padding: const EdgeInsets.fromLTRB(48.0, 40.0, 48.0, 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VWordmark(size: 30.0, onDark: true, anchor: true),
          Expanded(child: _DemoStage(slides: slides, index: index)),
          // Progress along the bottom of the panel.
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final p = controller.hasClients && controller.position.haveDimensions ? (controller.page ?? 0.0) : index.toDouble();
              return ClipRRect(
                borderRadius: BorderRadius.circular(999.0),
                child: LinearProgressIndicator(
                  value: ((p + 1.0) / slides.length).clamp(0.0, 1.0),
                  minHeight: 3.0,
                  backgroundColor: c.onPanelA(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(c.onPanel),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Cross-fades between slide animations with a gentle zoom.
class _DemoStage extends StatelessWidget {
  const _DemoStage({required this.slides, required this.index, this.scaleDown = false});

  final List<_Slide> slides;
  final int index;
  final bool scaleDown;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 560),
      reverseDuration: const Duration(milliseconds: 260),
      switchInCurve: VMotion.enter,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween<double>(begin: 0.94, end: 1.0).animate(a), child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FittedBox(fit: BoxFit.scaleDown, child: slides[index].demo()),
          ),
        ),
      ),
    );
  }
}

/// The words, one page per slide, with a slight parallax as you swipe.
class _TextPager extends StatelessWidget {
  const _TextPager({required this.controller, required this.slides});

  final PageController controller;
  final List<_Slide> slides;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return PageView.builder(
      key: const PageStorageKey<String>('onboarding-text'),
      controller: controller,
      itemCount: slides.length,
      itemBuilder: (context, i) {
        final s = slides[i];
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            double d = 0.0;
            if (controller.hasClients && controller.position.haveDimensions) d = (controller.page ?? 0.0) - i;
            return Opacity(
              opacity: (1.0 - d.abs() * 1.2).clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(d * 60.0, 0.0), child: child),
            );
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.eyebrow, style: VT.eyebrow(context, size: 11.0, spacing: 0.14)),
                const SizedBox(height: 10.0),
                Text(s.title, style: VT.h1(context, size: 32.0)),
                const SizedBox(height: 14.0),
                Text(s.body, style: VT.muted(context, size: 16.0, height: 1.6)),
                if (s.points.isNotEmpty) ...[
                  const SizedBox(height: 18.0),
                  for (final p in s.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.check_circle_outline_rounded, size: 17.0, color: c.teal),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(child: Text(p, style: VT.body(context, size: 14.0))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.count,
    required this.onBack,
    required this.onNext,
    required this.onDot,
    required this.last,
  });

  final int index;
  final int count;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<int> onDot;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: index == 0 ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring: index == 0,
              child: VButton(label: 'Back', icon: Icons.arrow_back, kind: VButtonKind.secondary, onPressed: onBack),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  GestureDetector(
                    onTap: () => onDot(i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 8.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: VMotion.enter,
                        width: i == index ? 22.0 : 7.0,
                        height: 7.0,
                        decoration: BoxDecoration(
                          color: i == index ? c.teal : c.mutedFg.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: VButton(
              key: ValueKey<bool>(last),
              label: last ? 'Open my matters' : 'Next',
              trailingIcon: Icons.arrow_forward,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
