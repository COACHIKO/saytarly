part of '../staff_dashboard.dart';

/// جسم لوحة الكاشير — نسخة الويندوز (Windows UI).
///
/// بانر ترحيبي متدرّج + إحصائيات حية + شبكة وصول سريع + إجراءات الشيفت،
/// وكله متاح من السايد بار أو من الصف العلوي.
extension _StaffDashboardWindowsBody on _StaffDashboardState {
  /// 🚪 تسجيل خروج لتغيير الدور — الشيفت يفضل مفتوح باسمك (تقدر ترجع
  /// وتكمّله)، الكاشير التاني محجوز لحد ما تقفل أو تسلّم، والأدمن بيدخل عادي.
  Future<void> _logoutToLogin() {
    return LogoutHelper.confirmAndLogout(
      context,
      openShiftNote:
          ('الشيفت رقم {v1} يفضل مفتوح باسمك: تقدر ترجع بنفس '.tr({
                'v1': widget.shiftId,
              }) +
              'الحساب وتكمّل، وكاشير تاني مش هيقدر يفتح شيفت غير لما تقفل '
                  .tr() +
              'أو تسلّم شيفتك — أما الأدمن والسوبر أدمن بيدخلوا براحتهم.'.tr()),
    );
  }

  /// Opens a page inside the desktop shell so the sidebar stays visible.
  void _pushShellPage(Widget page) {
    final route = MaterialPageRoute<void>(builder: (_) => page);
    final shellNavigator = _shellNavKey.currentState;
    if (shellNavigator != null) {
      shellNavigator.push(route);
    } else {
      Navigator.push(context, route);
    }
  }

  Widget _playstationPage(BuildContext context) =>
      PsScreen(staffName: widget.staffName, shiftId: widget.shiftId);

  Widget _tablesPage(BuildContext context) => DrinksscreenDashboard(
    staffName: widget.staffName,
    shiftId: widget.shiftId,
  );

  Widget _expensePage(BuildContext context) => CashierExpensesScreen(
    shiftId: widget.shiftId,
    cashierName: widget.staffName,
  );

  Widget _subStaffPage(BuildContext context) => SubStaffPage(
    staffId: widget.staffId,
    shiftId: widget.shiftId,
    cashierName: widget.staffName,
  );

  Widget _allSalesPage(BuildContext context) => ShiftDetailsPage(
    shiftId: widget.shiftId,
    staffName: widget.staffName,
    staffId: widget.staffId,
  );

  void _openPlaystation() => _pushShellPage(_playstationPage(context));

  void _openTables() => _pushShellPage(_tablesPage(context));

  void _openExpense() => _pushShellPage(_expensePage(context));

  void _openSubStaff() => _pushShellPage(_subStaffPage(context));

  void _openAllSales() => _pushShellPage(_allSalesPage(context));

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopShell(
      placeName: _placeName,
      roleLabel: 'نقطة الكاشير'.tr(),
      userName: widget.staffName,
      userRole: 'كاشير'.tr(),
      onLogout: _logoutToLogin,
      groups: [
        DesktopNavGroup(
          title: 'الكاشير'.tr(),
          items: [
            DesktopNavItem(
              id: 'staff-home',
              label: 'الرئيسية'.tr(),
              icon: Icons.home_outlined,
            ),
            DesktopNavItem(
              id: 'staff-ps',
              label: 'البلايستيشن'.tr(),
              icon: Icons.sports_esports_outlined,
              pageBuilder: _playstationPage,
            ),
            DesktopNavItem(
              id: 'staff-takeaway',
              label: 'تيك أواي'.tr(),
              icon: Icons.takeout_dining_outlined,
              onTap: _startTakeaway,
            ),
            DesktopNavItem(
              id: 'staff-tables',
              label: 'الترابيزات'.tr(),
              icon: Icons.table_restaurant_outlined,
              pageBuilder: _tablesPage,
            ),
            DesktopNavItem(
              id: 'staff-expense',
              label: 'إضافة مصروف'.tr(),
              icon: Icons.receipt_long_outlined,
              pageBuilder: _expensePage,
            ),
            DesktopNavItem(
              id: 'staff-substaff',
              label: 'شيفتات موظفين'.tr(),
              icon: Icons.badge_outlined,
              pageBuilder: _subStaffPage,
            ),
          ],
        ),
        DesktopNavGroup(
          title: 'الشيفت'.tr(),
          items: [
            DesktopNavItem(
              id: 'staff-debts',
              label: 'الفواتير الآجلة'.tr(),
              icon: Icons.wallet_outlined,
              onTap: _showDebtorsSheet,
            ),
            DesktopNavItem(
              id: 'staff-sales',
              label: 'كل المبيعات'.tr(),
              icon: Icons.query_stats_outlined,
              pageBuilder: _allSalesPage,
            ),
            DesktopNavItem(
              id: 'staff-close',
              label: 'قفل الشيفت'.tr(),
              icon: Icons.lock_outline,
              onTap: _confirmCloseShift,
            ),
            DesktopNavItem(
              id: 'staff-logout',
              label: 'خروج (تغيير دور)'.tr(),
              icon: Icons.logout,
              onTap: _logoutToLogin,
            ),
          ],
        ),
      ],
      activeId: 'staff-home',
      navigatorKey: _shellNavKey,
      title: 'الكاشير — {v1}'.tr({'v1': widget.staffName}),
      subtitle: 'شيفت رقم {v1} • {_placeName}'.tr({
        'v1': widget.shiftId,
        '_placeName': _placeName,
      }),
      actions: [
        const CardQueueIconButton(),
        DesktopToolbarIconButton(
          icon: Icons.wallet_outlined,
          tooltip: 'الفواتير الآجلة'.tr(),
          onPressed: _showDebtorsSheet,
        ),
        DesktopToolbarIconButton(
          icon: Icons.lock_outline,
          tooltip: 'قفل الشيفت'.tr(),
          onPressed: _confirmCloseShift,
        ),
        const DesktopThemeToggle(),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _staffHeroPanel(context, palette),
            const SizedBox(height: DesktopTokens.gapLg + 4),
            DesktopSectionTitle(title: 'الوصول السريع'.tr()),
            DesktopResponsiveGrid(
              minTileWidth: 270,
              maxColumns: 4,
              children: [
                DesktopActionTile(
                  title: 'البلايستيشن'.tr(),
                  subtitle: 'إدارة الأجهزة والجلسات'.tr(),
                  icon: Icons.sports_esports_outlined,
                  color: palette.info,
                  onTap: _openPlaystation,
                ),
                DesktopActionTile(
                  title: 'تيك أواي'.tr(),
                  subtitle: 'فاتورة سريعة للسفري'.tr(),
                  icon: Icons.takeout_dining_outlined,
                  color: palette.warning,
                  onTap: _startTakeaway,
                ),
                DesktopActionTile(
                  title: 'الترابيزات'.tr(),
                  subtitle: 'مبيعات الداخل والترابيزات'.tr(),
                  icon: Icons.table_restaurant_outlined,
                  color: palette.accent,
                  onTap: _openTables,
                ),
                DesktopActionTile(
                  title: 'إضافة مصروف'.tr(),
                  subtitle: 'تسجيل مصروف على الشيفت'.tr(),
                  icon: Icons.receipt_long_outlined,
                  color: palette.danger,
                  onTap: _openExpense,
                ),
                DesktopActionTile(
                  title: 'شيفتات موظفين'.tr(),
                  subtitle: 'متابعة شيفتات الفريق'.tr(),
                  icon: Icons.badge_outlined,
                  color: palette.success,
                  onTap: _openSubStaff,
                ),
              ],
            ),
            const SizedBox(height: DesktopTokens.gapLg + 4),
            DesktopSectionTitle(title: 'إجراءات الشيفت'.tr()),
            DesktopResponsiveGrid(
              minTileWidth: 270,
              maxColumns: 4,
              children: [
                DesktopActionTile(
                  title: 'الفواتير الآجلة'.tr(),
                  subtitle: 'عرض فواتير الأجل والتحصيل'.tr(),
                  icon: Icons.wallet_outlined,
                  color: palette.warning,
                  onTap: _showDebtorsSheet,
                  compact: true,
                ),
                DesktopActionTile(
                  title: 'كل المبيعات'.tr(),
                  subtitle: 'تقرير مفصّل لمبيعات الشيفت'.tr(),
                  icon: Icons.query_stats_outlined,
                  color: palette.info,
                  onTap: _openAllSales,
                  compact: true,
                ),
                DesktopActionTile(
                  title: 'قفل الشيفت'.tr(),
                  subtitle: 'إغلاق الشيفت وطباعة التقرير'.tr(),
                  icon: Icons.lock_outline,
                  color: palette.danger,
                  onTap: _confirmCloseShift,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: DesktopTokens.gapLg + 6),
            Center(
              child: Text(
                'SAYTARLY • Restaurant & Café Management',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  /// البانر الترحيبي المتدرّج في أعلى الصفحة.
  Widget _staffHeroPanel(BuildContext context, DesktopPalette palette) {
    final theme = Theme.of(context);
    final deep = Color.lerp(palette.accent, const Color(0xFF060D1C), 0.6)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesktopTokens.gapLg + 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [palette.accent, deep],
        ),
        borderRadius: BorderRadius.circular(DesktopTokens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.6),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحباً، {v1}'.tr({'v1': widget.staffName}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'شيفت رقم {v1} — كل حاجة تحت إيدك من هنا.'.tr({
                    'v1': widget.shiftId,
                  }),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapLg),
          _heroStat(context, 'جلسات مفتوحة'.tr(), '${activeInvoices.length}'),
          const SizedBox(width: DesktopTokens.gapSm + 2),
          _heroStat(context, 'إجمالي الأجهزة'.tr(), '${consoles.length}'),
        ],
      ),
    );
  }

  Widget _heroStat(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesktopTokens.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
