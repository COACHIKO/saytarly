import 'package:saytarly/core/utils/money.dart';
/*
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:flutter/services.dart' show rootBundle;

class DrinksInvoicePrinter {
  static Future<void> printInvoice(int invoiceId, {double discount = 0}) async {
    final pdf = pw.Document();
    final db = await DBHelper.database;

    // 🟢 تحميل خط Google Cairo
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
    );
    // 📋 بيانات الفاتورة
    final invoice =
        (await db.query('invoices', where: 'id=?', whereArgs: [invoiceId]))
            .first;
    final items = await db.rawQuery('''
  SELECT ii.*, d.name AS drink_name
  FROM invoice_items ii
  LEFT JOIN drinks d ON d.id = ii.drink_id
  WHERE ii.invoice_id = ?
''', [invoiceId]);

    final customerName = invoice['customer_name'] ?? 'بدون اسم';

    // 🕒 تنسيق الوقت
    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return '';
      try {
        final dt = DateTime.parse(timeStr);
        return DateFormat('yyyy/MM/dd HH:mm').format(dt);
      } catch (_) {
        return timeStr;
      }
    }

    final start = formatTime(invoice['start_time']?.toString());
    final end = formatTime(invoice['end_time']?.toString());
    final totalAmount = items.fold<double>(
      0,
      (sum, i) => sum + ((i['total'] ?? 0) as num).toDouble(),
    );

    final finalAmount = totalAmount - discount;

    // 📏 حجم الورق — العرض بيتظبط من الإعدادات (75mm افتراضيًا)
    final paperMm = await BusinessProfile.getInvoicePaperMm();
    final pageFormat = PdfPageFormat(
        paperMm * PdfPageFormat.mm, 150 * PdfPageFormat.mm,
        marginAll: 3 * PdfPageFormat.mm);
    // 🖼️ لوجو البراند: من الصورة المخصوصة (السوبر ادمن) وإلا اللوجو الافتراضي المدمج
    final logoBytes = await BusinessProfile.getLogoBytes();
    final logoImage = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final placeName = await BusinessProfile.getPlaceName();
    final receiptInfo = await BusinessProfile.getReceiptInfo();
    // 🧾 بناء الفاتورة
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات
        // العربي في اسم المحل (بدل Helvetica اللي مفيهوش جليف عربي).
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  */
/*    if (logoImage != null)
                    pw.Container(
                      width: 200,
                      height: 60,
                      child: pw.Image(logoImage),
                    ),*/ /*

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
                  pw.Text(
                    'فاتورة مشروبات',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('العميل: $customerName',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('وقت: $start',
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('إلى: $end',
                      style: pw.TextStyle(font: font, fontSize: 9)),

                  pw.Divider(),

                  // 🧃 جدول المشروبات (مُتوسّط)
                  pw.TableHelper.fromTextArray(
                    headers: ['الصنف', 'الكمية', 'السعر', 'الإجمالي'],
                    headerStyle: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    cellStyle: pw.TextStyle(
                        font: font,
                        fontSize: 8,
                        fontBold: pw.Font.courierBold()),
                    headerAlignment: pw.Alignment.center,
                    cellAlignment: pw.Alignment.center,
                    border: pw.TableBorder.all(width: 0.4),
                    data: items.map((item) {
                      final drink = item['drink_name'] ?? 'غير معروف';
                      final total = (item['total'] ?? 0) as num;
                      final qty = (item['qty'] ?? 1) as num;
                      final price =
                          (item['price'] != null && (item['price'] as num) > 0)
                              ? item['price']
                              : (qty > 0 ? total / qty : 0);
                      final totalAmount = items.fold<double>(
                        0,
                        (sum, i) => sum + ((i['total'] ?? 0) as num).toDouble(),
                      );

                      final finalAmount = totalAmount - discount;

                      return [
                        pw.Text(
                          drink.toString(),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                        qty.toString(),
                        price.toString(),
                        total.toString()
                      ];
                    }).toList(),
                  ),

                  pw.Divider(),
                  if (discount > 0)
                    pw.Text(
                      'الخصم: ${discount.toStringAsFixed(2)} ${Money.txt}',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  pw.Text(
                    'الإجمالي الكلي: ${finalAmount.toStringAsFixed(2)} ${Money.txt}',
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  */
/*  pw.Text(
                    'الإجمالي: ${items.fold<double>(0, (sum, i) => sum + (i['total'] as num).toDouble()).toStringAsFixed(2)} ${Money.txt}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),*/ /*

                  pw.SizedBox(height: 5),
                  pw.Text(
                    'شكراً لزيارتكم ',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // 🖨️ عرض نافذة الطباعة
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
*/
/*
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class DrinksInvoicePrinter {
  static Future<void> printInvoice() async {
    final pdf = pw.Document();

    // تحميل خط قاهـرة
    final cairo = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    // وقت الطباعة
    final printedOn = DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now());

    // تحميل اللوجو
    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load('assets/logo2/pepsi.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final pageFormat = PdfPageFormat(
        75 * PdfPageFormat.mm, 150 * PdfPageFormat.mm,
        marginAll: 3 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                if (logo != null)
                  pw.Container(
                    height: 100,
                    width: 1000,
                    alignment: pw.Alignment.center,
                    child: pw.Image(logo),
                  ),

                pw.Center(
                  child: pw.Text(
                    'فاتورة مبيعات',
                    style: pw.TextStyle(font: cairoBold, fontSize: 14),
                  ),
                ),

                pw.SizedBox(height: 4),

                // بيانات أعلى الفاتورة (ثابتة)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Date: 2024/10/19 – 03:23',
                              style: pw.TextStyle(font: cairo, fontSize: 9)),
                          pw.Text('Trip Number: 1814632',
                              style: pw.TextStyle(font: cairo, fontSize: 9)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Invoice#: IB/FS/2517146',
                              style: pw.TextStyle(font: cairo, fontSize: 9)),
                          pw.Text('Invoice Type: Credit',
                              style: pw.TextStyle(font: cairo, fontSize: 9)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('Customer No: 250768946',
                          style: pw.TextStyle(font: cairo, fontSize: 9)),
                      pw.Text('Mobile: 01220022607 / 46512',
                          style: pw.TextStyle(font: cairo, fontSize: 9)),
                      pw.Text('Route: EGOA02 – صالح الخربيشي',
                          style: pw.TextStyle(font: cairo, fontSize: 9)),
                      pw.Text('Salesman: حسن أحمد محمد حسن',
                          style: pw.TextStyle(font: cairo, fontSize: 9)),
                      pw.Text('Salesman Code: 2820683',
                          style: pw.TextStyle(font: cairo, fontSize: 9)),
                    ],
                  ),
                ),

                pw.Divider(),

                // عنوان الأعمدة
                pw.Container(
                  color: PdfColors.grey300,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 4,
                          child: pw.Text('الوصف',
                              textAlign: pw.TextAlign.center,
                              style:
                                  pw.TextStyle(font: cairoBold, fontSize: 9))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('الكمية',
                              textAlign: pw.TextAlign.center,
                              style:
                                  pw.TextStyle(font: cairoBold, fontSize: 9))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('السعر',
                              textAlign: pw.TextAlign.center,
                              style:
                                  pw.TextStyle(font: cairoBold, fontSize: 9))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('الإجمالي',
                              textAlign: pw.TextAlign.center,
                              style:
                                  pw.TextStyle(font: cairoBold, fontSize: 9))),
                    ],
                  ),
                ),

                // الصفوف (ثابتة)
                _itemRow(cairo, 'مياه غازية 330 مل – كانز – كود 25000502', '1',
                    '11.00', '11.00'),
                _itemRow(cairo, 'مياه غازية 330 مل – زجاجة – كود 25000488', '2',
                    '10.00', '20.00'),
                _itemRow(cairo, 'عصير مانجو 1 لتر – كود 30000411', '1', '25.00',
                    '25.00'),

                pw.Divider(),

                // الاجماليات
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal : 56.00 ${Money.txt}',
                          style: pw.TextStyle(font: cairo, fontSize: 10)),
                      pw.Text('VAT : 0.00',
                          style: pw.TextStyle(font: cairo, fontSize: 10)),
                      pw.Text('Schedule Tax : 0.00',
                          style: pw.TextStyle(font: cairo, fontSize: 10)),
                      pw.Text('WithHolding Tax : 0.00',
                          style: pw.TextStyle(font: cairo, fontSize: 10)),
                      pw.Text('Discount : 0.00',
                          style: pw.TextStyle(font: cairo, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice Total : 56.00 ${Money.txt}',
                          style: pw.TextStyle(font: cairoBold, fontSize: 12)),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),

                // توقيعات
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [
                      pw.Text('Salesman Signature',
                          style: pw.TextStyle(font: cairo, fontSize: 9)),
                      pw.Container(
                        height: 18,
                        width: 120,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: .5)),
                        ),
                      ),
                    ]),
                    pw.Column(children: [
                      pw.Text('Customer Signature',
                          style: pw.TextStyle(font: cairo, fontSize: 9)),
                      pw.Container(
                        height: 18,
                        width: 120,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: .5)),
                        ),
                      ),
                    ]),
                  ],
                ),

                pw.SizedBox(height: 6),

                pw.Center(
                  child: pw.Text('شكراً لزيارتكم',
                      style: pw.TextStyle(font: cairo, fontSize: 9)),
                ),
                pw.Center(
                  child: pw.Text('Printed on: $printedOn',
                      style: pw.TextStyle(font: cairo, fontSize: 8)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static pw.Widget _itemRow(
      pw.Font font, String name, String qty, String price, String total) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 4,
              child:
                  pw.Text(name, style: pw.TextStyle(font: font, fontSize: 8))),
          pw.Expanded(
              flex: 2,
              child: pw.Text(qty,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 8))),
          pw.Expanded(
              flex: 2,
              child: pw.Text(price,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 8))),
          pw.Expanded(
              flex: 2,
              child: pw.Text(total,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 8))),
        ],
      ),
    );
  }
}
*/
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/services/invoice_printing.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:flutter/services.dart' show rootBundle;

class DrinksInvoicePrinter {
  static Future<void> printInvoice(int invoiceId, {double discount = 0}) async {
    final pdf = pw.Document();
    final db = await DBHelper.database;

    // 🟢 تحميل خط Google Cairo
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Alexandria-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
    );
    // 📋 بيانات الفاتورة
    final invoice =
        (await db.query('invoices', where: 'id=?', whereArgs: [invoiceId]))
            .first;
    final items = await db.rawQuery('''
  SELECT ii.*, d.name AS drink_name
  FROM invoice_items ii
  LEFT JOIN drinks d ON d.id = ii.drink_id
  WHERE ii.invoice_id = ?
''', [invoiceId]);

    final customerName = invoice['customer_name'] ?? 'بدون اسم'.tr();

    // 🕒 تنسيق الوقت
    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return '';
      try {
        final dt = DateTime.parse(timeStr);
        return DateFormat('yyyy/MM/dd HH:mm').format(dt);
      } catch (_) {
        return timeStr;
      }
    }

    final start = formatTime(invoice['start_time']?.toString());
    final end = formatTime(invoice['end_time']?.toString());
    final totalAmount = items.fold<double>(
      0,
      (sum, i) => sum + ((i['total'] ?? 0) as num).toDouble(),
    );

    final finalAmount = totalAmount - discount;

    // 📏 حجم الورق — العرض بيتظبط من الإعدادات (75mm افتراضيًا)
    final paperMm = await BusinessProfile.getInvoicePaperMm();
    final pageFormat = PdfPageFormat(
        paperMm * PdfPageFormat.mm, 150 * PdfPageFormat.mm,
        marginAll: 3 * PdfPageFormat.mm);
    // 🖼️ لوجو البراند: من الصورة المخصوصة (السوبر ادمن) وإلا اللوجو الافتراضي المدمج
    final logoBytes = await BusinessProfile.getLogoBytes();
    final logoImage = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final placeName = await BusinessProfile.getPlaceName();
    final receiptInfo = await BusinessProfile.getReceiptInfo();
    // 🧾 بناء الفاتورة
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        // 🟢 خط افتراضي عربي لكل النصوص من غير style — إصلاح مربعات
        // العربي في اسم المحل (بدل Helvetica اللي مفيهوش جليف عربي).
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                  pw.Text(
                    'فاتورة مشروبات'.tr(),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('العميل: {customerName}'.tr({'customerName': customerName}),
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('وقت: {start}'.tr({'start': start}),
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text('إلى: {end}'.tr({'end': end}),
                      style: pw.TextStyle(font: font, fontSize: 9)),

                  pw.Divider(),

                  // 🧃 جدول المشروبات (مُتوسّط)
                  pw.TableHelper.fromTextArray(
                    headers: ['الصنف', 'الكمية'.tr(), 'السعر'.tr(), 'الإجمالي'.tr()],
                    headerStyle: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    cellStyle: pw.TextStyle(
                        font: font,
                        fontSize: 8,
                        fontBold: pw.Font.courierBold()),
                    headerAlignment: pw.Alignment.center,
                    cellAlignment: pw.Alignment.center,
                    border: pw.TableBorder.all(width: 0.4),
                    data: items.map((item) {
                      final drink = (item['drink_name'] ?? 'غير معروف'.tr())
                          .toString()
                          .replaceAll('منتج', '')
                          .trim();
                      final total = (item['total'] ?? 0) as num;
                      final qty = (item['qty'] ?? 1) as num;
                      final price =
                          (item['price'] != null && (item['price'] as num) > 0)
                              ? item['price']
                              : (qty > 0 ? total / qty : 0);

                      return [
                        pw.Text(
                          drink.toString(),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                        qty.toString(),
                        price.toString(),
                        total.toString()
                      ];
                    }).toList(),
                  ),

                  pw.Divider(),
                  if (discount > 0)
                    pw.Text(
                      'الخصم: {v1} {v2}'.tr({'v1': discount.toStringAsFixed(2), 'v2': Money.txt}),
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  pw.Text(
                    'الإجمالي الكلي: {v1} {v2}'.tr({'v1': finalAmount.toStringAsFixed(2), 'v2': Money.txt}),
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  if (receiptInfo['thanks']!.isNotEmpty)
                    pw.Text(
                      receiptInfo['thanks']!,
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // 🖨️ طباعة الفاتورة — على الطابعة المختارة من الإعدادات (إن وجدت)
    await runInvoicePrint((format) async => pdf.save());

    // 💰 فتح درج الكاشير بعد الطباعة — نفس الطابعة المختارة أو الافتراضية
    await openCashDrawer();
  }

  // ════════════════════════════════════════════════════════════════
  //  💰 CASH DRAWER  —  يفتح الدرج عن طريق إرسال أمر ESC/POS مباشرة
  //  لطابعة الـ USB المسجّلة في Windows (Print Spooler API)
  // ════════════════════════════════════════════════════════════════

  /// اسم الطابعة كما يظهر بالظبط في "Devices and Printers" بويندوز.
  /// لو سيبته فاضي، الكود هياخد الطابعة الافتراضية (Default Printer) —
  /// وبيتفضل عش الطابعة المختارة من شاشة الإعدادات لو مرّت.
  static const String? _printerName = null;

  /// أمر ESC/POS القياسي لفتح الدرج المتصل بمنفذ RJ11 في الطابعة:
  /// ESC p m t1 t2  →  0x1B 0x70 0x00 0x19 0xFA
  static final Uint8List _kickDrawerCommand = Uint8List.fromList([
    0x1B,
    0x70,
    0x00,
    0x19,
    0xFA,
  ]);

  /// يفتح الدرج. آمن (try/catch) — لو فشل الإرسال، الطباعة العادية
  /// مش بتتأثر لأنه بيتنفذ بعدها مباشرة بدون انتظار حرج.
  ///
  /// بيقرأ اسم الطابعة من الإعدادات أولًا، ولو مفيش محدد بيستخدم
  /// الافتراضية. [printerName] لو مرّر بيتقدم على الإعدادات.
  static Future<void> openCashDrawer({String? printerName}) async {
    try {
      var name = printerName;
      if (name == null || name.isEmpty) {
        final fromSettings = await BusinessProfile.getInvoicePrinterName();
        name = fromSettings.isNotEmpty ? fromSettings : _printerName;
      }
      name ??= _getDefaultPrinterName();
      if (name == null || name.isEmpty) {
        print('⚠️ لا توجد طابعة افتراضية لفتح الدرج');
        return;
      }
      _sendRawBytesToPrinter(name, _kickDrawerCommand);
    } catch (e) {
      print('⚠️ فشل فتح الدرج: $e');
    }
  }

  /// يرجع اسم الطابعة الافتراضية المسجلة في Windows
  static String? _getDefaultPrinterName() {
    final bufferSize = 260;
    final buffer = calloc<Uint16>(bufferSize).cast<Utf16>();
    final size = calloc<Uint32>()..value = bufferSize;
    try {
      final result = GetDefaultPrinter(buffer, size);
      if (result == 0) return null;
      return buffer.toDartString();
    } finally {
      calloc.free(buffer);
      calloc.free(size);
    }
  }

  /// يبعت raw bytes مباشرة للطابعة عن طريق Windows Print Spooler API
  /// (OpenPrinter → StartDocPrinter → WritePrinter → EndDocPrinter)
  static void _sendRawBytesToPrinter(String printerName, Uint8List data) {
    final hPrinter = calloc<HANDLE>();
    final namePtr = printerName.toNativeUtf16();

    try {
      final opened = OpenPrinter(namePtr, hPrinter, nullptr);
      if (opened == 0) {
        print('⚠️ تعذر فتح الطابعة: $printerName');
        return;
      }

      final docInfo = calloc<DOC_INFO_1>();
      final docNamePtr = 'Cash Drawer Kick'.toNativeUtf16();
      final dataTypePtr = 'RAW'.toNativeUtf16();

      docInfo.ref
        ..pDocName = docNamePtr
        ..pOutputFile = nullptr
        ..pDatatype = dataTypePtr;

      final jobId = StartDocPrinter(hPrinter.value, 1, docInfo.cast());
      if (jobId == 0) {
        print('⚠️ تعذر بدء مهمة الطباعة لفتح الدرج');
        ClosePrinter(hPrinter.value);
        calloc.free(docInfo);
        calloc.free(docNamePtr);
        calloc.free(dataTypePtr);
        return;
      }

      StartPagePrinter(hPrinter.value);

      final dataPtr = calloc<Uint8>(data.length);
      final dataList = dataPtr.asTypedList(data.length);
      dataList.setAll(0, data);

      final bytesWritten = calloc<Uint32>();
      WritePrinter(hPrinter.value, dataPtr.cast(), data.length, bytesWritten);

      EndPagePrinter(hPrinter.value);
      EndDocPrinter(hPrinter.value);
      ClosePrinter(hPrinter.value);

      calloc.free(docInfo);
      calloc.free(docNamePtr);
      calloc.free(dataTypePtr);
      calloc.free(dataPtr);
      calloc.free(bytesWritten);
    } finally {
      calloc.free(hPrinter);
      calloc.free(namePtr);
    }
  }
}
