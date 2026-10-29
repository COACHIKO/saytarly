import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/income_stats_screen_mobile_body.dart';
part 'desktop/income_stats_screen_windows_body.dart';

/// IncomeStatsScreen — شامل + صفحات التفاصيل
class IncomeStatsScreen extends StatefulWidget {
  const IncomeStatsScreen({super.key});

  @override
  State<IncomeStatsScreen> createState() => _IncomeStatsScreenState();
}

class _IncomeStatsScreenState extends State<IncomeStatsScreen> {
  double incomeToday = 0.0;
  double incomeShift = 0.0;
  double incomeTotal = 0.0;
  int sessionsCount = 0;
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Helper to safely read SUM results
  double _sumFromRow(Map row, String key) {
    final v = row[key];
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<void> _loadStats() async {
    final db = await DBHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final invoices = await db.query('invoices');

    // -----------------------
    // فواتير النهارده (باستخدام start_time كما في الـ ReportsScreen)
    // -----------------------
    final invoicesTodayRows = await db.rawQuery("""
      SELECT SUM(total_cost) AS total FROM invoices
      WHERE payment_type = 'paid' AND start_time LIKE ?
    """, ["$today%"]);
    final invoicesToday = _sumFromRow(invoicesTodayRows.first, 'total');

    // -----------------------
    // مداخل الكاش دراور النهارده (أي income) ولكن نميز topup/debt
    // -----------------------
    final cashIncomeTodayRows = await db.rawQuery("""
      SELECT SUM(amount) AS total FROM cash_drawer
      WHERE type='income' AND ((source NOT IN ('topup','debt')) OR source IS NULL) AND date LIKE ?
    """, ["$today%"]);
    final cashIncomeToday = _sumFromRow(cashIncomeTodayRows.first, 'total');

    final topupsTodayRows = await db.rawQuery("""
      SELECT SUM(amount) AS total FROM cash_drawer
      WHERE type='income' AND source='topup' AND date LIKE ?
    """, ["$today%"]);
    final topupsToday = _sumFromRow(topupsTodayRows.first, 'total');

    final debtPaymentsTodayRows = await db.rawQuery("""
      SELECT SUM(amount) AS total FROM cash_drawer
      WHERE type='income' AND source='debt' AND date LIKE ?
    """, ["$today%"]);
    final debtPaymentsToday = _sumFromRow(debtPaymentsTodayRows.first, 'total');

    // -----------------------
    // مصروفات اليوم
    // -----------------------
    final expensesTodayRows = await db.rawQuery("""
      SELECT SUM(amount) AS total FROM expenses
      WHERE date LIKE ?
    """, ["$today%"]);
    final expensesToday = _sumFromRow(expensesTodayRows.first, 'total');

    // حساب دخل اليوم: فواتير اليوم + مداخل الكاش (غير topup/debt) + topups + دفعات الديون - مصاريف اليوم
    final netToday =
        invoicesToday + topupsToday + debtPaymentsToday - expensesToday;

    // -----------------------
    // دخل الشيفت (كل income في cash_drawer)
    // -----------------------
    final shiftRows = await db.rawQuery("""
      SELECT SUM(amount) AS total FROM cash_drawer
      WHERE type='income'
    """);
    final shiftIncome = _sumFromRow(shiftRows.first, 'total');

    // -----------------------
    // الدخل الكلي: فواتير مدفوعة (كلها) + كل topups + كل debt payments - كل المصروفات
    // -----------------------
    final allInvoicesRows = await db.rawQuery("""
      SELECT SUM(total_cost) AS total FROM invoices WHERE payment_type='paid'
    """);
    final totalInvoiceIncome = _sumFromRow(allInvoicesRows.first, 'total');

    final allTopupsRows = await db.rawQuery("""
      SELECT SUM(amount) AS total FROM cash_drawer WHERE type='income' AND source='topup'
    """);
    final totalTopups = _sumFromRow(allTopupsRows.first, 'total');

    final allDebtPaymentsRows = await db.rawQuery("""
      SELECT SUM(amount) AS total FROM cash_drawer WHERE type='income' AND source='debt'
    """);
    final totalDebtPayments = _sumFromRow(allDebtPaymentsRows.first, 'total');

    final allExpensesRows =
        await db.rawQuery("SELECT SUM(amount) AS total FROM expenses");
    final totalExpenses = _sumFromRow(allExpensesRows.first, 'total');

    final totalIncome =
        totalInvoiceIncome + totalTopups + totalDebtPayments - totalExpenses;
    String _sourceLabel(String source) {
      switch (source) {
        case 'debt':
          return 'الحساب'.tr();
        case 'invoice':
          return 'فاتورة'.tr();
        case 'topup':
          return 'شحن'.tr();
        default:
          return source ?? 'آخر'.tr();
      }
    }

    if (!mounted) return;
    setState(() {
      incomeToday = netToday;
      incomeShift = shiftIncome;
      incomeTotal = totalIncome;
      sessionsCount = invoices.length;
    });
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(fontSize: 20, color: color)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

/// ===================================================================================
/// تفاصيل دخل اليوم — تعرض: فواتير اليوم، مداخل الكاش، شحنات، دفعات ديون، مصاريف
/// ===================================================================================
class TodayDetailsScreen extends StatelessWidget {
  const TodayDetailsScreen({super.key});

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<Map<String, dynamic>> loadData() async {
    final db = await DBHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // فواتير اليوم (paid)
    final invoicesToday = await db.rawQuery("""
      SELECT * FROM invoices WHERE payment_type='paid' AND start_time LIKE ?
    """, ["$today%"]);

    // مداخل كاش دراور اليوم (بناءً على المصدر)
    final incomesToday = await db.rawQuery("""
      SELECT * FROM cash_drawer WHERE type='income' AND date LIKE ? ORDER BY date DESC
    """, ["$today%"]);

    // مصروفات اليوم
    final expensesToday = await db.rawQuery("""
      SELECT * FROM expenses WHERE date LIKE ? ORDER BY date DESC
    """, ["$today%"]);

    // احسب المجموعات
    final invoicesTotal = (invoicesToday.isEmpty)
        ? 0.0
        : _toDouble(
            invoicesToday.fold(0.0, (p, e) => p + _toDouble(e['total_cost'])));
    final cashTotals = incomesToday.fold<Map<String, double>>({}, (map, row) {
      final src = (row['source'] ?? 'other').toString();
      final amt = _toDouble(row['amount']);
      map[src] = (map[src] ?? 0.0) + amt;
      return map;
    });
    final expensesTotal =
        expensesToday.fold(0.0, (p, e) => p + _toDouble(e['amount']));

    return {
      'invoices': invoicesToday,
      'invoices_total': invoicesTotal,
      'cash_items': incomesToday,
      'cash_totals': cashTotals,
      'expenses': expensesToday,
      'expenses_total': expensesTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

/// ===================================================================================
/// تفاصيل دخل الشيفت — عرض كامل لكل incomes (grouped + list)
/// ===================================================================================
class ShiftDetailsScreen extends StatelessWidget {
  const ShiftDetailsScreen({super.key});

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> loadShiftItems() async {
    final db = await DBHelper.database;
    final rows = await db.rawQuery("""
      SELECT * FROM cash_drawer WHERE type='income' ORDER BY date DESC
    """);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

/// ===================================================================================
/// تفاصيل الدخل الكلي — فواتير مدفوعة + شحنات + دفعات ديون + مصروفات (والمجاميع)
/// ===================================================================================
class TotalIncomeDetailsScreen extends StatelessWidget {
  const TotalIncomeDetailsScreen({super.key});

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<Map<String, dynamic>> loadAll() async {
    final db = await DBHelper.database;

    final invoices =
        await db.rawQuery("SELECT * FROM invoices ORDER BY start_time DESC");
    final expenses =
        await db.rawQuery("SELECT * FROM expenses ORDER BY date DESC");

    final paidInvoices =
        invoices.where((i) => i['payment_type'] == 'paid').toList();
    final debtInvoices =
        invoices.where((i) => i['payment_type'] == 'debt').toList();

    final totalInvoices = paidInvoices.fold<double>(
        0.0, (sum, i) => sum + _toDouble(i['total_cost']));
    final totalTopupsRow = await db.rawQuery(
        "SELECT SUM(amount) AS total FROM cash_drawer WHERE type='income' AND source='topup'");
    final totalTopups = _toDouble(totalTopupsRow.first['total']);

    // الديون: استبعد الديون المرتبطة بفواتير مدفوعة بالكامل
    final debtListRaw = await db.rawQuery(
        "SELECT * FROM cash_drawer WHERE type='income' AND source='debt' ORDER BY date DESC");

    final debtList = debtListRaw.where((d) {
      final invoiceId = d['invoice_id'];
      if (invoiceId == null) return true; // غير مرتبط بأي فاتورة
      // استبعد إذا الفاتورة كلها مدفوعة
      return !paidInvoices.any((i) => i['id'] == invoiceId);
    }).toList();

    final totalDebtPayments = debtList
        .where((d) =>
            !_toDouble(d['amount']).isNaN &&
            !(d['invoice_id'] != null &&
                invoices.any((inv) => inv['id'] == d['invoice_id'])))
        .fold<double>(0.0, (sum, d) => sum + _toDouble(d['amount']));

    final totalExpenses =
        expenses.fold<double>(0.0, (sum, e) => sum + _toDouble(e['amount']));

    final net = totalInvoices + totalTopups + totalDebtPayments - totalExpenses;

    // مخرجات
    final topupsList = await db.rawQuery(
        "SELECT * FROM cash_drawer WHERE type='income' AND source='topup' ORDER BY date DESC");

    return {
      'invoices': invoices,
      'expenses': expenses,
      'total_invoices': totalInvoices,
      'total_topups': totalTopups,
      'total_debt_payments': totalDebtPayments,
      'total_expenses': totalExpenses,
      'net': net,
      'topups_list': topupsList,
      'debt_list': debtList,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

String _formatArabicDateTime(String dateStr) {
  final date = DateTime.parse(dateStr);

   final days = [
    "الاثنين",
    'الثلاثاء'.tr(),
    'الأربعاء'.tr(),
    'الخميس'.tr(),
    'الجمعة'.tr(),
    'السبت'.tr(),
    'الأحد'.tr()
  ];

  final dayName = days[date.weekday - 1];

  final formatted = DateFormat("yyyy/MM/dd – hh:mm a").format(date);

  return "$dayName – $formatted";
}
