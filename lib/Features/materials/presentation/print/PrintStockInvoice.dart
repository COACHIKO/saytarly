import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/services/invoice_printing.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

import 'package:printing/printing.dart'; // للطباعة

class PrintStockInvoice {
  final List<DrinkModel> drinks;

  PrintStockInvoice(this.drinks);
  static Future<void> printStockInvoice(List<DrinkModel> drinks) async {
    final pdf = pw.Document();
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
    );

    final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity, // الطول غير محدود، الطابعة تكمل حسب المحتوى
      marginAll: 3 * PdfPageFormat.mm,
    );

    // 🖼️ لوجو البراند: من الصورة المخصوصة (السوبر ادمن) وإلا اللوجو الافتراضي المدمج
    final logoBytes = await BusinessProfile.getLogoBytes();
    final logoImage = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final rows = <List<String>>[];
    for (int i = 0; i < drinks.length; i += 3) {
      final first = drinks[i];
      final second = (i + 1 < drinks.length)
          ? drinks[i + 1]
          : DrinkModel(name: '', qty: 0, price: 0);
      final third = (i + 2 < drinks.length)
          ? drinks[i + 2]
          : DrinkModel(name: '', qty: 0, price: 0);

      rows.add([
        first.qty.toString(),
        first.name,
        second.qty.toString(),
        second.name,
        third.qty.toString(),
        third.name,
      ]);
    }

    final placeName = await BusinessProfile.getPlaceName();
    final receiptInfo = await BusinessProfile.getReceiptInfo();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
            await BusinessProfile.getInvoicePaperMm() * PdfPageFormat.mm,
            300 * PdfPageFormat.mm,
            marginAll: 2 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(4),
        textDirection: pw.TextDirection.rtl,
        // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) => [
          pw.Container(
            alignment: pw.Alignment.center,
            padding:  pw.EdgeInsets.only(bottom: 5),
            child: pw.Column(
              children: [
                if (logoImage != null) ...[
                  pw.Image(logoImage, height: 55, fit: pw.BoxFit.contain),
                  pw.SizedBox(height: 4),
                ],
                if (receiptInfo['phone']!.isNotEmpty)
                  pw.Text('تليفون: {v1}'.tr({'v1': receiptInfo['phone']}),
                      style: pw.TextStyle(font: font, fontSize: 8)),
                if (receiptInfo['address']!.isNotEmpty)
                  pw.Text(receiptInfo['address']!,
                      style: pw.TextStyle(font: font, fontSize: 8)),
                if (receiptInfo['taxId']!.isNotEmpty)
                  pw.Text('الرقم الضريبي: {v1}'.tr({'v1': receiptInfo['taxId']}),
                      style: pw.TextStyle(font: font, fontSize: 8)),
                pw.Text(
                  ' $placeName ',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              'فاتورة الجرد'.tr(),
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 1),
          pw.TableHelper.fromTextArray(
            headers: ['عدد', 'صنف'.tr(), 'عدد'.tr(), 'صنف'.tr(), 'عدد'.tr(), 'صنف'.tr()],
            columnWidths: {
              0: pw.FlexColumnWidth(0.5), // العمود الخاص بالعدد أصغر
              1: pw.FlexColumnWidth(1), // العمود الخاص بالاسم أكبر
              2: pw.FlexColumnWidth(0.5),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(0.5),
              5: pw.FlexColumnWidth(1),
            },
            headerStyle: pw.TextStyle(
                font: font, fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: pw.TextStyle(
                font: font, fontSize: 8, fontWeight: pw.FontWeight.bold),
            data: rows,
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.Text(
            'إجمالي عدد المنتجات: {v1}'.tr({'v1': drinks.length}),
            style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    // 🖨️ طباعة الفاتورة — على الطابعة المختارة من الإعدادات (إن وجدت)
    await runInvoicePrint((format) async => pdf.save());
  }

  Future<void> printStock() async {
    final pdf = pw.Document();
    final font =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));

    // تقسيم المشروبات إلى مجموعات كل مجموعة تحتوي على 3 منتجات
    List<List<DrinkModel>> chunkDrinks(List<DrinkModel> drinks, int size) {
      List<List<DrinkModel>> chunks = [];
      for (var i = 0; i < drinks.length; i += size) {
        final end = (i + size > drinks.length) ? drinks.length : i + size;
        chunks.add(drinks.sublist(i, end));
      }
      return chunks;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat:
            PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(4),
        textDirection: pw.TextDirection.rtl,
        // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) {
          final rows = chunkDrinks(drinks, 3).map((triple) {
            // أكمل الصف إذا كان أقل من 3 منتجات
            while (triple.length < 3) {
              triple.add(DrinkModel(name: '', qty: 0, price: 0));
            }

            return pw.TableRow(
              children: triple.map((d) {
                final color = d.qty < 10
                    ? PdfColor.fromInt(0xffff0000)
                    : PdfColor.fromInt(0xff000000);
                return pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(d.name,
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: color,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(d.qty.toString(),
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: color,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            );
          }).toList();

          return [
            pw.Center(
              child: pw.Text(
                'فاتورة الجرد'.tr(),
                style: pw.TextStyle(
                    font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Divider(),
            pw.Table(
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: rows,
            ),
            pw.Divider(),
            pw.Text(
              'إجمالي عدد المنتجات: {v1}'.tr({'v1': drinks.length}),
              style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
