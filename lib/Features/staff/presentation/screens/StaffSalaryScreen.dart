import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/staff_salary_screen_mobile_body.dart';
part 'desktop/staff_salary_screen_windows_body.dart';
class StaffSalaryScreen extends StatefulWidget {
  @override
  State<StaffSalaryScreen> createState() => _StaffSalaryScreenState();
}

class _StaffSalaryScreenState extends State<StaffSalaryScreen> {
  List<Map<String, dynamic>> staff = [];
  final now = DateTime.now();
  String get month => "${now.year}-${now.month.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    loadStaff();
  }

  Future<void> loadStaff() async {
    final all = await DBHelper.getAllUsers();
    final s = all
        .where((u) => u['role'] == 'cashier' || u['role'] == 'waiter')
        .toList();
    // احسب المرتب لكل موظف (غير مُكلّف UI)
    final List<Map<String, dynamic>> out = [];
    for (final u in s) {print("USER ${u['username']} — NET = ${u['net']}");

    final net = await DBHelper.calculateMonthlySalary(u['id'], month);
      out.add({'id': u['id'], 'username': u['username'], 'net': net});
    }
    setState(() => staff = out);

  }

  Future<void> _pay(int userId) async {
    // استدعي الدفع
    await DBHelper.payStaffSalary(userId, month);
    await loadStaff(); // اعادة تحميل القيم بعد الدفع (ستُصفر)
    AppToast.show('تم صرف المرتب'.tr());
  }

  Future<List<Map<String, dynamic>>> _history(int userId) {
    return DBHelper.getSalaryHistory(userId);
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}