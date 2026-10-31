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
    this.navigatorKey,
  });

  final String placeName;
  final String? roleLabel;
  final List<DesktopNavGroup> groups;
  final String? activeId;
  final ValueChanged<DesktopNavItem>? onSelect;

  /// Optional key for the nested navigator that hosts every page opened from
  /// the sidebar. Sections pushed through this navigator stay inside the shell
  /// so the sidebar keeps rendering next to them.
  final GlobalKey<NavigatorState>? navigatorKey;

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
  late final GlobalKey<NavigatorState> _navigatorKey =
      widget.navigatorKey ?? GlobalKey<NavigatorState>();
  late final _ShellNavigatorObserver _navigatorObserver =
      _ShellNavigatorObserver(_syncWithNavigator);

  /// The sidebar destination that is currently highlighted. It follows the
  /// page opened from the sidebar and falls back to [DesktopShell.activeId]
  /// whenever the shell is back on the dashboard.
  late String? _activeId = widget.activeId;

  /// True while a page is open on top of the dashboard. The shell's own top
  /// bar is hidden then because pushed pages bring their own page header.
  bool _hasPage = false;

  @override
  void didUpdateWidget(covariant DesktopShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasPage && widget.activeId != oldWidget.activeId) {
      _activeId = widget.activeId;
    }
  }

  void _syncWithNavigator() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasPage = _navigatorKey.currentState?.canPop() ?? false;
      final resetActive = !hasPage && _activeId != widget.activeId;
      if (hasPage == _hasPage && !resetActive) return;
      setState(() {
        _hasPage = hasPage;
        if (!hasPage) _activeId = widget.activeId;
      });
    });
  }

  /// Sidebar selection behaves like a choice: the selected section replaces
  /// the previous one inside the shell, while its own sub-pages keep a normal
  /// back stack. Items without a page (sheets, dialogs, logout...) simply run
  /// their callback and leave the highlighted section untouched.
  void _selectNavItem(DesktopNavItem item) {
    final builder = item.pageBuilder;
    if (builder != null) {
      setState(() => _activeId = item.id);
      _navigatorKey.currentState
          ?.pushAndRemoveUntil(
            MaterialPageRoute(
              settings: RouteSettings(name: 'desktop-section:${item.id}'),
              builder: builder,
            ),
            (route) => route.isFirst,
          )
          .then((_) => item.onPageClosed?.call());
      return;
    }

    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    if (widget.onSelect != null) {
      widget.onSelect!(item);
      return;
    }

    // No page and no callback means "go back to the dashboard".
    if (_activeId != widget.activeId) {
      setState(() => _activeId = widget.activeId);
    }
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> _openCommandPalette() async {
    final selected = await DesktopCommandPalette.show(
      context,
      groups: widget.groups,
    );
    if (!mounted || selected == null) return;
    _selectNavItem(selected);
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
          body: Stack(
            fit: StackFit.expand,
            children: [
              Row(
                children: [
                  DesktopSidebar(
                    placeName: widget.placeName,
                    roleLabel: widget.roleLabel,
                    groups: widget.groups,
                    expanded: _expanded,
                    activeId: _activeId,
                    onSelect: _selectNavItem,
                    footer: widget.sidebarFooter,
                    userName: widget.userName,
                    userRole: widget.userRole,
                    onLogout: widget.onLogout,
                    onSettings: widget.onSettings,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (!_hasPage) _buildTopBar(context, palette),
                        Expanded(
                          child: _HomeScope(
                            home: _buildHome(),
                            child: Navigator(
                              key: _navigatorKey,
                              observers: [_navigatorObserver],
                              onGenerateRoute:
                                  (settings) => MaterialPageRoute(
                                    settings: settings,
                                    builder:
                                        (context) => Builder(
                                          builder:
                                              (context) =>
                                                  _HomeScope.of(context),
                                        ),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // The single rail control: a pull-tab tucked into the sidebar
              // edge (not floating fully outside it), expanding/shrinking the
              // rail and flipping its arrow to show the next direction.
              AnimatedPositionedDirectional(
                duration: DesktopTokens.medium,
                curve: Curves.easeOutCubic,
                top: 66,
                start:
                    (_expanded
                        ? DesktopTokens.sidebarWidth
                        : DesktopTokens.sidebarCollapsedWidth) -
                    _SidebarToggleTab.edgeInset,
                child: _SidebarToggleTab(
                  expanded: _expanded,
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Padding(padding: widget.padding, child: widget.child),
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

/// The single floating rail control: a pull-tab that grows out of the sidebar
/// edge, tucked under the brand mark. It expands and shrinks the rail; the
/// arrow flips 180° each time. The breathing halo is only active while the
/// rail is collapsed, inviting the user to pull it open, and calms down once
/// the rail is expanded.
class _SidebarToggleTab extends StatefulWidget {
  const _SidebarToggleTab({required this.expanded, required this.onTap});

  /// How many pixels of the tab sit inside the drawer.
  static const double edgeInset = 14;

  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_SidebarToggleTab> createState() => _SidebarToggleTabState();
}

class _SidebarToggleTabState extends State<_SidebarToggleTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  bool _hovering = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.expanded) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _SidebarToggleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == oldWidget.expanded) return;
    if (widget.expanded) {
      _pulse.stop();
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final outward = rtl ? -1.0 : 1.0;
    // Perfectly balanced squircle — the tab reads as one clean object instead
    // of a lopsided tag.
    const radius = BorderRadius.all(Radius.circular(12));

    final tab = AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      width: _hovering ? 46 : 40,
      height: _hovering ? 38 : 34,
      decoration: BoxDecoration(
        gradient:
            _hovering
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.accent,
                    Color.lerp(palette.accent, Colors.black, 0.28)!,
                  ],
                )
                : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.sidebarBg, palette.sidebarBgDeep],
                ),
        borderRadius: radius,
        border: Border.all(
          color:
              _hovering
                  ? Colors.white.withValues(alpha: 0.38)
                  : palette.accent.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            top: 0,
            start: 9,
            end: 9,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              height: 1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: _hovering ? 0.30 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          AnimatedSlide(
            offset: Offset(_hovering ? 0.10 * outward : 0, 0),
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            child: AnimatedRotation(
              turns: widget.expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedScale(
                scale: _hovering ? 1.06 : 1,
                duration: const Duration(milliseconds: 170),
                child: Icon(
                  rtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: _hovering ? 23 : 21,
                  color: _hovering ? Colors.white : palette.sidebarFg,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit:
          (_) => setState(() {
            _hovering = false;
            _pressed = false;
          }),
      child: Tooltip(
        message: widget.expanded ? 'طي القائمة'.tr() : 'فتح القائمة'.tr(),
        waitDuration: const Duration(milliseconds: 450),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                // Calm glow once the rail is expanded; the pulsing invitation
                // is only needed while the rail is collapsed.
                final t =
                    widget.expanded
                        ? 0.0
                        : Curves.easeInOut.transform(_pulse.value);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(
                          alpha: 0.16 + 0.20 * t,
                        ),
                        blurRadius: 14 + 12 * t,
                        spreadRadius: 1 + 1.6 * t,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: tab,
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the dashboard (the shell's home page) live when the parent state
/// rebuilds while a section is open. The home route is created once by the
/// nested [Navigator], so it reads the latest child from this scope instead of
/// capturing the widget instance that existed when the route was created.
class _HomeScope extends InheritedWidget {
  const _HomeScope({required this.home, required super.child});

  final Widget home;

  static Widget of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_HomeScope>();
    assert(scope != null, '_HomeScope is missing above the desktop navigator');
    return scope!.home;
  }

  @override
  bool updateShouldNotify(_HomeScope oldWidget) => true;
}

/// Repaints the shell chrome whenever the nested navigator's stack changes.
class _ShellNavigatorObserver extends NavigatorObserver {
  _ShellNavigatorObserver(this.onChanged);

  final VoidCallback onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onChanged();
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
