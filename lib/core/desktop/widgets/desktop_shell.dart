import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/desktop/widgets/desktop_command_palette.dart';
import 'package:saytarly/core/desktop/widgets/desktop_controls.dart';
import 'package:saytarly/core/desktop/widgets/desktop_sidebar.dart';
import 'package:saytarly/core/localization/messages.dart';

/// Primary desktop shell.
///
/// Deep-navy navigation rail (right side in RTL), a clean white toolbar with a
/// command palette, and a maximum-width content stage. All dashboard roles
/// share this shell so the product feels like one system.
class DesktopShell extends StatefulWidget {
  const DesktopShell({
    super.key,
    required this.placeName,
    required this.groups,
    required this.title,
    required this.child,
    this.roleLabel,
    this.activeId,
    this.onSelect,
    this.subtitle,
    this.actions = const [],
    this.sidebarFooter,
    this.userName,
    this.userRole,
    this.onLogout,
    this.onSettings,
    this.showSearch = true,
    this.padding = const EdgeInsets.all(DesktopTokens.pagePadding),
    this.maxWidth = DesktopTokens.contentMaxWidth,
    this.initialExpanded = true,
  });

  final String placeName;
  final String? roleLabel;
  final List<DesktopNavGroup> groups;
  final String? activeId;
  final ValueChanged<DesktopNavItem>? onSelect;

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? sidebarFooter;
  final String? userName;
  final String? userRole;
  final VoidCallback? onLogout;
  final VoidCallback? onSettings;
  final bool showSearch;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final bool initialExpanded;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  late bool _expanded = widget.initialExpanded;

  Future<void> _openCommandPalette() async {
    final selected = await DesktopCommandPalette.show(
      context,
      groups: widget.groups,
    );
    if (!mounted || selected == null) return;
    if (selected.onTap != null) {
      selected.onTap!();
    } else {
      widget.onSelect?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: palette.background,
          body: Row(
            children: [
              DesktopSidebar(
                placeName: widget.placeName,
                roleLabel: widget.roleLabel,
                groups: widget.groups,
                expanded: _expanded,
                activeId: widget.activeId,
                onSelect: widget.onSelect,
                footer: widget.sidebarFooter,
                userName: widget.userName,
                userRole: widget.userRole,
                onLogout: widget.onLogout,
                onSettings: widget.onSettings,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context, palette),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: widget.maxWidth,
                          ),
                          child: Padding(
                            padding: widget.padding,
                            child: widget.child,
                          ),
                        ),
                      ),
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

  Widget _buildTopBar(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = widget.showSearch && width >= 1160;
    final compactTitle = width < 960;

    return Container(
      height: DesktopTokens.topBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.pagePadding,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            DesktopToolbarIconButton(
              icon:
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
              tooltip: 'رجوع'.tr(),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 16.5,
                  ),
                ),
                if (widget.subtitle != null && !compactTitle)
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          if (showSearch) ...[
            const SizedBox(width: DesktopTokens.gapLg),
            _CommandSearchButton(
              label: 'ابحث في SAYTARLY...'.tr(),
              onTap: _openCommandPalette,
            ),
          ],
          const SizedBox(width: DesktopTokens.gapMd),
          for (final action in widget.actions) ...[
            action,
            const SizedBox(width: 2),
          ],
          if (widget.actions.isNotEmpty)
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(
                horizontal: DesktopTokens.gapSm,
              ),
              color: palette.border,
            ),
          if (widget.userName != null)
            _TopBarUserMenu(
              name: widget.userName!,
              role: widget.userRole ?? widget.roleLabel,
              onLogout: widget.onLogout,
              onSettings: widget.onSettings,
            )
          else if (widget.onLogout != null)
            DesktopToolbarIconButton(
              icon: Icons.logout_rounded,
              tooltip: 'تسجيل الخروج'.tr(),
              onPressed: widget.onLogout,
            ),
        ],
      ),
    );
  }
}

class _CommandSearchButton extends StatefulWidget {
  const _CommandSearchButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_CommandSearchButton> createState() => _CommandSearchButtonState();
}

class _CommandSearchButtonState extends State<_CommandSearchButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          width: 258,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: _hover ? palette.surfaceSoft : palette.surfaceSoft,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm + 2),
            border: Border.all(
              color: _hover ? palette.borderStrong : palette.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 17,
                color: _hover ? palette.textSecondary : palette.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  'Ctrl K',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarUserMenu extends StatelessWidget {
  const _TopBarUserMenu({
    required this.name,
    this.role,
    this.onLogout,
    this.onSettings,
  });

  final String name;
  final String? role;
  final VoidCallback? onLogout;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final initials = _initials(name);
    final hasMenu = onLogout != null || onSettings != null;

    final avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
        color: palette.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E8BFF), Color(0xFF0F65D8)],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          if (hasMenu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: palette.textMuted,
              ),
            )
          else
            const SizedBox(width: 7),
        ],
      ),
    );

    if (!hasMenu) {
      return Tooltip(message: name, child: avatar);
    }

    return PopupMenuButton<_UserMenuAction>(
      tooltip: name,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.border),
      ),
      onSelected: (action) {
        switch (action) {
          case _UserMenuAction.settings:
            onSettings?.call();
            break;
          case _UserMenuAction.logout:
            onLogout?.call();
            break;
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem<_UserMenuAction>(
              enabled: false,
              height: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (role != null && role!.isNotEmpty)
                    Text(
                      role!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            if (onSettings != null)
              PopupMenuItem<_UserMenuAction>(
                value: _UserMenuAction.settings,
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 17,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text('الإعدادات'.tr()),
                  ],
                ),
              ),
            if (onLogout != null)
              PopupMenuItem<_UserMenuAction>(
                value: _UserMenuAction.logout,
                height: 40,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 17, color: palette.danger),
                    const SizedBox(width: 10),
                    Text(
                      'تسجيل الخروج'.tr(),
                      style: TextStyle(color: palette.danger),
                    ),
                  ],
                ),
              ),
          ],
      child: avatar,
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

enum _UserMenuAction { settings, logout }
