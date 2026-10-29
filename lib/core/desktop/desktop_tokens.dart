import 'package:flutter/material.dart';

/// قِيَم التصميم الموحّدة لواجهة سطح المكتب (مسافات، انحناءات، مقاسات).
///
/// أي شاشة ويندوز جديدة تستخدم القِيَم دي عشان الشكل يفضل متسق في كل الصفحات.
class DesktopTokens {
  DesktopTokens._();

  // ------- مقاسات أساسية -------
  static const double sidebarWidth = 264;
  static const double sidebarCollapsedWidth = 84;
  static const double topBarHeight = 64;
  static const double contentMaxWidth = 1560;
  static const double pagePadding = 24;
  static const double pageHeaderHeight = 74;

  // ------- مسافات -------
  static const double gapXs = 6;
  static const double gapSm = 10;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double gapXl = 32;

  // ------- انحناءات -------
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;

  // ------- حركة -------
  static const Duration fast = Duration(milliseconds: 130);
  static const Duration medium = Duration(milliseconds: 220);
}

/// ألوان واجهة سطح المكتب — مشتقة من ثيم التطبيق (لايت/دارك) عند الطلب.
///
/// الفكرة: نفس هوية اللون الأساسي (accent) بتاعة الثيم بتاع المستخدم،
/// لكن بمستويات أدق (حواف ناعمة، أسطح متعددة، سايد بار غامق ثابت) عشان
/// شكل الويندوز يبقى عالي المستوى في الوضعين.
class DesktopPalette {
  const DesktopPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
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

  /// خلفية الصفحة.
  final Color background;

  /// خلفية الكروت.
  final Color surface;

  /// سطح أخف (صفوف الجداول، الخانات الداخلية).
  final Color surfaceSoft;

  /// الحدود الناعمة الافتراضية.
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// اللون الرئيسي — جاي من ثيم التطبيق نفسه.
  final Color accent;
  final Color accentText;
  final Color accentSoft;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  final Color shadow;

  // ------- السايد بار (غامق في الوضعين — كشكل "أدوات" احترافي) -------
  final Color sidebarBg;
  final Color sidebarBgDeep;
  final Color sidebarFg;
  final Color sidebarMuted;
  final Color sidebarHover;
  final Color sidebarActiveBg;
  final Color sidebarBorder;

  /// نسخة شفافة من أي لون — للخلفيات الملونة (chips / badges).
  Color soft(Color color) => color.withValues(alpha: isDark ? 0.18 : 0.12);

  static const DesktopPalette dark = DesktopPalette(
    isDark: true,
    background: Color(0xFF0B0F1A),
    surface: Color(0xFF141B2C),
    surfaceSoft: Color(0xFF1B2335),
    border: Color(0x1F94A3C8),
    borderStrong: Color(0x3D94A3C8),
    textPrimary: Color(0xFFF2F5FB),
    textSecondary: Color(0xFFC2CADC),
    textMuted: Color(0xFF7F8AA3),
    accent: Color(0xFF3A7BD5),
    accentText: Color(0xFF8EB6F2),
    accentSoft: Color(0x263A7BD5),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    shadow: Color(0x59000000),
    sidebarBg: Color(0xFF0E1526),
    sidebarBgDeep: Color(0xFF0A101D),
    sidebarFg: Color(0xFFE8EDF8),
    sidebarMuted: Color(0xFF8E9AB4),
    sidebarHover: Color(0x14FFFFFF),
    sidebarActiveBg: Color(0x2E3A7BD5),
    sidebarBorder: Color(0x14FFFFFF),
  );

  static const DesktopPalette light = DesktopPalette(
    isDark: false,
    background: Color(0xFFF3F5FA),
    surface: Colors.white,
    surfaceSoft: Color(0xFFF1F4F9),
    border: Color(0xFFE4E8F1),
    borderStrong: Color(0xFFD5DBE7),
    textPrimary: Color(0xFF1B2333),
    textSecondary: Color(0xFF4D5769),
    textMuted: Color(0xFF8A93A6),
    accent: Color(0xFF39A96B),
    accentText: Color(0xFF2F7A50),
    accentSoft: Color(0x1F39A96B),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    shadow: Color(0x140B1220),
    sidebarBg: Color(0xFF0E1526),
    sidebarBgDeep: Color(0xFF0A101D),
    sidebarFg: Color(0xFFE8EDF8),
    sidebarMuted: Color(0xFF8E9AB4),
    sidebarHover: Color(0x14FFFFFF),
    sidebarActiveBg: Color(0x2E3A7BD5),
    sidebarBorder: Color(0x14FFFFFF),
  );

  /// يرجّع اللوحة المناسبة للثيم الحالي، والـ accent جاي من الثيم نفسه.
  static DesktopPalette of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? dark : light;
    final primary = theme.colorScheme.primary;

    final accentText = isDark
        ? Color.lerp(primary, Colors.white, 0.38)!
        : Color.lerp(primary, Colors.black, 0.42)!;

    return base.copyWith(
      accent: primary,
      accentText: accentText,
      accentSoft: primary.withValues(alpha: isDark ? 0.2 : 0.13),
      sidebarActiveBg: primary.withValues(alpha: isDark ? 0.24 : 0.18),
    );
  }

  DesktopPalette copyWith({
    bool? isDark,
    Color? background,
    Color? surface,
    Color? surfaceSoft,
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
