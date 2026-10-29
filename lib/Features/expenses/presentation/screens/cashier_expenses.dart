import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/cashier_expenses_mobile_body.dart';
part 'desktop/cashier_expenses_windows_body.dart';

class CashierExpensesScreen extends StatefulWidget {
  final int shiftId; // نمرر رقم الشيفت الحالي
  final String cashierName;
  const CashierExpensesScreen({
    Key? key,
    required this.shiftId,
    required this.cashierName,
  }) : super(key: key);

  @override
  State<CashierExpensesScreen> createState() => _CashierExpensesScreenState();
}

class _CashierExpensesScreenState extends State<CashierExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  late Future<List<Map<String, dynamic>>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  String formatDateArabic(String dateStr) {
    final date = DateTime.parse(dateStr);
    // locale: 'ar' للغة العربية
    final formatter = DateFormat('EEEE dd MMMM yyyy – HH:mm', 'ar');
    return formatter.format(date);
  }

  void _loadExpenses() {
    _expensesFuture = DBHelper.getExpensesByShift(widget.shiftId);
  }

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd – HH:mm').format(date);
  }

  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate()) {
      final description = _descCtrl.text;
      final amount = double.parse(_amountCtrl.text);

      await DBHelper.addExpense(
        description: description,
        amount: amount,
        addedBy: widget.cashierName,
        shiftId: widget.shiftId,
      );

      _descCtrl.clear();
      _amountCtrl.clear();

      setState(() {
        _loadExpenses();
      });

      AppToast.show('تم إضافة المصروف بنجاح'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }

  Widget _infoCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 18)),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
