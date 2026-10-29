/*
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart' as gfonts;

Future<void> printInvoiceReport({
  required int shiftId,
  required List<Map<String, dynamic>> invoices,
  required double totalDevice,
  required double totalDrinks,
  required double totalAll,
  required String staffName,
}) async {
  // تحميل خط Cairo من Google Fonts
  final fontData = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
  );
  final boldFont =  pw.Font.ttf(
    await rootBundle.load('assets/fonts/Alexandria-Bold.ttf'),
  );

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
          58 * PdfPageFormat.mm, double.infinity), // عرض ورقة حرارية 58مم
      margin: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
      theme: pw.ThemeData.withFont(base: fontData, bold: boldFont),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'تقرير نهاية الشيفت',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'الموظف: $staffName',
                style: pw.TextStyle(font: fontData, fontSize: 10),
              ),
              pw.Text(
                'الوقت: ${DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now())}',
                style: pw.TextStyle(font: fontData, fontSize: 10),
              ),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Text(
                'الفواتير المسجلة:',
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
              pw.SizedBox(height: 3),
              ...invoices.map((inv) {
                final console = inv["console_name"] ?? "غير محدد";
                final total = (inv["total"] ?? 0).toDouble();
                final drinks = (inv["drinks_cost"] ?? 0).toDouble();
                final device = (inv["device_cost"] ?? 0).toDouble();
                final time = inv["start_time"] != null
                    ? DateFormat('HH:mm')
                        .format(DateTime.parse(inv["start_time"]))
                    : "-";

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('🎮 ${console.name}',
                          style: pw.TextStyle(font: fontData, fontSize: 10)),
                      pw.Text('⏰ $time',
                          style: pw.TextStyle(font: fontData, fontSize: 9)),
                      pw.Text('💰 الجهاز: ${device.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: fontData, fontSize: 9)),
                      pw.Text('🥤 المشروبات: ${drinks.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: fontData, fontSize: 9)),
                      pw.Text('الإجمالي: ${total.toStringAsFixed(2)} ${Money.txt}',
                          style: pw.TextStyle(font: boldFont, fontSize: 10)),
                      pw.Divider(thickness: 0.3),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),
              pw.Text(
                'ملخص الشيفت:',
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
              pw.SizedBox(height: 3),
              pw.Text('إجمالي الأجهزة: ${totalDevice.toStringAsFixed(2)} ${Money.txt}',
                  style: pw.TextStyle(font: fontData, fontSize: 10)),
              pw.Text('إجمالي المشروبات: ${totalDrinks.toStringAsFixed(2)} ${Money.txt}',
                  style: pw.TextStyle(font: fontData, fontSize: 10)),
              pw.Text(
                'إجمالي الكلي: ${totalAll.toStringAsFixed(2)} ${Money.txt}',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'شكرًا لجهودك ❤️',
                  style: pw.TextStyle(font: fontData, fontSize: 10),
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
*/
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

Future<void> printInvoiceReport({
  required int shiftId,
  required List<Map<String, dynamic>> invoices,
  required double totalDevice,
  required double totalDrinks,
  required double totalAll,
  required String staffName,
  double totalPaid = 0, // 🆕 إجمالي المدفوع (كاش + شحن)
  double totalDebtRemaining = 0, // 🆕 إجمالي الآجل المتبقي (لسه مش متحصل)
  double totalDebtCollected = 0, // 🆕 اللي اتحصل من الآجل في الشيفت ده
}) async {
  final fontData = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Alexandria-Bold.ttf'),
  );

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
      margin: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
      theme: pw.ThemeData.withFont(base: fontData, bold: boldFont),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'تقرير نهاية الشيفت'.tr(),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('الموظف: {staffName}'.tr({'staffName': staffName}),
                  style: pw.TextStyle(font: fontData, fontSize: 10)),
              pw.Text(
                'الوقت: {v1}'.tr({'v1': DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now())}),
                style: pw.TextStyle(font: fontData, fontSize: 10),
              ),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Text('الفواتير المسجلة:'.tr(),
                  style: pw.TextStyle(font: boldFont, fontSize: 12)),
              pw.SizedBox(height: 3),
              ...invoices.map((inv) {
                final consoleName = inv["console_name"] ?? 'غير محدد'.tr();
                final total = (inv["total"] ?? 0).toDouble();
                final drinks = (inv["drinks_cost"] ?? 0).toDouble();
                final device = (inv["device_cost"] ?? 0).toDouble();
                final time = inv["start_time"] != null
                    ? DateFormat('HH:mm')
                        .format(DateTime.parse(inv["start_time"]))
                    : "-";

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('🎮 $consoleName',
                          style: pw.TextStyle(font: fontData, fontSize: 10)),
                      pw.Text('⏰ $time',
                          style: pw.TextStyle(font: fontData, fontSize: 9)),
                      pw.Text('💰 الجهاز: {v1}'.tr({'v1': device.toStringAsFixed(2)}),
                          style: pw.TextStyle(font: fontData, fontSize: 9)),
                      pw.Text('🥤 المشروبات: {v1}'.tr({'v1': drinks.toStringAsFixed(2)}),
                          style: pw.TextStyle(font: fontData, fontSize: 9)),
                      pw.Text('الإجمالي: {v1} {v2}'.tr({'v1': total.toStringAsFixed(2), 'v2': Money.txt}),
                          style: pw.TextStyle(font: boldFont, fontSize: 10)),
                      pw.Divider(thickness: 0.3),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),
              pw.Text('ملخص الشيفت:'.tr(),
                  style: pw.TextStyle(font: boldFont, fontSize: 12)),
              pw.SizedBox(height: 3),
              pw.Text('إجمالي الأجهزة: {v1} {v2}'.tr({'v1': totalDevice.toStringAsFixed(2), 'v2': Money.txt}),
                  style: pw.TextStyle(font: fontData, fontSize: 10)),
              pw.Text('إجمالي المشروبات: {v1} {v2}'.tr({'v1': totalDrinks.toStringAsFixed(2), 'v2': Money.txt}),
                  style: pw.TextStyle(font: fontData, fontSize: 10)),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // 🆕 قسم المدفوع والآجل
              pw.Text(
                  '💵 إجمالي المدفوع (كاش): {v1} {v2}'.tr({'v1': totalPaid.toStringAsFixed(2), 'v2': Money.txt}),
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 10, color: PdfColors.green800)),
              pw.Text(
                  '✅ محصّل من الآجل: {v1} {v2}'.tr({'v1': totalDebtCollected.toStringAsFixed(2), 'v2': Money.txt}),
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 10, color: PdfColors.teal800)),
              pw.Text(
                  '⏳ آجل لسه متبقي: {v1} {v2}'.tr({'v1': totalDebtRemaining.toStringAsFixed(2), 'v2': Money.txt}),
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 10, color: PdfColors.red800)),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1),
              pw.Text(
                'إجمالي الكلي: {v1} {v2}'.tr({'v1': totalAll.toStringAsFixed(2), 'v2': Money.txt}),
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('شكرًا لجهودك ❤️'.tr(),
                    style: pw.TextStyle(font: fontData, fontSize: 10)),
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
