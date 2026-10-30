import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';

/// The primary surface used by desktop pages.
///
/// Defaults to a white card with a hairline border and an almost invisible
/// shadow. Separation comes from borders first, elevation second.
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
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// Enables hover elevation + a stronger border.
  final bool hover;
  final bool selected;
  final VoidCallback? onTap;

  /// Set false for dense surfaces (tables, nested panels).
  final bool shadow;

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

    final borderColor =
        widget.borderColor ??
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
        color:
            widget.color ??
            (widget.selected ? palette.accentSoft : palette.surface),
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: borderColor),
        boxShadow:
            !widget.shadow
                ? null
                : [
                  BoxShadow(
                    color: palette.shadow.withValues(
                      alpha:
                          palette.isDark
                              ? (lifted ? 0.55 : 0.30)
                              : (lifted ? 0.10 : 0.045),
                    ),
                    blurRadius: lifted ? 28 : 16,
                    offset: Offset(0, lifted ? 14 : 7),
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

/// Section title used above grids and lists.
class DesktopSectionTitle extends StatelessWidget {
  const DesktopSectionTitle({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.subtitle,
    this.padding = const EdgeInsets.only(bottom: DesktopTokens.gapMd),
  });

  final String title;
  final String? subtitle;
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          fontSize: 16.5,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: DesktopTokens.gapSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: palette.accent.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.accentText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: DesktopTokens.gapMd),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Icon inside a soft tinted square.
class DesktopIconBadge extends StatelessWidget {
  const DesktopIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 42,
    this.radius = DesktopTokens.radiusMd,
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
        color: background ?? palette.soft(tint),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: palette.onSoft(tint), size: size * 0.46),
    );
  }
}

/// Wide action tile used in dashboard quick-access grids.
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
      padding: EdgeInsets.all(
        compact ? DesktopTokens.gapMd : DesktopTokens.gapMd + 2,
      ),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: icon,
            color: tint,
            size: compact ? 40 : 44,
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
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    fontSize: compact ? 13.5 : 14.5,
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
                      fontSize: compact ? 11 : 11.8,
                      height: 1.4,
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
            Icons.chevron_left_rounded,
            size: 18,
            color: palette.textMuted.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}
