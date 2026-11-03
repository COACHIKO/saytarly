import 'dart:async';

import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/desktop/widgets/desktop_card.dart';
import 'package:saytarly/core/localization/messages.dart';

/// زر أيقونة في شريط الأدوات — دائري، لهوفر ناعم وتلميح (tooltip).
class DesktopToolbarIconButton extends StatefulWidget {
  DesktopToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// لمسة حمراء صغيرة في الرُكن (زي عدد الفواتير المعلقة).
  final int badgeCount;

  @override
  State<DesktopToolbarIconButton> createState() =>
      _DesktopToolbarIconButtonState();
}

class _DesktopToolbarIconButtonState extends State<DesktopToolbarIconButton>
    with WidgetsBindingObserver {
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🪟 تصفير الهوفر عند فقدان الفوكس — أزرار الشجرة/الهيدر ما تفضلش رمادية.
    if (state != AppLifecycleState.resumed && _hovering) {
      setState(() => _hovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: DesktopTokens.fast,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hovering
                  ? palette.surfaceSoft
                  : palette.surfaceSoft.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
              border: Border.all(
                color: _hovering
                    ? palette.border
                    : palette.border.withValues(alpha: 0),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 19,
                  color:
                      widget.onPressed == null
                          ? palette.textMuted.withValues(alpha: 0.5)
                          : _hovering
                          ? palette.textPrimary
                          : palette.textSecondary,
                ),
                if (widget.badgeCount > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: palette.danger,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// خانة بحث سطح المكتب — ناعمة، بأيقونة، وبدون حدود تقليدية.
class DesktopSearchField extends StatelessWidget {
  DesktopSearchField({
    super.key,
    this.controller,
    this.onChanged,
    String? hint,
    this.width = 280,
    this.autofocus = false,
  }) : hint = hint ?? 'بحث...'.tr();

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hint;
  final double width;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        style: TextStyle(
          fontSize: 13,
          color: palette.textPrimary,
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12.5, color: palette.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: palette.textMuted,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          filled: true,
          fillColor: palette.surfaceSoft,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
            borderSide: BorderSide(color: palette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
            borderSide: BorderSide(color: palette.accent, width: 1.4),
          ),
        ),
      ),
    );
  }
}

/// عنصر واحد جوه [DesktopSegmented].
class DesktopSegmentItem<T> {
  const DesktopSegmentItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// أزرار تبديل (Segmented control) — للتابات والفلاتر السريعة.
class DesktopSegmented<T> extends StatelessWidget {
  const DesktopSegmented({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<DesktopSegmentItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            _SegmentButton<T>(
              item: item,
              selected: item.value == value,
              onTap: () => onChanged(item.value),
              palette: palette,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.palette,
    required this.theme,
  });

  final DesktopSegmentItem<T> item;
  final bool selected;
  final VoidCallback onTap;
  final DesktopPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: DesktopTokens.fast,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color:
            selected
                ? (palette.isDark ? palette.accentSoft : palette.surface)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
        border: Border.all(
          color:
              selected
                  ? palette.accent.withValues(alpha: 0.22)
                  : Colors.transparent,
        ),
        boxShadow:
            selected && !palette.isDark
                ? [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 15,
              color: selected ? palette.accentText : palette.textMuted,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            item.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? palette.accentText : palette.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

/// شيب صغير (أيقونة + نص) — للحالات والوسوم.
class DesktopInfoChip extends StatelessWidget {
  const DesktopInfoChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final tint = color ?? palette.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: palette.soft(tint),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: palette.onSoft(tint)),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.onSoft(tint),
              fontWeight: FontWeight.w700,
              fontSize: dense ? 10.5 : 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة فارغة أنيقة لأي صفحة.
class DesktopEmptyState extends StatelessWidget {
  const DesktopEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesktopTokens.gapXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesktopIconBadge(
              icon: icon,
              size: 64,
              radius: DesktopTokens.radiusLg,
            ),
            const SizedBox(height: DesktopTokens.gapLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: DesktopTokens.gapSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: DesktopTokens.gapLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ساعة حية + تاريخ عربي — تُعرض في شريط الأدوات العلوي.
class DesktopClock extends StatefulWidget {
  const DesktopClock({super.key});

  @override
  State<DesktopClock> createState() => _DesktopClockState();
}

class _DesktopClockState extends State<DesktopClock> {
  static List<String> get _months => [
    'يناير'.tr(),
    'فبراير'.tr(),
    'مارس'.tr(),
    'أبريل'.tr(),
    'مايو'.tr(),
    'يونيو'.tr(),
    'يوليو'.tr(),
    'أغسطس'.tr(),
    'سبتمبر'.tr(),
    'أكتوبر'.tr(),
    'نوفمبر'.tr(),
    'ديسمبر'.tr(),
  ];

  static List<String> get _weekdays => [
    'الأحد'.tr(),
    'الاثنين'.tr(),
    'الثلاثاء'.tr(),
    'الأربعاء'.tr(),
    'الخميس'.tr(),
    'الجمعة'.tr(),
    'السبت'.tr(),
  ];

  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _time {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _date =>
      '${_weekdays[_now.weekday % 7]} ${_now.day} ${_months[_now.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _time,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: palette.textPrimary,
            fontSize: 14.5,
          ),
        ),
        Text(
          _date,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

/// أزرار سطح المكتب الموحّدة — مقاسات مضبوطة بدل ستايل الأزرار العام.
class DesktopButton {
  DesktopButton._();

  static Widget primary({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        final palette = DesktopPalette.of(context);
        final tint = color ?? palette.accent;
        return FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: tint,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
            ),
            textStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            minimumSize: const Size(0, 42),
          ),
          icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
          label: Text(label),
        );
      },
    );
  }

  static Widget ghost({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        final palette = DesktopPalette.of(context);
        final tint = color ?? palette.textSecondary;
        return OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: tint,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: BorderSide(color: palette.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            minimumSize: const Size(0, 42),
          ),
          icon: icon != null ? Icon(icon, size: 17) : const SizedBox.shrink(),
          label: Text(label),
        );
      },
    );
  }
}
