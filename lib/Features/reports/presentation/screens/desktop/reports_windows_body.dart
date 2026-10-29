part of '../reports.dart';

/// عرض الأعمدة الرقمية في جداول سطح المكتب — عشان الأرقام تترصّ فوق بعض.
const double _invoiceNumericColumnWidth = 110;

/// جسم شاشة التقارير المفصلة — نسخة الويندوز (Windows UI).
///
/// نفس كل الأرقام والكولباكات اللي في الموبايل (نفس _mask ونفس الفلاتر):
/// مؤشرات فوق، فلاتر في الهيدر، وصفوف فواتير نضيفة بالهوفر مع تفاصيل الفاتورة.
extension _ReportsScreenWindowsBody on _ReportsScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    // إجمالي المصروفات — نفس الحساب اللي الموبايل بيستخدمه في كارت "المصاريف".
    final expensesTotal = expenses.fold<double>(
      0.0,
      (p, e) => p + ((e['amount'] ?? 0) as num).toDouble(),
    );

    return DesktopPageScaffold(
      title: 'تقارير مفصلة'.tr(),
      subtitle: _selectedDate == null
          ? 'كل الفواتير • {v1} فاتورة'.tr({'v1': invoices.length})
          : 'بتاريخ ${DateFormat('yyyy-MM-dd').format(_selectedDate!)} • '
                '${invoices.length} فاتورة',
      actions: [
        DesktopButton.ghost(
          label: 'عرض كل الفواتير'.tr(),
          icon: Icons.receipt_long_outlined,
          onPressed: _showAllInvoices,
        ),
        DesktopButton.primary(
          label: 'اختر تاريخ'.tr(),
          icon: Icons.calendar_today_outlined,
          onPressed: _pickDate,
        ),
        DesktopToolbarIconButton(
          icon: _numbersVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          tooltip: _numbersVisible ? 'إخفاء الأرقام'.tr() : 'إظهار الأرقام',
          onPressed: _toggleNumbersVisibility,
        ),
        DesktopToolbarIconButton(
          icon: Icons.inventory_outlined,
          tooltip: 'معلومات اكتر علي الدخل'.tr(),
          onPressed: _openIncomeStats,
        ),
        DesktopToolbarIconButton(
          icon: Icons.receipt_long_outlined,
          tooltip: 'المصروفات'.tr(),
          onPressed: _showExpensesSheet,
        ),
        DesktopToolbarIconButton(
          icon: Icons.delete_forever_outlined,
          tooltip: 'مسح الكل'.tr(),
          onPressed: _deleteAllInvoices,
        ),
      ],
      headerBottom: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DesktopTokens.gapMd,
        runSpacing: DesktopTokens.gapSm,
        children: [
          // نفس فلتر الموبايل بالظبط: _selectedDate == null يعني "كل الفواتير".
          DesktopSegmented<String>(
            items:  [
              DesktopSegmentItem(
                value: 'all',
                label: 'كل الفواتير'.tr(),
                icon: Icons.receipt_long_outlined,
              ),
              DesktopSegmentItem(
                value: 'pick',
                label: 'تاريخ محدد'.tr(),
                icon: Icons.calendar_today_outlined,
              ),
            ],
            value: _selectedDate == null ? 'all' : 'pick',
            onChanged: (value) {
              if (value == 'all') {
                _showAllInvoices();
              } else {
                _pickDate();
              }
            },
          ),
          if (_selectedDate != null)
            DesktopInfoChip(
              label: 'بتاريخ: {v1}'.tr({'v1': DateFormat('yyyy-MM-dd').format(_selectedDate!)}),
              icon: Icons.event,
              color: palette.accent,
            ),
          DesktopInfoChip(
            label: '{v1} فاتورة'.tr({'v1': invoices.length}),
            icon: Icons.description_outlined,
            color: palette.info,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==================== مؤشرات (نفس كروت الموبايل) ====================
          DesktopResponsiveGrid(
            minTileWidth: 250,
            maxColumns: 4,
            children: [
              DesktopStatCard(
                label: 'رصيد درج الكاش'.tr(),
                value: _mask('${formatter.format(cashDrawerBalance)} ${Money.txt}'),
                icon: Icons.point_of_sale_outlined,
                color: palette.info,
                hint: 'النقدية الموجودة في الدرج'.tr(),
              ),
              DesktopStatCard(
                label: 'إجمالي الدخل'.tr(),
                value: _mask(formatter.format(totalIncome)),
                icon: Icons.trending_up,
                color: palette.success,
                hint: 'صافي الفترة المعروضة'.tr(),
              ),
              DesktopStatCard(
                label: 'مبيعات المنتجات'.tr(),
                value: _mask('${formatter.format(productSales)} ${Money.txt}'),
                icon: Icons.shopping_bag_outlined,
                color: palette.accent,
              ),
              DesktopStatCard(
                label: 'مبيعات المشروبات'.tr(),
                value: _mask('${formatter.format(drinkSales)} ${Money.txt}'),
                icon: Icons.local_cafe_outlined,
                color: palette.info,
              ),
              if (_cigarettesEnabled)
                DesktopStatCard(
                  label: 'مبيعات السجائر'.tr(),
                  value: _mask('${formatter.format(cigarettesSales)} ${Money.txt}'),
                  icon: Icons.smoking_rooms_outlined,
                  color: palette.warning,
                ),
              if (_shishaEnabled)
                DesktopStatCard(
                  label: 'مبيعات الشيشة'.tr(),
                  value: _mask('${formatter.format(shishaSales)} ${Money.txt}'),
                  icon: Icons.blur_on,
                  color: palette.accent,
                ),
              DesktopStatCard(
                label: 'دخل الأجهزة'.tr(),
                value: _mask('${formatter.format(deviceIncome)} ${Money.txt}'),
                icon: Icons.videogame_asset_outlined,
                color: palette.info,
              ),
              DesktopStatCard(
                label: 'الديون المتبقية'.tr(),
                value: _mask('${formatter.format(debtTotal)} ${Money.txt}'),
                icon: Icons.warning_amber_rounded,
                color: palette.danger,
              ),
              DesktopStatCard(
                label: 'المصاريف'.tr(),
                value: _mask(formatter.format(expensesTotal)),
                icon: Icons.money_off_outlined,
                color: palette.danger,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg),

          // ==================== قائمة الفواتير ====================
          DesktopSectionTitle(
            title: 'الفواتير'.tr(),
            count: invoices.length,
            trailing: Text(
              'اضغط على أي فاتورة لعرض تفاصيلها'.tr(),
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
          ),
          if (invoices.isEmpty)
             DesktopEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد فواتير'.tr(),
              message: 'مفيش فواتير مسجلة في الفترة المعروضة.'.tr(),
            )
          else
            _DesktopInvoicesBrowser(
              invoices: invoices,
              formatter: formatter,
              mask: _mask,
            ),
        ],
      ),
    );
  }
}

/// متصفح فواتير سطح المكتب — صف لكل فاتورة، وبالضغط يفتح تفاصيلها
/// بنفس أرقام الموبايل بالظبط (الأصناف + الحساب + الآجل).
class _DesktopInvoicesBrowser extends StatefulWidget {
  const _DesktopInvoicesBrowser({
    required this.invoices,
    required this.formatter,
    required this.mask,
  });

  final List<Map<String, dynamic>> invoices;
  final NumberFormat formatter;
  final String Function(String value) mask;

  @override
  State<_DesktopInvoicesBrowser> createState() =>
      _DesktopInvoicesBrowserState();
}

class _DesktopInvoicesBrowserState extends State<_DesktopInvoicesBrowser> {
  /// الفاتورة المفتوحة حاليًا (تفاصيلها ظاهرة تحتها).
  int? _expandedId;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final inv in widget.invoices) ...[
          _invoiceCard(inv, palette),
          const SizedBox(height: DesktopTokens.gapSm),
        ],
      ],
    );
  }

  Widget _invoiceCard(Map<String, dynamic> inv, DesktopPalette palette) {
    final id = inv['id'];
    final start = DateTime.parse(inv['start_time']);
    final end = inv['end_time'] != null
        ? DateTime.parse(inv['end_time'])
        : null;

    final isDebt = inv['payment_type'] == 'علي الحساب';
    final isCancelled = inv['payment_type'] == 'ملغي';
    final statusColor = isCancelled
        ? palette.textMuted
        : (isDebt ? palette.danger : palette.success);
    final statusLabel = isCancelled ? 'ملغية'.tr() : (isDebt ? 'آجل'.tr() : 'مدفوعة');
    final statusIcon = isCancelled
        ? Icons.cancel
        : (isDebt ? Icons.account_balance_wallet : Icons.check_circle);

    final remaining = (inv['_remaining'] as double?) ?? 0.0;

    final expanded = _expandedId == id;

    return DesktopCard(
      hover: true,
      selected: expanded,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => setState(() => _expandedId = expanded ? null : id as int),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesktopIconBadge(icon: statusIcon, color: statusColor, size: 40),
              const SizedBox(width: DesktopTokens.gapSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'فاتورة #{id}'.tr({'id': id}),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesktopTokens.gapXs),
                        DesktopInfoChip(
                          label: statusLabel,
                          icon: statusIcon,
                          color: statusColor,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(start),
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDebt && remaining > 0) ...[
                DesktopInfoChip(
                  label: 'متبقي: {v1}'.tr({'v1': widget.mask(remaining.toStringAsFixed(2))}),
                  icon: Icons.warning_amber_rounded,
                  color: palette.danger,
                  dense: true,
                ),
                const SizedBox(width: DesktopTokens.gapSm),
              ],
              SizedBox(
                width: 170,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الإجمالي'.tr(),
                      style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.mask(
                        widget.formatter.format(inv['total_cost'] ?? 0),
                      ),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: palette.textMuted,
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: DesktopTokens.gapMd),
            Container(height: 1, color: palette.border),
            const SizedBox(height: DesktopTokens.gapMd),
            _details(inv, isDebt, start, end, palette),
          ],
        ],
      ),
    );
  }

  /// تفاصيل الفاتورة — نفس محتوى `_buildInvoiceDetails` في الموبايل.
  Widget _details(
    Map<String, dynamic> inv,
    bool isDebt,
    DateTime start,
    DateTime? end,
    DesktopPalette palette,
  ) {
    final items = (inv['_items'] as List<Map<String, dynamic>>?) ?? [];
    final paidAmount = (inv['_paidAmount'] as double?) ?? 0.0;
    final invoiceTotal = (inv['_invoiceTotal'] as double?) ?? 0.0;
    final remaining = (inv['_remaining'] as double?) ?? 0.0;
    final discount = ((inv['discount'] ?? 0) as num).toDouble();
    final drinksCost = ((inv['drinks_cost'] ?? 0) as num).toDouble();
    final deviceCost = ((inv['device_cost'] ?? 0) as num).toDouble();
    final cigCost = ((inv['cigarettes_cost'] ?? 0) as num).toDouble();
    final shishaCost = ((inv['shisha_cost'] ?? 0) as num).toDouble();
    final productsCost = ((inv['products_cost'] ?? 0) as num).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------- البيانات + الأصناف ----------------
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inv['console_id'] != 0) ...[
                _infoRow(
                  'الجهاز'.tr(),
                  (inv['console_name'] ?? inv['console_id']).toString(),
                  palette,
                ),
                _infoRow(
                  'وقت البداية'.tr(),
                  DateFormat('yyyy-MM-dd HH:mm').format(start),
                  palette,
                ),
              ] else
                _infoRow('النوع'.tr(), 'ترابيزة'.tr(), palette),
              _infoRow(
                'وقت الدفع'.tr(),
                end != null ? DateFormat('yyyy-MM-dd HH:mm').format(end) : 'جاري',
                palette,
              ),
              const SizedBox(height: DesktopTokens.gapMd),
              Text(
                'الأصناف'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: DesktopTokens.gapXs),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'لا توجد أصناف'.tr(),
                    style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                  ),
                )
              else
                for (final item in items) _itemRow(item, inv, palette),
            ],
          ),
        ),
        const SizedBox(width: DesktopTokens.gapXl),
        // ---------------- الحساب ----------------
        SizedBox(
          width: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحساب'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: DesktopTokens.gapXs),
              _financialRow('المشروبات'.tr(), drinksCost, palette),
              if (productsCost > 0)
                _financialRow('المنتجات / مأكولات'.tr(), productsCost, palette),
              if (cigCost > 0) _financialRow('السجائر'.tr(), cigCost, palette),
              if (shishaCost > 0) _financialRow('الشيشة'.tr(), shishaCost, palette),
              if (deviceCost > 0)
                _financialRow('تكلفة الجهاز'.tr(), deviceCost, palette),
              if (discount > 0)
                _financialRow(
                  'الخصم'.tr(),
                  discount,
                  palette,
                  color: palette.warning,
                ),
              const SizedBox(height: DesktopTokens.gapXs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: _financialRow(
                  'الإجمالي'.tr(),
                  invoiceTotal,
                  palette,
                  bold: true,
                  insideHighlight: true,
                ),
              ),
              const SizedBox(height: DesktopTokens.gapXs),
              _financialRow(
                'المدفوع'.tr(),
                paidAmount,
                palette,
                color: palette.success,
              ),
              if (isDebt && remaining > 0)
                _financialRow(
                  'المتبقي (آجل)'.tr(),
                  remaining,
                  palette,
                  color: palette.danger,
                  bold: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// صف صنف واحد — نفس اسم/كمية/إجمالي الموبايل.
  Widget _itemRow(
    Map<String, dynamic> item,
    Map<String, dynamic> inv,
    DesktopPalette palette,
  ) {
    double displayTotal = (item['total'] ?? 0.0).toDouble();
    if (item['drink_name'] == 'شحن رصيد' && displayTotal == 0) {
      displayTotal = inv['total_cost']?.toDouble() ?? 0.0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '{v1}'.tr({'v1': item['drink_name'] ?? 'شحن رصيد'.tr()}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: palette.textPrimary),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'x${item['qty']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: palette.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: _invoiceNumericColumnWidth,
            child: Text(
              widget.mask(displayTotal.toStringAsFixed(2)),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, DesktopPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: palette.textMuted),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialRow(
    String label,
    double value,
    DesktopPalette palette, {
    Color? color,
    bool bold = false,
    bool insideHighlight = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: insideHighlight ? 0 : 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 13.5 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            widget.mask('${value.toStringAsFixed(2)} ${Money.txt}'),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? palette.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
