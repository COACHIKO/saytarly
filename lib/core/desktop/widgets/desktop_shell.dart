import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/desktop/widgets/desktop_controls.dart';
import 'package:saytarly/core/desktop/widgets/desktop_sidebar.dart';
import 'package:saytarly/core/localization/messages.dart';

/// الشل الرئيسي لواجهة الويندوز.
///
/// بيعرض: سايد بار غامق (يمين في RTL) + شريط علوي فيه العنوان والأدوات
/// والساعة + منطقة المحتوى. لوحات التحكم (أدمن / كاشير / سوبر ادمن) كلها
/// بتستخدم الشل ده عشان تجربة سطح مكتب واحدة متسقة.
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

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final bool initialExpanded;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  late bool _expanded = widget.initialExpanded;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Scaffold(
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
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          Expanded(
            child: Column(
              children: [
                // ==================== الشريط العلوي ====================
                Container(
                  height: DesktopTokens.topBarHeight,
                  padding:  EdgeInsets.symmetric(
                    horizontal: DesktopTokens.pagePadding,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border(
                      bottom: BorderSide(color: palette.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      // ==================== زر الرجوع التلقائي ====================
                      // بيظهر بس لو فيه شاشة متدخلة فوق دي (زي لوحة الأدمن
                      // اللي بتتفتح من السوبر ادمن) — الجذر ما يبانش فيها.
                      if (Navigator.of(context).canPop()) ...[
                        DesktopToolbarIconButton(
                          icon: Directionality.of(context) ==
                                  TextDirection.rtl
                              ? Icons.arrow_forward_ios
                              : Icons.arrow_back_ios,
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
                                fontWeight: FontWeight.w900,
                                color: palette.textPrimary,
                                fontSize: 16.5,
                              ),
                            ),
                            if (widget.subtitle != null)
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
                      const SizedBox(width: DesktopTokens.gapMd),
                      for (final action in widget.actions) ...[
                        action,
                        const SizedBox(width: DesktopTokens.gapXs),
                      ],
                      if (widget.actions.isNotEmpty)
                        Container(
                          width: 1,
                          height: 26,
                          margin: const EdgeInsets.symmetric(
                            horizontal: DesktopTokens.gapSm,
                          ),
                          color: palette.border,
                        ),
                      const DesktopClock(),
                    ],
                  ),
                ),

                // ==================== منطقة المحتوى ====================
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: widget.maxWidth),
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
    );
  }
}
