import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

/// طباعة تقرير جرد لكل الديون المسجلة (اسم العميل + المبلغ المتبقي فقط)
/// على ورق حراري 70مم، صفحة ورا صفحة (Multi-page) بدل ما تكون رول واحد طويل.
Future<void> printDebtsInventoryReport(
  List<Map<String, dynamic>>
      debts, // كل عنصر لازم يحتوي customer_name و remaining_amount
  double totalAll,
) async {
  final fontData = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
  );

  final formatter = NumberFormat('#,##0.00');

  // ترتيب العملاء حسب الاسم أبجديًا (اختياري لكن بيسهل القراءة في الجرد)
  final sortedDebts = [...debts]..sort((a, b) => (a['customer_name'] ?? '')
      .toString()
      .compareTo((b['customer_name'] ?? '').toString()));

  final pdf = pw.Document();

  // 🆕 طول كل صفحة بالمليمتر — عدّل الرقم ده حسب طول الورقة اللي عايزها
  // (200 مم تقريبًا = طول ورقة كاشير متوسطة). لازم يكون رقم محدد مش infinity.
  const double pageHeightMm = 200;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat(
        70 * PdfPageFormat.mm,
        pageHeightMm * PdfPageFormat.mm,
      ),
      margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
      theme: pw.ThemeData.withFont(base: fontData, bold: boldFont),

      // 🧾 العنوان والتاريخ يظهروا فوق في كل صفحة
      header: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'جرد الديون (الآجل)'.tr(),
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
              // رقم الصفحة الحالية من إجمالي الصفحات
              pw.Text(
                'صفحة {v1} من {v2}'.tr({'v1': context.pageNumber, 'v2': context.pagesCount}),
                style: pw.TextStyle(font: fontData, fontSize: 9),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1),
            ],
          ),
        );
      },

      // 📊 الملخص والإجمالي يظهروا في آخر صفحة بس
      footer: (pw.Context context) {
        if (context.pageNumber != context.pagesCount) {
          return pw.Container();
        }
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Text(
                'عدد العملاء: {v1}'.tr({'v1': sortedDebts.length}),
                style: pw.TextStyle(font: fontData, fontSize: 10),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'الآجل الكلي: {v1} {v2}'.tr({'v1': formatter.format(totalAll), 'v2': Money.txt}),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 13,
                  color: PdfColors.red800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'تم الطباعة بواسطة النظام'.tr(),
                style: pw.TextStyle(font: fontData, fontSize: 9),
              ),
            ],
          ),
        );
      },

      // 🧾 قائمة العملاء والمبالغ — هي دي اللي بتتقسم تلقائيًا على الصفحات
      build: (pw.Context context) {
        return [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: sortedDebts.map((d) {
                final name = d['customer_name'] ?? 'غير معروف'.tr();
                final amount = ((d['remaining_amount'] ?? 0) as num).toDouble();

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          name,
                          style: pw.TextStyle(font: fontData, fontSize: 11),
                        ),
                      ),
                      pw.Text(
                        '${formatter.format(amount)} ${Money.txt}',
                        style: pw.TextStyle(font: boldFont, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
}

/// 🆕 طباعة تفاصيل كل دين كامل لكل عميل — كل عميل يبدأ في صفحة جديدة.
///
/// الشكل المتوقع لكل عنصر في customersData:
/// {
///   'customer_name': String,
///   'remaining_total': double,          // إجمالي المتبقي على العميل ده
///   'invoices': [
///     {
///       'date': String,                  // تاريخ مُنسّق جاهز للعرض
///       'items': List<Map<String,dynamic>>  // كل عنصر فيه drink_name/qty/price/total
///       'total': double,                 // المتبقي على الفاتورة دي
///       'paid': double,                  // المدفوع كاش على الفاتورة دي
///       'discount': double,              // الخصم على الفاتورة دي
///     },
///     ...
///   ],
/// }
Future<void> printAllDebtsDetailedReport(
  List<Map<String, dynamic>> customersData,
) async {
  final fontData = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
  );

  final formatter = NumberFormat('#,##0.00');

  final pdf = pw.Document();

  // طول كل صفحة بالمليمتر — نفس فكرة تقرير الجرد، رقم محدد مش infinity
  const double pageHeightMm = 250;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat(
        70 * PdfPageFormat.mm,
        pageHeightMm * PdfPageFormat.mm,
      ),
      margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات العربي.
      theme: pw.ThemeData.withFont(base: fontData, bold: boldFont),
      header: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(
            'صفحة {v1} من {v2}'.tr({'v1': context.pageNumber, 'v2': context.pagesCount}),
            style: pw.TextStyle(font: fontData, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        );
      },
      build: (pw.Context context) {
        final List<pw.Widget> widgets = [];

        for (int i = 0; i < customersData.length; i++) {
          final customer = customersData[i];
          final customerName =
              customer['customer_name']?.toString() ?? 'غير معروف'.tr();
          final remainingTotal =
              ((customer['remaining_total'] ?? 0) as num).toDouble();
          final invoices =
              (customer['invoices'] as List).cast<Map<String, dynamic>>();

          widgets.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 🧾 اسم العميل كعنوان
                  pw.Text(
                    customerName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 4),

                  // 📄 كل فاتورة من فواتير العميل ده
                  ...invoices.expand((inv) {
                    final date = inv['date']?.toString() ?? '';
                    final items =
                        (inv['items'] as List).cast<Map<String, dynamic>>();
                    final invTotal = ((inv['total'] ?? 0) as num).toDouble();
                    final invPaid = ((inv['paid'] ?? 0) as num).toDouble();
                    final invDiscount =
                        ((inv['discount'] ?? 0) as num).toDouble();

                    return [
                      pw.Text(
                        'فاتورة بتاريخ {date}'.tr({'date': date}),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 2),

                      // عناصر الفاتورة
                      ...items.map((item) {
                        final drinkName =
                            item['drink_name']?.toString() ?? 'غير معروف'.tr();
                        final qty = item['qty'] ?? 0;
                        final total = ((item['total'] ?? 0) as num).toDouble();

                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  '$drinkName x$qty',
                                  style: pw.TextStyle(
                                      font: fontData, fontSize: 10),
                                ),
                              ),
                              pw.Text(
                                formatter.format(total),
                                style:
                                    pw.TextStyle(font: fontData, fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }),

                      pw.SizedBox(height: 3),
                      if (invPaid > 0)
                        pw.Text(
                          'مدفوع: {v1} {v2}'.tr({'v1': formatter.format(invPaid), 'v2': Money.txt}),
                          style: pw.TextStyle(font: fontData, fontSize: 9),
                        ),
                      if (invDiscount > 0)
                        pw.Text(
                          'خصم: {v1} {v2}'.tr({'v1': formatter.format(invDiscount), 'v2': Money.txt}),
                          style: pw.TextStyle(font: fontData, fontSize: 9),
                        ),
                      pw.Text(
                        'متبقي الفاتورة: {v1} {v2}'.tr({'v1': formatter.format(invTotal), 'v2': Money.txt}),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: PdfColors.red800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Divider(thickness: 0.5),
                      pw.SizedBox(height: 4),
                    ];
                  }),

                  // 💰 إجمالي العميل
                  pw.SizedBox(height: 4),
                  pw.Text(
                    ('إجمالي المتبقي على {customerName}: '.tr({'customerName': customerName}) + '${formatter.format(remainingTotal)} ${Money.txt}'),
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 13,
                      color: PdfColors.red800,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          );

          // 🆕 كل عميل يبدأ في صفحة جديدة (ما عدا آخر واحد)
          if (i != customersData.length - 1) {
            widgets.add(pw.NewPage());
          }
        }

        return widgets;
      },
    ),
  );

  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
}
