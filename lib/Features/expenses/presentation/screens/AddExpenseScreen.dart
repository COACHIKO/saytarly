import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:intl/intl.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/add_expense_screen_mobile_body.dart';
part 'desktop/add_expense_screen_windows_body.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({Key? key}) : super(key: key);

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  late Future<List<Map<String, dynamic>>> _expensesFuture;

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  DateTime? _selectedDate; // للتاريخ المحدد
  bool _showAll = true;
  void _loadExpenses() {
    if (_showAll) {
      _expensesFuture = DBHelper.getAllExpenses();
    } else if (_selectedDate != null) {
      _expensesFuture = DBHelper.getExpensesByDate(
          _selectedDate!); // نحتاج دالة جديدة في DBHelper
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _showAll = false;
        _loadExpenses();
      });
    }
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
        addedBy: 'admin',
        shiftId: 0,
      );

      _descCtrl.clear();
      _amountCtrl.clear();

      // إعادة تحميل المصروفات بعد الإضافة
      setState(() {
        _loadExpenses();
      });

      AppToast.show('تم إضافة المصروف بنجاح'.tr());
    }
  }

  String formatDateArabic(String dateStr) {
    final date = DateTime.parse(dateStr);
    // locale: 'ar' للغة العربية
    final formatter = DateFormat('EEEE dd MMMM yyyy – HH:mm', 'ar');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

