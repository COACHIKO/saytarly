part of '../customers_report_screen.dart';

/// جسم تقرير العملاء الشهري — نسخة الويندوز (Windows UI).
///
/// نفس المنطق: نفس _loadCustomers ونفس _showCustomerInvoices ونفس
/// _confirmDeleteCustomer — اللي اتغيّر هو الشكل بس (KPI + جدول صفوف).
extension _CustomersReportScreenWindowsBody on _CustomersReportScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final totalIncome = _customers.fold<double>(
      0,
      (sum, c) => sum + (((c['total_income'] ?? 0) as num).toDouble()),
    );
    final totalInvoices = _customers.fold<int>(
      0,
      (sum, c) => sum + (((c['invoice_count'] ?? 0) as num).toInt()),
    );

    return DesktopPageScaffold(
      title: 'تقرير العملاء الشهري'.tr(),
      subtitle: 'الشهر: {_month} • {v2} عميل'.tr({'_month': _month, 'v2': _customers.length}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث البيانات'.tr(),
          onPressed: _loadCustomers,
        ),
      ],
      headerBottom: Row(
        children: [
          DesktopInfoChip(
            label: 'الشهر: {_month}'.tr({'_month': _month}),
            icon: Icons.calendar_month_outlined,
            color: palette.info,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: 'عدد العملاء: {v1}'.tr({'v1': _customers.length}),
            icon: Icons.people_outline,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: 'عدد الفواتير: {totalInvoices}'.tr({'totalInvoices': totalInvoices}),
            icon: Icons.receipt_long_outlined,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات الشهر ====================
          DesktopResponsiveGrid(
            minTileWidth: 250,
            maxColumns: 3,
            children: [
              DesktopStatCard(
                label: 'إجمالي مبيعات الشهر'.tr(),
                value: '{v1} ج'.tr({'v1': totalIncome.toStringAsFixed(2)}),
                icon: Icons.payments_outlined,
                color: palette.success,
                hint: 'مجموع فواتير كل العملاء'.tr(),
              ),
              DesktopStatCard(
                label: 'عدد العملاء'.tr(),
                value: '${_customers.length}',
                icon: Icons.people_outline,
                color: palette.info,
              ),
              DesktopStatCard(
                label: 'عدد الفواتير'.tr(),
                value: '$totalInvoices',
                icon: Icons.receipt_long_outlined,
                color: palette.accent,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== الجدول ====================
          DesktopSectionTitle(
            title: 'العملاء'.tr(),
            count: _customers.length,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(DesktopTokens.gapXl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_customers.isEmpty)
            DesktopEmptyState(
              icon: Icons.person_search_outlined,
              title: 'لا توجد بيانات لهذا الشهر'.tr(),
              message: 'مفيش فواتير مسجّلة على أي عميل في شهر {_month}.'.tr({'_month': _month}),
            )
          else ...[
            // رؤوس الأعمدة
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesktopTokens.gapMd,
                vertical: DesktopTokens.gapSm,
              ),
              child: Row(
                children: [
                  Expanded(flex: 5, child: _windowsHeaderCell(context, 'العميل'.tr())),
                  Expanded(
                    flex: 2,
                    child: _windowsHeaderCell(context, 'عدد الفواتير'.tr()),
                  ),
                  Expanded(
                    flex: 3,
                    child: _windowsHeaderCell(context, 'إجمالي المبيعات'.tr()),
                  ),
                  const SizedBox(width: 92),
                ],
              ),
            ),
            for (final c in _customers) ...[
              _windowsCustomerRow(context, c),
              const SizedBox(height: DesktopTokens.gapSm + 2),
            ],
            const SizedBox(height: DesktopTokens.gapSm),

            // ملخص الشهر
            DesktopCard(
              color: palette.accentSoft,
              borderColor: palette.accent.withValues(alpha: 0.35),
              child: Row(
                children: [
                  DesktopIconBadge(
                    icon: Icons.summarize_outlined,
                    color: palette.accent,
                  ),
                  const SizedBox(width: DesktopTokens.gapMd),
                  Expanded(
                    child: Text(
                      'ملخص شهر {_month}'.tr({'_month': _month}),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                    ),
                  ),
                  DesktopInfoChip(
                    label: '{totalInvoices} فاتورة'.tr({'totalInvoices': totalInvoices}),
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(width: DesktopTokens.gapMd),
                  Text(
                    '{v1} ج'.tr({'v1': totalIncome.toStringAsFixed(2)}),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.success,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _windowsHeaderCell(BuildContext context, String label) {
    final palette = DesktopPalette.of(context);
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: palette.textMuted,
            fontWeight: FontWeight.w800,
          ),
    );
  }

  /// صف عميل واحد — هوفر كامل + نفس إجراءات الموبايل (فتح/حذف).
  Widget _windowsCustomerRow(BuildContext context, Map<String, dynamic> c) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    final name = c['customer_name'] as String?;
    final invoiceCount = ((c['invoice_count'] ?? 0) as num).toInt();
    final income = ((c['total_income'] ?? 0) as num).toDouble();

    return DesktopCard(
      hover: true,
      onTap: name == null ? null : () => _showCustomerInvoices(name),
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                DesktopIconBadge(
                  icon: Icons.person_outline,
                  color: palette.info,
                  size: 38,
                  radius: DesktopTokens.radiusSm,
                ),
                const SizedBox(width: DesktopTokens.gapMd),
                Expanded(
                  child: Text(
                    name ?? 'بدون اسم'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: DesktopInfoChip(
                label: '{invoiceCount} فاتورة'.tr({'invoiceCount': invoiceCount}),
                icon: Icons.receipt_long_outlined,
                dense: true,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '{v1} ج'.tr({'v1': income.toStringAsFixed(2)}),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.success,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DesktopToolbarIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'مسح فواتير {v1} لهذا الشهر'.tr({'v1': name ?? 'العميل'.tr()}),
                  onPressed: () => _confirmDeleteCustomer(name),
                ),
                Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: palette.textMuted.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
