part of '../admin.dart';

/// Admin dashboard — Windows body.
///
/// Premium SaaS composition: live KPIs, sales performance, daily summary,
/// recent orders, stock alerts, quick access, and the searchable module
/// directory. All figures come from the same local SQLite database as before.
extension _AdminWindowsBody on _AdminDashboardState {
  Future<void> _logoutToLogin() => LogoutHelper.confirmAndLogout(context);

  void _pushPage(Widget page) {
    final pageRoute = MaterialPageRoute<void>(builder: (_) => page);
    final shellNavigator = _shellNavKey.currentState;
    if (shellNavigator != null) {
      shellNavigator.push(pageRoute);
    } else {
      Navigator.push(context, pageRoute);
    }
  }

  void _openReports() => _pushPage(ReportsScreen());

  void _openInventory() => _pushPage(const ManageMaterialsScreen());

  void _openSettings() => _pushPage(const SettingsScreen());

  Map<String, List<Map<String, dynamic>>> _groupedActions({
    bool filtered = false,
  }) {
    final query = _searchQuery.trim();
    final result = <String, List<Map<String, dynamic>>>{};

    for (final action in _actions) {
      if (filtered &&
          query.isNotEmpty &&
          !(action['title'] as String).toLowerCase().contains(
            query.toLowerCase(),
          )) {
        continue;
      }
      final group = action['group'] as String? ?? 'عام'.tr();
      result.putIfAbsent(group, () => []).add(action);
    }
    return result;
  }

  List<DesktopNavGroup> _windowsNavGroups() {
    final grouped = _groupedActions();

    return [
      DesktopNavGroup(
        title: 'نظرة عامة'.tr(),
        items: [
          DesktopNavItem(
            id: 'admin-home',
            label: 'لوحة التحكم'.tr(),
            icon: Icons.space_dashboard_outlined,
          ),
        ],
      ),
      for (final entry in grouped.entries)
        DesktopNavGroup(
          title: entry.key.tr(),
          items: [
            for (final action in entry.value)
              DesktopNavItem(
                id: action['id'] as String,
                label: (action['title'] as String).tr(),
                icon: action['icon'] as IconData,
                badge:
                    (action['id'] as String) == 'materials_low'
                        ? _dashboardStats.lowStockCount
                        : null,
                badgeColor: SaytarlyColors.warning,
                onTap: action['onTap'] as VoidCallback,
                pageBuilder: action['page'] as WidgetBuilder?,
              ),
          ],
        ),
    ];
  }

  List<DashboardQuickAction> _dashboardQuickActions() {
    final palette = DesktopPalette.of(context);
    return [
      DashboardQuickAction(
        label: 'التقارير'.tr(),
        subtitle: 'مبيعات، أرباح وتقارير تشغيلية'.tr(),
        icon: Icons.bar_chart_rounded,
        color: palette.accent,
        onTap: _openReports,
      ),
      DashboardQuickAction(
        label: 'إدارة المخزون'.tr(),
        subtitle: 'الخامات، الحدود والحركات'.tr(),
        icon: Icons.inventory_2_outlined,
        color: palette.warning,
        onTap: _openInventory,
      ),
      DashboardQuickAction(
        label: 'إضافة مصروف'.tr(),
        subtitle: 'تسجيل مصروف تشغيلي جديد'.tr(),
        icon: Icons.receipt_long_outlined,
        color: palette.info,
        onTap: () => _pushPage(AdminExpensesScreen()),
      ),
      DashboardQuickAction(
        label: 'تقرير المنتجات'.tr(),
        subtitle: 'الأكثر مبيعًا وأداء الأصناف'.tr(),
        icon: Icons.shopping_bag_outlined,
        color: palette.profit,
        onTap: () => _pushPage(const ProductsReportScreen()),
      ),
      DashboardQuickAction(
        label: 'رواتب الموظفين'.tr(),
        subtitle: 'المستحقات والرواتب المعلقة'.tr(),
        icon: Icons.account_balance_wallet_outlined,
        color: palette.profit,
        onTap: () => _pushPage(PendingSalariesScreen()),
      ),
      DashboardQuickAction(
        label: 'إدارة المستخدمين'.tr(),
        subtitle: 'الصلاحيات وحسابات الفريق'.tr(),
        icon: Icons.people_alt_outlined,
        color: palette.info,
        onTap: () => _pushPage(ManageUsersScreen()),
      ),
    ];
  }

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return DesktopShell(
      placeName: _placeName,
      roleLabel: 'مدير النظام'.tr(),
      groups: _windowsNavGroups(),
      activeId: 'admin-home',
      navigatorKey: _shellNavKey,
      userName: CurrentUser.displayName,
      userRole: 'مدير النظام'.tr(),
      onSettings: _openSettings,
      onLogout: _logoutToLogin,
      title: 'لوحة التحكم'.tr(),
      subtitle: 'نظرة شاملة على أداء {v1}'.tr({'v1': _placeName}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'تحديث البيانات'.tr(),
          onPressed: _loadStats,
        ),
        const DesktopThemeToggle(),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardOverview(
              stats: _dashboardStats,
              range: _dashboardRange,
              onRangeChanged: _setDashboardRange,
              quickActions: _dashboardQuickActions(),
              onViewOrders: _openReports,
              onManageStock: _openInventory,
              onOpenReports: _openReports,
            ),
            const SizedBox(height: DesktopTokens.gapXl + 6),
            DesktopSectionTitle(
              title: 'كل الأدوات'.tr(),
              subtitle: 'كل شاشات وإجراءات النظام في مكان واحد'.tr(),
              count: _groupedActions(
                filtered: true,
              ).values.fold<int>(0, (sum, list) => sum + list.length),
              trailing: DesktopSearchField(
                hint: 'ابحث عن أداة...'.tr(),
                onChanged: _setSearchQuery,
              ),
            ),
            const SizedBox(height: DesktopTokens.gapXs),
            ..._windowsActionSections(context),
            const SizedBox(height: DesktopTokens.gapLg),
            _buildDangerFooter(context, palette, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _windowsActionSections(BuildContext context) {
    final grouped = _groupedActions(filtered: true);

    if (grouped.isEmpty) {
      return [
        DesktopEmptyState(
          icon: Icons.search_off_rounded,
          title: 'مفيش نتائج'.tr(),
          message: 'جرّب كلمة بحث تانية — أو امسح البحث.'.tr(),
        ),
      ];
    }

    return [
      for (final entry in grouped.entries) ...[
        DesktopSectionTitle(title: entry.key.tr(), count: entry.value.length),
        DesktopResponsiveGrid(
          minTileWidth: 270,
          maxColumns: 4,
          children: [
            for (final action in entry.value)
              DesktopActionTile(
                title: (action['title'] as String).tr(),
                icon: action['icon'] as IconData,
                color: action['color'] as Color,
                onTap: () {
                  final page = action['page'] as WidgetBuilder?;
                  if (page != null) {
                    _pushPage(page(context));
                  } else {
                    (action['onTap'] as VoidCallback?)?.call();
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: DesktopTokens.gapLg + 4),
      ],
    ];
  }

  Widget _buildDangerFooter(
    BuildContext context,
    DesktopPalette palette,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
            border: Border.all(color: palette.danger.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: palette.danger.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'منطقة حساسة'.tr(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'مسح البيانات نهائي — بيتأكد قبل التنفيذ.'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _clearAllData,
                style: TextButton.styleFrom(
                  foregroundColor: palette.danger,
                  backgroundColor: palette.soft(palette.danger),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text('مسح كل البيانات'.tr()),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesktopTokens.gapMd),
        Text(
          'SAYTARLY • Restaurant & Café Management',
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textMuted.withValues(alpha: 0.7),
            fontSize: 9.5,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
