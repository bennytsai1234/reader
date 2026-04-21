import 'package:flutter/material.dart';

class ReaderMenuPalette {
  ReaderMenuPalette._();

  static const Color background = Color(0xF2111827);
  static const Color backgroundElevated = Color(0xF21F2937);
  static const Color foreground = Color(0xFFF8FAFC);
  static const Color mutedForeground = Color(0xFFCBD5E1);
  static const Color outline = Color(0x33FFFFFF);
  static const Color accent = Color(0xFF60A5FA);
  static const Color accentMuted = Color(0x3360A5FA);
  static const Color scrim = Color(0x33000000);
}

class ReaderMenuStyle {
  final Color background;
  final Color backgroundElevated;
  final Color foreground;
  final Color mutedForeground;
  final Color outline;
  final Color accent;
  final Color accentMuted;
  final Color scrim;

  const ReaderMenuStyle({
    required this.background,
    required this.backgroundElevated,
    required this.foreground,
    required this.mutedForeground,
    required this.outline,
    required this.accent,
    required this.accentMuted,
    required this.scrim,
  });

  factory ReaderMenuStyle.resolve({
    required BuildContext context,
    required bool followPageStyle,
    required Color pageBackgroundColor,
    required Color pageTextColor,
  }) {
    if (!followPageStyle) {
      return const ReaderMenuStyle(
        background: ReaderMenuPalette.background,
        backgroundElevated: ReaderMenuPalette.backgroundElevated,
        foreground: ReaderMenuPalette.foreground,
        mutedForeground: ReaderMenuPalette.mutedForeground,
        outline: ReaderMenuPalette.outline,
        accent: ReaderMenuPalette.accent,
        accentMuted: ReaderMenuPalette.accentMuted,
        scrim: ReaderMenuPalette.scrim,
      );
    }

    final accent = Theme.of(context).colorScheme.primary;
    final background = pageBackgroundColor.withValues(alpha: 0.96);
    return ReaderMenuStyle(
      background: background,
      backgroundElevated: Color.alphaBlend(
        pageTextColor.withValues(alpha: 0.06),
        background,
      ),
      foreground: pageTextColor,
      mutedForeground: pageTextColor.withValues(alpha: 0.68),
      outline: pageTextColor.withValues(alpha: 0.12),
      accent: accent,
      accentMuted: accent.withValues(alpha: 0.18),
      scrim: pageTextColor.withValues(alpha: 0.08),
    );
  }
}
