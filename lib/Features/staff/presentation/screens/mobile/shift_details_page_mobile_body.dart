part of '../ShiftDetailsPage.dart';

/// جسم تفاصيل الشيفت — نسخة الموبايل (زي ما كانت بالظبط).
extension _ShiftDetailsPageMobileBody on _ShiftDetailsPageState {
  Widget _buildMobileBody(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل شيفت {v1}'.tr({'v1': widget.staffName})),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_android),
            tooltip: 'إضافة فودافون كاش'.tr(),
            onPressed: _addVodafoneCashNote,
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ: {v1}'.tr({'v1': snapshot.error})),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, theme, cs, tt),
                const SizedBox(height: 20),
                _sectionHeader(
                  cs,
                  tt,
                  'الأصناف والمنتجات المباعة'.tr(),
                  Icons.fastfood,
                  productsSummary.length,
                ),
                const SizedBox(height: 8),
                if (productsSummary.isEmpty)
                  _emptyState(cs, tt, 'لا توجد أصناف مباعة في هذا الشيفت'.tr())
                else
                  _buildProductsSummaryCard(cs, tt),
                const SizedBox(height: 20),
                _sectionHeader(
                  cs,
                  tt,
                  'الفواتير'.tr(),
                  Icons.receipt_long,
                  invoices.length,
                ),
                const SizedBox(height: 8),
                if (invoices.isEmpty)
                  _emptyState(cs, tt, 'لا توجد فواتير في هذا الشيفت'.tr())
                else
                  ...invoices.map((inv) => _invoiceCard(cs, tt, inv)),
                const SizedBox(height: 20),
                _sectionHeader(
                  cs,
                  tt,
                  'المصروفات'.tr(),
                  Icons.money_off,
                  expenses.length,
                ),
                const SizedBox(height: 8),
                if (expenses.isEmpty)
                  _emptyState(cs, tt, 'لا توجد مصروفات مسجلة'.tr())
                else
                  ...expenses.map((e) => _expenseCard(cs, tt, e)),
                const SizedBox(height: 20),
                _sectionHeader(
                  cs,
                  tt,
                  'الآجل'.tr(),
                  Icons.schedule,
                  debts.length,
                ),
                const SizedBox(height: 8),
                if (debts.isEmpty)
                  _emptyState(cs, tt, 'لا توجد ديون آجلة'.tr())
                else
                  ...debts.map((d) => _debtCard(cs, tt, d)),
                const SizedBox(height: 20),
                _sectionHeader(
                  cs,
                  tt,
                  'محصّل من الآجل'.tr(),
                  Icons.price_check,
                  debtPayments.length,
                ),
                const SizedBox(height: 8),
                if (totalOpenPartialCollected > 0)
                  _summaryRow(
                    cs,
                    Icons.price_check,
                    'محصّل جزئيًا من ترابيزات لسه شغالة'.tr(),
                    totalOpenPartialCollected,
                    valueColor: Colors.white,
                  ),
                if (debtPayments.isEmpty)
                  _emptyState(cs, tt, 'لا يوجد تحصيل في هذا الشيفت'.tr())
                else
                  ...debtPayments.map((p) => _debtPaymentCard(cs, tt, p)),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- Summary Card ----------------
  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: cs.onPrimary,
          collapsedIconColor: cs.onPrimary.withOpacity(0.7),
          onExpansionChanged: (expanded) async {
            if (expanded && !canViewSummary) {
              final ok = await _confirmCashierPassword(context);
              if (ok) {
                _refresh(() => canViewSummary = true);
              }
            }
          },
          title: Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: cs.onPrimary),
              const SizedBox(width: 10),
              Text(
                'ملخص الشيفت'.tr(),
                style: tt.titleMedium?.copyWith(
                  color: cs.onPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, right: 34),
            child: Text(
              canViewSummary
                  ? 'اضغط للإخفاء'.tr()
                  : 'اضغط لعرض التفاصيل المالية'.tr(),
              style: TextStyle(
                color: cs.onPrimary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          children: canViewSummary ? [_summaryContent(cs)] : [],
        ),
      ),
    );
  }

  Widget _summaryContent(ColorScheme cs) {
    final totalDevicesPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      final deviceCost = (inv['device_cost']?.toDouble() ?? 0.0);
      final totalCost = (inv['total_cost']?.toDouble() ?? 0.0);
      final paidPartial = (inv['paid_partial']?.toDouble() ?? 0.0);
      final fraction = totalCost > 0 ? paidPartial / totalCost : 0.0;
      return sum + deviceCost * fraction;
    });

    final totalDrinksPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      final drinksCost = (inv['drinks_cost']?.toDouble() ?? 0.0);
      final totalCost = (inv['total_cost']?.toDouble() ?? 0.0);
      final paidPartial = (inv['paid_partial']?.toDouble() ?? 0.0);
      final fraction = totalCost > 0 ? paidPartial / totalCost : 0.0;
      return sum + drinksCost * fraction;
    });

    final totalProductsPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      final prodCost = (inv['products_cost']?.toDouble() ?? 0.0);
      final totalCost = (inv['total_cost']?.toDouble() ?? 0.0);
      final paidPartial = (inv['paid_partial']?.toDouble() ?? 0.0);
      final fraction = totalCost > 0 ? paidPartial / totalCost : 0.0;
      return sum + prodCost * fraction;
    });

    final totalCigarettes = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      final cigCost = (inv['cigarettes_cost']?.toDouble() ?? 0.0);
      final totalCost = (inv['total_cost']?.toDouble() ?? 0.0);
      final paidPartial = (inv['paid_partial']?.toDouble() ?? 0.0);
      final fraction = totalCost > 0 ? paidPartial / totalCost : 0.0;
      return sum + cigCost * fraction;
    });
    final totalShisha = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      final shishaCost = (inv['shisha_cost']?.toDouble() ?? 0.0);
      final totalCost = (inv['total_cost']?.toDouble() ?? 0.0);
      final paidPartial = (inv['paid_partial']?.toDouble() ?? 0.0);
      final fraction = totalCost > 0 ? paidPartial / totalCost : 0.0;
      return sum + shishaCost * fraction;
    });
    final totalOpenValue = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['is_open'] != true) return sum;
      return sum + ((inv['total_cost'] as num?)?.toDouble() ?? 0.0);
    });
    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, e) => sum + (e['amount']?.toDouble() ?? 0.0),
    );
    final totalTransactions = transactions.fold<double>(
      0.0,
      (sum, t) => sum + (t['received']?.toDouble() ?? 0.0),
    );

    final totalDebts = debts.fold<double>(
      0.0,
      (sum, d) => sum + ((d['remaining_amount'] as double?) ?? 0.0),
    );

    final totalDiscounts = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      final discount = (inv['discount'] as num?)?.toDouble() ?? 0.0;
      final totalCost = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;
      final paidPartial = (inv['paid_partial'] as double?) ?? 0.0;
      final fraction = totalCost > 0 ? paidPartial / totalCost : 0.0;
      return sum + discount * fraction;
    });
    final grandTotaldis =
        totalDevicesPaid +
        totalDrinksPaid +
        totalProductsPaid +
        totalCigarettes +
        totalShisha +
        totalTransactions +
        totalDebtCollected -
        totalExpenses -
        totalDiscounts;

    final grandTotal =
        totalDevicesPaid +
        totalDrinksPaid +
        totalProductsPaid +
        totalCigarettes +
        totalShisha +
        totalTransactions +
        totalDebtCollected -
        totalExpenses;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(
            cs,
            Icons.sports_esports,
            'إجمالي الأجهزة'.tr(),
            totalDevicesPaid,
          ),
          _summaryRow(
            cs,
            Icons.local_cafe,
            'إجمالي المشروبات'.tr(),
            totalDrinksPaid,
          ),
          if (totalProductsPaid > 0)
            _summaryRow(
              cs,
              Icons.fastfood,
              'إجمالي المنتجات/المأكولات'.tr(),
              totalProductsPaid,
              valueColor: Colors.teal,
            ),
          if (totalCigarettes > 0)
            _summaryRow(
              cs,
              Icons.smoking_rooms,
              'إجمالي السجائر'.tr(),
              totalCigarettes,
              valueColor: Colors.brown,
            ),
          if (totalShisha > 0)
            _summaryRow(
              cs,
              Icons.blur_on,
              'إجمالي الشيشة'.tr(),
              totalShisha,
              valueColor: Colors.deepPurple,
            ),
          _summaryRow(
            cs,
            Icons.money_off,
            'المصروفات'.tr(),
            totalExpenses,
            valueColor: Colors.redAccent,
          ),
          _summaryRow(
            cs,
            Icons.schedule,
            'الآجل'.tr(),
            totalDebts,
            valueColor: Colors.black,
          ),
          _summaryRow(
            cs,
            Icons.price_check,
            'محصّل من الآجل'.tr(),
            totalDebtCollected,
            valueColor: Colors.black,
          ),
          if (totalOpenValue > 0)
            _summaryRow(
              cs,
              Icons.hourglass_top,
              'قيمة الترابيزات المفتوحة (لسه شغالة)'.tr(),
              totalOpenValue,
              valueColor: Colors.white,
            ),
          if (vodafoneCashTotal > 0)
            _summaryRow(
              cs,
              Icons.phone_android,
              'فودافون كاش (معلومة فقط)'.tr(),
              vodafoneCashTotal,
              valueColor: Colors.orangeAccent,
            ),
          Divider(color: cs.onPrimary.withOpacity(0.2), height: 24),
          _summaryRow(
            cs,
            Icons.summarize,
            'المجموع الكلي'.tr(),
            grandTotal,
            bold: true,
          ),
          _summaryRow(
            cs,
            Icons.done_all,
            'المجموع بعد الخصومات'.tr(),
            grandTotaldis,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    ColorScheme cs,
    IconData icon,
    String label,
    double value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onPrimary.withOpacity(0.85)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onPrimary.withOpacity(0.9),
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} ${Money.txt}',
            style: TextStyle(
              color: valueColor ?? cs.onPrimary,
              fontSize: bold ? 15 : 13.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Section header ----------------
  Widget _sectionHeader(
    ColorScheme cs,
    TextTheme tt,
    String title,
    IconData icon,
    int count,
  ) {
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: tt.titleMedium?.copyWith(fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: cs.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(ColorScheme cs, TextTheme tt, String message) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.25), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.08),
              ),
              child: Icon(
                Icons.inbox_outlined,
                color: cs.onSurface.withOpacity(0.4),
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Invoice Card ----------------
  Widget _invoiceCard(ColorScheme cs, TextTheme tt, Map<String, dynamic> inv) {
    final paymentType = inv['payment_type'];
    final isCancelled = paymentType == 'ملغي';
    final remainingDebt = (inv['remaining_debt'] as double?) ?? 0.0;
    final isOpen = inv['is_open'] == true;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isCancelled) {
      statusColor = _ShiftDetailsPageState.cancelColor;
      statusLabel = 'ملغي'.tr();
      statusIcon = Icons.cancel_outlined;
    } else if (isOpen) {
      statusColor = Colors.blueAccent;
      statusLabel = 'جاري الآن'.tr();
      statusIcon = Icons.play_circle_outline;
    } else if (remainingDebt > 0) {
      statusColor = _ShiftDetailsPageState.debtColor;
      statusLabel = 'آجل'.tr();
      statusIcon = Icons.schedule;
    } else {
      statusColor = _ShiftDetailsPageState.paidColor;
      statusLabel = 'مدفوع'.tr();
      statusIcon = Icons.check_circle_outline;
    }

    final total = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;

    String fmt(dynamic v) => ((v as num?) ?? 0).toDouble().toStringAsFixed(2);

    // 🆕 قابلة للإلغاء لو آجلة، لسه مش ملغية، ومش لسه شغالة
    final canCancel = !isCancelled && !isOpen && remainingDebt > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primary.withOpacity(0.12),
                  child: Icon(Icons.person, size: 16, color: cs.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inv['customer_name'] ?? 'غير معروف'.tr(),
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                // 🆕 إلغاء الفاتورة الآجلة
                if (canCancel)
                  IconButton(
                    icon: Icon(Icons.delete_forever, size: 20, color: cs.error),
                    tooltip: 'إلغاء الفاتورة نهائيًا'.tr(),
                    onPressed: () => _handleCancelDebtInvoice(inv),
                  ),

                IconButton(
                  icon: Icon(Icons.print, size: 18, color: cs.primary),
                  tooltip: 'طباعة الفاتورة'.tr(),
                  onPressed: () async {
                    try {
                      final consoleId = inv['console_id'] as int?;
                      final deviceCost =
                          ((inv['device_cost'] ?? 0) as num).toDouble();

                      if (consoleId != null && deviceCost > 0) {
                        final db = await DBHelper.database;

                        final start = DateTime.tryParse(
                          inv['start_time']?.toString() ?? '',
                        );
                        final end = DateTime.tryParse(
                          inv['end_time']?.toString() ?? '',
                        );
                        final totalPausedSeconds =
                            (inv['total_paused_seconds'] as int?) ?? 0;

                        double duration = 0;
                        if (start != null && end != null) {
                          final rawSeconds = end.difference(start).inSeconds;
                          final effectiveSeconds =
                              rawSeconds - totalPausedSeconds;
                          duration = effectiveSeconds / 3600.0;
                        }

                        final drinksCost =
                            ((inv['drinks_cost'] ?? 0) as num).toDouble();
                        final discount =
                            ((inv['discount'] ?? 0) as num).toDouble();
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

                        final consoleName =
                            consoleNames[consoleId] ?? 'غير معروف'.tr();

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
                      print('⚠️ فشلت طباعة الفاتورة: $e');
                      if (mounted) {
                        AppToast.show('حصلت مشكلة في الطباعة'.tr());
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 18, color: cs.primary),
                  tooltip: 'تفاصيل الفاتورة'.tr(),
                  onPressed: () => _showInvoiceDetails(inv),
                ),
                IconButton(
                  icon: Icon(Icons.history, size: 18, color: cs.primary),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _miniStat(
                  cs,
                  Icons.sports_esports,
                  'بلايستيشن'.tr(),
                  fmt(inv['device_cost']),
                ),
                _miniStat(
                  cs,
                  Icons.local_cafe,
                  'مشروبات'.tr(),
                  fmt(inv['drinks_cost']),
                ),
                if (((inv['products_cost'] ?? 0) as num).toDouble() != 0)
                  _miniStat(
                    cs,
                    Icons.fastfood,
                    'منتجات'.tr(),
                    fmt(inv['products_cost']),
                  ),
                if (((inv['cigarettes_cost'] ?? 0) as num).toDouble() != 0)
                  _miniStat(
                    cs,
                    Icons.smoking_rooms,
                    'سجائر'.tr(),
                    fmt(inv['cigarettes_cost']),
                  ),
                if (((inv['shisha_cost'] ?? 0) as num).toDouble() != 0)
                  _miniStat(
                    cs,
                    Icons.blur_on,
                    'شيشة'.tr(),
                    fmt(inv['shisha_cost']),
                  ),
                if ((inv['discount'] ?? 0) != 0)
                  _miniStat(
                    cs,
                    Icons.discount,
                    'خصم'.tr(),
                    fmt(inv['discount']),
                  ),
                _miniStat(
                  cs,
                  Icons.payments,
                  'الإجمالي'.tr(),
                  fmt(total),
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 13,
                  color: cs.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'من {v1}  إلى  {v2}'.tr({
                      'v1': formatDate(inv['start_time']),
                      'v2': formatDate(inv['end_time']),
                    }),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  ),
                ),
              ],
            ),
            if (remainingDebt > 0) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _ShiftDetailsPageState.debtColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 15,
                      color: _ShiftDetailsPageState.debtColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'مدفوع جزئيًا: {v1}   |   الباقي: {v2}'.tr({
                          'v1': fmt(inv['paid_partial']),
                          'v2': fmt(inv['remaining_debt']),
                        }),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _ShiftDetailsPageState.debtColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 🆕 عرض المحصّل جزئيًا والفاتورة لسه مفتوحة
            if (isOpen && (inv['paid_partial'] as double? ?? 0.0) > 0) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _ShiftDetailsPageState.collectedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.price_check,
                      size: 15,
                      color: _ShiftDetailsPageState.collectedColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'محصّل جزئيًا (والترابيزة لسه شغالة): {v1} {v2}'.tr({
                          'v1': fmt(inv['paid_partial']),
                          'v2': Money.txt,
                        }),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _ShiftDetailsPageState.collectedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    ColorScheme cs,
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight ? cs.primary : cs.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: highlight ? cs.primary : cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ---------------- Products Summary Card ----------------
  Widget _buildProductsSummaryCard(ColorScheme cs, TextTheme tt) {
    final totalQty = productsSummary.fold<int>(
      0,
      (sum, p) => sum + ((p['total_qty'] ?? 0) as num).toInt(),
    );
    final totalAmount = productsSummary.fold<double>(
      0.0,
      (sum, p) => sum + ((p['total_amount'] ?? 0) as num).toDouble(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'إجمالي القطع المباعة: {totalQty}'.tr({
                        'totalQty': totalQty,
                      }),
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${totalAmount.toStringAsFixed(2)} ${Money.txt}',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...productsSummary.map((p) {
              final name = (p['product_name'] ?? '').toString();
              final qty = ((p['total_qty'] ?? 0) as num).toInt();
              final unitPrice = ((p['unit_price'] ?? 0) as num).toDouble();
              final total = ((p['total_amount'] ?? 0) as num).toDouble();
              final category = (p['category'] ?? '').toString();

              IconData icon = Icons.local_cafe;
              if (category == 'cigarette') {
                icon = Icons.smoking_rooms;
              } else if (category == 'shisha') {
                icon = Icons.blur_on;
              } else if (category == 'prodect' || category == 'cold') {
                icon = Icons.fastfood;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primary.withOpacity(0.1),
                      child: Icon(icon, size: 14, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'سعر الوحدة: {v1} {v2}'.tr({
                              'v1': unitPrice.toStringAsFixed(2),
                              'v2': Money.txt,
                            }),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$qty',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${total.toStringAsFixed(2)} ${Money.txt}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- Expense Card ----------------
  Widget _expenseCard(ColorScheme cs, TextTheme tt, Map<String, dynamic> e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _ShiftDetailsPageState.debtColor.withOpacity(0.12),
          child: const Icon(
            Icons.remove_circle_outline,
            color: _ShiftDetailsPageState.debtColor,
            size: 18,
          ),
        ),
        title: Text(
          '${e['description']}',
          style: tt.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        subtitle: Text(
          'تمت في: {v1} بواسطة: {v2}'.tr({
            'v1': formatDate(e['date']),
            'v2': e['added_by'],
          }),
          style: TextStyle(
            fontSize: 11.5,
            color: cs.onSurface.withOpacity(0.55),
          ),
        ),
        trailing: Text(
          '${(((e['amount']) as num?) ?? 0).toDouble().toStringAsFixed(2)} ${Money.txt}',
          style: const TextStyle(
            color: _ShiftDetailsPageState.debtColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  // ---------------- Debt Card ----------------
  Widget _debtCard(ColorScheme cs, TextTheme tt, Map<String, dynamic> d) {
    final totalAmount = (d['total_amount'] as num?)?.toDouble() ?? 0.0;

    final debtPaymentsForRow =
        transactions.where((t) => t['debt_id'] == d['id']).toList();

    final totalPaidPartial = (d['paid_partial'] as double?) ?? 0.0;
    final remaining =
        (d['remaining_amount'] as double?) ?? (totalAmount - totalPaidPartial);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.secondary.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cs.secondary.withOpacity(0.15),
          child: Icon(Icons.schedule, color: cs.secondary, size: 18),
        ),
        title: Text(
          d['customer_name'] ?? '',
          style: tt.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            'المتبقي: {v1} {v2}\nتاريخ: {v3}'.tr({
              'v1': remaining.toStringAsFixed(2),
              'v2': Money.txt,
              'v3': formatDate(d['date']),
            }),
            style: const TextStyle(
              fontSize: 12,
              color: _ShiftDetailsPageState.debtColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🆕 تعديل الدين
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: cs.primary),
              tooltip: 'تعديل الدين'.tr(),
              onPressed: () => _openEditDebt(d),
            ),
            // 🆕 إلغاء الدين
            IconButton(
              icon: Icon(Icons.delete_forever, size: 18, color: cs.error),
              tooltip: 'إلغاء الدين نهائيًا'.tr(),
              onPressed: () => _handleCancelDebt(d),
            ),
            IconButton(
              icon: Icon(Icons.print, size: 18, color: cs.secondary),
              tooltip: 'طباعة إيصال الدين'.tr(),
              onPressed: () async {
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
                      'items':
                          items
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(),
                      'total': totalAmount,
                      'original':
                          (d['original_amount'] as num?)?.toDouble() ??
                          totalAmount,
                      'paid': totalPaidPartial,
                      'payments':
                          payments
                              .map((p) => Map<String, dynamic>.from(p))
                              .toList(),
                    },
                  ];

                  await printDebtInvoice(
                    d['customer_name'] ?? 'غير معروف'.tr(),
                    debtDetails,
                    0,
                    0,
                  );
                } catch (e) {
                  print('⚠️ فشلت طباعة إيصال الدين: $e');
                  if (mounted) {
                    AppToast.show('حصلت مشكلة في الطباعة'.tr());
                  }
                }
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d['type'] ?? '',
                style: TextStyle(
                  fontSize: 11.5,
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Debt Payment Card ----------------
  Widget _debtPaymentCard(
    ColorScheme cs,
    TextTheme tt,
    Map<String, dynamic> p,
  ) {
    final customerName = (p['customer_name'] ?? 'غير معروف'.tr()).toString();
    final amount = ((p['amount'] ?? 0) as num).toDouble();
    final discount = ((p['discount'] ?? 0) as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _ShiftDetailsPageState.collectedColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _ShiftDetailsPageState.collectedColor.withOpacity(
            0.15,
          ),
          child: const Icon(
            Icons.price_check,
            color: _ShiftDetailsPageState.collectedColor,
            size: 18,
          ),
        ),
        title: Text(
          customerName,
          style: tt.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            discount > 0
                ? 'مدفوع: {v1} {v2}  |  خصم: {v3} {v4}\nبتاريخ: {v5}'.tr({
                  'v1': amount.toStringAsFixed(2),
                  'v2': Money.txt,
                  'v3': discount.toStringAsFixed(2),
                  'v4': Money.txt,
                  'v5': formatDate(p['paid_at'] as String?),
                })
                : 'مدفوع: ${amount.toStringAsFixed(2)} ${Money.txt}\nبتاريخ: ${formatDate(p['paid_at'] as String?)}',
            style: const TextStyle(
              fontSize: 12,
              color: _ShiftDetailsPageState.collectedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.print,
                size: 18,
                color: _ShiftDetailsPageState.collectedColor,
              ),
              tooltip: 'طباعة إيصال التحصيل'.tr(),
              onPressed: () async {
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
                      'items':
                          items
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(),
                      'total': amount,
                      'original': amount,
                      'paid': amount,
                      'payments': [Map<String, dynamic>.from(p)],
                    },
                  ];

                  await printDebtInvoice(
                    customerName,
                    debtDetails,
                    amount,
                    discount,
                  );
                } catch (e) {
                  print('⚠️ فشلت طباعة إيصال التحصيل: $e');
                  if (mounted) {
                    AppToast.show('حصلت مشكلة في الطباعة'.tr());
                  }
                }
              },
            ),
            Text(
              '${amount.toStringAsFixed(2)} ${Money.txt}',
              style: const TextStyle(
                color: _ShiftDetailsPageState.collectedColor,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
