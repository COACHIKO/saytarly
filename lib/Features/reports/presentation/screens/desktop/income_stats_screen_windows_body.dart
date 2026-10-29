part of '../IncomeStatsScreen.dart';

/// صيغة المبالغ في شاشات تفاصيل الدخل — نفس صيغة الموبايل بالظبط.
String _fmtMoneyJ(double value) => '{v1} ج'.tr({'v1': value.toStringAsFixed(2)});

/// صف بيانات نضيف في شاشات سطح المكتب (أيقونة + عنوان + وصف + مبلغ).
class _DesktopDataRow extends StatelessWidget {
  const _DesktopDataRow({
    required this.title,
    required this.trailing,
    this.subtitle,
    this.icon,
    this.color,
  });

  final String title;
  final String trailing;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopCard(
      hover: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            DesktopIconBadge(
              icon: icon!,
              color: color,
              size: 34,
              radius: DesktopTokens.radiusSm,
            ),
            const SizedBox(width: DesktopTokens.gapSm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Text(
            trailing,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color ?? palette.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// جسم شاشة تقرير الدخل — نسخة الويندوز (Windows UI).
///
/// نفس الأرقام ونفس صفحات التفاصيل — بس كروت سطح مكتب بالهوفر.
extension _IncomeStatsWindowsBody on _IncomeStatsScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'تقرير الدخل'.tr(),
      subtitle: 'ملخص سريع لدخل اليوم والشيفت والدخل الكلي'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopResponsiveGrid(
            minTileWidth: 250,
            maxColumns: 4,
            children: [
              DesktopStatCard(
                label: 'اجمالي الفواتير'.tr(),
                value: sessionsCount.toString(),
                icon: Icons.receipt_long_outlined,
                color: palette.info,
                hint: 'إجمالي عدد الفواتير المسجلة'.tr(),
              ),
              DesktopStatCard(
                label: 'دخل اليوم'.tr(),
                value: incomeToday.toStringAsFixed(2),
                icon: Icons.today_outlined,
                color: palette.success,
                hint: 'اضغط لعرض تفاصيل اليوم'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TodayDetailsScreen()),
                ),
              ),
              DesktopStatCard(
                label: 'دخل الشيفت'.tr(),
                value: incomeShift.toStringAsFixed(2),
                icon: Icons.point_of_sale_outlined,
                color: palette.info,
                hint: 'اضغط لعرض حركات الشيفت'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShiftDetailsScreen()),
                ),
              ),
              DesktopStatCard(
                label: 'الدخل الكلي'.tr(),
                value: incomeShift.toStringAsFixed(2),
                icon: Icons.account_balance_wallet_outlined,
                color: palette.warning,
                hint: 'اضغط لعرض التفاصيل الكاملة'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TotalIncomeDetailsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapLg),
          DesktopCard(
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: palette.textMuted),
                const SizedBox(width: DesktopTokens.gapSm),
                Expanded(
                  child: Text(
                    'كل كارت بيفتح تفاصيل الدخل الخاصة بيه (اليوم / الشيفت / الكلي).'.tr(),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// جسم شاشة تفاصيل دخل اليوم — نسخة الويندوز (Windows UI).
extension _TodayDetailsWindowsBody on TodayDetailsScreen {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'تفاصيل دخل اليوم'.tr(),
      subtitle: 'فواتير اليوم • مداخل الكاش • المصروفات'.tr(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: loadData(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snap.hasData) {
            return  DesktopEmptyState(
              icon: Icons.inbox_outlined,
              title: 'لا توجد بيانات'.tr(),
            );
          }

          // نفس تسميات الموبايل بالظبط (ومعاها نفس التعامل مع المصدر الفاضي).
          String sourceLabel(dynamic source) {
            switch (source) {
              case 'debt':
                return 'الفلوس الاجله تم دفعها'.tr();
              case 'invoice':
                return 'فواتير'.tr();
              case 'topup':
                return 'شحن'.tr();
              default:
                return (source ?? 'آخر'.tr()).toString();
            }
          }

          final data = snap.data!;
          final invoices = data['invoices'] as List;
          final invoicesTotal = _toDouble(data['invoices_total']);
          final cashItems = data['cash_items'] as List;
          final cashTotals = Map<String, double>.from(
            data['cash_totals'] as Map,
          );
          final expenses = data['expenses'] as List;
          final expensesTotal = _toDouble(data['expenses_total']);
          final invoicesPaidTotal = invoices
              .where((i) => i['payment_type'] == 'paid')
              .fold<double>(0.0, (sum, i) => sum + _toDouble(i['total_cost']));
          final invoicesDebtTotal = invoices
              .where(
                (i) =>
                    i['payment_type'] == 'debt' ||
                    i['payment_type'] == 'علي الحساب',
              )
              .fold<double>(0.0, (sum, i) => sum + _toDouble(i['total_cost']));
          final net = invoicesPaidTotal + invoicesDebtTotal - expensesTotal;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== ملخص اليوم ====================
              DesktopResponsiveGrid(
                minTileWidth: 250,
                maxColumns: 4,
                children: [
                  DesktopStatCard(
                    label: 'مبيعات (فواتير مدفوعة)'.tr(),
                    value: invoicesTotal.toStringAsFixed(2),
                    icon: Icons.receipt_long_outlined,
                    color: palette.success,
                  ),
                  for (final entry in cashTotals.entries)
                    DesktopStatCard(
                      label: 'دخل: {v1}'.tr({'v1': sourceLabel(entry.key)}),
                      value: entry.value.toStringAsFixed(2),
                      icon: Icons.payments_outlined,
                      color: palette.info,
                    ),
                  DesktopStatCard(
                    label: 'المصروفات'.tr(),
                    value: expensesTotal.toStringAsFixed(2),
                    icon: Icons.money_off_outlined,
                    color: palette.danger,
                  ),
                  DesktopStatCard(
                    label: 'الصافي اليومي'.tr(),
                    value: net.toStringAsFixed(2),
                    icon: Icons.account_balance_wallet_outlined,
                    color: palette.accent,
                    hint: 'مدفوع + آجل − مصروفات'.tr(),
                  ),
                ],
              ),
               SizedBox(height: DesktopTokens.gapLg),

              // ==================== تفاصيل الفواتير ====================
              DesktopSectionTitle(
                title: 'تفاصيل الفواتير المصرّفة اليوم'.tr(),
                count: invoices.length,
              ),
              if (invoices.isEmpty)
                Text(
                  'لا توجد فواتير اليوم'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final inv in invoices) ...[
                  _DesktopDataRow(
                    title: 'فاتورة #{v1}'.tr({'v1': inv['id']}),
                    subtitle: inv['start_time'] != null
                        ? _formatArabicDateTime(inv['start_time']).toString()
                        : '',
                    trailing: _fmtMoneyJ(_toDouble(inv['total_cost'])),
                    icon: Icons.receipt_outlined,
                    color: palette.accent,
                  ),
                   SizedBox(height: DesktopTokens.gapSm),
                ],
               SizedBox(height: DesktopTokens.gapMd),

              // ==================== تفاصيل مداخل الكاش ====================
              DesktopSectionTitle(
                title: 'تفاصيل مداخل الكاش (اليوم)'.tr(),
                count: cashItems.length,
              ),
              if (cashItems.isEmpty)
                Text(
                  'لا توجد مداخل كاش اليوم'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final item in cashItems) ...[
                  _DesktopDataRow(
                    title: sourceLabel(item['source']),
                    subtitle:
                        '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(item['date']), 'v2': item['cashier'] ?? '-'}),
                    trailing: _fmtMoneyJ(_toDouble(item['amount'])),
                    icon: Icons.payments_outlined,
                    color: palette.info,
                  ),
                   SizedBox(height: DesktopTokens.gapSm),
                ],
               SizedBox(height: DesktopTokens.gapMd),

              // ==================== تفاصيل المصروفات ====================
              DesktopSectionTitle(
                title: 'تفاصيل المصروفات (اليوم)'.tr(),
                count: expenses.length,
              ),
              if (expenses.isEmpty)
                Text(
                  'لا توجد مصروفات اليوم'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final expense in expenses) ...[
                  _DesktopDataRow(
                    title:
                        '{v1}'.tr({'v1': expense['description'] ?? expense['note'] ?? 'مصروف'.tr()}),
                    subtitle:
                        '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(expense['date']), 'v2': expense['added_by'] ?? '-'}),
                    trailing: '- ${_fmtMoneyJ(_toDouble(expense['amount']))}',
                    icon: Icons.money_off_outlined,
                    color: palette.danger,
                  ),
                  const SizedBox(height: DesktopTokens.gapSm),
                ],
            ],
          );
        },
      ),
    );
  }
}

/// جسم شاشة تفاصيل دخل الشيفت — نسخة الويندوز (Windows UI).
extension _ShiftDetailsWindowsBody on ShiftDetailsScreen {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'تفاصيل دخل الشيفت'.tr(),
      subtitle: 'كل حركات الكاش الداخل (income)'.tr(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadShiftItems(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snap.hasData) {
            return  DesktopEmptyState(
              icon: Icons.inbox_outlined,
              title: 'لا توجد بيانات'.tr(),
            );
          }

          String sourceLabel(dynamic source) {
            switch (source) {
              case 'debt':
                return 'الفلوس الاجله تم دفعها'.tr();
              case 'invoice':
                return 'فاتورة'.tr();
              case 'topup':
                return 'شحن'.tr();
              default:
                return (source ?? 'آخر'.tr()).toString();
            }
          }

          final rows = snap.data!;
          // نفس مجاميع الموبايل: حسب المصدر + المجموع الكلي.
          final sums = <String, double>{};
          double total = 0.0;
          for (final row in rows) {
            final src = sourceLabel(row['source']);
            final amount = _toDouble(row['amount']);
            sums[src] = (sums[src] ?? 0.0) + amount;
            total += amount;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopResponsiveGrid(
                minTileWidth: 250,
                maxColumns: 4,
                children: [
                  DesktopStatCard(
                    label: 'المجموع الكلي للشيفت'.tr(),
                    value: total.toStringAsFixed(2),
                    icon: Icons.account_balance_wallet_outlined,
                    color: palette.accent,
                    hint: '{v1} حركة'.tr({'v1': rows.length}),
                  ),
                  DesktopStatCard(
                    label: 'عدد الحركات'.tr(),
                    value: '${rows.length}',
                    icon: Icons.list_alt_outlined,
                    color: palette.info,
                  ),
                ],
              ),
               SizedBox(height: DesktopTokens.gapLg),

              // ==================== ملخص الشيفت ====================
               DesktopSectionTitle(title: 'ملخص الشيفت'.tr()),
              DesktopCard(
                child: Column(
                  children: [
                    for (final entry in sums.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'دخل: {v1}'.tr({'v1': entry.key}),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              _fmtMoneyJ(entry.value),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sums.isNotEmpty)
                      Divider(color: palette.border, height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'المجموع الكلي للشيفت'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _fmtMoneyJ(total),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: palette.accentText,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
               SizedBox(height: DesktopTokens.gapLg),

              // ==================== كل الحركات ====================
              DesktopSectionTitle(title: 'كل الحركات'.tr(), count: rows.length),
              if (rows.isEmpty)
                Text(
                  'لا توجد حركات في الشيفت'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final row in rows) ...[
                  _DesktopDataRow(
                    title: sourceLabel(row['source']),
                    subtitle: _formatArabicDateTime(row['date']),
                    trailing: _fmtMoneyJ(_toDouble(row['amount'])),
                    icon: Icons.payments_outlined,
                    color: palette.info,
                  ),
                  const SizedBox(height: DesktopTokens.gapSm),
                ],
            ],
          );
        },
      ),
    );
  }
}

/// جسم شاشة تفاصيل الدخل الكلي — نسخة الويندوز (Windows UI).
extension _TotalIncomeDetailsWindowsBody on TotalIncomeDetailsScreen {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'تفاصيل الدخل الكلي'.tr(),
      subtitle: 'فواتير مدفوعة + شحنات + دفعات ديون + مصروفات'.tr(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: loadAll(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snap.hasData) {
            return  DesktopEmptyState(
              icon: Icons.inbox_outlined,
              title: 'لا توجد بيانات'.tr(),
            );
          }

          String sourceLabel(dynamic source) {
            switch (source) {
              case 'debt':
                return 'الفلوس الاجله تم دفعها'.tr();
              case 'invoice':
                return 'فاتورة'.tr();
              case 'topup':
                return 'شحن'.tr();
              default:
                return (source ?? 'آخر'.tr()).toString();
            }
          }

          final data = snap.data!;
          final invoices = data['invoices'] as List;
          final expenses = data['expenses'] as List;
          final totalInvoices = _toDouble(data['total_invoices']);
          final totalTopups = _toDouble(data['total_topups']);
          final totalExpenses = _toDouble(data['total_expenses']);
          final topupsList = data['topups_list'] as List;
          final debtList = data['debt_list'] as List;
          final totalDebtPayments = _toDouble(data['total_debt_payments']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== ملخص إجمالي ====================
              DesktopResponsiveGrid(
                minTileWidth: 250,
                maxColumns: 4,
                children: [
                  DesktopStatCard(
                    label: 'إجمالي الفواتير (مدفوعة)'.tr(),
                    value: totalInvoices.toStringAsFixed(2),
                    icon: Icons.receipt_long_outlined,
                    color: palette.success,
                    hint: '{v1} فاتورة'.tr({'v1': invoices.length}),
                  ),
                  DesktopStatCard(
                    label: 'إجمالي الشحنات (Topups)'.tr(),
                    value: totalTopups.toStringAsFixed(2),
                    icon: Icons.add_card_outlined,
                    color: palette.info,
                    hint: '{v1} عملية شحن'.tr({'v1': topupsList.length}),
                  ),
                  DesktopStatCard(
                    label: 'إجمالي دفعات الديون'.tr(),
                    value: totalDebtPayments.toStringAsFixed(2),
                    icon: Icons.payments_outlined,
                    color: palette.accent,
                    hint: '{v1} دفعة'.tr({'v1': debtList.length}),
                  ),
                  DesktopStatCard(
                    label: 'إجمالي المصروفات'.tr(),
                    value: totalExpenses.toStringAsFixed(2),
                    icon: Icons.money_off_outlined,
                    color: palette.danger,
                    hint: '{v1} مصروف'.tr({'v1': expenses.length}),
                  ),
                ],
              ),
               SizedBox(height: DesktopTokens.gapLg),

              // ==================== الفواتير (مدفوعة) ====================
              DesktopSectionTitle(
                title: 'الفواتير (مدفوعة)'.tr(),
                count: invoices.length,
              ),
              if (invoices.isEmpty)
                Text(
                  'لا توجد فواتير'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final inv in invoices) ...[
                  _DesktopDataRow(
                    title: 'فاتورة #{v1}'.tr({'v1': inv['id']}),
                    subtitle: _formatArabicDateTime(
                      inv['start_time'] ?? inv['date'],
                    ),
                    trailing: _fmtMoneyJ(_toDouble(inv['total_cost'])),
                    icon: Icons.receipt_outlined,
                    color: palette.accent,
                  ),
                   SizedBox(height: DesktopTokens.gapSm),
                ],
               SizedBox(height: DesktopTokens.gapMd),

              // ==================== الشحنات ====================
              DesktopSectionTitle(
                title: 'الشحنات'.tr(),
                count: topupsList.length,
              ),
              if (topupsList.isEmpty)
                Text(
                  'لا توجد شحنات'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final topup in topupsList) ...[
                  _DesktopDataRow(
                    title: sourceLabel(topup['source']),
                    subtitle: _formatArabicDateTime(topup['date']),
                    trailing: _fmtMoneyJ(_toDouble(topup['amount'])),
                    icon: Icons.add_card_outlined,
                    color: palette.info,
                  ),
                   SizedBox(height: DesktopTokens.gapSm),
                ],
               SizedBox(height: DesktopTokens.gapMd),

              // ==================== دفعات الديون ====================
              DesktopSectionTitle(
                title: 'دفعات الديون'.tr(),
                count: debtList.length,
              ),
              if (debtList.isEmpty)
                Text(
                  'لا توجد دفعات ديون'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final debt in debtList) ...[
                  _DesktopDataRow(
                    title: sourceLabel(debt['source']),
                    subtitle:
                        '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(debt['date']), 'v2': debt['cashier'] ?? '-'}),
                    trailing: _fmtMoneyJ(_toDouble(debt['amount'])),
                    icon: Icons.payments_outlined,
                    color: palette.accent,
                  ),
                   SizedBox(height: DesktopTokens.gapSm),
                ],
               SizedBox(height: DesktopTokens.gapMd),

              // ==================== المصروفات ====================
              DesktopSectionTitle(
                title: 'المصروفات'.tr(),
                count: expenses.length,
              ),
              if (expenses.isEmpty)
                Text(
                  'لا توجد مصروفات'.tr(),
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                )
              else
                for (final expense in expenses) ...[
                  _DesktopDataRow(
                    title:
                        '{v1}'.tr({'v1': expense['description'] ?? expense['note'] ?? 'مصروف'.tr()}),
                    subtitle:
                        '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(expense['date']), 'v2': expense['added_by'] ?? '-'}),
                    trailing: '- ${_fmtMoneyJ(_toDouble(expense['amount']))}',
                    icon: Icons.money_off_outlined,
                    color: palette.danger,
                  ),
                  const SizedBox(height: DesktopTokens.gapSm),
                ],
            ],
          );
        },
      ),
    );
  }
}
