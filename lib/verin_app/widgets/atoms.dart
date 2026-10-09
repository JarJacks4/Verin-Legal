// Verin UI atoms — ports of the Figma Make building blocks: Wordmark, buttons,
// badges, cards, form fields, switch, stat tile, hash row, success state,
// theme toggle, toast.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/tokens.dart';
import 'celebrate.dart';

export 'celebrate.dart' show celebrate, VSuccessBurst, VUploadProgress;

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

/// Five-bar "cairn" mark: the top bar carries the teal accent. Geometry is
/// taken from the brand icon (550-unit square, bars 72 tall, 47 apart).
const kBrandHeroTag = 'verin-mark';
const kBrandNavy = Color(0xFF0B1622);
const kBrandTeal = Color(0xFF0E6E7D);
const kBrandPaper = Color(0xFFF6F3EE);

class VMark extends StatelessWidget {
  const VMark({
    super.key,
    this.size = 28.0,
    this.onDark = false,
    this.hero = false,
    this.anchor = false,
    this.baseColor,
    this.accentColor,
    this.reveal,
  });

  /// Width and height of the (square) mark.
  final double size;

  /// true on the dark brand panel (paper ribs), false on paper (ink ribs).
  final bool onDark;

  /// Fly between pages as a Hero (only one per page).
  final bool hero;

  /// Where the launch splash lands its logo.
  final bool anchor;

  final Color? baseColor, accentColor;

  /// 0→1 builds the mark bar by bar, bottom first.
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final base = baseColor ?? (onDark ? c.paper : c.ink);
    final accent = accentColor ?? c.teal;
    Widget mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: VMarkPainter(base: base, accent: accent, reveal: reveal)),
    );
    if (anchor) mark = BrandAnchor(base: base, accent: accent, child: mark);
    if (hero) {
      mark = Hero(
        tag: kBrandHeroTag,
        // The same mark on both pages; no need to rebuild anchors mid-flight.
        flightShuttleBuilder: (_, __, ___, ____, to) => SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: VMarkPainter(base: base, accent: accent)),
        ),
        child: mark,
      );
    }
    return mark;
  }
}

class VMarkPainter extends CustomPainter {
  VMarkPainter({required this.base, required this.accent, this.reveal}) : super(repaint: reveal);

  final Color base, accent;
  final Animation<double>? reveal;

  static const _widths = [203.0, 302.0, 396.0, 473.0, 550.0];

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 550.0;
    final t = reveal?.value ?? 1.0;
    for (var i = 0; i < 5; i++) {
      // Bottom bar first; each takes 45% of the run.
      final start = (4 - i) * 0.1375;
      final p = reveal == null ? 1.0 : Curves.easeOutCubic.transform(((t - start) / 0.45).clamp(0.0, 1.0));
      if (p <= 0.0) continue;
      final w = _widths[i] * u * (0.7 + 0.3 * p);
      final h = 72.0 * u;
      final y = i * 119.0 * u + (1.0 - p) * 40.0 * u;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH((size.width - w) / 2.0, y, w, h), Radius.circular(18.0 * u));
      final color = i == 0 ? accent : base;
      canvas.drawRRect(r, Paint()..color = color.withValues(alpha: color.a * p));
    }
  }

  @override
  bool shouldRepaint(VMarkPainter old) => old.base != base || old.accent != accent || old.reveal != reveal;
}

/// Registers a mark as a landing spot for the launch splash, and hides it
/// while the splash's copy is in flight.
class BrandAnchor extends StatefulWidget {
  const BrandAnchor({super.key, required this.base, required this.accent, required this.child});

  final Color base, accent;
  final Widget child;

  static final Set<_BrandAnchorState> _live = {};

  /// True while the splash flies its mark into place.
  static final ValueNotifier<bool> hidden = ValueNotifier<bool>(false);

  /// The visible anchor on the current page, as a global rect.
  static ({Rect rect, Color base, Color accent})? find(Size screen) {
    ({Rect rect, Color base, Color accent})? best;
    for (final a in _live) {
      final ctx = a._key.currentContext;
      if (ctx == null) continue;
      final route = a._route;
      if (route != null && !route.isCurrent) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.isEmpty || !(Offset.zero & screen).overlaps(rect)) continue;
      if (best == null || rect.width > best.rect.width) best = (rect: rect, base: a.widget.base, accent: a.widget.accent);
    }
    return best;
  }

  @override
  State<BrandAnchor> createState() => _BrandAnchorState();
}

class _BrandAnchorState extends State<BrandAnchor> {
  final _key = GlobalKey();
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    BrandAnchor._live.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    BrandAnchor._live.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: BrandAnchor.hidden,
        builder: (context, hide, child) => Opacity(opacity: hide ? 0.0 : 1.0, child: child),
        child: KeyedSubtree(key: _key, child: widget.child),
      );
}

class VWordmark extends StatelessWidget {
  const VWordmark({super.key, this.size = 28.0, this.onDark = false, this.brand = false, this.anchor = false});

  final double size;
  final bool onDark;

  /// Hero between pages and landing spot for the launch splash.
  final bool brand;

  /// Landing spot only (for logos that may appear twice on one page).
  final bool anchor;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VMark(size: size, onDark: onDark, hero: brand, anchor: brand || anchor),
        const SizedBox(width: 10.0),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verin',
              style: GoogleFonts.spectral(
                fontWeight: FontWeight.w700,
                fontSize: size * 0.78,
                letterSpacing: size * 0.78 * 0.01,
                height: 1.0,
                color: onDark ? c.paper : c.ink,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'EVIDENCE RECORD',
              style: GoogleFonts.ibmPlexSans(
                fontWeight: FontWeight.w500,
                fontSize: size * 0.26,
                letterSpacing: size * 0.26 * 0.26,
                height: 1.0,
                color: c.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hover helper
// ---------------------------------------------------------------------------

/// Gives a child hover state (web/desktop) and a click cursor.
class VHover extends StatefulWidget {
  const VHover({super.key, required this.builder, this.onTap, this.enabled = true});

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<VHover> createState() => _VHoverState();
}

class _VHoverState extends State<VHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onTap != null;
    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? widget.onTap : null,
        child: widget.builder(context, _hover && active),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum VButtonKind {
  /// Teal fill (var(--primary)).
  primary,

  /// Pale fill with foreground text ("Close", "Standalone verify tool").
  secondary,

  /// Pale fill with deep-teal text ("Add manual entry", "Connect …").
  tonal,

  /// Soft red fill ("Sign out").
  danger,

  /// Red outline ("Rotate").
  dangerOutline,

  /// Text only, teal ("Update", "Export").
  link,

  /// Brand panel fill ("Admin console").
  panel,
}

enum VButtonSize { sm, md, lg }

class VButton extends StatelessWidget {
  const VButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = VButtonKind.primary,
    this.size = VButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.fullWidth = false,
    this.loading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final VButtonKind kind;
  final VButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool loading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final disabled = onPressed == null || loading;

    Color bg;
    Color fg;
    Border? border;
    switch (kind) {
      case VButtonKind.primary:
        bg = c.primary;
        fg = c.primaryFg;
      case VButtonKind.secondary:
        bg = c.secondary;
        fg = c.foreground;
      case VButtonKind.tonal:
        bg = c.secondary;
        fg = c.tealDeep;
      case VButtonKind.danger:
        bg = c.broken.withValues(alpha: 0.08);
        fg = c.broken;
      case VButtonKind.dangerOutline:
        bg = Colors.transparent;
        fg = c.broken;
        border = Border.all(color: c.broken);
      case VButtonKind.link:
        bg = Colors.transparent;
        fg = c.teal;
      case VButtonKind.panel:
        bg = c.panel;
        fg = c.paper;
    }

    final (double padX, double padY, double font, FontWeight weight, double iconSize) = switch (size) {
      VButtonSize.sm => (12.0, 8.0, 13.0, FontWeight.w500, 14.0),
      VButtonSize.md => (16.0, 10.0, 14.0, FontWeight.w600, 16.0),
      VButtonSize.lg => (20.0, 12.0, 15.0, FontWeight.w600, 17.0),
    };
    final isLink = kind == VButtonKind.link;

    final text = loading ? (loadingLabel ?? label) : label;
    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: iconSize - 2,
            height: iconSize - 2,
            child: CircularProgressIndicator(strokeWidth: 2.0, color: fg),
          ),
          const SizedBox(width: 8.0),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 8.0),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexSans(fontSize: font, fontWeight: weight, color: fg, height: 1.4),
          ),
        ),
        if (trailingIcon != null && !loading) ...[
          const SizedBox(width: 8.0),
          Icon(trailingIcon, size: iconSize, color: fg),
        ],
      ],
    );

    return VHover(
      onTap: disabled ? null : onPressed,
      builder: (context, hovered) => Opacity(
        opacity: disabled ? 0.5 : (hovered ? 0.9 : 1.0),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: isLink ? const EdgeInsets.symmetric(vertical: 4.0) : EdgeInsets.symmetric(horizontal: padX, vertical: padY),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(kind == VButtonKind.dangerOutline ? 12.0 : VR.xl),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Square-ish icon button (close, copy, delete).
class VIconButton extends StatelessWidget {
  const VIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 18.0, this.color, this.filled = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  /// Pale background even when not hovered (sheet close buttons).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final btn = VHover(
      onTap: onPressed,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: (hovered || filled) ? c.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(VR.lg),
        ),
        child: Icon(icon, size: size, color: color ?? c.mutedFg),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class VBadge extends StatelessWidget {
  const VBadge({super.key, required this.label, required this.bg, required this.fg, this.icon, this.size = 11.0, this.bold = false});

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final double size;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size <= 10 ? 7.0 : 8.0, vertical: 2.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 1, color: fg),
            const SizedBox(width: 5.0),
          ],
          Text(
            label,
            style: GoogleFonts.ibmPlexSans(fontSize: size, fontWeight: bold ? FontWeight.w600 : FontWeight.w500, color: fg, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Inline status line: icon + label in a status colour, no fill
/// ("Verified", "Chain verified").
class VStatusInline extends StatelessWidget {
  const VStatusInline({super.key, required this.label, required this.icon, required this.color, this.size = 12.0});

  final String label;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size + 2, color: color),
        const SizedBox(width: 6.0),
        Text(label, style: GoogleFonts.ibmPlexSans(fontSize: size, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

/// White card with a hairline border (rounded-2xl).
class VCard extends StatelessWidget {
  const VCard({super.key, required this.child, this.padding = const EdgeInsets.all(20.0), this.radius = VR.card, this.color, this.borderColor, this.borderWidth = 1.0, this.clip = false});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border, width: borderWidth),
      ),
      child: child,
    );
  }
}

/// Pale-teal information panel (rounded-xl / rounded-2xl, no border).
class VPanel extends StatelessWidget {
  const VPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16.0), this.radius = VR.xl, this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color ?? VC.of(context).secondary, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

/// "HOW RECEIVING WORKS" panel: eyebrow + body.
class VInfoPanel extends StatelessWidget {
  const VInfoPanel({super.key, required this.title, required this.body, this.radius = VR.xl, this.padding = const EdgeInsets.all(16.0)});

  final String title;
  final String body;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return VPanel(
      radius: radius,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: VT.eyebrow(context)),
          const SizedBox(height: 6.0),
          Text(body, style: VT.body(context, size: 13.0, height: 1.6)),
        ],
      ),
    );
  }
}

/// Amber notice ("Manual entries are stamped with current server time…").
class VNotice extends StatelessWidget {
  const VNotice({super.key, required this.text, this.tone = VNoticeTone.pending, this.icon});

  final String text;
  final VNoticeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final (Color fg, Color bg, Color? border) = switch (tone) {
      VNoticeTone.pending => (c.pending, c.pending.withValues(alpha: 0.08), null),
      VNoticeTone.broken => (c.broken, c.broken.withValues(alpha: 0.10), null),
      VNoticeTone.verified => (c.verified, c.verified.withValues(alpha: 0.08), c.verified.withValues(alpha: 0.2)),
      VNoticeTone.teal => (c.tealDeep, c.tealPale, null),
    };
    final ic = icon ??
        switch (tone) {
          VNoticeTone.verified => Icons.check_circle_outline,
          VNoticeTone.teal => Icons.lock_outline,
          _ => Icons.warning_amber_rounded,
        };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VR.xl),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2.0), child: Icon(ic, size: 14.0, color: fg)),
          const SizedBox(width: 8.0),
          Expanded(child: Text(text, style: VT.body(context, size: 12.0, color: fg))),
        ],
      ),
    );
  }
}

enum VNoticeTone { pending, broken, verified, teal }

class VHairline extends StatelessWidget {
  const VHairline({super.key, this.vertical = false});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return vertical ? Container(width: 1.0, color: c.border) : Container(height: 1.0, color: c.border);
  }
}

/// "—— or ——"
class VOrDivider extends StatelessWidget {
  const VOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: VHairline()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text('or', style: VT.muted(context, size: 12.0)),
        ),
        const Expanded(child: VHairline()),
      ],
    );
  }
}

/// Round icon chip (w-9 h-9 rounded-full, pale fill).
class VIconCircle extends StatelessWidget {
  const VIconCircle({super.key, required this.icon, this.size = 36.0, this.iconSize = 17.0, this.bg, this.fg, this.square = false});

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? bg;
  final Color? fg;

  /// rounded-lg square instead of a circle (integration cards).
  final bool square;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? c.secondary,
        borderRadius: BorderRadius.circular(square ? 12.0 : size),
      ),
      child: Icon(icon, size: iconSize, color: fg ?? c.tealDeep),
    );
  }
}

/// Initials avatar.
class VAvatar extends StatelessWidget {
  const VAvatar({super.key, required this.initials, this.size = 32.0, this.muted = false});

  final String initials;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: muted ? c.secondary : c.teal, shape: BoxShape.circle),
      child: Text(
        initials,
        style: GoogleFonts.ibmPlexSans(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: muted ? c.mutedFg : c.primaryFg,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form controls
// ---------------------------------------------------------------------------

class VFieldLabel extends StatelessWidget {
  const VFieldLabel(this.text, {super.key, this.optional});

  final String text;
  final String? optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text.rich(
        TextSpan(
          text: text,
          style: VT.body(context, size: 13.0, weight: FontWeight.w500),
          children: [
            if (optional != null)
              TextSpan(text: ' — $optional', style: VT.muted(context, size: 13.0)),
          ],
        ),
      ),
    );
  }
}

InputDecoration vInputDecoration(BuildContext context, {String? hint, Widget? prefix, Widget? suffix, double radius = VR.xl}) {
  final c = VC.of(context);
  OutlineInputBorder b(Color color, [double w = 1.0]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: color, width: w));
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: VT.body(context, color: c.mutedFg.withValues(alpha: 0.75)),
    filled: true,
    fillColor: c.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
    prefixIcon: prefix,
    suffixIcon: suffix,
    border: b(c.border),
    enabledBorder: b(c.border),
    focusedBorder: b(c.teal.withValues(alpha: 0.6), 1.5),
    errorBorder: b(c.broken),
    focusedErrorBorder: b(c.broken, 1.5),
    disabledBorder: b(c.border),
  );
}

class VTextField extends StatelessWidget {
  const VTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.optional,
    this.enabled = true,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final String? optional;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      minLines: maxLines > 1 ? maxLines : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      enabled: enabled,
      textInputAction: textInputAction,
      style: VT.body(context),
      cursorColor: VC.of(context).teal,
      decoration: vInputDecoration(context, hint: hint, radius: maxLines > 1 ? 16.0 : VR.xl),
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [VFieldLabel(label!, optional: optional), field],
    );
  }
}

class VSelect<T> extends StatelessWidget {
  const VSelect({super.key, required this.value, required this.items, required this.onChanged, this.label, required this.labelFor});

  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String? label;
  final String Function(T) labelFor;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final field = DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: c.card,
      borderRadius: BorderRadius.circular(16.0),
      icon: Icon(Icons.expand_more, color: c.mutedFg, size: 18.0),
      style: VT.body(context),
      decoration: vInputDecoration(context),
      items: [
        for (final i in items) DropdownMenuItem<T>(value: i, child: Text(labelFor(i), style: VT.body(context))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [VFieldLabel(label!), field],
    );
  }
}

/// Read-only field ("Family law", "Indiana · IN Bar").
class VStaticField extends StatelessWidget {
  const VStaticField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VFieldLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
          decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.xl)),
          child: Text(value, style: VT.body(context, color: c.mutedFg)),
        ),
      ],
    );
  }
}

/// Two-to-four equal choice buttons ("Open / Closed", role pickers).
class VSegmented<T> extends StatelessWidget {
  const VSegmented({super.key, required this.value, required this.options, required this.onChanged, required this.labelFor, this.label, this.fontSize = 13.0});

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T) labelFor;
  final String? label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final row = Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8.0),
          Expanded(
            child: VHover(
              onTap: () => onChanged(options[i]),
              builder: (context, hovered) {
                final on = options[i] == value;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? c.primary : c.secondary,
                    borderRadius: BorderRadius.circular(VR.xl),
                  ),
                  child: Text(
                    labelFor(options[i]),
                    style: VT.body(context, size: fontSize, weight: FontWeight.w500, color: on ? c.primaryFg : c.foreground),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
    if (label == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(label!, style: VT.body(context, size: 13.0, weight: FontWeight.w500))),
        row,
      ],
    );
  }
}

/// Pill switch (w-11 h-6).
class VSwitch extends StatelessWidget {
  const VSwitch({super.key, required this.value, required this.onChanged, this.width = 44.0});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    const h = 24.0;
    const knob = 20.0;
    return VHover(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      builder: (context, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        height: h,
        decoration: BoxDecoration(color: value ? c.primary : c.switchBg, borderRadius: BorderRadius.circular(h)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2.0),
            width: knob,
            height: knob,
            decoration: BoxDecoration(
              color: c.paper,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3.0, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data display
// ---------------------------------------------------------------------------

enum VTone { verified, muted, pending, broken }

class VStat extends StatelessWidget {
  const VStat({super.key, required this.icon, required this.label, required this.value, this.tone = VTone.muted});

  final IconData icon;
  final String label;
  final String value;
  final VTone tone;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final color = switch (tone) {
      VTone.verified => c.verified,
      VTone.pending => c.pending,
      VTone.broken => c.broken,
      VTone.muted => c.tealDeep,
    };
    return VCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          VIconCircle(icon: icon, size: 40.0, iconSize: 18.0, fg: color),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: VT.muted(context, size: 11.0)),
                Text(value, style: VT.body(context, size: 15.0, weight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "SHA-256  3f9a…" — label and a mono hash on one line.
class VHashRow extends StatelessWidget {
  const VHashRow({super.key, required this.label, required this.value, this.short = false, this.size = 11.0});

  final String label;
  final String value;
  final bool short;
  final double size;

  @override
  Widget build(BuildContext context) {
    final display = short && value.length > 24 ? '${value.substring(0, 24)}…' : value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label, style: VT.muted(context, size: size)),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(display, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.mono(context, size: size)),
        ),
      ],
    );
  }
}

/// Full hash that wraps, with a copy button.
class VHashBlock extends StatelessWidget {
  const VHashBlock({super.key, required this.value, this.size = 10.0});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SelectableText(value.isEmpty ? '—' : value, style: VT.mono(context, size: size).copyWith(height: 1.6));
  }
}

class VSuccessState extends StatelessWidget {
  const VSuccessState({super.key, required this.title, required this.desc});

  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Column(
        children: [
          const VSuccessBurst(size: 64.0),
          const SizedBox(height: 16.0),
          Text(title, textAlign: TextAlign.center, style: VT.h3(context, size: 20.0)),
          const SizedBox(height: 16.0),
          Text(desc, textAlign: TextAlign.center, style: VT.muted(context)),
        ],
      ),
    );
  }
}

class VLoading extends StatelessWidget {
  const VLoading({super.key, this.padding = 32.0});

  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: SizedBox(
          width: 22.0,
          height: 22.0,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: VC.of(context).teal),
        ),
      ),
    );
  }
}

/// Error line in a soft red box (sign-in errors, failed loads).
class VErrorBox extends StatelessWidget {
  const VErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(color: c.broken.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(VR.xl)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2.0), child: Icon(Icons.warning_amber_rounded, size: 14.0, color: c.broken)),
          const SizedBox(width: 8.0),
          Expanded(child: Text(message, style: VT.body(context, size: 13.0, color: c.broken))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme toggle
// ---------------------------------------------------------------------------

enum VThemeToggleStyle { round, onPanel, row }

class VThemeToggle extends StatelessWidget {
  const VThemeToggle({super.key, this.style = VThemeToggleStyle.round});

  final VThemeToggleStyle style;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final dark = c.dark;
    final icon = dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    final label = 'Switch to ${dark ? 'light' : 'dark'} mode';
    switch (style) {
      case VThemeToggleStyle.row:
        return VHover(
          onTap: () => VThemeMode.toggle(context),
          builder: (context, hovered) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: hovered ? c.secondary.withValues(alpha: 0.6) : Colors.transparent,
              borderRadius: BorderRadius.circular(VR.xl),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16.0, color: c.mutedFg),
                const SizedBox(width: 12.0),
                Expanded(child: Text(dark ? 'Light mode' : 'Dark mode', style: VT.muted(context))),
              ],
            ),
          ),
        );
      case VThemeToggleStyle.onPanel:
      case VThemeToggleStyle.round:
        final onPanel = style == VThemeToggleStyle.onPanel;
        return Tooltip(
          message: label,
          child: VHover(
            onTap: () => VThemeMode.toggle(context),
            builder: (context, hovered) => Container(
              width: 36.0,
              height: 36.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onPanel ? (hovered ? Colors.white.withValues(alpha: 0.10) : Colors.transparent) : c.card,
                border: onPanel ? null : Border.all(color: c.border),
              ),
              child: Icon(icon, size: 16.0, color: onPanel ? c.onPanelA(0.8) : c.foreground),
            ),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Toast
// ---------------------------------------------------------------------------

void showVToast(BuildContext context, String message, {bool error = false, String? description, Duration? duration}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final c = VC.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 420.0,
      elevation: 6.0,
      backgroundColor: c.card,
      duration: duration ?? Duration(seconds: error ? 7 : 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: c.border)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error) Icon(Icons.error_outline, size: 16.0, color: c.broken) else const VSuccessBurst(size: 18.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                if (description != null) Text(description, style: VT.muted(context, size: 12.0)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> copyToClipboard(BuildContext context, String text, {String what = 'Copied'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showVToast(context, '$what to clipboard');
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

/// Dashed card with an icon, a title, a line of help and an optional action —
/// shown wherever a list has nothing in it yet.
class VEmptyState extends StatelessWidget {
  const VEmptyState({super.key, required this.icon, required this.title, required this.message, this.action, this.compact = false});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: compact ? 24.0 : 40.0),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(VR.card),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 40.0 : 52.0,
            height: compact ? 40.0 : 52.0,
            decoration: BoxDecoration(color: c.tealPale, shape: BoxShape.circle),
            child: Icon(icon, size: compact ? 18.0 : 22.0, color: c.tealDeep),
          ),
          const SizedBox(height: 14.0),
          Text(title, textAlign: TextAlign.center, style: VT.body(context, size: 15.0, weight: FontWeight.w600)),
          const SizedBox(height: 6.0),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420.0),
            child: Text(message, textAlign: TextAlign.center, style: VT.muted(context, size: 13.0, height: 1.55)),
          ),
          if (action != null) ...[const SizedBox(height: 18.0), action!],
        ],
      ),
    );
  }
}
