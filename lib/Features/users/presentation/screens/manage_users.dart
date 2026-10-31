import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/Features/staff/presentation/screens/SubStaffScreen.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/manage_users_mobile_body.dart';
part 'desktop/manage_users_windows_body.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> users = [];

  /// 🆕 بحث المستخدمين — لوحة الويندوز بس (الموبايل مش بيتأثر بيه).
  String _searchQuery = '';

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllUsers();
    final List<Map<String, dynamic>> enriched = [];

    for (final userRow in rows) {
      // اعمل نسخة قابلة للتعديل
      final user = Map<String, dynamic>.from(userRow);

      // 🆕 حساب السوبر ادمن مبيظهرش هنا — بيتدار من لوحة السوبر ادمن
      if (user['role'] == 'superadmin') continue;

      if (user['role'] == 'cashier' || user['role'] == 'waiter') {
        final settings = await DBHelper.getStaffSettings(user['id']);
        if (settings != null) {
          user['salary_per_hour'] = settings['salary_per_hour'];
          user['work_hours_per_day'] = settings['work_hours_per_day'];
        }
      }
      enriched.add(user);
    }

    setState(() => users = enriched);
  }

  /// الأدوار اللي بتاخد إعدادات راتب (staff_settings) — كاشير وموظف طلبات.
  bool _roleHasSalary(dynamic role) => role == 'cashier' || role == 'waiter';

  /// تسمية الدور بالعربي — بتستخدمها جسم الموبايل وجسم الويندوز.
  String _roleLabel(dynamic role) {
    switch (role) {
      case 'superadmin':
        return 'سوبر أدمن'.tr();
      case 'admin':
        return 'أدمن'.tr();
      case 'cashier':
        return 'كاشير — مدير الصالة'.tr();
      case 'waiter':
        return 'موظف طلبات'.tr();
      default:
        return '$role';
    }
  }

  void _showForm({Map<String, dynamic>? edit}) async {
    final userCtl = TextEditingController(text: edit?['username'] ?? '');
    final passCtl = TextEditingController(text: edit?['password'] ?? '');
    String role = edit?['role'] ?? 'cashier';

    // المشرف/الكاشير المسؤول — بيظهر لما الدور يكون «موظف طلبات (ويتر)».
    // الويتر بيتضاف كموظف فرعي مباشرة، وتقدر تضيف أكثر من ويتر لنفس المشرف.
    final supervisorOptions =
        users
            .where((u) => u['role'] == 'admin' || u['role'] == 'cashier')
            .toList();
    final supervisorIds =
        supervisorOptions.map((u) => (u['id'] as num).toInt()).toSet();
    final initialSupervisorId = (edit?['supervisor_id'] as num?)?.toInt();
    int? selectedSupervisorId =
        supervisorIds.contains(initialSupervisorId)
            ? initialSupervisorId
            : null;

    // إعدادات الموظف
    final settings =
        edit == null ? null : await DBHelper.getStaffSettings(edit['id']);
    final salaryCtl = TextEditingController(
      text: settings?['salary_per_hour']?.toString() ?? '',
    );
    final hoursCtl = TextEditingController(
      text: settings?['work_hours_per_day']?.toString() ?? '',
    );
    final daysOffCtl = TextEditingController(text: settings?['days_off'] ?? '');

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AppDialog(
                  title: Text(
                    edit == null ? 'إضافة مستخدم'.tr() : 'تعديل مستخدم'.tr(),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: userCtl,
                          decoration: InputDecoration(
                            labelText: 'اسم المستخدم'.tr(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: passCtl,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور'.tr(),
                          ),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: role,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'الدور'.tr(),
                            helperText:
                                'الكاشير بيدير الصالة وشيفتات الموظفين'.tr(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('أدمن — مدير النظام'.tr()),
                            ),
                            DropdownMenuItem(
                              value: 'cashier',
                              child: Text('كاشير — مدير الصالة'.tr()),
                            ),
                            DropdownMenuItem(
                              value: 'waiter',
                              child: Text('موظف طلبات (ويتر)'.tr()),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => role = v);
                          },
                        ),
                        if (role == 'waiter') ...[
                          SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            value: selectedSupervisorId ?? 0,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'المشرف / الكاشير المسؤول'.tr(),
                              helperText:
                                  'الويتر هيتضاف كموظف فرعي تحت المشرف ده. تقدر تضيف أكثر من ويتر — كل واحد حساب مستقل.'
                                      .tr(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('بدون مشرف — ويتر مستقل'.tr()),
                              ),
                              for (final s in supervisorOptions)
                                DropdownMenuItem(
                                  value: (s['id'] as num).toInt(),
                                  child: Text(
                                    '${s['username']} • ${_roleLabel(s['role'])}',
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              setDialogState(() {
                                selectedSupervisorId =
                                    (v == null || v == 0) ? null : v;
                              });
                            },
                          ),
                        ],
                        SizedBox(height: 5),
                        if (_roleHasSalary(role)) ...[
                          Divider(),
                          Text(
                            'إعدادات الراتب'.tr(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: salaryCtl,
                            decoration: InputDecoration(
                              labelText: 'الراتب بالساعة'.tr(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: hoursCtl,
                            decoration: InputDecoration(
                              labelText: 'عدد ساعات العمل اليومية'.tr(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إلغاء'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final u = userCtl.text.trim();
                        final p = passCtl.text.trim();
                        if (u.isEmpty || p.isEmpty) return;

                        final db = await DBHelper.database;
                        final waiterSupervisorId =
                            role == 'waiter' ? selectedSupervisorId : null;
                        int userId;

                        if (edit == null) {
                          userId = await DBHelper.insertUser({
                            'username': u,
                            'password': p,
                            'role': role,
                            'supervisor_id': waiterSupervisorId,
                          });
                        } else {
                          userId = edit['id'];
                          await db.update(
                            'users',
                            {
                              'password': p,
                              'role': role,
                              'supervisor_id': waiterSupervisorId,
                            },
                            where: 'id=?',
                            whereArgs: [userId],
                          );
                        }

                        // لو الدور كاشير أو موظف طلبات أضف إعدادات العمل
                        if (_roleHasSalary(role)) {
                          final salary = double.tryParse(salaryCtl.text) ?? 0.0;
                          final hours = int.tryParse(hoursCtl.text) ?? 8;
                          final daysOff = daysOffCtl.text.trim();

                          final existing = await DBHelper.getStaffSettings(
                            userId,
                          );
                          if (existing == null) {
                            await DBHelper.insertStaffSettings(
                              userId: userId,
                              salaryPerHour: salary,
                              workHoursPerDay: hours,
                              daysOff: daysOff,
                            );
                          } else {
                            await db.update(
                              'staff_settings',
                              {
                                'salary_per_hour': salary,
                                'work_hours_per_day': hours,
                                'days_off': daysOff,
                              },
                              where: 'user_id=?',
                              whereArgs: [userId],
                            );
                          }
                        }

                        Navigator.pop(context);
                        _load();
                      },
                      child: Text('حفظ'.tr()),
                    ),
                  ],
                ),
          ),
    );
  }

  void _confirmDeleteUser(int userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AppDialog(
            title: Text('تأكيد الحذف'.tr()),
            content: Text(
              'هل أنت متأكد من حذف المستخدم "{username}"؟'.tr({
                'username': username,
              }),
            ),
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
      await db.delete('users', where: 'id=?', whereArgs: [userId]);
      // لو فيه إعدادات الموظف، نحذفها أيضًا
      await db.delete(
        'staff_settings',
        where: 'user_id=?',
        whereArgs: [userId],
      );

      AppToast.show('تم حذف المستخدم "{username}"'.tr({'username': username}));
      _load(); // إعادة تحميل قائمة المستخدمين
    }
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
