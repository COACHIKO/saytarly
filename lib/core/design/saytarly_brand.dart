import 'package:flutter/material.dart';

/// The SAYTARLY brand palette.
///
/// Navy and electric blue are the permanent product identity. Everything else
/// is a working-interface neutral or a semantic colour that only appears when
/// it carries meaning (paid, low stock, danger, growth...).
abstract final class SaytarlyColors {
  SaytarlyColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color deepNavy = Color(0xFF0B1F3A);
  static const Color navy800 = Color(0xFF102B4E);
  static const Color navy700 = Color(0xFF183A63);
  static const Color controlBlue = Color(0xFF1677FF);
  static const Color controlBlueHover = Color(0xFF0F65D8);
  static const Color controlBluePressed = Color(0xFF0C56BD);
  static const Color softBlue = Color(0xFFEAF3FF);

  // ── Working neutrals ─────────────────────────────────────────────────────
  static const Color appCanvas = Color(0xFFF5F7FB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFC);
  static const Color surfaceSunken = Color(0xFFEEF2F7);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color textPrimary = Color(0xFF172B4D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Semantics ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color information = Color(0xFF0284C7);
  static const Color profit = Color(0xFF0F9F83);

  // ── Dark workspace ───────────────────────────────────────────────────────
  static const Color darkCanvas = Color(0xFF07111F);
  static const Color darkSurface = Color(0xFF0D1B2E);
  static const Color darkSurfaceSoft = Color(0xFF12233A);
  static const Color darkSurfaceSunken = Color(0xFF0A1626);
  static const Color darkBorder = Color(0xFF1E3149);
  static const Color darkBorderStrong = Color(0xFF2B4565);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFA7B6CA);
  static const Color darkTextMuted = Color(0xFF6F829C);
  static const Color darkAccent = Color(0xFF4D9AFF);
  static const Color darkSidebar = Color(0xFF071426);
  static const Color darkSidebarDeep = Color(0xFF040D18);
  static const Color darkSidebarActive = Color(0xFF12304F);
}

/// Ready-made gradients used by the brand surfaces.
abstract final class SaytarlyGradients {
  SaytarlyGradients._();

  static const LinearGradient brandMark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SaytarlyColors.navy800, SaytarlyColors.deepNavy],
  );

  static const LinearGradient sidebar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [SaytarlyColors.deepNavy, Color(0xFF071628)],
  );

  static const LinearGradient controlBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E8BFF), SaytarlyColors.controlBlue],
  );

  static const LinearGradient loginPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1C34), Color(0xFF0B2547), Color(0xFF061322)],
  );

  static const LinearGradient chartArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x401677FF), Color(0x001677FF)],
  );
}

/// Low-contrast elevation used throughout the desktop workspace.
abstract final class SaytarlyShadows {
  SaytarlyShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x080F172A), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(color: Color(0x120F172A), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x120F172A), blurRadius: 30, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1F0F172A),
      blurRadius: 48,
      offset: Offset(0, 24),
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> blueGlow = [
    BoxShadow(color: Color(0x331677FF), blurRadius: 28, offset: Offset(0, 10)),
  ];
}

/// Semantic + surface colours exposed through [ThemeData.extensions].
///
/// Reading through the extension keeps widgets theme-aware without importing
/// hard-coded colours, and makes the dark workspace a first-class citizen.
@immutable
class SaytarlyThemeTokens extends ThemeExtension<SaytarlyThemeTokens> {
  const SaytarlyThemeTokens({
    required this.isDark,
    required this.brandNavy,
    required this.brandBlue,
    required this.brandBlueHover,
    required this.brandBluePressed,
    required this.softBlue,
    required this.canvas,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.profit,
    required this.sidebar,
    required this.sidebarDeep,
    required this.sidebarActive,
    required this.sidebarText,
    required this.sidebarMuted,
    required this.sidebarBorder,
    required this.shadow,
  });

  final bool isDark;
  final Color brandNavy;
  final Color brandBlue;
  final Color brandBlueHover;
  final Color brandBluePressed;
  final Color softBlue;
  final Color canvas;
  final Color surface;
  final Color surfaceSoft;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color profit;

  final Color sidebar;
  final Color sidebarDeep;
  final Color sidebarActive;
  final Color sidebarText;
  final Color sidebarMuted;
  final Color sidebarBorder;
  final Color shadow;

  static const SaytarlyThemeTokens light = SaytarlyThemeTokens(
    isDark: false,
    brandNavy: SaytarlyColors.deepNavy,
    brandBlue: SaytarlyColors.controlBlue,
    brandBlueHover: SaytarlyColors.controlBlueHover,
    brandBluePressed: SaytarlyColors.controlBluePressed,
    softBlue: SaytarlyColors.softBlue,
    canvas: SaytarlyColors.appCanvas,
    surface: SaytarlyColors.surfaceWhite,
    surfaceSoft: SaytarlyColors.surfaceSoft,
    surfaceSunken: SaytarlyColors.surfaceSunken,
    border: SaytarlyColors.border,
    borderStrong: SaytarlyColors.borderStrong,
    textPrimary: SaytarlyColors.textPrimary,
    textSecondary: SaytarlyColors.textSecondary,
    textMuted: SaytarlyColors.textMuted,
    success: SaytarlyColors.success,
    warning: SaytarlyColors.warning,
    danger: SaytarlyColors.danger,
    info: SaytarlyColors.information,
    profit: SaytarlyColors.profit,
    sidebar: SaytarlyColors.deepNavy,
    sidebarDeep: Color(0xFF08172B),
    sidebarActive: SaytarlyColors.navy700,
    sidebarText: Color(0xFFF8FAFC),
    sidebarMuted: Color(0xFF9FB0C7),
    sidebarBorder: Color(0x14FFFFFF),
    shadow: Color(0x140F172A),
  );

  static const SaytarlyThemeTokens dark = SaytarlyThemeTokens(
    isDark: true,
    brandNavy: Color(0xFF0B1F3A),
    brandBlue: SaytarlyColors.darkAccent,
    brandBlueHover: Color(0xFF6FB1FF),
    brandBluePressed: Color(0xFF3D83E0),
    softBlue: Color(0xFF122B4A),
    canvas: SaytarlyColors.darkCanvas,
    surface: SaytarlyColors.darkSurface,
    surfaceSoft: SaytarlyColors.darkSurfaceSoft,
    surfaceSunken: SaytarlyColors.darkSurfaceSunken,
    border: SaytarlyColors.darkBorder,
    borderStrong: SaytarlyColors.darkBorderStrong,
    textPrimary: SaytarlyColors.darkTextPrimary,
    textSecondary: SaytarlyColors.darkTextSecondary,
    textMuted: SaytarlyColors.darkTextMuted,
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
    profit: Color(0xFF2DD4BF),
    sidebar: SaytarlyColors.darkSidebar,
    sidebarDeep: SaytarlyColors.darkSidebarDeep,
    sidebarActive: SaytarlyColors.darkSidebarActive,
    sidebarText: Color(0xFFEAF1FA),
    sidebarMuted: Color(0xFF7E91AB),
    sidebarBorder: Color(0x12FFFFFF),
    shadow: Color(0x66000000),
  );

  /// A translucent semantic tint that works in both modes.
  Color tint(Color color, {double light = 0.10, double dark = 0.18}) =>
      color.withValues(alpha: isDark ? dark : light);

  /// Readable foreground for text rendered on a semantic tint.
  Color onTint(Color color) =>
      isDark
          ? Color.lerp(color, Colors.white, 0.18)!
          : Color.lerp(color, Colors.black, 0.22)!;

  @override
  SaytarlyThemeTokens copyWith({
    bool? isDark,
    Color? brandNavy,
    Color? brandBlue,
    Color? brandBlueHover,
    Color? brandBluePressed,
    Color? softBlue,
    Color? canvas,
    Color? surface,
    Color? surfaceSoft,
    Color? surfaceSunken,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? profit,
    Color? sidebar,
    Color? sidebarDeep,
    Color? sidebarActive,
    Color? sidebarText,
    Color? sidebarMuted,
    Color? sidebarBorder,
    Color? shadow,
  }) {
    return SaytarlyThemeTokens(
      isDark: isDark ?? this.isDark,
      brandNavy: brandNavy ?? this.brandNavy,
      brandBlue: brandBlue ?? this.brandBlue,
      brandBlueHover: brandBlueHover ?? this.brandBlueHover,
      brandBluePressed: brandBluePressed ?? this.brandBluePressed,
      softBlue: softBlue ?? this.softBlue,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      profit: profit ?? this.profit,
      sidebar: sidebar ?? this.sidebar,
      sidebarDeep: sidebarDeep ?? this.sidebarDeep,
      sidebarActive: sidebarActive ?? this.sidebarActive,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarMuted: sidebarMuted ?? this.sidebarMuted,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  SaytarlyThemeTokens lerp(
    covariant ThemeExtension<SaytarlyThemeTokens>? other,
    double t,
  ) {
    if (other is! SaytarlyThemeTokens) return this;
    return SaytarlyThemeTokens(
      isDark: t < 0.5 ? isDark : other.isDark,
      brandNavy: Color.lerp(brandNavy, other.brandNavy, t)!,
      brandBlue: Color.lerp(brandBlue, other.brandBlue, t)!,
      brandBlueHover: Color.lerp(brandBlueHover, other.brandBlueHover, t)!,
      brandBluePressed:
          Color.lerp(brandBluePressed, other.brandBluePressed, t)!,
      softBlue: Color.lerp(softBlue, other.softBlue, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarDeep: Color.lerp(sidebarDeep, other.sidebarDeep, t)!,
      sidebarActive: Color.lerp(sidebarActive, other.sidebarActive, t)!,
      sidebarText: Color.lerp(sidebarText, other.sidebarText, t)!,
      sidebarMuted: Color.lerp(sidebarMuted, other.sidebarMuted, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// `context.saytarly` — the quickest way to reach the design tokens.
extension SaytarlyThemeContext on BuildContext {
  SaytarlyThemeTokens get saytarly {
    final theme = Theme.of(this);
    return theme.extension<SaytarlyThemeTokens>() ??
        (theme.brightness == Brightness.dark
            ? SaytarlyThemeTokens.dark
            : SaytarlyThemeTokens.light);
  }
}
