/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MaterialsInventoryScreen extends StatefulWidget {
  const MaterialsInventoryScreen({super.key});

  @override
  State<MaterialsInventoryScreen> createState() =>
      _MaterialsInventoryScreenState();
}

class _MaterialsInventoryScreenState extends State<MaterialsInventoryScreen> {
  List<Map<String, dynamic>> materials = [];
  Map<int, double> actualQty = {};
  Future<void> load() async {
    final db = await DBHelper.database;

    final result = await db.query(
      'raw_materials',
      orderBy: 'name',
    );

    materials = result.map((e) => Map<String, dynamic>.from(e)).toList();

    for (final m in materials) {
      actualQty[m['id']] = (m['qty'] as num).toDouble();
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> exportInventoryPdf() async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final regularFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Alexandria-Regular.ttf',
      ),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Amiri-Bold.ttf',
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                'تقرير جرد الخامات',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 24,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'تاريخ الجرد : ${DateTime.now().toString().substring(0, 10)}',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              cellAlignment: pw.Alignment.center,
              headerStyle: pw.TextStyle(
                font: boldFont,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey,
              ),
              cellStyle: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
              ),
              headers: const [
                'الخامة',
                'المسجل',
                'الفعلي',
                'الفرق',
                'الوحدة',
              ],
              data: materials.map((m) {
                final systemQty = (m['qty'] as num).toDouble();

                final actual = actualQty[m['id']] ?? systemQty;

                final diff = actual - systemQty;

                return [
                  m['name'].toString(),
                  systemQty.toStringAsFixed(2),
                  actual.toStringAsFixed(2),
                  diff.toStringAsFixed(2),
                  m['unit'].toString(),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return pdf.save();
      },
    );
  }

  Future<void> saveInventory() async {
    final db = await DBHelper.database;

    for (final m in materials) {
      final newQty = actualQty[m['id']] ?? (m['qty'] as num).toDouble();

      await db.update(
        'raw_materials',
        {
          'qty': newQty,
        },
        where: 'id=?',
        whereArgs: [m['id']],
      );
    }

    AppToast.show("✅ تم حفظ الجرد");

    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("جرد الخامات"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportInventoryPdf,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveInventory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: materials.length,
        itemBuilder: (_, i) {
          final m = materials[i];

          final systemQty = (m['qty'] as num).toDouble();

          final actual = this.actualQty[m['id']] ?? systemQty;

          final diff = actual - systemQty;

          Color diffColor = diff == 0
              ? Colors.grey
              : diff > 0
                  ? Colors.green
                  : Colors.red;

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "المسجل : $systemQty ${m['unit']}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: actual.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: "الكمية الفعلية",
                      suffixText: m['unit'],
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      this.actualQty[m['id']] = double.tryParse(v) ?? systemQty;

                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "الفرق : ",
                        ),
                        Text(
                          diff > 0 ? "+$diff" : diff.toString(),
                          style: TextStyle(
                            color: diffColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/material_unit.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/materials_inventory_screen_mobile_body.dart';
part 'desktop/materials_inventory_screen_windows_body.dart';

class MaterialsInventoryScreen extends StatefulWidget {
  const MaterialsInventoryScreen({super.key});

  @override
  State<MaterialsInventoryScreen> createState() =>
      _MaterialsInventoryScreenState();
}

class _MaterialsInventoryScreenState extends State<MaterialsInventoryScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  /// 📐 وحدات الخامات من إعدادات النشاط — بتتحمّل مع initState تحت.
  List<MaterialUnit> _units = BusinessProfile.defaultUnits;

  String formatQtyWithUnit(double qty, String unit) {
    // 📐 لو الوحدة ليها وحدة جزئية (كيلو ← جرام) والكمية أقل من 1،
    // نعرضها بالجزئية من إعدادات النشاط؛ وإلا العرض العادي بالوحدة نفسها.
    final hasSub = _units.any((u) => u.name == unit && u.hasSub);
    if (hasSub && qty.abs() > 0 && qty.abs() < 1) {
      final unitDef = _units.firstWhere((u) => u.name == unit && u.hasSub);
      final subQty = qty * unitDef.subFactor!;
      return "${subQty.toStringAsFixed(0)} ${unitDef.sub}";
    }

    if (qty.abs() < 0.0001) return "0 $unit";

    return "${qty.toStringAsFixed(2)} $unit";
  }

  double _cleanQty(double v) =>
      v.abs() < 0.0001 ? 0.0 : double.parse(v.toStringAsFixed(4));
  List<InventoryReportModel> reports = [];

  /// متحكمات حقول "الرصيد الفعلي" — بيتشاركوا بين جسم الموبايل وجسم الويندوز.
  Map<int, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    // 📐 وحدات الخامات من إعدادات النشاط — التنسيقات تتظبط فورًا بعد التحميل.
    BusinessProfile.getUnits().then((list) {
      if (mounted) setState(() => _units = list);
    });
    // 🆕 التقرير بيتحسب أول ما الشاشة تفتح (رصيد/مشتريات/استهلاك) —
    // مش محتاج تدوس «إعادة حساب الجرد» يدوي كل مرة.
    loadReport();
  }

  Future<void> loadReport() async {
    final db = await DBHelper.database;

    final materials = await db.query(
      'raw_materials',
      orderBy: 'name',
    );

    reports.clear();

    for (final m in materials) {
      final materialId = m['id'] as int;

      double openingQty = 0;
      double purchasesQty = 0;
      double consumedQty = 0;
      String formatDate(DateTime d) => d.toIso8601String().substring(0, 10);
      if (fromDate != null && toDate != null) {
        //-----------------------------------------
        // رصيد أول الفترة
        //-----------------------------------------
        final openingResult = await db.rawQuery(
          '''
SELECT
COALESCE(
SUM(
CASE
WHEN type='IN' THEN qty
ELSE -qty
END
),0
) balance
FROM material_transactions
WHERE material_id=?
AND substr(created_at,1,10) < ?
''',
          [materialId, formatDate(fromDate!)],
        );

        openingQty = ((openingResult.first['balance'] ?? 0) as num).toDouble();

        //-----------------------------------------
        // المشتريات خلال الفترة
        //-----------------------------------------
        final purchases = await db.rawQuery(
          '''
SELECT COALESCE(SUM(qty),0) total
FROM material_transactions
WHERE material_id=?
AND type='IN'
AND substr(created_at,1,10)
BETWEEN ? AND ?
''',
          [
            materialId,
            fromDate!.toIso8601String(),
            toDate!.toIso8601String(),
          ],
        );

        purchasesQty = ((purchases.first['total'] ?? 0) as num).toDouble();

        //-----------------------------------------
        // الاستهلاك خلال الفترة
        //-----------------------------------------
        final consumed = await db.rawQuery(
          '''
SELECT COALESCE(SUM(qty),0) total
FROM material_transactions
WHERE material_id=?
AND type='OUT'
AND substr(created_at,1,10)
 BETWEEN ? AND ?
''',
          [
            materialId,
            fromDate!.toString().substring(0, 10),
            toDate!.toString().substring(0, 10),
          ],
        );

        consumedQty = ((consumed.first['total'] ?? 0) as num).toDouble();
      } else {
        //-----------------------------------------
        // بدون فلترة => اعرض كل التاريخ
        //-----------------------------------------

        final purchases = await db.rawQuery(
          '''
SELECT COALESCE(SUM(qty),0) total
FROM material_transactions
WHERE material_id=?
AND type='IN'
''',
          [materialId],
        );

        purchasesQty = ((purchases.first['total'] ?? 0) as num).toDouble();

        final consumed = await db.rawQuery(
          '''
SELECT COALESCE(SUM(qty),0) total
FROM material_transactions
WHERE material_id=?
AND type='OUT'
''',
          [materialId],
        );

        consumedQty = ((consumed.first['total'] ?? 0) as num).toDouble();

        // اعرض الرصيد الحالي الحقيقي
        openingQty =
            ((m['qty'] ?? 0) as num).toDouble() + consumedQty - purchasesQty;
      }

      reports.add(
        InventoryReportModel(
          materialId: materialId,
          materialName: m['name'].toString(),
          unit: m['unit'].toString(),
          openingQty: openingQty,
          purchasesQty: purchasesQty,
          consumedQty: consumedQty,

          // الرصيد الفعلي الافتراضي
          actualQty: _cleanQty(openingQty + purchasesQty - consumedQty),
        ),
      );
    }

    if (!mounted) return; // الشاشة ممكن تتقفل أثناء الحساب
    setState(() {});
  }

  Future<void> approveInventory() async {
    final db = await DBHelper.database;

    for (final r in reports) {
      if (r.variance == 0) continue;

      await db.insert(
        'material_inventory_history',
        {
          'material_id': r.materialId,
          'old_qty': r.systemQty,
          'new_qty': r.actualQty,
          'difference': r.variance,
          'inventory_date': DateTime.now().toIso8601String(),
        },
      );

      await db.update(
        'raw_materials',
        {
          'qty': r.actualQty,
        },
        where: 'id=?',
        whereArgs: [r.materialId],
      );

      await db.insert(
        'material_transactions',
        {
          'material_id': r.materialId,
          'qty': r.variance.abs(),
          'type': r.variance > 0 ? 'IN' : 'OUT',
          'notes': 'تسوية جرد',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    }

    AppToast.show('تم اعتماد الجرد بنجاح'.tr());

    // 🆕 بعد الاعتماد نتأكد إن التقرير بيحدّث نفسه فورًا بعد تسوية الأرصدة.
    await loadReport();
  }

  Future<void> printPdf() async {
    final pdf = pw.Document();

    final regularFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Alexandria-Regular.ttf',
      ),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Amiri-Bold.ttf',
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'تقرير جرد الخامات'.tr(),
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 22,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'تاريخ التقرير : {v1}'.tr({'v1': DateTime.now().toString().substring(0, 10)}),
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
            ),
            cellStyle: pw.TextStyle(
              font: regularFont,
              fontSize: 11,
            ),
            headers:  [
              'الخامة',
              'رصيد أول الفترة'.tr(),
              'المضاف'.tr(),
              'المستهلك'.tr(),
              'رصيد النظام'.tr(),
              'الرصيد الفعلي'.tr(),
              'الفرق'.tr(),
            ],
            data: reports.map((e) {
              return [
                e.materialName,
                e.openingQty.toStringAsFixed(2),
                e.purchasesQty.toStringAsFixed(2),
                e.consumedQty.toStringAsFixed(2),
                e.systemQty.toStringAsFixed(2),
                e.actualQty.toStringAsFixed(2),
                e.variance.toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد الخامات: {v1}'.tr({'v1': reports.length}),
                style: pw.TextStyle(font: boldFont),
              ),
              pw.Text(
                'العجز: {v1}'.tr({'v1': reports.where((e) => e.isShortage).length}),
                style: pw.TextStyle(font: boldFont),
              ),
              pw.Text(
                'الزيادة: {v1}'.tr({'v1': reports.where((e) => e.isExcess).length}),
                style: pw.TextStyle(font: boldFont),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

class InventoryReportModel {
  int materialId;
  String materialName;
  String unit;

  double openingQty;
  double purchasesQty;
  double consumedQty;

  double actualQty;

  InventoryReportModel({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.openingQty,
    required this.purchasesQty,
    required this.consumedQty,
    required this.actualQty,
  });

  double get systemQty => double.parse(
      (openingQty + purchasesQty - consumedQty).toStringAsFixed(4));

  double get variance =>
      double.parse((actualQty - systemQty).toStringAsFixed(4));

  bool get isShortage => variance < 0;

  bool get isExcess => variance > 0;
}
