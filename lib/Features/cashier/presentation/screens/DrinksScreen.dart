import 'dart:convert';
import 'package:saytarly/core/utils/money.dart';

import 'package:flutter/material.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/Features/cashier/presentation/screens/DrinksInvoiceScreen.dart';
import 'package:saytarly/Features/cashier/presentation/print/pepsi.dart';
import 'package:saytarly/Features/cashier/presentation/screens/add_drinks.dart';
import 'package:saytarly/Features/cashier/presentation/print/drinks_invoice_print.dart';
import 'package:saytarly/core/widgets/BACKGROUND.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:intl/intl.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/drinks_screen_mobile_body.dart';
part 'desktop/drinks_screen_windows_body.dart';

class DrinksscreenDashboard extends StatefulWidget {
  final String staffName;
  final int shiftId; // أضف shiftId

  const DrinksscreenDashboard({
    Key? key,
    required this.staffName,
    required this.shiftId, // أضف هنا
  }) : super(key: key);

  @override
  State<DrinksscreenDashboard> createState() => _DrinksscreenDashboardState();
}

class _DrinksscreenDashboardState extends State<DrinksscreenDashboard> {
  List<Map<String, dynamic>> tables = [];

  // 🆕 فلتر حالة الترابيزات — لوحة الويندوز
  String _tableFilter = 'all';

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tbls = await DBHelper.getAllTables();
    final invs = await DBHelper.getAllInvoices();

    // ربط الترابيزات بالفواتير الجارية
    final tablesWithNames = tbls.map((t) {
      final activeInvoiceId = t['active_invoice_id'];
      String displayName = t['name'];
      if (activeInvoiceId != null) {
        final invoice = invs.firstWhere(
          (i) => i['id'] == activeInvoiceId,
          orElse: () => {},
        );
        displayName = invoice['customer_name'] ?? t['name'];
      }
      return {...t, 'displayName': displayName};
    }).toList();

    if (!mounted) return; // الشاشة قفلت بعد التحميل — ما نحدثش الواجهة
    setState(() {
      tables = tablesWithNames;
    });
  }

  Future<void> _startSession(Map<String, dynamic> table) async {
    final db = await DBHelper.database;

    // 🔹 جلب العملاء السابقين
    final customers = await db.rawQuery('''
    SELECT DISTINCT customer_name 
    FROM invoices 
    WHERE customer_name IS NOT NULL AND customer_name != ''
    ORDER BY customer_name COLLATE NOCASE
  ''');

    String? selectedCustomer;
    final customerNameCtrl = TextEditingController();

    if (!mounted) return; // الشاشة قفلت أثناء جلب العملاء — ما نلمس contextش
    // 🔹 نافذة اختيار العميل
    final customerName = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: Text('اختر أو أضف عميل'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCustomer,
                isExpanded: true,
                hint: Text('اختر عميل موجود'.tr()),
                items: [
                  DropdownMenuItem<String>(value: '', child: Text('بدون اسم'.tr())),
                  ...customers.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['customer_name'] as String,
                      child: Text(c['customer_name'] as String),
                    );
                  }).toList(),
                ],
                onChanged: (val) => setState(() => selectedCustomer = val),
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

    final now = DateTime.now().toIso8601String();
    final invoiceId = await DBHelper.createInvoice(
      0, // 0 لأن الجلسة تخص الترابيزة
      now,
      staffName: widget.staffName,
      shiftId: widget.shiftId,
      customerName: customerName.isEmpty ? null : customerName,
    );

    await DBHelper.updateTableInvoice(table['id'], invoiceId);

    // ✅ تحديث اسم العميل في الفاتورة (لو موجود)
    await db.update(
      'invoices',
      {'customer_name': customerName},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );

    _load();
  }

  Future<void> _partialPayment(Map<String, dynamic> table) async {
    final invoiceId = table['active_invoice_id'];
    if (invoiceId == null) return;

    final drinksCost = await DBHelper.getDrinksCostForInvoice(invoiceId);
    final alreadyPaid = await DBHelper.getPartialPaymentsTotal(invoiceId);
    final remaining = (drinksCost - alreadyPaid).clamp(0, double.infinity);

    if (remaining <= 0) {
      AppToast.show('الفاتورة متحصّلة بالكامل بالفعل'.tr());
      return;
    }

    final amountController = TextEditingController();
    double amount = 0.0;

    if (!mounted) return; // الشاشة قفلت بعد الحساب — ما نلمس contextش
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title:  Text('دفع جزئي'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إجمالي الحساب حتى الآن: {v1} ج'.tr({'v1': drinksCost.toStringAsFixed(2)}),
              ),
              if (alreadyPaid > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'تم تحصيله سابقًا: {v1} ج'.tr({'v1': alreadyPaid.toStringAsFixed(2)}),
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'المتبقي: {v1} ج'.tr({'v1': remaining.toStringAsFixed(2)}),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration:  InputDecoration(
                  labelText: 'المبلغ المدفوع الآن'.tr(),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() {
                    amount = double.tryParse(v) ?? 0.0;
                    if (amount > remaining) {
                      amount = remaining.toDouble();
                      amountController.text = amount.toStringAsFixed(2);
                      amountController.selection = TextSelection.fromPosition(
                        TextPosition(offset: amountController.text.length),
                      );
                    } else if (amount < 0) {
                      amount = 0;
                    }
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:  Text('إلغاء'.tr()),
            ),
            ElevatedButton(
              onPressed: amount > 0 ? () => Navigator.pop(context, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child:  Text('تأكيد الدفع'.tr()),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || amount <= 0) return;

    await DBHelper.addPartialPayment(
      invoiceId: invoiceId,
      amount: amount,
      shiftId: widget.shiftId,
      cashier: widget.staffName,
    );

    if (!mounted) return;
    AppToast.show('✅ تم تحصيل {v1} {v2}'.tr({'v1': amount.toStringAsFixed(2), 'v2': Money.txt}));
    _load();
  }

  Future<double> _endSession(Map<String, dynamic> table) async {
    // 🆕
    final invoiceId = table['active_invoice_id'];
    if (invoiceId == null) return 0.0;
    print(
      '🧾 START endSession | tableId=${table['id']} | invoiceId=$invoiceId',
    );

    final invoice = (await DBHelper.getAllInvoices()).firstWhere(
      (i) => i['id'] == invoiceId,
    );

    final start = DateTime.parse(invoice['start_time']);
    final end = DateTime.now();
    final drinksCost = await DBHelper.getDrinksCostForInvoice(invoiceId);
    final alreadyPaid = await DBHelper.getPartialPaymentsTotal(invoiceId);
    final deviceCost = 0.0;
    bool shouldPrint = false;
    final total = drinksCost + deviceCost;

    /*
    final discountInput = await showDialog<String>(
      context: context,
      builder: (_) => AppDialog(
        title: Text('إضافة خصم اختياري'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'الخصم',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => discount = double.tryParse(val) ?? 0.0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'ok'),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );

    if (discountInput == null || discountInput == 'cancel') return 0.0;
*/

    // 🧾 اختيار طريقة الدفع
    double discount = 0.0;
    final discountController = TextEditingController();
    double totalAfterDiscount(double discount) =>
        (drinksCost - discount - alreadyPaid).clamp(0, double.infinity);

    if (!mounted) return 0.0; // الشاشة قفلت قبل نافذة الدفع — ما نلمس contextش
    final paymentChoice = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
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
                      discountController.selection = TextSelection.fromPosition(
                        TextPosition(offset: discountController.text.length),
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
                'الإجمالي بعد الخصم: {v1} ج'.tr({'v1': totalAfterDiscount(discount).toStringAsFixed(2)}),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('تكلفة المشروبات: {v1}'.tr({'v1': drinksCost.toStringAsFixed(2)})),
              if (alreadyPaid > 0)
                Text(
                  'تم تحصيله جزئيًا: {v1} ج'.tr({'v1': alreadyPaid.toStringAsFixed(2)}),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text('الخصم: {v1}'.tr({'v1': discount.toStringAsFixed(2)})),
              const SizedBox(height: 8),
              // 🆕 خيار الطباعة
              CheckboxListTile(
                value: shouldPrint,
                onChanged: (val) {
                  setState(() {
                    shouldPrint = val ?? false;
                  });
                },
                title:  Text('طباعة الفاتورة'.tr()),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          /* actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
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
                    child:  Text('إلغاء'.tr(), style: TextStyle(fontSize: 13)),
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
                    child:  Text(
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
                    child:  Text(
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

    if (paymentChoice == null || paymentChoice == 'cancel') return 0.0;
    print('💳 paymentChoice = $paymentChoice');
    print(
      '💰 drinksCost=$drinksCost | deviceCost=$deviceCost | discount=$discount',
    );

    final db = await DBHelper.database;
    print('➡️ ENTER DEBT FLOW');

    if (paymentChoice == 'debt') {
      if (!mounted) return 0.0; // الشاشة قفلت بعد الدايلوج — ما نلمس contextش
      final nameController = TextEditingController();
      String? selectedCustomer;

      final customerName = await showDialog<String>(
        context: context,
        builder: (_) => AppDialog(
          title:  Text('تسجيل الدين'.tr()),
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
                    decoration:  InputDecoration(
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
                        (n) =>
                            n.toLowerCase().contains(value.text.toLowerCase()),
                      );
                    },
                    onSelected: (value) {
                      selectedCustomer = value;
                    },
                    fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
                      return TextField(
                        controller: textCtrl,
                        focusNode: focusNode,
                        decoration:  InputDecoration(
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
              child:  Text('إلغاء'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                final result = nameController.text.trim().isNotEmpty
                    ? nameController.text.trim()
                    : selectedCustomer;

                Navigator.pop(context, result);
              },
              child:  Text('حفظ'.tr()),
            ),
          ],
        ),
      );
      if (customerName == null || customerName.isEmpty) return discount;
      print('👤 customerName=$customerName');
      print('💸 totalAfterDiscount=${totalAfterDiscount(discount)}');

      // ⬅️ كمّل تسجيل الدين هنا

      // جلب كل المشروبات الخاصة بالفاتورة

      final debtId = await db.insert('debts', {
        'customer_name': customerName,
        'total_amount': (drinksCost - discount).clamp(0, double.infinity),
        'date': DateTime.now().toIso8601String(),
        'invoice_id': invoiceId,
        'shift_id': widget.shiftId,
      });
      final invoiceDrinks = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      for (var drink in invoiceDrinks) {
        final qty = drink['qty'] != null
            ? (drink['qty'] is num
                  ? (drink['qty'] as num).toDouble()
                  : double.tryParse(drink['qty'].toString()) ?? 0.0)
            : 0.0;

        final price = drink['price'] != null
            ? (drink['price'] is num
                  ? (drink['price'] as num).toDouble()
                  : double.tryParse(drink['price'].toString()) ?? 0.0)
            : 0.0;

        final name =
            (drink['drink_name'] != null &&
                drink['drink_name'].toString().isNotEmpty)
            ? drink['drink_name'].toString()
            : 'مشروب غير معروف';

        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': name,
          'qty': qty,
          'price': price,
          'total': qty * price,
        });
      }
      // 🆕 سطر تسوية يمثّل (الخصم + الدفعة الجزئية) عشان مجموع
      // الأصناف يفضل مطابق لـ total_amount حتى لو الدين اتعدّل بعدين

      // 🔹 جلب كل الديون للتأكيد
      final allDebts = await db.query('debts', orderBy: 'date DESC');
      print('📌 جميع الديون بعد الإدخال:');

      for (var d in allDebts) {
        final debtId = d['id'];
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

        print(
          '➡ الدين ID: $debtId - العميل: ${d['customer_name']} - المبلغ: ${d['total_amount']}',
        );

        // المشروبات
        if (items.isEmpty) {
          print('   لا توجد مشروبات مسجلة.');
        } else {
          print('   المشروبات:');
          for (var item in items) {
            print(
              '     ${item['drink_name']} x${item['qty']} - السعر: ${item['price']} - الإجمالي: ${item['total']}',
            );
          }
        }

        // الدفعات
        if (payments.isEmpty) {
          print('   لا توجد دفعات مسجلة.');
        } else {
          print('   الدفعات:');
          for (var p in payments) {
            print(
              '     المبلغ: ${p['amount']}, الخصم: ${p['discount']}, التاريخ: ${p['paid_at']}',
            );
          }
        }
      }
      // 🔧 سطر التسوية بقى بس للخصم
      if (discount > 0) {
        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': 'خصم',
          'qty': 1,
          'price': -discount,
          'total': -discount,
        });
      }

      print('🚨 CALL endInvoice (DEBT)');
      // 🆕 نقل أي دفعة جزئية سابقة لسجل الدين عشان تتحسب كمحصّل فورًا
      if (alreadyPaid > 0) {
        await DBHelper.migratePartialPaymentsToDebt(
          invoiceId: invoiceId,
          debtId: debtId,
          customerName: customerName,
        );
      }
      await DBHelper.endInvoice(
        invoiceId,
        end.toIso8601String(),
        deviceCost,
        drinksCost,
        discount: discount,
        addToCashDrawer: false,
        paymentType: 'علي الحساب'.tr(),
        shiftId: widget.shiftId,
      );
      // 🆕 تزامن total_cost الفاتورة مع الدين الفعلي
      // 🆕 تصحيح تقسيم الأعمدة
      await DBHelper.updateInvoiceDrinksCost(invoiceId);
      print('✅ endInvoice FINISHED (DEBT)');
    } else if (paymentChoice == 'paid') {
      final remainingToCollect = (totalAfterDiscount(
        discount,
      )).clamp(0, double.infinity).toDouble();

      await DBHelper.endInvoice(
        invoiceId,
        end.toIso8601String(),
        deviceCost,
        drinksCost,
        discount: discount,
        addToCashDrawer: false,
        paymentType: 'paid',
        shiftId: widget.shiftId,
      );
      await DBHelper.updateInvoiceDrinksCost(invoiceId);
      if (remainingToCollect > 0) {
        await DBHelper.addCashDrawerEntry(
          remainingToCollect,
          'income',
          'invoice',
          invoiceId: invoiceId,
          cashier: widget.staffName,
        );
      }
    }
    print('🪑 FREE TABLE ${table['id']}');

    // 🔄 تحرير الترابيزة
    await DBHelper.updateTableInvoice(table['id'], null);
    // 🆕 طباعة اختيارية حسب اختيار المستخدم
    if (shouldPrint) {
      try {
        await DrinksInvoicePrinter.printInvoice(invoiceId, discount: discount);
      } catch (e) {
        print('⚠️ فشلت الطباعة لكن العملية اتسجلت بنجاح: $e');
      }
    }
    _load();
    print('🪑 FREE TABLE ${table['id']}');

    return discount; // ⚡ إرجاع الخصم
  }

  /* Future<double> _endSession(Map<String, dynamic> table) async {
    final invoiceId = table['active_invoice_id'];
    if (invoiceId == null) return 0.0;
    print(
        '🧾 START endSession | tableId=${table['id']} | invoiceId=$invoiceId');

    final invoice = (await DBHelper.getAllInvoices()).firstWhere(
      (i) => i['id'] == invoiceId,
    );

    final start = DateTime.parse(invoice['start_time']);
    final end = DateTime.now();
    final drinksCost = await DBHelper.getDrinksCostForInvoice(invoiceId);
    final deviceCost = 0.0;
    final total = drinksCost + deviceCost;

*/ /*
    final discountInput = await showDialog<String>(
      context: context,
      builder: (_) => AppDialog(
        title: Text('إضافة خصم اختياري'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'الخصم',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => discount = double.tryParse(val) ?? 0.0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'ok'),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );

    if (discountInput == null || discountInput == 'cancel') return 0.0;
*/ /*

    // 🧾 اختيار طريقة الدفع
    double discount = 0.0;
    final discountController = TextEditingController();
    double totalAfterDiscount(double discount) =>
        (drinksCost - discount).clamp(0, double.infinity);

    final paymentChoice = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: Text('اختيار طريقة الدفع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      double entered = double.tryParse(val) ?? 0.0;
                      // نجبر الخصم يكون بين 0 و total
                      if (entered > total) {
                        discountController.text = total
                            .toStringAsFixed(2); // نص الخصم يبقى مساوي للإجمالي
                        discount = total;
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
                'الإجمالي بعد الخصم: ${totalAfterDiscount(discount).toStringAsFixed(2)} ج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('تكلفة المشروبات: ${drinksCost.toStringAsFixed(2)}'),
              Text('الخصم: ${discount.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
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

    if (paymentChoice == null || paymentChoice == 'cancel') return 0.0;
    print('💳 paymentChoice = $paymentChoice');
    print(
        '💰 drinksCost=$drinksCost | deviceCost=$deviceCost | discount=$discount');

    final db = await DBHelper.database;
    print('➡️ ENTER DEBT FLOW');

    if (paymentChoice == 'debt') {
      final nameController = TextEditingController();

      final customerName = await showDialog<String>(
        context: context,
        builder: (_) => AppDialog(
          title: Text('تسجيل الدين'),
          content: FutureBuilder<List<String>>(
            future: DBHelper.getDebtorsNames(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final names = snapshot.data!;

              return Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return names;
                  return names.where((n) =>
                      n.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (selection) {
                  nameController.text = selection;
                },
                fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
                  return TextField(
                    */ /*   controller: textCtrl,*/ /*
                    controller: nameController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'اسم العميل',
                      hintText: 'ابحث أو اكتب اسم جديد',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                nameController.text.trim(),
              ),
              child: Text('حفظ'),
            ),
          ],
        ),
      );

      if (customerName == null || customerName.isEmpty) return discount;
      print('👤 customerName=$customerName');
      print('💸 totalAfterDiscount=${totalAfterDiscount(discount)}');

      // ⬅️ كمّل تسجيل الدين هنا

// جلب كل المشروبات الخاصة بالفاتورة

      final debtId = await db.insert('debts', {
        'customer_name': customerName,
        'total_amount': totalAfterDiscount(discount),
        'date': DateTime.now().toIso8601String(),
        'invoice_id': invoiceId,
      });
      final invoiceDrinks = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      for (var drink in invoiceDrinks) {
        final qty = drink['qty'] != null
            ? (drink['qty'] is num
                ? (drink['qty'] as num).toDouble()
                : double.tryParse(drink['qty'].toString()) ?? 0.0)
            : 0.0;

        final price = drink['price'] != null
            ? (drink['price'] is num
                ? (drink['price'] as num).toDouble()
                : double.tryParse(drink['price'].toString()) ?? 0.0)
            : 0.0;

        final name = (drink['drink_name'] != null &&
                drink['drink_name'].toString().isNotEmpty)
            ? drink['drink_name'].toString()
            : 'مشروب غير معروف';

        await db.insert('debt_items', {
          'debt_id': debtId,
          'drink_name': name,
          'qty': qty,
          'price': price,
          'total': qty * price,
        });
      }

// 🔹 جلب كل الديون للتأكيد
      final allDebts = await db.query('debts', orderBy: 'date DESC');
      print('📌 جميع الديون بعد الإدخال:');

      for (var d in allDebts) {
        final debtId = d['id'];
        final items = await db
            .query('debt_items', where: 'debt_id = ?', whereArgs: [debtId]);
        final payments = await db
            .query('debt_payments', where: 'debt_id = ?', whereArgs: [debtId]);

        print(
            '➡ الدين ID: $debtId - العميل: ${d['customer_name']} - المبلغ: ${d['total_amount']}');

        // المشروبات
        if (items.isEmpty) {
          print('   لا توجد مشروبات مسجلة.');
        } else {
          print('   المشروبات:');
          for (var item in items) {
            print(
                '     ${item['drink_name']} x${item['qty']} - السعر: ${item['price']} - الإجمالي: ${item['total']}');
          }
        }

        // الدفعات
        if (payments.isEmpty) {
          print('   لا توجد دفعات مسجلة.');
        } else {
          print('   الدفعات:');
          for (var p in payments) {
            print(
                '     المبلغ: ${p['amount']}, الخصم: ${p['discount']}, التاريخ: ${p['paid_at']}');
          }
        }
      }
      print('🚨 CALL endInvoice (DEBT)');

      await DBHelper.endInvoice(
        invoiceId,
        end.toIso8601String(),
        deviceCost,
        drinksCost,
        discount: discount,
        addToCashDrawer: false,
        paymentType: 'علي الحساب',
        shiftId: widget.shiftId,
      );
      print('✅ endInvoice FINISHED (DEBT)');
    } else if (paymentChoice == 'paid') {
      await DBHelper.endInvoice(
        invoiceId,
        end.toIso8601String(),
        deviceCost,
        drinksCost,
        discount: discount,
        addToCashDrawer: true,
        paymentType: 'paid',
        shiftId: widget.shiftId,
      );
    }
    print('🪑 FREE TABLE ${table['id']}');

    // 🔄 تحرير الترابيزة
    await DBHelper.updateTableInvoice(table['id'], null);
    _load();
    print('🪑 FREE TABLE ${table['id']}');

    return discount; // ⚡ إرجاع الخصم
  }
*/
  /*
  Future<void> _endSession(Map<String, dynamic> table) async {
    final invoiceId = table['active_invoice_id'];
    if (invoiceId == null) return;

    final invoice = (await DBHelper.getAllInvoices()).firstWhere(
      (i) => i['id'] == invoiceId,
    );

    final start = DateTime.parse(invoice['start_time']);
    final end = DateTime.now();
    final duration = end.difference(start).inSeconds / 3600.0;

    final drinksCost = await DBHelper.getDrinksCostForInvoice(
      invoiceId,
    ); // سعر المشروبات
    final deviceCost = 0; // الترابيزات مش محسوبة وقت
    final total = drinksCost + deviceCost;

    // Dialog تأكيد الدفع
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: Text('تأكيد إغلاق الجلسة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تكلفة المشروبات: ${drinksCost.toStringAsFixed(2)}'),
            Divider(),
            Text(
              'الإجمالي: ${total.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DBHelper.endInvoice(
      invoiceId,
      end.toIso8601String(),
      deviceCost.toDouble(),
      drinksCost,
    );
    await DBHelper.updateTableInvoice(table['id'], null);
    _load();
  }
*/

  String _searchQuery = '';

  List<Map<String, dynamic>> get filteredTables {
    if (_searchQuery.isEmpty) return tables;
    return tables.where((t) {
      final name = (t['displayName'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  // لتفريغ كل الترابيزات
  Future<void> _clearAllTables() async {
    for (final t in tables) {
      if (t['active_invoice_id'] != null) {
        await DBHelper.endInvoice(
          t['active_invoice_id'],
          DateTime.now().toIso8601String(),
          0,
          await DBHelper.getDrinksCostForInvoice(t['active_invoice_id']),
        );
        await DBHelper.updateInvoiceDrinksCost(t['active_invoice_id']);
        await DBHelper.updateTableInvoice(t['id'], null);
      }
    }
    _load();
  }

  /*  Future<void> _startTakeaway() async {
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
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: Text('اختر أو أضف عميل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCustomer,
                isExpanded: true,
                hint: Text('اختر عميل موجود'),
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text('بدون اسم'),
                  ),
                  ...customers.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['customer_name'] as String,
                      child: Text(c['customer_name'] as String),
                    );
                  }).toList(),
                ],
                onChanged: (val) => setState(() => selectedCustomer = val),
              ),
              SizedBox(height: 10),
              TextField(
                controller: customerNameCtrl,
                decoration: InputDecoration(
                  labelText: 'أو أدخل عميل جديد',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = customerNameCtrl.text.trim();
                Navigator.pop(
                  context,
                  name.isNotEmpty ? name : selectedCustomer,
                );
              },
              child: Text('ابدأ'),
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
      staffName: widget.staffName, shiftId: widget.shiftId,
      customerName: customerName.isEmpty ? null : customerName,
    );
    final allDrinks = await db.query('invoice_drinks');
    print('All drinks: $allDrinks');

    // فتح شاشة إضافة مشروبات مباشرة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDrinksScreen(invoiceId: invoiceId),
      ),
    ).then((_) {
      // بعد إضافة المشروبات، يمكن إنهاء الفاتورة مباشرة
      _handleTakeawayPayment(invoiceId);
    });
  }*/

  /*Future<void> _handleTakeawayPayment(int invoiceId) async {
    final drinksCost = await DBHelper.getDrinksCostForInvoice(invoiceId);
    double discount = 0.0;
    final discountController = TextEditingController();

    final paymentChoice = await showDialog<String>(
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
                    discount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 10),
              Text(
                'الإجمالي بعد الخصم: ${(drinksCost - discount).clamp(0, double.infinity).toStringAsFixed(2)} ج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
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

    if (paymentChoice == null || paymentChoice == 'cancel') return;

    final db = await DBHelper.database;
    final totalAfterDiscount =
        (drinksCost - discount).clamp(0, double.infinity);

    if (paymentChoice == 'debt') {
      final nameController = TextEditingController();
      final customerName = await showDialog<String>(
        context: context,
        builder: (_) => AppDialog(
          title: Text('تسجيل الدين'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'اسم العميل',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: Text('حفظ'),
            ),
          ],
        ),
      );

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
  Future<bool> _checkPassword() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title:  Text('كلمة المرور'.tr()),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration:  InputDecoration(hintText: 'أدخل كلمة المرور'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text == "0000");
            },
            child:  Text('تأكيد'.tr()),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> forceCloseTable(int tableId) async {
    final db = await DBHelper.database;

    final table = await db.query('tables', where: 'id=?', whereArgs: [tableId]);

    if (table.isEmpty) return;

    final invoiceId = table.first['active_invoice_id'];

    if (invoiceId != null) {
      // جلب عناصر الفاتورة
      final items = await db.query(
        'invoice_items',
        where: 'invoice_id=?',
        whereArgs: [invoiceId],
      );

      // إرجاع الكميات للمخزون
      for (final item in items) {
        final items = await db.query(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );

        for (final item in items) {
          final drinkId = item['drink_id'] as int;
          final qty = (item['qty'] as num).toInt();

          final drinkData = await db.query(
            'drinks',
            where: 'id = ?',
            whereArgs: [drinkId],
          );

          if (drinkData.isNotEmpty) {
            final currentStock = drinkData.first['qty'] as int;

            await db.update(
              'drinks',
              {'qty': currentStock + qty},
              where: 'id = ?',
              whereArgs: [drinkId],
            );

            await DBHelper.restoreRecipe(drinkId, qty);
          }
        }
      }

      // حذف العناصر
      await db.delete(
        'invoice_items',
        where: 'invoice_id=?',
        whereArgs: [invoiceId],
      );

      // حذف الفاتورة
      await db.delete('invoices', where: 'id=?', whereArgs: [invoiceId]);
    }

    // تحرير الترابيزة
    await db.update(
      'tables',
      {'active_invoice_id': null},
      where: 'id=?',
      whereArgs: [tableId],
    );

    if (!mounted) return; // الشاشة قفلت بعد الحذف — ما نحدثش الواجهة
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

