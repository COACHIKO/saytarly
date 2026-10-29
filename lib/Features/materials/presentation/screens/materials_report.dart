import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/materials_report_mobile_body.dart';
part 'desktop/materials_report_windows_body.dart';

class MaterialsReportScreen extends StatefulWidget {
  const MaterialsReportScreen({super.key});

  @override
  State<MaterialsReportScreen> createState() => _MaterialsReportScreenState();
}

class _MaterialsReportScreenState extends State<MaterialsReportScreen> {
  List<Map<String, dynamic>> data = [];

  Future<void> load() async {
    final db = await DBHelper.database;

    data = await db.rawQuery(
      '''
      SELECT *
      FROM raw_materials
      WHERE qty <= min_qty
      ''',
    );

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
