part of '../super_admin_dashboard.dart';

/// جسم لوحة السوبر ادمن — نسخة الويندوز (Windows UI).
///
/// مركز تحكم كامل: مؤشرات النظام (أقسام / منتجات / حالة التهيئة) + كل
/// أدوات التخصيص في سايد بار وشبكة تايلز.
extension _SuperAdminWindowsBody on _SuperAdminDashboardState {
  /// 🚪 تسجيل خروج لتغيير الدور — شغل التهيئة الإداري مش محتاج لازم
  /// يفضل علطول؛ الدور بيتسمى تاني من شاشة اللوجين.
  Future<void> _logoutToLogin() => LogoutHelper.confirmAndLogout(context);

  Map<String, List<Map<String, dynamic>>> _groupedActions() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final action in _actions) {
      final group = action['group'] as String? ?? 'عام'.tr();
      grouped.putIfAbsent(group, () => []).add(action);
    }
    return grouped;
  }

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return DesktopShell(
      placeName: _placeName,
      roleLabel: 'السوبر ادمن'.tr(),
      userName: CurrentUser.displayName,
      userRole: 'السوبر ادمن'.tr(),
      onLogout: _logoutToLogin,
      groups: [
        DesktopNavGroup(
          title: 'نظرة عامة'.tr(),
          items: [
            DesktopNavItem(
              id: 'super-home',
              label: 'لوحة التحكم'.tr(),
              icon: Icons.space_dashboard_outlined,
            ),
          ],
        ),
        for (final entry in _groupedActions().entries)
          DesktopNavGroup(
            title: entry.key.tr(),
            items: [
              for (final action in entry.value)
                DesktopNavItem(
                  id: action['title'] as String,
                  label: (action['title'] as String).tr(),
                  icon: action['icon'] as IconData,
                  onTap: action['onTap'] as VoidCallback,
                  pageBuilder: action['page'] as WidgetBuilder?,
                  onPageClosed: _load,
                ),
            ],
          ),
      ],
      activeId: 'super-home',
      navigatorKey: _shellNavKey,
      title: 'لوحة السوبر ادمن'.tr(),
      subtitle: '$_placeName • $_typeLabel',
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.rocket_launch_outlined,
          tooltip: 'معالج التهيئة'.tr(),
          onPressed: () => _push(SetupWizardScreen(fromDashboard: true)),
        ),
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث البيانات'.tr(),
          onPressed: _load,
        ),
        DesktopThemeToggle(),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== مؤشرات النظام ====================
            DesktopResponsiveGrid(
              minTileWidth: 240,
              children: [
                DesktopStatCard(
                  label: 'أقسام المنتجات'.tr(),
                  value: '$_modulesCount',
                  icon: Icons.category_outlined,
                  color: palette.accent,
                  hint: 'كل قسم له إدارة وتقارير خاصة'.tr(),
                ),
                DesktopStatCard(
                  label: 'إجمالي المنتجات'.tr(),
                  value: '$_productsCount',
                  icon: Icons.local_cafe_outlined,
                  color: palette.info,
                  hint: 'عبر كل الأقسام'.tr(),
                ),
                DesktopStatCard(
                  label: 'حالة التهيئة'.tr(),
                  value: _setupCompleted ? 'مكتملة'.tr() : 'ناقصة'.tr(),
                  icon:
                      _setupCompleted
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                  color: _setupCompleted ? palette.success : palette.warning,
                  hint:
                      _setupCompleted
                          ? 'كل خطوات التهيئة خلصت'.tr()
                          : 'لسه فيه خطوات محتاجة تكمل'.tr(),
                  onTap:
                      () => _push(const SetupWizardScreen(fromDashboard: true)),
                ),
                DesktopStatCard(
                  label: 'نوع النشاط'.tr(),
                  value: _typeLabel.isEmpty ? '—' : _typeLabel,
                  icon: Icons.storefront_outlined,
                  color: palette.warning,
                  hint: _placeName,
                  onTap: () => _push(const BusinessProfileScreen()),
                ),
              ],
            ),
            const SizedBox(height: DesktopTokens.gapLg + 4),

            // ==================== أدوات التحكم ====================
            for (final entry in _groupedActions().entries) ...[
              DesktopSectionTitle(
                title: entry.key.tr(),
                count: entry.value.length,
              ),
              DesktopResponsiveGrid(
                minTileWidth: 290,
                maxColumns: 4,
                children: [
                  for (final action in entry.value)
                    DesktopActionTile(
                      title: (action['title'] as String).tr(),
                      subtitle: (action['subtitle'] as String).tr(),
                      icon: action['icon'] as IconData,
                      color: action['color'] as Color,
                      onTap: action['onTap'] as VoidCallback,
                    ),
                ],
              ),
              const SizedBox(height: DesktopTokens.gapLg + 4),
            ],

            const SizedBox(height: DesktopTokens.gapXs),
            Center(
              child: Text(
                'SAYTARLY • Restaurant & Café Management',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textMuted.withValues(alpha: 0.7),
                  fontSize: 9.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
