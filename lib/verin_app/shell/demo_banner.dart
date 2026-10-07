// NFR demo workspace: the banner shown on every screen of a demo firm, the
// reset action, and the Settings card that turns an empty workspace into one.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_api.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import '../onboarding/tour.dart';
import '../demo/data_handling.dart';
import '../demo/demo_runs.dart';
import '/flutter_flow/flutter_flow_util.dart';

bool isDemoFirm(FirmAccountRecord? f) => f?.snapshotData['isDemo'] == true;
bool demoResetting(FirmAccountRecord? f) => f?.snapshotData['demoResetting'] == true;

/// Asks, then rebuilds the sample matters. Returns true when done.
Future<bool> resetDemo(BuildContext context, {bool first = false}) async {
  final ok = await showVDialog<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(first ? 'Make this an NFR demo workspace?' : 'Reset the demo?', style: VT.h2(ctx, size: 18.0)),
        const SizedBox(height: 8.0),
        Text(
          first
              ? 'Adds seven fictional matters covering family law, personal injury, immigration, civil litigation and criminal defense, with real screenshots, an email, PDFs, annotations and three months of value history. '
                  'Use this account only for demonstrations — not for client work.'
              : 'Everything in this workspace — including anything added during a demo — is deleted and replaced with the original sample matters. '
                  'Takes about a minute.',
          style: VT.muted(ctx, size: 13.0),
        ),
        const SizedBox(height: 18.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            VButton(label: 'Cancel', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
            const SizedBox(width: 8.0),
            VButton(label: first ? 'Set up demo' : 'Reset demo', icon: Icons.restart_alt, onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  showVToast(context, first ? 'Preparing the demo workspace…' : 'Resetting the demo…', description: 'This takes about a minute.');
  try {
    final r = await VerinApi.seedDemoWorkspace();
    if (context.mounted) showVToast(context, 'Demo ready', description: '${r['matters'] ?? 7} matters · ${r['items'] ?? ''} items');
    return true;
  } catch (e) {
    if (context.mounted) showVToast(context, 'The demo could not be prepared', error: true, description: e is VerinApiException ? e.message : '$e');
    return false;
  }
}

/// Thin strip across the top of every screen in a demo workspace.
class DemoBanner extends StatefulWidget {
  const DemoBanner({super.key, required this.firm, required this.user});

  final FirmAccountRecord? firm;
  final VUser user;

  @override
  State<DemoBanner> createState() => _DemoBannerState();
}

class _DemoBannerState extends State<DemoBanner> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final resetting = _busy || demoResetting(widget.firm);
    const fg = Color(0xFF3A2A00);
    // Phones: short text and icon-only buttons.
    final narrow = MediaQuery.sizeOf(context).width < 640.0;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: !isDemoFirm(widget.firm)
          ? const SizedBox(width: double.infinity)
          : TourTarget(
              id: 'demo_strip',
              child: Container(
              width: double.infinity,
              color: const Color(0xFFF4C842),
              padding: EdgeInsets.symmetric(horizontal: narrow ? 8.0 : 16.0, vertical: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.slideshow_outlined, size: 15.0, color: fg),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'NFR DEMO  ', style: VT.body(context, size: 12.0, weight: FontWeight.w700, color: fg)),
                          TextSpan(
                            text: resetting
                                ? (narrow ? 'Resetting…' : 'Resetting the sample matters…')
                                : (narrow ? 'Sample data' : 'Fictional sample data · not for resale or client work'),
                            style: VT.body(context, size: 12.0, color: fg),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Checklist #8: time and log every demo.
                  if (!resetting) DemoRunTimer(fg: fg, narrow: narrow),
                  // Checklist #9: what happens to a firm's closed matter.
                  if (!resetting && !narrow)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: fg, padding: const EdgeInsets.symmetric(horizontal: 8.0), minimumSize: const Size(0, 28.0)),
                      onPressed: () => showDataHandling(context),
                      icon: const Icon(Icons.privacy_tip_outlined, size: 15.0),
                      label: Text('Data handling', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: fg)),
                    ),
                  if (!resetting)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: fg, padding: const EdgeInsets.symmetric(horizontal: 8.0), minimumSize: const Size(0, 28.0)),
                      onPressed: () {
                        // Every tip shows again, starting from the welcome slides.
                        TourProgress.reset();
                        context.goNamed('GettingStarted');
                      },
                      icon: const Icon(Icons.slideshow_outlined, size: 15.0),
                      label: Text(narrow ? 'Tips' : 'Replay tips', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: fg)),
                    ),
                  if (widget.user.isAdmin)
                    resetting
                        ? const SizedBox(width: 14.0, height: 14.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: fg))
                        : TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: fg, padding: const EdgeInsets.symmetric(horizontal: 8.0), minimumSize: const Size(0, 28.0)),
                            onPressed: () async {
                              setState(() => _busy = true);
                              await resetDemo(context);
                              if (mounted) setState(() => _busy = false);
                            },
                            icon: const Icon(Icons.restart_alt, size: 15.0),
                            label: Text(narrow ? 'Reset' : 'Reset demo', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: fg)),
                          ),
                ],
              ),
            ),
            ),
    );
  }
}

/// Admin → Settings: make an empty workspace a demo, or reset one.
class DemoWorkspaceCard extends StatefulWidget {
  const DemoWorkspaceCard({super.key, required this.firm});

  final FirmAccountRecord? firm;

  @override
  State<DemoWorkspaceCard> createState() => _DemoWorkspaceCardState();
}

class _DemoWorkspaceCardState extends State<DemoWorkspaceCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final demo = isDemoFirm(widget.firm);
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const VIconCircle(icon: Icons.slideshow_outlined),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(demo ? 'This is an NFR demo workspace' : 'NFR demo workspace', style: VT.body(context, weight: FontWeight.w600)),
                    Text(
                      demo
                          ? 'Seven fictional matters across all five practices, for showing Verin to firms. Reset any time to start a demo fresh.'
                          : 'For showing Verin to prospective clients. Use a separate account (e.g. demo@verinlegal.com) with no real matters.',
                      style: VT.muted(context, size: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          VButton(
            label: demo ? 'Reset sample data' : 'Make this a demo workspace',
            icon: Icons.restart_alt,
            kind: demo ? VButtonKind.secondary : VButtonKind.tonal,
            size: VButtonSize.sm,
            loading: _busy || demoResetting(widget.firm),
            loadingLabel: 'Preparing…',
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await resetDemo(context, first: !demo);
                    if (mounted) setState(() => _busy = false);
                  },
          ),
        ],
      ),
    );
  }
}
