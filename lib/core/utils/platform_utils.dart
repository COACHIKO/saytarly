import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for platform detection and responsive layout helpers
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on mobile (Android or iOS)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Check if running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Check if running on Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// Check if running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Check if running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Breakpoint for large screens (tablets and desktops)
  static const double largeScreenBreakpoint = 900;

  /// Breakpoint for medium screens (small tablets)
  static const double mediumScreenBreakpoint = 600;

  /// Check if the current screen is considered large
  /// (desktop, web in fullscreen, or large tablets)
  static bool isLargeScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= largeScreenBreakpoint || isDesktop || isWeb;
  }

  /// Check if the current screen is considered medium
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mediumScreenBreakpoint && width < largeScreenBreakpoint;
  }

  /// Check if the current screen is considered small (mobile)
  static bool isSmallScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < mediumScreenBreakpoint;
  }

  /// Get the screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeScreenBreakpoint) {
      return ScreenType.large;
    } else if (width >= mediumScreenBreakpoint) {
      return ScreenType.medium;
    } else {
      return ScreenType.small;
    }
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.large:
        return desktop ?? tablet ?? mobile;
      case ScreenType.medium:
        return tablet ?? mobile;
      case ScreenType.small:
        return mobile;
    }
  }
}

/// Enum for screen types
enum ScreenType {
  small, // Mobile
  medium, // Tablet
  large, // Desktop/Web
}
