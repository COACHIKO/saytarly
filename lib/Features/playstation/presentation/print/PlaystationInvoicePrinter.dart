import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/services/invoice_printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

class PlaystationInvoicePrinter {
  static Future<void> printSession({
    required String staffName,
    required String consoleName,
    required double duration,
    required double deviceCost,
    required double drinksCost,
    required double total,
    double discount = 0,
    List<Map<String, dynamic>>? drinks, // 🧃 لو فيه مشروبات
  }) async {
    final pdf = pw.Document();
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
    );
    // 📏 حجم الورق — العرض بيتظبط من الإعدادات (75mm افتراضيًا)
    final paperMm = await BusinessProfile.getInvoicePaperMm();
    final pageFormat = PdfPageFormat(
      paperMm * PdfPageFormat.mm,
      150 * PdfPageFormat.mm,
      marginAll: 3 * PdfPageFormat.mm,
    );

    // 🖼️ لوجو البراند: من الصورة المخصوصة (السوبر ادمن) وإلا اللوجو الافتراضي المدمج
    final logoBytes = await BusinessProfile.getLogoBytes();
    final logoImage = logoBytes == null ? null : pw.MemoryImage(logoBytes);

    final placeName = await BusinessProfile.getPlaceName();
    final receiptInfo = await BusinessProfile.getReceiptInfo();
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
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
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          ' $placeName ',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    ' فاتورة بلايستيشن '.tr(),
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('الموظف: {staffName}'.tr({'staffName': staffName}),
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text(
                      'التاريخ: {v1}'.tr({'v1': DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}),
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Divider(),
                  pw.Text('الجهاز: {consoleName}'.tr({'consoleName': consoleName}),
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('المدة: {v1} ساعة'.tr({'v1': duration.toStringAsFixed(2)}),
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('تكلفة الجهاز: {v1} {v2}'.tr({'v1': deviceCost.toStringAsFixed(2), 'v2': Money.txt}),
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  if (drinks != null && drinks.isNotEmpty) ...[
                    pw.Divider(),
                    pw.Text(' المشروبات'.tr(),
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 3),
                    pw.TableHelper.fromTextArray(
                      headers: ['الصنف', 'الكمية'.tr(), 'الإجمالي'.tr()],
                      headerStyle: pw.TextStyle(
                        font: font,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      cellStyle: pw.TextStyle(font: font, fontSize: 8),
                      cellAlignment: pw.Alignment.center,
                      headerAlignment: pw.Alignment.center,
                      border: pw.TableBorder.all(width: 0.2),
                      data: drinks.map((item) {
                        final drinkName = (item['name'] ?? 'غير معروف'.tr())
                            .toString()
                            .replaceFirst(RegExp(r'^منتج\s*'), '');

                        return [
                          pw.Text(
                            drinkName,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                            ),
                          ),
                          item['qty'].toString(),
                          (item['total'] as num).toStringAsFixed(2),
                        ];
                      }).toList(),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                        'إجمالي المشروبات: {v1} {v2}'.tr({'v1': drinksCost.toStringAsFixed(2), 'v2': Money.txt}),
                        style: pw.TextStyle(font: font, fontSize: 9)),
                  ],
                  pw.Divider(),
                  if (discount > 0)
                    pw.Text(
                      'الخصم: {v1} {v2}'.tr({'v1': discount.toStringAsFixed(2), 'v2': Money.txt}),
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'الإجمالي الكلي: {v1} {v2}'.tr({'v1': (total - discount).toStringAsFixed(2), 'v2': Money.txt}),
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  if (receiptInfo['thanks']!.isNotEmpty)
                    pw.Text(' ${receiptInfo['thanks']} ',
                        style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );

    // 🖨️ طباعة الفاتورة — على الطابعة المختارة من الإعدادات (إن وجدت)
    await runInvoicePrint((format) async => pdf.save());
  }
}
