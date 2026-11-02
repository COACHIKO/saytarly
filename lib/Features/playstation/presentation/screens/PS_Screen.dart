import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/Features/cashier/presentation/screens/DrinksInvoiceScreen.dart';
import 'package:saytarly/Features/cashier/presentation/screens/add_drinks.dart';
import 'package:saytarly/Features/cashier/presentation/screens/invoice_screen.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:saytarly/Features/playstation/presentation/print/PlaystationInvoicePrinter.dart';
import 'package:saytarly/core/widgets/BACKGROUND.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/ps_screen_mobile_body.dart';
part 'desktop/ps_screen_windows_body.dart';

class PsScreen extends StatefulWidget {
  final String staffName;
  final int shiftId;
  const PsScreen({Key? key, required this.staffName, required this.shiftId})
    : super(key: key);

  @override
  State<PsScreen> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<PsScreen> {
  List<ConsoleModel> consoles = [];
  List<Map<String, dynamic>> activeInvoices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cs = await DBHelper.getAllConsoles();
    final inv = await DBHelper.getActiveInvoices();
    if (!mounted) return;
    setState(() {
      consoles = cs.map((r) => ConsoleModel.fromMap(r)).toList();
      activeInvoices = inv;
    });
  }

  Future<void> _startSession(ConsoleModel c) async {
    final db = await DBHelper.database;

    // 🔹 جلب العملاء المسجلين مسبقاً
    final customers = await db.rawQuery('''
    SELECT DISTINCT customer_name 
    FROM invoices 
    WHERE customer_name IS NOT NULL AND customer_name != ''
    ORDER BY customer_name COLLATE NOCASE
  ''');

    String? selectedCustomer;
    final nameController = TextEditingController();

    if (!mounted) return; // الشاشة قفلت أثناء جلب العملاء — ما نلمس contextش
    // 🔹 عرض نافذة الاختيار
    final result = await showDialog<String>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AppDialog(
                  title: Text('بدء جلسة جديدة'.tr()),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCustomer,
                        isExpanded: true,
                        hint: Text('اختر عميل موجود'.tr()),
                        items:
                            customers
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c['customer_name'] as String,
                                    child: Text(c['customer_name'] as String),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => selectedCustomer = val),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'أو أضف عميل جديد'.tr(),
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
                        final name = nameController.text.trim();
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

    if (result == null || result.isEmpty) return;

    final now = DateTime.now().toIso8601String();

    // ✅ إنشاء الفاتورة مع حفظ اسم العميل (سواء مختار أو جديد)
    await DBHelper.createInvoice(
      c.id!,
      now,
      staffName: widget.staffName,
      customerName: result,
      shiftId: widget.shiftId,
      isFixedPrice: c.isFixedPrice,
      fixedPrice: c.fixedPrice,
    );

    await _load();
  }

  /// ✅ بيحسب إجمالي ثواني التوقف "في الذاكرة بس" — من غير ما يكتب أي حاجة
  /// في قاعدة البيانات. لو الفاتورة لسه واقفة (paused_at != null) بيضيف
  /// المدة من وقت الإيقاف لحد دلوقتي كـ"توقف مؤقت افتراضي" للحساب بس.
  /// السبب: لو كتبنا الاستئناف في القاعدة بمجرد ما حد يدوس "إنهاء"، وبعدين
  /// اتلغت شاشة الدفع، هتفضل القاعدة فاكرة إن الجلسة "شغالة" فعليًا رغم إن
  /// الجهاز لسه واقف عندك، فالوقت اللي بعد كده هيتحسب غلط كوقت تشغيل.
  int _calcTotalPausedSeconds(Map<String, dynamic> invoice) {
    final storedPaused = (invoice['total_paused_seconds'] ?? 0) as int;
    final pausedAtRaw = invoice['paused_at'];
    if (pausedAtRaw == null) return storedPaused;

    final pausedTime = DateTime.parse(pausedAtRaw as String);
    final liveExtra = DateTime.now().difference(pausedTime).inSeconds;
    return storedPaused + liveExtra;
  }

  Future<void> _endSession(Map<String, dynamic> invoice, ConsoleModel c) async {
    final wasPaused = invoice['paused_at'] != null;

    final end = DateTime.now();
    final start = DateTime.parse(invoice['start_time']);
    // ✅ نحسب وقت التوقف كامل (المخزّن + الحالي لو لسه واقف) من غير ما نلمس
    // القاعدة، عشان لو المستخدم لغى شاشة الدفع تفضل الجلسة واقفة زي ما هي
    final totalPaused = _calcTotalPausedSeconds(invoice);
    final rawSeconds = end.difference(start).inSeconds;
    final effectiveSeconds = rawSeconds - totalPaused;
    final hours = effectiveSeconds ~/ 3600; // عدد الساعات الكاملة
    final minutes = (effectiveSeconds % 3600) ~/ 60; // عدد الدقائق المتبقية

    String displayDuration =
        c.fixedPrice != null ? 'Match' : '${hours} ساعة و ${minutes} دقيقة';

    final duration = effectiveSeconds / 3600.0;

    final deviceCost =
        (c.fixedPrice != null && c.fixedPrice! > 0)
            ? c.fixedPrice!
            : duration * c.pricePerHour;

    final drinksCost = await DBHelper.getDrinksCostForInvoice(
      invoice['id'] as int,
    );
    final total = deviceCost + drinksCost;
    double discount = 0.0;

    final discountController = TextEditingController();

    double totalAfterDiscount(double discount) =>
        (drinksCost + deviceCost - discount).clamp(0, double.infinity);

    final db = await DBHelper.database;

    // ✅ تحقق إذا كان العنصر موجود مسبقًا قبل الإضافة
    final existing = await db.query(
      'invoice_items',
      where: 'invoice_id = ? AND item_type = ?',
      whereArgs: [invoice['id'], 'playstation'],
    );
    final playstationName =
        c.fixedPrice != null
            ? 'Playstation Match'
            : 'Playstation ${duration.toStringAsFixed(2)} ساعة';

    if (existing.isEmpty && c.fixedPrice == null) {
      await db.insert('invoice_items', {
        'invoice_id': invoice['id'],
        'drink_id': null,
        'drink_name': playstationName,
        'hours': duration,
        'qty': 1,
        'price': deviceCost,
        'total': deviceCost,
        'item_type': 'playstation',
      });
    }

    // اختيار طريقة الدفع
    if (!mounted) return null; // الشاشة قفلت أثناء الجلسة — ما نلمس contextش
    final paymentChoice = await showDialog<String>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AppDialog(
                  title: Text('اختيار طريقة الدفع'.tr()),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            double entered = double.tryParse(val) ?? 0.0;
                            // نجبر الخصم يكون بين 0 و total
                            if (entered > total) {
                              discountController.text = total.toStringAsFixed(
                                2,
                              ); // نص الخصم يبقى مساوي للإجمالي
                              discount = total;
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
                      SizedBox(height: 10),
                      Text(
                        'الإجمالي بعد الخصم: {v1} ج'.tr({
                          'v1': totalAfterDiscount(discount).toStringAsFixed(2),
                        }),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  /*
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text('إلغاء')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, 'debt'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('على الحساب')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, 'paid'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('دفع كامل')),
          ],*/
                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
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

    if (paymentChoice == null || paymentChoice == 'cancel') return;

    if (paymentChoice == 'debt') {
      final nameController = TextEditingController();
      String? selectedCustomer;

      final customerName = await showDialog<String>(
        context: context,
        builder:
            (_) => AppDialog(
              title: Text('تسجيل الدين'.tr()),
              content: FutureBuilder<List<String>>(
                future: DBHelper.getDebtorsNames(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final names = snapshot.data!;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'عميل جديد'.tr(),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_add),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Autocomplete<String>(
                        optionsBuilder: (value) {
                          if (value.text.isEmpty) {
                            return names;
                          }

                          return names.where(
                            (n) => n.toLowerCase().contains(
                              value.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (value) {
                          selectedCustomer = value;
                        },
                        fieldViewBuilder: (
                          context,
                          textCtrl,
                          focusNode,
                          onSubmit,
                        ) {
                          return TextField(
                            controller: textCtrl,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'بحث عن عميل موجود'.tr(),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    final result =
                        nameController.text.trim().isNotEmpty
                            ? nameController.text.trim()
                            : selectedCustomer;

                    Navigator.pop(context, result);
                  },
                  child: Text('حفظ'.tr()),
                ),
              ],
            ),
      );
      if (customerName == null || customerName.isEmpty) return;

      // ⬅️ كمل تسجيل الدين هنا

      final debtId = await db.insert('debts', {
        'customer_name': customerName,
        'total_amount': totalAfterDiscount(discount),
        'date': DateTime.now().toIso8601String(),
        'invoice_id': invoice['id'],
        'shift_id': widget.shiftId,
      });

      final items = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice['id']],
      );
      for (var item in items) {
        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': item['drink_name'],
          'qty': item['qty'],
          'price': item['price'],
          'total': item['total'],
        });
      }
      if (c.fixedPrice != null) {
        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': playstationName,
          'qty': 1,
          'price': deviceCost,
          'total': deviceCost,
        });
      }
      // 🆕 لو فيه خصم، سجّله كسطر منفصل عشان يفضل متسق مع total_amount
      // حتى لو حد عدّل الدين بعدين (زي شاشة تعديل الدين اللي بتعامل
      // سطور "خصم" و"دفعة مقدمة" كـ locked/display-only)
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
        invoice['id'] as int,
        end.toIso8601String(),
        deviceCost,
        drinksCost,
        discount: discount,
        addToCashDrawer: false,
        paymentType: 'علي الحساب'.tr(),
        shiftId: widget.shiftId,
      ); // 🆕 تصحيح تقسيم الأعمدة (مشروبات/سجاير/شيشة) + تطبيق الخصم على الإجمالي
      await DBHelper.updateInvoiceDrinksCost(invoice['id'] as int);
    } else if (paymentChoice == 'paid') {
      await DBHelper.endInvoice(
        invoice['id'] as int,
        end.toIso8601String(),
        deviceCost,
        drinksCost,
        discount: discount,
        addToCashDrawer: true,
        paymentType: 'paid',
        shiftId: widget.shiftId,
      );
      await DBHelper.updateInvoiceDrinksCost(invoice['id'] as int);
    }

    await _load();

    if (!mounted) return; // الشاشة قفلت بعد القفل — ما نفتحش دايلوج على State ميت
    // عرض شاشة الفاتورة النهائية
    showDialog(
      context: context,
      builder:
          (dialogContext) => AppDialog(
            title: Text('الفاتورة النهائية'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الجهاز: {v1}'.tr({'v1': c.name})),
                Text(
                  'وقت الاستخدام: {displayDuration}'.tr({
                    'displayDuration': displayDuration,
                  }),
                ),
                Text(
                  'تكلفة الجهاز: {v1}'.tr({
                    'v1': deviceCost.toStringAsFixed(2),
                  }),
                ),
                Text(
                  'تكلفة المشروبات: {v1}'.tr({
                    'v1': drinksCost.toStringAsFixed(2),
                  }),
                ),
                Text('الخصم: {v1}'.tr({'v1': discount.toStringAsFixed(2)})),
                Divider(),
                Text(
                  'الإجمالي: {v1}'.tr({
                    'v1': totalAfterDiscount(discount).toStringAsFixed(2),
                  }),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('حسناً'.tr()),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // 🧃 جلب المشروبات من قاعدة البيانات
                  final drinks = await DBHelper.database.then((db) async {
                    final list = await db.rawQuery(
                      ''' SELECT d.name, d.name_en, ii.qty, ii.total FROM invoice_items ii LEFT JOIN drinks d ON d.id = ii.drink_id WHERE ii.invoice_id = ? ''',
                      [invoice['id']],
                    );
                    return list.map((e) {
                      final display = DrinkModel.displayNameFromMap(e);
                      return {
                        'name':
                            display.isNotEmpty
                                ? display
                                : (e['name'] ?? 'بلاستيشن'.tr()),
                        'qty': e['qty'] ?? 1,
                        'total': e['total'] ?? 0.0,
                      };
                    }).toList();
                  }); // 🖨️ طباعة الفاتورة
                  await PlaystationInvoicePrinter.printSession(
                    staffName: widget.staffName,
                    consoleName: c.name,
                    duration: duration,
                    discount: discount,
                    deviceCost: deviceCost,
                    drinksCost: drinksCost,
                    total: total,
                    drinks: drinks,
                  );
                },
                child: Text('طباعة'.tr()),
              ),
            ],
          ),
    );
  }

  Future<void> _printInvoice({
    required Map<String, dynamic> invoice,
    required ConsoleModel console,
    required double duration,
    required double deviceCost,
    required double drinksCost,
    required double total,
  }) async {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat(
      75 * PdfPageFormat.mm,
      150 * PdfPageFormat.mm,
      marginAll: 3 * PdfPageFormat.mm,
    );
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'فاتورة الجلسة'.tr(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '📅 التاريخ: {v1}'.tr({
                    'v1': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  }),
                ),
                pw.Text('👤 الموظف: {v1}'.tr({'v1': widget.staffName})),
                pw.Divider(),
                pw.Text('🎮 الجهاز: {v1}'.tr({'v1': console.name})),
                pw.Text(
                  '⏱ مدة الجلسة: {v1} ساعة'.tr({
                    'v1': duration.toStringAsFixed(2),
                  }),
                ),
                pw.Text(
                  '💰 تكلفة الجهاز: {v1}'.tr({
                    'v1': deviceCost.toStringAsFixed(2),
                  }),
                ),
                pw.Text(
                  '🥤 تكلفة المشروبات: {v1}'.tr({
                    'v1': drinksCost.toStringAsFixed(2),
                  }),
                ),
                pw.Divider(),
                pw.Text(
                  'الإجمالي: {v1}'.tr({'v1': total.toStringAsFixed(2)}),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // عرض واجهة الطباعة
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Map<int, Map<String, dynamic>> _activeMap() {
    final m = <int, Map<String, dynamic>>{};
    for (final inv in activeInvoices) {
      m[inv['console_id'] as int] = inv;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
