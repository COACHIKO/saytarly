import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../../services/shared_pref/pref_keys.dart';
import '../../../services/shared_pref/shared_pref.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(_getInitialThemeMode());

  /// Get initial theme mode from SharedPreferences
  static ThemeMode _getInitialThemeMode() {
    // First check the new string-based theme mode
    final themeString = SharedPref.preferences.getString(PrefKeys.themeMode);
    if (themeString != null) {
      return _parseThemeMode(themeString);
    }

    // Fallback to legacy boolean theme
    final legacyTheme = SharedPref().getBool("theme");
    return legacyTheme ? ThemeMode.dark : ThemeMode.light;
  }

  /// Parse theme mode from string
  static ThemeMode _parseThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Legacy toggle theme (for backward compatibility)
  void toggleTheme(bool isDarkMode) {
    final themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final themeString = isDarkMode ? 'dark' : 'light';
    SharedPref().setBool("theme", isDarkMode);
    SharedPref.preferences.setString(PrefKeys.themeMode, themeString);
    emit(themeMode);
  }

  /// Simple flip used by UI toggles when the direction doesn't matter.
  void toggle() {
    setThemeModeEnum(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Set theme mode using string value ('light', 'dark', 'system')
  void setThemeMode(String theme) {
    final themeMode = _parseThemeMode(theme);
    SharedPref.preferences.setString(PrefKeys.themeMode, theme);
    // Also update legacy bool for backward compatibility
    if (theme == 'dark') {
      SharedPref().setBool("theme", true);
    } else if (theme == 'light') {
      SharedPref().setBool("theme", false);
    }
    emit(themeMode);
  }

  /// Set theme mode directly using ThemeMode enum
  void setThemeModeEnum(ThemeMode mode) {
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      themeString = 'system';
        break;
    }
    setThemeMode(themeString);
  }

  /// Get current theme mode as string
  String get currentThemeString {
    switch (state) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      return 'system';
    }
  }
}
