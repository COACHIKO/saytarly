import 'package:flutter/material.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';

/// Legacy colour aliases kept for the mobile surfaces and older widgets.
///
/// New desktop code should read [SaytarlyThemeTokens] through
/// `context.saytarly` instead of hard-coding colours.
class CColors {
  // App theme colours.
  static const Color primary = SaytarlyColors.controlBlue;
  static const Color secondary = SaytarlyColors.deepNavy;
  static const Color accent = SaytarlyColors.softBlue;

  // Text colours.
  static const Color textPrimary = SaytarlyColors.textPrimary;
  static const Color textSecondary = SaytarlyColors.textSecondary;
  static const Color textWhite = Colors.white;

  // Background colours.
  static const Color light = SaytarlyColors.appCanvas;
  static const Color dark = SaytarlyColors.textPrimary;
  static const Color primaryBackground = SaytarlyColors.softBlue;

  // Background container colours.
  static const Color lightContainer = SaytarlyColors.surfaceSoft;
  static Color darkContainer = CColors.white.withValues(alpha: 0.1);

  // Button colours.
  static const Color buttonPrimary = SaytarlyColors.controlBlue;
  static const Color buttonSecondary = SaytarlyColors.textSecondary;
  static const Color buttonDisabled = Color(0xFFCBD5E1);

  // Border colours.
  static const Color borderPrimary = SaytarlyColors.border;
  static const Color borderSecondary = Color(0xFFF1F5F9);

  // Error and validation colours.
  static const Color error = SaytarlyColors.danger;
  static const Color success = SaytarlyColors.success;
  static const Color warning = SaytarlyColors.warning;
  static const Color info = SaytarlyColors.information;

  // Neutral shades.
  static const Color black = SaytarlyColors.textPrimary;
  static const Color darkerGrey = SaytarlyColors.textSecondary;
  static const Color darkGrey = SaytarlyColors.textMuted;
  static const Color grey = SaytarlyColors.border;
  static const Color softGrey = SaytarlyColors.surfaceSoft;
  static const Color lightGrey = SaytarlyColors.appCanvas;
  static const Color white = Color(0xFFFFFFFF);
}
