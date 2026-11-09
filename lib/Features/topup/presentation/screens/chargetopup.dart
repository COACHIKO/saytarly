import 'package:flutter/material.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/Features/debts/presentation/widgets/customer_picker_dialog.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/chargetopup_mobile_body.dart';
part 'desktop/chargetopup_windows_body.dart';

class chargetop extends StatefulWidget {
  final int shiftId;
  const chargetop({super.key, required this.shiftId});

  @override
  State<chargetop> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<chargetop> {
  final _costController = TextEditingController();
  final _receivedController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _transactions = [];
  double _balance = 0.0;

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final tx = await DBHelper.getAllTransactions();
    final bal = await DBHelper.getMachineBalance();
    setState(() {
      _transactions = tx;
      _balance = bal;
    });
  }

  String formatArabicDate(DateTime date) {
    final days = [
      "الاثنين",
      'الثلاثاء'.tr(),
      'الأربعاء'.tr(),
      'الخميس'.tr(),
      'الجمعة'.tr(),
      'السبت'.tr(),
      'الأحد'.tr(),
    ];

    final months = [
      "يناير".tr(),
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
      'ديسمبر'.tr(),
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'م'.tr() : "ص".tr();

    final minute = date.minute.toString().padLeft(2, '0');

    return '{dayName}، {v2} {monthName} {v4} - {hour}:{minute} {ampm}'.tr({
      'dayName': dayName,
      'v2': date.day,
      'monthName': monthName,
      'v4': date.year,
      'hour': hour,
      'minute': minute,
      'ampm': ampm,
    });
  }

  Future<void> _record() async {
    final cost = double.tryParse(_costController.text) ?? 0.0;
    final received = double.tryParse(_receivedController.text) ?? 0.0;

    if (cost <= 0) return _showError('أدخل تكلفة صحيحة'.tr());
    if (received <= 0) return _showError('أدخل المبلغ المستلم'.tr());

    // 🔥 اختيار طريقة الدفع
    final paymentChoice = await showDialog<String>(
      context: context,
      builder:
          (_) => AppDialog(
            title: Text('اختيار طريقة الدفع'.tr()),
            content: Text(
              'المبلغ المستلم: {v1} ج'.tr({'v1': received.toStringAsFixed(2)}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, "cancel"),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, "debt"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('على الحساب'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, "paid"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('دفع كامل'.tr()),
              ),
            ],
          ),
    );

    if (paymentChoice == "cancel" || paymentChoice == null) return;

    setState(() => _loading = true);

    final db = await DBHelper.database;

    // ============================================================
    //  🔶 1) شــحــن عــلــى الــحــســاب (دين)
    // ============================================================
    if (paymentChoice == "debt") {
      // 🆕 ديالوج العملاء الموحّد — بيعرض كل العملاء المسجّلين، وأي
      // اسم جديد بيتحفظ كعميل وبيتسجل بيه الشحن على الحساب.
      final customerName = await showCustomerPickerDialog(
        context,
        title: 'تسجيل الشحن كدين',
      );

      if (customerName == null || customerName.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // ⬇️ استخدم customerName هنا

      // خصم من المكنة
      await db.rawUpdate("UPDATE machine_balance SET balance = balance - ?", [
        cost,
      ]);
      final int invoiceId = await db.insert("invoices", {
        "start_time": DateTime.now().toIso8601String(),
        "end_time": DateTime.now().toIso8601String(),
        "total_cost": received,
        "payment_type": "علي الحساب",
        "console_id": 0,
        "discount": 0,
      });
      // حفظ الدين فقط
      // سجل الدين
      final debtId = await db.insert("debts", {
        "customer_name": customerName,
        "total_amount": received,
        "date": DateTime.now().toIso8601String(),
        "invoice_id": invoiceId,
        "type": "علي الحساب",
        "shift_id": widget.shiftId,
      });

      // سجل عنصر افتراضي للشحن ليظهر في التفاصيل
      await db.insert("debt_items", {
        "debt_id": debtId,
        "drink_name": "شحن رصيد",
        "qty": 1,
        "price": cost,
        "total": received,
      });

      // خصم من المكنة فقط
      await db.insert("machine_balance_logs", {
        "amount": cost,
        "type": "withdraw",
        "note": "خصم تكلفة شحن (cost=$cost)",
        "date": DateTime.now().toIso8601String(),
      });

      AppToast.show(
        'تم تسجيل شحن {received} ج كدين باسم {customerName}'.tr({
          'received': received,
          'customerName': customerName,
        }),
      );

      _costController.clear();
      _receivedController.clear();
      await _reload();
      setState(() => _loading = false);
      return;
    }

    // ============================================================
    //  🔷 2) دفــع كــامــل (نفس النظام القديم)
    // ============================================================
    if (paymentChoice == "paid") {
      await DBHelper.recordTransaction(
        cost: cost,
        received: received,
        shiftId: widget.shiftId,
      );
      // تسجيل الربح كدخل لليومية
      await db.insert('cash_drawer', {
        'type': 'income',
        'amount': received,
        'source': 'topup',
        'date': DateTime.now().toIso8601String(),
        'shift_id': widget.shiftId,
      });
      await db.insert("machine_balance_logs", {
        "amount": cost,
        "type": "deposit",
        "note": "عملية رصيد (تكلفة: $cost - مستلم: $received)",
        "date": DateTime.now().toIso8601String(),
      });

      AppToast.show('تم تسجيل العملية بنجاح'.tr());
    }

    _costController.clear();
    _receivedController.clear();
    await _reload();
    setState(() => _loading = false);
  }

  void _showError(String msg) {
    AppToast.show(msg);
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
