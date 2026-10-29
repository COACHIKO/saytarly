import 'package:saytarly/Features/debts/presentation/print/debts_print.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/Features/debts/presentation/print/invoice_debet_print.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/debts_screen_mobile_body.dart';
part 'desktop/debts_screen_windows_body.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({Key? key}) : super(key: key);

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Map<String, dynamic>> debts = [];
  List<Map<String, dynamic>> filteredDebts = [];
  final formatter = NumberFormat('#,##0.00');
  String searchQuery = '';
  bool _isLoadingDebts = true;
  // 🆕 تقريب أي مبلغ فلوس لأقرب قرش (خانتين عشريتين) عشان نمنع
  // تراكم كسور الـ floating point زي 4.999999999
  double _roundMoney(double v) => double.parse(v.toStringAsFixed(2));
  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  // 🆕 يحسب إجمالي المدفوع فعليًا لدين واحد من جدول debt_payments
  // (total_amount بقت ثابتة دايمًا، فده هو المصدر الوحيد للمدفوع)
  // 🔧 مصلّح: بنجمع amount + discount مع بعض، لأن الخصم كان بيتجاهل
  // تمامًا من حساب "المدفوع"، فكان المتبقي بيفضل يظهر كامل حتى لو
  // اتعمل خصم يغطي كل الدين أو جزء منه.
  Future<double> _getDebtPaidTotal(int debtId) async {
    final db = await DBHelper.database;
    final res = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) + COALESCE(SUM(discount),0) as s '
      'FROM debt_payments WHERE debt_id = ?',
      [debtId],
    );
    return (res.first['s'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _exportBackup() async {
    final db = await DBHelper.database;

    final debts = await db.query('debts');
    final items = await db.query('debt_items');
    final payments = await db.query('debt_payments');

    final backup = {
      "debts": debts,
      "debt_items": items,
      "debt_payments": payments,
      "created_at": DateTime.now().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    // 👇 اختيار مكان الحفظ
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ نسخة احتياطية'.tr(),
      fileName: 'backup_debts.json',
    );

    if (outputPath == null) return;

    if (!outputPath.toLowerCase().endsWith('.json')) {
      outputPath = '$outputPath.json';
    }

    final file = File(outputPath);
    await file.writeAsString(jsonString);

    if (outputPath == null) return; // المستخدم لغى

    if (context.mounted) {
      AppToast.show('تم حفظ النسخة بنجاح 📁'.tr());
    }
  }

  Future<void> _restoreBackup() async {
    final db = await DBHelper.database;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      await db.transaction((txn) async {
        await txn.delete('debt_payments');
        await txn.delete('debt_items');
        await txn.delete('debts');

        // =========================
        // debts
        // =========================
        for (final d in data['debts']) {
          final row = Map<String, dynamic>.from(d);

          await txn.insert('debts', {
            'id': row['id'],
            'customer_name': row['customer_name'],
            'total_amount':
                (row['total_amount'] as num?)?.toDouble() ??
                double.tryParse('${row['total_amount']}') ??
                0.0,
            'date': row['date'],
            'invoice_id': row['invoice_id'],
            'type': row['type'],
            'shift_id': row['shift_id'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // =========================
        // debt_items
        // =========================
        for (final i in data['debt_items']) {
          final row = Map<String, dynamic>.from(i);

          await txn.insert('debt_items', {
            'id': row['id'],
            'debt_id': row['debt_id'],
            'drink_name': row['drink_name'],
            'qty': row['qty'],
            'price':
                (row['price'] as num?)?.toDouble() ??
                double.tryParse('${row['price']}') ??
                0.0,
            'total':
                (row['total'] as num?)?.toDouble() ??
                double.tryParse('${row['total']}') ??
                0.0,
            'drink_id': row['drink_id'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // =========================
        // debt_payments
        // =========================
        for (final p in data['debt_payments']) {
          final row = Map<String, dynamic>.from(p);

          await txn.insert('debt_payments', {
            'id': row['id'],
            'debt_id': row['debt_id'],
            'amount':
                (row['amount'] as num?)?.toDouble() ??
                double.tryParse('${row['amount']}') ??
                0.0,
            'paid_at': row['paid_at'],
            'discount':
                (row['discount'] as num?)?.toDouble() ??
                double.tryParse('${row['discount']}') ??
                0.0,
            'customer_name': row['customer_name'],
            'invoice_id': row['invoice_id'],
            'shift_id': row['shift_id'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      await _loadDebts();

      if (mounted) {
        AppToast.show('تم استعادة النسخة بنجاح 📥'.tr());
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());

      if (mounted) {
        AppToast.show('خطأ في الاستعادة: {e}'.tr({'e': e}));
      }
    }
  }

  // 🆕 كل دين بنحسب متبقيه الحقيقي = total_amount (ثابتة) - مجموع دفعاته
  // (كاش + خصم مع بعض عن طريق _getDebtPaidTotal المصلّحة)
  Future<void> _loadDebts() async {
    if (!mounted) return;
    setState(() => _isLoadingDebts = true); // 🆕

    final data = await DBHelper.getAllDebts();

    final Map<String, Map<String, dynamic>> grouped = {};
    for (var d in data) {
      final name = d['customer_name'] ?? 'غير معروف'.tr();
      final debtId = (d['id'] as num).toInt();
      final totalAmount = ((d['total_amount'] ?? 0) as num).toDouble();

      final paid = await _getDebtPaidTotal(debtId);
      final remaining = (totalAmount - paid)
          .clamp(0, double.infinity)
          .toDouble();

      if (!grouped.containsKey(name)) {
        grouped[name] = {
          'customer_name': name,
          'remaining_amount': remaining, // 🆕 بدل total_amount
          'ids': [d['id']],
          'date': d['date'],
        };
      } else {
        grouped[name]!['remaining_amount'] =
            (grouped[name]!['remaining_amount'] as double) + remaining;
        grouped[name]!['ids'].add(d['id']);
      }
    }

    if (!mounted) return;
    setState(() {
      debts = grouped.values.toList();
      filteredDebts = debts;
      _isLoadingDebts = false; // 🆕
    });
  }

  void _filterDebts(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredDebts = debts;
      } else {
        filteredDebts = debts
            .where(
              (d) => (d['customer_name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _deleteDebt(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: Text('تأكيد الحذف'.tr()),
        content: Text('هل أنت متأكد من حذف هذا الدين؟'.tr()),
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
      final db = await DBHelper.database;
      await db.delete('debts', where: 'id = ?', whereArgs: [id]);
      await db.delete('debt_items', where: 'debt_id = ?', whereArgs: [id]);
      _loadDebts();
    }
  }

  void _showDebtDetails(
    List<int> debtIds,
    String personName,
    double totalDebtTotal,
  ) async {
    final db = await DBHelper.database;
    List<Map<String, dynamic>> allDetails = [];

    for (var id in debtIds) {
      final debt = await db.query('debts', where: 'id = ?', whereArgs: [id]);
      if (debt.isEmpty) continue;

      final row = debt.first;

      final date = DateTime.tryParse(row['date'].toString());
      final formattedDate = date != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(date)
          : 'غير محدد';

      // 🆕 total_amount بقت ثابتة (الإجمالي الأصلي)، والمدفوع بيتحسب
      // من debt_payments مش من الفرق بين original_amount و total_amount
      final totalAmount = ((row['total_amount'] ?? 0) as num).toDouble();

      final items = await db.query(
        'debt_items',
        where: 'debt_id = ?',
        whereArgs: [id],
      );
      final payments = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [id],
        orderBy: 'paid_at ASC',
      );

      final double paidAmount = payments.fold<double>(
        0.0,
        (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
      );
      // 🆕 مجموع الخصم على الدين ده، عشان نطرحه هو كمان من المتبقي
      final double discountAmount = payments.fold<double>(
        0.0,
        (sum, p) => sum + ((p['discount'] ?? 0) as num).toDouble(),
      );
      // 🔧 مصلّح: كانت بتطرح amount بس، فالخصم مكانش بيتحسب في المتبقي
      final double remaining = (totalAmount - paidAmount - discountAmount)
          .clamp(0, double.infinity)
          .toDouble();

      allDetails.add({
        'id': id,
        'date': formattedDate,
        'items': items,
        'total': remaining, // 🆕 المتبقي الحقيقي (بعد الكاش والخصم مع بعض)
        'original': totalAmount, // 🆕 الإجمالي الثابت
        'paid': paidAmount, // الكاش الفعلي بس (للعرض في "💵 مدفوع")
        'discount': discountAmount, // 🆕 إجمالي الخصم (للعرض لو حبينا)
        'payments': payments,
      });
    }

    // رتب الفواتير من الأحدث للأقدم
    allDetails.sort((a, b) => b['date'].compareTo(a['date']));

    if (allDetails.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AppDialog(
          title: Text('تفاصيل ديون {personName}'.tr({'personName': personName})),
          content: Text('لا توجد مشروبات مسجلة'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    // 🧾 عرض التفاصيل في BottomSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'تفاصيل الاجل {personName}'.tr({'personName': personName}),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: allDetails.length,
                    itemBuilder: (_, i) {
                      final section = allDetails[i];
                      final debtDate =
                          DateTime.tryParse(section['date'] ?? '') ??
                          DateTime.now();
                      final formattedDate = DateFormat(
                        'EEEE, yyyy-MM-dd',
                        'ar',
                      ).format(debtDate);
                      final formattedTime = DateFormat(
                        'HH:mm',
                        'ar',
                      ).format(debtDate);

                      final dateText =
                          'فاتورة بتاريخ {formattedDate} الساعة {formattedTime}'.tr({'formattedDate': formattedDate, 'formattedTime': formattedTime});

                      final items =
                          section['items'] as List<Map<String, dynamic>>;
                      final paid = section['paid'] as double;
                      final remaining = section['total'] as double;
                      final payments =
                          section['payments'] as List<Map<String, dynamic>>;
                      print('Items for debt ${section['id']}: $items');

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🧾 $dateText',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.teal[800],
                                ),
                              ),
                              SizedBox(height: 6),
                              ...items.map((item) {
                                final drinkName =
                                    item['drink_name'] ?? 'غير معروف'.tr();
                                final qty = item['qty'] ?? 0;
                                final price = (item['price'] ?? 0).toDouble();
                                final total = (item['total'] ?? 0).toDouble();

                                print('Items: $items');

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$drinkName x$qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Text('${formatter.format(price)} ${Money.txt}'),
                                      Text(
                                        'الإجمالي: {v1}'.tr({'v1': formatter.format(total)}),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              ...payments.map((p) {
                                final paidAmount = (p['amount'] as num)
                                    .toDouble();
                                final discountAmount = (p['discount'] ?? 0)
                                    .toDouble();

                                final paidDate =
                                    DateTime.tryParse(p['paid_at'] ?? '') ??
                                    DateTime.now();
                                final formattedDate = DateFormat(
                                  'EEEE, yyyy-MM-dd HH:mm',
                                  'ar',
                                ).format(paidDate);

                                String paymentText =
                                    '💵 دفع  {v1}'.tr({'v1': formatter.format(paidAmount)});
                                if (discountAmount > 0) {
                                  paymentText +=
                                      ' + خصم {v1}'.tr({'v1': formatter.format(discountAmount)});
                                }
                                paymentText += ' بتاريخ {formattedDate}'.tr({'formattedDate': formattedDate});

                                return Text(
                                  '$paymentText',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                              Divider(),
                              // 💰 المبلغ المدفوع والمتبقي
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (paid > 0)
                                    Text(
                                      '💵 مدفوع: {v1} {v2}'.tr({'v1': formatter.format(paid), 'v2': Money.txt}),
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  Text(
                                    '💰 المتبقي: {v1} {v2}'.tr({'v1': formatter.format(remaining), 'v2': Money.txt}),
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(),
                // 💸 زر الدفع
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ElevatedButton.icon(
                    label: Text(
                      ' دفع الدين ({v1} {v2})'.tr({'v1': formatter.format(totalDebtTotal), 'v2': Money.txt}),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _showPayDialog(personName, totalDebtTotal, debtIds),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool isLoading = false;

  // 🆕 هيلبر مشترك: بيحدّث بيانات الفاتورة (discount + total_cost) عشان
  // تعكس إجمالي خصم الدين الحقيقي (دفعات سابقة + الدفعة الحالية) بدل
  // ما تفضل الفاتورة عارضة السعر الكامل وكأن مفيش خصم اتعمل خالص.
  Future<void> _updateInvoiceAfterDebtClosed({
    required int invoiceId,
    required List<Map<String, dynamic>> previousPayments,
    required double discountForRow,
  }) async {
    final db = await DBHelper.database;

    final invRows = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );

    if (invRows.isEmpty) {
      await db.update(
        'invoices',
        {'payment_type': 'paid'},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      return;
    }

    final invRow = invRows.first;
    final deviceCost = ((invRow['device_cost'] ?? 0) as num).toDouble();
    final drinksCost = ((invRow['drinks_cost'] ?? 0) as num).toDouble();
    final oldDiscount = ((invRow['discount'] ?? 0) as num).toDouble();

    // 🆕 نجمع خصومات كل الدفعات (السابقة + الدفعة الحالية اللي قفلت الدين)
    // مش بس خصم آخر دفعة، عشان لو الدين اتقفل على أكتر من دفعة جزئية
    final previousDiscountTotal = previousPayments.fold<double>(
      0.0,
      (sum, p) => sum + ((p['discount'] ?? 0) as num).toDouble(),
    );
    final totalDebtDiscount = previousDiscountTotal + discountForRow;

    final newDiscount = oldDiscount + totalDebtDiscount;
    final newTotal = (deviceCost + drinksCost - newDiscount).clamp(
      0,
      double.infinity,
    );

    await db.update(
      'invoices',
      {
        'payment_type': 'paid',
        'discount': newDiscount, // 🆕
        'total_cost': newTotal, // 🆕 عشان يعرض/يطبع صح بعد الخصم
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  void _showPayDialog(String name, double total, List<int> ids) async {
    final screenContext = context; // ✅ context ثابت بتاع الشاشة نفسها
    final controller = TextEditingController();
    final discountController = TextEditingController();
    double discount = 0.0;

    bool isSaving = false;

    showDialog(
      context: screenContext,
      builder: (dialogOuterContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AppDialog(
          title: Text('تسديد دين {name}'.tr({'name': name})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إجمالي الدين: {v1} {v2}'.tr({'v1': formatter.format(total), 'v2': Money.txt})),
              SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'المبلغ المدفوع (اتركه فارغ لتسديد الكل)'.tr(),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: discountController,
                decoration: InputDecoration(
                  labelText: 'الخصم'.tr(),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {
                    discount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 10),
              Text(
                'المبلغ بعد الخصم: {v1}'.tr({'v1': formatter.format(_roundMoney((controller.text.isEmpty ? total : double.tryParse(controller.text) ?? total) - discount))}),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('إلغاء'.tr()),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: isSaving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('تأكيد الدفع'.tr()),
              onPressed: isSaving
                  ? null
                  : () async {
                      // 🆕 هات آخر شيفت مفتوح الأول قبل أي حاجة
                      final currentShiftId =
                          await DBHelper.getLastOpenShiftId();

                      // 🆕 لو مفيش شيفت مفتوح، نبّه الأدمن واسأله يكمل ولا لأ
                      if (currentShiftId == null) {
                        final confirmNoShift = await showDialog<bool>(
                          context: dialogContext,
                          builder: (_) => AppDialog(
                            title: Text('⚠️ لا يوجد شيفت مفتوح حالياً'.tr()),
                            content: Text(
                              ('مفيش أي شيفت كاشير مفتوح دلوقتي.\n'.tr() + 'الدفعة هتتسجل بنجاح، لكنها مش هتظهر في تقرير أي شيفت.\n\n'.tr() + 'هل تريد المتابعة؟'.tr()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: Text('إلغاء'.tr()),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: Text('متابعة على أي حال'.tr()),
                              ),
                            ],
                          ),
                        );

                        if (confirmNoShift != true) {
                          return; // الأدمن رجع عن القرار
                        }
                      }

                      setState(() {
                        isSaving = true;
                      });

                      final entered = controller.text.trim();
                      // ✅ لو الخانة فاضية، معناها "ادفع الباقي بعد الخصم"
                      double amountInput =
                          double.tryParse(entered) ??
                          (total - discount).clamp(0, double.infinity);

                      // المبلغ اللي فعليًا هيخش درج الكاش
                      // المبلغ اللي فعليًا هيخش درج الكاش
                      double finalAmount = _roundMoney(
                        amountInput.clamp(0, double.infinity),
                      );

                      // المبلغ الكلي اللي هيتخصم من الدين (كاش + خصم)
                      double totalToApply = _roundMoney(finalAmount + discount);

                      if (totalToApply <= 0) {
                        setState(() {
                          isSaving = false;
                        });
                        return;
                      }

                      final db = await DBHelper.database;

                      // سجل درج الكاش بس للمبلغ الفعلي المدفوع (finalAmount)
                      if (finalAmount > 0) {
                        await DBHelper.addCashDrawerEntry(
                          finalAmount,
                          'income',
                          'debt',
                          shiftId: currentShiftId, // 🆕
                        );
                      }

                      // تطبيق الدفعة على الديون بترتيب الأقدم أولاً
                      // تطبيق الدفعة على الديون بترتيب الأقدم أولاً
                      double remainingCash = finalAmount;
                      double remainingDiscount = _roundMoney(discount);
                      List<Map<String, dynamic>> debtsRows = [];
                      for (var id in ids) {
                        final rows = await db.query(
                          'debts',
                          where: 'id = ?',
                          whereArgs: [id],
                        );
                        if (rows.isNotEmpty) debtsRows.add(rows.first);
                      }
                      debtsRows.sort((a, b) {
                        final da =
                            DateTime.tryParse(a['date'].toString()) ??
                            DateTime(1970);
                        final dbt =
                            DateTime.tryParse(b['date'].toString()) ??
                            DateTime(1970);
                        return da.compareTo(dbt);
                      });

                      // ✅ هنا هنجمع تفاصيل كل فاتورة بعد الدفع الفعلي عشان الطباعة
                      final List<Map<String, dynamic>> printDetails = [];

                      for (var row in debtsRows) {
                        final double remainingToApplyOuter =
                            remainingCash + remainingDiscount;
                        if (remainingToApplyOuter <= 0) break;

                        final int debtId = (row['id'] as num).toInt();
                        // 🆕 total_amount بقت ثابتة (الإجمالي الأصلي للدين)
                        final double totalAmountRow =
                            ((row['total_amount'] ?? 0) as num).toDouble();
                        final invoiceId = row['invoice_id'];

                        final customer = (row['customer_name'] ?? name)
                            .toString();
                        final originalInvoiceId = invoiceId;

                        // ✅ نجيب العناصر والمدفوعات السابقة قبل أي تعديل/حذف
                        final items = await db.query(
                          'debt_items',
                          where: 'debt_id = ?',
                          whereArgs: [debtId],
                        );
                        final previousPayments = await db.query(
                          'debt_payments',
                          where: 'debt_id = ?',
                          whereArgs: [debtId],
                        );
                        // 🔧 مصلّح: "المدفوع سابقًا" لازم يشمل الخصم كمان،
                        // مش الكاش (amount) بس، عشان rowTotal (المتبقي)
                        // يتحسب صح لو كان فيه خصم في دفعة سابقة.
                        final double paidBefore = previousPayments.fold<double>(
                          0,
                          (sum, p) =>
                              sum +
                              ((p['amount'] ?? 0) as num).toDouble() +
                              ((p['discount'] ?? 0) as num).toDouble(),
                        );

                        // 🆕 المتبقي الحقيقي لهذا الدين = الإجمالي الثابت - كل
                        // المدفوعات السابقة (كاش + خصم)
                        final double rowTotal = (totalAmountRow - paidBefore)
                            .clamp(0, double.infinity)
                            .toDouble();

                        // لو الدين ده خلص فعلاً من قبل (نادر، لكن للأمان)
                        if (rowTotal <= 0) continue;

                        final double remainingToApply =
                            remainingCash + remainingDiscount;
                        if (remainingToApply <= 0) break;

                        // ✅ نصيب هذه الفاتورة من الدفعة (كاش + خصم مع بعض)
                        final double appliedToThisRow =
                            remainingToApply >= rowTotal
                            ? rowTotal
                            : remainingToApply;

                        // ✅ نوزع النصيب ده بين الكاش والخصم: الكاش الأول ثم الخصم
                        final double cashForRow = _roundMoney(
                          remainingCash >= appliedToThisRow
                              ? appliedToThisRow
                              : remainingCash,
                        );
                        final double discountForRow = _roundMoney(
                          appliedToThisRow - cashForRow,
                        );

                        final double remainingAfter = _roundMoney(
                          rowTotal - appliedToThisRow,
                        );

                        // حالة خاصة: شحن رصيد فقط
                        if (items.length == 1 &&
                            items.first['drink_name'] == 'شحن رصيد') {
                          final double originalCost =
                              (items.first['total'] as num).toDouble();

                          // دفع جزئي
                          if (appliedToThisRow < rowTotal) {
                            // 🆕 مفيش تحديث لـ total_amount هنا — تفضل ثابتة،
                            // والمتبقي هيتحسب تلقائيًا من debt_payments في المرة الجاية

                            await db.insert('debt_payments', {
                              'debt_id': debtId,
                              'amount': cashForRow,
                              'discount': discountForRow,
                              'paid_at': DateTime.now().toIso8601String(),
                              'customer_name': customer,
                              'invoice_id': originalInvoiceId,
                              'shift_id': currentShiftId, // 🆕
                            });

                            printDetails.add({
                              'date': row['date'],
                              'items': items
                                  .map((e) => Map<String, dynamic>.from(e))
                                  .toList(),
                              'original': totalAmountRow,
                              'total': remainingAfter, // ✅ المتبقي بعد الدفع
                              'paid':
                                  paidBefore + cashForRow, // ✅ شامل الدفعة دي
                              'payments': [
                                ...previousPayments.map(
                                  (e) => Map<String, dynamic>.from(e),
                                ),
                                {
                                  'amount': cashForRow,
                                  'discount': discountForRow,
                                  'paid_at': DateTime.now().toIso8601String(),
                                },
                              ],
                            });

                            remainingCash = _roundMoney(
                              remainingCash - cashForRow,
                            );
                            remainingDiscount = _roundMoney(
                              remainingDiscount - discountForRow,
                            );
                            continue;
                          }

                          // دفع كامل
                          await DBHelper.recordTransaction(
                            cost: originalCost,
                            received: cashForRow,
                            shiftId: currentShiftId ?? 0,
                          );
                          await db.insert('invoice_items', {
                            'invoice_id': invoiceId,
                            'drink_id': 0,
                            'drink_name': 'شحن رصيد',
                            'qty': 1,
                            'price': originalCost,
                            'total': cashForRow,
                          });

                          // 🆕 مصلّح: نستخدم نفس الهيلبر بتاع الحالة العادية
                          // عشان discount + total_cost يتحدّثوا صح هنا كمان
                          if (invoiceId != null) {
                            await _updateInvoiceAfterDebtClosed(
                              invoiceId: invoiceId as int,
                              previousPayments: previousPayments,
                              discountForRow: discountForRow,
                            );
                          }

                          await db.insert('debt_payments', {
                            'debt_id': debtId,
                            'amount': cashForRow,
                            'discount': discountForRow,
                            'paid_at': DateTime.now().toIso8601String(),
                            'customer_name': customer,
                            'invoice_id': originalInvoiceId,
                            'shift_id': currentShiftId, // 🆕 كان ناقص هنا
                          });

                          printDetails.add({
                            'date': row['date'],
                            'items': items
                                .map((e) => Map<String, dynamic>.from(e))
                                .toList(),
                            'original': totalAmountRow,
                            'total': 0.0, // ✅ اتسدد بالكامل
                            'paid': paidBefore + cashForRow,
                            'payments': [
                              ...previousPayments.map(
                                (e) => Map<String, dynamic>.from(e),
                              ),
                              {
                                'amount': cashForRow,
                                'discount': discountForRow,
                                'paid_at': DateTime.now().toIso8601String(),
                              },
                            ],
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

                          remainingCash = _roundMoney(
                            remainingCash - cashForRow,
                          );
                          remainingDiscount = _roundMoney(
                            remainingDiscount - discountForRow,
                          );
                          continue;
                        }

                        // الحالة العادية
                        if (appliedToThisRow >= rowTotal) {
                          if (invoiceId != null) {
                            // 🆕 مصلّح: بنحدّث discount + total_cost بالفاتورة
                            // عشان تعكس إجمالي خصم الدين (سابق + حالي)، مش
                            // مجرد payment_type = paid من غير تعديل السعر.
                            await _updateInvoiceAfterDebtClosed(
                              invoiceId: invoiceId as int,
                              previousPayments: previousPayments,
                              discountForRow: discountForRow,
                            );
                          }
                        }
                        // 🆕 لو دفع جزئي، مفيش تحديث لـ total_amount —
                        // تفضل ثابتة والمتبقي بيتحسب من debt_payments تلقائيًا

                        // ✅ سجّل نصيب هذه الفاتورة فقط من الدفعة (كاش + خصم منفصلين)
                        await db.insert('debt_payments', {
                          'debt_id': debtId,
                          'amount': cashForRow,
                          'discount': discountForRow,
                          'paid_at': DateTime.now().toIso8601String(),
                          'customer_name': customer,
                          'invoice_id': originalInvoiceId,
                          'shift_id': currentShiftId, // 🆕 كان ناقص هنا
                        });

                        printDetails.add({
                          'date': row['date'],
                          'items': items
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(),
                          'original': totalAmountRow,
                          'total':
                              remainingAfter, // ✅ المتبقي الحقيقي بعد الدفع
                          'paid': paidBefore + cashForRow,
                          'payments': [
                            ...previousPayments.map(
                              (e) => Map<String, dynamic>.from(e),
                            ),
                            {
                              'amount': cashForRow,
                              'discount': discountForRow,
                              'paid_at': DateTime.now().toIso8601String(),
                            },
                          ],
                        });

                        if (appliedToThisRow >= rowTotal) {
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
                        }

                        remainingCash = _roundMoney(remainingCash - cashForRow);
                        remainingDiscount = _roundMoney(
                          remainingDiscount - discountForRow,
                        );
                      }

                      // ✅ إغلاق dialog الدفع والـ bottomsheet باستخدام context الشاشة
                      Navigator.of(screenContext).pop(); // dialog الدفع
                      Navigator.of(screenContext).pop(); // bottomsheet
                      _loadDebts();

                      // ✅ اسأل المستخدم يطبع ولا لأ
                      if (screenContext.mounted) {
                        final wantPrint = await showDialog<bool>(
                          context: screenContext,
                          builder: (printDialogContext) => AppDialog(
                            title: Text('طباعة الفاتورة'.tr()),
                            content: Text('هل تريد طباعة فاتورة السداد؟'.tr()),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(printDialogContext, false),
                                child: Text('لا'.tr()),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(printDialogContext, true),
                                child: Text('نعم، اطبع'.tr()),
                              ),
                            ],
                          ),
                        );

                        if (wantPrint == true) {
                          await printDebtInvoice(
                            name,
                            printDetails, // ✅ الأرقام الصح بعد الدفع
                            finalAmount, // ✅ الكاش الفعلي المدفوع بس
                            discount, // ✅ الخصم الكامل
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printDebtsInventory() async {
    if (debts.isEmpty) {
      AppToast.show('لا توجد ديون لطباعتها'.tr());
      return;
    }

    // 🆕 المجموع من remaining_amount بدل total_amount
    final totalAll = debts.fold<double>(
      0,
      (sum, d) => sum + (d['remaining_amount'] as num).toDouble(),
    );
    for (final d in debts) {
      print(d);
    }
    await printDebtsInventoryReport(debts, totalAll);
  }
  // ============================================================
  // 🆕 إعادة هيكلة debts_screen.dart لدعم طباعة عميل واحد لوحده
  // ============================================================

  // 1) الدالة دي بتجيب بيانات الطباعة لعميل واحد بس (نفس المنطق اللي كان
  //    جوه _printAllDebtsDetailed، لكن مستقل عشان نقدر نستخدمه لعميل
  //    واحد أو لكل العملاء من غير تكرار كود).
  //    ضيفها جوه _DebtsScreenState:

  Future<Map<String, dynamic>?> _buildCustomerPrintData(
    String customerName,
    List<dynamic> rawIds,
  ) async {
    final db = await DBHelper.database;
    final ids = rawIds.cast<int>();

    final List<Map<String, dynamic>> invoices = [];
    double customerRemainingTotal = 0.0;

    for (final id in ids) {
      final debtRows = await db.query(
        'debts',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (debtRows.isEmpty) continue;
      final row = debtRows.first;

      final totalAmount = ((row['total_amount'] ?? 0) as num).toDouble();

      final items = await db.query(
        'debt_items',
        where: 'debt_id = ?',
        whereArgs: [id],
      );
      final payments = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [id],
        orderBy: 'paid_at ASC',
      );

      final paidAmount = payments.fold<double>(
        0.0,
        (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
      );
      final discountAmount = payments.fold<double>(
        0.0,
        (sum, p) => sum + ((p['discount'] ?? 0) as num).toDouble(),
      );
      final remaining = (totalAmount - paidAmount - discountAmount)
          .clamp(0, double.infinity)
          .toDouble();

      if (remaining <= 0) continue;

      final date = DateTime.tryParse(row['date'].toString());
      final formattedDate = date != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(date)
          : 'غير محدد';

      invoices.add({
        'date': formattedDate,
        'items': items,
        'total': remaining,
        'paid': paidAmount,
        'discount': discountAmount,
      });

      customerRemainingTotal += remaining;
    }

    if (invoices.isEmpty) return null; // كل ديون العميل ده خلصت

    invoices.sort(
      (a, b) => (b['date'] as String).compareTo(a['date'] as String),
    );

    return {
      'customer_name': customerName,
      'remaining_total': customerRemainingTotal,
      'invoices': invoices,
    };
  }

  // 2) دالة طباعة كل الديون (نفس القديمة، لكن بقت بتستخدم الهيلبر المشترك):

  Future<void> _printAllDebtsDetailed() async {
    if (debts.isEmpty) {
      AppToast.show('لا توجد ديون لطباعتها'.tr());
      return;
    }

    final List<Map<String, dynamic>> customersData = [];

    for (final d in debts) {
      final customerName = d['customer_name'] ?? 'غير معروف'.tr();
      final data = await _buildCustomerPrintData(customerName, d['ids']);
      if (data != null) customersData.add(data);
    }

    if (customersData.isEmpty) {
      if (context.mounted) {
        AppToast.show('لا توجد ديون لطباعتها'.tr());
      }
      return;
    }

    await printAllDebtsDetailedReport(customersData);
  }

  // 3) 🆕 دالة طباعة عميل واحد بس:

  Future<void> _printSingleDebt(
    String customerName,
    List<dynamic> rawIds,
  ) async {
    final data = await _buildCustomerPrintData(customerName, rawIds);

    if (data == null) {
      if (context.mounted) {
        AppToast.show('لا يوجد دين متبقي على هذا العميل'.tr());
      }
      return;
    }

    await printAllDebtsDetailedReport([data]);
  }

  // ============================================================
  // 4) في build()، عدّل ListTile بتاعة كل عميل في الـ ListView.builder
  //    عشان تضيف زرار طباعة جنب المبلغ (trailing). استبدل الـ trailing
  //    الحالي اللي بيعرض المبلغ بس بده:
  // ============================================================

  /*
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      '${formatter.format(d['remaining_amount'])} ${Money.txt}',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.redAccent,
      ),
    ),
    IconButton(
      icon: const Icon(Icons.print, size: 20),
      tooltip: 'طباعة دين ${d['customer_name']}',
      onPressed: () => _printSingleDebt(
        d['customer_name'] ?? 'غير معروف',
        d['ids'],
      ),
    ),
  ],
),
*/
  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

