import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:intl/intl.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/pending_salaries_screen_mobile_body.dart';
part 'desktop/pending_salaries_screen_windows_body.dart';
class PendingSalariesScreen extends StatefulWidget {
  const PendingSalariesScreen({super.key});

  @override
  State<PendingSalariesScreen> createState() => _PendingSalariesScreenState();
}

class _PendingSalariesScreenState extends State<PendingSalariesScreen> {
  List<Map<String, dynamic>> pending = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DBHelper.database;

    pending = await db.rawQuery("""
    SELECT 
      staff_id,
      staff_name,
      SUM(hours) AS total_hours,
      SUM(net) AS total_net,
      MAX(date) AS last_date
    FROM staff_due_salaries
    WHERE is_paid = 0
    GROUP BY staff_id
    ORDER BY last_date DESC
  """);

    setState(() {});
  }

  String _formatArabicDateTime(String dateStr) {
    final date = DateTime.parse(dateStr);

     final days = [
      "الاثنين",
      'الثلاثاء'.tr(),
      'الأربعاء'.tr(),
      'الخميس'.tr(),
      'الجمعة'.tr(),
      'السبت'.tr(),
      'الأحد'.tr()
    ];

    final dayName = days[date.weekday - 1];

    final formatted = DateFormat("yyyy/MM/dd – hh:mm a").format(date);

    return "$dayName – $formatted";
  }

  Future<void> _pay(int userId, double amount, String name) async {
    final db = await DBHelper.database;

    // علّم كل المستحقات الخاصة بهذا الموظف إنها اتصرفت
    await db.update(
      'staff_due_salaries',
      {'is_paid': 1},
      where: 'staff_id=? AND is_paid=0',
      whereArgs: [userId],
    );

    // سجل المصروف
    await DBHelper.addExpense(
      description: 'صرف راتب {name}'.tr({'name': name}),
      amount: amount,
      shiftId: 1,
      addedBy: "Admin",
    );

    _load();
    AppToast.show('تم صرف الراتب لـ {name}'.tr({'name': name}));
  }

  void _showDetailsSheet(int staffId, String name) async {
    final db = await DBHelper.database;

    final details = await db.rawQuery("""
    SELECT *
    FROM staff_due_salaries
    WHERE staff_id = ? AND is_paid = 0
    ORDER BY date DESC
  """, [staffId]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تفاصيل أيام العمل – {name}'.tr({'name': name}),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...details.map((d) {
                final formatted = _formatArabicDateTime(d['date'].toString());

                return Card(
                  child: ListTile(
                    title: Text('التاريخ: {formatted}'.tr({'formatted': formatted})),
                    subtitle: Text(
                      'الساعات: {v1}\nالصافي: {v2}'.tr({'v1': d['hours'], 'v2': d['net']}),
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

/*  Future<void> _pay(int id, double amount, String name) async {
    final db = await DBHelper.database;

    // 1) تعليم بأنها اتصرفت
    await db.update(
      'staff_due_salaries',
      {'is_paid': 1},
      where: 'id=?',
      whereArgs: [id],
    );

    // 2) تسجيلها كمصروف
    await DBHelper.addExpense(
      description: "صرف راتب $name",
      amount: amount,
      shiftId: 1,
      addedBy: "Admin",
    );

    _load();
    AppToast.show('تم صرف الراتب لـ $name');
  }*/

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}