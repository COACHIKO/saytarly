part of '../ShiftDetailsPage.dart';

/// أرقام الملخص المالي للشيفت — بنفس معادلات نسخة الموبايل بالظبط.
class _ShiftSummaryNumbers {
  const _ShiftSummaryNumbers({
    required this.devices,
    required this.drinks,
    required this.products,
    required this.cigarettes,
    required this.shisha,
    required this.expenses,
    required this.debt,
    required this.collected,
    required this.openValue,
    required this.vodafone,
    required this.transactions,
    required this.discounts,
    required this.grandTotal,
    required this.grandTotalAfterDiscounts,
  });

  final double devices;
  final double drinks;
  final double products;
  final double cigarettes;
  final double shisha;
  final double expenses;
  final double debt;
  final double collected;
  final double openValue;
  final double vodafone;
  final double transactions;
  final double discounts;
  final double grandTotal;
  final double grandTotalAfterDiscounts;
}

/// جسم تفاصيل الشيفت — نسخة الويندوز (Windows UI).
///
/// ملخص مالي (بنفس حماية كلمة المرور)، أصناف، فواتير، مصروفات، وآجل —
/// كلها كروت سطح مكتب بنفس الـ dialogs والطباعة الموجودة بالظبط.
extension _ShiftDetailsPageWindowsBody on _ShiftDetailsPageState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'تفاصيل شيفت {v1}'.tr({'v1': widget.staffName}),
      subtitle: 'الفواتير • الأصناف • المصروفات • الآجل'.tr(),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث البيانات'.tr(),
          onPressed: () => _reload(),
        ),
        DesktopButton.primary(
          label: 'إضافة فودافون كاش'.tr(),
          icon: Icons.phone_android_outlined,
          onPressed: () => _addVodafoneCashNote(),
        ),
      ],
      headerBottom: Wrap(
        spacing: DesktopTokens.gapSm,
        runSpacing: DesktopTokens.gapSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DesktopInfoChip(
            label: '{v1} فاتورة'.tr({'v1': invoices.length}),
            icon: Icons.receipt_long_outlined,
            color: palette.accentText,
          ),
          DesktopInfoChip(
            label: '{v1} فاتورة مفتوحة'.tr({
              'v1': invoices.where((inv) => inv['is_open'] == true).length,
            }),
            icon: Icons.play_circle_outline,
            color: palette.warning,
          ),
          DesktopInfoChip(
            label: '{v1} آجل'.tr({
              'v1':
                  debts
                      .where(
                        (d) => ((d['remaining_amount'] as double?) ?? 0) > 0,
                      )
                      .length,
            }),
            icon: Icons.schedule_outlined,
            color: palette.danger,
          ),
          DesktopInfoChip(
            label: '{v1} مصروف'.tr({'v1': expenses.length}),
            icon: Icons.money_off_outlined,
            color: palette.warning,
          ),
          if (vodafoneCashTotal > 0)
            DesktopInfoChip(
              label: 'فودافون كاش: {v1}'.tr({'v1': _money(vodafoneCashTotal)}),
              icon: Icons.phone_android_outlined,
              color: palette.accent,
            ),
        ],
      ),
      child: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return DesktopEmptyState(
              icon: Icons.error_outline,
              title: 'حدث خطأ أثناء تحميل البيانات'.tr(),
              message: '${snapshot.error}',
              action: DesktopButton.ghost(
                label: 'إعادة المحاولة'.tr(),
                icon: Icons.refresh,
                onPressed: () => _reload(),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== الملخص المالي ====================
              if (!canViewSummary)
                _windowsSummaryLocked(context)
              else
                _windowsSummaryGrid(context),
              SizedBox(height: DesktopTokens.gapLg),

              // ==================== الأصناف والمنتجات ====================
              DesktopSectionTitle(
                title: 'الأصناف والمنتجات المباعة'.tr(),
                count: productsSummary.length,
              ),
              if (productsSummary.isEmpty)
                DesktopEmptyState(
                  icon: Icons.fastfood_outlined,
                  title: 'لا توجد أصناف مباعة في هذا الشيفت'.tr(),
                )
              else
                _windowsProductsGrid(context),
              SizedBox(height: DesktopTokens.gapLg),

              // ==================== الفواتير ====================
              DesktopSectionTitle(
                title: 'الفواتير'.tr(),
                count: invoices.length,
              ),
              if (invoices.isEmpty)
                DesktopEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'لا توجد فواتير في هذا الشيفت'.tr(),
                )
              else
                ...invoices.map((inv) => _windowsInvoiceCard(context, inv)),
              SizedBox(height: DesktopTokens.gapLg),

              // ==================== المصروفات ====================
              DesktopSectionTitle(
                title: 'المصروفات'.tr(),
                count: expenses.length,
              ),
              if (expenses.isEmpty)
                DesktopEmptyState(
                  icon: Icons.money_off_outlined,
                  title: 'لا توجد مصروفات مسجلة'.tr(),
                )
              else
                ...expenses.map((e) => _windowsExpenseCard(context, e)),
              SizedBox(height: DesktopTokens.gapLg),

              // ==================== الآجل ====================
              DesktopSectionTitle(title: 'الآجل'.tr(), count: debts.length),
              if (debts.isEmpty)
                DesktopEmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'لا توجد ديون آجلة'.tr(),
                )
              else
                ...debts.map((d) => _windowsDebtCard(context, d)),
              SizedBox(height: DesktopTokens.gapLg),

              // ==================== محصّل من الآجل ====================
              DesktopSectionTitle(
                title: 'محصّل من الآجل'.tr(),
                count: debtPayments.length,
              ),
              if (totalOpenPartialCollected > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
                  child: DesktopCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesktopTokens.gapMd,
                      vertical: DesktopTokens.gapSm + 2,
                    ),
                    child: Row(
                      children: [
                        DesktopIconBadge(
                          icon: Icons.price_check,
                          color: palette.success,
                          size: 36,
                        ),
                        const SizedBox(width: DesktopTokens.gapSm),
                        Expanded(
                          child: Text(
                            'محصّل جزئيًا من ترابيزات لسه شغالة'.tr(),
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _money(totalOpenPartialCollected),
                          style: TextStyle(
                            color: palette.success,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (debtPayments.isEmpty)
                DesktopEmptyState(
                  icon: Icons.price_check,
                  title: 'لا يوجد تحصيل في هذا الشيفت'.tr(),
                )
              else
                ...debtPayments.map((p) => _windowsDebtPaymentCard(context, p)),
              const SizedBox(height: DesktopTokens.gapLg),
            ],
          );
        },
      ),
    );
  }

  // ==================================================================
  // الملخص المالي
  // ==================================================================

  /// الملخص مقفول — نفس حماية كلمة المرور اللي في الموبايل.
  Widget _windowsSummaryLocked(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopCard(
      padding: const EdgeInsets.all(DesktopTokens.gapLg),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.lock_outline,
            color: palette.warning,
            size: 48,
            radius: DesktopTokens.radiusMd,
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الملخص المالي محمي'.tr(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أدخل كلمة مرور الكاشير لعرض تفاصيل المبيعات والتحصيل.'.tr(),
                  style: TextStyle(color: palette.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          DesktopButton.primary(
            label: 'عرض الملخص المالي'.tr(),
            icon: Icons.lock_open_outlined,
            onPressed: () async {
              final ok = await _confirmCashierPassword(context);
              if (ok) {
                _refresh(() => canViewSummary = true);
              }
            },
          ),
        ],
      ),
    );
  }

  /// شبكة المؤشرات المالية — نفس أرقام `_summaryContent` بتاعة الموبايل.
  Widget _windowsSummaryGrid(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final n = _windowsSummaryNumbers();

    return DesktopResponsiveGrid(
      minTileWidth: 225,
      maxColumns: 6,
      children: [
        DesktopStatCard(
          label: 'إجمالي الأجهزة'.tr(),
          value: _money(n.devices),
          icon: Icons.sports_esports_outlined,
          color: palette.info,
          hint: 'نصيب البلايستيشن من المدفوع'.tr(),
        ),
        DesktopStatCard(
          label: 'إجمالي المشروبات'.tr(),
          value: _money(n.drinks),
          icon: Icons.local_cafe_outlined,
          color: palette.accent,
          hint: 'نصيب المشروبات من المدفوع'.tr(),
        ),
        if (n.products > 0)
          DesktopStatCard(
            label: 'إجمالي المنتجات/المأكولات'.tr(),
            value: _money(n.products),
            icon: Icons.fastfood_outlined,
            color: palette.success,
          ),
        if (n.cigarettes > 0)
          DesktopStatCard(
            label: 'إجمالي السجائر'.tr(),
            value: _money(n.cigarettes),
            icon: Icons.smoking_rooms_outlined,
            color: palette.warning,
          ),
        if (n.shisha > 0)
          DesktopStatCard(
            label: 'إجمالي الشيشة'.tr(),
            value: _money(n.shisha),
            icon: Icons.blur_on,
            color: palette.info,
          ),
        if (n.transactions > 0)
          DesktopStatCard(
            label: 'إجمالي الحركات'.tr(),
            value: _money(n.transactions),
            icon: Icons.swap_horiz,
            color: palette.textSecondary,
          ),
        DesktopStatCard(
          label: 'المصروفات'.tr(),
          value: _money(n.expenses),
          icon: Icons.money_off_outlined,
          color: palette.danger,
          hint: '{v1} مصروف'.tr({'v1': expenses.length}),
        ),
        DesktopStatCard(
          label: 'الآجل'.tr(),
          value: _money(n.debt),
          icon: Icons.schedule_outlined,
          color: palette.danger,
          hint: '{v1} دين'.tr({'v1': debts.length}),
        ),
        DesktopStatCard(
          label: 'محصّل من الآجل'.tr(),
          value: _money(n.collected),
          icon: Icons.price_check,
          color: palette.success,
          hint: '{v1} عملية'.tr({'v1': debtPayments.length}),
        ),
        if (n.openValue > 0)
          DesktopStatCard(
            label: 'قيمة الترابيزات المفتوحة'.tr(),
            value: _money(n.openValue),
            icon: Icons.hourglass_top,
            color: palette.warning,
            hint: 'لسه شغالة'.tr(),
          ),
        if (n.vodafone > 0)
          DesktopStatCard(
            label: 'فودافون كاش'.tr(),
            value: _money(n.vodafone),
            icon: Icons.phone_android_outlined,
            color: palette.accent,
            hint: 'معلومة فقط'.tr(),
          ),
        DesktopStatCard(
          label: 'المجموع الكلي'.tr(),
          value: _money(n.grandTotal),
          icon: Icons.summarize_outlined,
          color: palette.accent,
          hint:
              n.discounts > 0
                  ? 'بعد الخصومات: {v1}'.tr({
                    'v1': _money(n.grandTotalAfterDiscounts),
                  })
                  : 'من غير خصومات'.tr(),
        ),
      ],
    );
  }

  /// حساب أرقام الملخص — منقولة حرفيًا من `_summaryContent`.
  _ShiftSummaryNumbers _windowsSummaryNumbers() {
    double paidFraction(Map<String, dynamic> inv, double cost) {
      final totalCost = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;
      final paidPartial = (inv['paid_partial'] as num?)?.toDouble() ?? 0.0;
      final fraction = totalCost > 0 ? paidPartial / totalCost : 0.0;
      return cost * fraction;
    }

    final totalDevicesPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum +
          paidFraction(inv, (inv['device_cost'] as num?)?.toDouble() ?? 0.0);
    });
    final totalDrinksPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum +
          paidFraction(inv, (inv['drinks_cost'] as num?)?.toDouble() ?? 0.0);
    });
    final totalProductsPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum +
          paidFraction(inv, (inv['products_cost'] as num?)?.toDouble() ?? 0.0);
    });
    final totalCigarettes = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum +
          paidFraction(
            inv,
            (inv['cigarettes_cost'] as num?)?.toDouble() ?? 0.0,
          );
    });
    final totalShisha = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum +
          paidFraction(inv, (inv['shisha_cost'] as num?)?.toDouble() ?? 0.0);
    });
    final totalOpenValue = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['is_open'] != true) return sum;
      return sum + ((inv['total_cost'] as num?)?.toDouble() ?? 0.0);
    });
    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );
    final totalTransactions = transactions.fold<double>(
      0.0,
      (sum, t) => sum + ((t['received'] as num?)?.toDouble() ?? 0.0),
    );
    final totalDebts = debts.fold<double>(
      0.0,
      (sum, d) => sum + ((d['remaining_amount'] as double?) ?? 0.0),
    );
    final totalDiscounts = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum +
          paidFraction(inv, (inv['discount'] as num?)?.toDouble() ?? 0.0);
    });

    final grandTotal =
        totalDevicesPaid +
        totalDrinksPaid +
        totalProductsPaid +
        totalCigarettes +
        totalShisha +
        totalTransactions +
        totalDebtCollected -
        totalExpenses;
    final grandTotaldis = grandTotal - totalDiscounts;

    return _ShiftSummaryNumbers(
      devices: totalDevicesPaid,
      drinks: totalDrinksPaid,
      products: totalProductsPaid,
      cigarettes: totalCigarettes,
      shisha: totalShisha,
      expenses: totalExpenses,
      debt: totalDebts,
      collected: totalDebtCollected,
      openValue: totalOpenValue,
      vodafone: vodafoneCashTotal,
      transactions: totalTransactions,
      discounts: totalDiscounts,
      grandTotal: grandTotal,
      grandTotalAfterDiscounts: grandTotaldis,
    );
  }

  // ==================================================================
  // الأصناف والمنتجات
  // ==================================================================

  Widget _windowsProductsGrid(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final totalQty = productsSummary.fold<int>(
      0,
      (sum, p) => sum + ((p['total_qty'] ?? 0) as num).toInt(),
    );
    final totalAmount = productsSummary.fold<double>(
      0.0,
      (sum, p) => sum + ((p['total_amount'] ?? 0) as num).toDouble(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
          child: Wrap(
            spacing: DesktopTokens.gapSm,
            runSpacing: DesktopTokens.gapSm,
            children: [
              DesktopInfoChip(
                label: 'إجمالي القطع المباعة: {totalQty}'.tr({
                  'totalQty': totalQty,
                }),
                icon: Icons.inventory_2_outlined,
                color: palette.accentText,
              ),
              DesktopInfoChip(
                label: 'إجمالي القيمة: {v1}'.tr({'v1': _money(totalAmount)}),
                icon: Icons.payments_outlined,
                color: palette.success,
              ),
            ],
          ),
        ),
        DesktopResponsiveGrid(
          minTileWidth: 250,
          maxColumns: 5,
          children: [
            for (final p in productsSummary)
              DesktopCard(
                hover: true,
                padding: const EdgeInsets.all(DesktopTokens.gapMd),
                child: Row(
                  children: [
                    DesktopIconBadge(
                      icon: _windowsProductIcon(
                        (p['category'] ?? '').toString(),
                      ),
                      color: palette.accent,
                    ),
                    const SizedBox(width: DesktopTokens.gapSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (p['product_name'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'سعر الوحدة: {v1} {v2}'.tr({
                              'v1': ((p['unit_price'] ?? 0) as num)
                                  .toDouble()
                                  .toStringAsFixed(2),
                              'v2': Money.txt,
                            }),
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: DesktopTokens.gapXs),
                    DesktopInfoChip(
                      label: 'x${((p['total_qty'] ?? 0) as num).toInt()}',
                      color: palette.textSecondary,
                      dense: true,
                    ),
                    const SizedBox(width: DesktopTokens.gapSm),
                    Text(
                      _money(((p['total_amount'] ?? 0) as num).toDouble()),
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  IconData _windowsProductIcon(String category) {
    if (category == 'cigarette') return Icons.smoking_rooms_outlined;
    if (category == 'shisha') return Icons.blur_on;
    if (category == 'prodect' || category == 'cold') {
      return Icons.fastfood_outlined;
    }
    return Icons.local_cafe_outlined;
  }

  // ==================================================================
  // الفواتير
  // ==================================================================

  Widget _windowsInvoiceCard(BuildContext context, Map<String, dynamic> inv) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    final paymentType = inv['payment_type'];
    final isCancelled = paymentType == 'ملغي';
    final remainingDebt = (inv['remaining_debt'] as double?) ?? 0.0;
    final isOpen = inv['is_open'] == true;
    final canCancel = !isCancelled && !isOpen && remainingDebt > 0;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isCancelled) {
      statusColor = _ShiftDetailsPageState.cancelColor;
      statusLabel = 'ملغي'.tr();
      statusIcon = Icons.cancel_outlined;
    } else if (isOpen) {
      statusColor = palette.info;
      statusLabel = 'جاري الآن'.tr();
      statusIcon = Icons.play_circle_outline;
    } else if (remainingDebt > 0) {
      statusColor = _ShiftDetailsPageState.debtColor;
      statusLabel = 'آجل'.tr();
      statusIcon = Icons.schedule_outlined;
    } else {
      statusColor = _ShiftDetailsPageState.paidColor;
      statusLabel = 'مدفوع'.tr();
      statusIcon = Icons.check_circle_outline;
    }

    final total = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;
    final paidPartial = (inv['paid_partial'] as num?)?.toDouble() ?? 0.0;

    return DesktopCard(
      margin: const EdgeInsets.only(bottom: DesktopTokens.gapSm + 2),
      padding: const EdgeInsets.all(DesktopTokens.gapMd),
      borderColor: statusColor.withValues(alpha: 0.45),
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DesktopIconBadge(
                icon: Icons.person_outline,
                color: palette.accent,
                size: 36,
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              Expanded(
                child: Text(
                  (inv['customer_name'] ?? 'غير معروف'.tr()).toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
              ),
              DesktopInfoChip(
                label: (paymentType ?? '-').toString(),
                color: palette.textSecondary,
                dense: true,
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              DesktopInfoChip(
                label: statusLabel,
                icon: statusIcon,
                color: statusColor,
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              DesktopToolbarIconButton(
                icon: Icons.print_outlined,
                tooltip: 'طباعة الفاتورة'.tr(),
                onPressed: () => _windowsPrintInvoice(context, inv),
              ),
              DesktopToolbarIconButton(
                icon: Icons.info_outline,
                tooltip: 'تفاصيل الفاتورة'.tr(),
                onPressed: () => _showInvoiceDetails(inv),
              ),
              DesktopToolbarIconButton(
                icon: Icons.history,
                tooltip: 'سجل تعديلات هذه الفاتورة'.tr(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AuditLogScreen(
                            invoiceId: inv['id'] as int,
                            title: 'سجل تعديلات الفاتورة #{v1}'.tr({
                              'v1': inv['id'],
                            }),
                          ),
                    ),
                  );
                },
              ),
              if (canCancel)
                DesktopToolbarIconButton(
                  icon: Icons.delete_forever_outlined,
                  tooltip: 'إلغاء الفاتورة نهائيًا'.tr(),
                  onPressed: () => _handleCancelDebtInvoice(inv),
                ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapSm + 2),
          Wrap(
            spacing: DesktopTokens.gapSm,
            runSpacing: DesktopTokens.gapSm,
            children: [
              DesktopInfoChip(
                label: 'بلايستيشن: {v1}'.tr({
                  'v1': _money(((inv['device_cost'] ?? 0) as num).toDouble()),
                }),
                icon: Icons.sports_esports_outlined,
                color: palette.textSecondary,
                dense: true,
              ),
              DesktopInfoChip(
                label: 'مشروبات: {v1}'.tr({
                  'v1': _money(((inv['drinks_cost'] ?? 0) as num).toDouble()),
                }),
                icon: Icons.local_cafe_outlined,
                color: palette.textSecondary,
                dense: true,
              ),
              if (((inv['products_cost'] ?? 0) as num).toDouble() != 0)
                DesktopInfoChip(
                  label: 'منتجات: {v1}'.tr({
                    'v1': _money(
                      ((inv['products_cost'] ?? 0) as num).toDouble(),
                    ),
                  }),
                  icon: Icons.fastfood_outlined,
                  color: palette.textSecondary,
                  dense: true,
                ),
              if (((inv['cigarettes_cost'] ?? 0) as num).toDouble() != 0)
                DesktopInfoChip(
                  label: 'سجائر: {v1}'.tr({
                    'v1': _money(
                      ((inv['cigarettes_cost'] ?? 0) as num).toDouble(),
                    ),
                  }),
                  icon: Icons.smoking_rooms_outlined,
                  color: palette.textSecondary,
                  dense: true,
                ),
              if (((inv['shisha_cost'] ?? 0) as num).toDouble() != 0)
                DesktopInfoChip(
                  label: 'شيشة: {v1}'.tr({
                    'v1': _money(((inv['shisha_cost'] ?? 0) as num).toDouble()),
                  }),
                  icon: Icons.blur_on,
                  color: palette.textSecondary,
                  dense: true,
                ),
              if ((inv['discount'] ?? 0) != 0)
                DesktopInfoChip(
                  label: 'خصم: {v1}'.tr({
                    'v1': _money(((inv['discount'] ?? 0) as num).toDouble()),
                  }),
                  icon: Icons.discount_outlined,
                  color: palette.warning,
                  dense: true,
                ),
              DesktopInfoChip(
                label: 'الإجمالي: {v1}'.tr({'v1': _money(total)}),
                icon: Icons.payments_outlined,
                color: palette.accentText,
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: palette.textMuted),
              const SizedBox(width: DesktopTokens.gapXs),
              Expanded(
                child: Text(
                  'من {v1}  إلى  {v2}'.tr({
                    'v1': formatDate(inv['start_time']),
                    'v2': formatDate(inv['end_time']),
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                ),
              ),
              if (remainingDebt > 0)
                DesktopInfoChip(
                  label: 'مدفوع جزئيًا: {v1}  |  الباقي: {v2}'.tr({
                    'v1': _money(paidPartial),
                    'v2': _money(remainingDebt),
                  }),
                  icon: Icons.info_outline,
                  color: _ShiftDetailsPageState.debtColor,
                ),
              if (isOpen && paidPartial > 0) ...[
                const SizedBox(width: DesktopTokens.gapSm),
                DesktopInfoChip(
                  label: 'محصّل جزئيًا (والترابيزة لسه شغالة): {v1}'.tr({
                    'v1': _money(paidPartial),
                  }),
                  icon: Icons.price_check,
                  color: _ShiftDetailsPageState.collectedColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// طباعة الفاتورة — نفس منطق زرار الطباعة في نسخة الموبايل.
  Future<void> _windowsPrintInvoice(
    BuildContext context,
    Map<String, dynamic> inv,
  ) async {
    try {
      final consoleId = inv['console_id'] as int?;
      final deviceCost = ((inv['device_cost'] ?? 0) as num).toDouble();

      if (consoleId != null && deviceCost > 0) {
        final db = await DBHelper.database;

        final start = DateTime.tryParse(inv['start_time']?.toString() ?? '');
        final end = DateTime.tryParse(inv['end_time']?.toString() ?? '');
        final totalPausedSeconds = (inv['total_paused_seconds'] as int?) ?? 0;

        double duration = 0;
        if (start != null && end != null) {
          final rawSeconds = end.difference(start).inSeconds;
          final effectiveSeconds = rawSeconds - totalPausedSeconds;
          duration = effectiveSeconds / 3600.0;
        }

        final drinksCost = ((inv['drinks_cost'] ?? 0) as num).toDouble();
        final discount = ((inv['discount'] ?? 0) as num).toDouble();
        final total = deviceCost + drinksCost;

        final drinkItemsRaw = await db.query(
          'invoice_items',
          where: 'invoice_id = ? AND item_type != ?',
          whereArgs: [inv['id'], 'playstation'],
        );
        final drinksList =
            drinkItemsRaw
                .map(
                  (e) => {
                    'name': e['drink_name'] ?? 'غير معروف'.tr(),
                    'qty': e['qty'] ?? 1,
                    'total': e['total'] ?? 0.0,
                  },
                )
                .toList();

        final consoleName = consoleNames[consoleId] ?? 'غير معروف'.tr();

        await PlaystationInvoicePrinter.printSession(
          staffName: widget.staffName,
          consoleName: consoleName,
          duration: duration,
          deviceCost: deviceCost,
          drinksCost: drinksCost,
          total: total,
          discount: discount,
          drinks: drinksList,
        );
      } else {
        await DrinksInvoicePrinter.printInvoice(
          inv['id'] as int,
          discount: ((inv['discount'] ?? 0) as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ فشلت طباعة الفاتورة: $e');
      AppToast.show('حصلت مشكلة في الطباعة'.tr());
    }
  }

  // ==================================================================
  // المصروفات
  // ==================================================================

  Widget _windowsExpenseCard(BuildContext context, Map<String, dynamic> e) {
    final palette = DesktopPalette.of(context);

    return DesktopCard(
      margin: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.remove_circle_outline,
            color: _ShiftDetailsPageState.debtColor,
            size: 38,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${e['description']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تمت في: {v1} بواسطة: {v2}'.tr({
                    'v1': formatDate(e['date']),
                    'v2': e['added_by'],
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Text(
            _money(((e['amount'] as num?) ?? 0).toDouble()),
            style: const TextStyle(
              color: _ShiftDetailsPageState.debtColor,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // الآجل
  // ==================================================================

  Widget _windowsDebtCard(BuildContext context, Map<String, dynamic> d) {
    final palette = DesktopPalette.of(context);

    final totalAmount = (d['total_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPaidPartial = (d['paid_partial'] as double?) ?? 0.0;
    final remaining =
        (d['remaining_amount'] as double?) ?? (totalAmount - totalPaidPartial);

    return DesktopCard(
      margin: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      borderColor: palette.accent.withValues(alpha: 0.35),
      hover: true,
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.schedule_outlined,
            color: palette.accent,
            size: 38,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (d['customer_name'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'المتبقي: {v1} {v2}  |  تاريخ: {v3}'.tr({
                    'v1': remaining.toStringAsFixed(2),
                    'v2': Money.txt,
                    'v3': formatDate(d['date']),
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _ShiftDetailsPageState.debtColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: (d['type'] ?? '').toString(),
            color: palette.accentText,
            dense: true,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopToolbarIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'تعديل الدين'.tr(),
            onPressed: () => _openEditDebt(d),
          ),
          DesktopToolbarIconButton(
            icon: Icons.delete_forever_outlined,
            tooltip: 'إلغاء الدين نهائيًا'.tr(),
            onPressed: () => _handleCancelDebt(d),
          ),
          DesktopToolbarIconButton(
            icon: Icons.print_outlined,
            tooltip: 'طباعة إيصال الدين'.tr(),
            onPressed:
                () => _windowsPrintDebt(
                  context,
                  d,
                  totalAmount,
                  totalPaidPartial,
                ),
          ),
        ],
      ),
    );
  }

  /// طباعة إيصال الدين — نفس منطق نسخة الموبايل.
  Future<void> _windowsPrintDebt(
    BuildContext context,
    Map<String, dynamic> d,
    double totalAmount,
    double totalPaidPartial,
  ) async {
    try {
      final db = await DBHelper.database;
      final debtId = (d['id'] as num).toInt();

      final items = await db.query(
        'debt_items',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );
      final payments = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );

      final debtDetails = <Map<String, dynamic>>[
        {
          'date': d['date'],
          'items': items.map((e) => Map<String, dynamic>.from(e)).toList(),
          'total': totalAmount,
          'original': (d['original_amount'] as num?)?.toDouble() ?? totalAmount,
          'paid': totalPaidPartial,
          'payments':
              payments.map((p) => Map<String, dynamic>.from(p)).toList(),
        },
      ];

      await printDebtInvoice(
        (d['customer_name'] ?? 'غير معروف'.tr()).toString(),
        debtDetails,
        0,
        0,
      );
    } catch (e) {
      debugPrint('⚠️ فشلت طباعة إيصال الدين: $e');
      AppToast.show('حصلت مشكلة في الطباعة'.tr());
    }
  }

  // ==================================================================
  // التحصيل
  // ==================================================================

  Widget _windowsDebtPaymentCard(BuildContext context, Map<String, dynamic> p) {
    final palette = DesktopPalette.of(context);

    final customerName = (p['customer_name'] ?? 'غير معروف'.tr()).toString();
    final amount = ((p['amount'] ?? 0) as num).toDouble();
    final discount = ((p['discount'] ?? 0) as num).toDouble();

    return DesktopCard(
      margin: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      borderColor: _ShiftDetailsPageState.collectedColor.withValues(alpha: 0.4),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.price_check,
            color: _ShiftDetailsPageState.collectedColor,
            size: 38,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  discount > 0
                      ? 'مدفوع: {v1} {v2}  |  خصم: {v3} {v4}  |  بتاريخ: {v5}'
                          .tr({
                            'v1': amount.toStringAsFixed(2),
                            'v2': Money.txt,
                            'v3': discount.toStringAsFixed(2),
                            'v4': Money.txt,
                            'v5': formatDate(p['paid_at'] as String?),
                          })
                      : 'مدفوع: ${amount.toStringAsFixed(2)} ${Money.txt}  |  بتاريخ: ${formatDate(p['paid_at'] as String?)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _ShiftDetailsPageState.collectedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopToolbarIconButton(
            icon: Icons.print_outlined,
            tooltip: 'طباعة إيصال التحصيل'.tr(),
            onPressed:
                () => _windowsPrintDebtPayment(
                  context,
                  p,
                  customerName,
                  amount,
                  discount,
                ),
          ),
          const SizedBox(width: DesktopTokens.gapXs),
          Text(
            _money(amount),
            style: const TextStyle(
              color: _ShiftDetailsPageState.collectedColor,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  /// طباعة إيصال التحصيل — نفس منطق نسخة الموبايل.
  Future<void> _windowsPrintDebtPayment(
    BuildContext context,
    Map<String, dynamic> p,
    String customerName,
    double amount,
    double discount,
  ) async {
    try {
      final db = await DBHelper.database;
      final debtId = p['debt_id'] as int;

      final items = await db.query(
        'debt_items',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );

      final debtDetails = <Map<String, dynamic>>[
        {
          'date': p['paid_at'],
          'items': items.map((e) => Map<String, dynamic>.from(e)).toList(),
          'total': amount,
          'original': amount,
          'paid': amount,
          'payments': [Map<String, dynamic>.from(p)],
        },
      ];

      await printDebtInvoice(customerName, debtDetails, amount, discount);
    } catch (e) {
      debugPrint('⚠️ فشلت طباعة إيصال التحصيل: $e');
      AppToast.show('حصلت مشكلة في الطباعة'.tr());
    }
  }

  // ==================================================================
  // أدوات صغيرة
  // ==================================================================

  /// تنسيق مبلغ بنفس شكل نسخة الموبايل.
  String _money(double value) => '${value.toStringAsFixed(2)} ${Money.txt}';
}
