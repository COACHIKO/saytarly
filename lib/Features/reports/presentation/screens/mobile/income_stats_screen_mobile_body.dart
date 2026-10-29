part of '../IncomeStatsScreen.dart';

/// جسم شاشات تقرير الدخل (الرئيسية + التفاصيل) — نسخة الموبايل (زي ما كانت بالظبط).
extension _IncomeStatsMobileBody on _IncomeStatsScreenState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text('تقرير الدخل'.tr())),
      body: ListView(
        children: [
          _statCard(
            '🔹 اجمالي الفواتير'.tr(),
            sessionsCount.toString(),
            Icons.today,
            Colors.blue,
            () {},
          ),
          _statCard(
            '🔹 دخل اليوم'.tr(),
            incomeToday.toStringAsFixed(2),
            Icons.today,
            Colors.blue,
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TodayDetailsScreen()));
            },
          ),
          _statCard(
            '🟢 دخل الشيفت'.tr(),
            incomeShift.toStringAsFixed(2),
            Icons.point_of_sale,
            Colors.green,
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ShiftDetailsScreen()));
            },
          ),
          _statCard(
            '💰 الدخل الكلي'.tr(),
            /*     incomeTotal.toStringAsFixed(2),*/
            incomeShift.toStringAsFixed(2),
            Icons.account_balance_wallet,
            Colors.orange,
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TotalIncomeDetailsScreen()));
            },
          ),
        ],
      ),
    );
  }
}

/// جسم شاشة تفاصيل دخل اليوم — نسخة الموبايل (زي ما كانت بالظبط).
extension _TodayDetailsMobileBody on TodayDetailsScreen {

  Widget _buildMobileBody(BuildContext context) {
    String _sourceLabel(String source) {
      switch (source) {
        case 'debt':
          return 'الفلوس الاجله تم دفعها'.tr();
        case 'invoice':
          return 'فواتير'.tr();
        case 'topup':
          return 'شحن'.tr();
        default:
          return source ?? 'آخر'.tr();
      }
    }

    return Scaffold(
      appBar: AppBar(title:  Text('تفاصيل دخل اليوم'.tr())),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadData(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (!snap.hasData) return  Center(child: Text('لا توجد بيانات'.tr()));

          final data = snap.data!;
          final invoices = data['invoices'] as List;
          final invoicesTotal = _toDouble(data['invoices_total']);
          final cashItems = data['cash_items'] as List;
          final cashTotals =
              Map<String, double>.from(data['cash_totals'] as Map);
          final expenses = data['expenses'] as List;
          final expensesTotal = _toDouble(data['expenses_total']);
          final invoicesPaidTotal = invoices
              .where((i) => i['payment_type'] == 'paid')
              .fold<double>(0.0, (sum, i) => sum + _toDouble(i['total_cost']));

          final invoicesDebtTotal = invoices
              .where((i) =>
                  i['payment_type'] == 'debt' ||
                  i['payment_type'] == 'علي الحساب')
              .fold<double>(0.0, (sum, i) => sum + _toDouble(i['total_cost']));

// لحساب الصافي بدون تكرار الدين
          final net = invoicesPaidTotal + invoicesDebtTotal - expensesTotal;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ListTile(
                  title: Text('ملخص اليوم'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18))),
              ListTile(
                  title: Text('مبيعات (فواتير مدفوعة)'.tr()),
                  trailing: Text('{v1} ج'.tr({'v1': invoicesTotal.toStringAsFixed(2)}))),
              ...cashTotals.entries.map((e) => ListTile(
                  title: Text('دخل: {v1}'.tr({'v1': _sourceLabel(e.key)})),
                  trailing: Text('{v1} ج'.tr({'v1': e.value.toStringAsFixed(2)})))),
              ListTile(
                  title: Text('المصروفات'.tr()),
                  trailing: Text('- {v1} ج'.tr({'v1': expensesTotal.toStringAsFixed(2)}))),
              Divider(),
              ListTile(
                  title: Text('الصافي اليومي'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('{v1} ج'.tr({'v1': net.toStringAsFixed(2)}))),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),

              // تفاصيل الفواتير
              ListTile(
                  title: Text('تفاصيل الفواتير المصرّفة اليوم'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...invoices.map<Widget>((inv) {
                final start = inv['start_time'] != null
                    ? _formatArabicDateTime(inv['start_time']).toString()
                    : '';
                return ListTile(
                  title: Text('فاتورة #{v1}'.tr({'v1': inv['id']})),
                  subtitle: Text(start),
                  trailing: Text(
                      '{v1} ج'.tr({'v1': _toDouble(inv['total_cost']).toStringAsFixed(2)})),
                );
              }),

              const Divider(),

              // تفاصيل مداخل الكاش دراور
              ListTile(
                  title: Text('تفاصيل مداخل الكاش (اليوم)'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...cashItems.map<Widget>((c) {
                return ListTile(
                  title: Text(_sourceLabel(c['source'])),
                  subtitle: Text(
                      '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(c['date']), 'v2': c['cashier'] ?? '-'})),
                  trailing:
                      Text('{v1} ج'.tr({'v1': _toDouble(c['amount']).toStringAsFixed(2)})),
                );
              }),

              const Divider(),

              // تفاصيل المصروفات
              ListTile(
                  title: Text('تفاصيل المصروفات (اليوم)'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...expenses.map<Widget>((ex) {
                return ListTile(
                  title: Text('{v1}'.tr({'v1': ex['description'] ?? ex['note'] ?? 'مصروف'.tr()})),
                  subtitle: Text(
                      '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(ex['date']), 'v2': ex['added_by'] ?? '-'})),
                  trailing:
                      Text('- {v1} ج'.tr({'v1': _toDouble(ex['amount']).toStringAsFixed(2)})),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// جسم شاشة تفاصيل دخل الشيفت — نسخة الموبايل (زي ما كانت بالظبط).
extension _ShiftDetailsMobileBody on ShiftDetailsScreen {

  Widget _buildMobileBody(BuildContext context) {
    String _sourceLabel(String source) {
      switch (source) {
        case 'debt':
          return 'الفلوس الاجله تم دفعها'.tr();
        case 'invoice':
          return 'فاتورة'.tr();
        case 'topup':
          return 'شحن'.tr();
        default:
          return source ?? 'آخر'.tr();
      }
    }

    return Scaffold(
      appBar: AppBar(title:  Text('تفاصيل دخل الشيفت'.tr())),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadShiftItems(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (!snap.hasData) return  Center(child: Text('لا توجد بيانات'.tr()));

          final rows = snap.data!;
          // احسب المجاميع حسب المصدر
          final Map<String, double> sums = {};
          double total = 0.0;
          for (final r in rows) {
            final src = (_sourceLabel(r['source']) ?? 'other').toString();
            final amt = _toDouble(r['amount']);
            sums[src] = (sums[src] ?? 0.0) + amt;
            total += amt;
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ListTile(
                  title: Text('ملخص الشيفت'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18))),
              ...sums.entries.map((e) => ListTile(
                  title: Text('دخل: {v1}'.tr({'v1': e.key})),
                  trailing: Text('{v1} ج'.tr({'v1': e.value.toStringAsFixed(2)})))),
              Divider(),
              ListTile(
                  title: Text('المجموع الكلي للشيفت'.tr()),
                  trailing: Text('{v1} ج'.tr({'v1': total.toStringAsFixed(2)}))),
              const Divider(),
              ...rows.map((r) => ListTile(
                    title: Text("${_sourceLabel(r['source']) ?? 'other'}"),
                    subtitle: Text("${_formatArabicDateTime(r['date'])}"),
                    trailing:
                        Text('{v1} ج'.tr({'v1': _toDouble(r['amount']).toStringAsFixed(2)})),
                  )),
            ],
          );
        },
      ),
    );
  }
}

/// جسم شاشة تفاصيل الدخل الكلي — نسخة الموبايل (زي ما كانت بالظبط).
extension _TotalIncomeDetailsMobileBody on TotalIncomeDetailsScreen {

  Widget _buildMobileBody(BuildContext context) {
    String _sourceLabel(String source) {
      switch (source) {
        case 'debt':
          return 'الفلوس الاجله تم دفعها'.tr();
        case 'invoice':
          return 'فاتورة'.tr();
        case 'topup':
          return 'شحن'.tr();
        default:
          return source ?? 'آخر'.tr();
      }
    }

    return Scaffold(
      appBar: AppBar(title:  Text('تفاصيل الدخل الكلي'.tr())),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadAll(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (!snap.hasData) return  Center(child: Text('لا توجد بيانات'.tr()));

          final data = snap.data!;
          final invoices = data['invoices'] as List;
          final expenses = data['expenses'] as List;
          final totalInvoices = _toDouble(data['total_invoices']);
          final totalTopups = _toDouble(data['total_topups']);

          final totalExpenses = _toDouble(data['total_expenses']);
          final net = _toDouble(data['net']);
          final topupsList = data['topups_list'] as List;
          final debtList = data['debt_list'] as List;
          final totalDebtPayments = _toDouble(data['total_debt_payments']);

          final netCorrected =
              totalInvoices + totalTopups + totalDebtPayments - totalExpenses;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ListTile(
                  title: Text('ملخص إجمالي'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18))),
              ListTile(
                  title: Text('إجمالي الفواتير (مدفوعة)'.tr()),
                  trailing: Text('{v1} ج'.tr({'v1': totalInvoices.toStringAsFixed(2)}))),
              ListTile(
                  title: Text('إجمالي الشحنات (Topups)'.tr()),
                  trailing: Text('{v1} ج'.tr({'v1': totalTopups.toStringAsFixed(2)}))),
              ListTile(
                  title: Text('إجمالي دفعات الديون'.tr()),
                  trailing: Text('{v1} ج'.tr({'v1': totalDebtPayments.toStringAsFixed(2)}))),
              ListTile(
                  title: Text('إجمالي المصروفات'.tr()),
                  trailing: Text('- {v1} ج'.tr({'v1': totalExpenses.toStringAsFixed(2)}))),
              Divider(),
              /*        ListTile(
                  title: Text("صافي الدخل الكلي",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text("${netCorrected.toStringAsFixed(2)} ج")),

              const SizedBox(height: 12),

              // قوائم التفاصيل
              const Divider(),*/
              ListTile(
                  title: Text('الفواتير (مدفوعة)'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...invoices.map<Widget>((inv) {
                return ListTile(
                  title: Text('فاتورة #{v1}'.tr({'v1': inv['id']})),
                  subtitle: Text(
                      _formatArabicDateTime(inv['start_time'] ?? inv['date'])),
                  trailing: Text(
                      '{v1} ج'.tr({'v1': _toDouble(inv['total_cost']).toStringAsFixed(2)})),
                );
              }),
              const Divider(),
              ListTile(
                  title: Text('الشحنات '.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...topupsList.map<Widget>((t) {
                return ListTile(
                  title: Text("${_sourceLabel(t['source']) ?? 'Cashier'}"),
                  subtitle: Text("${_formatArabicDateTime(t['date'])}"),
                  trailing:
                      Text('{v1} ج'.tr({'v1': _toDouble(t['amount']).toStringAsFixed(2)})),
                );
              }),
              const Divider(),
              ListTile(
                  title: Text('دفعات الديون'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...debtList.map<Widget>((d) {
                return ListTile(
                  title: Text('{v1}'.tr({'v1': _sourceLabel(d['source']) ?? 'الديون'.tr()})),
                  subtitle: Text(
                      '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(d['date']), 'v2': d['cashier'] ?? '-'})),
                  trailing:
                      Text('{v1} ج'.tr({'v1': _toDouble(d['amount']).toStringAsFixed(2)})),
                );
              }),
              const Divider(),
              ListTile(
                  title: Text('المصروفات'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...expenses.map<Widget>((ex) {
                return ListTile(
                  title: Text('{v1}'.tr({'v1': ex['description'] ?? ex['note'] ?? 'مصروف'.tr()})),
                  subtitle: Text(
                      '{v1} - بواسطة: {v2}'.tr({'v1': _formatArabicDateTime(ex['date']), 'v2': ex['added_by'] ?? '-'})),
                  trailing:
                      Text('- {v1} ج'.tr({'v1': _toDouble(ex['amount']).toStringAsFixed(2)})),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

