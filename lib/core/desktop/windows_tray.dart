import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'package:saytarly/core/localization/messages.dart';

/// Keeps Saytarly alive in the Windows notification area.
///
/// The window's X button no longer terminates the process: the close event is
/// intercepted and the window is hidden to the system tray. The tray icon can
/// restore the window or exit the app completely.
class WindowsTray with WindowListener, TrayListener {
  WindowsTray._();

  static final WindowsTray instance = WindowsTray._();

  static const String _iconPath = 'assets/images/app_icon.ico';
  static const String _tooltip = 'Saytarly';

  bool _windowReady = false;
  bool _trayReady = false;
  bool _exiting = false;

  bool get isSupported => Platform.isWindows;

  /// Intercepts the native close button and keeps the process alive.
  /// Safe to call multiple times.
  Future<void> prepareWindow() async {
    if (!isSupported || _windowReady) return;
    _windowReady = true;
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
  }

  /// Creates the tray icon and its context menu. Called after the first frame
  /// so the native plugins and the saved language are fully ready.
  Future<void> setupTray() async {
    if (!isSupported || _trayReady) return;
    _trayReady = true;
    trayManager.addListener(this);
    try {
      await trayManager.setIcon(_iconPath);
      await trayManager.setToolTip(_tooltip);
      await refreshMenu();
    } catch (error) {
      _trayReady = false;
      debugPrint('Windows tray setup notice: $error');
    }
  }

  /// Rebuilds the tray menu in the current UI language.
  Future<void> refreshMenu() async {
    if (!isSupported || !_trayReady) return;
    try {
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(
              key: 'show',
              label: 'فتح Saytarly'.tr(),
              onClick: (_) => showWindow(),
            ),
            MenuItem(
              key: 'hide',
              label: 'إخفاء'.tr(),
              onClick: (_) => hideToTray(),
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'exit',
              label: 'خروج'.tr(),
              onClick: (_) => exitApp(),
            ),
          ],
        ),
      );
    } catch (error) {
      debugPrint('Windows tray menu notice: $error');
    }
  }

  /// Brings the main window back from the tray.
  Future<void> showWindow() async {
    if (!isSupported) return;
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (error) {
      debugPrint('Windows tray show notice: $error');
    }
  }

  /// Hides the window while keeping the app and its background services alive.
  Future<void> hideToTray() async {
    if (!isSupported || _exiting) return;
    try {
      await windowManager.hide();
    } catch (error) {
      debugPrint('Windows tray hide notice: $error');
    }
  }

  /// Real quit from the tray menu — removes the icon and closes the process.
  Future<void> exitApp() async {
    if (!isSupported || _exiting) return;
    _exiting = true;
    try {
      await trayManager.destroy();
    } catch (_) {
      // The icon may already be gone.
    }
    try {
      await windowManager.setPreventClose(false);
    } catch (_) {}
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    // X button / Alt+F4 / taskbar close → hide, never quit.
    if (!_exiting) hideToTray();
  }

  @override
  void onTrayIconMouseDown() {
    showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}
