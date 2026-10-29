import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../services/shared_pref/pref_keys.dart';
import '../../../services/shared_pref/shared_pref.dart';

/// Accent colors available for selection
class AccentColors {
  static const List<Color> colors = [
    Color(0xFF5fb141), // Green (default - matches CColors.primary)
    Color(0xFF6366F1), // Indigo
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
  ];

  static Color getColor(int index) {
    if (index < 0 || index >= colors.length) return colors[0];
    return colors[index];
  }
}

/// Cubit that manages the accent color across the app
class AccentColorCubit extends Cubit<Color> {
  AccentColorCubit() : super(_getInitialColor());

  /// Get initial accent color from SharedPreferences
  static Color _getInitialColor() {
    final index =
        SharedPref.preferences.getInt(PrefKeys.accentColorIndex) ?? 0;
    return AccentColors.getColor(index);
  }

  /// Get current color index
  int get currentIndex {
    final index = AccentColors.colors.indexOf(state);
    return index >= 0 ? index : 0;
  }

  /// Set accent color by index
  Future<void> setAccentColorIndex(int index) async {
    await SharedPref.preferences.setInt(PrefKeys.accentColorIndex, index);
    emit(AccentColors.getColor(index));
  }

  /// Set accent color directly
  Future<void> setAccentColor(Color color) async {
    final index = AccentColors.colors.indexOf(color);
    if (index >= 0) {
      await setAccentColorIndex(index);
    }
  }
}
