part of '../materials_report.dart';

/// جسم الخامات الناقصة — نسخة الموبايل (زي ما كانت بالظبط).
extension _MaterialsReportScreenMobileBody on _MaterialsReportScreenState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('الخامات الناقصة'.tr()),
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (_, i) {
          final m = data[i];

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.warning,
                color: Colors.red,
              ),
              title: Text(m['name']),
              subtitle: Text(
                'المتبقي {v1} {v2}'.tr({'v1': m['qty'], 'v2': m['unit']}),
              ),
            ),
          );
        },
      ),
    );
  }
}

