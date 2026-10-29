import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:saytarly/core/localization/messages.dart';

/// طباعة تقرير جرد لكل الخامات المسجلة (اسم الخامة + الكمية المتاحة + الوحدة)
/// على ورق حراري 70مم، بنفس أسلوب باقي تقارير المحل (خط Alexandria + RTL)
Future<void> printMaterialsInventoryReport(
  List<Map<String, dynamic>>
      materials, // كل عنصر لازم يحتوي name, qty, unit, min_qty
) async {
  final fontData = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Alexandria-Bold.ttf'),
  );

  final qtyFormatter = NumberFormat('#,##0.##');

  // ترتيب الخامات أبجديًا حسب الاسم
  final sortedMaterials = [...materials]..sort((a, b) =>
      (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

  final lowStockCount = sortedMaterials.where((m) {
    final qty = (m['qty'] as num?)?.toDouble() ?? 0;
    final minQty = (m['min_qty'] as num?)?.toDouble() ?? 0;
    return qty <= minQty;
  }).length;

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(70 * PdfPageFormat.mm, double.infinity),
      margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
      theme: pw.ThemeData.withFont(base: fontData, bold: boldFont),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'جرد الخامات'.tr(),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'التاريخ: {v1}'.tr({'v1': DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now())}),
                style: pw.TextStyle(font: fontData, fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),

              // 🧾 قائمة الخامات والكميات
              ...sortedMaterials.map((m) {
                final name = m['name'] ?? 'غير معروف'.tr();
                final qty = (m['qty'] as num?)?.toDouble() ?? 0;
                final minQty = (m['min_qty'] as num?)?.toDouble() ?? 0;
                final unit = m['unit'] ?? '';
                final isLow = qty <= minQty;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          isLow ? '(ناقص) {name}'.tr({'name': name}) : name,
                          style: pw.TextStyle(
                            font: isLow ? boldFont : fontData,
                            fontSize: 11,
                            color: isLow ? PdfColors.red800 : PdfColors.black,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${qtyFormatter.format(qty)} $unit',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          color: isLow ? PdfColors.red800 : PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),

              // 📊 ملخص الجرد
              pw.Text(
                'إجمالي عدد الخامات: {v1}'.tr({'v1': sortedMaterials.length}),
                style: pw.TextStyle(font: fontData, fontSize: 10),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'خامات ناقصة: {lowStockCount}'.tr({'lowStockCount': lowStockCount}),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: PdfColors.red800,
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'تم الطباعة بواسطة النظام'.tr(),
                  style: pw.TextStyle(font: fontData, fontSize: 9),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
}
