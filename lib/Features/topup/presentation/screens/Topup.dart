import 'package:flutter/material.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/topup_mobile_body.dart';
part 'desktop/topup_windows_body.dart';

class Topup extends StatefulWidget {
  const Topup({super.key});

  @override
  State<Topup> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<Topup> {
  final _addController = TextEditingController();
  double _balance = 0.0;
  Map<String, dynamic> _summary = {};

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  // فلترة بالتاريخ
  DateTime? _fromDate;
  DateTime? _toDate;

  // نتائج الفلترة وملخصاتها
  List<Map<String, dynamic>> _filteredTransactions = [];
  double _totalCostFiltered = 0.0;
  double _totalReceivedFiltered = 0.0;
  double _totalProfitFiltered = 0.0;

  @override
  void initState() {
    super.initState();

    _reload();
  }

  String formatArabicDate(DateTime date) {
     final days = [
      "الاثنين",
      'الثلاثاء'.tr(),
      'الأربعاء'.tr(),
      'الخميس'.tr(),
      'الجمعة'.tr(),
      'السبت'.tr(),
      'الأحد'.tr()
    ];

     final months = [
      "يناير",
      'فبراير'.tr(),
      'مارس'.tr(),
      'أبريل'.tr(),
      'مايو'.tr(),
      'يونيو'.tr(),
      'يوليو'.tr(),
      'أغسطس'.tr(),
      'سبتمبر'.tr(),
      'أكتوبر'.tr(),
      'نوفمبر'.tr(),
      'ديسمبر'.tr()
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'م'.tr() : "ص";

    final minute = date.minute.toString().padLeft(2, '0');

    return '{dayName}، {v2} {monthName} {v4} - {hour}:{minute} {ampm}'.tr({'dayName': dayName, 'v2': date.day, 'monthName': monthName, 'v4': date.year, 'hour': hour, 'minute': minute, 'ampm': ampm});
  }

  // لتأكد من تهيئة intl قبل التنسيق
  Future<void> _initIntlAndReload() async {
    await _reload();
  }

  Future<void> _reload() async {
    final bal = await DBHelper.getMachineBalance();
    final summary = await DBHelper.getSummary();
    // ونعيد حساب الفلترة الحالية (لو مفيش فلتر هـ يحمّل كل العمليات)
    final all = await DBHelper.getAllTransactions();
    _applyFilterOnList(all);
    setState(() {
      _balance = bal;
      _summary = summary;
    });
  }

  Future<void> _addBalance() async {
    final value = double.tryParse(_addController.text) ?? 0.0;
    if (value <= 0) return _showError('ادخل قيمة اكبر من صفر'.tr());
    await DBHelper.addToMachineBalance(value);
    _addController.clear();
    await _reload();
  }

  void _showError(String msg) {
    AppToast.show(msg);
  }

  // دالة عرض التاريخ/الوقت بالعربي مع يوم الأسبوع
  String _formattedDate(DateTime date) => formatArabicDate(date);

  // مساعدة لاختيار التاريخ
  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
      // أعد تحميل/فلترة العمليات
      final all = await DBHelper.getAllTransactions();
      _applyFilterOnList(all);
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
      final all = await DBHelper.getAllTransactions();
      _applyFilterOnList(all);
    }
  }

  // تطبق الفلتر على لائحة العمليات وتحسب المجاميع
  void _applyFilterOnList(List<Map<String, dynamic>> all) {
    final filtered = all.where((t) {
      final d = DateTime.tryParse(t['date'].toString()) ?? DateTime.now();
      // إذا حدد من تاريخ -> d يجب أن يكون >= fromDate بداية اليوم
      if (_fromDate != null) {
        final startOfFrom =
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (d.isBefore(startOfFrom)) return false;
      }
      // إذا حدد إلى تاريخ -> d يجب أن يكون <= endOfTo (نهاية اليوم)
      if (_toDate != null) {
        final endOfTo =
            DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (d.isAfter(endOfTo)) return false;
      }
      return true;
    }).toList();

    // حساب المجاميع
    double totalCost = 0.0;
    double totalReceived = 0.0;
    double totalProfit = 0.0;

    for (var t in filtered) {
      totalCost += (t['cost'] as num?)?.toDouble() ?? 0.0;
      totalReceived += (t['received'] as num?)?.toDouble() ?? 0.0;
      totalProfit += (t['profit'] as num?)?.toDouble() ?? 0.0;
    }

    setState(() {
      _filteredTransactions = filtered;
      _totalCostFiltered = totalCost;
      _totalReceivedFiltered = totalReceived;
      _totalProfitFiltered = totalProfit;
    });
  }

  // تحميل العمليات مرة واحدة (للاستخدام اليدوي)
  Future<void> _loadAndApplyFilter() async {
    final all = await DBHelper.getAllTransactions();
    _applyFilterOnList(all);
  }

  Future<void> _printReport() async {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat(
      75 * PdfPageFormat.mm,
      150 * PdfPageFormat.mm,
      marginAll: 3 * PdfPageFormat.mm,
    );

    // خط عربي مدمج داخل مكتبة pdf – بدون تحميل

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'تقرير ماكينة الشحن'.tr(),
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // ملخص الفلتر
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('عدد العمليات: {v1}'.tr({'v1': _filteredTransactions.length}),
                    style: pw.TextStyle()),
                pw.Text(
                    'إجمالي التكلفة: {v1}'.tr({'v1': _totalCostFiltered.toStringAsFixed(2)})),
                pw.Text(
                    'إجمالي المستلم: {v1}'.tr({'v1': _totalReceivedFiltered.toStringAsFixed(2)})),
                pw.Text(
                    'إجمالي الربح: {v1}'.tr({'v1': _totalProfitFiltered.toStringAsFixed(2)})),
              ],
            ),
          ),

          pw.SizedBox(height: 20),
          pw.Text('تفاصيل العمليات:'.tr(), style: pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 8),

          // جدول العمليات
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('التاريخ'.tr(), style: pw.TextStyle())),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('التكلفة'.tr(), style: pw.TextStyle())),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('المستلم'.tr(), style: pw.TextStyle())),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('الربح'.tr(), style: pw.TextStyle())),
                ],
              ),
              ..._filteredTransactions.map((t) {
                final date =
                    DateTime.tryParse(t['date'].toString()) ?? DateTime.now();
                return pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(formatArabicDate(date))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(t['received'].toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(t['cost'].toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(t['profit'].toString())),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    // عرض نافذة الطباعة
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

