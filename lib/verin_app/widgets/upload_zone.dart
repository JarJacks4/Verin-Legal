// Upload zone + staged-file previews (New matter drawer and Manual entry).

import 'package:flutter/material.dart';

import '../data/evidence_upload.dart';
import '../theme/tokens.dart';
import 'atoms.dart';

class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, required this.color, this.radius = VR.xl, this.strokeWidth = 2.0});

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, radius: radius, strokeWidth: strokeWidth),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.color, required this.radius, required this.strokeWidth});

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color || old.radius != radius;
}

/// Click-to-browse zone in the Make's dashed style.
class UploadZone extends StatelessWidget {
  const UploadZone({super.key, required this.title, required this.hint, required this.onTap, this.compact = false});

  final String title;
  final String hint;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return VHover(
      onTap: onTap,
      builder: (context, hovered) => DashedBorder(
        color: hovered ? c.teal : c.border,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: compact ? 24.0 : 28.0, horizontal: 16.0),
          decoration: BoxDecoration(color: hovered ? c.tealPale : c.secondary, borderRadius: BorderRadius.circular(VR.xl)),
          child: Column(
            children: [
              Container(
                width: compact ? 36.0 : 40.0,
                height: compact ? 36.0 : 40.0,
                decoration: BoxDecoration(color: hovered ? c.teal : c.card, shape: BoxShape.circle),
                child: Icon(Icons.file_upload_outlined, size: compact ? 16.0 : 18.0, color: hovered ? c.primaryFg : c.tealDeep),
              ),
              const SizedBox(height: 8.0),
              Text(title, textAlign: TextAlign.center, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
              const SizedBox(height: 2.0),
              Text.rich(
                TextSpan(
                  style: VT.muted(context, size: 12.0),
                  children: [
                    TextSpan(text: 'browse files', style: VT.body(context, size: 12.0, color: c.teal)),
                    TextSpan(text: ' · $hint'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData iconForKind(EvidenceKind k) => switch (k) {
      EvidenceKind.photo => Icons.image_outlined,
      EvidenceKind.video => Icons.movie_outlined,
      EvidenceKind.document => Icons.description_outlined,
      EvidenceKind.email => Icons.mail_outline,
      EvidenceKind.physical => Icons.inventory_2_outlined,
    };

/// 3-column thumbnail grid with an "Add more" tile (New matter drawer).
class StagedGrid extends StatelessWidget {
  const StagedGrid({super.key, required this.files, required this.onRemove, required this.onAddMore, this.progress});

  final List<StagedFile> files;
  final void Function(int index) onRemove;
  final VoidCallback onAddMore;
  final Map<int, double>? progress;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return LayoutBuilder(builder: (context, box) {
      const gap = 8.0;
      final w = (box.maxWidth - gap * 2) / 3;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < files.length; i++)
            SizedBox(
              width: w,
              height: w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VR.xl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: c.secondary),
                    if (files[i].isImage)
                      Image.memory(files[i].bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(iconForKind(files[i].kind), size: 22.0, color: c.tealDeep),
                          const SizedBox(height: 6.0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(files[i].name,
                                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: VT.muted(context, size: 10.0)),
                          ),
                        ],
                      ),
                    Positioned(
                      left: 6.0,
                      bottom: 6.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(color: const Color(0x99172024), borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconForKind(files[i].kind), size: 9.0, color: Colors.white),
                            const SizedBox(width: 3.0),
                            Text(files[i].kind.name, style: VT.body(context, size: 9.0, weight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    if (progress != null && progress![i] != null)
                      (progress![i]! >= 1.0
                          ? Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(color: c.verifiedBg.withValues(alpha: 0.72)),
                                  child: VUploadProgress(value: progress![i], compact: true),
                                ),
                              ),
                            )
                          : Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: VUploadProgress(value: progress![i], height: 4.0),
                            )),
                    Positioned(
                      top: 6.0,
                      right: 6.0,
                      child: VHover(
                        onTap: () => onRemove(i),
                        builder: (context, _) => Container(
                          width: 20.0,
                          height: 20.0,
                          decoration: const BoxDecoration(color: Color(0xB3172024), shape: BoxShape.circle),
                          child: const Icon(Icons.delete_outline, size: 11.0, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: w,
            height: w,
            child: VHover(
              onTap: onAddMore,
              builder: (context, hovered) => DashedBorder(
                color: c.border,
                child: Container(
                  decoration: BoxDecoration(color: hovered ? c.tealPale : c.secondary, borderRadius: BorderRadius.circular(VR.xl)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18.0, color: c.mutedFg),
                      const SizedBox(height: 4.0),
                      Text('Add more', style: VT.muted(context, size: 10.0)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// List rows with thumbnail, name, size and remove (Manual entry drawer).
class StagedList extends StatelessWidget {
  const StagedList({super.key, required this.files, required this.onRemove, this.progress, this.errors});

  final List<StagedFile> files;
  final void Function(int index) onRemove;
  final Map<int, double>? progress;
  final Map<int, String>? errors;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Column(
      children: [
        for (var i = 0; i < files.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.xl)),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          color: c.secondary,
                          child: files[i].isImage
                              ? Image.memory(files[i].bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                              : Icon(iconForKind(files[i].kind), size: 18.0, color: c.tealDeep),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(files[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                            Text(
                              errors?[i] ?? '${files[i].sizeLabel} · ${files[i].kind.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: VT.body(context, size: 11.0, color: errors?[i] != null ? c.broken : c.mutedFg),
                            ),
                          ],
                        ),
                      ),
                      VIconButton(icon: Icons.delete_outline, size: 14.0, tooltip: 'Remove', onPressed: () => onRemove(i)),
                    ],
                  ),
                  if (progress != null && progress![i] != null) ...[
                    const SizedBox(height: 8.0),
                    VUploadProgress(value: progress![i], height: 4.0),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
