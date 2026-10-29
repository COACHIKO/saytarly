import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/playstation_sales_report_screen_mobile_body.dart';
part 'desktop/playstation_sales_report_screen_windows_body.dart';

/// صفحة الأدمن: تقرير مبيعات البلايستيشن — كل جهاز اشتغل قد إيه وجاب كام.
/// فلترة حسب: يومي / شهري / شيفت معين.
class PlaystationSalesReportScreen extends StatefulWidget {
  const PlaystationSalesReportScreen({super.key});

  @override
  State<PlaystationSalesReportScreen> createState() =>
      _PlaystationSalesReportScreenState();
}

class _PlaystationSalesReportScreenState
    extends State<PlaystationSalesReportScreen> {
  String _periodType = 'day';
  double _debtCollectedInPeriod = 0.0;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  int? _selectedShiftId;
  bool _isClearing = false; // 🆕
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _report = [];
  bool _isLoading = false;
  String _searchQuery = '';

  static const Color revenueColor = Color(0xFF2FBE7A);
  static const Color discountColor = Color(0xFFFF9F45);

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _loadShifts();
    _loadReport();
  }

  Future<void> _loadShifts() async {
    final shifts = await DBHelper.getAllShifts();
    setState(() {
      _shifts = shifts;
      if (_selectedShiftId == null && shifts.isNotEmpty) {
        _selectedShiftId = shifts.first['id'] as int;
      }
    });
  }

// 🆕 نفس الفلترة لكن من غير استبعاد "ملغي" — عشان المسح يشمل كل حاجة فعلاً
  Future<List<int>> _getAllPlaystationInvoiceIdsInPeriodForDeletion(
    Database db, {
    required String periodType,
    DateTime? date,
    String? month,
    int? shiftId,
  }) async {
    String whereClause = "WHERE device_cost > 0 AND console_id IS NOT NULL";
    List<dynamic> args = [];

    if (periodType == 'day' && date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      whereClause += ' AND start_time >= ? AND start_time < ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    } else if (periodType == 'month' && month != null) {
      whereClause += ' AND start_time LIKE ?';
      args = ['$month%'];
    } else if (periodType == 'shift' && shiftId != null) {
      whereClause += ' AND shift_id = ?';
      args = [shiftId];
    }

    final rows = await db.rawQuery(
      'SELECT id FROM invoices $whereClause',
      args,
    );
    return rows.map((r) => r['id'] as int).toList();
  }

// 🆕 لابل بشري للفترة المختارة حاليًا
  String _periodLabel() {
    switch (_periodType) {
      case 'day':
        return 'يوم {v1}-{v2}-{v3}'.tr({'v1': _selectedDate.year, 'v2': _selectedDate.month.toString().padLeft(2, '0'), 'v3': _selectedDate.day.toString().padLeft(2, '0')});
      case 'month':
        return 'شهر {v1}-{v2}'.tr({'v1': _selectedMonth.year, 'v2': _selectedMonth.month.toString().padLeft(2, '0')});
      case 'shift':
        final match = _shifts.where((s) => s['id'] == _selectedShiftId);
        if (match.isEmpty) return 'الشيفت المختار'.tr();
        return _shiftLabel(match.first);
      default:
        return 'الفترة المختارة'.tr();
    }
  }

// 🆕 مسح كل فواتير البلايستيشن وبنودها الخاصة بالفترة المعروضة حاليًا
  Future<void> _clearPeriodSales() async {
    if (_periodType == 'shift' && _selectedShiftId == null) {
      AppToast.show('اختار شيفت الأول'.tr());
      return;
    }

    final label = _periodLabel();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:  Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('تأكيد مسح مبيعات البلايستيشن'.tr())),
          ],
        ),
        content: Text(
          ('هيتم مسح كل فواتير البلايستيشن وبنودها الخاصة بـ "{label}" نهائيًا من قاعدة البيانات.\n\n'.tr({'label': label}) + '⚠️ العملية دي لا يمكن التراجع عنها.\n'.tr() + 'ملحوظة: الديون (الآجل) نفسها هتفضل موجودة، لكن أي دفعة كاش مرتبطة بالفواتير دي هتتمسح.'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text('مسح نهائيًا'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    try {
      final db = await DBHelper.database;

      final invoiceIds = await _getAllPlaystationInvoiceIdsInPeriodForDeletion(
        db,
        periodType: _periodType,
        date: _periodType == 'day' ? _selectedDate : null,
        month: _periodType == 'month'
            ? '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}'
            : null,
        shiftId: _periodType == 'shift' ? _selectedShiftId : null,
      );

      if (invoiceIds.isEmpty) {
        setState(() => _isClearing = false);
        if (!mounted) return;
        AppToast.show('لا توجد فواتير بلايستيشن في هذه الفترة لمسحها'.tr());
        return;
      }

      final placeholders = List.filled(invoiceIds.length, '?').join(',');

      await db.rawDelete(
        'DELETE FROM invoice_items WHERE invoice_id IN ($placeholders)',
        invoiceIds,
      );

      // 🆕 امسح أي دفعات جزئية (كاش اتحصّل) مرتبطة بالفواتير دي
      await db.rawDelete(
        'DELETE FROM debt_payments WHERE invoice_id IN ($placeholders)',
        invoiceIds,
      );

      await db.rawDelete(
        'DELETE FROM invoices WHERE id IN ($placeholders)',
        invoiceIds,
      );

      await _loadReport();

      if (!mounted) return;
      AppToast.show('✅ تم مسح {v1} فاتورة بلايستيشن وبنودها'.tr({'v1': invoiceIds.length}));
    } catch (e) {
      if (!mounted) return;
      AppToast.show('خطأ أثناء المسح: {e}'.tr({'e': e}));
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  String _ar(String text) {
    return ArabicReshaper().reshape(text);
  }

// 🆕 طباعة/مشاركة تقرير البلايستيشن الحالي كـ PDF
  Future<void> _printReportPdf() async {
    try {
      final pdf = pw.Document();

      final fontRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
      );
      final fontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
      );

      final items = _filteredReport;

      final totalRevenue = _report.fold<double>(
        0,
        (sum, item) => sum + (item['revenue'] as double),
      );
      final totalDiscount = _report.fold<double>(
        0,
        (sum, item) => sum + (item['discount_amount'] as double),
      );
      final totalDebt = _report.fold<double>(
        0,
        (sum, item) => sum + (item['debt_revenue'] as double),
      );
      final totalDebtCollectedRev = _report.fold<double>(
        0,
        (sum, item) => sum + (item['debt_collected_revenue'] as double),
      );
      final totalHoursAll = _report.fold<double>(
        0,
        (sum, item) => sum + (item['hours_played'] as double),
      );
      final netCollected =
          totalRevenue - totalDiscount - totalDebt + _debtCollectedInPeriod;

      pw.Widget summaryRow(String label, dynamic value,
          {bool isTotal = false, bool isMoney = true}) {
        final displayValue = isMoney
            ? '${(value as double).toStringAsFixed(2)} ${Money.txt}'
            : value.toString();
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  font: isTotal ? fontBold : fontRegular,
                  fontSize: isTotal ? 9 : 7,
                ),
              ),
              pw.Text(
                displayValue,
                style: pw.TextStyle(font: fontBold, fontSize: isTotal ? 9 : 7),
              ),
            ],
          ),
        );
      }

      pw.Widget itemBlock(Map<String, dynamic> item) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _ar(item['name'] as String),
                style: pw.TextStyle(font: fontBold, fontSize: 8),
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    _ar('جلسات: {v1}   ساعات: {v2}'.tr({'v1': item['sessions_count'], 'v2': _formatHours(item['hours_played'] as double)})),
                    style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                  ),
                  pw.Text(
                    _ar('إيراد: {v1}'.tr({'v1': (item['revenue'] as double).toStringAsFixed(2)})),
                    style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                  ),
                ],
              ),
              if ((item['discount_amount'] as double) != 0 ||
                  (item['debt_revenue'] as double) != 0 ||
                  (item['debt_collected_revenue'] as double) != 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      _ar('خصم: {v1}'.tr({'v1': (item['discount_amount'] as double).toStringAsFixed(2)})),
                      style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                    ),
                    pw.Text(
                      _ar('آجل: {v1}'.tr({'v1': (item['debt_revenue'] as double).toStringAsFixed(2)})),
                      style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                    ),
                    pw.Text(
                      _ar('محصّل: {v1}'.tr({'v1': (item['debt_collected_revenue'] as double).toStringAsFixed(2)})),
                      style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                    ),
                  ],
                ),
              pw.Divider(thickness: 0.3, height: 6),
            ],
          ),
        );
      }

      final placeName = await BusinessProfile.getPlaceName();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat(
            70 * PdfPageFormat.mm,
            3000 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm,
          ),
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(6),
          build: (context) => [
            pw.Center(
              child: pw.Text(
                '$placeName',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'تقرير مبيعات البلايستيشن'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 9),
              ),
            ),
            pw.Center(
              child: pw.Text(
                _periodLabel(),
                style: pw.TextStyle(font: fontRegular, fontSize: 7),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'تاريخ الطباعة: {v1}'.tr({'v1': DateTime.now().toString().substring(0, 16)}),
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 6,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 4),
            if (items.isEmpty)
              pw.Text(
                'لا توجد جلسات بلايستيشن في هذه الفترة'.tr(),
                style: pw.TextStyle(font: fontBold, fontSize: 8),
              )
            else
              ...items.map((item) => itemBlock(item)),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text('الملخص'.tr(), style: pw.TextStyle(font: fontBold, fontSize: 9)),
            pw.SizedBox(height: 4),
            summaryRow('عدد الأجهزة النشطة'.tr(), items.length, isMoney: false),
            summaryRow('إجمالي الساعات'.tr(), _formatHours(totalHoursAll),
                isMoney: false),
            summaryRow('إجمالي الإيراد'.tr(), totalRevenue),
            summaryRow('إجمالي الخصم'.tr(), totalDiscount),
            summaryRow('آجل باقي (غير محصّل)'.tr(), totalDebt),
            summaryRow('دفعات جزئية (غير مضاف للصافي)'.tr(), totalDebtCollectedRev),
            summaryRow(
                'اتحصّل فعليًا من آجل قديم (كاش)'.tr(), _debtCollectedInPeriod),
            pw.Divider(),
            summaryRow('الصافي المتوقع'.tr(), netCollected, isTotal: true),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      AppToast.show('خطأ أثناء إنشاء الـ PDF: {e}'.tr({'e': e}));
    }
  }

  Future<Set<int>> _getPlaystationInvoiceIdsInPeriod(
    Database db, {
    required String periodType,
    DateTime? date,
    String? month,
    int? shiftId,
  }) async {
    String whereClause =
        'WHERE payment_type != \'ملغي\' AND device_cost > 0 AND console_id IS NOT NULL'.tr();
    List<dynamic> args = [];

    if (periodType == 'day' && date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      whereClause += ' AND start_time >= ? AND start_time < ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    } else if (periodType == 'month' && month != null) {
      whereClause += ' AND start_time LIKE ?';
      args = ['$month%'];
    } else if (periodType == 'shift' && shiftId != null) {
      whereClause += ' AND shift_id = ?';
      args = [shiftId];
    }

    final rows = await db.rawQuery(
      'SELECT id FROM invoices $whereClause',
      args,
    );
    return rows.map((r) => r['id'] as int).toSet();
  }

  Future<double> getDebtCollectedInPeriod(
    Database db, {
    required String periodType,
    DateTime? date,
    String? month,
    int? shiftId,
  }) async {
    String rangeStart;
    String rangeEnd;

    if (periodType == 'day' && date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      rangeStart = start.toIso8601String();
      rangeEnd = end.toIso8601String();
    } else if (periodType == 'month' && month != null) {
      final parts = month.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final start = DateTime(y, m, 1);
      final end = DateTime(y, m + 1, 1);
      rangeStart = start.toIso8601String();
      rangeEnd = end.toIso8601String();
    } else if (periodType == 'shift' && shiftId != null) {
      final shiftRow =
          await db.query('shifts', where: 'id = ?', whereArgs: [shiftId]);
      if (shiftRow.isEmpty) return 0.0;
      rangeStart = (shiftRow.first['check_in'] as String?) ??
          DateTime.now().toIso8601String();
      rangeEnd = (shiftRow.first['check_out'] as String?) ??
          DateTime.now().toIso8601String();
    } else {
      return 0.0;
    }

    // 🆕 فواتير البلايستيشن بتاعة الفترة نفسها — دفعاتها محسوبة أصلاً ضمن (totalRevenue - totalDebt)
    final periodInvoiceIds = await _getPlaystationInvoiceIdsInPeriod(
      db,
      periodType: periodType,
      date: date,
      month: month,
      shiftId: shiftId,
    );

    // 🆕 join مع debts و invoices عشان نجيب بس الدفعات الخاصة بفواتير فيها بلايستيشن
    final rows = await db.rawQuery('''
      SELECT dp.amount as amount, dp.invoice_id as invoice_id
      FROM debt_payments dp
      JOIN debts d ON d.id = dp.debt_id
      JOIN invoices i ON i.id = d.invoice_id
      WHERE dp.paid_at >= ? AND dp.paid_at <= ?
        AND i.device_cost > 0
        AND i.console_id IS NOT NULL
    ''', [rangeStart, rangeEnd]);

    // 🆕 استبعاد أي دفعة خاصة بفاتورة بلايستيشن أصلاً داخلة في التقرير الحالي (تفادي الاحتساب المكرر)
    final total = rows.fold<double>(0.0, (sum, p) {
      final invId = p['invoice_id'];
      if (invId != null && periodInvoiceIds.contains(invId as int)) {
        return sum;
      }
      return sum + ((p['amount'] as num?)?.toDouble() ?? 0.0);
    });

    return total;
  }

  Future<List<Map<String, dynamic>>> getPlaystationSalesReport(
    Database db, {
    required String periodType,
    DateTime? date,
    String? month,
    int? shiftId,
  }) async {
    String whereClause =
        'WHERE i.payment_type != \'ملغي\' AND i.device_cost > 0 AND i.console_id IS NOT NULL'.tr();
    List<dynamic> args = [];

    if (periodType == 'day' && date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      whereClause += ' AND i.start_time >= ? AND i.start_time < ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    } else if (periodType == 'month' && month != null) {
      whereClause += ' AND i.start_time LIKE ?';
      args = ['$month%'];
    } else if (periodType == 'shift' && shiftId != null) {
      whereClause += ' AND i.shift_id = ?';
      args = [shiftId];
    }

    final salesRows = await db.rawQuery('''
    SELECT
      i.console_id,
      COUNT(*) as sessions_count,
      SUM(
        CASE WHEN i.start_time IS NOT NULL AND i.end_time IS NOT NULL
        THEN MAX(0.0, (strftime('%s', i.end_time) - strftime('%s', i.start_time)
             - COALESCE(i.total_paused_seconds, 0)) / 3600.0)
        ELSE 0 END
      ) as hours_played,
      SUM(i.device_cost) as revenue,
      SUM(
        CASE WHEN (i.total_cost + i.discount) > 0
        THEN i.discount * (i.device_cost * 1.0 / (i.total_cost + i.discount))
        ELSE 0 END
      ) as discount_amount,
      SUM(
        CASE WHEN i.payment_type IN ('علي الحساب','debt') THEN
          (i.device_cost - (CASE WHEN (i.total_cost + i.discount) > 0
            THEN i.discount * (i.device_cost * 1.0 / (i.total_cost + i.discount))
            ELSE 0 END))
          * (
            CASE WHEN i.total_cost > 0
            THEN MAX(0.0, MIN(1.0, (i.total_cost - COALESCE(dc.collected, 0)) * 1.0 / i.total_cost))
            ELSE 1.0 END
          )
        ELSE 0 END
      ) as debt_revenue,
      SUM(
        CASE WHEN i.payment_type IN ('علي الحساب','debt') THEN
          (i.device_cost - (CASE WHEN (i.total_cost + i.discount) > 0
            THEN i.discount * (i.device_cost * 1.0 / (i.total_cost + i.discount))
            ELSE 0 END))
          * (
            CASE WHEN i.total_cost > 0
            THEN MAX(0.0, MIN(1.0, COALESCE(dc.collected, 0) * 1.0 / i.total_cost))
            ELSE 0.0 END
          )
        ELSE 0 END
      ) as debt_collected_revenue
    FROM invoices i
    LEFT JOIN (
      SELECT d.invoice_id AS invoice_id, COALESCE(SUM(dp.amount), 0) AS collected
      FROM debts d
      LEFT JOIN debt_payments dp ON dp.debt_id = d.id
      GROUP BY d.invoice_id
    ) dc ON dc.invoice_id = i.id
    $whereClause
    GROUP BY i.console_id
  ''', args);

    final salesMap = <int, Map<String, dynamic>>{
      for (final r in salesRows)
        if (r['console_id'] != null) (r['console_id'] as int): r,
    };

    final consoles = await db.query('consoles', orderBy: 'name');

    final result = consoles.map((c) {
      final id = c['id'] as int;
      final sold = salesMap[id];
      final revenue = (sold?['revenue'] as num?)?.toDouble() ?? 0.0;
      final discountAmount =
          (sold?['discount_amount'] as num?)?.toDouble() ?? 0.0;
      final debtRevenue = (sold?['debt_revenue'] as num?)?.toDouble() ?? 0.0;
      final debtCollectedRevenue =
          (sold?['debt_collected_revenue'] as num?)?.toDouble() ?? 0.0;

      return {
        'id': id,
        'name': c['name'] ?? 'غير معروف'.tr(),
        'sessions_count': (sold?['sessions_count'] as num?)?.toInt() ?? 0,
        'hours_played': (sold?['hours_played'] as num?)?.toDouble() ?? 0.0,
        'revenue': revenue,
        'discount_amount': discountAmount,
        'net_revenue': revenue - discountAmount,
        'debt_revenue': debtRevenue,
        'debt_collected_revenue': debtCollectedRevenue,
      };
    }).toList();

    result.sort(
      (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
    );

    return result;
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final db = await DBHelper.database;

      final report = await getPlaystationSalesReport(
        db,
        periodType: _periodType,
        date: _periodType == 'day' ? _selectedDate : null,
        month: _periodType == 'month'
            ? '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}'
            : null,
        shiftId: _periodType == 'shift' ? _selectedShiftId : null,
      );

      // 🆕 المحصّل فعليًا من آجل بلايستيشن قديم خلال الفترة دي
      final debtCollected = await getDebtCollectedInPeriod(
        db,
        periodType: _periodType,
        date: _periodType == 'day' ? _selectedDate : null,
        month: _periodType == 'month'
            ? '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}'
            : null,
        shiftId: _periodType == 'shift' ? _selectedShiftId : null,
      );

      setState(() {
        _report = report;
        _debtCollectedInPeriod = debtCollected;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      AppToast.show('خطأ في تحميل التقرير: {e}'.tr({'e': e}));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadReport();
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'اختر أي يوم في الشهر المطلوب'.tr(),
    );
    if (picked != null) {
      setState(() => _selectedMonth = picked);
      _loadReport();
    }
  }

  String _shiftLabel(Map<String, dynamic> s) {
    final staffName = s['staff_name'] ?? '—';
    final date = s['shift_date'] ?? '';
    return '#${s['id']} - $staffName ($date)';
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h > 0 && m > 0) return '{h} س {m} د'.tr({'h': h, 'm': m});
    if (h > 0) return '{h} س'.tr({'h': h});
    return '{m} د'.tr({'m': m});
  }

  List<Map<String, dynamic>> get _filteredReport {
    var list = _report.where((d) => (d['sessions_count'] as int) > 0).toList();

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((d) => (d['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

