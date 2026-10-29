import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';

/// كارت سطح المكتب — الـ building block الأساسي لكل الصفحات.
///
/// يدعم: هوفر ناعم (رفع + حدود أوضح)، اختيار (selected)، وظل خفيف.
class DesktopCard extends StatefulWidget {
  const DesktopCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesktopTokens.gapMd),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.radius = DesktopTokens.radiusLg,
    this.hover = false,
    this.selected = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// يفعّل تفاعل الهوفر (رفع + حدود أقوى).
  final bool hover;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<DesktopCard> createState() => _DesktopCardState();
}

class _DesktopCardState extends State<DesktopCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final interactive = widget.onTap != null && widget.hover;
    final lifted = interactive && _hovering;

    final borderColor = widget.borderColor ??
        (lifted
            ? palette.borderStrong
            : widget.selected
                ? palette.accent.withValues(alpha: 0.55)
                : palette.border);

    final Widget card = AnimatedContainer(
      duration: DesktopTokens.fast,
      curve: Curves.easeOut,
      margin: widget.margin,
      padding: widget.padding,
      transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.color ??
            (widget.selected ? palette.accentSoft : palette.surface),
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: lifted ? 0.9 : 0.45),
            blurRadius: lifted ? 24 : 14,
            offset: Offset(0, lifted ? 10 : 6),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}

/// شريط عنوان قسم صغير — [مربط ألوان] + عنوان + عدّاد اختياري + عنصر إجراء.
class DesktopSectionTitle extends StatelessWidget {
  const DesktopSectionTitle({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: DesktopTokens.gapMd),
  });

  final String title;
  final int? count;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 16,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: DesktopTokens.gapSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// أيقونة داخل مربع ملوّن مائل — تُستخدم في الكروت والتايلز والـ stats.
class DesktopIconBadge extends StatelessWidget {
  const DesktopIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 42,
    this.radius = DesktopTokens.radiusSm,
    this.background,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double radius;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final tint = color ?? palette.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? tint.withValues(alpha: palette.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: tint, size: size * 0.48),
    );
  }
}

/// تايل إجراء عريض — أيقونة + عنوان + وصف + سهم — للاستخدام في الشبكات
/// الرئيسية في لوحات التحكم. يدعم الهوفر بشكل كامل.
class DesktopActionTile extends StatelessWidget {
  const DesktopActionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
    this.compact = false,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool compact;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final tint = color ?? palette.accent;

    return DesktopCard(
      hover: true,
      onTap: onTap,
      padding: EdgeInsets.all(compact ? DesktopTokens.gapMd : DesktopTokens.gapMd + 2),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: icon,
            color: tint,
            size: compact ? 40 : 46,
            radius: DesktopTokens.radiusMd,
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: compact ? 13.5 : 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: DesktopTokens.gapSm),
            badge!,
          ],
          const SizedBox(width: DesktopTokens.gapXs),
          Icon(
            Icons.chevron_left,
            size: 18,
            color: palette.textMuted.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
