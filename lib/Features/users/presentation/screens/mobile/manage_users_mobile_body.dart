part of '../manage_users.dart';

/// جسم شاشة إدارة المستخدمين — نسخة الموبايل (زي ما كانت بالظبط).
extension _ManageUsersScreenMobileBody on _ManageUsersScreenState {

  Widget _buildMobileBody(BuildContext context) {
    void _showSalariesReport() async {
      final now = DateTime.now();
      final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      List<Map<String, dynamic>> salaries = [];

      for (final u in users) {
        if (u['role'] == 'cashier' || u['role'] == 'waiter') {
          final net = await DBHelper.calculateMonthlySalary(u['id'], month);
          salaries.add({
            'name': u['username'],
            'net_salary': net.toStringAsFixed(2),
          });
        }
      }

      showDialog(
        context: context,
        builder: (_) => AppDialog(
          title: Text('رواتب الشهر {month}'.tr({'month': month})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: salaries.map((s) {
              return ListTile(
                title: Text(s['name']),
                trailing: Text('${s['net_salary']} ${Money.txt}'),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'.tr()),
            ),
          ],
        ),
      );
    }
    /*  void _showSalariesReport() async {
      final now = DateTime.now();
      final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      List<Map<String, dynamic>> salaries = [];

      for (final u in users) {
        if (u['role'] == 'cashier' || u['role'] == 'waiter') {
          final net = await DBHelper.calculateMonthlySalary(u['id'], month);
          salaries.add({
            'id': u['id'], // مهم للزر
            'name': u['username'],
            'net_salary': net,
          });
        }
      }

      showDialog(
        context: context,
        builder: (_) => AppDialog(
          title: Text('رواتب الشهر $month'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: salaries.map((s) {
              return ListTile(
                title: Text(s['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${s['net_salary'].toStringAsFixed(2)} ${Money.txt}'),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final userId = s['id'];
                        final amount = s['net_salary'];

                        // 1) إضافة كمصروف
                        await DBHelper.addExpense(
                          description: "صرف راتب ${s['name']}",
                          amount: amount,
                          shiftId: 1, // أو أي شيفت مناسب
                          addedBy: "Admin",
                        );

                        // 2) تحديث جدول المستحقات ليصبح مدفوع
                        await DBHelper.markSalaryPaid(userId, month);

                        AppToast.show('تم صرف الراتب لـ ${s['name']}');

                        Navigator.pop(context);
                      },
                      child: Text("صرف"),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
          ],
        ),
      );
    }*/

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المستخدمين'.tr()),
        /*actions: [
          IconButton(
            icon: Icon(Icons.payments),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StaffSalaryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: _showSalariesReport,
          )
        ],*/
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.deepPurple.withOpacity(0.4),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(u['username']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الدور: {v1}'.tr({'v1': _roleLabel(u['role'])})),
                          if (u['role'] == 'cashier' || u['role'] == 'waiter')
                            Text(
                                'الراتب بالساعة: {v1}'.tr({'v1': u['salary_per_hour'] ?? 'غير محدد'.tr()})),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (u['role'] == 'admin' || u['role'] == 'cashier')
                            IconButton(
                              icon: Icon(Icons.group),
                              tooltip: 'الموظفين الفرعيين'.tr(),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SubStaffScreen(supervisorId: u['id']),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showForm(edit: u),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.red,
                            tooltip: 'حذف المستخدم'.tr(),
                            onPressed: () =>
                                _confirmDeleteUser(u['id'], u['username']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: Icon(Icons.add),
                label: Text('إضافة مستخدم'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

