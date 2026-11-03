import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/manage_users_mobile_body.dart';
part 'desktop/manage_users_windows_body.dart';

/// إدارة المستخدمين — شجرة الفريق 🌿
///
/// الفكرة: الكاشير (والأدمن) جذور، وموظف الطلبات بيظهر كورقة تتفرع من
/// الجذر اللي بيشتغل تحته. الويتر الواحد يقدر يشتغل تحت أكتر من كاشير
/// في نفس الوقت — فبيرجع كورقة تحت كل واحد فيهم عادي جدًا.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> users = [];

  /// 🌿 فروع التعيين: waiterId → كل المشرفين اللي بيشتغل تحتهم.
  /// خريطة الشجرة نفسها — بيتحدث من الجدول sub_staff_assignments.
  final Map<int, List<int>> assignments = {};

  /// بحث المستخدمين — لوحة الويندوز بس (الموبايل مش بيتأثر بيه).
  String _searchQuery = '';

  /// 👆 أي جذور موسّعة في الموبايل (الويندوز بيدايق التفاصيل دايمًا).
  final Set<int> _expandedSupervisors = {};

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllUsers();
    final assignmentRows = await DBHelper.getAllStaffAssignments();

    final List<Map<String, dynamic>> enriched = [];
    final Map<int, List<int>> branches = {};

    for (final row in assignmentRows) {
      final waiterId = (row['waiter_id'] as num?)?.toInt();
      final supervisorId = (row['supervisor_id'] as num?)?.toInt();
      if (waiterId == null || supervisorId == null) continue;
      branches.putIfAbsent(waiterId, () => []).add(supervisorId);
    }

    for (final userRow in rows) {
      final user = Map<String, dynamic>.from(userRow);

      // السوبر ادمن مبيظهرش هنا — بيتدار من لوحة السوبر ادمن
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

    if (!mounted) return;
    setState(() {
      users = _sortUsers(enriched);
      assignments
        ..clear()
        ..addAll(branches);
      // تأكد إن كاشيرات الشجرة مفتوحين بشكل افتراضي في الموبايل
      _expandedSupervisors.addAll(
        users
            .where(
              (u) => u['role'] == 'cashier' && _childrenOfUser(u).isNotEmpty,
            )
            .map((u) => (u['id'] as num).toInt()),
      );
    });
  }

  /// الترتيب: أدمن → كاشير → ويتر، وكل مجموعة بأسماء أبجدية.
  List<Map<String, dynamic>> _sortUsers(
    List<Map<String, dynamic>> input,
  ) {
    int weight(Map<String, dynamic> u) => switch (u['role'] as String? ?? '') {
      'admin' => 0,
      'cashier' => 1,
      'waiter' => 2,
      _ => 3,
    };
    final list = [...input];
    list.sort((a, b) {
      final w = weight(a).compareTo(weight(b));
      if (w != 0) return w;
      return (a['username'] as String? ?? '').compareTo(
        b['username'] as String? ?? '',
      );
    });
    return list;
  }

  // ============================ علاقات الشجرة ============================

  bool _isBranchRole(dynamic role) => role == 'admin' || role == 'cashier';

  /// أدوار بتاخد إعدادات راتب (staff_settings) — كاشير وموظف طلبات.
  bool _roleHasSalary(dynamic role) => role == 'cashier' || role == 'waiter';

  /// تسمية الدور بالعربي — بتستخدم جسم الموبايل وجسم الويندوز.
  String _roleLabel(dynamic role) {
    switch (role) {
      case 'superadmin':
        return 'سوبر أدمن'.tr();
      case 'admin':
        return 'أدمن — مدير النظام'.tr();
      case 'cashier':
        return 'كاشير — مدير الصالة'.tr();
      case 'waiter':
        return 'موظف طلبات'.tr();
      default:
        return '$role';
    }
  }

  int _userId(Map<String, dynamic> u) => (u['id'] as num).toInt();

  /// أطفال الجذر ده — الويترات اللي بيشتغلوا تحته مباشرة.
  /// ترتيبهم: المشرف الأساسي الأول (supervisor_id) وبعده الباقي.
  List<Map<String, dynamic>> _childrenOfUser(Map<String, dynamic> root) {
    final rootId = _userId(root);
    final children =
        users
            .where((u) => u['role'] == 'waiter')
            .where((u) => _supervisorIdsOf(u).contains(rootId))
            .toList();
    children.sort((a, b) {
      final primaryA = a['supervisor_id'] == rootId;
      final primaryB = b['supervisor_id'] == rootId;
      if (primaryA != primaryB) return primaryA ? -1 : 1;
      return (a['username'] as String? ?? '').compareTo(
        b['username'] as String? ?? '',
      );
    });
    return children;
  }

  /// كل المشرفين اللي الموظف بيشتغل تحتهم.
  List<int> _supervisorIdsOf(Map<String, dynamic> user) {
    return assignments[_userId(user)] ?? const <int>[];
  }

  /// الويترات اللي مالهمش أي جذر — بيتجمعوا في عقدة جانبية مستقلة.
  List<Map<String, dynamic>> get _independentStaff =>
      users
          .where((u) => u['role'] == 'waiter')
          .where((u) => _supervisorIdsOf(u).isEmpty)
          .toList();

  /// أسماء المشرفين اللي ويتر معلّق عندهم (لعرض chip «شغال تحت …»).
  List<String> _supervisorNamesOf(Map<String, dynamic> user) {
    final names = users
        .where((u) => _isBranchRole(u['role']))
        .where((u) => _supervisorIdsOf(user).contains(_userId(u)))
        .map((u) => u['username'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    return names;
  }

  /// من غير حرف «فرعي» في كل النص — الشجرة هي اللي بتوصف العلاقة.
  String _underLabel(Map<String, dynamic> user) {
    final names = _supervisorNamesOf(user);
    if (names.isEmpty) return 'فريق مستقل'.tr();
    if (names.length == 1) return 'شغال تحت {n}'.tr({'n': names.first});
    return 'شغال تحت {n} كاشير'.tr({'n': names.join('، '.tr())});
  }

  // ============================ التعديل والحفظ ============================

  void _showForm({Map<String, dynamic>? edit}) async {
    final userCtl = TextEditingController(text: edit?['username'] ?? '');
    final passCtl = TextEditingController(text: edit?['password'] ?? '');
    final initialRole = edit?['role'];
    String role = (initialRole == 'admin' ||
            initialRole == 'cashier' ||
            initialRole == 'waiter')
        ? initialRole as String
        : 'cashier';

    // الخطوط الرأسية 🌿: الويتر يقدر يتسجّل تحت أكتر من كاشير بنفس الوقت.
    // الكاشير والأدمن هوما الجذور المتاحة للموظف الجديد.
    final branchOptions =
        users.where((u) => _isBranchRole(u['role'])).toList();
    final branchIds = branchOptions.map(_userId).toSet();
    final Set<int> branchSelection = edit == null
        ? <int>{}
        : _supervisorIdsOf(edit).where(branchIds.contains).toSet();

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

    if (!mounted) return; // الشاشة قفلت أثناء تحميل الإعدادات — ما نلمس contextش
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
                          initialValue: role,
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
                              child: Text('موظف طلبات'.tr()),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => role = v);
                          },
                        ),
                        if (role == 'waiter') ...[
                          SizedBox(height: 14),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'يشتغل تحت مين؟'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'اختار أكتر من كاشير لو الموظف هيغطي أكتر من شيفت في نفس الوقت.'
                                .tr(),
                            style: Theme.of(dialogContext).textTheme.bodySmall,
                          ),
                          SizedBox(height: 8),
                          if (branchOptions.isEmpty)
                            Text(
                              'ضيف كاشير الأول — الموظف شغاله تابيع ليه.'
                                  .tr(),
                              style: TextStyle(
                                color: Theme.of(dialogContext).colorScheme.error,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final s in branchOptions)
                                  FilterChip(
                                    label: Text(
                                      '${s['username']} • ${_roleLabel(s['role'])}',
                                    ),
                                    selected: branchSelection.contains(
                                      _userId(s),
                                    ),
                                    onSelected: (on) => setDialogState(() {
                                      on
                                          ? branchSelection.add(
                                            _userId(s),
                                          )
                                          : branchSelection.remove(
                                            _userId(s),
                                          );
                                    }),
                                  ),
                              ],
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
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('إلغاء'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final u = userCtl.text.trim();
                        final p = passCtl.text.trim();
                        if (u.isEmpty || p.isEmpty) return;

                        final db = await DBHelper.database;
                        final waiterSupervisors =
                            role == 'waiter' ? branchSelection : <int>{};
                        // المشرف الأساسي — أول واحد متعين عنده (للتوافق مع
                        // الشاشات القديمة اللي بتقرأ supervisor_id).
                        final primarySupervisorId =
                            waiterSupervisors.isEmpty ? null : waiterSupervisors.first;
                        int userId;

                        if (edit == null) {
                          userId = await DBHelper.insertUser({
                            'username': u,
                            'password': p,
                            'role': role,
                            'supervisor_id': primarySupervisorId,
                          });
                        } else {
                          userId = edit['id'];
                          await db.update(
                            'users',
                            {
                              'password': p,
                              'role': role,
                              'supervisor_id': primarySupervisorId,
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

                        // 🌿 مزامنة فروع التعيين: نمسح المصدوف ونزرع الجديد —
                        // كده الويتر قادر يتحط تحت كاشيرين وبيدخل تحت الاتنين
                        // في نفس الوقت، والشجرة تعيد رسم نفسها.
                        if (role == 'waiter') {
                          await DBHelper.unassignAllWaiters(userId);
                          for (final supId in waiterSupervisors) {
                            await DBHelper.assignWaiterToSupervisor(
                              waiterId: userId,
                              supervisorId: supId,
                            );
                          }
                          // المشرف الأساسي يتسجل صريحًا حتى لو كان قبل كده
                          // عنده مشرف تاني.
                          await db.update(
                            'users',
                            {'supervisor_id': primarySupervisorId},
                            where: 'id=?',
                            whereArgs: [userId],
                          );
                        } else {
                          await DBHelper.unassignAllWaiters(userId);
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _load();
                      },
                      child: Text('حفظ'.tr()),
                    ),
                  ],
                ),
          ),
    );
  }

  /// 🌿 فصل الموظف من جذر واحد بس — فرعه عند كاشيرات تانيين بيفضل شغال.
  Future<void> _detachFromSupervisor(
    Map<String, dynamic> waiter,
    Map<String, dynamic> supervisor,
  ) async {
    final waiterId = _userId(waiter);
    final supervisorId = _userId(supervisor);

    await DBHelper.unassignWaiterFromSupervisor(
      waiterId: waiterId,
      supervisorId: supervisorId,
    );

    // لو المشرف المفصول ده كان الأساسي، نمرر الدور لأي مشرف تاني موجود،
    // وإلا الموظف بيرجع مستقل.
    final remaining = _supervisorIdsOf(waiter).where((id) => id != supervisorId).toList();
    final nextPrimary =
        waiter['supervisor_id'] == supervisorId
            ? (remaining.isEmpty ? null : remaining.first)
            : (waiter['supervisor_id'] as num?)?.toInt();
    final db = await DBHelper.database;
    await db.update(
      'users',
      {'supervisor_id': nextPrimary},
      where: 'id=?',
      whereArgs: [waiterId],
    );

    AppToast.show(
      remaining.isEmpty
          ? '«{n}» بقى فريق مستقل'.tr({'n': waiter['username']})
          : 'تم الفصل من عند {n} — ولسه شغال تحت مشرفين تانيين'.tr({
            'n': supervisor['username'],
          }),
    );
    _load();
  }

  /// 🌿 إسقاط ورقة على جذر — بيربط الموظف بالكاشير ده زيادة على مشرفينه
  /// الحاليين (يعني ممكن يكون متفرّع تحت أكتر من كاشير في نفس الوقت،
  /// والإسقاط على جذر تاني بيعمل جذر إضافي — التحرير بيقدّر مسألة كاملة).
  Future<void> _attachWaiterToSupervisor(
    Map<String, dynamic> waiter,
    Map<String, dynamic> supervisor,
  ) async {
    final waiterId = _userId(waiter);
    final supId = _userId(supervisor);
    if (waiterId == supId) return;

    if (_supervisorIdsOf(waiter).contains(supId)) {
      AppToast.show(
        '«{n}» شغال تحت {u} من قبل'.tr({
          'n': waiter['username'] ?? '',
          'u': supervisor['username'] ?? '',
        }),
      );
      _load();
      return;
    }

    await DBHelper.assignWaiterToSupervisor(
      waiterId: waiterId,
      supervisorId: supId,
    );

    // بعد السقوط نفتوح فرع الجذر ده — الويتر يبان قدامك فورًا (المطوي
    // ممكن يحس إن السحب أهمل) — على الديسكتوب المجموعة المفتوحة بلا أثر.
    _expandedSupervisors.add(supId);

    AppToast.show(
      '«{n}» بقى متفرّع تحت {u} 🌿'.tr({
        'n': waiter['username'] ?? '',
        'u': supervisor['username'] ?? '',
      }),
    );
    _load();
  }

  void _confirmDeleteUser(int userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AppDialog(
            title: Text('تأكيد الحذف'.tr()),
            content: Text(
              'هل أنت متأكد من حذف المستخدم "{username}"؟'.tr({
                'username': username,
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
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
      // 🌿 تنظيف فروع التعيين بتاعته كويتر أو كمشرف — عشان ما يفضلش
      // ويتر معلّق عند كاشير اتحذف أو العكس.
      await DBHelper.deleteUserAssignments(userId);

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
