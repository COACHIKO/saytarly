import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saytarly/Features/staff/logic/cubit/sub_staff_update_cubit.dart';
import 'package:saytarly/core/database/db_helper.dart'; // استبدل بمسار DBHelper الصحيح
import 'package:saytarly/core/utils/money.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/sub_staff_page_mobile_body.dart';
part 'desktop/sub_staff_page_windows_body.dart';
class SubStaffPage extends StatefulWidget {
  final int staffId;
  final int shiftId;
  final String cashierName;
  const SubStaffPage(
      {required this.staffId,
      required this.shiftId,
      required this.cashierName,
      Key? key})
      : super(key: key);

  @override
  State<SubStaffPage> createState() => _SubStaffPageState();
}

class _SubStaffPageState extends State<SubStaffPage> {
  List<Map<String, dynamic>> editableSubStaff = [];
  Timer? timer;
  bool _loading = true;
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _loadSubStaff();

    // الإشارة اللي بترسلها لوحة الموظف عشان نعيد التحميل فورًا.
    _sub = subStaffUpdateCubit.stream.listen((_) {
      if (mounted) _loadSubStaff();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadSubStaff() async {
    final subStaffList = await DBHelper.getSubStaff(widget.staffId);
    setState(() {
      editableSubStaff = List<Map<String, dynamic>>.from(subStaffList);
      _loading = false;
    });
    print('subStaffList after join with shifts:');
    for (var staff in subStaffList) {
      print(staff);
    }
  }

  /* Future<void> _toggleShift(Map<String, dynamic> staff) async {
    final staffId = staff['id'] as int;
    final shiftStartStr = staff['shift_start'];
    final shiftEndStr = staff['shift_end'];
    final salaryPerHour = (staff['salary_per_hour'] ?? 0.0) as double;

    bool isWorking = shiftStartStr != null && shiftEndStr == null;

    if (!isWorking) {
      // بدء الشيفت
      await DBHelper.startShiftForSubStaff(
        staffId: staffId,
        supervisorShiftId: widget.shiftId,
        startTime: DateTime.now().toIso8601String(),
      );
      await _loadSubStaff();
    } else {
      // حساب المدة والأجر
      final start = DateTime.parse(shiftStartStr!);
      final end = DateTime.now();
      final workedHours = end.difference(start).inSeconds / 3600;
      final earned = workedHours * salaryPerHour;

      // عرض Dialog للتأكيد
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          title: const Text('تأكيد إنهاء الشيفت'),
          content: Text(
              'مدة العمل: ${workedHours.toStringAsFixed(2)} ساعة\nالأجر: ${earned.toStringAsFixed(2)} ${Money.txt}\nهل أنت متأكد من إنهاء الشيفت؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // إنهاء الشيفت
        await DBHelper.endShiftForSubStaff(
          staffId: staffId,
          endTime: end.toIso8601String(),
        );

        // إضافة المبلغ كمصروف
        await DBHelper.addExpense(
          description: 'أجر موظف: ${staff['username']}',
          amount: earned,
          addedBy: widget.cashierName,
          shiftId: widget.shiftId,
        );

        await _loadSubStaff();
        AppToast.show('تم إنهاء الشيفت وإضافة الأجر: ${earned.toStringAsFixed(2)} ${Money.txt} كمصروف');
      }
    }
  }
*/

  Future<void> _toggleShift(Map<String, dynamic> staff) async {
    final staffId = staff['id'] as int;
    final shiftStartStr = staff['shift_start'];
    final shiftEndStr = staff['shift_end'];
    final salaryPerHour = (staff['salary_per_hour'] ?? 0.0) as double;

    bool isWorking = shiftStartStr != null && shiftEndStr == null;

    if (!isWorking) {
      // بدء الشيفت
      await DBHelper.startShiftForSubStaff(
        staffId: staffId,
        supervisorShiftId: widget.shiftId,
        startTime: DateTime.now().toIso8601String(),
      );
      await _loadSubStaff();
    } else {
      // حساب المدة والأجر
      final start = DateTime.parse(shiftStartStr!);
      final end = DateTime.now();
      final workedHours = end.difference(start).inSeconds / 3600;
      final earned = workedHours * salaryPerHour;

      // عرض Dialog للتأكيد مع خيارات الرصيد/صرف/إلغاء
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AppDialog(
          title:  Text('تأكيد إنهاء الشيفت'.tr()),
          content: Text(
              'مدة العمل: {v1} ساعة\nالأجر: {v2} {v3}\nاختر ماذا تريد فعله بالأجر:'.tr({'v1': workedHours.toStringAsFixed(2), 'v2': earned.toStringAsFixed(2), 'v3': Money.txt})),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child:  Text('إلغاء'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'add_to_balance'),
              child:  Text('إضافة إلى حسابو'.tr()),
              style: ElevatedButton.styleFrom(),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'pay_directly'),
              child:  Text('صرف مباشرة'.tr()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      );

      if (action == null || action == 'cancel') return; // لو إلغاء

      // إنهاء الشيفت أولاً
      await DBHelper.endShiftForSubStaff(
        staffId: staffId,
        endTime: end.toIso8601String(),
      );

      // تنفيذ الإجراء المختار
      if (action == 'add_to_balance') {
        await DBHelper.addStaffDueSalary({
          'id': staff['id'],
          'name': staff['username'],
          'shiftId': widget.shiftId,
          'hours': workedHours,
          'earned': earned,
          'net': earned, // هنا ممكن تحسب خصم السلفة لو موجودة
        });
        AppToast.show('تم إضافة الأجر إلى الرصيد'.tr());
      } else if (action == 'pay_directly') {
        await DBHelper.addExpense(
          description: 'أجر موظف: {v1}'.tr({'v1': staff['username']}),
          amount: earned,
          addedBy: widget.cashierName,
          shiftId: widget.shiftId,
        );
        AppToast.show('تم صرف الأجر مباشرة كمصروف'.tr());
      }

      await _loadSubStaff();
    }
  }

/*
  Future<void> _toggleShift(Map<String, dynamic> staff) async {
    final staffId = staff['id'] as int;
    final shiftStartStr = staff['shift_start'];
    final shiftEndStr = staff['shift_end'];

    bool isWorking = shiftStartStr != null && shiftEndStr == null;

    if (!isWorking) {
      // بدء الشيفت
      await DBHelper.startShiftForSubStaff(
        staffId: staffId,
        supervisorShiftId: widget.shiftId,
        startTime: DateTime.now().toIso8601String(),
      );
    } else {
      // إنهاء الشيفت
      await DBHelper.endShiftForSubStaff(
        staffId: staffId,
        endTime: DateTime.now().toIso8601String(),
      );
    }

    await _loadSubStaff();
  }
*/

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}