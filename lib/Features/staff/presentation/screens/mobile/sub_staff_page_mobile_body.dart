part of '../SubStaffPage.dart';

/// جسم الموظفين الفرعيين — نسخة الموبايل (زي ما كانت بالظبط).
extension _SubStaffPageMobileBody on _SubStaffPageState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('الموظفين الفرعيين'.tr()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: editableSubStaff.length,
                itemBuilder: (context, i) {
                  final staff = editableSubStaff[i];
                  final staffName = staff['username'] ?? 'غير معروف'.tr();
                  final shiftStartStr = staff['shift_start'];
                  final shiftEndStr = staff['shift_end'];
                  final salaryPerHour =
                      (staff['salary_per_hour'] ?? 0.0) as double;

                  bool isWorking = shiftStartStr != null && shiftEndStr == null;
                  double workedHours = 0.0;
                  double earned = 0.0;

                  if (shiftStartStr != null) {
                    final start = DateTime.parse(shiftStartStr);
                    final end = shiftEndStr != null
                        ? DateTime.parse(shiftEndStr)
                        : DateTime.now();
                    workedHours = end.difference(start).inSeconds / 3600;
                    earned = workedHours * salaryPerHour;
                  }

                  return Card(
                      margin:  EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      child: Padding(
                        padding:  EdgeInsets.symmetric(
                            vertical: 8), // المسافة الرأسية
                        child: ListTile(
                          title: Text(staffName),
                          subtitle: shiftStartStr != null
                              ? Text(
                                  'المدة: {v1} ساعة'.tr({'v1': workedHours.toStringAsFixed(2)}))
                              : null,
                          trailing: ElevatedButton(
                            onPressed: () => _toggleShift(staff),
                            child: Text(isWorking ? 'إنهاء'.tr() : 'بدء'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isWorking ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ));
                },
              ),
            ),
    );
  }
}
