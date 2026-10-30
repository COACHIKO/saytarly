import 'package:flutter/material.dart';

import 'saytarly_brand.dart';

/// SAYTARLY's Material 3 theme.
///
/// Design rules encoded here:
/// - navy/blue identity, cool neutrals, semantic colour only when meaningful;
/// - low-contrast borders + very soft shadows;
/// - 8px spacing rhythm and 10–16px corner radii;
/// - comfortable desktop hit areas (40–44px);
/// - readable Arabic typography (Alexandria) and Inter for Latin.
abstract final class SaytarlyTheme {
  SaytarlyTheme._();

  static const String latinFont = 'Inter';
  static const String arabicFont = 'Alexandria';

  static ThemeData light({
    String? fontFamily,
    Color accent = SaytarlyColors.controlBlue,
  }) {
    return _build(
      brightness: Brightness.light,
      tokens: SaytarlyThemeTokens.light,
      fontFamily: fontFamily ?? latinFont,
      accent: accent,
    );
  }

  static ThemeData dark({
    String? fontFamily,
    Color accent = SaytarlyColors.darkAccent,
  }) {
    return _build(
      brightness: Brightness.dark,
      tokens: SaytarlyThemeTokens.dark,
      fontFamily: fontFamily ?? latinFont,
      accent: accent,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required SaytarlyThemeTokens tokens,
    required String fontFamily,
    required Color accent,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(fontFamily, tokens);
    final scheme = _colorScheme(brightness, tokens, accent);
    final radiusSm = BorderRadius.circular(8);
    final radiusMd = BorderRadius.circular(10);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: accent,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: tokens.canvas,
      canvasColor: tokens.canvas,
      dividerColor: tokens.border,
      disabledColor: tokens.textMuted,
      hoverColor: tokens.brandBlue.withValues(alpha: isDark ? 0.10 : 0.05),
      highlightColor: tokens.brandBlue.withValues(alpha: isDark ? 0.14 : 0.08),
      focusColor: tokens.brandBlue.withValues(alpha: 0.14),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: tokens.textSecondary, size: 20),
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 20),
      extensions: [tokens],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        iconTheme: IconThemeData(color: tokens.textSecondary, size: 20),
        actionsIconTheme: IconThemeData(color: tokens.textSecondary, size: 20),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        shape: Border(bottom: BorderSide(color: tokens.border)),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.border),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.surface,
        modalBarrierColor: SaytarlyColors.deepNavy.withValues(alpha: 0.42),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: tokens.borderStrong,
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: tokens.surfaceSoft,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textMuted,
          fontSize: 13,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textSecondary,
          fontSize: 13,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(color: accent),
        prefixIconColor: tokens.textMuted,
        suffixIconColor: tokens.textMuted,
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: tokens.danger, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.7)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? tokens.surfaceSoft : const Color(0xFFE7EDF5),
          disabledForegroundColor: tokens.textMuted,
          elevation: 0,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          overlayColor: Colors.white.withValues(alpha: 0.12),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? tokens.surfaceSoft : const Color(0xFFE7EDF5);
            }
            if (states.contains(WidgetState.pressed)) {
              return Color.lerp(accent, Colors.black, 0.14);
            }
            if (states.contains(WidgetState.hovered)) {
              return Color.lerp(accent, Colors.black, 0.10);
            }
            return accent;
          }),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? tokens.surfaceSoft : const Color(0xFFE7EDF5),
          disabledForegroundColor: tokens.textMuted,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: tokens.border),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return tokens.surfaceSoft;
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused) ||
                states.contains(WidgetState.hovered)) {
              return BorderSide(color: tokens.borderStrong);
            }
            return BorderSide(color: tokens.border);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.textSecondary,
          highlightColor: tokens.brandBlue.withValues(alpha: 0.08),
          hoverColor: tokens.brandBlue.withValues(alpha: 0.06),
          minimumSize: const Size(38, 38),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 420),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF15243A) : SaytarlyColors.deepNavy,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: SaytarlyShadows.floating,
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        margin: const EdgeInsets.only(top: 6),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: tokens.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.border),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(tokens.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(8),
          shadowColor: WidgetStatePropertyAll(tokens.shadow),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: tokens.border),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(tokens.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: tokens.border),
            ),
          ),
        ),
        inputDecorationTheme: base.inputDecorationTheme,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF15243A) : SaytarlyColors.deepNavy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: SaytarlyColors.darkAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceSoft,
        selectedColor: tokens.softBlue,
        disabledColor: tokens.surfaceSunken,
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: tokens.brandBlue,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: tokens.brandBlue,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: tokens.borderStrong, width: 1.3),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.10)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return tokens.borderStrong;
        }),
        overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? tokens.textMuted : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return isDark ? tokens.surfaceSunken : const Color(0xFFD7E0EA);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return tokens.border;
        }),
        overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.10)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: tokens.surfaceSunken,
        circularTrackColor: tokens.surfaceSunken,
        linearMinHeight: 6,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.hovered)) {
            return tokens.textMuted.withValues(alpha: 0.75);
          }
          return tokens.borderStrong.withValues(alpha: 0.8);
        }),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        thickness: const WidgetStatePropertyAll(7),
        radius: const Radius.circular(99),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
        interactive: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: tokens.textSecondary,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: tokens.border,
        overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.06)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        minVerticalPadding: 10,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: tokens.textSecondary,
        collapsedIconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
        collapsedTextColor: tokens.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        collapsedShape: RoundedRectangleBorder(borderRadius: radiusMd),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(tokens.surfaceSoft),
        headingTextStyle: textTheme.labelMedium?.copyWith(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textPrimary,
        ),
        dividerThickness: 1,
        horizontalMargin: 0,
        columnSpacing: 24,
        headingRowHeight: 42,
        dataRowMinHeight: 46,
        dataRowMaxHeight: 56,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ColorScheme _colorScheme(
    Brightness brightness,
    SaytarlyThemeTokens t,
    Color accent,
  ) {
    final base = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    return base.copyWith(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: t.softBlue,
      onPrimaryContainer: t.isDark ? t.brandBlue : t.brandNavy,
      secondary: t.profit,
      onSecondary: Colors.white,
      secondaryContainer: t.tint(t.profit, light: 0.08, dark: 0.20),
      onSecondaryContainer: t.onTint(t.profit),
      tertiary: t.warning,
      onTertiary: Colors.white,
      tertiaryContainer: t.tint(t.warning, light: 0.10, dark: 0.20),
      onTertiaryContainer: t.onTint(t.warning),
      error: t.danger,
      onError: Colors.white,
      errorContainer: t.tint(t.danger, light: 0.08, dark: 0.20),
      onErrorContainer: t.onTint(t.danger),
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textSecondary,
      surfaceDim: t.surfaceSoft,
      surfaceBright: t.surface,
      surfaceContainerLowest: t.surface,
      surfaceContainerLow: t.surfaceSoft,
      surfaceContainer: t.surfaceSoft,
      surfaceContainerHigh: t.surfaceSunken,
      surfaceContainerHighest: t.surfaceSunken,
      outline: t.borderStrong,
      outlineVariant: t.border,
      shadow: t.shadow,
      scrim: SaytarlyColors.deepNavy,
      inverseSurface: t.isDark ? t.surfaceSoft : SaytarlyColors.deepNavy,
      onInverseSurface: t.isDark ? t.textPrimary : Colors.white,
      inversePrimary: t.isDark ? t.brandBlue : SaytarlyColors.softBlue,
    );
  }

  static TextTheme _textTheme(String fontFamily, SaytarlyThemeTokens t) {
    TextStyle style({
      required double size,
      required double height,
      required FontWeight weight,
      double spacing = 0,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: spacing,
        color: t.textPrimary,
      );
    }

    return TextTheme(
      displayLarge: style(
        size: 40,
        height: 48,
        weight: FontWeight.w800,
        spacing: -1.2,
      ),
      displayMedium: style(
        size: 34,
        height: 42,
        weight: FontWeight.w800,
        spacing: -0.9,
      ),
      displaySmall: style(
        size: 28,
        height: 36,
        weight: FontWeight.w800,
        spacing: -0.5,
      ),
      headlineLarge: style(
        size: 26,
        height: 34,
        weight: FontWeight.w800,
        spacing: -0.4,
      ),
      headlineMedium: style(
        size: 22,
        height: 30,
        weight: FontWeight.w800,
        spacing: -0.2,
      ),
      headlineSmall: style(size: 20, height: 28, weight: FontWeight.w700),
      titleLarge: style(size: 18, height: 26, weight: FontWeight.w700),
      titleMedium: style(size: 16, height: 24, weight: FontWeight.w700),
      titleSmall: style(size: 14, height: 20, weight: FontWeight.w700),
      bodyLarge: style(size: 15, height: 24, weight: FontWeight.w500),
      bodyMedium: style(size: 14, height: 22, weight: FontWeight.w400),
      bodySmall: style(
        size: 12,
        height: 18,
        weight: FontWeight.w400,
      ).copyWith(color: t.textSecondary),
      labelLarge: style(size: 13, height: 18, weight: FontWeight.w700),
      labelMedium: style(
        size: 12,
        height: 16,
        weight: FontWeight.w600,
      ).copyWith(color: t.textSecondary),
      labelSmall: style(
        size: 11,
        height: 16,
        weight: FontWeight.w600,
      ).copyWith(color: t.textMuted),
    );
  }
}
