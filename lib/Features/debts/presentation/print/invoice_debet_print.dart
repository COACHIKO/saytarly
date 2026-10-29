import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/services/invoice_printing.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

Future<void> printDebtInvoice(
  String customerName,
  List<Map<String, dynamic>> debtDetails,
  double totalPaid, // ✅ دلوقتي ده الكاش الفعلي بس (finalAmount)
  double totalDiscount, // ✅ الخصم الكامل
) async {
  final pdf = pw.Document();

  final fontRegular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
  );

  final fontBold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
  );

  // 🖼️ لوجو البراند: من الصورة المخصوصة (السوبر ادمن) وإلا اللوجو الافتراضي المدمج
  final logoBytes = await BusinessProfile.getLogoBytes();
  final logoImage = logoBytes == null ? null : pw.MemoryImage(logoBytes);

  final formatter = NumberFormat('#,##0.00');

  // ✅ إجمالي المتبقي الحقيقي = مجموع 'total' في كل فاتورة (وهو أصلاً محسوب بعد
  // خصم الدفعة والخصم في نفس اللوب اللي بنى debtDetails)، فمفيش داعي نطرح تاني هنا.
  final double totalRemaining = debtDetails.fold(
      0.0, (sum, d) => sum + ((d['total'] ?? 0) as num).toDouble());

  final placeName = await BusinessProfile.getPlaceName();
  final receiptInfo = await BusinessProfile.getReceiptInfo();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat(
          await BusinessProfile.getInvoicePaperMm() * PdfPageFormat.mm,
          300 * PdfPageFormat.mm,
          marginAll: 2 * PdfPageFormat.mm),
      textDirection: pw.TextDirection.rtl,
      // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
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
                    style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              if (receiptInfo['address']!.isNotEmpty)
                pw.Text(receiptInfo['address']!,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              if (receiptInfo['taxId']!.isNotEmpty)
                pw.Text('الرقم الضريبي: {v1}'.tr({'v1': receiptInfo['taxId']}),
                    style: pw.TextStyle(font: fontRegular, fontSize: 8)),
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
        pw.SizedBox(height: 6),
        pw.Center(
            child: pw.Text('فاتورة اجله'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 14))),
        pw.SizedBox(height: 4),
        pw.Text('العميل: {customerName}'.tr({'customerName': customerName}),
            style: pw.TextStyle(font: fontRegular, fontSize: 10)),
        pw.Text(
            'التاريخ: {v1}'.tr({'v1': DateFormat('EEEE, yyyy-MM-dd HH:mm', 'ar').format(DateTime.now())}),
            style: pw.TextStyle(font: fontRegular, fontSize: 10)),
        pw.Divider(),

        // تفاصيل الديون
        ...debtDetails.map((d) {
          final date = d['date'] ?? '';
          final debtDate = DateTime.tryParse(date.toString()) ?? DateTime.now();
          final formattedDate =
              DateFormat('EEEE, yyyy-MM-dd HH:mm', 'ar').format(debtDate);

          final items = (d['items'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          // ✅ 'total' هنا هو المتبقي بعد هذه الدفعة تحديدًا (مش قبلها)
          final total = (d['total'] ?? 0).toDouble();
          final paid = (d['paid'] ?? 0).toDouble();
          final payments = (d['payments'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('فاتورة بتاريخ {formattedDate}'.tr({'formattedDate': formattedDate}),
                  style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.SizedBox(height: 2),
              ...items.map((item) {
                final name = item['drink_name'] ?? 'غير معروف'.tr();
                final qty = item['qty'] ?? 0;
                final price = (item['price'] ?? 0).toDouble();
                final totalItem = (item['total'] ?? 0).toDouble();

                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('$name x$qty',
                        style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                    pw.Text('${formatter.format(price)} ${Money.txt}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                    pw.Text('${formatter.format(totalItem)} ${Money.txt}',
                        style: pw.TextStyle(font: fontBold, fontSize: 9)),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 2),
              ...payments.map((p) {
                final paidDate = DateTime.tryParse(p['paid_at'] ?? '');
                final amount = (p['amount'] ?? 0).toDouble();
                final disc = (p['discount'] ?? 0).toDouble();
                var text =
                    ' دفع {v1} بتاريخ {v2}'.tr({'v1': formatter.format(amount), 'v2': paidDate != null ? DateFormat('yyyy-MM-dd').format(paidDate) : '-'});
                if (disc > 0) {
                  text += ' (+ خصم {v1})'.tr({'v1': formatter.format(disc)});
                }
                return pw.Text(
                  text,
                  style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 9,
                      color: PdfColors.green800),
                );
              }).toList(),
              pw.SizedBox(height: 2),
              pw.Text(' مدفوع: {v1} {v2}'.tr({'v1': formatter.format(paid), 'v2': Money.txt}),
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 9, color: PdfColors.green800)),
              pw.SizedBox(height: 2),
              pw.Text(' المتبقي: {v1} {v2}'.tr({'v1': formatter.format(total), 'v2': Money.txt}),
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 9, color: PdfColors.red800)),
              pw.Divider(thickness: 0.5),
            ],
          );
        }).toList(),

        // الملخص
        pw.SizedBox(height: 4),
        pw.Divider(),
        pw.Text('ملخص الفاتورة'.tr(),
            style: pw.TextStyle(font: fontBold, fontSize: 11)),
        pw.SizedBox(height: 2),
        pw.Text('إجمالي المدفوع (كاش): {v1} {v2}'.tr({'v1': formatter.format(totalPaid), 'v2': Money.txt}),
            style: pw.TextStyle(font: fontRegular, fontSize: 10)),
        pw.SizedBox(height: 2),
        pw.Text('الخصم: {v1} {v2}'.tr({'v1': formatter.format(totalDiscount), 'v2': Money.txt}),
            style: pw.TextStyle(font: fontRegular, fontSize: 10)),
        pw.SizedBox(height: 2),
        // ✅ اتحسبت مرة واحدة بس، من غير طرح الخصم مرتين
        pw.Text('المتبقي بعد الخصم: {v1} {v2}'.tr({'v1': formatter.format(totalRemaining), 'v2': Money.txt}),
            style: pw.TextStyle(
                font: fontBold, fontSize: 10, color: PdfColors.red800)),

        pw.SizedBox(height: 6),
        if (receiptInfo['thanks']!.isNotEmpty)
          pw.Center(
              child: pw.Text(receiptInfo['thanks']!,
                  style: pw.TextStyle(font: fontBold, fontSize: 10))),
      ],
    ),
  );

  // 🖨️ طباعة الفاتورة — على الطابعة المختارة من الإعدادات (إن وجدت)
  await runInvoicePrint((format) async => pdf.save());
}
