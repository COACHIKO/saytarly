part of '../PlaystationSalesReportScreen.dart';

/// جسم شاشة تقرير مبيعات البلايستيشن — نسخة الويندوز (Windows UI).
///
/// نفس الأرقام بالظبط: صف مؤشرات (KPI) في الأول، فلاتر الفترة في هيدر
/// الصفحة، وصفوف الأجهزة بكروت عليها هوفر — وزرار الطباعة ومسح الفترة في
/// الـ actions. نفس الميثودس ونفس الـ callbacks.
extension _PlaystationSalesReportScreenWindowsBody
    on _PlaystationSalesReportScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final totalRevenue = _report.fold<double>(
      0,
      (sum, item) => sum + (item['revenue'] as double),
    );
    final totalDiscount = _report.fold<double>(
      0,
      (sum, item) => sum + (item['discount_amount'] as double),
    );
    final totalDebt = _report.fold<double>(
      0,
      (sum, item) => sum + (item['debt_revenue'] as double),
    );
    final netCollected =
        totalRevenue - totalDiscount - totalDebt + _debtCollectedInPeriod;
    final activeConsolesCount =
        _report.where((d) => (d['sessions_count'] as int) > 0).length;
    final totalHours = _report.fold<double>(
      0,
      (sum, item) => sum + (item['hours_played'] as double),
    );

    return DesktopPageScaffold(
      title: 'تقرير مبيعات البلايستيشن'.tr(),
      subtitle:
          '{v1} • {activeConsolesCount} جهاز • {v3}'.tr({'v1': _periodLabel(), 'activeConsolesCount': activeConsolesCount, 'v3': _formatHours(totalHours)}),
      actions: [
        DesktopButton.ghost(
          label: _isClearing ? 'جارٍ المسح...'.tr() : 'مسح مبيعات الفترة',
          icon: Icons.delete_forever_outlined,
          color: palette.danger,
          onPressed: _isClearing ? null : _clearPeriodSales,
        ),
        DesktopButton.primary(
          label: 'طباعة PDF'.tr(),
          icon: Icons.picture_as_pdf_outlined,
          onPressed: _isLoading ? null : _printReportPdf,
        ),
      ],
      headerBottom: Row(
        children: [
          DesktopSegmented<String>(
            items:  [
              DesktopSegmentItem(
                value: 'day',
                label: 'يومي'.tr(),
                icon: Icons.today_outlined,
              ),
              DesktopSegmentItem(
                value: 'month',
                label: 'شهري'.tr(),
                icon: Icons.calendar_month_outlined,
              ),
              DesktopSegmentItem(
                value: 'shift',
                label: 'شيفت'.tr(),
                icon: Icons.schedule_outlined,
              ),
            ],
            value: _periodType,
            onChanged: (v) {
              _refresh(() => _periodType = v);
              _loadReport();
            },
          ),
           SizedBox(width: DesktopTokens.gapMd),
          Expanded(child: _windowsPeriodPicker(palette)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات الفترة ====================
          DesktopResponsiveGrid(
            minTileWidth: 225,
            maxColumns: 4,
            children: [
              DesktopStatCard(
                label: 'الصافي المتوقع'.tr(),
                value: '${netCollected.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.account_balance_wallet_rounded,
                color: palette.accent,
                hint: _periodLabel(),
              ),
              DesktopStatCard(
                label: 'إيراد'.tr(),
                value: '${totalRevenue.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.payments_rounded,
                color: _PlaystationSalesReportScreenState.revenueColor,
              ),
              DesktopStatCard(
                label: 'خصم'.tr(),
                value: '${totalDiscount.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.discount_rounded,
                color: _PlaystationSalesReportScreenState.discountColor,
              ),
              DesktopStatCard(
                label: 'آجل باقي'.tr(),
                value: '${totalDebt.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.schedule_rounded,
                color: palette.danger,
              ),
              DesktopStatCard(
                label: 'اتحصّل فعليًا (كاش)'.tr(),
                value: '${_debtCollectedInPeriod.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.account_balance_wallet_outlined,
                color: palette.info,
              ),
              DesktopStatCard(
                label: 'أجهزة اشتغلت في الفترة'.tr(),
                value: '$activeConsolesCount',
                icon: Icons.sports_esports_outlined,
                color: palette.success,
              ),
              DesktopStatCard(
                label: 'إجمالي الساعات'.tr(),
                value: _formatHours(totalHours),
                icon: Icons.timer_outlined,
                color: palette.warning,
              ),
            ],
          ),

           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== قايمة الأجهزة ====================
          DesktopSectionTitle(
            title: 'الأجهزة'.tr(),
            count: _filteredReport.length,
            trailing: DesktopSearchField(
              hint: 'ابحث عن جهاز...'.tr(),
              onChanged: (v) => _refresh(() => _searchQuery = v),
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: palette.accent),
              ),
            )
          else if (_filteredReport.isEmpty)
            DesktopEmptyState(
              icon: Icons.sports_esports_outlined,
              title: 'لا توجد جلسات بلايستيشن في هذه الفترة'.tr(),
              message: 'جرّب تغيّر الفترة من الفلاتر فوق أو امسح كلمة البحث.'.tr(),
            )
          else ...[
            _windowsTableHeader(palette),
            const SizedBox(height: DesktopTokens.gapSm),
            for (final item in _filteredReport)
              _windowsItemRow(context, palette, item),
          ],
        ],
      ),
    );
  }

  /// رؤوس أعمدة الجدول — نفس تقسيم صف الموبايل.
  Widget _windowsTableHeader(DesktopPalette palette) {
    final style = TextStyle(
      color: palette.textMuted,
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesktopTokens.gapMd),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('الجهاز'.tr(), style: style)),
          Expanded(
            flex: 2,
            child: Text('جلسات'.tr(), textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text('ساعات'.tr(), textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: 3,
            child: Text('الإيراد'.tr(), textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }

  /// صف جهاز في الجدول — نفس أرقام وبيانات صف الموبايل.
  Widget _windowsItemRow(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> item,
  ) {
    final theme = Theme.of(context);
    final sessions = item['sessions_count'] as int;
    final hours = item['hours_played'] as double;
    final revenue = item['revenue'] as double;
    final discountAmount = item['discount_amount'] as double;
    final debtRevenue = item['debt_revenue'] as double;
    final debtCollected = item['debt_collected_revenue'] as double;
    final hasExtra =
        discountAmount > 0 || debtRevenue > 0.01 || debtCollected > 0.01;

    return DesktopCard(
      hover: true,
      margin: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapMd - 2,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  item['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$sessions',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _PlaystationSalesReportScreenState.revenueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatHours(hours),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  revenue.toStringAsFixed(2),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (hasExtra) ...[
            const SizedBox(height: DesktopTokens.gapSm),
            Wrap(
              spacing: DesktopTokens.gapXs,
              runSpacing: DesktopTokens.gapXs,
              children: [
                if (discountAmount > 0)
                  DesktopInfoChip(
                    label: 'خصم {v1}'.tr({'v1': discountAmount.toStringAsFixed(2)}),
                    icon: Icons.discount_outlined,
                    color: _PlaystationSalesReportScreenState.discountColor,
                    dense: true,
                  ),
                if (debtRevenue > 0.01)
                  DesktopInfoChip(
                    label: 'آجل {v1}'.tr({'v1': debtRevenue.toStringAsFixed(2)}),
                    icon: Icons.schedule_outlined,
                    color: palette.danger,
                    dense: true,
                  ),
                if (debtCollected > 0.01)
                  DesktopInfoChip(
                    label: 'اتحصّل {v1}'.tr({'v1': debtCollected.toStringAsFixed(2)}),
                    icon: Icons.check_circle_outline,
                    color: palette.info,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// اختيار مدة التقرير — نفس منطق اختيار الفترة في الموبايل
  /// (يوم / شهر / شيفت).
  Widget _windowsPeriodPicker(DesktopPalette palette) {
    switch (_periodType) {
      case 'day':
        return _windowsPickerPill(
          palette,
          icon: Icons.calendar_today_rounded,
          label:
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          onTap: _pickDate,
        );
      case 'month':
        return _windowsPickerPill(
          palette,
          icon: Icons.calendar_month_rounded,
          label:
              '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
          onTap: _pickMonth,
        );
      case 'shift':
        if (_shifts.isEmpty) {
          return _windowsPickerPill(
            palette,
            icon: Icons.schedule_outlined,
            label: 'لا توجد شيفتات'.tr(),
          );
        }
        return Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
            border: Border.all(color: palette.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedShiftId,
              dropdownColor: palette.surface,
              icon: Icon(
                Icons.expand_more_rounded,
                color: palette.accentText,
                size: 18,
              ),
              items: _shifts
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text(
                        _shiftLabel(s),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                _refresh(() => _selectedShiftId = v);
                _loadReport();
              },
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// پِلّة اختيار (زي بنّية الموبايل) — بهوفر ناعم على سطح المكتب.
  Widget _windowsPickerPill(
    DesktopPalette palette, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return HoverBuilder(
      builder: (context, hovering) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hovering ? palette.accentSoft : palette.surfaceSoft,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
            border: Border.all(
              color: hovering ? palette.accent : palette.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: palette.accentText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 17,
                color: palette.textMuted.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
