// Verin Legal — shared UI building blocks for hand-written screens.
//
// These reproduce the look of the FlutterFlow components already in the app
// (Spectral headings, IBM Plex Sans body, Space Grotesk labels, the navy/teal
// palette from FlutterFlowTheme) but take real callbacks and never fall back to
// placeholder text, which matters for an evidence app: an empty value renders
// as an em dash, never as sample content.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Em dash shown wherever a value is missing.
const String kDash = '—';

String orDash(String? s) => (s == null || s.trim().isEmpty) ? kDash : s;

class VerinText {
  static TextStyle display(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.spectral(
      textStyle: t.displaySmall,
      color: t.primaryText,
      height: 1.2,
    );
  }

  static TextStyle heading(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.spectral(
      textStyle: t.headlineMedium,
      color: t.primaryText,
      height: 1.25,
    );
  }

  static TextStyle section(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.spectral(
      textStyle: t.titleLarge,
      color: t.primaryText,
      fontWeight: FontWeight.bold,
      height: 1.3,
    );
  }

  static TextStyle title(BuildContext context, {Color? color}) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.ibmPlexSans(
      textStyle: t.titleMedium,
      color: color ?? t.primaryText,
      fontWeight: FontWeight.bold,
      height: 1.4,
    );
  }

  static TextStyle titleSmall(BuildContext context, {Color? color}) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.ibmPlexSans(
      textStyle: t.titleSmall,
      color: color ?? t.primaryText,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.ibmPlexSans(
      textStyle: t.bodyMedium,
      color: color ?? t.primaryText,
      height: 1.5,
    );
  }

  static TextStyle bodyMuted(BuildContext context) =>
      body(context, color: FlutterFlowTheme.of(context).secondaryText);

  static TextStyle small(BuildContext context, {Color? color}) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.ibmPlexSans(
      textStyle: t.bodySmall,
      color: color ?? t.secondaryText,
      height: 1.5,
    );
  }

  static TextStyle label(BuildContext context, {Color? color, FontWeight? weight}) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.ibmPlexSans(
      textStyle: t.labelMedium,
      color: color ?? t.secondaryText,
      fontWeight: weight,
      height: 1.3,
    );
  }

  /// Space Grotesk, used for hashes, timestamps and tag text.
  static TextStyle mono(BuildContext context, {Color? color, FontWeight? weight}) {
    final t = FlutterFlowTheme.of(context);
    return GoogleFonts.spaceGrotesk(
      textStyle: t.labelSmall,
      color: color ?? t.secondaryText,
      fontWeight: weight,
      height: 1.2,
    );
  }
}

enum VerinButtonVariant { primary, secondary, outline, ghost, destructive }

enum VerinButtonSize { small, medium, large }

class VerinButton extends StatelessWidget {
  const VerinButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = VerinButtonVariant.outline,
    this.size = VerinButtonSize.medium,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final VerinButtonVariant variant;
  final VerinButtonSize size;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final disabled = onPressed == null || loading;

    Color bg;
    Color fg;
    Color border = Colors.transparent;
    switch (variant) {
      case VerinButtonVariant.primary:
        bg = t.primary;
        fg = t.onPrimary;
        break;
      case VerinButtonVariant.secondary:
        bg = t.secondary;
        fg = t.onSecondary;
        break;
      case VerinButtonVariant.destructive:
        bg = t.error;
        fg = t.onError;
        break;
      case VerinButtonVariant.outline:
        bg = Colors.transparent;
        fg = t.primaryText;
        border = t.alternate;
        break;
      case VerinButtonVariant.ghost:
        bg = Colors.transparent;
        fg = t.primaryText;
        break;
    }

    final double radius = size == VerinButtonSize.small
        ? 4.0
        : size == VerinButtonSize.large
            ? 8.0
            : 6.0;
    final EdgeInsets pad = size == VerinButtonSize.small
        ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0)
        : size == VerinButtonSize.large
            ? const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);
    final double fontSize = size == VerinButtonSize.small ? 13.0 : 14.0;

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 14.0,
            height: 14.0,
            child: CircularProgressIndicator(strokeWidth: 2.0, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 16.0, color: fg),
        if (loading || icon != null) const SizedBox(width: 8.0),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexSans(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: disabled && !loading ? 0.55 : 1.0,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          child: Padding(padding: pad, child: content),
        ),
      ),
    );
  }
}

/// Small rounded tag, e.g. channel / status / "Transcribed".
class VerinTag extends StatelessWidget {
  const VerinTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: foreground),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: VerinText.mono(context, color: foreground, weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Pill used in the matter header ("Chain verified", "In Clio").
class VerinPill extends StatelessWidget {
  const VerinPill({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.border,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999.0),
        border: Border.all(color: border ?? Colors.transparent, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: foreground),
          const SizedBox(width: 4.0),
          Text(label, style: VerinText.mono(context, color: foreground, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// White card with the app's standard hairline border.
class VerinCard extends StatelessWidget {
  const VerinCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.color,
    this.borderColor,
    this.radius = 8.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? t.secondaryBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? t.alternate, width: 1.0),
      ),
      child: child,
    );
  }
}

class VerinEmptyState extends StatelessWidget {
  const VerinEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32.0, color: t.secondaryText),
          const SizedBox(height: 12.0),
          Text(title, style: VerinText.titleSmall(context), textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4.0),
            Text(message!, style: VerinText.small(context), textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: 16.0),
            action!,
          ],
        ],
      ),
    );
  }
}

class VerinLoading extends StatelessWidget {
  const VerinLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: 28.0,
          height: 28.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: FlutterFlowTheme.of(context).secondary,
          ),
        ),
      ),
    );
  }
}

void showVerinSnack(BuildContext context, String message, {bool error = false}) {
  final t = FlutterFlowTheme.of(context);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: t.onPrimary)),
      backgroundColor: error ? t.error : t.secondary,
      duration: Duration(milliseconds: error ? 6000 : 3000),
    ),
  );
}

/// Right-side drawer used for detail sheets (receipt, verify tool, reports).
Future<T?> showVerinSheet<T>(BuildContext context, Widget child, {double maxWidth = 560.0}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: MediaQuery.viewInsetsOf(sheetContext),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// Standard sheet chrome: title row with a working close button.
class VerinSheetFrame extends StatelessWidget {
  const VerinSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Material(
      color: t.secondaryBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 12.0, 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: VerinText.section(context)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4.0),
                        Text(subtitle!, style: VerinText.small(context)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close_rounded, color: t.secondaryText),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Divider(height: 1.0, thickness: 1.0, color: t.alternate),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: child,
            ),
          ),
          if (footer != null) ...[
            Divider(height: 1.0, thickness: 1.0, color: t.alternate),
            Padding(padding: const EdgeInsets.all(16.0), child: footer!),
          ],
        ],
      ),
    );
  }
}

/// Monospace hash with a copy button.
class VerinHashLine extends StatelessWidget {
  const VerinHashLine({super.key, required this.label, required this.value, this.onCopied});

  final String label;
  final String value;
  final VoidCallback? onCopied;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VerinText.mono(context, color: t.accent3)),
        const SizedBox(height: 4.0),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                orDash(value),
                style: VerinText.mono(context, color: t.primaryText),
              ),
            ),
            if (value.isNotEmpty && onCopied != null)
              IconButton(
                tooltip: 'Copy',
                icon: Icon(Icons.content_copy_rounded, size: 16.0, color: t.primary),
                onPressed: onCopied,
              ),
          ],
        ),
      ],
    );
  }
}
