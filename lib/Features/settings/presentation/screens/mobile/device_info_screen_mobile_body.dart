part of '../device_info_screen.dart';

/// جسم شاشة مواصفات الجهاز — نسخة الموبايل (زي ما كانت بالظبط).
extension _DeviceInfoMobileBody on _DeviceInfoScreenState {
  Widget _infoTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: SelectableText(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            AppToast.show('تم النسخ'.tr());
          },
        ),
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('مواصفات هذا الجهاز'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'نسخ التقرير الكامل'.tr(),
            onPressed: _loading
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _fullReport));
                    AppToast.show('تم نسخ كل المواصفات — جاهزة للإرسال'.tr());
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                 Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'ابعت الكود ده كامل للمهندس عند التفعيل أو لو حصلت مشكلة بعد تغيير قطعة في الجهاز.'.tr(),
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                _infoTile('كود الجهاز الكامل (المستخدم في القفل)'.tr(), _hash),
                _infoTile('CPU ID', _cpu),
                _infoTile('Motherboard ID', _board),
                _infoTile('Disk ID', _disk),
              ],
            ),
    );
  }
}
