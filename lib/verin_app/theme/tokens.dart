// Verin design tokens — a direct port of the Figma Make theme
// (src/styles/theme.css). Light and dark sets; never pure white or black.
//
// Use `VC.of(context)` for colours and `VT` for text styles.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/main.dart';

class VColors {
  const VColors({
    required this.dark,
    required this.ink,
    required this.paper,
    required this.teal,
    required this.tealDeep,
    required this.tealPale,
    required this.panel,
    required this.oxblood,
    required this.verified,
    required this.pending,
    required this.broken,
    required this.background,
    required this.foreground,
    required this.card,
    required this.primary,
    required this.primaryFg,
    required this.secondary,
    required this.secondaryFg,
    required this.muted,
    required this.mutedFg,
    required this.destructive,
    required this.border,
    required this.inputBg,
    required this.switchBg,
  });

  final bool dark;
  final Color ink;
  final Color paper;
  final Color teal;
  final Color tealDeep;
  final Color tealPale;
  final Color panel;
  final Color oxblood;
  final Color verified;
  final Color pending;
  final Color broken;
  final Color background;
  final Color foreground;
  final Color card;
  final Color primary;
  final Color primaryFg;
  final Color secondary;
  final Color secondaryFg;
  final Color muted;
  final Color mutedFg;
  final Color destructive;
  final Color border;
  final Color inputBg;
  final Color switchBg;

  // Status tints used behind badges (same in both modes in the Make).
  Color get verifiedBg => const Color(0x1F2F7D5B); // rgba(47,125,91,0.12)
  Color get pendingBg => const Color(0x24B0791C); // rgba(176,121,28,0.14)
  Color get brokenBg => const Color(0x1F8C3A3F); // rgba(140,58,63,0.12)
  Color get scrim => const Color(0x38172024); // rgba(23,32,36,0.22)

  // Light text on the always-dark brand panel.
  Color get onPanel => const Color(0xFFE4EEEF);
  Color onPanelA(double a) => const Color(0xFFE4EEEF).withValues(alpha: a);

  static const light = VColors(
    dark: false,
    ink: Color(0xFF172024),
    paper: Color(0xFFFBFAF8),
    teal: Color(0xFF0E6E7D),
    tealDeep: Color(0xFF093F49),
    tealPale: Color(0xFFE4EEEF),
    panel: Color(0xFF093F49),
    oxblood: Color(0xFF8C3A3F),
    verified: Color(0xFF2F7D5B),
    pending: Color(0xFFB0791C),
    broken: Color(0xFF8C3A3F),
    background: Color(0xFFFBFAF8),
    foreground: Color(0xFF172024),
    card: Color(0xFFFDFCFA),
    primary: Color(0xFF0E6E7D),
    primaryFg: Color(0xFFFBFAF8),
    secondary: Color(0xFFE4EEEF),
    secondaryFg: Color(0xFF093F49),
    muted: Color(0xFFEFEBE3),
    mutedFg: Color(0xFF5C6A6E),
    destructive: Color(0xFF8C3A3F),
    border: Color(0x1F172024), // rgba(23,32,36,0.12)
    inputBg: Color(0xFFF1EDE5),
    switchBg: Color(0xFFCBD5D4),
  );

  static const darkSet = VColors(
    dark: true,
    ink: Color(0xFFE8EEEE),
    paper: Color(0xFFFBFAF8),
    teal: Color(0xFF4FB8C8),
    tealDeep: Color(0xFF8FD3DD),
    tealPale: Color(0xFF1A363D),
    panel: Color(0xFF0B2E35),
    oxblood: Color(0xFFE27B80),
    verified: Color(0xFF5FC08F),
    pending: Color(0xFFE0A54A),
    broken: Color(0xFFE88A8F),
    background: Color(0xFF0F1618),
    foreground: Color(0xFFE8EEEE),
    card: Color(0xFF162023),
    primary: Color(0xFF4FB8C8),
    primaryFg: Color(0xFF08181B),
    secondary: Color(0xFF1D3036),
    secondaryFg: Color(0xFFA9DCE4),
    muted: Color(0xFF1C2528),
    mutedFg: Color(0xFF96A7AB),
    destructive: Color(0xFFC25056),
    border: Color(0x1FE8EEEE), // rgba(232,238,238,0.12)
    inputBg: Color(0xFF1B272B),
    switchBg: Color(0xFF3A4C51),
  );
}

class VC {
  static VColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? VColors.darkSet : VColors.light;
}

/// Radii from the Make (Tailwind v4 with --radius: 1.25rem).
class VR {
  static const double xl = 24.0; // rounded-xl: buttons, inputs, small panels
  static const double lg = 20.0; // rounded-lg: icon buttons
  static const double card = 16.0; // rounded-2xl: cards and lists
  static const double pill = 999.0;
}

/// Text styles. Headings use Spectral (the Evidence Record voice), body uses
/// IBM Plex Sans, hashes use IBM Plex Mono.
class VT {
  static TextStyle h1(BuildContext c, {double size = 30.0, Color? color}) => GoogleFonts.spectral(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: color ?? VC.of(c).foreground,
      );

  static TextStyle h2(BuildContext c, {double size = 20.0, Color? color}) => GoogleFonts.spectral(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: color ?? VC.of(c).foreground,
      );

  /// Spectral at body weight, e.g. matter names in lists.
  static TextStyle serif(BuildContext c, {double size = 15.0, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.spectral(fontSize: size, fontWeight: weight, height: 1.3, color: color ?? VC.of(c).foreground);

  static TextStyle h3(BuildContext c, {double size = 18.0, Color? color}) => GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color ?? VC.of(c).foreground,
      );

  static TextStyle body(BuildContext c,
          {double size = 14.0, FontWeight weight = FontWeight.w400, Color? color, double height = 1.5}) =>
      GoogleFonts.ibmPlexSans(fontSize: size, fontWeight: weight, height: height, color: color ?? VC.of(c).foreground);

  static TextStyle muted(BuildContext c, {double size = 14.0, FontWeight weight = FontWeight.w400, double height = 1.5}) =>
      GoogleFonts.ibmPlexSans(fontSize: size, fontWeight: weight, height: height, color: VC.of(c).mutedFg);

  /// Small uppercase section label ("HOW RECEIVING WORKS").
  static TextStyle eyebrow(BuildContext c, {double size = 12.0, Color? color, double spacing = 0.06}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: size * spacing,
        height: 1.4,
        color: color ?? VC.of(c).tealDeep,
      );

  static TextStyle mono(BuildContext c, {double size = 11.0, Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, height: 1.5, color: color ?? VC.of(c).foreground);
}

/// Light / dark switching, persisted. Defaults to light until the user picks.
class VThemeMode {
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static void toggle(BuildContext context) {
    final next = isDark(context) ? ThemeMode.light : ThemeMode.dark;
    MyApp.of(context).setThemeMode(next);
  }

  /// Kept for callers that want the stored preference.
  static ThemeMode get stored => FlutterFlowTheme.themeMode;
}
