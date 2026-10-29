import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Enum representing the supported platforms in the application
enum AppPlatformType {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
  unknown,
}

/// A utility class to detect and manage platform-specific behavior
class PlatformDetector {
  static PlatformDetector? _instance;
  late final AppPlatformType _currentPlatform;

  PlatformDetector._internal() {
    _currentPlatform = _detectPlatform();
  }

  /// Singleton instance
  static PlatformDetector get instance {
    _instance ??= PlatformDetector._internal();
    return _instance!;
  }

  /// Get the current platform type
  AppPlatformType get currentPlatform => _currentPlatform;

  /// Check if the current platform is Android
  bool get isAndroid => _currentPlatform == AppPlatformType.android;

  /// Check if the current platform is iOS
  bool get isIOS => _currentPlatform == AppPlatformType.ios;

  /// Check if the current platform is Web
  bool get isWeb => _currentPlatform == AppPlatformType.web;

  /// Check if the current platform is Windows
  bool get isWindows => _currentPlatform == AppPlatformType.windows;

  /// Check if the current platform is macOS
  bool get isMacOS => _currentPlatform == AppPlatformType.macos;

  /// Check if the current platform is Linux
  bool get isLinux => _currentPlatform == AppPlatformType.linux;

  /// Check if the current platform is a mobile platform (Android or iOS)
  bool get isMobile => isAndroid || isIOS;

  /// Check if the current platform is a desktop platform
  bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Check if SIP UA should be used (non-Android platforms)
  /// On Android, we use a different native SIP implementation.
  bool get useSipUA => !isAndroid;

  /// Check if the native Android SIP implementation should be used
  bool get useNativeAndroidSip => isAndroid;

  /// Detect the current platform
  AppPlatformType _detectPlatform() {
    if (kIsWeb) {
      return AppPlatformType.web;
    }

    if (Platform.isAndroid) {
      return AppPlatformType.android;
    }

    if (Platform.isIOS) {
      return AppPlatformType.ios;
    }

    if (Platform.isWindows) {
      return AppPlatformType.windows;
    }

    if (Platform.isMacOS) {
      return AppPlatformType.macos;
    }

    if (Platform.isLinux) {
      return AppPlatformType.linux;
    }

    return AppPlatformType.unknown;
  }

  @override
  String toString() => 'PlatformDetector(platform: $_currentPlatform)';
}

/// Convenience global accessor for platform detection
final platformDetector = PlatformDetector.instance;

