import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/desktop/widgets/desktop_card.dart';

/// A titled desktop surface: compact header, hairline divider, content.
///
/// This is the standard container for dashboard panels, report summaries and
/// settings groups. Keeping the header pattern here avoids each screen
/// re-inventing its own panel chrome.
class DesktopPanel extends StatelessWidget {
  const DesktopPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.headerLeading,
    this.headerPadding = const EdgeInsets.fromLTRB(20, 18, 20, 16),
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
    this.showDivider = true,
    this.padding = EdgeInsets.zero,
    this.radius = DesktopTokens.radiusLg,
    this.hover = false,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget? headerLeading;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry bodyPadding;
  final bool showDivider;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool hover;
  final VoidCallback? onTap;

  bool get _hasHeader =>
      title != null || headerLeading != null || trailing != null;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return DesktopCard(
      padding: padding,
      radius: radius,
      hover: hover,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasHeader)
            Padding(
              padding: headerPadding,
              child: Row(
                children: [
                  if (headerLeading != null) ...[
                    headerLeading!,
                    const SizedBox(width: DesktopTokens.gapMd),
                  ] else if (icon != null) ...[
                    DesktopIconBadge(
                      icon: icon!,
                      color: iconColor,
                      size: 38,
                      radius: 11,
                    ),
                    const SizedBox(width: DesktopTokens.gapMd),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: palette.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
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
            ),
          if (_hasHeader && showDivider)
            Divider(height: 1, thickness: 1, color: palette.border),
          Padding(padding: bodyPadding, child: child),
        ],
      ),
    );
  }
}
