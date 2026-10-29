import 'dart:ui';
import 'package:flutter/material.dart';
import '../platform_type.dart';
import '../utils/constants/colors.dart';

/// Dialog type enum for different visual styles
enum AppDialogType {
  error,
  success,
  warning,
  info,
  confirm,
}

/// Beautiful, responsive dialog system for both mobile and desktop platforms.
/// Provides consistent, user-friendly feedback across the entire application.
class AppDialog {
  AppDialog._();

  /// Show an error dialog with animated icon and smooth transitions
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context: context,
      type: AppDialogType.error,
      title: title,
      message: message,
      buttonText: buttonText ?? 'Got it',
      onPressed: onPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context: context,
      type: AppDialogType.success,
      title: title,
      message: message,
      buttonText: buttonText ?? 'Awesome!',
      onPressed: onPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show a warning dialog
  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context: context,
      type: AppDialogType.warning,
      title: title,
      message: message,
      buttonText: buttonText ?? 'Understood',
      onPressed: onPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show an info dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context: context,
      type: AppDialogType.info,
      title: title,
      message: message,
      buttonText: buttonText ?? 'OK',
      onPressed: onPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show a confirmation dialog with two buttons
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDangerous = false,
  }) {
    return _showConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText ?? 'Confirm',
      cancelText: cancelText ?? 'Cancel',
      isDangerous: isDangerous,
    );
  }

  static Future<void> _showDialog({
    required BuildContext context,
    required AppDialogType type,
    required String title,
    required String message,
    required String buttonText,
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    final isDesktop = platformDetector.isDesktop || platformDetector.isWeb;

    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AppDialogContent(
          type: type,
          title: title,
          message: message,
          buttonText: buttonText,
          onPressed: onPressed,
          isDesktop: isDesktop,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * animation.value,
            sigmaY: 5 * animation.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    bool isDangerous = false,
  }) {
    final isDesktop = platformDetector.isDesktop || platformDetector.isWeb;

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AppConfirmDialogContent(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          isDangerous: isDangerous,
          isDesktop: isDesktop,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * animation.value,
            sigmaY: 5 * animation.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Internal dialog content widget
class _AppDialogContent extends StatefulWidget {
  const _AppDialogContent({
    required this.type,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.isDesktop,
    this.onPressed,
  });

  final AppDialogType type;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool isDesktop;

  @override
  State<_AppDialogContent> createState() => _AppDialogContentState();
}

class _AppDialogContentState extends State<_AppDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _iconRotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _iconAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogWidth =
        widget.isDesktop ? 420.0 : MediaQuery.of(context).size.width * 0.85;
    final config = _getDialogConfig(widget.type);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxWidth: widget.isDesktop ? 420 : 340),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(widget.isDesktop ? 24 : 20),
            boxShadow: [
              BoxShadow(
                color: config.color.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored header strip
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      config.color,
                      config.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(widget.isDesktop ? 32 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated icon
                    AnimatedBuilder(
                      animation: _iconAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _iconRotationAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: _DialogIcon(
                        type: widget.type,
                        config: config,
                        isDesktop: widget.isDesktop,
                      ),
                    ),
                    SizedBox(height: widget.isDesktop ? 28 : 20),
                    // Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.isDesktop ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Message
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.isDesktop ? 16 : 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: widget.isDesktop ? 32 : 24),
                    // Button
                    _DialogButton(
                      text: widget.buttonText,
                      color: config.color,
                      isDesktop: widget.isDesktop,
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onPressed?.call();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirm dialog content widget
class _AppConfirmDialogContent extends StatelessWidget {
  const _AppConfirmDialogContent({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDangerous,
    required this.isDesktop,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogWidth =
        isDesktop ? 420.0 : MediaQuery.of(context).size.width * 0.85;
    final confirmColor = isDangerous ? CColors.error : CColors.primary;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxWidth: isDesktop ? 420 : 340),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: isDesktop ? 72 : 60,
                  height: isDesktop ? 72 : 60,
                  decoration: BoxDecoration(
                    color: (isDangerous ? CColors.error : CColors.info)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDangerous
                        ? Icons.warning_amber_rounded
                        : Icons.help_outline_rounded,
                    size: isDesktop ? 36 : 30,
                    color: isDangerous ? CColors.error : CColors.info,
                  ),
                ),
                SizedBox(height: isDesktop ? 28 : 20),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: isDesktop ? 32 : 24),
                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: _DialogOutlineButton(
                        text: cancelText,
                        isDesktop: isDesktop,
                        isDark: isDark,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        text: confirmText,
                        color: confirmColor,
                        isDesktop: isDesktop,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated icon widget for dialogs
class _DialogIcon extends StatelessWidget {
  const _DialogIcon({
    required this.type,
    required this.config,
    required this.isDesktop,
  });

  final AppDialogType type;
  final _DialogConfig config;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final size = isDesktop ? 80.0 : 64.0;
    final iconSize = isDesktop ? 42.0 : 34.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            config.color.withOpacity(0.2),
            config.color.withOpacity(0.05),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.75,
          height: size * 0.75,
          decoration: BoxDecoration(
            color: config.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            config.icon,
            size: iconSize,
            color: config.color,
          ),
        ),
      ),
    );
  }
}

/// Primary dialog button
class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.text,
    required this.color,
    required this.isDesktop,
    required this.onPressed,
  });

  final String text;
  final Color color;
  final bool isDesktop;
  final VoidCallback onPressed;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _onHoverChanged(bool isHovered) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isHovered != isHovered) {
        setState(() => _isHovered = isHovered);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: widget.isDesktop ? 52 : 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isPressed
                  ? [
                      widget.color.withOpacity(0.9),
                      widget.color.withOpacity(0.8),
                    ]
                  : _isHovered
                      ? [
                          widget.color.withOpacity(0.95),
                          widget.color,
                        ]
                      : [
                          widget.color,
                          widget.color.withOpacity(0.85),
                        ],
            ),
            borderRadius: BorderRadius.circular(widget.isDesktop ? 14 : 12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.4 : 0.25),
                blurRadius: _isHovered ? 16 : 10,
                offset: Offset(0, _isPressed ? 2 : (_isHovered ? 6 : 4)),
              ),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, _isPressed ? 2.0 : 0.0),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.isDesktop ? 16 : 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline/secondary dialog button
class _DialogOutlineButton extends StatefulWidget {
  const _DialogOutlineButton({
    required this.text,
    required this.isDesktop,
    required this.isDark,
    required this.onPressed,
  });

  final String text;
  final bool isDesktop;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  State<_DialogOutlineButton> createState() => _DialogOutlineButtonState();
}

class _DialogOutlineButtonState extends State<_DialogOutlineButton> {
  bool _isHovered = false;

  void _onHoverChanged(bool isHovered) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isHovered != isHovered) {
        setState(() => _isHovered = isHovered);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: widget.isDesktop ? 52 : 48,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFF3F4F6))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.isDesktop ? 14 : 12),
            border: Border.all(
              color: _isHovered
                  ? CColors.primary.withOpacity(0.5)
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFE5E7EB)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.isDesktop ? 16 : 15,
                fontWeight: FontWeight.w600,
                color: _isHovered
                    ? CColors.primary
                    : (widget.isDark
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF4B5563)),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog configuration for different types
class _DialogConfig {
  const _DialogConfig({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;
}

_DialogConfig _getDialogConfig(AppDialogType type) {
  switch (type) {
    case AppDialogType.error:
      return const _DialogConfig(
        color: Color(0xFFEF4444),
        icon: Icons.close_rounded,
      );
    case AppDialogType.success:
      return const _DialogConfig(
        color: Color(0xFF10B981),
        icon: Icons.check_rounded,
      );
    case AppDialogType.warning:
      return const _DialogConfig(
        color: Color(0xFFF59E0B),
        icon: Icons.warning_amber_rounded,
      );
    case AppDialogType.info:
      return const _DialogConfig(
        color: Color(0xFF3B82F6),
        icon: Icons.info_outline_rounded,
      );
    case AppDialogType.confirm:
      return const _DialogConfig(
        color: Color(0xFF3B82F6),
        icon: Icons.help_outline_rounded,
      );
  }
}
