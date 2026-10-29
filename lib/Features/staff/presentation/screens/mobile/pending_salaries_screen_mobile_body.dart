part of '../PendingSalariesScreen.dart';

/// جسم مستحقات الموظفين — نسخة الموبايل (زي ما كانت بالظبط).
extension _PendingSalariesScreenMobileBody on _PendingSalariesScreenState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مستحقات الموظفين'.tr())),
      body: pending.isEmpty
          ? Center(child: Text('لا توجد مستحقات حتى الآن'.tr()))
          : ListView.builder(
              itemCount: pending.length,
              itemBuilder: (_, index) {
                final p = pending[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text("${p['staff_name']}"),
                    subtitle: Text(('الساعات: {v1}\n'.tr({'v1': p['total_hours']}) + 'الصافي: {v1}\n'.tr({'v1': p['total_net']}) + 'آخر تاريخ: {v1}'.tr({'v1': _formatArabicDateTime(p['last_date'])}))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.info),
                          onPressed: () =>
                              _showDetailsSheet(p['staff_id'], p['staff_name']),
                        ),
                        ElevatedButton(
                          onPressed: () => _pay(
                            p['staff_id'],
                            p['total_net'],
                            p['staff_name'],
                          ),
                          child: Text('صرف'.tr()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
