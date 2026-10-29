part of '../shifts_report.dart';

/// جسم تقارير الشيفتات — نسخة الموبايل (زي ما كانت بالظبط).
extension _ShiftsReportMobileBody on _ShiftsReportScreenState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('تقارير الشيفتات'.tr()),
        actions: [
          _designSwitcher(), // 🆕 زرار تغيير التصميم
          if (isMobile) ...[
            IconButton(
              tooltip: 'اختر تاريخ'.tr(),
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _refresh(() => _selectedDate = picked);
                  _loadShifts(date: picked);
                }
              },
            ),
            IconButton(
              tooltip: 'ملخص اليوم'.tr(),
              icon: const Icon(Icons.summarize),
              onPressed: _generateDailySummary,
            ),
            IconButton(
              tooltip: 'عرض الكل'.tr(),
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                _refresh(() => _selectedDate = null);
                _loadShifts();
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.tonal(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _refresh(() => _selectedDate = picked);
                    _loadShifts(date: picked);
                  }
                },
                child:  Text('اختر تاريخ'.tr()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.tonal(
                onPressed: _generateDailySummary,
                child:  Text('ملخص اليوم'.tr()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.tonal(
                onPressed: () {
                  _refresh(() => _selectedDate = null);
                  _loadShifts();
                },
                child:  Text('عرض الكل'.tr()),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ?  Center(child: CircularProgressIndicator())
          : shifts.isEmpty
              ?  Center(child: Text('لا توجد بيانات شيفتات بعد'.tr()))
              : Padding(
                  padding:
                      EdgeInsets.all(_design == ReportDesign.full ? 12 : 16),
                  child: ListView.builder(
                    itemCount: shifts.length +
                        (_loadedCount < _rawShifts.length ? 1 : 0),
                    addAutomaticKeepAlives: false,
                    itemBuilder: (context, i) {
                      // 🆕 آخر عنصر = مؤشر/زرار تحميل المزيد
                      if (i >= shifts.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _loadMoreShifts();
                        });
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: _isLoadingMore
                                ? const CircularProgressIndicator()
                                : TextButton.icon(
                                    onPressed: _loadMoreShifts,
                                    icon: const Icon(Icons.expand_more),
                                    label:  Text('تحميل المزيد'.tr()),
                                  ),
                          ),
                        );
                      }

                      final s = shifts[i];
                      final bool isSummary = s['check_in'] == null;
                      final debtDetails =
                          ((s['debt_collected_details'] as List?)
                                  ?.cast<Map<String, dynamic>>()) ??
                              [];
                      final paidInvoiceDetails = ((s['paid_details'] as List?)
                              ?.cast<Map<String, dynamic>>()) ??
                          [];
                      final debtInvoiceDetails = ((s['debt_details'] as List?)
                              ?.cast<Map<String, dynamic>>()) ??
                          [];
                      final salesDetailsList = ((s['sales_details'] as List?)
                              ?.cast<Map<String, dynamic>>()) ??
                          [];
                      final expensesDetailsList =
                          ((s['expenses_details'] as List?)
                                  ?.cast<Map<String, dynamic>>()) ??
                              [];
                      final vodafoneNotes = ((s['vodafone_cash_notes'] as List?)
                              ?.cast<Map<String, dynamic>>()) ??
                          [];

                      final deleteButton = IconButton(
                        icon: Icon(Icons.delete,
                            color: _design == ReportDesign.full
                                ? Colors.white
                                : Colors.red),
                        tooltip: 'مسح بيانات الشيفت'.tr(),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AppDialog(
                              title:  Text('تأكيد المسح'.tr()),
                              content:  Text(
                                  'هل تريد مسح كل بيانات هذا الشيفت؟'.tr()),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child:  Text('إلغاء'.tr()),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child:  Text('تأكيد'.tr()),
                                ),
                              ],
                            ),
                          );

                          if (confirmed ?? false) {
                            if (s['id'] == null) {
                              print("تحذير: الشيفت بدون ID، لا يمكن مسحه");
                              return;
                            }
                            await DBHelper.clearShiftData(
                              s['id'] as int,
                              s['staff_name'] as String,
                              DateTime.parse(s['check_in']),
                              s['check_out'] != null
                                  ? DateTime.parse(s['check_out'])
                                  : null,
                            );
                            await _loadShifts();
                            AppToast.show('تم مسح بيانات الشيفت بالكامل'.tr());
                          }
                        },
                      );

                      // 🆕 تصميم "full" — بيستخدم بنّاء منفصل بشبكة عريضة
                      if (_design == ReportDesign.full) {
                        return isSummary
                            ? _buildFullSummaryCard(
                                s,
                                paidInvoiceDetails: paidInvoiceDetails,
                                debtInvoiceDetails: debtInvoiceDetails,
                                debtDetails: debtDetails,
                                expensesDetailsList: expensesDetailsList,
                                vodafoneNotes: vodafoneNotes,
                                deleteButton: deleteButton,
                              )
                            : _buildFullShiftCard(
                                s,
                                paidInvoiceDetails: paidInvoiceDetails,
                                debtInvoiceDetails: debtInvoiceDetails,
                                debtDetails: debtDetails,
                                expensesDetailsList: expensesDetailsList,
                                salesDetailsList: salesDetailsList,
                                vodafoneNotes: vodafoneNotes,
                                deleteButton: deleteButton,
                              );
                      }

                      if (isSummary) {
                        return _wrapCard(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading:
                                _leadingAvatar(Icons.person, Colors.blueAccent),
                            title: Text(
                              'الموظف: {v1}'.tr({'v1': s['staff_name']}),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                _statRow(
                                  emoji: '💵',
                                  icon: Icons.check_circle_outline,
                                  label: 'إجمالي المدفوع'.tr(),
                                  amount: (s['paid'] ?? 0).toDouble(),
                                  color: Colors.green[700]!,
                                  onTap: () => _showDetailsSheet(
                                    title: 'تفاصيل المدفوع'.tr(),
                                    items: paidInvoiceDetails,
                                    nameOf: (m) =>
                                        (m['customer_name'] ?? 'غير معروف'.tr())
                                            .toString(),
                                    subtitleOf: (m) => _orderSubtitle(m),
                                    amountOf: (m) =>
                                        ((m['amount'] ?? 0) as num).toDouble(),
                                    color: Colors.green[700]!,
                                    icon: Icons.check_circle_outline,
                                  ),
                                ),
                                _statRow(
                                  emoji: '💳',
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'إجمالي الآجل'.tr(),
                                  amount: (s['debt'] ?? 0).toDouble(),
                                  color: Colors.red[700]!,
                                  onTap: () => _showDetailsSheet(
                                    title: 'تفاصيل الآجل'.tr(),
                                    items: debtInvoiceDetails,
                                    nameOf: (m) =>
                                        (m['customer_name'] ?? 'غير معروف'.tr())
                                            .toString(),
                                    subtitleOf: (m) => _orderSubtitle(m),
                                    amountOf: (m) =>
                                        ((m['amount'] ?? 0) as num).toDouble(),
                                    color: Colors.red[700]!,
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                                _statRow(
                                  emoji: '✅',
                                  icon: Icons.price_check,
                                  label: 'إجمالي المحصّل من الآجل'.tr(),
                                  amount: (s['debt_collected'] ?? 0).toDouble(),
                                  color: Colors.teal[700]!,
                                  onTap: () =>
                                      _showDebtCollectedDetails(debtDetails),
                                ),
                                _statRow(
                                  emoji: '💸',
                                  icon: Icons.money_off,
                                  label: 'إجمالي المصروفات'.tr(),
                                  amount: (s['expenses'] ?? 0).toDouble(),
                                  color: Colors.orange[800]!,
                                  onTap: () => _showDetailsSheet(
                                    title: 'تفاصيل المصروفات'.tr(),
                                    items: expensesDetailsList,
                                    nameOf: (m) => (m['description'] ?? 'مصروف'.tr())
                                        .toString(),
                                    subtitleOf: (m) =>
                                        'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['date'])}),
                                    amountOf: (m) =>
                                        ((m['amount'] ?? 0) as num).toDouble(),
                                    color: Colors.orange[800]!,
                                    icon: Icons.money_off,
                                  ),
                                ),
                                _statRow(
                                  emoji: '📱',
                                  icon: Icons.phone_android,
                                  label: 'فودافون كاش'.tr(),
                                  amount: (s['vodafone_cash_total'] ?? 0)
                                      .toDouble(),
                                  color: Colors.pink[700]!,
                                  onTap: () => _showDetailsSheet(
                                    title: 'تفاصيل فودافون كاش'.tr(),
                                    items: vodafoneNotes,
                                    nameOf: (m) => (m['note'] as String?)
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? m['note']
                                        : 'فودافون كاش',
                                    subtitleOf: (m) =>
                                        'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['created_at'])}),
                                    amountOf: (m) =>
                                        ((m['amount'] ?? 0) as num).toDouble(),
                                    color: Colors.pink[700]!,
                                    icon: Icons.phone_android,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                      '⏱️ إجمالي الساعات: {v1}   |   🔢 عدد الشيفتات: {v2}'.tr({'v1': s['total_hours'].toStringAsFixed(2), 'v2': s['count']}),
                                      style: _metaStyle()),
                                ),
                                const Divider(height: 16, thickness: 0.5),
                                Text(
                                  '🏆 المدفوع + المحصّل: {v1} {v2}'.tr({'v1': ((s['paid'] ?? 0) + (s['debt_collected'] ?? 0)).toStringAsFixed(2), 'v2': Money.txt}),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.deepPurple[800],
                                  ),
                                ),
                              ],
                            ),
                            trailing: deleteButton,
                          ),
                        );
                      }

                      final totalSalesWithCharge = (s['total_sales'] ?? 0) +
                          (s['charge_in'] ?? 0) -
                          (s['expenses'] ?? 0);
                      final paidPlusCollected =
                          (s['paid'] ?? 0) + (s['debt_collected'] ?? 0);
                      final paidPlusCollectedCash = (s['paid'] ?? 0) +
                          (s['debt_collected'] ?? 0) -
                          (s['expenses'] ?? 0);

                      return _wrapCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading:
                              _leadingAvatar(Icons.person, Colors.deepPurple),
                          title: Text(
                            'الموظف: {v1}'.tr({'v1': s['staff_name']}),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  '📅 ${formatArabicDate(DateTime.parse(s['shift_date']))}',
                                  style: _metaStyle()),
                              Text(
                                  '🕐 بدأ: {v1}'.tr({'v1': formatArabicDate(DateTime.parse(s['check_in']))}),
                                  style: _metaStyle()),
                              if (s['check_out'] != null)
                                Text(
                                    '🕓 انتهى: {v1}'.tr({'v1': formatArabicDate(DateTime.parse(s['check_out']))}),
                                    style: _metaStyle()),
                              Text(
                                  '⏱️ عدد الساعات: {v1}'.tr({'v1': s['total_hours']?.toStringAsFixed(2) ?? 0}),
                                  style: _metaStyle()),
                              const SizedBox(height: 6),
                              _statRow(
                                emoji: '💵',
                                icon: Icons.check_circle_outline,
                                label: 'المدفوع'.tr(),
                                amount: (s['paid'] ?? 0).toDouble(),
                                color: Colors.green[700]!,
                                onTap: () => _showDetailsSheet(
                                  title: 'تفاصيل المدفوع'.tr(),
                                  items: paidInvoiceDetails,
                                  nameOf: (m) =>
                                      (m['customer_name'] ?? 'غير معروف'.tr())
                                          .toString(),
                                  subtitleOf: (m) => _orderSubtitle(m),
                                  amountOf: (m) =>
                                      ((m['amount'] ?? 0) as num).toDouble(),
                                  color: Colors.green[700]!,
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                              _statRow(
                                emoji: '💳',
                                icon: Icons.money_off,
                                label: 'الآجل'.tr(),
                                amount: (s['debt'] ?? 0).toDouble(),
                                color: Colors.orange[800]!,
                                onTap: () => _showDetailsSheet(
                                  title: 'تفاصيل الآجل'.tr(),
                                  items: debtInvoiceDetails,
                                  nameOf: (m) =>
                                      (m['customer_name'] ?? 'غير معروف'.tr())
                                          .toString(),
                                  subtitleOf: (m) => _orderSubtitle(m),
                                  amountOf: (m) =>
                                      ((m['amount'] ?? 0) as num).toDouble(),
                                  color: Colors.orange[800]!,
                                  icon: Icons.money_off,
                                ),
                              ),
                              _statRow(
                                emoji: '✅',
                                icon: Icons.price_check,
                                label: 'محصّل من الآجل'.tr(),
                                amount: (s['debt_collected'] ?? 0).toDouble(),
                                color: Colors.teal[700]!,
                                onTap: () =>
                                    _showDebtCollectedDetails(debtDetails),
                                suffix: (s['debt_collected_count'] ?? 0) > 0
                                    ? ' ({v1} عملية)'.tr({'v1': s['debt_collected_count']})
                                    : '',
                              ),
                              if ((s['debt_collected_discount'] ?? 0) > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: Text(
                                    '↳ خصم على التحصيل: {v1} {v2}'.tr({'v1': (s['debt_collected_discount']).toStringAsFixed(2), 'v2': Money.txt}),
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 12),
                                  ),
                                ),
                              _statRow(
                                emoji: '💸',
                                icon: Icons.money_off,
                                label: 'المصروفات'.tr(),
                                amount: (s['expenses'] ?? 0).toDouble(),
                                color: Colors.orange[800]!,
                                onTap: () => _showDetailsSheet(
                                  title: 'تفاصيل المصروفات'.tr(),
                                  items: expensesDetailsList,
                                  nameOf: (m) =>
                                      (m['description'] ?? 'مصروف'.tr()).toString(),
                                  subtitleOf: (m) =>
                                      'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['date'])}),
                                  amountOf: (m) =>
                                      ((m['amount'] ?? 0) as num).toDouble(),
                                  color: Colors.orange[800]!,
                                  icon: Icons.money_off,
                                ),
                              ),
                              _statRow(
                                emoji: '📱',
                                icon: Icons.phone_android,
                                label: 'فودافون كاش'.tr(),
                                amount:
                                    (s['vodafone_cash_total'] ?? 0).toDouble(),
                                color: Colors.pink[700]!,
                                onTap: () => _showDetailsSheet(
                                  title: 'تفاصيل فودافون كاش'.tr(),
                                  items: vodafoneNotes,
                                  nameOf: (m) => (m['note'] as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? m['note']
                                      : 'فودافون كاش',
                                  subtitleOf: (m) =>
                                      'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['created_at'])}),
                                  amountOf: (m) =>
                                      ((m['amount'] ?? 0) as num).toDouble(),
                                  color: Colors.pink[700]!,
                                  icon: Icons.phone_android,
                                ),
                              ),
                              _statRow(
                                emoji: '💰',
                                icon: Icons.point_of_sale,
                                label: 'إجمالي المبيعات'.tr(),
                                amount: totalSalesWithCharge.toDouble(),
                                color: Colors.blue[700]!,
                                onTap: () => _showDetailsSheet(
                                  title: 'تفاصيل إجمالي المبيعات'.tr(),
                                  items: salesDetailsList,
                                  nameOf: (m) =>
                                      (m['customer_name'] ?? 'غير معروف'.tr())
                                          .toString(),
                                  subtitleOf: (m) => _orderSubtitle(m,
                                      notePrefix: (m['note'] ?? '').toString()),
                                  amountOf: (m) =>
                                      ((m['amount'] ?? 0) as num).toDouble(),
                                  color: Colors.blue[700]!,
                                  icon: Icons.point_of_sale,
                                ),
                              ),
                              const Divider(height: 16, thickness: 0.5),
                              Text(
                                '🏆 المدفوع + المحصّل: {v1} {v2}'.tr({'v1': paidPlusCollected.toStringAsFixed(2), 'v2': Money.txt}),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.deepPurple[800],
                                ),
                              ),
                              const Divider(height: 16, thickness: 0.5),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                   Text(
                                    'صافي الكاش'.tr(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(المبيعات + المحصل - المصاريف)'.tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${paidPlusCollectedCash.toStringAsFixed(2)} ${Money.txt}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: deleteButton,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // 🆕 زرار تغيير التصميم — بيظهر في الـ AppBar
  Widget _designSwitcher() {
    return PopupMenuButton<ReportDesign>(
      tooltip: 'تغيير شكل التقرير'.tr(),
      icon: Icon(_designIcon(_design)),
      onSelected: _changeDesign,
      itemBuilder: (context) => ReportDesign.values
          .map((d) => CheckedPopupMenuItem<ReportDesign>(
                value: d,
                checked: _design == d,
                child: Row(
                  children: [
                    Icon(_designIcon(d), size: 18),
                    const SizedBox(width: 8),
                    Text(_designLabel(d)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ------------------------------------------------------------
  // تصاميم classic / cards / minimal (زي ما هي)
  // ------------------------------------------------------------
  Widget _statRow({
    required String emoji,
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    VoidCallback? onTap,
    String suffix = '',
  }) {
    final valueText = '${formatter.format(amount)} ${Money.txt}$suffix';

    switch (_design) {
      case ReportDesign.classic:
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '$emoji $label: $valueText',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        );

      case ReportDesign.cards:
      case ReportDesign.full: // مش بتتنادى في full أصلاً، بس لازم ترجع حاجة
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w600, color: color),
                  ),
                ),
                Text(
                  valueText,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_left,
                      size: 16, color: color.withOpacity(0.6)),
                ],
              ],
            ),
          ),
        );

      case ReportDesign.minimal:
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                Text(
                  valueText,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
              ],
            ),
          ),
        );
    }
  }

  TextStyle _metaStyle() {
    switch (_design) {
      case ReportDesign.classic:
        return const TextStyle();
      case ReportDesign.cards:
      case ReportDesign.full:
        return TextStyle(color: Colors.grey[700], fontSize: 13);
      case ReportDesign.minimal:
        return TextStyle(color: Colors.grey[600], fontSize: 12.5);
    }
  }

  Widget _leadingAvatar(IconData icon, Color color) {
    switch (_design) {
      case ReportDesign.classic:
        return Icon(icon, color: color);
      case ReportDesign.cards:
      case ReportDesign.full:
        return CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        );
      case ReportDesign.minimal:
        return Icon(icon, color: color, size: 20);
    }
  }

  Widget _wrapCard({required Widget child}) {
    switch (_design) {
      case ReportDesign.classic:
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: child,
        );

      case ReportDesign.cards:
      case ReportDesign.full:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).cardColor,
                Colors.deepPurple.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        );

      case ReportDesign.minimal:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          child: Material(color: Colors.transparent, child: child),
        );
    }
  }

  int _fullGridColumns(double width) {
    if (width < 420) return 1;
    if (width < 520) return 2;
    if (width < 700) return 3;
    if (width < 1000) return 4;
    if (width < 1200) return 5;
    return 6;
  }

  Widget _fullHeader({
    required String title,
    required List<String> metaLines,
    required Widget trailing,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.72)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
                if (metaLines.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 14,
                    runSpacing: 2,
                    children: metaLines
                        .map((m) => Text(
                              m,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 12.5),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // كارت بيانات مربّع — بياخد مكانه في الشبكة ويملا المساحة الفاضية
  Widget _fullTile({
    required String emoji,
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    VoidCallback? onTap,
    String? subLine,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(Icons.chevron_left,
                      size: 16, color: color.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${formatter.format(amount)} ${Money.txt}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subLine != null) ...[
              const SizedBox(height: 2),
              Text(
                subLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // شريط كبير عريض بالعرض بالكامل — للأرقام النهائية (المجموع/صافي الكاش)
  Widget _fullFooterBanner({
    required List<MapEntry<String, String>> lines,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border(top: BorderSide(color: color.withOpacity(0.25))),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: lines
            .map(
              (e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.key,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text(
                    e.value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFullSummaryCard(
    Map<String, dynamic> s, {
    required List<Map<String, dynamic>> paidInvoiceDetails,
    required List<Map<String, dynamic>> debtInvoiceDetails,
    required List<Map<String, dynamic>> debtDetails,
    required List<Map<String, dynamic>> expensesDetailsList,
    required List<Map<String, dynamic>> vodafoneNotes,
    required Widget deleteButton,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fullHeader(
                title: 'ملخص الشيفتات — {v1}'.tr({'v1': s['staff_name']}),
                metaLines: [
                  "⏱️ ${s['total_hours'].toStringAsFixed(2)} ساعة",
                  '🔢 {v1} شيفت'.tr({'v1': s['count']}),
                ],
                trailing: deleteButton,
                color: Colors.green,
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = _fullGridColumns(constraints.maxWidth);
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.2,
                      children: [
                        _fullTile(
                          emoji: '💵',
                          icon: Icons.check_circle_outline,
                          label: 'إجمالي المدفوع'.tr(),
                          amount: (s['paid'] ?? 0).toDouble(),
                          color: Colors.green[700]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل المدفوع'.tr(),
                            items: paidInvoiceDetails,
                            nameOf: (m) =>
                                (m['customer_name'] ?? 'غير معروف'.tr()).toString(),
                            subtitleOf: (m) => _orderSubtitle(m),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.green[700]!,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        _fullTile(
                          emoji: '💳',
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'إجمالي الآجل'.tr(),
                          amount: (s['debt'] ?? 0).toDouble(),
                          color: Colors.red[700]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل الآجل'.tr(),
                            items: debtInvoiceDetails,
                            nameOf: (m) =>
                                (m['customer_name'] ?? 'غير معروف'.tr()).toString(),
                            subtitleOf: (m) => _orderSubtitle(m),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.red[700]!,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        _fullTile(
                          emoji: '✅',
                          icon: Icons.price_check,
                          label: 'محصّل من الآجل'.tr(),
                          amount: (s['debt_collected'] ?? 0).toDouble(),
                          color: Colors.teal[700]!,
                          onTap: () => _showDebtCollectedDetails(debtDetails),
                        ),
                        _fullTile(
                          emoji: '💸',
                          icon: Icons.money_off,
                          label: 'المصروفات'.tr(),
                          amount: (s['expenses'] ?? 0).toDouble(),
                          color: Colors.orange[800]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل المصروفات'.tr(),
                            items: expensesDetailsList,
                            nameOf: (m) =>
                                (m['description'] ?? 'مصروف'.tr()).toString(),
                            subtitleOf: (m) =>
                                'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['date'])}),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.orange[800]!,
                            icon: Icons.money_off,
                          ),
                        ),
                        _fullTile(
                          emoji: '📱',
                          icon: Icons.phone_android,
                          label: 'فودافون كاش'.tr(),
                          amount: (s['vodafone_cash_total'] ?? 0).toDouble(),
                          color: Colors.pink[700]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل فودافون كاش'.tr(),
                            items: vodafoneNotes,
                            nameOf: (m) =>
                                (m['note'] as String?)?.trim().isNotEmpty ==
                                        true
                                    ? m['note']
                                    : 'فودافون كاش',
                            subtitleOf: (m) =>
                                'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['created_at'])}),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.pink[700]!,
                            icon: Icons.phone_android,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _fullFooterBanner(
                color: Colors.deepPurple,
                lines: [
                  MapEntry(
                    '🏆 المدفوع + المحصّل'.tr(),
                    '${((s['paid'] ?? 0) + (s['debt_collected'] ?? 0)).toStringAsFixed(2)} ${Money.txt}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullShiftCard(
    Map<String, dynamic> s, {
    required List<Map<String, dynamic>> paidInvoiceDetails,
    required List<Map<String, dynamic>> debtInvoiceDetails,
    required List<Map<String, dynamic>> debtDetails,
    required List<Map<String, dynamic>> expensesDetailsList,
    required List<Map<String, dynamic>> salesDetailsList,
    required List<Map<String, dynamic>> vodafoneNotes,
    required Widget deleteButton,
  }) {
    final totalSalesWithCharge =
        (s['total_sales'] ?? 0) + (s['charge_in'] ?? 0) - (s['expenses'] ?? 0);
    final paidPlusCollected = (s['paid'] ?? 0) + (s['debt_collected'] ?? 0);
    final paidPlusCollectedCash =
        (s['paid'] ?? 0) + (s['debt_collected'] ?? 0) - (s['expenses'] ?? 0);

    final discount = (s['debt_collected_discount'] ?? 0) as num;
    final collectedCount = (s['debt_collected_count'] ?? 0) as num;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fullHeader(
                title: 'الموظف: {v1}'.tr({'v1': s['staff_name']}),
                metaLines: [
                  '📅 ${formatArabicDate(DateTime.parse(s['shift_date']))}',
                  '🕐 بدأ: {v1}'.tr({'v1': formatArabicDate(DateTime.parse(s['check_in']))}),
                  if (s['check_out'] != null)
                    '🕓 انتهى: {v1}'.tr({'v1': formatArabicDate(DateTime.parse(s['check_out']))}),
                  '⏱️ {v1} ساعة'.tr({'v1': s['total_hours']?.toStringAsFixed(2) ?? 0}),
                ],
                trailing: deleteButton,
                color: Colors.green,
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = _fullGridColumns(constraints.maxWidth);
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _fullTile(
                          emoji: '💵',
                          icon: Icons.check_circle_outline,
                          label: 'المدفوع'.tr(),
                          amount: (s['paid'] ?? 0).toDouble(),
                          color: Colors.green[700]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل المدفوع'.tr(),
                            items: paidInvoiceDetails,
                            nameOf: (m) =>
                                (m['customer_name'] ?? 'غير معروف'.tr()).toString(),
                            subtitleOf: (m) => _orderSubtitle(m),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.green[700]!,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        _fullTile(
                          emoji: '💳',
                          icon: Icons.money_off,
                          label: 'الآجل'.tr(),
                          amount: (s['debt'] ?? 0).toDouble(),
                          color: Colors.orange[800]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل الآجل'.tr(),
                            items: debtInvoiceDetails,
                            nameOf: (m) =>
                                (m['customer_name'] ?? 'غير معروف'.tr()).toString(),
                            subtitleOf: (m) => _orderSubtitle(m),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.orange[800]!,
                            icon: Icons.money_off,
                          ),
                        ),
                        _fullTile(
                          emoji: '✅',
                          icon: Icons.price_check,
                          label: 'محصّل من الآجل'.tr(),
                          amount: (s['debt_collected'] ?? 0).toDouble(),
                          color: Colors.teal[700]!,
                          onTap: () => _showDebtCollectedDetails(debtDetails),
                          subLine: collectedCount > 0
                              ? ('{collectedCount} عملية'.tr({'collectedCount': collectedCount}) + '{v1}'.tr({'v1': discount > 0 ? ' • خصم {v1}'.tr({'v1': discount.toStringAsFixed(2)}) : ''}))
                              : null,
                        ),
                        _fullTile(
                          emoji: '💸',
                          icon: Icons.money_off,
                          label: 'المصروفات'.tr(),
                          amount: (s['expenses'] ?? 0).toDouble(),
                          color: Colors.orange[800]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل المصروفات'.tr(),
                            items: expensesDetailsList,
                            nameOf: (m) =>
                                (m['description'] ?? 'مصروف'.tr()).toString(),
                            subtitleOf: (m) =>
                                'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['date'])}),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.orange[800]!,
                            icon: Icons.money_off,
                          ),
                        ),
                        _fullTile(
                          emoji: '📱',
                          icon: Icons.phone_android,
                          label: 'فودافون كاش'.tr(),
                          amount: (s['vodafone_cash_total'] ?? 0).toDouble(),
                          color: Colors.pink[700]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل فودافون كاش'.tr(),
                            items: vodafoneNotes,
                            nameOf: (m) =>
                                (m['note'] as String?)?.trim().isNotEmpty ==
                                        true
                                    ? m['note']
                                    : 'فودافون كاش',
                            subtitleOf: (m) =>
                                'بواسطة: {v1} - {v2}'.tr({'v1': m['added_by'] ?? '-', 'v2': _formatDateSafe(m['created_at'])}),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.pink[700]!,
                            icon: Icons.phone_android,
                          ),
                        ),
                        _fullTile(
                          emoji: '💰',
                          icon: Icons.point_of_sale,
                          label: 'إجمالي المبيعات'.tr(),
                          amount: totalSalesWithCharge.toDouble(),
                          color: Colors.blue[700]!,
                          onTap: () => _showDetailsSheet(
                            title: 'تفاصيل إجمالي المبيعات'.tr(),
                            items: salesDetailsList,
                            nameOf: (m) =>
                                (m['customer_name'] ?? 'غير معروف'.tr()).toString(),
                            subtitleOf: (m) => _orderSubtitle(m,
                                notePrefix: (m['note'] ?? '').toString()),
                            amountOf: (m) =>
                                ((m['amount'] ?? 0) as num).toDouble(),
                            color: Colors.blue[700]!,
                            icon: Icons.point_of_sale,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _fullFooterBanner(
                color: Colors.green[800]!,
                lines: [
                  MapEntry('🏆 المدفوع + المحصّل'.tr(),
                      '${paidPlusCollected.toStringAsFixed(2)} ${Money.txt}'),
                  MapEntry('💚 صافي الكاش'.tr(),
                      '${paidPlusCollectedCash.toStringAsFixed(2)} ${Money.txt}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
