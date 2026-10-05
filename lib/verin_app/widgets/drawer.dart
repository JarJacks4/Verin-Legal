// Right-side drawer — port of the Make's <Drawer>: full-height panel that
// slides in from the right over a light scrim, title row with a close button,
// scrolling body. Every sheet in the app uses this.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'atoms.dart';
import '../onboarding/tour.dart';
import '../onboarding/tours.dart' show drawerTours, drawerTourForTitle;

Future<T?> showVDrawer<T>(
  BuildContext context, {
  required Widget Function(BuildContext context) builder,
  String? title,
  double width = 500.0,
  bool scroll = true,
  String? tour,
}) {
  // First-time tips for this sheet (onboarding/tours.dart), by id or title.
  final tourId = tour ?? drawerTourForTitle[title];
  final steps = tourId == null ? null : drawerTours[tourId];
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: VC.of(context).scrim,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (dialogContext, _, __) {
      final body = Builder(builder: builder);
      return VDrawerFrame(
        title: title,
        width: width,
        scroll: scroll,
        child: steps == null
            ? body
            : TourLauncher(tourId: 'sheet_$tourId', steps: steps, delay: const Duration(milliseconds: 550), child: body),
      );
    },
    transitionBuilder: (context, anim, _, child) {
      // Glides in with a long ease-out; leaves quicker with an ease-in.
      final curved = CurvedAnimation(parent: anim, curve: const Cubic(0.22, 1.0, 0.36, 1.0), reverseCurve: const Cubic(0.4, 0.0, 1.0, 1.0));
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

class VDrawerFrame extends StatelessWidget {
  const VDrawerFrame({super.key, required this.child, this.title, this.width = 500.0, this.scroll = true});

  final Widget child;
  final String? title;
  final double width;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final w = width > screenW ? screenW : width;
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: c.card,
        elevation: 0,
        child: Container(
          width: w,
          height: double.infinity,
          decoration: BoxDecoration(
            color: c.card,
            border: Border(left: BorderSide(color: c.border)),
            boxShadow: const [BoxShadow(color: Color(0x2E172024), blurRadius: 60.0, spreadRadius: -12.0, offset: Offset(-24, 0))],
          ),
          child: SafeArea(
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24.0, 12.0, 16.0, 12.0),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                  child: Row(
                    children: [
                      if (title != null) Expanded(child: Text(title!, style: VT.h2(context, size: 18.0))) else const Spacer(),
                      VIconButton(icon: Icons.close, tooltip: 'Close', onPressed: () => Navigator.of(context).maybePop()),
                    ],
                  ),
                ),
                Expanded(
                  child: TourTarget(
                    id: 'drawer_body',
                    child: scroll
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: child,
                          )
                        : child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered modal (Data retention dialog) — rounded-2xl card on a dark scrim.
Future<T?> showVDialog<T>(BuildContext context, {required Widget Function(BuildContext) builder, double maxWidth = 448.0}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x73000000),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) {
      final c = VC.of(ctx);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: c.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VR.card), side: BorderSide(color: c.border)),
              child: Padding(padding: const EdgeInsets.all(24.0), child: Builder(builder: builder)),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: const Cubic(0.22, 1.0, 0.36, 1.0), reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut, reverseCurve: Curves.easeIn),
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// Bottom sheet with a grab handle (API access sheet in the Make).
Future<T?> showVBottomSheet<T>(BuildContext context, {required Widget Function(BuildContext) builder}) {
  final c = VC.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73000000),
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(4.0)),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
                child: Builder(builder: builder),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
