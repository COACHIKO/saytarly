import 'dart:ui';

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// APP TOAST
/// A polished, Windows 11 / Fluent-inspired toast notification system.
/// Lightweight, non-blocking alternative to [SnackBar]. Designed to look
/// great on desktop (top-right stack) and mobile (top center), with frosted
/// glass background, accent stripe, animated icon, progress bar and an
/// optional action button.
///
///
/// Usage:
/// ```dart
/// AppToast.success(context, message: 'Recording saved');
/// AppToast.error(context, title: 'Save failed', message: e.toString());
/// AppToast.info(context, message: 'Connected to server');
/// ```
/// ═══════════════════════════════════════════════════════════════════════════

enum AppToastType { success, error, warning, info }

enum AppToastPosition { topRight, topCenter, bottomRight, bottomCenter }

class AppToast {
  AppToast._();

  static final List<_ToastEntry> _entries = <_ToastEntry>[];

  /// Quick success toast.
  static void success(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    AppToastPosition? position,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context,
        type: AppToastType.success,
        title: title,
        message: message,
        duration: duration,
        position: position,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Quick error toast.
  static void error(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 5),
    AppToastPosition? position,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context,
        type: AppToastType.error,
        title: title,
        message: message,
        duration: duration,
        position: position,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Quick warning toast.
  static void warning(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    AppToastPosition? position,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context,
        type: AppToastType.warning,
        title: title,
        message: message,
        duration: duration,
        position: position,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Quick info toast.
  static void info(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    AppToastPosition? position,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context,
        type: AppToastType.info,
        title: title,
        message: message,
        duration: duration,
        position: position,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Full-control entry point.
  static void show(
    BuildContext context, {
    required AppToastType type,
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    AppToastPosition? position,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final mq = MediaQuery.maybeOf(context);
    final isWide = (mq?.size.width ?? 0) >= 720;
    final resolvedPosition = position ??
        (isWide ? AppToastPosition.topRight : AppToastPosition.topCenter);

    final entry = _ToastEntry(
      type: type,
      title: title,
      message: message,
      duration: duration,
      position: resolvedPosition,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    entry.overlayEntry = OverlayEntry(
      builder: (ctx) =>
          _ToastStack(entry: entry, onDismiss: () => _remove(entry)),
    );

    _entries.add(entry);
    overlay.insert(entry.overlayEntry!);
  }

  static void _remove(_ToastEntry entry) {
    if (!_entries.remove(entry)) return;
    entry.overlayEntry?.remove();
    entry.overlayEntry = null;
  }

  /// Dismiss every toast currently shown.
  static void dismissAll() {
    for (final entry in List<_ToastEntry>.from(_entries)) {
      _remove(entry);
    }
  }
}

class _ToastEntry {
  _ToastEntry({
    required this.type,
    required this.title,
    required this.message,
    required this.duration,
    required this.position,
    required this.actionLabel,
    required this.onAction,
  });

  final AppToastType type;
  final String? title;
  final String message;
  final Duration duration;
  final AppToastPosition position;
  final String? actionLabel;
  final VoidCallback? onAction;
  OverlayEntry? overlayEntry;
}

class _ToastStack extends StatefulWidget {
  const _ToastStack({required this.entry, required this.onDismiss});

  final _ToastEntry entry;
  final VoidCallback onDismiss;

  @override
  State<_ToastStack> createState() => _ToastStackState();
}

class _ToastStackState extends State<_ToastStack>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _progressCtrl;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _controller.forward();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.entry.duration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dismiss();
      })
      ..forward();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    if (_controller.status == AnimationStatus.reverse ||
        _controller.status == AnimationStatus.dismissed) {
      return;
    }
    _progressCtrl.stop();
    await _controller.reverse();
    widget.onDismiss();
  }

  void _onHover(bool value) {
    setState(() => _hovering = value);
    if (value) {
      _progressCtrl.stop();
    } else if (_progressCtrl.value < 1.0) {
      _progressCtrl.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final position = widget.entry.position;
    final isTop = position == AppToastPosition.topRight ||
        position == AppToastPosition.topCenter;
    final isCenter = position == AppToastPosition.topCenter ||
        position == AppToastPosition.bottomCenter;

    final beginOffset = Offset(
      isCenter ? 0 : (position == AppToastPosition.topRight ? 1.05 : 1.05),
      isCenter ? (isTop ? -0.4 : 0.4) : 0,
    );

    final slide = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    final fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    final card = MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: _ToastCard(
        entry: widget.entry,
        progressCtrl: _progressCtrl,
        isHovering: _hovering,
        onClose: _dismiss,
      ),
    );

    return Positioned(
      top: isTop ? mq.padding.top + 16 : null,
      bottom: isTop ? null : mq.padding.bottom + 16,
      left: isCenter ? 0 : null,
      right: isCenter ? 0 : 16,
      child: Align(
        alignment: isCenter
            ? (isTop ? Alignment.topCenter : Alignment.bottomCenter)
            : (isTop ? Alignment.topRight : Alignment.bottomRight),
        child: SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: card,
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.entry,
    required this.progressCtrl,
    required this.isHovering,
    required this.onClose,
  });

  final _ToastEntry entry;
  final AnimationController progressCtrl;
  final bool isHovering;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = _palette(entry.type, isDark);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 420,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1F2230) : Colors.white)
                    .withOpacity(isHovering ? 0.98 : 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.accent.withOpacity(isDark ? 0.35 : 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                    blurRadius: isHovering ? 30 : 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccentStripe(color: palette.accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AnimatedIcon(palette: palette),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if ((entry.title ?? '').isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            entry.title!,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        entry.message,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.78),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _CloseButton(onTap: onClose),
                              ],
                            ),
                            if (entry.actionLabel != null &&
                                entry.onAction != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: palette.accent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      entry.onAction?.call();
                                      onClose();
                                    },
                                    child: Text(
                                      entry.actionLabel!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            AnimatedBuilder(
                              animation: progressCtrl,
                              builder: (_, __) => _ProgressBar(
                                value: 1.0 - progressCtrl.value,
                                color: palette.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastPalette _palette(AppToastType type, bool isDark) {
    switch (type) {
      case AppToastType.success:
        return const _ToastPalette(
          accent: Color(0xFF16A34A),
          softBg: Color(0xFFDCFCE7),
          icon: Icons.check_circle_rounded,
        );
      case AppToastType.error:
        return const _ToastPalette(
          accent: Color(0xFFDC2626),
          softBg: Color(0xFFFEE2E2),
          icon: Icons.error_rounded,
        );
      case AppToastType.warning:
        return const _ToastPalette(
          accent: Color(0xFFD97706),
          softBg: Color(0xFFFEF3C7),
          icon: Icons.warning_amber_rounded,
        );
      case AppToastType.info:
        return const _ToastPalette(
          accent: Color(0xFF2563EB),
          softBg: Color(0xFFDBEAFE),
          icon: Icons.info_rounded,
        );
    }
  }
}

class _ToastPalette {
  const _ToastPalette({
    required this.accent,
    required this.softBg,
    required this.icon,
  });

  final Color accent;
  final Color softBg;
  final IconData icon;
}

class _AccentStripe extends StatelessWidget {
  const _AccentStripe({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _AnimatedIcon extends StatefulWidget {
  const _AnimatedIcon({required this.palette});
  final _ToastPalette palette;

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTransition(
      scale: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? widget.palette.accent.withOpacity(0.22)
              : widget.palette.softBg,
        ),
        alignment: Alignment.center,
        child:
            Icon(widget.palette.icon, color: widget.palette.accent, size: 20),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _hover
                ? scheme.onSurface.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: scheme.onSurface.withOpacity(0.55),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 3,
        child: Stack(
          children: [
            Container(color: color.withOpacity(0.12)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
