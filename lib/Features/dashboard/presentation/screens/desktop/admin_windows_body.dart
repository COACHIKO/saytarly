part of '../admin.dart';

/// جسم لوحة الأدمن — نسخة الويندوز (Windows UI).
///
/// سايد بار كامل بكل أدوات النظام مجمّعة في مجموعات + صف مؤشرات (KPI)
/// + شبكة أدوات قابلة للبحث بالهوفر.
extension _AdminWindowsBody on _AdminDashboardState {
  /// 🚪 تسجيل خروج لتغيير الدور — من شاشة اللوجين بيدخل بأي دور تاني.
  /// (الأدمن مالوش شيفت فمفيش أي قيود دخول بعده).
  Future<void> _logoutToLogin() => LogoutHelper.confirmAndLogout(context);

  /// بنجمّع كل الأدوات حسب المفتاح 'group' — نفس مصدر بيانات الموبايل.
  Map<String, List<Map<String, dynamic>>> _groupedActions({
    bool filtered = false,
  }) {
    final query = _searchQuery.trim();
    final result = <String, List<Map<String, dynamic>>>{};

    for (final action in _actions) {
      if (filtered &&
          query.isNotEmpty &&
          !(action['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase())) {
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
      for (final entry in grouped.entries)
        DesktopNavGroup(
          title: entry.key,
          items: [
            for (final action in entry.value)
              DesktopNavItem(
                id: action['title'] as String,
                label: action['title'] as String,
                icon: action['icon'] as IconData,
                onTap: action['onTap'] as VoidCallback,
              ),
          ],
        ),
    ];
  }

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopShell(
      placeName: _placeName,
      roleLabel: 'لوحة التحكم'.tr(),
      groups: _windowsNavGroups(),
      onSelect: (item) => item.onTap?.call(),
      title: 'لوحة التحكم'.tr(),
      subtitle: '{_placeName} • نظرة شاملة على النظام'.tr({'_placeName': _placeName}),
      actions: [
        DesktopToolbarIconButton(
          icon: _showStats
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          tooltip: _showStats ? 'إخفاء الملخص'.tr() : 'إظهار الملخص',
          onPressed: () => _refresh(() => _showStats = !_showStats),
        ),
        DesktopToolbarIconButton(
          icon: Icons.delete_outline,
          tooltip: 'مسح كل البيانات'.tr(),
          onPressed: _clearAllData,
        ),
        DesktopToolbarIconButton(
          icon: Icons.logout,
          tooltip: 'تسجيل خروج (تغيير دور)'.tr(),
          onPressed: _logoutToLogin,
        ),
         DesktopThemeToggle(),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== مؤشرات سريعة ====================
            if (_showStats) ...[
              _windowsStatsGrid(context),
               SizedBox(height: DesktopTokens.gapLg + 4),
            ],

            // ==================== كل الأدوات ====================
            DesktopSectionTitle(
              title: 'كل الأدوات'.tr(),
              count: _groupedActions(filtered: true)
                  .values
                  .fold<int>(0, (sum, list) => sum + list.length),
              trailing: DesktopSearchField(
                hint: 'ابحث عن أداة...'.tr(),
                onChanged: _setSearchQuery,
              ),
            ),
            const SizedBox(height: DesktopTokens.gapXs),
            ..._windowsActionSections(context),

            const SizedBox(height: DesktopTokens.gapMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 14, color: palette.textMuted),
                const SizedBox(width: DesktopTokens.gapXs),
                Text(
                  'Eng: Waled Mabrok — 01032548232',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _windowsStatsGrid(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopResponsiveGrid(
      minTileWidth: 230,
      children: [
        DesktopStatCard(
          label: 'عدد الفواتير'.tr(),
          value: '$sessionsCount',
          icon: Icons.receipt_long_outlined,
          color: palette.info,
        ),
        DesktopStatCard(
          label: 'إجمالي الدخل'.tr(),
          value: _money(incomeToday),
          icon: Icons.payments_outlined,
          color: palette.success,
        ),
        DesktopStatCard(
          label: 'إجمالي المصروفات'.tr(),
          value: _money(expensesTotal),
          icon: Icons.receipt_outlined,
          color: palette.danger,
        ),
        DesktopStatCard(
          label: 'شحن الرصيد'.tr(),
          value: _money(topupsTotal),
          icon: Icons.wallet_outlined,
          color: palette.warning,
        ),
        DesktopStatCard(
          label: 'تحصيل الآجل'.tr(),
          value: _money(debtsCollected),
          icon: Icons.handshake_outlined,
          color: palette.accent,
        ),
      ],
    );
  }

  List<Widget> _windowsActionSections(BuildContext context) {
    final grouped = _groupedActions(filtered: true);

    if (grouped.isEmpty) {
      return [
        DesktopEmptyState(
          icon: Icons.search_off,
          title: 'مفيش نتائج'.tr(),
          message: 'جرّب كلمة بحث تانية — أو امسح البحث.'.tr(),
        ),
      ];
    }

    return [
      for (final entry in grouped.entries) ...[
        DesktopSectionTitle(
          title: entry.key,
          count: entry.value.length,
        ),
        DesktopResponsiveGrid(
          minTileWidth: 270,
          maxColumns: 4,
          children: [
            for (final action in entry.value)
              DesktopActionTile(
                title: action['title'] as String,
                icon: action['icon'] as IconData,
                color: action['color'] as Color,
                onTap: action['onTap'] as VoidCallback,
              ),
          ],
        ),
        const SizedBox(height: DesktopTokens.gapLg + 4),
      ],
    ];
  }

  static String _money(double value) => '${value.toStringAsFixed(2)} ${Money.txt}';
}
