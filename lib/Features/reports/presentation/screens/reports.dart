import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:intl/intl.dart';

import 'package:saytarly/Features/reports/presentation/screens/IncomeStatsScreen.dart';
import 'package:saytarly/core/services/app_settings.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/reports_mobile_body.dart';
part 'desktop/reports_windows_body.dart';

class ReportsScreen extends StatefulWidget {
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> expenses = [];
  Map<int, List<Map<String, dynamic>>> invoiceItems = {};
  double totalIncome = 0;
  final formatter = NumberFormat('#,##0.00');
  double shishaSales = 0.0;
  double productSales = 0.0;
  double drinkSales = 0.0;
  double deviceIncome = 0.0;
  double debtTotal = 0.0;
  double totalCigarettes = 0.0;
  double cashDrawerBalance = 0.0;

  // 🆕 كنترولر عشان نقدر نعمل Scroll للآخر برمجيًا
  final ScrollController _scrollController = ScrollController();

  // 🆕 حالة إظهار/إخفاء الأرقام المالية
  bool _numbersVisible = false;
  bool _cigarettesEnabled = false;
  bool _shishaEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCashDrawerBalance();
    _loadFeatureFlags(); // 🆕
  }

  Future<void> _loadFeatureFlags() async {
    final cig = await AppSettings.getCigarettesEnabled();
    final shisha = await AppSettings.getShishaEnabled();
    if (!mounted) return;
    setState(() {
      _cigarettesEnabled = cig;
      _shishaEnabled = shisha;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCashDrawerBalance({DateTime? date}) async {
    final balance = await DBHelper.getCashDrawerBalance(date: date);
    setState(() {
      cashDrawerBalance = balance;
    });
  }

  Future<double> calculateTotalCigarettes(
    List<Map<String, dynamic>> invoices,
  ) async {
    double totalCigarettes = 0.0;

    for (final inv in invoices) {
      if (inv['payment_type'] == 'ملغي') continue;

      final cigCost = (inv['cigarettes_cost']?.toDouble() ?? 0.0);
      if (cigCost <= 0) continue;

      totalCigarettes += cigCost;
    }

    return totalCigarettes;
  }

  // ============================================================
  // 🚀 هيلبر بيجيب صفوف من جدول معين فلترة بعمود IN(...)، وبيقسمهم
  // على دفعات (chunks) عشان SQLite بيرفض أي IN فيه آلاف القيم مرة
  // واحدة. ده اللي بيحل مشكلة إن الصفحة كانت بتجيب الجدول *كامله*
  // (كل الفواتير من أول ما التطبيق اشتغل) حتى لو انت بس بتفتح فلتر
  // يوم واحد.
  // ============================================================
  Future<List<Map<String, dynamic>>> _queryInChunks(
    dynamic db,
    String table,
    String column,
    List<int> ids, {
    int chunkSize = 400,
  }) async {
    if (ids.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize > ids.length) ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.query(
        table,
        where: '$column IN ($placeholders)',
        whereArgs: chunk,
      );
      results.addAll(rows);
    }
    return results;
  }

  double totalTopupsPaid = 0.0;
  Future<void> _load({DateTime? date}) async {
    final db = await DBHelper.database;

    double cigs = 0.0;
    double shisha = 0.0;
    double products = 0.0;
    double drinksOnly = 0.0;
    double deviceIncomeLocal = 0.0;
    double totalPaid = 0.0;
    double topupsTotal = 0.0;

    List<Map<String, dynamic>> inv;
    List<Map<String, dynamic>> exp;

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      inv = await db.query(
        'invoices',
        where: 'start_time >= ? AND start_time < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );

      exp = await db.query(
        'expenses',
        where: 'date >= ? AND date < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );
    } else {
      inv = await DBHelper.getAllInvoices();
      exp = await DBHelper.getAllExpenses();
    }
    // 🆕 خريطة نوع كل صنف (hot/cold/cigarette/shisha/...) من جدول drinks
    // — invoice_items مفيهوش عمود temperature، فلازم نجيبه من هنا
    final allDrinksRows = await db.query(
      'drinks',
      columns: ['id', 'temperature'],
    );
    final drinkTempById = <int, String>{
      for (final d in allDrinksRows)
        if (d['id'] != null)
          (d['id'] as int): (d['temperature'] ?? '').toString().toLowerCase(),
    };
    final productKeywords = [
      'منتج',
      'product',
      'آندومي'.tr(),
      'اندومي'.tr(),
      'شيبسي'.tr(),
      'مولتو'.tr(),
      'شوكلاته'.tr(),
      'تاو'.tr(),
    ];

    // 🚀 قبل كده كانت الثلاث استعلامات دي بتجيب الجدول *كامله* من غير
    // فلتر خالص (كل الديون/الدفعات/عناصر الفواتير من أول يوم في
    // التطبيق) حتى لو انت بس فاتح فلتر "يوم واحد". يعني لو الداتا
    // كبرت، الصفحة تفضل بطيئة حتى وانت بتشوف يوم واحد بس.
    // دلوقتي بيتفلتروا على نفس الفواتير (inv) اللي هتتعرض فعليًا.
    final invoiceIds = inv.map((e) => e['id'] as int).toList();

    final allDebts = await _queryInChunks(
      db,
      'debts',
      'invoice_id',
      invoiceIds,
    );
    final debtByInvoiceId = <int, Map<String, dynamic>>{
      for (final d in allDebts)
        if (d['invoice_id'] != null) (d['invoice_id'] as int): d,
    };

    final debtIds = allDebts.map((d) => d['id'] as int).toList();
    final allPayments = await _queryInChunks(
      db,
      'debt_payments',
      'debt_id',
      debtIds,
    );
    final paymentsByDebtId = <int, List<Map<String, dynamic>>>{};
    for (final p in allPayments) {
      final debtId = p['debt_id'] as int?;
      if (debtId == null) continue;
      paymentsByDebtId.putIfAbsent(debtId, () => []).add(p);
    }

    final allInvoiceItems = await _queryInChunks(
      db,
      'invoice_items',
      'invoice_id',
      invoiceIds,
    );
    final itemsByInvoiceId = <int, List<Map<String, dynamic>>>{};
    for (final item in allInvoiceItems) {
      final invId = item['invoice_id'] as int?;
      if (invId == null) continue;
      itemsByInvoiceId.putIfAbsent(invId, () => []).add(item);
    }

    // معالجة كل فاتورة من الداتا المحمّلة مسبقًا (من غير أي query جديد)
    final mutableInvoices = <Map<String, dynamic>>[];
    for (var i in inv) {
      final invId = i['id'] as int;
      final mutableInv = Map<String, dynamic>.from(i);

      if (i['payment_type'] != 'ملغي') {
        final totalCost = ((i['total_cost'] ?? 0) as num).toDouble();
        final discount = ((i['discount'] ?? 0) as num).toDouble();
        final drinksCost = ((i['drinks_cost'] ?? 0) as num).toDouble();
        final deviceCost = ((i['device_cost'] ?? 0) as num).toDouble();
        final cigCost = ((i['cigarettes_cost'] ?? 0) as num).toDouble(); // 🆕
        final shishaCost = ((i['shisha_cost'] ?? 0) as num).toDouble(); // 🆕
        final productsCost = ((i['products_cost'] ?? 0) as num).toDouble(); // 🆕

        // حساب إجمالي الفاتورة الصحيح الشامل لكل البنود مطروحاً منه الخصم
        final sumOfAllItems = drinksCost + deviceCost + cigCost + shishaCost + productsCost - discount;
        final invoiceTotal = totalCost > 0
            ? totalCost
            : (sumOfAllItems < 0 ? 0.0 : sumOfAllItems);

        double paidAmount = 0.0;
        if (i['payment_type'] == 'paid') {
          paidAmount = invoiceTotal;
        } else {
          final debt = debtByInvoiceId[invId];
          if (debt != null) {
            final debtId = debt['id'] as int;
            final payments = paymentsByDebtId[debtId] ?? [];
            paidAmount = payments.fold<double>(
              0.0,
              (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
            );
          }
          paidAmount += ((i['paid_partial'] ?? 0) as num).toDouble();
        }

        totalPaid += paidAmount;
        deviceIncomeLocal += deviceCost;

        // 🆕 خد الأرقام من أعمدة الفاتورة مباشرة، مش من إعادة تجميع الأصناف
        cigs += cigCost;
        shisha += shishaCost;
        products += productsCost;
        drinksOnly += drinksCost;

        mutableInv['_paidAmount'] = paidAmount;
        mutableInv['_invoiceTotal'] = invoiceTotal;
        mutableInv['_remaining'] = (invoiceTotal - paidAmount) < 0
            ? 0.0
            : (invoiceTotal - paidAmount);

        final paidRatio = invoiceTotal > 0
            ? (paidAmount / invoiceTotal).clamp(0.0, 1.0)
            : 0.0;
        final items = itemsByInvoiceId[invId] ?? [];
        mutableInv['_items'] = items;

        // 🆕 الحلقة بقت بس لاكتشاف "شحن رصيد" — مش بتجمع cigs/shisha/products/drinks تاني
        for (var item in items) {
          final name = (item['drink_name'] ?? '').toString().toLowerCase();
          if (name.contains('شحن رصيد')) {
            double totalItem = ((item['total'] ?? 0) as num).toDouble();
            if (totalItem == 0) totalItem = totalCost;
            topupsTotal += totalItem * paidRatio;
          }
        }
      }

      mutableInvoices.add(mutableInv);
    }

    // باقي حساب remainingDebts زي ما هو، بس استخدم allDebts و paymentsByDebtId
    // بدل ما تعمل query لكل دين على حدة:
    double remainingDebts = 0.0;
    for (var row in allDebts) {
      final debtId = row['id'] as int;
      final totalAmount = ((row['total_amount'] ?? 0) as num).toDouble();
      final payments = paymentsByDebtId[debtId] ?? [];
      final paidForThisDebt = payments.fold<double>(
        0.0,
        (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
      );
      final remaining = totalAmount - paidForThisDebt;
      remainingDebts += remaining < 0 ? 0 : remaining;
    }

    final balance = await DBHelper.getCashDrawerBalance(date: date);

    // 🆕 نرتب الفواتير من الأحدث للأقدم (آخر فاتورة تظهر أول واحدة)
    mutableInvoices.sort((a, b) {
      final idA = a['id'] as int? ?? 0;
      final idB = b['id'] as int? ?? 0;
      return idB.compareTo(idA); // تنازلي
    });

    setState(() {
      invoices = mutableInvoices;
      expenses = exp;
      totalIncome = balance;
      cigarettesSales = cigs;
      shishaSales = shisha;
      productSales = products;
      drinkSales = drinksOnly;
      totalTopupsPaid = topupsTotal;
      deviceIncome = deviceIncomeLocal;
      debtTotal = remainingDebts;
    });

    totalCigarettes = await calculateTotalCigarettes(invoices);
    setState(() {});
  }

  Future<void> _deleteAllInvoices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: Text('تأكيد حذف الكل'.tr()),
        content: Text('هل أنت متأكد من مسح جميع الفواتير؟'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف'.tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.deleteAllInvoices();
      _load();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _load(date: picked);
    }
  }

  void _showAllInvoices() {
    setState(() => _selectedDate = null);
    _load();
  }

  void _openIncomeStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IncomeStatsScreen()),
    );
  }

  // ============================================================
  // 🆕 المصروفات
  // 🚀 كانت جزء من نفس الـ ListView.builder الطويل بتاع الفواتير،
  // وزرار "انزل لآخر الصفحة" كان بيحاول يوصلها بالقفز/الأنيميشن —
  // وده اللي كان بيسبب الهنج (فلاتر لازم يبني مئات عناصر الفواتير
  // عشان يعرف مكان آخر عنصر بالظبط). الحل الأسلم: المصروفات بقت
  // منفصلة تمامًا عن قائمة الفواتير، وبتتفتح في صفحة سفلية (Bottom
  // Sheet) خفيفة عند الضغط على الزرار — مفيش أي علاقة بسكرول
  // القائمة الطويلة خالص، فمستحيل تسبب نفس المشكلة.
  // ============================================================
  void _showExpensesSheet() {
    final total = expenses.fold<double>(
      0.0,
      (p, e) => p + ((e['amount'] ?? 0) as num).toDouble(),
    );

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
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'المصروفات ({v1}) — الإجمالي: {v2}'.tr({'v1': expenses.length, 'v2': _mask(formatter.format(total))}),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(),
                Expanded(
                  child: expenses.isEmpty
                      ?  Center(child: Text('لا توجد مصروفات'.tr()))
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: expenses.length,
                          itemBuilder: (_, i) {
                            final e = expenses[i];
                            final date = DateTime.parse(e['date']);
                            return ListTile(
                              title: Text(e['description']),
                              subtitle: Text(
                                'تمت الإضافة بواسطة: {v1} - التاريخ: {v2}'.tr({'v1': e['added_by'], 'v2': DateFormat('yyyy-MM-dd HH:mm').format(date)}),
                              ),
                              trailing: Text(
                                _mask('{v1} ج'.tr({'v1': e['amount'].toStringAsFixed(2)})),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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

  // ============================================================
  // 🆕 إظهار/إخفاء الأرقام المالية بباسورد الأدمن
  // ============================================================

  // تقفيل الأرقام مش محتاج باسورد (زي أي toggle عادي)، لكن فتحها
  // لازم يتطلب باسورد الأدمن.
  Future<void> _toggleNumbersVisibility() async {
    if (_numbersVisible) {
      setState(() => _numbersVisible = false);
      return;
    }

    final password = await _askAdminPassword();
    if (password == null) return; // المستخدم لغى

    final isValid = await _verifyAdminPassword(password);
    if (isValid) {
      setState(() => _numbersVisible = true);
    } else if (mounted) {
      AppToast.show('كلمة المرور غير صحيحة'.tr());
    }
  }

  Future<String?> _askAdminPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title:  Text('كلمة مرور الأدمن'.tr()),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration:  InputDecoration(labelText: 'كلمة المرور'.tr()),
          onSubmitted: (val) => Navigator.pop(dialogContext, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child:  Text('تأكيد'.tr()),
          ),
        ],
      ),
    );
  }

  // 🆕 بيتحقق من الباسورد فعليًا من جدول users بتاع التطبيق (role = admin أو superadmin)
  // — نفس الجدول اللي بيستخدمه تسجيل الدخول العادي، فمفيش باسورد منفصل.
  Future<bool> _verifyAdminPassword(String password) async {
    final db = await DBHelper.database;
    final res = await db.query(
      'users',
      where: 'role IN (?, ?) AND password = ?',
      whereArgs: ['admin', 'superadmin', password],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  // 🆕 هيلبر بيرجع الرقم الحقيقي أو نقط إخفاء حسب حالة الإظهار
  String _mask(String realValue) {
    return _numbersVisible ? realValue : '••••••';
  }

  double deviceIncomeLocal = 0.0;
  double debtTotalLocal = 0.0;

  double cigarettesSales = 0.0;
  DateTime? _selectedDate;

  // ============================================================
  // 📱 نقطة الفصل بين تصميم الموبايل والديسكتوب. تقدر تغيّر الرقم
  // ده لو عايز نقطة الفصل تبقى في عرض تاني.
  // ============================================================
  static const double _mobileBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  _SummaryCardData(this.title, this.value, this.color, this.icon);
}
