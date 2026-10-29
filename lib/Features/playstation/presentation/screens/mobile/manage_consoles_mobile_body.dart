part of '../manage_consoles.dart';

/// جسم شاشة إدارة الأجهزة — نسخة الموبايل (زي ما كانت بالظبط).
extension _ManageConsolesScreenMobileBody on _ManageConsolesScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة الأجهزة'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: consoles.length,
                itemBuilder: (_, i) {
                  final c = consoles[i];

                  // ✅ تحديد إذا الجهاز محدد
                  final isSelected = c.id == selectedConsoleId;
                  final bgColor =
                      isSelected ? Colors.deepPurple.shade100 : Colors.white;

                  return Card(
                    //color: bgColor, // 🎯 هنا نغير لون الخلفية
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
                      title: Text(c.name),
                      subtitle: Text(
                          'سعر الساعة: {v1}'.tr({'v1': c.pricePerHour.toStringAsFixed(2)})),
                      onTap: () {
                        _refresh(() {
                          if (selectedConsoleId == c.id) {
                            selectedConsoleId =
                                null; // إلغاء الاختيار لو ضغط مرة ثانية
                          } else {
                            selectedConsoleId = c.id;
                          }
                        });
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showForm(edit: c),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              await DBHelper.deleteConsole(c.id!);
                              _load();
                            },
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
                label: Text('إضافة جهاز'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
