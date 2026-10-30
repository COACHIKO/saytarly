import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/widgets/BACKGROUND.dart';
import 'package:saytarly/Features/auth/presentation/screens/logout_helper.dart';
import 'package:saytarly/Features/auth/presentation/screens/login.dart';
import 'package:saytarly/Features/staff/logic/cubit/sub_staff_update_cubit.dart';
import 'package:saytarly/core/services/backup_helper.dart';
import 'package:saytarly/Features/cards/presentation/widgets/card_queue_icon_button.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/Features/cashier/presentation/screens/DrinksScreen.dart';
import 'package:saytarly/Features/playstation/presentation/screens/PS_Screen.dart';
import 'package:saytarly/Features/debts/presentation/print/invoice_debet_print.dart';
import 'package:saytarly/Features/cashier/presentation/screens/add_drinks.dart';
import 'package:saytarly/Features/staff/presentation/screens/ShiftDetailsPage.dart';
import 'package:saytarly/Features/expenses/presentation/screens/cashier_expenses.dart';
import 'package:saytarly/Features/cashier/presentation/print/drinks_invoice_print.dart';
import 'package:saytarly/Features/staff/presentation/screens/SubStaffPage.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw; // لـ pw
import 'package:printing/printing.dart'; // للطباعة
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/staff_dashboard_mobile_body.dart';
part 'desktop/staff_dashboard_windows_body.dart';

class StaffDashboard extends StatefulWidget {
  final String staffName; // اسم الكاشير الحالي
  final int staffId;
  final int shiftId; // ✅ أضف ده
  final int supervisorShiftId;
  const StaffDashboard({
    super.key,
    required this.staffName,
    required this.shiftId,
    required this.staffId,
    required this.supervisorShiftId,
  });
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  List<ConsoleModel> consoles = [];
  List<Map<String, dynamic>> activeInvoices = [];

  /// اسم المحل — بيظهر في السايد بار في واجهة الويندوز.
  String _placeName = BusinessProfile.fallbackName;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPlaceName();
  }

  Future<void> _loadPlaceName() async {
    final name = await BusinessProfile.getPlaceName();
    if (!mounted) return;
    setState(() => _placeName = name);
  }

  double vodafoneCashTotal = 0.0;
  List<Map<String, dynamic>> vodafoneCashNotes = [];
  Future<void> _load() async {
    final cs = await DBHelper.getAllConsoles();
    final inv = await DBHelper.getActiveInvoices();
    setState(() {
      consoles = cs.map((r) => ConsoleModel.fromMap(r)).toList();
      activeInvoices = inv;
    });
  }

  Future<void> _startSession(ConsoleModel c) async {
    final now = DateTime.now().toIso8601String();
    await DBHelper.createInvoice(
      c.id!,
      now,
      staffName: widget.staffName,
      shiftId: widget.shiftId,
    );
    await _load();
  }

  Future<void> _endSession(Map<String, dynamic> invoice, ConsoleModel c) async {
    final end = DateTime.now();
    final start = DateTime.parse(invoice['start_time']);
    final duration = end.difference(start).inSeconds / 3600.0; // ساعات
    final deviceCost = duration * c.pricePerHour;
    final drinksCost = await DBHelper.getDrinksCostForInvoice(
      invoice['id'] as int,
    );
    final total = deviceCost + drinksCost;

    await DBHelper.endInvoice(
      invoice['id'] as int,
      end.toIso8601String(),
      deviceCost,
      drinksCost,
      shiftId: widget.shiftId,
      addToCashDrawer: true,
      paymentType: 'paid',
    );

    await _load();

    showDialog(
      context: context,
      builder:
          (_) => AppDialog(
            title: Text('الفاتورة النهائية'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الكونسول: {v1}'.tr({'v1': c.name})),
                Text(
                  'المدة: {v1} ساعة'.tr({'v1': duration.toStringAsFixed(2)}),
                ),
                Text(
                  'تكلفة الكونسول: {v1}'.tr({
                    'v1': deviceCost.toStringAsFixed(2),
                  }),
                ),
                Text(
                  'المشروبات: {v1}'.tr({'v1': drinksCost.toStringAsFixed(2)}),
                ),
                Divider(),
                Text(
                  'الإجمالي: {v1}'.tr({'v1': total.toStringAsFixed(2)}),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('تم'.tr()),
              ),
            ],
          ),
    );
  }

  Map<int, Map<String, dynamic>> _activeMap() {
    final m = <int, Map<String, dynamic>>{};
    for (final inv in activeInvoices) {
      m[inv['console_id'] as int] = inv;
    }
    return m;
  }

  void _showSubStaffSelector() async {
    final subStaffList = await DBHelper.getSubStaff(widget.staffId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            List<Map<String, dynamic>> editableSubStaff =
                List<Map<String, dynamic>>.from(subStaffList);

            // ⏱️ Timer لتحديث الوقت كل ثانية
            Timer? timer;
            timer = Timer.periodic(Duration(seconds: 1), (_) {
              setStateSheet(() {});
            });

            return WillPopScope(
              onWillPop: () async {
                timer?.cancel(); // إيقاف الـ Timer عند إغلاق الشيت
                return true;
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الموظفين الفرعيين'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: editableSubStaff.length,
                        itemBuilder: (context, i) {
                          final staff = editableSubStaff[i];
                          final staffName =
                              staff['username'] ?? 'غير معروف'.tr();
                          final staffId = staff['id'] as int;
                          final shiftStartStr = staff['shift_start'];
                          final shiftEndStr = staff['shift_end'];
                          final salaryPerHour =
                              (staff['salary_per_hour'] ?? 0.0) as double;

                          // احسب حالة الشيفت في كل مرة
                          bool isWorking =
                              shiftStartStr != null && shiftEndStr == null;
                          double workedHours = 0.0;
                          double earned = 0.0;

                          if (shiftStartStr != null) {
                            final start = DateTime.parse(shiftStartStr);
                            final end =
                                shiftEndStr != null
                                    ? DateTime.parse(shiftEndStr)
                                    : DateTime.now();
                            workedHours =
                                end.difference(start).inSeconds / 3600;
                            earned = workedHours * salaryPerHour;
                          }

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(staffName),
                              subtitle:
                                  shiftStartStr != null
                                      ? Text(
                                        'المدة: {v1} ساعة\nالأجر: {v2} {v3}'
                                            .tr({
                                              'v1': workedHours.toStringAsFixed(
                                                2,
                                              ),
                                              'v2': earned.toStringAsFixed(2),
                                              'v3': Money.txt,
                                            }),
                                      )
                                      : null,
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  if (!isWorking) {
                                    // بدء الشيفت
                                    await DBHelper.startShiftForSubStaff(
                                      staffId: staffId,
                                      supervisorShiftId: widget.shiftId,
                                      startTime:
                                          DateTime.now().toIso8601String(),
                                    );
                                  } else {
                                    // إنهاء الشيفت
                                    await DBHelper.endShiftForSubStaff(
                                      staffId: staffId,
                                      endTime: DateTime.now().toIso8601String(),
                                    );
                                  }

                                  // تحديث البيانات بعد أي تغيير
                                  final updatedList =
                                      await DBHelper.getSubStaff(
                                        widget.staffId,
                                      );
                                  setStateSheet(() {
                                    editableSubStaff =
                                        List<Map<String, dynamic>>.from(
                                          updatedList,
                                        );
                                  });
                                },
                                child: Text(
                                  isWorking ? 'إنهاء'.tr() : 'بدء'.tr(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isWorking ? Colors.red : Colors.green,
                                ),
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
      },
    );
  }

  // 🔹 دالة لقفل الشيفت
  void _confirmCloseShift() async {
    // أولاً: جلب بيانات الموظفين الفرعيين الحاليين
    final subStaffList = await DBHelper.getSubStaff(widget.staffId);

    // حساب الأجر لكل موظف
    List<Map<String, dynamic>> staffEarnings =
        subStaffList.map((staff) {
          final shiftStartStr = staff['shift_start'];
          final shiftEndStr = staff['shift_end'];
          final salaryPerHour = (staff['salary_per_hour'] ?? 0.0) as double;
          final advance = (staff['advance'] ?? 0.0) as double; // سلفة الموظف
          double workedHours = 0.0;
          double earned = 0.0;
          double netEarned = 0.0;

          if (shiftStartStr != null) {
            final start = DateTime.parse(shiftStartStr);
            final end =
                shiftEndStr != null
                    ? DateTime.parse(shiftEndStr)
                    : DateTime.now();
            workedHours = end.difference(start).inSeconds / 3600;
            earned = workedHours * salaryPerHour;
            netEarned = (earned - advance).clamp(0, earned);
          }

          return {
            'id': staff['id'],
            'name': staff['username'] ?? 'غير معروف'.tr(),
            'workedHours': workedHours,
            'earned': earned,
            'advance': advance,
            'netEarned': netEarned,
          };
        }).toList();
    /* ج, سلفة: ${s['advance'].toStringAsFixed(2)}*/
    final shiftInvoices = await DBHelper.getInvoicesByShift(widget.shiftId);
    final productsSold = await DBHelper.getShiftProductsSummary(widget.shiftId);
    final shiftExpenses = await DBHelper.getExpensesByShift(widget.shiftId);
    final totalExpenses = shiftExpenses.fold<double>(
      0.0,
      (sum, e) => sum + ((e['amount'] ?? 0) as num).toDouble(),
    );
    final totalDevices = shiftInvoices.fold<double>(
      0.0,
      (s, i) =>
          i['payment_type'] == 'ملغي'
              ? s
              : s + ((i['device_cost'] ?? 0) as num).toDouble(),
    );
    final totalDrinks = shiftInvoices.fold<double>(
      0.0,
      (s, i) =>
          i['payment_type'] == 'ملغي'
              ? s
              : s + ((i['drinks_cost'] ?? 0) as num).toDouble(),
    );
    final totalProducts = shiftInvoices.fold<double>(
      0.0,
      (s, i) =>
          i['payment_type'] == 'ملغي'
              ? s
              : s + ((i['products_cost'] ?? 0) as num).toDouble(),
    );
    final totalCigarettes = shiftInvoices.fold<double>(
      0.0,
      (s, i) =>
          i['payment_type'] == 'ملغي'
              ? s
              : s + ((i['cigarettes_cost'] ?? 0) as num).toDouble(),
    );
    final totalShisha = shiftInvoices.fold<double>(
      0.0,
      (s, i) =>
          i['payment_type'] == 'ملغي'
              ? s
              : s + ((i['shisha_cost'] ?? 0) as num).toDouble(),
    );
    final totalItemsSoldQty = productsSold.fold<int>(
      0,
      (s, p) => s + ((p['total_qty'] ?? 0) as num).toInt(),
    );
    final totalSalesBeforeDiscount =
        totalDevices +
        totalDrinks +
        totalProducts +
        totalCigarettes +
        totalShisha;

    // بناء نص لعرضه في الـ AlertDialog
    final earningsText =
        staffEarnings.isEmpty
            ? 'لا يوجد موظفين فرعيين مسجلين'.tr()
            : staffEarnings
                .map(
                  (s) => '• {v1}: أجر: {v2} ج | صافي: {v3} ج'.tr({
                    'v1': s['name'],
                    'v2': s['earned'].toStringAsFixed(2),
                    'v3': s['netEarned'].toStringAsFixed(2),
                  }),
                )
                .join('\n');

    // عرض الـ AlertDialog
    showDialog(
      context: context,
      builder:
          (_) => AppDialog(
            title: Text('تأكيد قفل الشيفت'.tr()),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '📊 ملخص مبيعات الشيفت:'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• إجمالي المبيعات: {v1} {v2}'.tr({
                      'v1': totalSalesBeforeDiscount.toStringAsFixed(2),
                      'v2': Money.txt,
                    }),
                  ),
                  Text(
                    '• المشروبات: {v1} {v2}'.tr({
                      'v1': totalDrinks.toStringAsFixed(2),
                      'v2': Money.txt,
                    }),
                  ),
                  if (totalProducts > 0)
                    Text(
                      '• المنتجات/المأكولات: {v1} {v2}'.tr({
                        'v1': totalProducts.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                    ),
                  if (totalDevices > 0)
                    Text(
                      '• الأجهزة: {v1} {v2}'.tr({
                        'v1': totalDevices.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                    ),
                  if (totalCigarettes > 0)
                    Text(
                      '• السجائر: {v1} {v2}'.tr({
                        'v1': totalCigarettes.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                    ),
                  if (totalShisha > 0)
                    Text(
                      '• الشيشة: {v1} {v2}'.tr({
                        'v1': totalShisha.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                    ),
                  Text(
                    '• إجمالي الأصناف المباعة: {totalItemsSoldQty} قطعة'.tr({
                      'totalItemsSoldQty': totalItemsSoldQty,
                    }),
                  ),
                  Text(
                    '• المصروفات المسجلة: {v1} {v2}'.tr({
                      'v1': totalExpenses.toStringAsFixed(2),
                      'v2': Money.txt,
                    }),
                  ),
                  Divider(height: 20),
                  Text(
                    '👥 أجور الموظفين:'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(earningsText),
                  SizedBox(height: 12),
                  Text(
                    'هل تريد تأكيد قفل الشيفت وطباعة التقرير؟'.tr(),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء'.tr(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.lock),
                label: Text('تأكيد القفل'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  // 1️⃣ جلب بيانات الكاشير الرئيسي
                  final mainStaff = await DBHelper.getUserById(widget.staffId);
                  double mainWorkedHours = 0.0;
                  double mainEarned = 0.0;
                  double mainNetEarned = 0.0;

                  if (mainStaff != null) {
                    final shiftStartStr = mainStaff['shift_start'];
                    final shiftEndStr = mainStaff['shift_end'];
                    final salaryPerHour =
                        (mainStaff['salary_per_hour'] ?? 0.0) as double;
                    final advance = (mainStaff['advance'] ?? 0.0) as double;

                    if (shiftStartStr != null) {
                      final start = DateTime.parse(shiftStartStr);
                      final end =
                          shiftEndStr != null
                              ? DateTime.parse(shiftEndStr)
                              : DateTime.now();
                      mainWorkedHours = end.difference(start).inSeconds / 3600;
                      mainEarned = mainWorkedHours * salaryPerHour;
                      mainNetEarned = (mainEarned - advance).clamp(
                        0,
                        mainEarned,
                      );
                    }

                    // 2️⃣ إضافة راتب الكاشير للمستحقات بدل المصروف مباشرة
                    if (mainNetEarned > 0) {
                      await DBHelper.addStaffDueSalary({
                        'id': mainStaff['id'],
                        'name': mainStaff['username'],
                        'shiftId': widget.shiftId,
                        'hours': mainWorkedHours,
                        'earned': mainEarned,
                        'advance': advance,
                        'net': mainNetEarned,
                      });
                    }
                  }

                  // 1️⃣ جلب وحساب الأجور
                  final subStaffList = await DBHelper.getSubStaff(
                    widget.staffId,
                  );

                  List<Map<String, dynamic>> staffEarnings =
                      subStaffList.map((staff) {
                        final shiftStartStr = staff['shift_start'];
                        final shiftEndStr = staff['shift_end'];
                        final salaryPerHour =
                            (staff['salary_per_hour'] ?? 0.0) as double;
                        final advance = (staff['advance'] ?? 0.0) as double;
                        double workedHours = 0.0;
                        double earned = 0.0;
                        double netEarned = 0.0;

                        if (shiftStartStr != null) {
                          final start = DateTime.parse(shiftStartStr);
                          final end =
                              shiftEndStr != null
                                  ? DateTime.parse(shiftEndStr)
                                  : DateTime.now();
                          workedHours = end.difference(start).inSeconds / 3600;
                          earned = workedHours * salaryPerHour;
                          netEarned = (earned - advance).clamp(0, earned);
                        }

                        return {
                          'id': staff['id'],
                          'name': staff['username'] ?? 'غير معروف'.tr(),
                          'workedHours': workedHours,
                          'earned': earned,
                          'advance': advance,
                          'netEarned': netEarned,
                        };
                      }).toList();

                  // 2️⃣ إضافة الأجور للمصروفات
                  for (var staff in staffEarnings) {
                    if (staff['netEarned'] > 0) {
                      /*   await DBHelper.addExpense(
                    description: "أجر ${staff['name']}",
                    amount: staff['netEarned'],
                    shiftId: widget.shiftId,
                    addedBy: widget.staffName,
                  );*/
                      await DBHelper.addStaffDueSalary({
                        'id': staff['id'],
                        'name': staff['name'],
                        'shiftId': widget.shiftId,
                        'hours': staff['workedHours'],
                        'earned': staff['earned'],
                        'advance': staff['advance'],
                        'net': staff['netEarned'],
                      });
                    }
                  }
                  final db = await DBHelper.database;
                  final allShifts = await db.query('staff_shifts');
                  print('جميع الشيفتات في staff_shifts:');
                  for (var row in allShifts) {
                    print(row);
                  }

                  // 3️⃣ إغلاق الموظفين الفرعيين
                  await DBHelper.closeAllOpenSubStaffShifts();
                  print('widget.shiftId = ${widget.shiftId}');

                  await Future.delayed(
                    const Duration(milliseconds: 300),
                  ); // تأخير بسيط للتأكيد
                  subStaffUpdateCubit.markUpdated();
                  final updated = await DBHelper.database.then(
                    (db) => db.query(
                      'sub_staff',
                      where: 'supervisor_shift_id = ?',
                      whereArgs: [widget.shiftId],
                    ),
                  );
                  print(updated);

                  // 4️⃣ إغلاق الشيفت الرئيسي
                  final closed = await _closeShift();

                  // 5️⃣ بعد القفل: خروج كامل لشاشة اللوجين مع تصفير الستاك كله —
                  // pushAndRemoveUntil أضمن من popUntil(#first): مفيش أي دايلوج
                  // قديم أو شاشة مكدسة تقدر تفضل فوق اللوجين.
                  if (closed) {
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  } else {
                    AppToast.show(
                      '⚠️ لا يمكن الرجوع قبل قفل جميع الترابيزات والبلايستيشن'
                          .tr(),
                      kind: FeedbackKind.error,
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  /// 🛡️ جارد القفل — بيرجّع **حالة** بس من غير ما ينفذ أي قفل بنفسه:
  /// - 'clear'   = مفيش ترابيزات أو أجهزة مفتوحة → ينفع تقفل عادي.
  /// - 'blocked' = المستخدم شاف التحذير واختار «حسناً» → ممنوع القفل.
  /// - 'handover'= اختار «تسليم الشيفت» → التنفيذ في [_closeShift] مرة
  ///   واحدة بالظبط (كان قبل كده بيتنفذ جوه الجارد ثم تاني في
  ///   [_closeShift] = التقرير بيطلع مرتين).
  Future<String> _canCloseShift(BuildContext context) async {
    // 🔹 ترابيزات المشروبات
    final tables = await DBHelper.getAllTables();
    final openTables =
        tables.where((t) => t['active_invoice_id'] != null).toList();

    if (openTables.isNotEmpty) {
      final action = await showDialog<String>(
        context: context,
        builder:
            (_) => AppDialog(
              title: Text('⚠️ لا يمكن قفل الشيفت'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('يوجد ترابيزات مفتوحة:'.tr()),
                  SizedBox(height: 8),
                  ...openTables.map((t) => Text('• ${t['name']}')),
                  SizedBox(height: 10),
                  Text(
                    'تقدر تسلّم الشيفت (بالترابيزات المفتوحة وحسابها) لموظف تاني ويكمّله.'
                        .tr(),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('حسناً'.tr()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'handover'),
                  child: Text('🤝 تسليم الشيفت'.tr()),
                ),
              ],
            ),
      );
      return action == 'handover' ? 'handover' : 'blocked';
    }

    // 🔹 أجهزة البلايستيشن
    final psInvoices =
        (await DBHelper.getActiveInvoices())
            .where((inv) => (inv['console_id'] ?? 0) != 0)
            .toList();

    if (psInvoices.isNotEmpty) {
      final action = await showDialog<String>(
        context: context,
        builder:
            (_) => AppDialog(
              title: Text('⚠️ لا يمكن قفل الشيفت'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('يوجد أجهزة بلايستيشن تعمل حالياً:'.tr()),
                  SizedBox(height: 8),
                  ...psInvoices.map(
                    (inv) => Text(
                      '• جهاز رقم {v1}'.tr({'v1': inv['console_id']}),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'تقدر تسلّم الشيفت (بالجلسات المفتوحة وحسابها) لموظف تاني ويكمّله.'
                        .tr(),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('حسناً'.tr()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'handover'),
                  child: Text('🤝 تسليم الشيفت'.tr()),
                ),
              ],
            ),
      );
      return action == 'handover' ? 'handover' : 'blocked';
    }

    return 'clear';
  }

  Future<bool> _closeShift({bool force = false}) async {
    final confirmed = await _confirmCashierPassword(context);
    if (!confirmed) return false;
    if (!force) {
      final guard = await _canCloseShift(context);
      if (guard == 'blocked') return false;
      // 🤝 التسليم بيقفل الشيفت هنا مرة واحدة — وبكلمة سر واحدة كمان
      // (اتأكدنا منها فوق، فمش بنسألها تاني جوه التسليم).
      if (guard == 'handover') {
        return _handoverAndClose(alreadyConfirmed: true);
      }
    }
    return _executeShiftClose();
  }

  /// 🤝 تسليم الشيفت لموظف تاني (مع الفواتير المفتوحة وحسابها):
  /// اختيار موظف → تأكيد بكلمة السر → نقل الفواتير لشيفت الجديد → قفل الشيفت.
  /// الراجع true = الشيفت اتقفل فعلاً بعد التسليم.
  Future<bool> _handoverAndClose({bool alreadyConfirmed = false}) async {
    final picked = await _pickHandoverEmployee();
    if (picked == null) return false;

    // لو جاينا من [_closeShift] فالباسورد اتأكدنا منه هناك — مش بنسأله تاني.
    if (!alreadyConfirmed) {
      final confirmed = await _confirmCashierPassword(context);
      if (!confirmed) return false;
    }

    final result = await DBHelper.handoverShift(
      oldShiftId: widget.shiftId,
      targetUserId: (picked['id'] as num?)?.toInt() ?? 0,
      // 🏷️ اسم الفواتير المنقولة يتغير لاسم اللي سلّمتم له — كده كل
      // التقارير (بما إنها بتشترط staff_name في نطاق الزمن) بتحسبهم صح.
      targetUserName: picked['username']?.toString() ?? '',
    );
    final moved = (result['moved'] as num?)?.toInt() ?? 0;
    final targetName = picked['username']?.toString() ?? '';

    final closed = await _executeShiftClose();
    if (!closed) return false;

    final label =
        moved > 0 ? ' مع {moved} فاتورة مفتوحة'.tr({'moved': moved}) : '';
    AppToast.show(
      '✅ تم تسليم الشيفت{label} للموظف {targetName}'.tr({
        'label': label,
        'targetName': targetName,
      }),
    );
    // ✍️ الـ pop بيتعمل في الفلو الخارجي لزرار القفل (بعد ما _closeShift ترجع
    // true) — عشان ما نعملش pop مرتين من كونتِكست ممكن يكون اتنفرد.
    return true;
  }

  /// 🤝 اختيار الموظف اللي هيتسلم له الشيفت — **الكاشير بس**: الويتر
  /// مش بيتحاسب على شيفت (مفيش له إمكانية قفل) والأدمن والسوبر أدمن
  /// مش بياخدوا شيفت أصلًا — فمحد فيهم يظهر في القايمة.
  Future<Map<String, Object?>?> _pickHandoverEmployee() async {
    final db = await DBHelper.database;
    final users = await db.query(
      'users',
      where: "id != ? AND role = 'cashier'",
      whereArgs: [widget.staffId],
      orderBy: 'username ASC',
    );

    return showDialog<Map<String, Object?>?>(
      context: context,
      builder:
          (dlg) => AppDialog(
            title: Text('🤝 تسليم الشيفت لموظف تاني'.tr()),
            content: SizedBox(
              width: 340,
              child:
                  users.isEmpty
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('مفيش موظفين تانيين مسجلين.'.tr()),
                          SizedBox(height: 4),
                          Text(
                            'ضيف موظف من شاشة إدارة المستخدمين الأول.'.tr(),
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.person_outline),
                            title: Text('${u['username'] ?? ''}'),
                            subtitle: Text(
                              'الدور: {v1}'.tr({
                                'v1': _roleLabel(u['role']?.toString() ?? ''),
                              }),
                            ),
                            onTap: () => Navigator.pop(dlg, u),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlg),
                child: Text('إلغاء'.tr()),
              ),
            ],
          ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'superadmin':
        return 'سوبر أدمن'.tr();
      case 'admin':
        return 'أدمن'.tr();
      case 'waiter':
        return 'ويتر'.tr();
      default:
        return 'كاشير'.tr();
    }
  }

  // 🔸 جسم القفل الفعلي (يتصل من القفل العادي أو بعد التسليم)
  Future<bool> _executeShiftClose() async {
    final now = DateTime.now();

    // ✅ اطبع تقرير الشيفت (كل الحسابات جوه الدالة نفسها)
    await _printShiftReport(widget.shiftId);

    // ✅ اقفل الشيفت فعليًا
    await DBHelper.checkOut(widget.shiftId, now.toIso8601String());
    await BackupHelper.saveAutoBackupSnapshot();
    // 🆕 رفع نسخة على السيرفر (Supabase) كمان — من غير ما يوقف قفل الشيفت لو فشل
    try {
      await BackupHelper.uploadBackupToSupabase();
    } catch (e) {
      debugPrint('⚠️ فشل رفع النسخة على السيرفر بعد قفل الشيفت: $e');
    }
    AppToast.show(
      'تم قفل الشيفت في {v1}'.tr({'v1': DateFormat('HH:mm').format(now)}),
    );
    return true;
  }

  Future<bool> _confirmCashierPassword(BuildContext context) async {
    final passController = TextEditingController();
    bool isValid = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AppDialog(
          title: Text('تأكيد قفل الشيفت'.tr()),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'أدخل كلمة المرور'.tr()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text('إلغاء'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passController.text.trim();

                // ✅ تحقق من الباسورد
                final user = await DBHelper.getUserById(widget.staffId);

                if (user != null && user['password'] == password) {
                  isValid = true;
                  Navigator.pop(ctx);
                } else {
                  AppToast.show(
                    'كلمة المرور غير صحيحة'.tr(),
                    kind: FeedbackKind.error,
                  );
                }
              },
              child: Text('تأكيد'.tr()),
            ),
          ],
        );
      },
    );

    return isValid;
  }

  Future<void> _printShiftReport(int shiftId) async {
    final pdf = pw.Document();

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Alexandria-Bold.ttf'),
    );
    final db = await DBHelper.database;
    vodafoneCashTotal = await DBHelper.getVodafoneCashTotal(widget.shiftId);
    vodafoneCashNotes = await DBHelper.getVodafoneCashNotes(widget.shiftId);
    final rawInvoices = await DBHelper.getInvoicesByShift(shiftId);
    final productsSummary = await DBHelper.getShiftProductsSummary(shiftId);
    final invoices =
        rawInvoices.map((inv) => Map<String, dynamic>.from(inv)).toList();

    // 🆕 حساب المدفوع فعليًا (paid_partial) لكل فاتورة، بما فيها الآجل الجزئي
    for (var inv in invoices) {
      double paidPartial;
      final totalCost =
          (inv['total_cost'] as num?)?.toDouble() ??
          ((inv['device_cost'] ?? 0) as num).toDouble() +
              ((inv['drinks_cost'] ?? 0) as num).toDouble() -
              ((inv['discount'] ?? 0) as num).toDouble();

      if (inv['payment_type'] == 'علي الحساب' ||
          inv['payment_type'] == 'debt') {
        final debtRows = await db.query(
          'debts',
          where: 'invoice_id = ?',
          whereArgs: [inv['id']],
        );
        if (debtRows.isNotEmpty) {
          final debtPaymentsRows = await db.query(
            'debt_payments',
            where: 'debt_id = ?',
            whereArgs: [debtRows.first['id']],
          );
          paidPartial = debtPaymentsRows.fold<double>(
            0.0,
            (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
          );
        } else {
          paidPartial = 0.0;
        }
      } else if (inv['payment_type'] == 'ملغي') {
        paidPartial = 0.0;
      } else {
        paidPartial = totalCost; // مدفوعة بالكامل
      }

      inv['paid_partial'] = paidPartial;
      inv['total_cost_calc'] = totalCost;
    }
    final expenses = await DBHelper.getExpensesByShift(shiftId);
    final rawDebts = await DBHelper.getDebtsByShift(shiftId);
    final debts = rawDebts.map((d) => Map<String, dynamic>.from(d)).toList();

    // 🆕 حساب المدفوع والخصم فعليًا لكل دين، عشان "الآجل الجديد" يعرض الباقي مش الإجمالي
    for (var d in debts) {
      final debtId = d['id'] as int;
      final debtDate =
          DateTime.tryParse(d['date']?.toString() ?? '') ?? DateTime(1970);

      final payments = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
        orderBy: 'paid_at ASC',
      );

      // ✅ كل الدفعات (بما فيها الجزئي المرحّل) — للعرض بس "مدفوع فعليًا"
      final paidAll = payments.fold<double>(
        0.0,
        (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
      );

      // ✅ الدفعات اللي حصلت بعد إنشاء الدين فقط
      // (الدفعة الجزئية القديمة المرحّلة تاريخها قبل تاريخ الدين، فمستبعدة هنا
      // لأنها أصلاً متطروحة جوه total_amount من _endSession)
      final paymentsAfterCreation =
          payments.where((p) {
            final paidAt = DateTime.tryParse(p['paid_at']?.toString() ?? '');
            return paidAt != null && !paidAt.isBefore(debtDate);
          }).toList();

      final paidAfter = paymentsAfterCreation.fold<double>(
        0.0,
        (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
      );
      final discountAfter = paymentsAfterCreation.fold<double>(
        0.0,
        (sum, p) => sum + ((p['discount'] as num?)?.toDouble() ?? 0.0),
      );

      final total = (d['total_amount'] as num?)?.toDouble() ?? 0.0;
      d['paid_partial'] = paidAll; // للعرض: كل المدفوع من أول الفاتورة
      d['remaining_amount'] = total - paidAll - discountAfter; // الباقي الحقيقي
    }
    final transactions = await DBHelper.getTransactionsByShift(shiftId);

    final shiftRow = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [shiftId],
    );
    final checkIn =
        shiftRow.isNotEmpty ? shiftRow.first['check_in'] as String? : null;
    final checkOut =
        shiftRow.isNotEmpty ? shiftRow.first['check_out'] as String? : null;

    final rangeStart = checkIn ?? DateTime.now().toIso8601String();
    final rangeEnd = checkOut ?? DateTime.now().toIso8601String();

    // 🆕 مجموعة IDs بتاعة فواتير الشيفت الحالي (عشان نستثني ديونها من "المحصّل")
    // 🆕 مجموعة IDs بتاعة فواتير الشيفت الحالي (عشان نستثني ديونها من "المحصّل")
    final currentShiftInvoiceIds =
        invoices.map((inv) => inv['id']).whereType<int>().toSet();

    // 🔧 قراءة مباشرة من debt_payments بدون أي JOIN خالص
    // (customer_name و invoice_id بقوا متسجلين جوه الجدول نفسه)
    final debtPaymentsRowsRaw = await db.query(
      'debt_payments',
      where: 'paid_at >= ? AND paid_at <= ?',
      whereArgs: [rangeStart, rangeEnd],
      orderBy: 'paid_at ASC',
    );

    // 🔧 استبعاد أي دفعة خاصة بدين اتسجل واتحصّل في نفس الشيفت
    final debtPaymentsRows =
        debtPaymentsRowsRaw.where((p) {
          final invId = p['invoice_id'];
          if (invId == null) return true;
          return !currentShiftInvoiceIds.contains(invId as int);
        }).toList();

    // 🔧 استبعاد أي دفعة خاصة بدين اتسجل واتحصّل في نفس الشيفت
    // (لأن فاتورته أصلاً بقت 'paid' واتحسبت ضمن الأجهزة/المشروبات)

    final totalDebtCollected = debtPaymentsRows.fold<double>(
      0.0,
      (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
    );
    final totalDebtDiscount = debtPaymentsRows.fold<double>(
      0.0,
      (sum, p) => sum + ((p['discount'] ?? 0) as num).toDouble(),
    );

    final totalDevicesPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum + ((inv['device_cost'] as num?)?.toDouble() ?? 0.0);
    });

    final totalDrinksPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum + ((inv['drinks_cost'] as num?)?.toDouble() ?? 0.0);
    });

    final totalProductsPaid = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum + ((inv['products_cost'] as num?)?.toDouble() ?? 0.0);
    });

    final totalCigarettes = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum + ((inv['cigarettes_cost'] as num?)?.toDouble() ?? 0.0);
    });

    final totalShisha = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      return sum + ((inv['shisha_cost'] as num?)?.toDouble() ?? 0.0);
    });
    final totalDiscounts = invoices.fold<double>(0.0, (sum, inv) {
      if (inv['payment_type'] == 'ملغي') return sum;
      final discount = (inv['discount'] as num?)?.toDouble() ?? 0.0;
      return sum + discount;
    });
    final totalExpenses = expenses.fold(
      0.0,
      (sum, e) => sum + (e['amount'] ?? 0),
    );
    final totalTransactions = transactions.fold(
      0.0,
      (sum, t) => sum + (t['received'] ?? 0),
    );

    final totalDebts = debts.fold<double>(
      0.0,
      (double sum, d) => sum + ((d['remaining_amount'] as double?) ?? 0.0),
    );
    final cancelledInvoices =
        invoices.where((inv) => inv['payment_type'] == 'ملغي').toList();

    final totalCancelled = cancelledInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + ((inv['total_cost'] as num?)?.toDouble() ?? 0.0),
    );

    final grandTotalBeforeDiscount =
        totalDevicesPaid +
        totalDrinksPaid +
        totalProductsPaid +
        totalCigarettes +
        totalShisha +
        totalTransactions +
        totalDebtCollected -
        totalExpenses;

    final grandTotal =
        grandTotalBeforeDiscount - totalDiscounts; // ✅ بعد الخصم فعليًا
    final placeName = await BusinessProfile.getPlaceName();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
          72 * PdfPageFormat.mm,
          300 * PdfPageFormat.mm,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        textDirection: pw.TextDirection.rtl,
        build:
            (context) => [
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Column(
                  children: [
                    pw.Text(
                      ' $placeName ',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'تقرير نهاية الشيفت'.tr(),
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
              ),
              pw.Text(
                'الموظف: {v1}'.tr({'v1': widget.staffName}),
                style: pw.TextStyle(font: fontRegular, fontSize: 8),
              ),
              pw.Text(
                'التاريخ: {v1}'.tr({
                  'v1': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                }),
                style: pw.TextStyle(font: fontRegular, fontSize: 8),
              ),
              pw.Divider(thickness: 0.5),

              // الفواتير
              pw.Text(
                'الفواتير:'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 9),
              ),
              ...invoices.map((inv) {
                final customer = (inv['customer_name'] ?? '').toString().trim();
                final customerName =
                    customer.isEmpty ? 'غير معروف'.tr() : customer;
                final device = (inv['device_cost'] ?? 0).toDouble();
                final drinks = (inv['drinks_cost'] ?? 0).toDouble();
                final products =
                    ((inv['products_cost'] ?? 0) as num).toDouble();
                final cigarettes = (inv['cigarettes_cost'] ?? 0).toDouble();
                final shisha = (inv['shisha_cost'] ?? 0).toDouble();
                final discount = (inv['discount'] ?? 0).toDouble();
                final total =
                    (inv['total_cost'] as num?)?.toDouble() ??
                    (device +
                        drinks +
                        products +
                        cigarettes +
                        shisha -
                        discount);
                // 🆕 المدفوع فعليًا والباقي
                final paidPartial = (inv['paid_partial'] as double?) ?? 0.0;
                final totalCostCalc =
                    (inv['total_cost_calc'] as double?) ?? total;
                final remaining = totalCostCalc - paidPartial;
                final isPartiallyPaid =
                    remaining > 0.01 && inv['payment_type'] != 'ملغي';

                final start =
                    inv['start_time'] != null
                        ? DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(inv['start_time']))
                        : '-';
                final end =
                    inv['end_time'] != null
                        ? DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(inv['end_time']))
                        : '-';

                final isOnCredit = (inv['payment_type'] ?? '') == 'علي الحساب';

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'الزبون: {customerName}{v2}'.tr({
                        'customerName': customerName,
                        'v2': isOnCredit ? ' (علي الحساب)'.tr() : '',
                      }),
                      style: pw.TextStyle(
                        font: isOnCredit ? fontBold : fontRegular,
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      'من {start} إلى {end}'.tr({'start': start, 'end': end}),
                      style: pw.TextStyle(font: fontRegular, fontSize: 7),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'جهاز :'.tr(),
                          style: pw.TextStyle(fontSize: 7, font: fontBold),
                        ),
                        pw.Text(
                          '${device.toStringAsFixed(2)} ${Money.txt}',
                          style: pw.TextStyle(fontSize: 7, font: fontBold),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          ' مشروبات :'.tr(),
                          style: pw.TextStyle(fontSize: 7, font: fontBold),
                        ),
                        pw.Text(
                          '${drinks.toStringAsFixed(2)} ${Money.txt}',
                          style: pw.TextStyle(fontSize: 7, font: fontBold),
                        ),
                      ],
                    ),
                    if (products > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'منتجات / مأكولات :'.tr(),
                            style: pw.TextStyle(fontSize: 7, font: fontBold),
                          ),
                          pw.Text(
                            '${products.toStringAsFixed(2)} ${Money.txt}',
                            style: pw.TextStyle(fontSize: 7, font: fontBold),
                          ),
                        ],
                      ), // 🆕 سجاير — تتطبع بس لو موجودة
                    if (cigarettes > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'سجائر :'.tr(),
                            style: pw.TextStyle(fontSize: 7, font: fontBold),
                          ),
                          pw.Text(
                            '${cigarettes.toStringAsFixed(2)} ${Money.txt}',
                            style: pw.TextStyle(fontSize: 7, font: fontBold),
                          ),
                        ],
                      ),
                    // 🆕 شيشة — تتطبع بس لو موجودة
                    if (shisha > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'شيشة :'.tr(),
                            style: pw.TextStyle(fontSize: 7, font: fontBold),
                          ),
                          pw.Text(
                            '${shisha.toStringAsFixed(2)} ${Money.txt}',
                            style: pw.TextStyle(fontSize: 7, font: fontBold),
                          ),
                        ],
                      ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'الخصم:'.tr(),
                          style: pw.TextStyle(font: fontBold, fontSize: 7),
                        ),
                        pw.Text(
                          '${discount.toStringAsFixed(2)} ${Money.txt}',
                          style: pw.TextStyle(font: fontBold, fontSize: 7),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'الإجمالي:'.tr(),
                          style: pw.TextStyle(font: fontBold, fontSize: 8),
                        ),
                        pw.Text(
                          '${total.toStringAsFixed(2)} ${Money.txt}',
                          style: pw.TextStyle(font: fontBold, fontSize: 8),
                        ),
                      ],
                    ),
                    if (isPartiallyPaid) ...[
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'مدفوع:'.tr(),
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 7,
                              color: PdfColors.teal800,
                            ),
                          ),
                          pw.Text(
                            '${paidPartial.toStringAsFixed(2)} ${Money.txt}',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 7,
                              color: PdfColors.teal800,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'الباقي:'.tr(),
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 7,
                              color: PdfColors.red800,
                            ),
                          ),
                          pw.Text(
                            '${remaining.toStringAsFixed(2)} ${Money.txt}',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 7,
                              color: PdfColors.red800,
                            ),
                          ),
                        ],
                      ),
                    ],
                    pw.Divider(thickness: 0.3),
                  ],
                );
              }),
              // 🆕 قسم الفواتير الملغية
              pw.SizedBox(height: 4),
              pw.Text(
                'الفواتير الملغية:'.tr(),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              if (cancelledInvoices.isEmpty)
                pw.Text(
                  'لا توجد فواتير ملغية'.tr(),
                  style: pw.TextStyle(font: fontRegular, fontSize: 7),
                )
              else
                ...cancelledInvoices.map((inv) {
                  final customer =
                      (inv['customer_name'] ?? '').toString().trim();
                  final customerName =
                      customer.isEmpty ? 'غير معروف'.tr() : customer;
                  final total = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;
                  final start =
                      inv['start_time'] != null
                          ? DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(inv['start_time']))
                          : '-';
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '$customerName ($start)',
                        style: pw.TextStyle(
                          fontSize: 7,
                          font: fontRegular,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        '${total.toStringAsFixed(2)} ${Money.txt}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          font: fontBold,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  );
                }),
              if (cancelledInvoices.isNotEmpty)
                pw.Text(
                  'إجمالي الملغي (غير محسوب): {v1} {v2}'.tr({
                    'v1': totalCancelled.toStringAsFixed(2),
                    'v2': Money.txt,
                  }),
                  style: pw.TextStyle(
                    fontSize: 7,
                    font: fontBold,
                    color: PdfColors.grey700,
                  ),
                ),
              // 🆕 جدول تفاصيل الأصناف والمنتجات المباعة في الشيفت
              pw.SizedBox(height: 4),
              pw.Text(
                'الأصناف والمنتجات المباعة:'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 9),
              ),
              if (productsSummary.isEmpty)
                pw.Text(
                  'لا توجد أصناف مباعة في هذا الشيفت'.tr(),
                  style: pw.TextStyle(font: fontRegular, fontSize: 7),
                )
              else ...[
                pw.SizedBox(height: 2),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 0.5),
                      top: pw.BorderSide(width: 0.5),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          'الصنف'.tr(),
                          style: pw.TextStyle(font: fontBold, fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'الكمية'.tr(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontBold, fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'السعر'.tr(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontBold, fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'الإجمالي'.tr(),
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(font: fontBold, fontSize: 7),
                        ),
                      ),
                    ],
                  ),
                ),
                ...productsSummary.map((p) {
                  final name = (p['product_name'] ?? '').toString();
                  final qty = ((p['total_qty'] ?? 0) as num).toInt();
                  final price = ((p['unit_price'] ?? 0) as num).toDouble();
                  final total = ((p['total_amount'] ?? 0) as num).toDouble();
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            name,
                            style: pw.TextStyle(font: fontRegular, fontSize: 7),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '$qty',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: fontBold, fontSize: 7),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            price.toStringAsFixed(1),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: fontRegular, fontSize: 7),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            '{v1} ج'.tr({'v1': total.toStringAsFixed(2)}),
                            textAlign: pw.TextAlign.left,
                            style: pw.TextStyle(font: fontBold, fontSize: 7),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                pw.Divider(thickness: 0.5),
              ],

              // المصروفات
              pw.Text(
                'المصروفات:'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 9),
              ),
              ...expenses.map(
                (e) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      e['description'],
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                    pw.Text(
                      '${(e['amount'] ?? 0).toStringAsFixed(2)} ${Money.txt}',
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                  ],
                ),
              ),

              // الديون الجديدة (اللي اتسجلت في الشيفت ده)
              pw.Text(
                'الاجل الجديد:'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 9),
              ),
              ...debts.map((d) {
                final remaining =
                    (d['remaining_amount'] as double?) ??
                    ((d['total_amount'] as num?)?.toDouble() ?? 0.0);
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      d['customer_name'],
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                    pw.Text(
                      '${remaining.toStringAsFixed(2)} ${Money.txt}',
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                  ],
                );
              }),

              // 🆕 قسم المحصّل من الآجل
              pw.SizedBox(height: 4),
              pw.Text(
                'محصّل من الآجل:'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 9),
              ),
              if (debtPaymentsRows.isEmpty)
                pw.Text(
                  'لا يوجد تحصيل في هذا الشيفت'.tr(),
                  style: pw.TextStyle(font: fontRegular, fontSize: 7),
                )
              else
                ...debtPaymentsRows.map((p) {
                  final customer =
                      (p['customer_name'] ?? 'غير معروف'.tr()).toString();
                  final amount = ((p['amount'] ?? 0) as num).toDouble();
                  final discount = ((p['discount'] ?? 0) as num).toDouble();
                  final time =
                      p['paid_at'] != null
                          ? DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(p['paid_at'] as String))
                          : '-';
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '$customer ($time)',
                        style: pw.TextStyle(fontSize: 7, font: fontRegular),
                      ),
                      pw.Text(
                        discount > 0
                            ? '{v1} {v2} (خصم {v3})'.tr({
                              'v1': amount.toStringAsFixed(2),
                              'v2': Money.txt,
                              'v3': discount.toStringAsFixed(2),
                            })
                            : '${amount.toStringAsFixed(2)} ${Money.txt}',
                        style: pw.TextStyle(fontSize: 7, font: fontBold),
                      ),
                    ],
                  );
                }),

              // الملخص
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ملخص الشيفت'.tr(),
                      style: pw.TextStyle(font: fontBold, fontSize: 9),
                    ),
                    pw.Text(
                      'إجمالي الأجهزة: {v1} {v2}'.tr({
                        'v1': totalDevicesPaid.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'إجمالي المشروبات: {v1} {v2}'.tr({
                        'v1': totalDrinksPaid.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                    pw.SizedBox(height: 2),
                    if (totalProductsPaid > 0) ...[
                      pw.Text(
                        'إجمالي المنتجات/المأكولات: {v1} {v2}'.tr({
                          'v1': totalProductsPaid.toStringAsFixed(2),
                          'v2': Money.txt,
                        }),
                        style: pw.TextStyle(fontSize: 7, font: fontBold),
                      ),
                      pw.SizedBox(height: 2),
                    ],
                    // 🆕 عرض السجاير والشيشة لو موجودين
                    if (totalCigarettes > 0) ...[
                      pw.Text(
                        'إجمالي السجائر: {v1} {v2}'.tr({
                          'v1': totalCigarettes.toStringAsFixed(2),
                          'v2': Money.txt,
                        }),
                        style: pw.TextStyle(fontSize: 7, font: fontBold),
                      ),
                      pw.SizedBox(height: 2),
                    ],
                    if (totalShisha > 0) ...[
                      pw.Text(
                        'إجمالي الشيشة: {v1} {v2}'.tr({
                          'v1': totalShisha.toStringAsFixed(2),
                          'v2': Money.txt,
                        }),
                        style: pw.TextStyle(fontSize: 7, font: fontBold),
                      ),
                      pw.SizedBox(height: 2),
                    ],
                    pw.Text(
                      'المصروفات: {v1} {v2}'.tr({
                        'v1': totalExpenses.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                    pw.SizedBox(height: 2),

                    // 🆕 السطر المهم اللي كان ناقص
                    pw.Text(
                      ' محصّل من الآجل: {v1} {v2}'.tr({
                        'v1': totalDebtCollected.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: fontBold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    if (totalDebtDiscount > 0)
                      pw.Text(
                        'خصم على التحصيل: {v1} {v2}'.tr({
                          'v1': totalDebtDiscount.toStringAsFixed(2),
                          'v2': Money.txt,
                        }),
                        style: pw.TextStyle(fontSize: 7, font: fontRegular),
                      ),
                    pw.SizedBox(height: 2),

                    pw.Text(
                      'الاجل الجديد: {v1} {v2}'.tr({
                        'v1': (totalDebts).toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                      style: pw.TextStyle(
                        fontSize: 7,
                        font: fontBold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    // 🆕 الخصم يظهر بس لو حصل، في الآخر قبل المجموع النهائي
                    if (totalDiscounts > 0) ...[
                      pw.Text(
                        'إجمالي الخصومات: {v1} {v2}'.tr({
                          'v1': totalDiscounts.toStringAsFixed(2),
                          'v2': Money.txt,
                        }),
                        style: pw.TextStyle(
                          fontSize: 7,
                          font: fontBold,
                          color: PdfColors.orange800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                    ],
                    pw.Text(
                      'المجموع الكلي: {v1} {v2}'.tr({
                        'v1': grandTotal.toStringAsFixed(2),
                        'v2': Money.txt,
                      }),
                      style: pw.TextStyle(font: fontBold, fontSize: 8),
                    ),
                    // ...
                    /*   pw.Text(
                    'المجموع الكلي (قبل الخصم): ${grandTotalBeforeDiscount.toStringAsFixed(2)} ${Money.txt}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8)),*/
                    pw.Text(
                      ('المجموع الكلي (بعد الخصم+الاجل): '.tr() +
                          '${(grandTotal - totalDebts).toStringAsFixed(2)} ${Money.txt}'),
                      style: pw.TextStyle(font: fontBold, fontSize: 8),
                    ),
                    /*   pw.Text(
                    ' بعد الخصم المجموع الكلي: ${grandTotaldis.toStringAsFixed(2)} ${Money.txt}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8)),*/
                    /*  pw.SizedBox(height: 2),
                pw.Text(
                    'إجمالي الخصومات: ${totalDiscounts.toStringAsFixed(2)} ${Money.txt}',
                    style: pw.TextStyle(fontSize: 7, font: fontBold)),
                pw.SizedBox(height: 2),*/
                    pw.Text(
                      'فودافون كاش (معلومة فقط): {v1} {v2}'.tr({
                        'v1': vodafoneCashTotal,
                        'v2': Money.txt,
                      }),
                      style: pw.TextStyle(font: fontBold, fontSize: 8),
                    ),

                    pw.Text(
                      'تم بحمد الله '.tr(),
                      style: pw.TextStyle(fontSize: 7, font: fontBold),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /* Future<void> printDebtInvoice(
      String customer,
      List<Map<String, dynamic>>? debtItems,
      double amountPaid,
      double discount) async {
    final pdf = pw.Document();

    final debtItemsList = (debtItems ?? [])
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('فاتورة دين: $customer'),
          pw.Table.fromTextArray(
            context: context,
            data: <List<String>>[
              <String>['المنتج', 'الكمية', 'السعر', 'الإجمالي'],
              ...debtItemsList.map((item) => [
                    item['drink_name'] ?? '',
                    item['qty'].toString(),
                    (item['price'] ?? 0).toStringAsFixed(2),
                    (item['total'] ?? 0).toStringAsFixed(2),
                  ])
            ],
          ),
        ],
      ),
    );

    final file = File('invoice.pdf');
    await file.writeAsBytes(await pdf.save());
  }*/
  Future<void> _showDebtorsSheet() async {
    final db = await DBHelper.database;
    bool _collectingDebt = false;
    final rawRows = await db.rawQuery('''
  SELECT d.*,
         i.staff_name,
         i.id as invoice_id
  FROM debts d
  LEFT JOIN invoices i ON d.invoice_id = i.id
  ORDER BY d.date DESC
''');

    // 🆕 نحسب المدفوع والمتبقي الحقيقيين لكل دين اعتمادًا على debt_payments
    // (بدل ما نعتمد على total_amount كأنها هي المتبقي)
    final rows = <Map<String, dynamic>>[];
    for (final raw in rawRows) {
      final row = Map<String, dynamic>.from(raw);
      final debtId = (row['id'] as num).toInt();
      final paidRes = await db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) as s FROM debt_payments WHERE debt_id = ?',
        [debtId],
      );
      final paid = (paidRes.first['s'] as num?)?.toDouble() ?? 0.0;
      final totalAmount = ((row['total_amount'] ?? 0) as num).toDouble();
      row['paid_amount'] = paid;
      row['remaining_amount'] =
          (totalAmount - paid).clamp(0, double.infinity).toDouble();
      rows.add(row);
    }

    List<Map<String, dynamic>> filteredRows = List.from(rows);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              builder: (context, controller) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'الفلوس الاجله (لـ {v1})'.tr({'v1': widget.staffName}),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'بحث باسم العميل'.tr(),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.blueGrey[700],
                          ),
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setStateSheet(() {
                            final query = val.toLowerCase();
                            filteredRows =
                                rows.where((r) {
                                  final customer =
                                      (r['customer_name'] ??
                                              r['person_name'] ??
                                              '')
                                          .toString()
                                          .toLowerCase();
                                  return customer.contains(query);
                                }).toList();
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child:
                            filteredRows.isEmpty
                                ? Center(child: Text('لا توجد نتائج'.tr()))
                                : ListView.separated(
                                  controller: controller,
                                  itemCount: filteredRows.length,
                                  separatorBuilder: (_, __) => Divider(),
                                  itemBuilder: (context, i) {
                                    final r = filteredRows[i];
                                    final dateStr = r['date']?.toString();
                                    DateTime? dt;
                                    try {
                                      dt =
                                          dateStr != null
                                              ? DateTime.parse(dateStr)
                                              : null;
                                    } catch (_) {
                                      dt = null;
                                    }
                                    final dateText =
                                        dt != null
                                            ? DateFormat(
                                              'yyyy-MM-dd HH:mm',
                                            ).format(dt)
                                            : 'غير معروف';

                                    // 🆕 المتبقي الحقيقي (بعد طرح debt_payments)
                                    final total =
                                        (r['remaining_amount'] as double?) ??
                                        0.0;
                                    final customer =
                                        (r['customer_name'] ??
                                                r['person_name'] ??
                                                'غير معروف'.tr())
                                            .toString();

                                    return ListTile(
                                      title: Text(
                                        customer,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'التاريخ: {dateText}\nفاتورة: {v2}'.tr({
                                          'dateText': dateText,
                                          'v2': r['invoice_id'] ?? '—',
                                        }),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${total.toStringAsFixed(2)} ${Money.txt}',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.print,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'طباعة الفاتورة'.tr(),
                                            onPressed: () async {
                                              final r = filteredRows[i];
                                              final customer =
                                                  (r['customer_name'] ??
                                                          r['person_name'] ??
                                                          'غير معروف'.tr())
                                                      .toString();

                                              final debtId =
                                                  (r['id'] as num).toInt();
                                              final db =
                                                  await DBHelper.database;

                                              final items = await db.query(
                                                'debt_items',
                                                where: 'debt_id = ?',
                                                whereArgs: [debtId],
                                              );
                                              final debtItems =
                                                  items
                                                      .map(
                                                        (e) => Map<
                                                          String,
                                                          dynamic
                                                        >.from(e),
                                                      )
                                                      .toList();

                                              final payments = await db.query(
                                                'debt_payments',
                                                where: 'debt_id = ?',
                                                whereArgs: [debtId],
                                              );

                                              // 🆕 نستخدم remaining_amount بدل total_amount
                                              final remainingForPrint =
                                                  (r['remaining_amount']
                                                      as double?) ??
                                                  0.0;
                                              final totalAmountRaw =
                                                  ((r['total_amount'] ?? 0)
                                                          as num)
                                                      .toDouble();

                                              final debtDetails = <
                                                Map<String, dynamic>
                                              >[
                                                {
                                                  'date': r['date'],
                                                  'items': debtItems,
                                                  'total': remainingForPrint,
                                                  'original':
                                                      ((r['original_amount'] ??
                                                                  totalAmountRaw)
                                                              as num)
                                                          .toDouble(),
                                                  'paid':
                                                      (r['paid_amount']
                                                          as double?) ??
                                                      0.0,
                                                  'payments':
                                                      payments
                                                          .map(
                                                            (p) => Map<
                                                              String,
                                                              dynamic
                                                            >.from(p),
                                                          )
                                                          .toList(),
                                                },
                                              ];

                                              // 🔧 الطباعة هنا مش بتعدل أي بيانات، فمفيش
                                              // خطورة، بس برضو نحوطها try/catch للأمان
                                              try {
                                                await printDebtInvoice(
                                                  customer,
                                                  debtDetails,
                                                  0,
                                                  0,
                                                );
                                              } catch (e) {
                                                print(
                                                  '⚠️ فشلت طباعة الفاتورة: $e',
                                                );
                                              }
                                            },
                                          ),
                                          SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                            tooltip: 'تحصيل الدين'.tr(),
                                            onPressed: () async {
                                              final r = filteredRows[i];
                                              final customer =
                                                  (r['customer_name'] ??
                                                          r['person_name'] ??
                                                          'غير معروف'.tr())
                                                      .toString();
                                              // 🆕 المتبقي الحقيقي هو الأساس للتحصيل
                                              final total =
                                                  (r['remaining_amount']
                                                      as double?) ??
                                                  0.0;
                                              final originalInvoiceId =
                                                  r['invoice_id'];

                                              double amountToPay = total;
                                              double discount = 0;
                                              bool shouldPrint =
                                                  false; // 🆕 افتراضيًا مفعّل

                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder: (context) {
                                                  return StatefulBuilder(
                                                    builder: (
                                                      context,
                                                      setDialogState,
                                                    ) {
                                                      return AppDialog(
                                                        title: Text(
                                                          'تحصيل دين {customer}'
                                                              .tr({
                                                                'customer':
                                                                    customer,
                                                              }),
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              'إجمالي الدين: {v1} {v2}'.tr({
                                                                'v1': total
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    ),
                                                                'v2': Money.txt,
                                                              }),
                                                            ),
                                                            SizedBox(height: 8),
                                                            TextField(
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              decoration: InputDecoration(
                                                                labelText:
                                                                    'المبلغ المدفوع'
                                                                        .tr(),
                                                                hintText: total
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    ),
                                                              ),
                                                              onChanged: (v) {
                                                                setDialogState(() {
                                                                  amountToPay =
                                                                      double.tryParse(
                                                                        v,
                                                                      ) ??
                                                                      total;
                                                                  if (amountToPay >
                                                                      total) {
                                                                    amountToPay =
                                                                        total;
                                                                  }
                                                                });
                                                              },
                                                            ),

                                                            SizedBox(height: 8),
                                                            // 🆕 خيار الطباعة
                                                            CheckboxListTile(
                                                              value:
                                                                  shouldPrint,
                                                              onChanged: (val) {
                                                                setDialogState(
                                                                  () {
                                                                    shouldPrint =
                                                                        val ??
                                                                        true;
                                                                  },
                                                                );
                                                              },
                                                              title: Text(
                                                                'طباعة إيصال بعد التحصيل'
                                                                    .tr(),
                                                              ),
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                            child: Text(
                                                              'إلغاء'.tr(),
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                            child: Text(
                                                              'تحصيل'.tr(),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              );

                                              if (confirm != true) return;

                                              final db =
                                                  await DBHelper.database;
                                              final debtId =
                                                  (r['id'] as num).toInt();

                                              await DBHelper.addCashDrawerEntry(
                                                amountToPay,
                                                'income',
                                                'debt',
                                                cashier: widget.staffName,
                                              );

                                              final remainingAmount =
                                                  total -
                                                  amountToPay -
                                                  discount;

                                              final items = await db.query(
                                                'debt_items',
                                                where: 'debt_id = ?',
                                                whereArgs: [debtId],
                                              );

                                              final bool isRechargeOnly =
                                                  items.length == 1 &&
                                                  items.first['drink_name'] ==
                                                      'شحن رصيد';

                                              // ============================
                                              // حالة خاصة: شحن رصيد فقط
                                              // ============================
                                              if (isRechargeOnly) {
                                                if (amountToPay < total) {
                                                  final remaining =
                                                      total - amountToPay;

                                                  // 1️⃣ التوثيق الأول قبل أي حاجة تانية
                                                  await db.insert(
                                                    'debt_payments',
                                                    {
                                                      'debt_id': debtId,
                                                      'amount': amountToPay,
                                                      'discount': 0,
                                                      'paid_at':
                                                          DateTime.now()
                                                              .toIso8601String(),
                                                      'customer_name': customer,
                                                      'invoice_id':
                                                          originalInvoiceId,
                                                      'shift_id':
                                                          widget.shiftId,
                                                    },
                                                  );

                                                  // 🆕 مبقاش فيه تحديث لـ total_amount هنا —
                                                  // total_amount بتفضل ثابتة، وبس debt_payments
                                                  // هي مصدر تتبّع المدفوع/المتبقي

                                                  if (!mounted) return;
                                                  setStateSheet(() {
                                                    final updated = Map<
                                                      String,
                                                      dynamic
                                                    >.from(r);
                                                    // 🆕 نحدّث remaining_amount بدل total_amount
                                                    updated['remaining_amount'] =
                                                        remaining;
                                                    updated['paid_amount'] =
                                                        ((updated['paid_amount']
                                                                as double?) ??
                                                            0.0) +
                                                        amountToPay;
                                                    filteredRows[i] = updated;
                                                  });

                                                  if (!mounted) return;
                                                  AppToast.show(
                                                    '💰 تم دفع {v1} {v2}، المتبقي {v3} {v4}'
                                                        .tr({
                                                          'v1': amountToPay
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                          'v2': Money.txt,
                                                          'v3': remaining
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                          'v4': Money.txt,
                                                        }),
                                                  );
                                                  return;
                                                }

                                                // دفع كامل شحن الرصيد
                                                final double cost =
                                                    (items.first['total']
                                                            as num)
                                                        .toDouble();

                                                // 1️⃣ التوثيق الأول
                                                await db.insert(
                                                  'debt_payments',
                                                  {
                                                    'debt_id': debtId,
                                                    'amount': total,
                                                    'discount': 0,
                                                    'paid_at':
                                                        DateTime.now()
                                                            .toIso8601String(),
                                                    'customer_name': customer,
                                                    'invoice_id':
                                                        originalInvoiceId,
                                                    'shift_id': widget.shiftId,
                                                  },
                                                );

                                                // 2️⃣ باقي العمليات
                                                if (originalInvoiceId != null) {
                                                  await db.update(
                                                    'invoices',
                                                    {'payment_type': 'paid'},
                                                    where: 'id = ?',
                                                    whereArgs: [
                                                      originalInvoiceId,
                                                    ],
                                                  );
                                                }

                                                await DBHelper.recordTransaction(
                                                  cost: cost,
                                                  received: total,
                                                  shiftId: widget.shiftId,
                                                );

                                                await db
                                                    .insert('invoice_items', {
                                                      'invoice_id':
                                                          originalInvoiceId,
                                                      'drink_id': 0,
                                                      'drink_name': 'شحن رصيد',
                                                      'qty': 1,
                                                      'price': cost,
                                                      'total': total,
                                                    });

                                                await db.delete(
                                                  'debts',
                                                  where: 'id = ?',
                                                  whereArgs: [debtId],
                                                );
                                                await db.delete(
                                                  'debt_items',
                                                  where: 'debt_id = ?',
                                                  whereArgs: [debtId],
                                                );

                                                if (!mounted) return;
                                                setStateSheet(() {
                                                  filteredRows.removeAt(i);
                                                });

                                                if (!mounted) return;
                                                AppToast.show(
                                                  '✅ تم تسديد شحن الرصيد بالكامل'
                                                      .tr(),
                                                );
                                                return;
                                              }

                                              // ============================
                                              // الحالة العادية (غير شحن رصيد)
                                              // ============================

                                              // 1️⃣ التوثيق أولاً — قبل أي طباعة أو تعديل
                                              await db.insert('debt_payments', {
                                                'debt_id': debtId,
                                                'amount': amountToPay,
                                                'discount': discount,
                                                'paid_at':
                                                    DateTime.now()
                                                        .toIso8601String(),
                                                'customer_name': customer,
                                                'invoice_id': originalInvoiceId,
                                                'shift_id': widget.shiftId,
                                              });

                                              // 2️⃣ لو الدين خلص، نقفل الفاتورة ونمسح الدين
                                              //    (مبقاش فيه تحديث لـ total_amount هنا)
                                              if (remainingAmount <= 0) {
                                                if (originalInvoiceId != null) {
                                                  await db.update(
                                                    'invoices',
                                                    {'payment_type': 'paid'},
                                                    where: 'id = ?',
                                                    whereArgs: [
                                                      originalInvoiceId,
                                                    ],
                                                  );
                                                }
                                                await db.delete(
                                                  'debts',
                                                  where: 'id = ?',
                                                  whereArgs: [r['id']],
                                                );
                                              }

                                              if (!mounted) return;
                                              setStateSheet(() {
                                                if (remainingAmount <= 0) {
                                                  filteredRows.removeAt(i);
                                                } else {
                                                  final updatedRow =
                                                      Map<String, dynamic>.from(
                                                        r,
                                                      );
                                                  // 🆕 نحدّث remaining_amount بدل total_amount
                                                  updatedRow['remaining_amount'] =
                                                      remainingAmount;
                                                  updatedRow['paid_amount'] =
                                                      ((updatedRow['paid_amount']
                                                              as double?) ??
                                                          0.0) +
                                                      amountToPay;
                                                  filteredRows[i] = updatedRow;
                                                }
                                              });

                                              // 3️⃣ الطباعة آخر خطوة، وجوه try/catch
                                              //    عشان لو فشلت البيانات تبقى خلاص متسجلة صح
                                              if (shouldPrint) {
                                                // 🆕 الشرط ده بس
                                                try {
                                                  final rawDebtItems =
                                                      await DBHelper.getDebtItems(
                                                        debtId,
                                                      );
                                                  final debtItems =
                                                      rawDebtItems
                                                          .map<
                                                            Map<String, dynamic>
                                                          >(
                                                            (e) => Map<
                                                              String,
                                                              dynamic
                                                            >.from(e),
                                                          )
                                                          .toList();

                                                  await printDebtInvoice(
                                                    customer,
                                                    debtItems,
                                                    amountToPay,
                                                    discount,
                                                  );
                                                } catch (e) {
                                                  print(
                                                    '⚠️ فشلت الطباعة لكن الدفعة اتسجلت بنجاح: $e',
                                                  );
                                                }
                                              } // 🆕
                                              if (!mounted) return;
                                              AppToast.show(
                                                '✅ تم تحصيل دين {customer}، المدفوع: {v2} {v3}، الخصم: {v4} {v5}'
                                                    .tr({
                                                      'customer': customer,
                                                      'v2': amountToPay
                                                          .toStringAsFixed(2),
                                                      'v3': Money.txt,
                                                      'v4': discount
                                                          .toStringAsFixed(2),
                                                      'v5': Money.txt,
                                                    }),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        final items =
                                            await DBHelper.getDebtItems(
                                              (r['id'] as num).toInt(),
                                            );
                                        if (!mounted) return;
                                        // 🆕 المتبقي الحقيقي هنا كمان
                                        final total =
                                            (r['remaining_amount']
                                                as double?) ??
                                            0.0;
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => AppDialog(
                                                title: Text(
                                                  'تفاصيل دين {v1}'.tr({
                                                    'v1': customer,
                                                  }),
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'المبلغ المتبقي: {v1} {v2}'
                                                            .tr({
                                                              'v1': total
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                              'v2': Money.txt,
                                                            }),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text('تفاصيل:'.tr()),
                                                      ...items.map((it) {
                                                        final name =
                                                            it['drink_name'] ??
                                                            'غير معروف'.tr();
                                                        final qty =
                                                            it['qty'] ?? 0;
                                                        final price =
                                                            ((it['price'] ?? 0)
                                                                    as num)
                                                                .toDouble();
                                                        final t =
                                                            ((it['total'] ?? 0)
                                                                    as num)
                                                                .toDouble();
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 4.0,
                                                              ),
                                                          child: Text(
                                                            '$name x$qty — ${t.toStringAsFixed(2)} ${Money.txt}',
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: Text('إغلاق'.tr()),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  //تسجيل الدين القديم
  /*  Future<void> _showDebtorsSheet() async {
    final db = await DBHelper.database;

    */ /*   final rows = await db.rawQuery('''
    SELECT d.*,
           i.staff_name,
           i.id as invoice_id
    FROM debts d
    LEFT JOIN invoices i ON d.invoice_id = i.id
    WHERE i.staff_name = ?
    ORDER BY d.date DESC
  ''', [widget.staffName]);*/ /*
    final rows = await db.rawQuery('''
  SELECT d.*,
         i.staff_name,
         i.id as invoice_id
  FROM debts d
  LEFT JOIN invoices i ON d.invoice_id = i.id
  ORDER BY d.date DESC
''');

    List<Map<String, dynamic>> filteredRows = List.from(rows); // نسخة للتصفية

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              builder: (context, controller) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'الفلوس الاجله (لـ ${widget.staffName})',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      // 🔹 حقل البحث
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'بحث باسم العميل',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.blueGrey[700]),
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setStateSheet(() {
                            final query = val.toLowerCase();
                            filteredRows = rows.where((r) {
                              final customer =
                                  (r['customer_name'] ?? r['person_name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              return customer.contains(query);
                            }).toList();
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: filteredRows.isEmpty
                            ? Center(child: Text('لا توجد نتائج'))
                            : ListView.separated(
                                controller: controller,
                                itemCount: filteredRows.length,
                                separatorBuilder: (_, __) => Divider(),
                                itemBuilder: (context, i) {
                                  final r = filteredRows[i];
                                  final dateStr = r['date']?.toString();
                                  DateTime? dt;
                                  try {
                                    dt = dateStr != null
                                        ? DateTime.parse(dateStr)
                                        : null;
                                  } catch (_) {
                                    dt = null;
                                  }
                                  final dateText = dt != null
                                      ? DateFormat('yyyy-MM-dd HH:mm')
                                          .format(dt)
                                      : 'غير معروف';

                                  final total =
                                      ((r['total_amount'] ?? 0) as num)
                                          .toDouble();
                                  final customer = (r['customer_name'] ??
                                          r['person_name'] ??
                                          'غير معروف')
                                      .toString();

                                  return ListTile(
                                    title: Text(customer,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        'التاريخ: $dateText\nفاتورة: ${r['invoice_id'] ?? '—'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${total.toStringAsFixed(2)} ${Money.txt}',
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.print,
                                              color: Colors.blue),
                                          tooltip: 'طباعة الفاتورة',
                                          onPressed: () async {
                                            final r = filteredRows[i];
                                            final customer =
                                                (r['customer_name'] ??
                                                        r['person_name'] ??
                                                        'غير معروف')
                                                    .toString();

                                            final debtId =
                                                (r['id'] as num).toInt();
                                            final db = await DBHelper.database;

                                            // جلب العناصر
                                            final items = await db.query(
                                                'debt_items',
                                                where: 'debt_id = ?',
                                                whereArgs: [debtId]);
                                            final debtItems = items
                                                .map((e) =>
                                                    Map<String, dynamic>.from(
                                                        e))
                                                .toList();

                                            // جلب المدفوعات السابقة
                                            final payments = await db.query(
                                                'debt_payments',
                                                where: 'debt_id = ?',
                                                whereArgs: [debtId]);
                                            final totalPaid = payments.fold<
                                                    double>(
                                                0,
                                                (sum, p) =>
                                                    sum +
                                                    ((p['amount'] ?? 0) as num)
                                                        .toDouble());

                                            // إعداد تفاصيل الدين للطباعة
                                            final debtDetails =
                                                <Map<String, dynamic>>[
                                              {
                                                'date': r['date'],
                                                'items': debtItems,
                                                'total': ((r['total_amount'] ??
                                                        0) as num)
                                                    .toDouble(),
                                                'original':
                                                    ((r['original_amount'] ??
                                                            r['total_amount'] ??
                                                            0) as num)
                                                        .toDouble(),
                                                'paid': 0,
                                                'payments': payments
                                                    .map((p) => Map<String,
                                                        dynamic>.from(p))
                                                    .toList(),
                                              }
                                            ];

                                            await printDebtInvoice(
                                              customer,
                                              debtDetails,
                                              0,
                                              0, // لو عندك خصم
                                            );
                                          },
                                        ),
                                        SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.check_circle,
                                              color: Colors.green),
                                          tooltip: 'تحصيل الدين',
                                          onPressed: () async {
                                            final r =
                                                filteredRows[i]; // كل صف دين
                                            final customer =
                                                (r['customer_name'] ??
                                                        r['person_name'] ??
                                                        'غير معروف')
                                                    .toString();
                                            final total = ((r['total_amount'] ??
                                                    0) as num)
                                                .toDouble();
                                            final originalInvoiceId = r[
                                                'invoice_id']; // 🆕 خده من هنا قبل أي حذف

                                            double amountToPay = total;
                                            double discount = 0;

                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder: (context,
                                                      setDialogState) {
                                                    return AppDialog(
                                                      title: Text(
                                                          'تحصيل دين $customer'),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                              'إجمالي الدين: ${total.toStringAsFixed(2)} ${Money.txt}'),
                                                          SizedBox(height: 8),
                                                          TextField(
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'المبلغ المدفوع',
                                                              hintText: total
                                                                  .toStringAsFixed(
                                                                      2),
                                                            ),
                                                            onChanged: (v) {
                                                              setDialogState(
                                                                  () {
                                                                amountToPay =
                                                                    double.tryParse(
                                                                            v) ??
                                                                        total;
                                                                if (amountToPay >
                                                                    total)
                                                                  amountToPay =
                                                                      total;
                                                              });
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: Text('إلغاء'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child: Text('تحصيل'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );

                                            if (confirm != true) return;

                                            final db = await DBHelper.database;

                                            await DBHelper.addCashDrawerEntry(
                                                amountToPay, 'income', 'debt',
                                                cashier: widget.staffName);

                                            final remainingAmount =
                                                total - amountToPay - discount;
                                            final debtId =
                                                (r['id'] as num).toInt();

                                            final items = await db.query(
                                              'debt_items',
                                              where: 'debt_id = ?',
                                              whereArgs: [debtId],
                                            );

                                            final bool isRechargeOnly =
                                                items.length == 1 &&
                                                    items.first['drink_name'] ==
                                                        'شحن رصيد';

                                            // حالة خاصة: شحن رصيد فقط
                                            if (isRechargeOnly) {
                                              if (amountToPay < total) {
                                                // 💰 تسجيل دفعة جزئية فقط
                                                await db
                                                    .insert('debt_payments', {
                                                  'debt_id': debtId,
                                                  'amount': amountToPay,
                                                  'discount': 0,
                                                  'paid_at': DateTime.now()
                                                      .toIso8601String(),
                                                  'customer_name':
                                                      customer, // 🆕
                                                  'invoice_id':
                                                      originalInvoiceId, // 🆕
                                                });

                                                final remaining =
                                                    total - amountToPay;

                                                await db.update(
                                                  'debts',
                                                  {'total_amount': remaining},
                                                  where: 'id = ?',
                                                  whereArgs: [debtId],
                                                );

                                                setStateSheet(() {
                                                  final updated =
                                                      Map<String, dynamic>.from(
                                                          r);
                                                  updated['total_amount'] =
                                                      remaining;
                                                  filteredRows[i] = updated;
                                                });

                                                AppToast.show('💰 تم دفع ${amountToPay.toStringAsFixed(2)} ${Money.txt}، المتبقي ${remaining.toStringAsFixed(2)} ${Money.txt}',);

                                                return;
                                              }

                                              if (originalInvoiceId != null) {
                                                await db.update(
                                                  'invoices',
                                                  {'payment_type': 'paid'},
                                                  where: 'id = ?',
                                                  whereArgs: [
                                                    originalInvoiceId
                                                  ],
                                                );
                                              }

                                              final double cost =
                                                  (items.first['total'] as num)
                                                      .toDouble();

                                              await DBHelper.recordTransaction(
                                                cost: cost,
                                                received: total,
                                                shiftId: widget.shiftId,
                                              );

                                              await db.insert('invoice_items', {
                                                'invoice_id': originalInvoiceId,
                                                'drink_id': 0,
                                                'drink_name': 'شحن رصيد',
                                                'qty': 1,
                                                'price': cost,
                                                'total': total,
                                              });

                                              // ✅ حذف الدين
                                              await db.delete('debts',
                                                  where: 'id = ?',
                                                  whereArgs: [debtId]);
                                              await db.delete('debt_items',
                                                  where: 'debt_id = ?',
                                                  whereArgs: [debtId]);

                                              // ✅ توثيق الدفع
                                              await db.insert('debt_payments', {
                                                'debt_id': debtId,
                                                'amount': total,
                                                'discount': 0,
                                                'paid_at': DateTime.now()
                                                    .toIso8601String(),
                                                'customer_name': customer, // 🆕
                                                'invoice_id':
                                                    originalInvoiceId, // 🆕
                                              });

                                              setStateSheet(() {
                                                filteredRows.removeAt(i);
                                              });

                                              AppToast.show('✅ تم تسديد شحن الرصيد بالكامل');

                                              return;
                                            }

                                            // الحالة العادية (غير شحن رصيد)
                                            if (remainingAmount <= 0) {
                                              if (originalInvoiceId != null) {
                                                await db.update(
                                                  'invoices',
                                                  {'payment_type': 'paid'},
                                                  where: 'id = ?',
                                                  whereArgs: [
                                                    originalInvoiceId
                                                  ],
                                                );
                                              }

                                              await db.delete(
                                                'debts',
                                                where: 'id = ?',
                                                whereArgs: [r['id']],
                                              );
                                            } else {
                                              await db.update(
                                                'debts',
                                                {
                                                  'total_amount':
                                                      remainingAmount
                                                },
                                                where: 'id = ?',
                                                whereArgs: [r['id']],
                                              );
                                            }

                                            setStateSheet(() {
                                              if (remainingAmount <= 0) {
                                                filteredRows.removeAt(i);
                                              } else {
                                                final updatedRow =
                                                    Map<String, dynamic>.from(
                                                        r);
                                                updatedRow['total_amount'] =
                                                    remainingAmount;
                                                filteredRows[i] = updatedRow;
                                              }
                                            });

                                            final rawDebtItems =
                                                await DBHelper.getDebtItems(
                                                    (r['id'] as num).toInt());
                                            final debtItems = rawDebtItems
                                                .map<Map<String, dynamic>>(
                                                    (e) => Map<String,
                                                        dynamic>.from(e))
                                                .toList();

                                            await printDebtInvoice(
                                                customer,
                                                debtItems,
                                                amountToPay,
                                                discount);

                                            // 🔧 التوثيق الأخير - ده اللي كان ناقص منه الاسم والـ invoice_id
                                            await db.insert('debt_payments', {
                                              'debt_id': debtId,
                                              'amount': amountToPay,
                                              'discount': discount,
                                              'paid_at': DateTime.now()
                                                  .toIso8601String(),
                                              'customer_name': customer, // 🆕
                                              'invoice_id':
                                                  originalInvoiceId, // 🆕
                                            });

                                            AppToast.show('✅ تم تحصيل دين $customer، المدفوع: ${amountToPay.toStringAsFixed(2)} ${Money.txt}، الخصم: ${discount.toStringAsFixed(2)} ${Money.txt}',);
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      final items = await DBHelper.getDebtItems(
                                          (r['id'] as num).toInt());
                                      showDialog(
                                        context: context,
                                        builder: (_) => AppDialog(
                                          title: Text('تفاصيل دين ${customer}'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'المبلغ المتبقي: ${total.toStringAsFixed(2)} ${Money.txt}'),
                                                SizedBox(height: 8),
                                                Text('تفاصيل:'),
                                                ...items.map((it) {
                                                  final name =
                                                      it['drink_name'] ??
                                                          'غير معروف';
                                                  final qty = it['qty'] ?? 0;
                                                  final price = ((it['price'] ??
                                                          0) as num)
                                                      .toDouble();
                                                  final t = ((it['total'] ?? 0)
                                                          as num)
                                                      .toDouble();
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 4.0),
                                                    child: Text(
                                                        '$name x$qty — ${t.toStringAsFixed(2)} ${Money.txt}'),
                                                  );
                                                }).toList(),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('إغلاق')),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }*/

  Future<void> _startTakeaway() async {
    // 🔹 جلب العملاء السابقين
    final db = await DBHelper.database;
    final customers = await db.rawQuery('''
    SELECT DISTINCT customer_name 
    FROM invoices 
    WHERE customer_name IS NOT NULL AND customer_name != ''
    ORDER BY customer_name COLLATE NOCASE
  ''');

    String? selectedCustomer;
    final customerNameCtrl = TextEditingController();

    // نافذة اختيار العميل أو إدخاله
    final customerName = await showDialog<String>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AppDialog(
                  title: Text('اختر أو أضف عميل'.tr()),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCustomer,
                        isExpanded: true,
                        hint: Text('اختر عميل موجود'.tr()),
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text('بدون اسم'.tr()),
                          ),
                          ...customers.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['customer_name'] as String,
                              child: Text(c['customer_name'] as String),
                            );
                          }).toList(),
                        ],
                        onChanged:
                            (val) => setState(() => selectedCustomer = val),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: customerNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'أو أدخل عميل جديد'.tr(),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: Text('إلغاء'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = customerNameCtrl.text.trim();
                        Navigator.pop(
                          context,
                          name.isNotEmpty ? name : selectedCustomer,
                        );
                      },
                      child: Text('ابدأ'.tr()),
                    ),
                  ],
                ),
          ),
    );

    if (customerName == null) return;

    // إنشاء فاتورة جديدة بدون ربط ترابيزة
    final invoiceId = await DBHelper.createInvoice(
      0, // 0 لأن هذه فاتورة Takeaway
      DateTime.now().toIso8601String(),
      staffName: widget.staffName,
      shiftId: widget.shiftId,
      customerName: customerName.isEmpty ? null : customerName,
    );

    // فتح شاشة إضافة مشروبات مباشرة
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddDrinksScreen(invoiceId: invoiceId)),
    ).then((_) {
      // بعد إضافة المشروبات، يمكن إنهاء الفاتورة مباشرة

      _handleTakeawayPayment(invoiceId, customerName: customerName);
    });
  }

  Future<void> _handleTakeawayPayment(
    int invoiceId, {
    String? customerName,
  }) async {
    final drinksCost = await DBHelper.getDrinksCostForInvoice(invoiceId);
    double discount = 0.0;
    bool shouldPrint = false;
    final discountController = TextEditingController();

    Future<void> restoreInvoiceStock() async {
      final db = await DBHelper.database;

      final items = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      for (final item in items) {
        final drinkId = item['drink_id'] as int;
        final qty = item['qty'] as int;

        // رجوع المشروبات
        await db.rawUpdate(
          '''
        UPDATE drinks
        SET qty = qty + ?
        WHERE id = ?
        ''',
          [qty, drinkId],
        );

        // رجوع المواد الخام
        await DBHelper.restoreRecipe(drinkId, qty);
      }
    }

    final paymentChoice = await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AppDialog(
                  title: Text('خصم وطريقة الدفع للتيك أواي'.tr()),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'الخصم'.tr(),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            final double totalAmount = drinksCost;

                            double entered = double.tryParse(val) ?? 0.0;

                            if (entered > totalAmount) {
                              discountController.text = totalAmount
                                  .toStringAsFixed(2);

                              discount = totalAmount;

                              discountController
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: discountController.text.length,
                                ),
                              );
                            } else if (entered < 0) {
                              discount = 0;
                            } else {
                              discount = entered;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'الإجمالي بعد الخصم: {v1} ج'.tr({
                          'v1': (drinksCost - discount)
                              .clamp(0, double.infinity)
                              .toStringAsFixed(2),
                        }),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // 🆕 خيار الطباعة
                      CheckboxListTile(
                        value: shouldPrint,
                        onChanged: (val) {
                          setState(() {
                            shouldPrint = val ?? false;
                          });
                        },
                        title: Text('طباعة الفاتورة'.tr()),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  /*         actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'cancel');
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'debt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('على الحساب'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('دفع كامل'),
            ),
          ],*/
                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              foregroundColor: Colors.grey.shade700,
                            ),
                            onPressed: () => Navigator.pop(context, 'cancel'),
                            child: Text(
                              'إلغاء'.tr(),
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => Navigator.pop(context, 'debt'),
                            child: Text(
                              'على الحساب'.tr(),
                              style: TextStyle(fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => Navigator.pop(context, 'paid'),
                            child: Text(
                              'دفع كامل'.tr(),
                              style: TextStyle(fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
    );

    if (paymentChoice == null || paymentChoice == 'cancel') {
      await restoreInvoiceStock();

      await DBHelper.endInvoice(
        invoiceId,
        DateTime.now().toIso8601String(),
        0,
        0,
        discount: 0,
        addToCashDrawer: false,
        paymentType: 'ملغي'.tr(),
      );

      _load();
      return;
    }

    final db = await DBHelper.database;

    final totalAfterDiscount = (drinksCost - discount).clamp(
      0,
      double.infinity,
    );

    if (paymentChoice == 'debt') {
      String? debtCustomerName = customerName;

      // لو مفيش اسم، اسأل عنه
      if (debtCustomerName == null || debtCustomerName.isEmpty) {
        debtCustomerName = await showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            TextEditingController nameController = TextEditingController();
            bool isButtonEnabled = false;

            return StatefulBuilder(
              builder:
                  (context, setState) => AppDialog(
                    title: Text('تسجيل الدين'.tr()),
                    content: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم العميل'.tr(),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          isButtonEnabled = value.trim().isNotEmpty;
                        });
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: Text('إلغاء'.tr()),
                      ),
                      ElevatedButton(
                        onPressed:
                            isButtonEnabled
                                ? () => Navigator.pop(
                                  context,
                                  nameController.text.trim(),
                                )
                                : null,
                        child: Text('حفظ'.tr()),
                      ),
                    ],
                  ),
            );
          },
        );
      }

      if (debtCustomerName == null || debtCustomerName == 'cancel') {
        await restoreInvoiceStock();

        await DBHelper.endInvoice(
          invoiceId,
          DateTime.now().toIso8601String(),
          0,
          0,
          discount: 0,
          addToCashDrawer: false,
          paymentType: 'ملغي'.tr(),
        );

        _load();
        return;
      }

      await db.insert('debts', {
        'customer_name': debtCustomerName,
        'total_amount': totalAfterDiscount,
        'date': DateTime.now().toIso8601String(),
        'invoice_id': invoiceId,
        'shift_id': widget.shiftId,
      });

      final debtRecord = await db.query(
        'debts',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      final debtId = debtRecord.first['id'];

      final drinks = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      for (var d in drinks) {
        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': d['drink_name'],
          'qty': d['qty'],
          'price': d['price'],
          'total': d['total'],
        });
      }
      // 🆕 لو فيه خصم، سجّله كسطر منفصل عشان يفضل متسق مع total_amount
      // حتى لو حد عدّل الدين بعدين (شاشة تعديل الدين بتعامل سطور "خصم"
      // و"دفعة مقدمة" كـ locked/display-only، فمش بيتم حذفها أو تعديلها بالغلط)
      if (discount > 0) {
        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': 'خصم',
          'qty': 1,
          'price': -discount,
          'total': -discount,
        });
      }

      await DBHelper.endInvoice(
        invoiceId,
        DateTime.now().toIso8601String(),
        0,
        drinksCost,
        discount: discount,
        addToCashDrawer: false,
        paymentType: 'علي الحساب'.tr(),
        shiftId: widget.shiftId,
      );
      // 🆕 تصحيح تقسيم الأعمدة (مشروبات/سجاير/شيشة) + تطبيق الخصم على الإجمالي
      await DBHelper.updateInvoiceDrinksCost(invoiceId);
    } else if (paymentChoice == 'paid') {
      await DBHelper.endInvoice(
        invoiceId,
        DateTime.now().toIso8601String(),
        0,
        drinksCost,
        discount: discount,
        addToCashDrawer: true,
        paymentType: 'paid',
        shiftId: widget.shiftId,
      ); // 🆕 تصحيح تقسيم الأعمدة (مشروبات/سجاير/شيشة) + تطبيق الخصم على الإجمالي
      await DBHelper.updateInvoiceDrinksCost(invoiceId);
    }
    // 🆕 الطباعة بقت اختيارية حسب اختيار المستخدم
    if (shouldPrint) {
      try {
        await DrinksInvoicePrinter.printInvoice(invoiceId, discount: discount);
      } catch (e) {
        print('⚠️ فشلت الطباعة لكن العملية اتسجلت بنجاح: $e');
      }
    }

    _load();

    // 🆕 إشعار نهائي يوضح إن الأوردر اتسجل بنجاح
    if (mounted) {
      final message =
          paymentChoice == 'debt'
              ? '✅ تم تسجيل الأوردر على الحساب — الإجمالي: {v1} {v2}'.tr({
                'v1': totalAfterDiscount.toStringAsFixed(2),
                'v2': Money.txt,
              })
              : '✅ تم إنهاء الأوردر بنجاح — الإجمالي: ${totalAfterDiscount.toStringAsFixed(2)} ${Money.txt}';

      AppToast.show(message, kind: FeedbackKind.success);
    }
  }
  /*  Future<void> _handleTakeawayPayment(int invoiceId) async {
    final drinksCost = await DBHelper.getDrinksCostForInvoice(invoiceId);
    double discount = 0.0;
    final discountController = TextEditingController();

    final paymentChoice = await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: Text('خصم وطريقة الدفع للتيك أواي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الخصم',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      final double totalAmount = drinksCost;

                      double entered = double.tryParse(val) ?? 0.0;
                      // نجبر الخصم يكون بين 0 و total
                      if (entered > totalAmount) {
                        discountController.text = totalAmount
                            .toStringAsFixed(2); // نص الخصم يبقى مساوي للإجمالي
                        discount = totalAmount;
                        discountController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: discountController.text.length),
                        );
                      } else if (entered < 0) {
                        discount = 0;
                      } else {
                        discount = entered;
                      }
                    });
                  }),
              SizedBox(height: 10),
              Text(
                'الإجمالي بعد الخصم: ${(drinksCost - discount).clamp(0, double.infinity).toStringAsFixed(2)} ج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final db = await DBHelper.database;

                final items = await db.query(
                  'invoice_items',
                  where: 'invoice_id = ?',
                  whereArgs: [invoiceId],
                );

                for (final item in items) {
                  final drinkId = item['drink_id'] as int;
                  final qty = item['qty'] as int;

                  // رجوع مخزون المشروب
                  await db.rawUpdate(
                    '''
        UPDATE drinks
        SET qty = qty + ?
        WHERE id = ?
        ''',
                    [qty, drinkId],
                  );

                  // رجوع المواد الخام
                  await DBHelper.restoreRecipe(
                    drinkId,
                    qty,
                  );
                }

                Navigator.pop(context, 'cancel');
              },
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'debt'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('على الحساب'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'paid'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('دفع كامل'),
            ),
          ],
        ),
      ),
    );

    if (paymentChoice == null || paymentChoice == 'cancel') {
      // غلق الفاتورة مباشرة بدون أي تكلفة
      await DBHelper.endInvoice(
        invoiceId,
        DateTime.now().toIso8601String(),
        0, // deviceCost
        0, // drinksCost
        discount: 0,
        addToCashDrawer: false,
        paymentType: 'ملغي', // علامة لإلغاء الفاتورة
      );
      _load(); // إعادة تحميل الفواتير
      return;
    }

    final db = await DBHelper.database;
    final totalAfterDiscount =
        (drinksCost - discount).clamp(0, double.infinity);

    if (paymentChoice == 'debt') {
      final customerName = await showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          TextEditingController nameController = TextEditingController();
          bool isButtonEnabled = false;

          return StatefulBuilder(
            builder: (context, setState) => AppDialog(
              title: Text('تسجيل الدين'),
              content: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم العميل',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    isButtonEnabled = value.trim().isNotEmpty;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () => Navigator.pop(context, nameController.text)
                      : null, // غير مفعل إذا كان فارغ
                  child: Text('حفظ'),
                ),
              ],
            ),
          );
        },
      );
      if (customerName == null || customerName == 'cancel') {
        // غلق الفاتورة مباشرة بدون أي تكلفة
        await DBHelper.endInvoice(
          invoiceId,
          DateTime.now().toIso8601String(),
          0, // deviceCost
          0, // drinksCost
          discount: 0,
          addToCashDrawer: false,
          paymentType: 'ملغي', // علامة لإلغاء الفاتورة
        );
        _load(); // إعادة تحميل الفواتير
        return;
      }

      if (customerName == null || customerName.isEmpty) return;

      await db.insert('debts', {
        'customer_name': customerName,
        'total_amount': totalAfterDiscount,
        'date': DateTime.now().toIso8601String(),
        'invoice_id': invoiceId,
      });
      final debtRecord = await db.query(
        'debts',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      final debtId = debtRecord.first['id'];

// نقل المشروبات إلى debt_items
      final drinks = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      print('About to fetch drinks for invoice $invoiceId');

      print('Drinks fetched for invoice $invoiceId: ${drinks.length}');
      for (var d in drinks) {
        print(d);
      }

      for (var d in drinks) {
        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': d['drink_name'],
          'qty': d['qty'],
          'price': d['price'],
          'total': d['total'],
        });
      }
      final insertedItems = await db
          .query('debt_items', where: 'debt_id = ?', whereArgs: [debtId]);
      print('Inserted items for debt $debtId: ${insertedItems.length}');
      debugPrint('Inserted items for debt $debtId: ${insertedItems.length}');

      await DBHelper.endInvoice(
        invoiceId,
        DateTime.now().toIso8601String(),
        0,
        discount: discount,
        drinksCost,
        addToCashDrawer: false,
        paymentType: 'علي الحساب',
      );
    } else if (paymentChoice == 'paid') {
      await DBHelper.endInvoice(
        invoiceId,
        DateTime.now().toIso8601String(),
        0,
        discount: discount,
        drinksCost,
        addToCashDrawer: true,
        paymentType: 'paid',
      );
    }

    await DrinksInvoicePrinter.printInvoice(invoiceId, discount: discount);
  }*/

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
