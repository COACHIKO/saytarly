part of '../ProductsReportScreen.dart';

/// جسم تقرير المنتجات — نسخة الويندوز (Windows UI).
///
/// نفس منطق الموبايل: فلاتر (يومي / شهري / شيفت + القسم) + بحث، بس بشكل
/// سطح مكتب: صف مؤشرات KPI، جدول صفوف بكروت، وكارت ملخص سفلي مميز.
extension _ProductsReportScreenWindowsBody on _ProductsReportScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final items = _filteredReport;
    final totals = _windowsTotals();
    final soldItemsCount =
        _report.where((d) => (d['sold_qty'] as double) > 0).length;

    return DesktopPageScaffold(
      title: 'تقرير المنتجات'.tr(),
      subtitle: '{v1} • {soldItemsCount} صنف'.tr({'v1': _periodLabel(), 'soldItemsCount': soldItemsCount}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث التقرير'.tr(),
          onPressed: _isLoading ? null : _loadReport,
        ),
        DesktopButton.ghost(
          label: 'مسح مبيعات الفترة'.tr(),
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
      headerBottom: _windowsFilters(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات الفترة ====================
          DesktopResponsiveGrid(
            minTileWidth: 215,
            maxColumns: 5,
            children: [
              DesktopStatCard(
                label: 'الصافي المتوقع'.tr(),
                value: _money(totals.net),
                icon: Icons.account_balance_wallet_outlined,
                color: palette.accent,
                hint: _periodLabel(),
              ),
              DesktopStatCard(
                label: 'إجمالي الإيراد'.tr(),
                value: _money(totals.revenue),
                icon: Icons.payments_outlined,
                color: _ProductsReportScreenState.revenueColor,
              ),
              DesktopStatCard(
                label: 'إجمالي الخصم'.tr(),
                value: _money(totals.discount),
                icon: Icons.discount_outlined,
                color: _ProductsReportScreenState.discountColor,
              ),
              DesktopStatCard(
                label: 'آجل باقي (غير محصّل)'.tr(),
                value: _money(totals.debt),
                icon: Icons.schedule_outlined,
                color: palette.danger,
              ),
              DesktopStatCard(
                label: 'اتحصّل فعليًا (كاش)'.tr(),
                value: _money(_debtCollectedInPeriod),
                icon: Icons.price_check_outlined,
                color: palette.info,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg),

          // ==================== جدول المنتجات ====================
          DesktopSectionTitle(
            title: 'المنتجات المباعة'.tr(),
            count: soldItemsCount,
            trailing: DesktopSearchField(
              hint: 'ابحث عن منتج...'.tr(),
              onChanged: (v) => _refresh(() => _searchQuery = v),
            ),
          ),
          if (_isLoading)
             Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
             DesktopEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'لا توجد مبيعات منتجات في هذه الفترة'.tr(),
              message: 'جرّب تغيّر الفترة أو القسم من الفلاتر اللي فوق.'.tr(),
            )
          else ...[
            _windowsTableHeader(palette),
            const SizedBox(height: DesktopTokens.gapSm),
            for (final item in items) ...[
              _windowsItemCard(context, palette, item),
              const SizedBox(height: DesktopTokens.gapSm),
            ],
          ],
          const SizedBox(height: DesktopTokens.gapLg),

          // ==================== الملخص ====================
          _windowsSummaryCard(palette, totals),
          const SizedBox(height: DesktopTokens.gapLg),
        ],
      ),
    );
  }

  // ---------------- الفلاتر ----------------

  Widget _windowsFilters(DesktopPalette palette) {
    return Row(
      children: [
        DesktopSegmented<String>(
          items:  [
            DesktopSegmentItem<String>(
              value: 'day',
              label: 'يومي'.tr(),
              icon: Icons.calendar_today_outlined,
            ),
            DesktopSegmentItem<String>(
              value: 'month',
              label: 'شهري'.tr(),
              icon: Icons.calendar_month_outlined,
            ),
            DesktopSegmentItem<String>(
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
        const SizedBox(width: DesktopTokens.gapMd),
        _windowsPeriodPicker(palette),
        const SizedBox(width: DesktopTokens.gapMd),
        _windowsModuleFilter(palette),
      ],
    );
  }

  Widget _windowsPeriodPicker(DesktopPalette palette) {
    switch (_periodType) {
      case 'day':
        return DesktopButton.ghost(
          label: _windowsDate(_selectedDate),
          icon: Icons.calendar_today_rounded,
          onPressed: _pickDate,
        );
      case 'month':
        return DesktopButton.ghost(
          label:
              '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
          icon: Icons.calendar_month_rounded,
          onPressed: _pickMonth,
        );
      case 'shift':
        if (_shifts.isEmpty) {
          return  DesktopInfoChip(
            label: 'لا توجد شيفتات'.tr(),
            icon: Icons.info_outline,
          );
        }
        return _windowsDropdown<int?>(
          palette: palette,
          icon: Icons.schedule_rounded,
          value: _selectedShiftId,
          items: [
            for (final s in _shifts)
              DropdownMenuItem<int?>(
                value: s['id'] as int,
                child: Text(
                  _shiftLabel(s),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            _refresh(() => _selectedShiftId = v);
            _loadReport();
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _windowsModuleFilter(DesktopPalette palette) {
    return _windowsDropdown<int?>(
      palette: palette,
      icon: Icons.category_outlined,
      value: _selectedModuleId,
      items: [
         DropdownMenuItem<int?>(value: null, child: Text('كل الأقسام'.tr())),
        for (final m in _modules)
          DropdownMenuItem<int?>(
            value: m['id'] as int,
            child: Text(m['name'] as String? ?? ''),
          ),
      ],
      onChanged: (v) {
        _refresh(() => _selectedModuleId = v);
        _loadReport();
      },
    );
  }

  /// دروب داون بشكل سطح المكتب — نفس ألوان الكروت والحقول.
  Widget _windowsDropdown<T>({
    required DesktopPalette palette,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: palette.textMuted),
          const SizedBox(width: DesktopTokens.gapSm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isDense: true,
                value: value,
                dropdownColor: palette.surface,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
                icon: Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: palette.accentText,
                ),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- الجدول ----------------

  Widget _windowsTableHeader(DesktopPalette palette) {
    final style = TextStyle(
      color: palette.textMuted,
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('الصنف'.tr(), style: style)),
          Expanded(
            flex: 2,
            child: Text('اتباع'.tr(), textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text('باقي'.tr(), textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: 3,
            child: Text('الإيراد'.tr(), textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }

  Widget _windowsItemCard(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> item,
  ) {
    final sold = item['sold_qty'] as double;
    final remaining = item['remaining_qty'] as double;
    final revenue = item['revenue'] as double;
    final discountAmount = item['discount_amount'] as double;
    final debtRevenue = item['debt_revenue'] as double;
    final debtCollected = item['debt_collected_revenue'] as double;
    final unit = item['is_weighted'] as bool
        ? (item['unit'] == 'kg' ? 'كجم'.tr() : 'جم')
        : '';
    final lowStock = remaining <= 5;
    final hasExtra =
        discountAmount > 0 || debtRevenue > 0.01 || debtCollected > 0.01;

    return DesktopCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapMd - 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  item['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${_formatQty(item, sold)} $unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _ProductsReportScreenState.revenueColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatQty(item, remaining),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: lowStock ? FontWeight.bold : FontWeight.w600,
                    color: lowStock ? palette.danger : palette.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  revenue.toStringAsFixed(2),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (hasExtra) ...[
            const SizedBox(height: DesktopTokens.gapSm),
            Wrap(
              spacing: DesktopTokens.gapSm,
              runSpacing: 4,
              children: [
                if (discountAmount > 0)
                  DesktopInfoChip(
                    label: 'خصم {v1}'.tr({'v1': discountAmount.toStringAsFixed(2)}),
                    color: _ProductsReportScreenState.discountColor,
                    dense: true,
                  ),
                if (debtRevenue > 0.01)
                  DesktopInfoChip(
                    label: 'آجل {v1}'.tr({'v1': debtRevenue.toStringAsFixed(2)}),
                    color: palette.danger,
                    dense: true,
                  ),
                if (debtCollected > 0.01)
                  DesktopInfoChip(
                    label: 'اتحصّل {v1}'.tr({'v1': debtCollected.toStringAsFixed(2)}),
                    color: palette.success,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- الملخص ----------------

  Widget _windowsSummaryCard(
    DesktopPalette palette,
    ({
      double revenue,
      double discount,
      double debt,
      double debtCollected,
      double net,
    }) totals,
  ) {
    return DesktopCard(
      color: palette.accentSoft,
      borderColor: palette.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: palette.accentText,
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              Text(
                'الملخص'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          _windowsSummaryRow(palette, 'إجمالي الإيراد'.tr(), totals.revenue),
          _windowsSummaryRow(palette, 'إجمالي الخصم'.tr(), totals.discount),
          _windowsSummaryRow(palette, 'آجل باقي (غير محصّل)'.tr(), totals.debt),
          _windowsSummaryRow(
            palette,
            'دفع جزء من تربيزات'.tr(),
            totals.debtCollected,
          ),
          _windowsSummaryRow(
            palette,
            'اتحصّل فعليًا من آجل قديم (كاش)'.tr(),
            _debtCollectedInPeriod,
          ),
          Divider(color: palette.border, height: DesktopTokens.gapLg),
          _windowsSummaryRow(
            palette,
            'الصافي المتوقع'.tr(),
            totals.net,
            bold: true,
            color: palette.accentText,
          ),
        ],
      ),
    );
  }

  Widget _windowsSummaryRow(
    DesktopPalette palette,
    String label,
    double value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14.5 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: color ?? palette.textSecondary,
              ),
            ),
          ),
          Text(
            _money(value),
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- أدوات صغيرة ----------------

  ({
    double revenue,
    double discount,
    double debt,
    double debtCollected,
    double net,
  }) _windowsTotals() {
    final revenue = _report.fold<double>(
      0,
      (sum, item) => sum + (item['revenue'] as double),
    );
    final discount = _report.fold<double>(
      0,
      (sum, item) => sum + (item['discount_amount'] as double),
    );
    final debt = _report.fold<double>(
      0,
      (sum, item) => sum + (item['debt_revenue'] as double),
    );
    final debtCollected = _report.fold<double>(
      0,
      (sum, item) => sum + (item['debt_collected_revenue'] as double),
    );
    final net = revenue - discount - debt + _debtCollectedInPeriod;

    return (
      revenue: revenue,
      discount: discount,
      debt: debt,
      debtCollected: debtCollected,
      net: net,
    );
  }

  String _money(double value) => '${value.toStringAsFixed(2)} ${Money.txt}';

  String _windowsDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
