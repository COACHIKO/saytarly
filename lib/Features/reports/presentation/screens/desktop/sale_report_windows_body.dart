part of '../SaleReport.dart';

/// جسم تقرير المبيعات — نسخة الويندوز (Windows UI).
///
/// نفس الفلاتر ونفس الأرقام بالظبط (يومي/شهري/شيفت + البحث + الطباعة والمسح):
/// مؤشرات فوق، الفلاتر في الهيدر، والجدول رؤوس أعمدة ثابتة + صفوف بالهوفر.
extension _SalesReportScreenWindowsBody on _SalesReportScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    // نفس حسابات الموبايل بالحرف.
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
    final soldItemsCount =
        _report.where((d) => (d['sold_qty'] as double) > 0).length;
    final totalDebtCollected = _report.fold<double>(
      0,
      (sum, item) => sum + (item['debt_collected_revenue'] as double),
    );
    final filtered = _filteredReport;

    return DesktopPageScaffold(
      title: widget.customTitle ?? 'تقرير المبيعات'.tr(),
      subtitle: '{v1} • {soldItemsCount} صنف'.tr({
        'v1': _periodLabel(),
        'soldItemsCount': soldItemsCount,
      }),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث التقرير'.tr(),
          onPressed: _isLoading ? null : _loadReport,
        ),
        DesktopButton.primary(
          label: 'طباعة PDF'.tr(),
          icon: Icons.picture_as_pdf_outlined,
          onPressed: _isLoading ? null : _printReportPdf,
        ),
        // 🆕 زرار المسح بيظهر بس في التقرير العام (بدون فلتر فئة) — زي الموبايل.
        if (widget.categoryFilter == null && widget.moduleId == null)
          DesktopButton.ghost(
            label: _isClearing ? 'جاري المسح...'.tr() : 'مسح مبيعات الفترة',
            icon: Icons.delete_forever_outlined,
            color: palette.danger,
            onPressed: _isClearing ? null : _clearPeriodSales,
          ),
      ],
      headerBottom: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DesktopTokens.gapMd,
        runSpacing: DesktopTokens.gapSm,
        children: [
          DesktopSegmented<String>(
            items: [
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
            onChanged: (value) {
              _refresh(() => _periodType = value);
              _loadReport();
            },
          ),
          _desktopPeriodPicker(palette),
          DesktopSearchField(
            hint: 'ابحث عن صنف'.tr(),
            width: 240,
            onChanged: (value) => _refresh(() => _searchQuery = value),
          ),
          DesktopInfoChip(
            label: '{soldItemsCount} صنف'.tr({
              'soldItemsCount': soldItemsCount,
            }),
            icon: Icons.inventory_2_outlined,
            color: palette.accent,
          ),
        ],
      ),
      child:
          _isLoading
              ? Padding(
                padding: EdgeInsets.symmetric(vertical: 90),
                child: Center(child: CircularProgressIndicator()),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================== مؤشرات (نفس قيم الموبايل) ====================
                  DesktopResponsiveGrid(
                    minTileWidth: 250,
                    maxColumns: 3,
                    children: [
                      DesktopStatCard(
                        label: 'الصافي المتوقع'.tr(),
                        value: netCollected.toStringAsFixed(2),
                        icon: Icons.account_balance_wallet_outlined,
                        color: palette.accent,
                        hint: 'الإيراد − الخصم − الآجل + المحصّل'.tr(),
                      ),
                      DesktopStatCard(
                        label: 'إيراد'.tr(),
                        value: totalRevenue.toStringAsFixed(0),
                        icon: Icons.payments_outlined,
                        color: palette.success,
                      ),
                      DesktopStatCard(
                        label: 'خصم'.tr(),
                        value: totalDiscount.toStringAsFixed(0),
                        icon: Icons.discount_outlined,
                        color: palette.warning,
                      ),
                      DesktopStatCard(
                        label: 'آجل باقي'.tr(),
                        value: totalDebt.toStringAsFixed(0),
                        icon: Icons.schedule_outlined,
                        color: palette.danger,
                      ),
                      DesktopStatCard(
                        label: 'دفع جزء من تربيزات (غير مضاف للصافي)'.tr(),
                        value: totalDebtCollected.toStringAsFixed(0),
                        icon: Icons.price_check_outlined,
                        color: palette.info,
                        hint: 'دفعات جزئية على الفواتير الآجلة'.tr(),
                      ),
                      DesktopStatCard(
                        label: 'اتحصّل فعليًا (كاش)'.tr(),
                        value: _debtCollectedInPeriod.toStringAsFixed(0),
                        icon: Icons.account_balance_wallet_outlined,
                        color: palette.info,
                        hint: 'من آجل قديم خارج الفترة'.tr(),
                      ),
                    ],
                  ),
                  SizedBox(height: DesktopTokens.gapLg),

                  // ==================== جدول الأصناف ====================
                  DesktopSectionTitle(
                    title: 'الأصناف المباعة'.tr(),
                    count: filtered.length,
                  ),
                  _desktopTableHeader(palette),
                  const SizedBox(height: DesktopTokens.gapSm),
                  if (filtered.isEmpty)
                    DesktopEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'لا توجد مبيعات في هذه الفترة'.tr(),
                      message: 'جرّب تغيير الفترة أو البحث عن صنف تاني.'.tr(),
                    )
                  else ...[
                    for (final item in filtered) ...[
                      _desktopItemRow(item, palette),
                      const SizedBox(height: DesktopTokens.gapSm),
                    ],
                    const SizedBox(height: DesktopTokens.gapXs),
                    _desktopTotalsRow(palette, filtered.length, totalRevenue),
                  ],
                ],
              ),
    );
  }

  /// اختيار الفترة — نفس منطق `_buildPeriodPicker` في الموبايل.
  Widget _desktopPeriodPicker(DesktopPalette palette) {
    switch (_periodType) {
      case 'day':
        return DesktopButton.ghost(
          label:
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
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
          return DesktopInfoChip(
            label: 'لا توجد شيفتات'.tr(),
            icon: Icons.info_outline,
            color: palette.warning,
          );
        }
        return Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
            border: Border.all(color: palette.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedShiftId,
              dropdownColor: palette.surface,
              icon: Icon(
                Icons.expand_more_rounded,
                color: palette.accentText,
                size: 18,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
              items:
                  _shifts
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text(
                            _shiftLabel(s),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                _refresh(() => _selectedShiftId = value);
                _loadReport();
              },
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// رأس الجدول — نفس ترتيب أعمدة الموبايل (الصنف / اتباع / باقي / الإيراد).
  Widget _desktopTableHeader(DesktopPalette palette) {
    final style = TextStyle(
      color: palette.textMuted,
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            child: Text(
              'اتباع'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
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

  /// صف صنف — نفس أرقام الموبايل (اتباع/باقي/إيراد + الشرائح).
  Widget _desktopItemRow(Map<String, dynamic> item, DesktopPalette palette) {
    final sold = item['sold_qty'] as double;
    final remaining = item['remaining_qty'] as double;
    final revenue = item['revenue'] as double;
    final discountAmount = item['discount_amount'] as double;
    final debtRevenue = item['debt_revenue'] as double;
    final debtCollected = item['debt_collected_revenue'] as double;
    final unit =
        item['is_weighted'] as bool
            ? (item['unit'] == 'kg' ? 'كجم'.tr() : 'جم'.tr())
            : '';
    final lowStock = remaining <= 5;
    final hasExtra =
        discountAmount > 0 || debtRevenue > 0.01 || debtCollected > 0.01;

    return DesktopCard(
      hover: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${_formatQty(item, sold)} $unit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.success,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatQty(item, remaining),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lowStock ? palette.danger : palette.textSecondary,
                    fontSize: 12.5,
                    fontWeight: lowStock ? FontWeight.w800 : FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  revenue.toStringAsFixed(2),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          if (hasExtra) ...[
            const SizedBox(height: DesktopTokens.gapSm),
            Wrap(
              spacing: DesktopTokens.gapSm,
              runSpacing: DesktopTokens.gapXs,
              children: [
                if (discountAmount > 0)
                  DesktopInfoChip(
                    label: 'خصم {v1}'.tr({
                      'v1': discountAmount.toStringAsFixed(2),
                    }),
                    icon: Icons.discount_outlined,
                    color: palette.warning,
                    dense: true,
                  ),
                if (debtRevenue > 0.01)
                  DesktopInfoChip(
                    label: 'آجل {v1}'.tr({
                      'v1': debtRevenue.toStringAsFixed(2),
                    }),
                    icon: Icons.schedule_outlined,
                    color: palette.danger,
                    dense: true,
                  ),
                if (debtCollected > 0.01)
                  DesktopInfoChip(
                    label: 'اتحصّل {v1}'.tr({
                      'v1': debtCollected.toStringAsFixed(2),
                    }),
                    icon: Icons.price_check_outlined,
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

  /// صف الإجماليات — مميز بخلفية accentSoft زي باقي التقارير.
  Widget _desktopTotalsRow(
    DesktopPalette palette,
    int soldItemsCount,
    double totalRevenue,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
        border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(
            'الإجمالي'.tr(),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: '{soldItemsCount} صنف'.tr({
              'soldItemsCount': soldItemsCount,
            }),
            icon: Icons.inventory_2_outlined,
            color: palette.accent,
            dense: true,
          ),
          const Spacer(),
          Text(
            totalRevenue.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: palette.accentText,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapXs),
          Text(
            '${Money.txt}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.accentText,
            ),
          ),
        ],
      ),
    );
  }
}
