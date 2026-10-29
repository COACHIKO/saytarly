import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/database/db_helper.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/sub_staff_screen_mobile_body.dart';
part 'desktop/sub_staff_screen_windows_body.dart';
class SubStaffScreen extends StatefulWidget {
  final int supervisorId; // الكاشير أو المدير المسؤول

  const SubStaffScreen({super.key, required this.supervisorId});

  @override
  State<SubStaffScreen> createState() => _SubStaffScreenState();
}

class _SubStaffScreenState extends State<SubStaffScreen> {
  List<Map<String, dynamic>> subStaff = [];

  @override
  void initState() {
    super.initState();
    _loadSubStaff();
  }

  Future<void> _loadSubStaff() async {
    final rows = await DBHelper.getSubStaff(widget.supervisorId);
    setState(() => subStaff = rows);
  }

  void _showForm({Map<String, dynamic>? edit}) {
    if (edit == null) {
      // الإضافة بقيت تعيين موظف طلبات (ويتر) موجود — اللي الأدمن أنشئه في
      // إدارة المستخدمين — كموظف فرعي للشيفت ده، مش إنشاء حساب من الصفر.
      _assignSubStaff();
      return;
    }
    final nameCtrl = TextEditingController(text: edit['username'] ?? '');
    final passCtrl = TextEditingController(text: edit['password'] ?? '');
    final salaryCtrl =
    TextEditingController(text: edit['salary_per_hour']?.toString() ?? '');
    final hoursCtrl =
    TextEditingController(text: edit['work_hours_per_day']?.toString() ?? '8');

    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: Text('تعديل الموظف: {v1}'.tr({'v1': edit['username']})),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'اسم الموظف'.tr())),
              SizedBox(height: 8),
              TextField(controller: passCtrl, decoration: InputDecoration(labelText: 'كلمة المرور'.tr())),    SizedBox(height: 8),
              TextField(
                controller: salaryCtrl,
                decoration: InputDecoration(labelText: 'الراتب بالساعة'.tr()),
                keyboardType: TextInputType.number,
              ),    SizedBox(height: 8),
              TextField(
                controller: hoursCtrl,
                decoration: InputDecoration(labelText: 'عدد ساعات العمل اليومية'.tr()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء'.tr())),
          ElevatedButton(
            onPressed: () async {
              final username = nameCtrl.text.trim();
              final password = passCtrl.text.trim();
              final salary = double.tryParse(salaryCtrl.text) ?? 0.0;
              final hours = int.tryParse(hoursCtrl.text) ?? 8;

              if (username.isEmpty || password.isEmpty) return;

              final userId = edit['id'];
              final db = await DBHelper.database;
              await db.update(
                'users',
                {'username': username, 'password': password},
                where: 'id=?',
                whereArgs: [userId],
              );

              final existing = await DBHelper.getStaffSettings(userId);
              if (existing == null) {
                await DBHelper.insertStaffSettings(
                  userId: userId,
                  salaryPerHour: salary,
                  workHoursPerDay: hours,
                  daysOff: '',
                );
              } else {
                await db.update(
                  'staff_settings',
                  {'salary_per_hour': salary, 'work_hours_per_day': hours},
                  where: 'user_id=?',
                  whereArgs: [userId],
                );
              }

              Navigator.pop(context);
              _loadSubStaff();
            },
            child: Text('حفظ'.tr()),
          ),
        ],
      ),
    );
  }

  /// التعيين عند الكاشير ده — بيختار من موظفي الطلبات (الويترات) اللي
  /// أنشئهم الأدمن في إدارة المستخدمين، وبيلوس الراتب/ساعات العمل.
  Future<void> _assignSubStaff() async {
    // 🔑 فحص مكرر احتياطي + بنمسك الاختيار بإيدي الموظف (int) بدل مقارنة
    // الماب نفسه بالهوية (identity) — المقارنة دي كانت بتكسر الدروب داون.
    final candidates =
        await DBHelper.getAssignableWaiters(widget.supervisorId);
    final deduped = <Map<String, dynamic>>[];
    for (final c in candidates) {
      if (!deduped.any((x) => x['id'] == c['id'])) deduped.add(c);
    }
    if (!mounted) return;

    int? selectedId;
    final salaryCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '8');

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AppDialog(
          title:  Text('تعيين موظف طلبات (ويتر) كموظف فرعي'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (deduped.isEmpty)
                   Text(
                    ('مفيش موظفي طلبات متاحين للتعيين — أنشئ حساب '.tr() + '«موظف طلبات (ويتر)» الأول من إدارة المستخدمين، '.tr() + 'وبعدها رجع هنا ويعينه للشيفت ده.'.tr()),
                  )
                else ...[
                  DropdownButtonFormField<int>(
                    value: selectedId,
                    isExpanded: true,
                    decoration:  InputDecoration(
                      labelText: 'موظف الطلبات'.tr(),
                      helperText:
                          'بعد التعيين، بدء/إنهاء شيفته بيكون من شاشة شيفتات الموظفين'.tr(),
                    ),
                    items: [
                      for (final c in deduped)
                        DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text(
                            ('${c['username']}' + '{v1}'.tr({'v1': c['supervisor_id'] != null ? ' — منقول من مشرف تاني'.tr() : ''})),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) async {
                      setDialogState(() => selectedId = v);
                      if (v == null) return;
                      // نبتدي الأجر/الساعات من إعدادات الموظف الموجودة لو فيه
                      final settings = await DBHelper.getStaffSettings(v);
                      if (!dialogContext.mounted) return;
                      setDialogState(() {
                        salaryCtrl.text =
                            settings?['salary_per_hour']?.toString() ?? '';
                        hoursCtrl.text =
                            settings?['work_hours_per_day']?.toString() ?? '8';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: salaryCtrl,
                    decoration:
                         InputDecoration(labelText: 'الراتب بالساعة'.tr()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hoursCtrl,
                    decoration:  InputDecoration(
                        labelText: 'عدد ساعات العمل اليومية'.tr()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:  Text('إلغاء'.tr()),
            ),
            if (deduped.isNotEmpty)
              ElevatedButton(
                onPressed: selectedId == null
                    ? null
                    : () async {
                        final pickedRow = deduped
                            .firstWhere((c) => c['id'] == selectedId);
                        final userId = pickedRow['id'] as int;
                        final salary = double.tryParse(salaryCtrl.text) ?? 0.0;
                        final hours = int.tryParse(hoursCtrl.text) ?? 8;

                        final db = await DBHelper.database;
                        await db.update(
                          'users',
                          {'supervisor_id': widget.supervisorId},
                          where: 'id=?',
                          whereArgs: [userId],
                        );

                        final existing =
                            await DBHelper.getStaffSettings(userId);
                        if (existing == null) {
                          await DBHelper.insertStaffSettings(
                            userId: userId,
                            salaryPerHour: salary,
                            workHoursPerDay: hours,
                            daysOff: '',
                          );
                        } else {
                          await db.update(
                            'staff_settings',
                            {
                              'salary_per_hour': salary,
                              'work_hours_per_day': hours,
                            },
                            where: 'user_id=?',
                            whereArgs: [userId],
                          );
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _loadSubStaff();
                      },
                child:  Text('تعيين'.tr()),
              ),
          ],
        ),
      ),
    );
  }

  /// بيشيل الموظف الفرعي من الشيفت ده (بدون مسح الحساب) — الحساب يرجع
  /// متاح للتعيين عند أي كاشير تاني من إدارة المستخدمين.
  Future<void> _removeSubStaff(Map<String, dynamic> u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: Text('إزالة {v1} من الشيفت ده'.tr({'v1': u['username']})),
        content:  Text(
          'الحساب نفسه مش هيتحذف — هيبقى متاح للتعيين عند أي كاشير تاني من إدارة المستخدمين.'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text('إزالة'.tr()),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // لو عنده شيفت شغّال دلوقتي بنقفله الأول
    final isWorking = u['shift_start'] != null && u['shift_end'] == null;
    if (isWorking) {
      await DBHelper.endStaffShift(u['id'] as int, DateTime.now());
    }
    final db = await DBHelper.database;
    await db.update(
      'users',
      {'supervisor_id': null},
      where: 'id=?',
      whereArgs: [u['id']],
    );
    _loadSubStaff();
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}