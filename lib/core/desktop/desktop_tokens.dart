import 'package:flutter/material.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';

/// Shared desktop layout values.
///
/// New Windows screens should use these values so spacing, radii and motion
/// stay consistent across every page.
class DesktopTokens {
  DesktopTokens._();

  // Base dimensions.
  static const double sidebarWidth = 276;
  static const double sidebarCollapsedWidth = 84;
  static const double topBarHeight = 68;
  static const double contentMaxWidth = 1600;
  static const double pagePadding = 28;
  static const double pageHeaderHeight = 76;

  // 8px rhythm (with a 6px micro-step for dense controls).
  static const double gapXs = 6;
  static const double gapSm = 10;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double gapXl = 32;

  // Radii.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // Motion.
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 240);
}

/// Desktop-facing colour palette derived from [SaytarlyThemeTokens] and the
/// user-selected accent. Widgets in the desktop kit keep using this class, so
/// the whole Windows surface follows one source of truth.
class DesktopPalette {
  const DesktopPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.profit,
    required this.shadow,
    required this.sidebarBg,
    required this.sidebarBgDeep,
    required this.sidebarFg,
    required this.sidebarMuted,
    required this.sidebarHover,
    required this.sidebarActiveBg,
    required this.sidebarBorder,
  });

  final bool isDark;

  /// Page background.
  final Color background;

  /// Card surface.
  final Color surface;

  /// Soft inner surface (table rows, nested fields).
  final Color surfaceSoft;

  /// Recessed surface.
  final Color surfaceSunken;

  /// Default hairline border.
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Accent from the app theme (Control Blue by default).
  final Color accent;
  final Color accentText;
  final Color accentSoft;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color profit;

  final Color shadow;

  // Sidebar — always deep navy in both modes.
  final Color sidebarBg;
  final Color sidebarBgDeep;
  final Color sidebarFg;
  final Color sidebarMuted;
  final Color sidebarHover;
  final Color sidebarActiveBg;
  final Color sidebarBorder;

  /// A translucent version of any colour, for chips and badges.
  Color soft(Color color) => color.withValues(alpha: isDark ? 0.18 : 0.10);

  /// Readable text colour on a tinted chip.
  Color onSoft(Color color) =>
      isDark
          ? Color.lerp(color, Colors.white, 0.18)!
          : Color.lerp(color, Colors.black, 0.22)!;

  /// The palette for the current theme.
  static DesktopPalette of(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.saytarly;
    final primary = theme.colorScheme.primary;
    final base = _fromTokens(tokens, primary);

    final accentText =
        tokens.isDark
            ? Color.lerp(primary, Colors.white, 0.32)!
            : Color.lerp(primary, Colors.black, 0.24)!;

    return base.copyWith(
      accent: primary,
      accentText: accentText,
      accentSoft: primary.withValues(alpha: tokens.isDark ? 0.20 : 0.11),
    );
  }

  static DesktopPalette _fromTokens(SaytarlyThemeTokens t, Color accent) {
    return DesktopPalette(
      isDark: t.isDark,
      background: t.canvas,
      surface: t.surface,
      surfaceSoft: t.surfaceSoft,
      surfaceSunken: t.surfaceSunken,
      border: t.border,
      borderStrong: t.borderStrong,
      textPrimary: t.textPrimary,
      textSecondary: t.textSecondary,
      textMuted: t.textMuted,
      accent: accent,
      accentText: accent,
      accentSoft: t.softBlue,
      success: t.success,
      warning: t.warning,
      danger: t.danger,
      info: t.info,
      profit: t.profit,
      shadow: t.shadow,
      sidebarBg: t.sidebar,
      sidebarBgDeep: t.sidebarDeep,
      sidebarFg: t.sidebarText,
      sidebarMuted: t.sidebarMuted,
      sidebarHover: Colors.white.withValues(alpha: 0.06),
      sidebarActiveBg: t.sidebarActive,
      sidebarBorder: t.sidebarBorder,
    );
  }

  static DesktopPalette get light =>
      _fromTokens(SaytarlyThemeTokens.light, SaytarlyColors.controlBlue);

  static DesktopPalette get dark =>
      _fromTokens(SaytarlyThemeTokens.dark, SaytarlyColors.darkAccent);

  DesktopPalette copyWith({
    bool? isDark,
    Color? background,
    Color? surface,
    Color? surfaceSoft,
    Color? surfaceSunken,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentText,
    Color? accentSoft,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? profit,
    Color? shadow,
    Color? sidebarBg,
    Color? sidebarBgDeep,
    Color? sidebarFg,
    Color? sidebarMuted,
    Color? sidebarHover,
    Color? sidebarActiveBg,
    Color? sidebarBorder,
  }) {
    return DesktopPalette(
      isDark: isDark ?? this.isDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      profit: profit ?? this.profit,
      shadow: shadow ?? this.shadow,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      sidebarBgDeep: sidebarBgDeep ?? this.sidebarBgDeep,
      sidebarFg: sidebarFg ?? this.sidebarFg,
      sidebarMuted: sidebarMuted ?? this.sidebarMuted,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarActiveBg: sidebarActiveBg ?? this.sidebarActiveBg,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
    );
  }
}
