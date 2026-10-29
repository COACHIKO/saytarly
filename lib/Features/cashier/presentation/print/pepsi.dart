import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:saytarly/core/localization/messages.dart';

class PepsiStaticInvoice {
  static Future<void> printStaticInvoice() async {
    final pdf = pw.Document();
    final labelWidth = 120.0; // عرض عمود اللبلات
    final valueWidth = 50.0; // عرض عمود الأرقام

    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
    );

    final logoBytes = await rootBundle.load('assets/logo2/pepsi.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final pageFormat = PdfPageFormat(
      73 * PdfPageFormat.mm,
      300 * PdfPageFormat.mm,
      marginAll: 2 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(
                    logo,
                    height: 80,
                    width: pageFormat.width - 35, // ياخد العرض بالكامل
                    fit: pw.BoxFit.fill,
                  ),

                  pw.SizedBox(height: 8),
                  pw.Text(
                    ('شركة بيبسي كولا مصر، ش.م.م_ومقيدة بالسجل التجاري تحت رقم 288729 القاهرة،\n'.tr() + ' ويقع مقرها الرئيسي بالمبنى الإداري رقم 13C02 بداخل كايرو فيستفال سيتي بيزنس بارك،\n'.tr() + '  التجمع الخامس - جمهورية مصر العربية رقم التسجيل الضريبي: 46-072-100.\n'.tr()),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      lineSpacing: 0,
                      height: 0.1,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Center(
                      child: pw.Text("5425-Zagazig",
                          style: pw.TextStyle(font: font, fontSize: 7))),
                  pw.SizedBox(height: 3),
                  _row(font, "", 'فاتورة مبيعات'.tr(), "Sales Invoice"),
                  /*    pw.Center(
                      child: pw.Text("",
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold))),
                  pw.Center(
                      child: pw.Text("",
                          style: pw.TextStyle(font: font, fontSize: 9))),*/
                  //  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'تاريخ الفاتورة:'.tr(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "20/11/2025 15:58",
                          style: pw.TextStyle(font: font, fontSize: 7),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Date:",
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'رقم الرحلة:'.tr(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "1814632",
                          style: pw.TextStyle(font: font, fontSize: 7),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Trip Number ID:",
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'رقم الفاتورة:'.tr(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "BJF22511746",
                          style: pw.TextStyle(font: font, fontSize: 7),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Invoice:",
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'نوع الفاتورة:'.tr(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Salesman / أجل المندوب'.tr(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 6,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Invoice Type:",
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'تاريخ الاستحقاق:'.tr(),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Credit",
                          style: pw.TextStyle(font: font, fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Due Date:",
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'اسم العميل :'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "Customer Name:",
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "",
                          style: pw.TextStyle(font: font, fontSize: 5),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "250768946",
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          ' ال سامى'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 7),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  /*   _row(font, "", "", "ال سامی"),
                  pw.SizedBox(height: 3),
                  pw.Text("250768946",
                      style: pw.TextStyle(font: font, fontSize: 9)),*/
                  pw.Text(
                      'الزقازيق هرية الطريق الرئيسي  الزقازيق 46512 01220022607 '.tr(),
                      style: pw.TextStyle(font: font, fontSize: 6)),
                  /*        pw.Text("0122002260746512",
                      style: pw.TextStyle(font: font, fontSize: 8)),*/

                  //     pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'م العميل الضريبي'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "",
                          style: pw.TextStyle(font: font, fontSize: 7),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Cust. Tax Id:",
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'مسار'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'حسن صالح - EGOA02'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 7),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Route:",
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  // pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'المندوب'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'حمدى احمد محمد حسن'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 6),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          "Salesman:",
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  //  pw.SizedBox(height: 3),
                  pw.Center(
                    child: pw.Text("2820683",
                        style: pw.TextStyle(font: font, fontSize: 9)),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    "---------------------------------------------------------------------------------------",
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  // ----- Product Description Section (same as image) -----

                  // ====== Row 1: Product Description – Qty – LP – TP – CP – SCH Tax ======

                  /*         pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start, // ← أهم خطوة
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 80, // نفس عرض الصورة
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Product Description",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text("(وصف المنتج)",
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 25,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text("Qty",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text("(كمية)",
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("L P",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text("(قائمة الأسعار)",
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("T P",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text("(سعر التداول)",
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("C P",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text("(سعر المستهلك)",
                                style: pw.TextStyle(font: font, fontSize: 4)),
                          ],
                        ),
                      ),
                    ],
                  ),
*/
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("C P",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(سعر المستهلك)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 4)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("T P",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(سعر التداول)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("L P",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(قائمة الأسعار)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 4)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 25,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text("Qty",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(كمية)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 80,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text("Product Description",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(وصف المنتج)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 6),

// ====== Row 2 (Prd Code – Disc – Payable – VAT – SCH Tax) ======

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("SCH Tax",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(ضريبة الجدول)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 4)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text("VAT",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(ضريبة)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 30,
                        child: pw.Column(
                          children: [
                            pw.Text(" Payable Total ",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(مستحق الدفع)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 4)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 25,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text("Disc",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(خصم)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 80,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text("Prd Code",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text('(كود المنتج)'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    "---------------------------------------------------------------------------------------",
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                  //pw.SizedBox(height: 3),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("310.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("310.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("1/0",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text(
                        'بيبسي 360 مل'.tr(),
                        style: pw.TextStyle(font: font, fontSize: 8),
                        textAlign: pw.TextAlign.start,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("310.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("360024040",
                          style: pw.TextStyle(font: font, fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    "---------------------------------------------------------------------------------------",
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                  //pw.SizedBox(height: 3),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("310.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("310.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("1/0",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("Total",
                          style: pw.TextStyle(font: font, fontSize: 9)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("310.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("0.00",
                          style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text('المجموع'.tr(),
                          style: pw.TextStyle(font: font, fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    "---------------------------------------------------------------------------------------",
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("", style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("1/0",
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 8,
                          )),
                      pw.Text("", style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("", style: pw.TextStyle(font: font, fontSize: 7)),
                      pw.Text("P99-360 ML CAN",
                          style: pw.TextStyle(font: font, fontSize: 9)),
                    ],
                  ),

                  pw.Text(
                    "---------------------------------------------------------------------------------------",
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // 1️⃣ عمود الأرقام (على الشمال)
                      pw.Container(
                        width: valueWidth,
                        padding: pw.EdgeInsets.only(left: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("0.00",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text("0.00",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text("0.00",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text("0.00",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text("310.00",
                                style: pw.TextStyle(font: font, fontSize: 8)),
                          ],
                        ),
                      ),

                      // مسافة بين العمودين
                      pw.SizedBox(width: 10),

                      // 2️⃣ عمود النصوص (على اليمين)
                      pw.Container(
                        width: labelWidth,
                        padding: pw.EdgeInsets.only(right: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('VAT / القيمة المضافة'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text('Schedule / ض. جدول'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text('With holding Tax / تجارية صناعية'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text('Discount / الخصم'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.SizedBox(height: 3),
                            pw.Text('Invoice Total / قيمة الفاتورة'.tr(),
                                style: pw.TextStyle(font: font, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.Text(
                    "---------------------------------------------------------------------------------------",
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
// SIGNATURES
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            "-------------------------",
                            style: pw.TextStyle(font: font, fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text("Salesman Signature",
                              style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Text('توقيع السائق'.tr(),
                              style: pw.TextStyle(font: font, fontSize: 7)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            "---------------------------",
                            style: pw.TextStyle(font: font, fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text("Customer Signature",
                              style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Text('توقيع العميل'.tr(),
                              style: pw.TextStyle(font: font, fontSize: 7)),
                        ],
                      ),
                    ],
                  ),

// Pepsi logo
                  pw.Image(
                    logo,
                    height: 60,
                    width: pageFormat.width, // ياخد العرض بالكامل
                    fit: pw.BoxFit.fill,
                  ),

                  pw.Center(
                    child: pw.Text("Amounts are in EGP",
                        style: pw.TextStyle(font: font, fontSize: 8)),
                  ),

                  pw.Center(
                    child: pw.Text(
                        'Printed On: 20/11/2025 15:58  تم الطباعة بتاريخ:'.tr(),
                        style: pw.TextStyle(font: font, fontSize: 7)),
                  ),

                  pw.Center(
                    child: pw.Text(
                        "--------------- End of Report ---------------",
                        style: pw.TextStyle(font: font, fontSize: 8)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _row(
      pw.Font font, String titleAr, String value, String titleEn) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 9)),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(titleAr, style: pw.TextStyle(font: font, fontSize: 8)),
            pw.Text(titleEn, style: pw.TextStyle(font: font, fontSize: 7)),
          ],
        ),
      ],
    );
  }
}
