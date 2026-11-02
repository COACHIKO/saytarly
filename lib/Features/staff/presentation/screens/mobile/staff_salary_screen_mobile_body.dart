part of '../StaffSalaryScreen.dart';

/// جسم صرف مرتبات الموظفين — نسخة الموبايل (زي ما كانت بالظبط).
extension _StaffSalaryScreenMobileBody on _StaffSalaryScreenState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صرف مرتبات الموظفين'.tr()),
      ),
      body: ListView(
        children: staff.map((u) {
          return ListTile(
            title: Text(u['username']),
            subtitle: Text('مستحق: {v1} {v2}'.tr({'v1': u['net'].toStringAsFixed(2), 'v2': Money.txt})),
            trailing: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final already = await DBHelper.isSalaryPaid(u['id'], month);
                    if (already) {
                      AppToast.show('تم صرف هذا الشهر مسبقًا'.tr());
                      return;
                    }
                    await _pay(u['id']);
                  },
                  child: Text('صرف'.tr()),
                ),
                IconButton(
                  icon: Icon(Icons.history),
                  onPressed: () async {
                    final hist = await _history(u['id']);
                    if (!mounted) return; // الشاشة قفلت — ما نلمس contextش
                    showDialog(
                      context: context,
                      builder: (_) => AppDialog(
                        title: Text('تاريخ الصرف - {v1}'.tr({'v1': u['username']})),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: hist.map((h) {
                              return ListTile(
                                title: Text('شهر: {v1}'.tr({'v1': h['month']})),
                                subtitle: Text('تاريخ: {v1}'.tr({'v1': h['paid_at']})),
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('إغلاق'.tr()))],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
