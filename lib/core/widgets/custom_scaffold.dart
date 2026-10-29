import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../platform_type.dart';
import '../utils/platform_utils.dart';

/// Custom Scaffold that adapts to different screen sizes
/// Handles mobile, tablet, desktop (Windows, macOS, Web) layouts
class CustomScaffold extends StatelessWidget {
  final Widget? body;
  final Widget? mobileBody;
  final Widget? windowsBody;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  /// Optional custom body for large screens (desktop/tablet)
  /// If null, uses the same body as mobile
  final Widget? desktopBody;

  /// Maximum width for content on large screens
  /// Defaults to 1200
  final double maxContentWidth;

  /// Whether to center the content on large screens
  /// Defaults to true
  final bool centerContentOnLargeScreen;

  const CustomScaffold({
    super.key,
    this.body,
    this.mobileBody,
    this.windowsBody,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
    this.desktopBody,
    this.maxContentWidth = 1200,
    this.centerContentOnLargeScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = PlatformUtils.isLargeScreen(context);
    final platform = platformDetector;

    // Check if platform is desktop (Windows, macOS, or Linux)
    final isDesktop =
        platform.isWindows || platform.isMacOS || platform.isLinux;

    Widget? resolvedBody;

    if (isDesktop && windowsBody != null) {
      resolvedBody = windowsBody;
    } else if (platform.isMobile && mobileBody != null) {
      resolvedBody = mobileBody;
    } else if (isLargeScreen && desktopBody != null) {
      resolvedBody = desktopBody;
    }

    final bodyToUse = resolvedBody ?? body ?? mobileBody ?? desktopBody;

    return Scaffold(
      appBar: appBar,
      body: isLargeScreen && centerContentOnLargeScreen
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: bodyToUse,
              ),
            )
          : bodyToUse,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}
