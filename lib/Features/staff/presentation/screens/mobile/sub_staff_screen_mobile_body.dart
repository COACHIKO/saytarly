part of '../SubStaffScreen.dart';

/// جسم الموظفين الفرعيين — نسخة الموبايل (زي ما كانت بالظبط).
extension _SubStaffScreenMobileBody on _SubStaffScreenState {
  Widget _buildShiftButton(Map<String, dynamic> u) {
    final isWorking = u['shift_start'] != null && u['shift_end'] == null;

    return ElevatedButton(
      onPressed: () async {
        final now = DateTime.now();
        // 🌿 الفروع: شيفت الموظف الفرعي بيتسجل على شيفت الكاشير المفتوح
        // — عشان التحاسب ياخد مالكه الصح حتى لو شغّال عند كاشيرات كتير.
        if (!isWorking) {
          final openShiftId = await DBHelper.getOpenShiftId(
            widget.supervisorId,
          );
          if (openShiftId == null) {
            AppToast.show('افتح شيفت الكاشير الأول بدءًا من شاشة البداية'.tr());
            return;
          }
          await DBHelper.startShiftForSubStaff(
            staffId: u['id'] as int,
            supervisorShiftId: openShiftId,
            startTime: now.toIso8601String(),
          );
        } else {
          final openShiftId = await DBHelper.getOpenShiftId(
            widget.supervisorId,
          );
          await DBHelper.endStaffShift(
            u['id'] as int,
            now,
            supervisorShiftId: openShiftId ?? 0,
          );
        }
        _loadSubStaff();
      },
      child: Text(isWorking ? 'إنهاء'.tr() : 'بدء'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: isWorking ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الموظفين الفرعيين'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: subStaff.length,
                itemBuilder: (_, i) {
                  final u = subStaff[i];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      title: Text(u['username']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الراتب بالساعة: {v1}'.tr({
                              'v1': u['salary_per_hour'] ?? 'غير محدد'.tr(),
                            }),
                          ),
                          // 🌿 لو متعيين عند كاشيرات كمان — تنبيه إن حذفه
                          // من هنا مش هيشيله من هناك.
                          if (((u['assign_count'] ?? 0) as num) > 1)
                            Text(
                              'متعيّن عند كاشيرات تانية ({v1}) — إزالته من هنا مش هتشيله منهم'.tr({
                                'v1': ((u['assign_count'] as num) - 1).toString(),
                              }),
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          if (u['shift_start'] != null)
                            Text(
                              'بدأت العمل: {v1}'.tr({
                                'v1': DateFormat(
                                  'HH:mm',
                                ).format(DateTime.parse(u['shift_start'])),
                              }),
                            ),
                          if (u['shift_end'] != null)
                            Text(
                              'انتهت: {v1}'.tr({
                                'v1': DateFormat(
                                  'HH:mm',
                                ).format(DateTime.parse(u['shift_end'])),
                              }),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildShiftButton(u),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showForm(edit: u),
                          ),
                          IconButton(
                            icon: Icon(Icons.link_off),
                            tooltip: 'إزالة من الشيفت'.tr(),
                            onPressed: () => _removeSubStaff(u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text('تعيين ويتر موجود'.tr()),
                ),
                ElevatedButton.icon(
                  onPressed: _createWaiterSubStaff,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text('ويتر جديد'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
