import 'package:flutter/material.dart';
import 'package:saytarly/core/design/widgets/saytarly_brand_mark.dart';
import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/localization/messages.dart';

/// One sidebar destination.
class DesktopNavItem {
  const DesktopNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.onTap,
    this.badge,
    this.badgeColor,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Executed instead of the shell's `onSelect` callback when provided.
  final VoidCallback? onTap;

  /// Optional count shown at the end of the row (e.g. low-stock alerts).
  final int? badge;
  final Color? badgeColor;
}

/// A labelled group of sidebar destinations.
class DesktopNavGroup {
  const DesktopNavGroup({this.title, required this.items});

  final String? title;
  final List<DesktopNavItem> items;
}

/// Deep-navy desktop navigation rail.
///
/// - SAYTARLY brand lockup at the top;
/// - active workspace / branch card;
/// - grouped destinations with a clear electric-blue active rail;
/// - live alert badges;
/// - the signed-in user anchored at the bottom.
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
    this.userName,
    this.userRole,
    this.onLogout,
    this.onSettings,
  });

  final String placeName;
  final String? roleLabel;
  final List<DesktopNavGroup> groups;
  final bool expanded;
  final VoidCallback onToggle;
  final String? activeId;
  final ValueChanged<DesktopNavItem>? onSelect;
  final Widget? footer;
  final String? userName;
  final String? userRole;
  final VoidCallback? onLogout;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return AnimatedContainer(
      duration: DesktopTokens.medium,
      curve: Curves.easeOutCubic,
      width:
          expanded
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
          _buildWorkspace(context, palette),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              children: [
                for (final group in groups) ...[
                  if (group.title != null && expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 7),
                      child: Text(
                        group.title!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: palette.sidebarMuted.withValues(alpha: 0.68),
                        ),
                      ),
                    )
                  else if (group.title != null && !expanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 1,
                          color: palette.sidebarBorder,
                        ),
                      ),
                    ),
                  for (final item in group.items)
                    _SidebarNavItem(
                      item: item,
                      expanded: expanded,
                      active: item.id == activeId,
                      onTap:
                          item.onTap ??
                          (onSelect == null ? null : () => onSelect!(item)),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null) ...[
            Container(height: 1, color: palette.sidebarBorder),
            Padding(
              padding: const EdgeInsets.all(DesktopTokens.gapSm),
              child: footer!,
            ),
          ],
          if (userName != null) ...[
            Container(height: 1, color: palette.sidebarBorder),
            _buildUserCard(context, palette),
          ],
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context, DesktopPalette palette) {
    return SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child:
            expanded
                ? Row(
                  children: [
                    const SaytarlyLogo(markSize: 36, onDark: true),
                    const Spacer(),
                    _toggleButton(context, palette, expanded: true),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SaytarlyBrandMark(size: 36),
                    const SizedBox(height: 6),
                    _toggleButton(context, palette, expanded: false),
                  ],
                ),
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);

    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Tooltip(
          message: '$placeName${roleLabel != null ? ' • $roleLabel' : ''}',
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
              border: Border.all(color: palette.sidebarBorder),
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 20,
              color: palette.sidebarFg,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          border: Border.all(color: palette.sidebarBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 17,
                color: palette.sidebarFg,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.sidebarFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.8,
                    ),
                  ),
                  if (roleLabel != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      roleLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.sidebarMuted,
                        fontSize: 10.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);
    final name = userName ?? '';
    final role = userRole ?? roleLabel ?? '';
    final initials = _initials(name);

    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Tooltip(
          message: role.isEmpty ? name : '$name\n$role',
          child: _Avatar(initials: initials, palette: palette, size: 38),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 9, 8, 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          border: Border.all(color: palette.sidebarBorder),
        ),
        child: Row(
          children: [
            _Avatar(initials: initials, palette: palette, size: 34),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.sidebarFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.4,
                    ),
                  ),
                  if (role.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.sidebarMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onLogout != null)
              Tooltip(
                message: 'تسجيل الخروج'.tr(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onLogout,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 15,
                        color: palette.sidebarMuted,
                      ),
                    ),
                  ),
                ),
              )
            else if (onSettings != null)
              Tooltip(
                message: 'الإعدادات'.tr(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onSettings,
                    child: Icon(
                      Icons.settings_outlined,
                      size: 16,
                      color: palette.sidebarMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(
    BuildContext context,
    DesktopPalette palette, {
    required bool expanded,
  }) {
    return Tooltip(
      message: expanded ? 'طي القائمة'.tr() : 'فتح القائمة'.tr(),
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: palette.sidebarBorder),
            ),
            child: Icon(
              expanded
                  ? (Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded)
                  : Icons.menu_rounded,
              size: 18,
              color: palette.sidebarMuted,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
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
    final active = widget.active;
    final bg =
        active
            ? palette.sidebarActiveBg
            : _hovering
            ? palette.sidebarHover
            : Colors.transparent;
    final fg = active || _hovering ? palette.sidebarFg : palette.sidebarMuted;
    final iconColor = active ? Colors.white : fg;

    final content =
        widget.expanded
            ? AnimatedContainer(
              duration: DesktopTokens.fast,
              height: 43,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
                border: Border.all(
                  color:
                      active
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.transparent,
                ),
              ),
              child: Stack(
                children: [
                  if (active)
                    PositionedDirectional(
                      start: 0,
                      top: 9,
                      bottom: 9,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(13, 0, 10, 0),
                    child: Row(
                      children: [
                        Icon(widget.item.icon, size: 19, color: iconColor),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            widget.item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: fg,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13.2,
                            ),
                          ),
                        ),
                        if (widget.item.badge != null &&
                            widget.item.badge! > 0) ...[
                          const SizedBox(width: 6),
                          _Badge(
                            count: widget.item.badge!,
                            color: widget.item.badgeColor ?? palette.accent,
                          ),
                        ] else if (active) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: palette.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
            : AnimatedContainer(
              duration: DesktopTokens.fast,
              width: 48,
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
                border: Border.all(
                  color:
                      active
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.transparent,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(widget.item.icon, size: 21, color: iconColor),
                  if (widget.item.badge != null && widget.item.badge! > 0)
                    Positioned(
                      top: 8,
                      right: 9,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.item.badgeColor ?? palette.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.sidebarBg,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );

    final wrapped = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: content,
      ),
    );

    return widget.expanded
        ? wrapped
        : Tooltip(
          message: widget.item.label,
          waitDuration: const Duration(milliseconds: 350),
          child: wrapped,
        );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          height: 1,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.none,
          fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.palette,
    required this.size,
  });

  final String initials;
  final DesktopPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E8BFF), Color(0xFF0F65D8)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
