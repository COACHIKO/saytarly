part of '../debts_screen.dart';

/// جسم شاشة الديون — نسخة الويندوز (Windows UI).
///
/// صف مؤشرات (KPI) + بحث + قائمة العملاء كصفوف قابلة للهوفر، ونفس
/// الإجراءات بالظبط اللي الموبايل بينادي عليها (تفاصيل/سداد/طباعة/حذف).
extension _DebtsScreenWindowsBody on _DebtsScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    // 🆕 المجموع من remaining_amount بدل total_amount (نفس حساب الموبايل)
    final totalAll = filteredDebts.fold<double>(
      0,
      (sum, d) => sum + (d['remaining_amount'] as num).toDouble(),
    );

    final totalInvoices = filteredDebts.fold<int>(
      0,
      (sum, d) => sum + (((d['ids'] as List?)?.length) ?? 0),
    );

    return DesktopPageScaffold(
      title: 'الديون المسجلة'.tr(),
      subtitle: 'متابعة الآجل وتحصيل المديونيات'.tr(),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث البيانات'.tr(),
          onPressed: _loadDebts,
        ),
        DesktopButton.ghost(
          label: 'جرد الديون'.tr(),
          icon: Icons.print_outlined,
          onPressed: _printDebtsInventory,
        ),
        DesktopButton.ghost(
          label: 'استعادة نسخة'.tr(),
          icon: Icons.upload_file_outlined,
          onPressed: _restoreBackup,
        ),
        DesktopButton.ghost(
          label: 'تصدير نسخة'.tr(),
          icon: Icons.download_outlined,
          onPressed: _exportBackup,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات سريعة ====================
          DesktopResponsiveGrid(
            minTileWidth: 250,
            maxColumns: 3,
            children: [
              DesktopStatCard(
                label: 'إجمالي المتأخرات'.tr(),
                value: '${formatter.format(totalAll)} ${Money.txt}',
                icon: Icons.trending_down,
                color: palette.danger,
                hint: 'المجموع المتبقي على العملاء'.tr(),
              ),
              DesktopStatCard(
                label: 'عدد العملاء'.tr(),
                value: '${filteredDebts.length}',
                icon: Icons.people_outline,
                color: palette.info,
                hint: searchQuery.isEmpty
                    ? 'كل العملاء المسجّلين'.tr()
                    : 'نتيجة البحث الحالي',
              ),
              DesktopStatCard(
                label: 'عدد الفواتير'.tr(),
                value: '$totalInvoices',
                icon: Icons.receipt_long_outlined,
                color: palette.accent,
                hint: 'فواتير آجلة غير مسددة'.tr(),
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== البحث ====================
          DesktopSectionTitle(
            title: 'العملاء'.tr(),
            count: filteredDebts.length,
            trailing: DesktopSearchField(
              hint: 'ابحث باسم العميل...'.tr(),
              onChanged: _filterDebts,
              width: 300,
            ),
          ),

          // ==================== القائمة ====================
          if (_isLoadingDebts)
            const Padding(
              padding: EdgeInsets.all(DesktopTokens.gapXl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredDebts.isEmpty)
            DesktopEmptyState(
              icon: Icons.money_off_outlined,
              title: 'لا توجد ديون حالياً'.tr(),
              message: searchQuery.isEmpty
                  ? 'مفيش أي مبالغ آجلة مسجّلة على العملاء.'.tr()
                  : 'مفيش نتائج للبحث "$searchQuery".',
            )
          else
            for (final d in filteredDebts) ...[
              _windowsDebtRow(context, d),
              const SizedBox(height: DesktopTokens.gapSm + 2),
            ],
        ],
      ),
    );
  }

  /// صف عميل واحد — هوفر كامل + نفس الإجراءات اللي الموبايل بينادي عليها.
  Widget _windowsDebtRow(BuildContext context, Map<String, dynamic> d) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    final customerName = (d['customer_name'] ?? 'غير معروف'.tr()).toString();
    final remaining = (d['remaining_amount'] ?? 0).toDouble();
    final date = DateTime.tryParse(d['date'].toString());
    final ids = d['ids'];
    final idList = ids is List ? ids.cast<int>() : [ids as int];

    // الموبايل بيفتح التفاصيل على ضغطة الصف، ومنها بيتبعت نفس الـ
    // _showPayDialog — فبنستخدم نفس الميثود بالحرف (وهي بتقفل الـ
    // dialog والـ bottom sheet مع بعض، فمينفعش نناديها لوحدها).
    void openDetails() => _showDebtDetails(idList, customerName, remaining);

    return DesktopCard(
      hover: true,
      onTap: openDetails,
      padding:  EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.person_outline,
            color: remaining > 0 ? palette.danger : palette.success,
          ),
           SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
                 SizedBox(height: 3),
                Text(
                  date != null
                      ? 'التاريخ: {v1}'.tr({'v1': DateFormat('yyyy-MM-dd HH:mm').format(date)})
                      : 'التاريخ: غير محدد',
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
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: '{v1} فاتورة'.tr({'v1': (ids as List?)?.length ?? 1}),
            icon: Icons.receipt_long_outlined,
            dense: true,
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Text(
            '${formatter.format(remaining)} ${Money.txt}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.danger,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopToolbarIconButton(
            icon: Icons.print_outlined,
            tooltip: 'طباعة دين {customerName}'.tr({'customerName': customerName}),
            onPressed: () => _printSingleDebt(customerName, d['ids']),
          ),
          DesktopToolbarIconButton(
            icon: Icons.delete_outline,
            tooltip: 'حذف'.tr(),
            onPressed: () => _deleteDebt(d['id'] ?? 0),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopButton.primary(
            label: 'سداد'.tr(),
            icon: Icons.payments_outlined,
            onPressed: openDetails,
          ),
        ],
      ),
    );
  }
}
