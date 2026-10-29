import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/desktop/widgets/brand_logo.dart';
import 'package:saytarly/core/localization/messages.dart';

/// عنصر واحد في قائمة السايد بار.
class DesktopNavItem {
  const DesktopNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;

  /// لو موجود بيتنفّذ بدل onSelect بتاع الشل.
  final VoidCallback? onTap;
}

/// مجموعة عناصر في السايد بار (مع عنوان اختياري).
class DesktopNavGroup {
  const DesktopNavGroup({this.title, required this.items});

  final String? title;
  final List<DesktopNavItem> items;
}

/// السايد بار الغامق لواجهة سطح المكتب.
///
/// - قابل للطي (expanded/collapsed) مع أنيميشن ناعم.
/// - عناصر بهوفر ومؤشر اختيار سفلي واضح.
/// - في الوضع المطوي تظهر الأيقونات فقط مع Tooltip.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.placeName,
    required this.groups,
    required this.expanded,
    required this.onToggle,
    this.roleLabel,
    this.activeId,
    this.onSelect,
    this.footer,
  });

  final String placeName;
  final String? roleLabel;
  final List<DesktopNavGroup> groups;
  final bool expanded;
  final VoidCallback onToggle;
  final String? activeId;
  final ValueChanged<DesktopNavItem>? onSelect;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return AnimatedContainer(
      duration: DesktopTokens.medium,
      curve: Curves.easeOutCubic,
      width: expanded
          ? DesktopTokens.sidebarWidth
          : DesktopTokens.sidebarCollapsedWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.sidebarBg, palette.sidebarBgDeep],
        ),
        border: BorderDirectional(
          end: BorderSide(color: palette.sidebarBorder),
        ),
      ),
      child: Column(
        children: [
          _buildBrand(context, palette),
          Container(height: 1, color: palette.sidebarBorder),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: DesktopTokens.gapSm,
                vertical: DesktopTokens.gapMd,
              ),
              children: [
                for (final group in groups) ...[
                  if (group.title != null && expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                      child: Text(
                        group.title!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: palette.sidebarMuted.withValues(alpha: 0.75),
                        ),
                      ),
                    )
                  else if (group.title != null && !expanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: palette.sidebarBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  for (final item in group.items)
                    _SidebarNavItem(
                      item: item,
                      expanded: expanded,
                      active: item.id == activeId,
                      onTap: item.onTap ?? (onSelect == null ? null : () => onSelect!(item)),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null) ...[
            Container(height: 1, color: palette.sidebarBorder),
            Padding(
              padding: const EdgeInsets.all(DesktopTokens.gapSm + 2),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesktopTokens.gapSm + 2),
        child: expanded
            ? Row(
                children: [
                  _logo(palette),
                  const SizedBox(width: DesktopTokens.gapSm + 2),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: palette.sidebarFg,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        if (roleLabel != null)
                          Text(
                            roleLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.sidebarMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _toggleButton(palette, expanded: true),
                ],
              )
            : Column(
                children: [
                  _toggleButton(palette, expanded: false),
                ],
              ),
      ),
    );
  }

  Widget _logo(DesktopPalette palette) {
    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.sidebarHover,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
        border: Border.all(color: palette.sidebarBorder),
      ),
      child: BrandLogo(
        errorChild: Icon(
          Icons.local_cafe_rounded,
          size: 20,
          color: palette.sidebarFg,
        ),
      ),
    );
  }

  Widget _toggleButton(DesktopPalette palette, {required bool expanded}) {
    return Tooltip(
      message: expanded ? 'طي القائمة'.tr() : 'فتح القائمة',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.sidebarHover,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
              border: Border.all(color: palette.sidebarBorder),
            ),
            child: Icon(
              expanded ? Icons.chevron_right : Icons.menu_rounded,
              size: 19,
              color: palette.sidebarMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    required this.item,
    required this.expanded,
    required this.active,
    this.onTap,
  });

  final DesktopNavItem item;
  final bool expanded;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    final Color bg = widget.active
        ? palette.sidebarActiveBg
        : _hovering
            ? palette.sidebarHover
            : Colors.transparent;

    final Color fg = widget.active
        ? palette.sidebarFg
        : _hovering
            ? palette.sidebarFg
            : palette.sidebarMuted;

    final Color iconColor = widget.active
        ? (palette.isDark ? palette.sidebarFg : palette.accentText)
        : fg;

    final content = widget.expanded
        ? AnimatedContainer(
            duration: DesktopTokens.fast,
            height: 42,
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
              border: Border.all(
                color: widget.active
                    ? palette.accent.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(widget.item.icon, size: 19, color: iconColor),
                const SizedBox(width: DesktopTokens.gapSm + 2),
                Expanded(
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight:
                          widget.active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (widget.active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          )
        : AnimatedContainer(
            duration: DesktopTokens.fast,
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
              border: Border.all(
                color: widget.active
                    ? palette.accent.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Icon(widget.item.icon, size: 21, color: iconColor),
          );

    final wrapped = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Align(
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    return widget.expanded
        ? wrapped
        : Tooltip(
            message: widget.item.label,
            waitDuration: const Duration(milliseconds: 400),
            child: wrapped,
          );
  }
}
