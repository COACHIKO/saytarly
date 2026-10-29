/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:flutter/foundation.dart';

class ShiftsReportScreen extends StatefulWidget {
  @override
  State<ShiftsReportScreen> createState() => _ShiftsReportScreenState();
}

class _ShiftsReportScreenState extends State<ShiftsReportScreen> {
  List<Map<String, dynamic>> shifts = [];
  final bool isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts({DateTime? date}) async {
    final data = await DBHelper.getAllShifts(date: date);

    List<Map<String, dynamic>> editableShifts = [];

    for (var s in data) {
      final shift = Map<String, dynamic>.from(s);

      final db = await DBHelper.database;

      final rangeStart = shift['check_in'];
      final rangeEnd = shift['check_out'] ?? DateTime.now().toIso8601String();

      // =========================
      // 1️⃣ حساب المدفوع والآجل من الفواتير
      // =========================
      final invoices = await db.query(
        'invoices',
        where:
            'shift_id = ? OR ((shift_id IS NULL OR shift_id = 0) AND staff_name = ? AND start_time >= ? AND start_time <= ?)',
        whereArgs: [shift['id'], shift['staff_name'], rangeStart, rangeEnd],
      );

      double paid = 0.0;
      double debt = 0.0;

      for (var inv in invoices) {
        final type = inv['payment_type'] as String?;
        final total = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;

        if (type == 'paid') {
          paid += total;
        } else if (type == 'debt' || type == 'علي الحساب') {
          final invoiceId = inv['id'];
          final debtRows = await db.query(
            'debts',
            where: 'invoice_id = ?',
            whereArgs: [invoiceId],
          );

          double totalPaidPartial = 0.0;

          if (debtRows.isNotEmpty) {
            final debtId = debtRows.first['id'];
            final debtPayments = await db.query(
              'debt_payments',
              where: 'debt_id = ?',
              whereArgs: [debtId],
            );

            totalPaidPartial = debtPayments.fold<double>(
              0.0,
              (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
            );
          }

          if (totalPaidPartial >= total) {
            paid += total;
          } else {
            paid += totalPaidPartial;
            debt += (total - totalPaidPartial);
          }
        }
      }
      final currentShiftInvoiceIds =
          invoices.map((e) => e['id'] as int).toSet();
      // =========================
      // 2️⃣ حساب الشحن من machine_balance_logs
      // =========================
      final chargeLogs = await db.query(
        'machine_balance_logs',
        where: 'date >= ? AND date <= ?',
        whereArgs: [rangeStart, rangeEnd],
      );

      double totalDeposits = 0.0;
      double totalWithdraws = 0.0;

      for (var log in chargeLogs) {
        double amount = (log['amount'] as num).toDouble();
        if (log['type'] == 'deposit') {
          totalDeposits += amount;
          paid += amount;
        } else if (log['type'] == 'withdraw') {
          totalWithdraws += amount;
          debt += amount;
        }
      }

      // =========================
      // 🆕 3️⃣ المحصّل من الآجل (ديون قديمة اتحصلت في الشيفت ده)
      // =========================
      final debtPaymentsRowsRaw = await db.query(
        'debt_payments',
        where: 'paid_at >= ? AND paid_at <= ?',
        whereArgs: [rangeStart, rangeEnd],
        orderBy: 'paid_at ASC',
      );

      final debtPaymentsRows = debtPaymentsRowsRaw.where((p) {
        final invoiceId = p['invoice_id'];

        if (invoiceId == null) {
          return true;
        }

        // لو الفاتورة اتعملت في نفس الشيفت
        // لا تعتبرها "تحصيل دين"
        return !currentShiftInvoiceIds.contains(invoiceId as int);
      }).toList();

      final debtCollected = debtPaymentsRows.fold<double>(
        0.0,
        (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
      );
      final debtCollectedDiscount = debtPaymentsRows.fold<double>(
        0.0,
        (sum, p) => sum + ((p['discount'] ?? 0) as num).toDouble(),
      );

      shift['paid'] = paid;
      shift['debt'] = debt;
      shift['charge_in'] = totalDeposits;
      shift['charge_out'] = totalWithdraws;
      shift['debt_collected'] = debtCollected; // 🆕
      shift['debt_collected_discount'] = debtCollectedDiscount; // 🆕
      shift['debt_collected_count'] = debtPaymentsRows.length; // 🆕

      // =========================
      // 4️⃣ حساب السجائر
      // =========================
      final invoiceItems = await db.rawQuery('''
        SELECT ii.total, d.temperature 
        FROM invoice_items ii
        LEFT JOIN drinks d ON d.id = ii.drink_id
        WHERE ii.invoice_id IN (
          SELECT id FROM invoices
          WHERE shift_id = ? OR ((shift_id IS NULL OR shift_id = 0) AND staff_name = ? AND start_time >= ? AND start_time <= ?)
        )
      ''', [shift['id'], shift['staff_name'], rangeStart, rangeEnd]);

      double cigaretteTotal = 0.0;
      for (var item in invoiceItems) {
        if (item['temperature'] == 'cigarette') {
          cigaretteTotal += (item['total'] as num).toDouble();
        }
      }
      shift['cigarettes'] = cigaretteTotal;
      final totalCash = ((shift['paid'] ?? 0) as num).toDouble() +
          ((shift['debt_collected'] ?? 0) as num).toDouble() -
          ((shift['expenses'] ?? 0) as num).toDouble();
      // =========================
      // 5️⃣ المصروفات
      // =========================
      final expenses = await DBHelper.getExpensesByShift(shift['id'] as int);
      final totalExpenses = expenses.fold<double>(
          0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));
      shift['expenses'] = totalExpenses;

      editableShifts.add(shift);
    }

    setState(() => shifts = editableShifts);
  }

  String formatArabicDate(DateTime date) {
    const days = [
      "الاثنين",
      "الثلاثاء",
      "الأربعاء",
      "الخميس",
      "الجمعة",
      "السبت",
      "الأحد"
    ];
    const months = [
      "يناير",
      "فبراير",
      "مارس",
      "أبريل",
      "مايو",
      "يونيو",
      "يوليو",
      "أغسطس",
      "سبتمبر",
      "أكتوبر",
      "نوفمبر",
      "ديسمبر"
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? "م" : "ص";
    final minute = date.minute.toString().padLeft(2, '0');

    return "$dayName، ${date.day} $monthName ${date.year} - $hour:$minute $ampm";
  }

  void _generateDailySummary() {
    if (shifts.isEmpty) return;

    Map<String, Map<String, dynamic>> grouped = {};

    for (var s in shifts) {
      final name = s['staff_name'];

      if (!grouped.containsKey(name)) {
        grouped[name] = {
          'staff_name': name,
          'paid': 0.0,
          'debt': 0.0,
          'expenses': 0.0,
          'charge_out': 0.0,
          'charge_in': 0.0,
          'total_hours': 0.0,
          'cigarettes': 0.0,
          'debt_collected': 0.0, // 🆕
          'count': 0,
        };
      }

      grouped[name]!['paid'] += (s['paid'] ?? 0);
      grouped[name]!['debt'] += (s['debt'] ?? 0);
      grouped[name]!['expenses'] += (s['expenses'] ?? 0);
      grouped[name]!['charge_out'] += (s['charge_out'] ?? 0);
      grouped[name]!['charge_in'] += (s['charge_in'] ?? 0);
      grouped[name]!['total_hours'] += (s['total_hours'] ?? 0);
      grouped[name]!['cigarettes'] += (s['cigarettes'] ?? 0);
      grouped[name]!['debt_collected'] += (s['debt_collected'] ?? 0); // 🆕
      grouped[name]!['count'] += 1;
    }

    setState(() {
      shifts = grouped.values.toList();
    });
  }

  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الشيفتات'),
        actions: [
          if (isMobile) ...[
            IconButton(
              tooltip: "اختر تاريخ",
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _loadShifts(date: picked);
                }
              },
            ),
            IconButton(
              tooltip: "ملخص اليوم",
              icon: const Icon(Icons.summarize),
              onPressed: _generateDailySummary,
            ),
            IconButton(
              tooltip: "عرض الكل",
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                setState(() => _selectedDate = null);
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
                    setState(() => _selectedDate = picked);
                    _loadShifts(date: picked);
                  }
                },
                child: const Text("اختر تاريخ"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.tonal(
                onPressed: _generateDailySummary,
                child: const Text("ملخص اليوم"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.tonal(
                onPressed: () {
                  setState(() => _selectedDate = null);
                  _loadShifts();
                },
                child: const Text("عرض الكل"),
              ),
            ),
          ],
        ],
      ),
      body: shifts.isEmpty
          ? Center(child: Text('لا توجد بيانات شيفتات بعد'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: shifts.length,
                itemBuilder: (context, i) {
                  final s = shifts[i];
                  final bool isSummary = s['check_in'] == null;
                  final summaryTotal = (s['paid'] ?? 0) +
                      (s['charge_in'] ?? 0) -
                      (s['expenses'] ?? 0) +
                      (s['debt_collected'] ?? 0);
                  if (isSummary) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.person, color: Colors.blue),
                        title: Text("الموظف: ${s['staff_name']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "💵 إجمالي المدفوع: ${s['paid'].toStringAsFixed(2)}"),
                            Text(
                                "💳 إجمالي الآجل: ${s['debt'].toStringAsFixed(2)}"),
                            // 🆕 المحصّل من الآجل
                            Text(
                              "✅ إجمالي المحصّل من الآجل: ${(s['debt_collected'] ?? 0).toStringAsFixed(2)} ${Money.txt}",
                              style: TextStyle(
                                  color: Colors.teal[700],
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                                "💸 إجمالي المصروفات: ${s['expenses'].toStringAsFixed(2)}"),
                            Text(
                                "⏱️ إجمالي الساعات: ${s['total_hours'].toStringAsFixed(2)}"),
                            Text("🔢 عدد الشيفتات: ${s['count']}"),
                            Divider(height: 12, thickness: 0.5),
                            Text(
                              '🏆 المدفوع + المحصّل: ${((s['paid'] ?? 0) + (s['debt_collected'] ?? 0)).toStringAsFixed(2)} ${Money.txt}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.deepPurple[800],
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: "مسح بيانات الشيفت",
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AppDialog(
                                title: Text("تأكيد المسح"),
                                content:
                                    Text("هل تريد مسح كل بيانات هذا الشيفت؟"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text("إلغاء"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text("تأكيد"),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed ?? false) {
                              await DBHelper.clearShiftData(
                                s['id'] as int,
                                s['staff_name'] as String,
                                DateTime.parse(s['check_in']),
                                s['check_out'] != null
                                    ? DateTime.parse(s['check_out'])
                                    : null,
                              );
                              await _loadShifts();
                              AppToast.show("تم مسح بيانات الشيفت بالكامل");
                            }
                          },
                        ),
                      ),
                    );
                  }

                  // 🔧 مصلّح: كان فيه - - (طرح سالب) بيجمع المصروفات بدل ما يطرحها
                  final totalSalesWithCharge = (s['total_sales'] ?? 0) +
                      (s['charge_in'] ?? 0) -
                      (s['expenses'] ?? 0);
                  final paidPlusCollected =
                      (s['paid'] ?? 0) + (s['debt_collected'] ?? 0);
                  final paidPlusCollectedCash = (s['paid'] ?? 0) +
                      (s['debt_collected'] ?? 0) -
                      (s['expenses'] ?? 0);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.deepPurple.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.deepPurple),
                      title: Text('الموظف: ${s['staff_name']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '📅 التاريخ: ${formatArabicDate(DateTime.parse(s['shift_date']))}'),
                          Text(
                              '🕐 بدأ الشيفت: ${formatArabicDate(DateTime.parse(s['check_in']))}'),
                          if (s['check_out'] != null)
                            Text(
                                '🕓 انتهى: ${formatArabicDate(DateTime.parse(s['check_out']))}'),
                          Text(
                              '⏱️ عدد الساعات: ${s['total_hours']?.toStringAsFixed(2) ?? 0}'),
                          Text(
                              '💵 المدفوع: ${s['paid']?.toStringAsFixed(2) ?? 0} ${Money.txt}'),
                          Text(
                              '💳 الآجل: ${s['debt']?.toStringAsFixed(2) ?? 0} ${Money.txt}'),

                          // 🆕 سطر جديد يوضح المحصّل من الآجل خلال الشيفت ده
                          Text(
                            '✅ محصّل من الآجل: ${(s['debt_collected'] ?? 0).toStringAsFixed(2)} ${Money.txt}'
                            '${(s['debt_collected_count'] ?? 0) > 0 ? " (${s['debt_collected_count']} عملية)" : ""}',
                            style: TextStyle(
                                color: Colors.teal[700],
                                fontWeight: FontWeight.bold),
                          ),
                          if ((s['debt_collected_discount'] ?? 0) > 0)
                            Text(
                              '↳ خصم على التحصيل: ${(s['debt_collected_discount']).toStringAsFixed(2)} ${Money.txt}',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 12),
                            ),

                          Text(
                              '💸 المصروفات: ${s['expenses']?.toStringAsFixed(2) ?? 0} ${Money.txt}'),
                          Text(
                              '💰 إجمالي المبيعات: ${totalSalesWithCharge.toStringAsFixed(2)} ${Money.txt}'),
                          Divider(height: 12, thickness: 0.5),
                          Text(
                            '🏆 المدفوع + المحصّل: ${paidPlusCollected.toStringAsFixed(2)} ${Money.txt}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.deepPurple[800],
                            ),
                          ),
                          Divider(height: 12, thickness: 0.5),
                          Divider(height: 12, thickness: 0.5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'صافي الكاش',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '(المبيعات + المحصل - المصاريف)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${paidPlusCollectedCash.toStringAsFixed(2)} ${Money.txt}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: "مسح بيانات الشيفت",
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AppDialog(
                              title: Text("تأكيد المسح"),
                              content:
                                  Text("هل تريد مسح كل بيانات هذا الشيفت؟"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text("إلغاء"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("تأكيد"),
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
                            AppToast.show("تم مسح بيانات الشيفت بالكامل");
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:saytarly/core/services/app_settings.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/shifts_report_mobile_body.dart';
part 'desktop/shifts_report_windows_body.dart';

// 🆕 التصاميم المتاحة للتقرير
enum ReportDesign { classic, cards, minimal, full }

class ShiftsReportScreen extends StatefulWidget {
  @override
  State<ShiftsReportScreen> createState() => _ShiftsReportScreenState();
}

class _ShiftsReportScreenState extends State<ShiftsReportScreen> {
  List<Map<String, dynamic>> shifts = [];
  final bool isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final formatter = NumberFormat('#,##0.00');
// 🆕 Pagination
  static const int _pageSize = 7;
  List<Map<String, dynamic>> _rawShifts = [];
  Map<int, String> _consoleNameById = {};
  int _loadedCount = 0;
  bool _isLoadingMore = false;
  // 🆕 التصميم الحالي المختار — "full" هو اللي بياخد عرض الصفحة كله
  ReportDesign _design = ReportDesign.classic;

  // 🆕 true من أول ما الشاشة تفتح لحد ما أول تحميل يخلص، عشان مايظهرش
  // "لا توجد بيانات" لمدة ثانية أو اتنين وهو لسه بيحمّل فعليًا.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShifts();
    _loadDesign();
  }

  Future<void> _loadDesign() async {
    final saved = await AppSettings.getShiftsReportDesign();
    final match = ReportDesign.values.where((d) => d.name == saved);
    if (match.isNotEmpty && mounted) {
      setState(() => _design = match.first);
    }
  }

  Future<void> _changeDesign(ReportDesign value) async {
    setState(() => _design = value);
    await AppSettings.setShiftsReportDesign(value.name);
  }

  // ============================================================
  // ⬇️⬇️⬇️ كل اللي تحت من هنا (تحميل وحساب البيانات) متغيرش ولا حرف فيه
  // ============================================================
  // 🚀 دوال الجلب المجمّع — بديل الاستعلامات المتكررة لكل فاتورة لوحدها.
  // دي أكبر سبب في بطء تحميل الصفحة لما يبقى فيه شيفتات/فواتير كتير.
  // ============================================================

  /// بيجيب عناصر كل الفواتير المطلوبة مرة واحدة (متوازية) بدل ما يستنى
  /// كل فاتورة على حدة.
  Future<Map<int, List<Map<String, dynamic>>>> _fetchItemsForInvoices(
    List<int> invoiceIds,
  ) async {
    if (invoiceIds.isEmpty) return {};
    final results = await Future.wait(
      invoiceIds.map((id) => DBHelper.getItemsForInvoice(id)),
    );
    final map = <int, List<Map<String, dynamic>>>{};
    for (var i = 0; i < invoiceIds.length; i++) {
      map[invoiceIds[i]] = results[i];
    }
    return map;
  }

  /// بيجيب "قد إيه اتحصّل" لكل فاتورة آجلة، لكل الفواتير مرة واحدة
  /// باستعلامين بس (IN) بدل استعلامين لكل فاتورة آجلة.
  Future<Map<int, double>> _fetchDebtPaidTotalsForInvoices(
    List<int> invoiceIds,
  ) async {
    if (invoiceIds.isEmpty) return {};
    final db = await DBHelper.database;
    final placeholders = List.filled(invoiceIds.length, '?').join(',');

    final debtRows = await db.query(
      'debts',
      where: 'invoice_id IN ($placeholders)',
      whereArgs: invoiceIds,
    );
    if (debtRows.isEmpty) return {};

    final debtIdToInvoiceId = <int, int>{
      for (final d in debtRows) (d['id'] as int): (d['invoice_id'] as int),
    };
    final debtIds = debtIdToInvoiceId.keys.toList();
    final debtPlaceholders = List.filled(debtIds.length, '?').join(',');

    final paymentRows = await db.query(
      'debt_payments',
      where: 'debt_id IN ($debtPlaceholders)',
      whereArgs: debtIds,
    );

    final totalsByInvoice = <int, double>{};
    for (final p in paymentRows) {
      final debtId = p['debt_id'] as int;
      final invoiceId = debtIdToInvoiceId[debtId];
      if (invoiceId == null) continue;
      final amount = ((p['amount'] ?? 0) as num).toDouble();
      totalsByInvoice[invoiceId] = (totalsByInvoice[invoiceId] ?? 0) + amount;
    }
    return totalsByInvoice;
  }

  // ============================================================
  Future<void> _loadShifts({DateTime? date}) async {
    if (mounted) setState(() => _isLoading = true);

    final data = await DBHelper.getAllShifts(date: date);
    final db = await DBHelper.database;

    final consolesRows = await db.query('consoles');
    final consoleNameById = <int, String>{
      for (final c in consolesRows)
        (c['id'] as int): (c['name'] ?? 'جهاز'.tr()).toString(),
    };

    if (!mounted) return; // 🆕 يمنع الكراش لو الشاشة اتقفلت أثناء التحميل

    setState(() {
      _rawShifts = data;
      _consoleNameById = consoleNameById;
      shifts = [];
      _loadedCount = 0;
    });

    await _loadMoreShifts();
  }

  // 🆕 بيعالج أول دفعة (أو الدفعة اللي بعدها) بس، مش كل الشيفتات مرة واحدة
  Future<void> _loadMoreShifts() async {
    if (_isLoadingMore) return;
    if (_loadedCount >= _rawShifts.length) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoadingMore = true);

    final nextBatch = _rawShifts.skip(_loadedCount).take(_pageSize).toList();

    // 🚀 بنعالج شيفتات الدفعة دي بالتوازي مع بعض بدل ما نستناهم واحد واحد
    final processed = await Future.wait(
      nextBatch.map((s) => _enrichShift(s, _consoleNameById)),
    );

    if (!mounted) return; // 🆕 حماية تانية بعد الـ await

    setState(() {
      shifts.addAll(processed);
      _loadedCount += nextBatch.length;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  // 🆕 ده بالظبط جسم اللوب القديم اللي كان جوه _loadShifts،
  // اتحول لدالة مستقلة عشان تتنادى لكل شيفت لوحده وبالتوازي
  Future<Map<String, dynamic>> _enrichShift(
    Map<String, dynamic> s,
    Map<int, String> consoleNameById,
  ) async {
    final db = await DBHelper.database;
    final shift = Map<String, dynamic>.from(s);

    final rangeStart = shift['check_in'];
    final rangeEnd = shift['check_out'] ?? DateTime.now().toIso8601String();

    final invoices = await db.query(
      'invoices',
      where:
          'shift_id = ? OR ((shift_id IS NULL OR shift_id = 0) AND staff_name = ? AND start_time >= ? AND start_time <= ?)',
      whereArgs: [shift['id'], shift['staff_name'], rangeStart, rangeEnd],
    );

    final invoiceIds = invoices.map((e) => e['id'] as int).toList();

    final itemsByInvoice = await _fetchItemsForInvoices(invoiceIds);
    final debtPaidByInvoice = await _fetchDebtPaidTotalsForInvoices(invoiceIds);

    double paid = 0.0;
    double debt = 0.0;
    final List<Map<String, dynamic>> paidDetails = [];
    final List<Map<String, dynamic>> debtDetailsList = [];
    final List<Map<String, dynamic>> salesDetails = [];

    for (var inv in invoices) {
      final type = inv['payment_type'] as String?;
      final total = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;
      final customerName = (inv['customer_name'] ?? '').toString();
      final startTime = inv['start_time'];
      final invoiceId = inv['id'] as int;

      final invItems = itemsByInvoice[invoiceId] ?? const [];
      final itemsSummary = invItems.map((it) {
        final n = (it['drink_name'] ?? 'صنف'.tr()).toString();
        final q = it['qty'] ?? 1;
        return '$n×$q';
      }).join('، '.tr());

      String? deviceSummary;
      final consoleId = inv['console_id'];
      if (consoleId != null && (consoleId as int) != 0) {
        final consoleName = consoleNameById[consoleId] ?? 'جهاز'.tr();
        if (inv['is_fixed_price'] == 1) {
          final fixedPrice = ((inv['fixed_price'] ?? 0) as num).toDouble();
          deviceSummary =
              '🎮 {consoleName} (سعر ثابت {v2} {v3})'.tr({'consoleName': consoleName, 'v2': formatter.format(fixedPrice), 'v3': Money.txt});
        } else {
          final st = DateTime.tryParse(inv['start_time']?.toString() ?? '');
          final et = DateTime.tryParse(inv['end_time']?.toString() ?? '');
          if (st != null && et != null) {
            final pausedSeconds =
                (inv['total_paused_seconds'] as num?)?.toInt() ?? 0;
            final minutes =
                et.difference(st).inMinutes - (pausedSeconds / 60).round();
            final hours = minutes / 60.0;
            deviceSummary =
                '🎮 {consoleName} ({v2} ساعة)'.tr({'consoleName': consoleName, 'v2': hours.toStringAsFixed(2)});
          } else {
            deviceSummary = '🎮 $consoleName';
          }
        }
      }

      if (type == 'paid') {
        paid += total;
        paidDetails.add({
          'customer_name': customerName,
          'amount': total,
          'start_time': startTime,
          'items_summary': itemsSummary,
          'device_summary': deviceSummary,
        });
        salesDetails.add({
          'customer_name': customerName,
          'amount': total,
          'start_time': startTime,
          'note': 'مدفوعة',
          'items_summary': itemsSummary,
          'device_summary': deviceSummary,
        });
      } else if (type == 'debt' || type == 'علي الحساب') {
        final totalPaidPartial = debtPaidByInvoice[invoiceId] ?? 0.0;

        if (totalPaidPartial >= total) {
          paid += total;
          paidDetails.add({
            'customer_name': customerName,
            'amount': total,
            'start_time': startTime,
            'items_summary': itemsSummary,
            'device_summary': deviceSummary,
          });
          salesDetails.add({
            'customer_name': customerName,
            'amount': total,
            'start_time': startTime,
            'note': 'آجل مسدد بالكامل',
            'items_summary': itemsSummary,
            'device_summary': deviceSummary,
          });
        } else {
          paid += totalPaidPartial;
          final remaining = total - totalPaidPartial;
          debt += remaining;
          debtDetailsList.add({
            'customer_name': customerName,
            'amount': remaining,
            'start_time': startTime,
            'items_summary': itemsSummary,
            'device_summary': deviceSummary,
          });
          salesDetails.add({
            'customer_name': customerName,
            'amount': total,
            'start_time': startTime,
            'note': 'آجل',
            'items_summary': itemsSummary,
            'device_summary': deviceSummary,
          });
        }
      }
    }

    final currentShiftInvoiceIds = invoices.map((e) => e['id'] as int).toSet();
    final double invoiceOnlySales = paid + debt;

    final chargeLogs = await db.query(
      'machine_balance_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [rangeStart, rangeEnd],
    );

    double totalDeposits = 0.0;
    double totalWithdraws = 0.0;
    final List<Map<String, dynamic>> chargeInDetails = [];
    final List<Map<String, dynamic>> chargeOutDetails = [];

    for (var log in chargeLogs) {
      double amount = (log['amount'] as num).toDouble();
      if (log['type'] == 'deposit') {
        totalDeposits += amount;
        paid += amount;
        chargeInDetails.add({
          'customer_name': (log['note'] ?? 'شحن رصيد'.tr()).toString(),
          'amount': amount,
          'start_time': log['date'],
        });
      } else if (log['type'] == 'withdraw') {
        totalWithdraws += amount;
        debt += amount;
        chargeOutDetails.add({
          'customer_name': (log['note'] ?? 'سحب رصيد'.tr()).toString(),
          'amount': amount,
          'start_time': log['date'],
        });
      }
    }

    final debtPaymentsRowsRaw = await db.query(
      'debt_payments',
      where: 'paid_at >= ? AND paid_at <= ?',
      whereArgs: [rangeStart, rangeEnd],
      orderBy: 'paid_at ASC',
    );

    final debtPaymentsRows = debtPaymentsRowsRaw.where((p) {
      final invoiceId = p['invoice_id'];
      if (invoiceId == null) return true;
      return !currentShiftInvoiceIds.contains(invoiceId as int);
    }).toList();

    final debtCollected = debtPaymentsRows.fold<double>(
      0.0,
      (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
    );
    final debtCollectedDiscount = debtPaymentsRows.fold<double>(
      0.0,
      (sum, p) => sum + ((p['discount'] ?? 0) as num).toDouble(),
    );

    shift['paid'] = paid;
    shift['debt'] = debt;
    shift['total_sales'] = invoiceOnlySales;
    shift['charge_in'] = totalDeposits;
    shift['charge_out'] = totalWithdraws;
    shift['debt_collected'] = debtCollected;
    shift['debt_collected_discount'] = debtCollectedDiscount;
    shift['debt_collected_count'] = debtPaymentsRows.length;
    shift['debt_collected_details'] =
        debtPaymentsRows.map((p) => Map<String, dynamic>.from(p)).toList();
    shift['paid_details'] = paidDetails;
    shift['debt_details'] = debtDetailsList;
    shift['sales_details'] = salesDetails;
    shift['charge_in_details'] = chargeInDetails;
    shift['charge_out_details'] = chargeOutDetails;

    final invoiceItems = await db.rawQuery('''
      SELECT ii.total, d.temperature 
      FROM invoice_items ii
      LEFT JOIN drinks d ON d.id = ii.drink_id
      WHERE ii.invoice_id IN (
        SELECT id FROM invoices
        WHERE shift_id = ? OR ((shift_id IS NULL OR shift_id = 0) AND staff_name = ? AND start_time >= ? AND start_time <= ?)
      )
    ''', [shift['id'], shift['staff_name'], rangeStart, rangeEnd]);

    double cigaretteTotal = 0.0;
    for (var item in invoiceItems) {
      if (item['temperature'] == 'cigarette') {
        cigaretteTotal += (item['total'] as num).toDouble();
      }
    }
    shift['cigarettes'] = cigaretteTotal;

    final expenses = await DBHelper.getExpensesByShift(shift['id'] as int);
    final totalExpenses = expenses.fold<double>(
        0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));
    shift['expenses'] = totalExpenses;
    shift['expenses_details'] =
        expenses.map((e) => Map<String, dynamic>.from(e)).toList();

    final vodafoneCashTotal =
        await DBHelper.getVodafoneCashTotal(shift['id'] as int);
    final vodafoneCashNotes =
        await DBHelper.getVodafoneCashNotes(shift['id'] as int);
    shift['vodafone_cash_total'] = vodafoneCashTotal;
    shift['vodafone_cash_notes'] =
        vodafoneCashNotes.map((e) => Map<String, dynamic>.from(e)).toList();

    return shift;
  }

  String formatArabicDate(DateTime date) {
     final days = [
      "الاثنين",
      'الثلاثاء'.tr(),
      'الأربعاء'.tr(),
      'الخميس'.tr(),
      'الجمعة'.tr(),
      'السبت'.tr(),
      'الأحد'.tr()
    ];
     final months = [
      "يناير",
      'فبراير'.tr(),
      'مارس'.tr(),
      'أبريل'.tr(),
      'مايو'.tr(),
      'يونيو'.tr(),
      'يوليو'.tr(),
      'أغسطس'.tr(),
      'سبتمبر'.tr(),
      'أكتوبر'.tr(),
      'نوفمبر'.tr(),
      'ديسمبر'.tr()
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'م'.tr() : "ص";
    final minute = date.minute.toString().padLeft(2, '0');

    return '{dayName}، {v2} {monthName} {v4} - {hour}:{minute} {ampm}'.tr({'dayName': dayName, 'v2': date.day, 'monthName': monthName, 'v4': date.year, 'hour': hour, 'minute': minute, 'ampm': ampm});
  }

  void _showDebtCollectedDetails(List<Map<String, dynamic>> details) {
    if (details.isEmpty) {
      AppToast.show('مفيش تفاصيل تحصيل في الفترة دي'.tr());
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'تفاصيل تحصيل الآجل ({v1} عملية)'.tr({'v1': details.length}),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: details.length,
                    itemBuilder: (_, i) {
                      final p = details[i];
                      final amount = ((p['amount'] ?? 0) as num).toDouble();
                      final discount = ((p['discount'] ?? 0) as num).toDouble();
                      final customerName =
                          (p['customer_name'] ?? 'غير معروف'.tr()).toString();
                      final paidAt =
                          DateTime.tryParse(p['paid_at']?.toString() ?? '');
                      final formattedDate = paidAt != null
                          ? formatArabicDate(paidAt)
                          : 'غير محدد';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.check_circle,
                              color: Colors.teal),
                          title: Text(
                            customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(formattedDate),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${formatter.format(amount)} ${Money.txt}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              if (discount > 0)
                                Text(
                                  'خصم {v1}'.tr({'v1': formatter.format(discount)}),
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailsSheet({
    required String title,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) nameOf,
    required String Function(Map<String, dynamic>) subtitleOf,
    required double Function(Map<String, dynamic>) amountOf,
    Color color = Colors.deepPurple,
    IconData icon = Icons.receipt_long,
  }) {
    if (items.isEmpty) {
      AppToast.show('مفيش تفاصيل في الفترة دي'.tr());
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '$title (${items.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(
                            nameOf(item),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(subtitleOf(item)),
                          trailing: Text(
                            '${formatter.format(amountOf(item))} ${Money.txt}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateSafe(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    return parsed != null ? formatArabicDate(parsed) : 'غير محدد';
  }

  String _orderSubtitle(Map<String, dynamic> m, {String? notePrefix}) {
    final parts = <String>[_formatDateSafe(m['start_time'])];
    if (notePrefix != null && notePrefix.isNotEmpty) {
      parts[0] = '$notePrefix - ${parts[0]}';
    }
    final device = (m['device_summary'] as String?);
    if (device != null && device.isNotEmpty) parts.add(device);
    final items = (m['items_summary'] as String?);
    if (items != null && items.isNotEmpty) parts.add('🥤 $items');
    return parts.join('\n');
  }

  void _generateDailySummary() {
    if (shifts.isEmpty) return;

    Map<String, Map<String, dynamic>> grouped = {};

    for (var s in shifts) {
      final name = s['staff_name'];

      if (!grouped.containsKey(name)) {
        grouped[name] = {
          'staff_name': name,
          'paid': 0.0,
          'debt': 0.0,
          'expenses': 0.0,
          'charge_out': 0.0,
          'charge_in': 0.0,
          'total_hours': 0.0,
          'cigarettes': 0.0,
          'debt_collected': 0.0,
          'debt_collected_details': <Map<String, dynamic>>[],
          'total_sales': 0.0,
          'paid_details': <Map<String, dynamic>>[],
          'debt_details': <Map<String, dynamic>>[],
          'sales_details': <Map<String, dynamic>>[],
          'charge_in_details': <Map<String, dynamic>>[],
          'charge_out_details': <Map<String, dynamic>>[],
          'expenses_details': <Map<String, dynamic>>[],
          'vodafone_cash_total': 0.0,
          'vodafone_cash_notes': <Map<String, dynamic>>[],
          'count': 0,
        };
      }

      grouped[name]!['paid'] += (s['paid'] ?? 0);
      grouped[name]!['debt'] += (s['debt'] ?? 0);
      grouped[name]!['expenses'] += (s['expenses'] ?? 0);
      grouped[name]!['charge_out'] += (s['charge_out'] ?? 0);
      grouped[name]!['charge_in'] += (s['charge_in'] ?? 0);
      grouped[name]!['total_hours'] += (s['total_hours'] ?? 0);
      grouped[name]!['cigarettes'] += (s['cigarettes'] ?? 0);
      grouped[name]!['debt_collected'] += (s['debt_collected'] ?? 0);
      grouped[name]!['total_sales'] += (s['total_sales'] ?? 0);
      grouped[name]!['vodafone_cash_total'] += (s['vodafone_cash_total'] ?? 0);
      (grouped[name]!['vodafone_cash_notes'] as List<Map<String, dynamic>>)
          .addAll((s['vodafone_cash_notes'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              []);
      (grouped[name]!['debt_collected_details'] as List<Map<String, dynamic>>)
          .addAll((s['debt_collected_details'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              []);
      (grouped[name]!['paid_details'] as List<Map<String, dynamic>>).addAll(
          (s['paid_details'] as List?)?.cast<Map<String, dynamic>>() ?? []);
      (grouped[name]!['debt_details'] as List<Map<String, dynamic>>).addAll(
          (s['debt_details'] as List?)?.cast<Map<String, dynamic>>() ?? []);
      (grouped[name]!['sales_details'] as List<Map<String, dynamic>>).addAll(
          (s['sales_details'] as List?)?.cast<Map<String, dynamic>>() ?? []);
      (grouped[name]!['charge_in_details'] as List<Map<String, dynamic>>)
          .addAll(
              (s['charge_in_details'] as List?)?.cast<Map<String, dynamic>>() ??
                  []);
      (grouped[name]!['charge_out_details'] as List<Map<String, dynamic>>)
          .addAll((s['charge_out_details'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              []);
      (grouped[name]!['expenses_details'] as List<Map<String, dynamic>>).addAll(
          (s['expenses_details'] as List?)?.cast<Map<String, dynamic>>() ?? []);
      grouped[name]!['count'] += 1;
    }

    setState(() {
      shifts = grouped.values.toList();
    });
  }

  DateTime? _selectedDate;
  // ============================================================
  // ⬆️⬆️⬆️ لحد هنا كل حاجة زي ما هي بالظبط، من غير أي تعديل
  // ============================================================

  // ============================================================
  // 🆕 أدوات التصميم — نفس البيانات بترسمها كل مرة بشكل مختلف
  // ============================================================
  String _designLabel(ReportDesign d) {
    switch (d) {
      case ReportDesign.classic:
        return 'كلاسيكي'.tr();
      case ReportDesign.cards:
        return 'كروت'.tr();
      case ReportDesign.minimal:
        return 'بسيط'.tr();
      case ReportDesign.full:
        return 'لوحة كاملة'.tr();
    }
  }

  IconData _designIcon(ReportDesign d) {
    switch (d) {
      case ReportDesign.classic:
        return Icons.view_agenda_outlined;
      case ReportDesign.cards:
        return Icons.dashboard_customize_outlined;
      case ReportDesign.minimal:
        return Icons.view_list_outlined;
      case ReportDesign.full:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);
}
