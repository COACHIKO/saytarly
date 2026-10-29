import 'package:saytarly/core/services/business_profile.dart';
import 'package:printing/printing.dart';

/// تنفيذ طباعة الفواتير الإلكترونية:
/// - لو حدد السوبر ادمن اسم طابعة من الإعدادات → بيطبع عليها مباشرة
///   بدون واجهة يوزر (directPrintPdf) — مثالي لأوردرات المطاعم.
/// - لو فاضي → نافذة الطباعة العادية على الطابعة الافتراضية زي الأول.
Future<void> runInvoicePrint(LayoutCallback onLayout) async {
  final printerName = await BusinessProfile.getInvoicePrinterName();
  if (printerName.isNotEmpty) {
    await Printing.directPrintPdf(
      printer: Printer(url: '', name: printerName),
      onLayout: onLayout,
    );
  } else {
    await Printing.layoutPdf(onLayout: onLayout);
  }
}
