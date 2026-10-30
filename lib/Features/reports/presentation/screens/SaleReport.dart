import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/sale_report_mobile_body.dart';
part 'desktop/sale_report_windows_body.dart';

/// صفحة الأدمن: تقرير المبيعات — كل صنف اتباع كام وباقي كام.
/// فلترة حسب: يومي / شهري / شيفت معين.
class SalesReportScreen extends StatefulWidget {
  final List<String>? categoryFilter; // 🆕 null = كل الأصناف
  final String? customTitle; // 🆕 عنوان مخصص للأبار بار
  final int? moduleId; // 🆕 تقرير قسم كامل من أقسام السوبر ادمن

  const SalesReportScreen({
    super.key,
    this.categoryFilter,
    this.customTitle,
    this.moduleId,
  });

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String _periodType = 'day';

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  int? _selectedShiftId;
  double _debtCollectedInPeriod = 0.0;
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _report = [];
  bool _isLoading = false;
  bool _isClearing = false; // 🆕
  String _searchQuery = '';

  // ألوان دلالية للماليات — ثابتة عمدًا عشان تفضل مفهومة (أخضر=إيراد، أحمر=آجل...)
  // بس بنستخدم ألوان الثيم للخلفيات والحدود والنصوص
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

  Future<Set<int>> _getInvoiceIdsInPeriod(
    Database db, {
    required String periodType,
    DateTime? date,
    String? month,
    int? shiftId,
  }) async {
    String whereClause = 'WHERE payment_type != \'ملغي\''.tr();
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

  // 🆕 نفس منطق الفلترة الزمنية، لكن من غير استبعاد الفواتير "ملغي" —
  // عشان المسح يشمل كل حاجة في الفترة دي فعلاً، مش المبيعات الفعّالة بس.
  Future<List<int>> _getAllInvoiceIdsInPeriodForDeletion(
    Database db, {
    required String periodType,
    DateTime? date,
    String? month,
    int? shiftId,
  }) async {
    String whereClause = '1=1';
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
      'SELECT id FROM invoices WHERE $whereClause',
      args,
    );
    return rows.map((r) => r['id'] as int).toList();
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
      final shiftRow = await db.query(
        'shifts',
        where: 'id = ?',
        whereArgs: [shiftId],
      );
      if (shiftRow.isEmpty) return 0.0;
      rangeStart =
          (shiftRow.first['check_in'] as String?) ??
          DateTime.now().toIso8601String();
      rangeEnd =
          (shiftRow.first['check_out'] as String?) ??
          DateTime.now().toIso8601String();
    } else {
      return 0.0;
    }

    // 🆕 فواتير الفترة نفسها — دفعاتها اتحسبت أصلاً ضمن (totalRevenue - totalDebt)
    final periodInvoiceIds = await _getInvoiceIdsInPeriod(
      db,
      periodType: periodType,
      date: date,
      month: month,
      shiftId: shiftId,
    );

    final rows = await db.query(
      'debt_payments',
      where: 'paid_at >= ? AND paid_at <= ?',
      whereArgs: [rangeStart, rangeEnd],
    );

    // 🆕 استبعاد أي دفعة خاصة بفاتورة أصلاً داخلة في التقرير الحالي
    final total = rows.fold<double>(0.0, (sum, p) {
      final invId = p['invoice_id'];
      if (invId != null && periodInvoiceIds.contains(invId as int)) {
        return sum;
      }
      return sum + ((p['amount'] as num?)?.toDouble() ?? 0.0);
    });

    return total;
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

  String _ar(String text) {
    return ArabicReshaper().reshape(text);
  }

  Future<List<Map<String, dynamic>>> getSalesReportWithStock(
    Database db, {
    required String periodType,
    DateTime? date,
    String? month,
    int? shiftId,
  }) async {
    String whereClause = 'WHERE i.payment_type != \'ملغي\''.tr();
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

    String catCondition = '';
    List<dynamic> catArgs = [];
    if (widget.moduleId != null) {
      // تقرير قسم كامل — كل منتجات القسم مهما كانت تصنيفاتها
      catCondition = ' AND d.module_id = ?';
      catArgs = [widget.moduleId];
    } else if (widget.categoryFilter != null &&
        widget.categoryFilter!.isNotEmpty) {
      final placeholders = List.filled(
        widget.categoryFilter!.length,
        '?',
      ).join(',');
      catCondition = ' AND d.temperature IN ($placeholders)';
      catArgs = widget.categoryFilter!;
    } else {
      // تقرير المشروبات فقط: استبعاد السجائر والشيشة والمنتجات
      catCondition =
          " AND (d.temperature NOT IN ('cigarette', 'shisha', 'prodect') OR d.temperature IS NULL)";
    }

    final salesRows = await db.rawQuery(
      '''
    SELECT
      ii.drink_id,
      SUM(ii.qty) as sold_qty,
      SUM(ii.total) as revenue,
      SUM(
        CASE WHEN (i.total_cost + i.discount) > 0
        THEN ii.total * (i.discount * 1.0 / (i.total_cost + i.discount))
        ELSE 0 END
      ) as discount_amount,
      SUM(
        CASE WHEN i.payment_type IN ('علي الحساب','debt') THEN
          ii.qty * (
            CASE WHEN i.total_cost > 0
            THEN MAX(0.0, MIN(1.0, (i.total_cost - COALESCE(dc.collected, 0)) * 1.0 / i.total_cost))
            ELSE 1.0 END
          )
        ELSE 0 END
      ) as debt_qty,
      SUM(
        CASE WHEN i.payment_type IN ('علي الحساب','debt') THEN
          (ii.total - CASE WHEN (i.total_cost + i.discount) > 0
            THEN ii.total * (i.discount * 1.0 / (i.total_cost + i.discount))
            ELSE 0 END)
          * (
            CASE WHEN i.total_cost > 0
            THEN MAX(0.0, MIN(1.0, (i.total_cost - COALESCE(dc.collected, 0)) * 1.0 / i.total_cost))
            ELSE 1.0 END
          )
        ELSE 0 END
      ) as debt_revenue,
      SUM(
        CASE WHEN i.payment_type IN ('علي الحساب','debt') THEN
          (ii.total - CASE WHEN (i.total_cost + i.discount) > 0
            THEN ii.total * (i.discount * 1.0 / (i.total_cost + i.discount))
            ELSE 0 END)
          * (
            CASE WHEN i.total_cost > 0
            THEN MAX(0.0, MIN(1.0, COALESCE(dc.collected, 0) * 1.0 / i.total_cost))
            ELSE 0.0 END
          )
        ELSE 0 END
      ) as debt_collected_revenue
    FROM invoice_items ii
    JOIN invoices i ON i.id = ii.invoice_id
    JOIN drinks d ON d.id = ii.drink_id
    LEFT JOIN (
      SELECT d.invoice_id AS invoice_id, COALESCE(SUM(dp.amount), 0) AS collected
      FROM debts d
      LEFT JOIN debt_payments dp ON dp.debt_id = d.id
      GROUP BY d.invoice_id
    ) dc ON dc.invoice_id = i.id
    $whereClause $catCondition
    GROUP BY ii.drink_id
  ''',
      [...args, ...catArgs],
    );

    final salesMap = <int, Map<String, dynamic>>{
      for (final r in salesRows)
        if (r['drink_id'] != null) (r['drink_id'] as int): r,
    };
    List<Map<String, dynamic>> drinks;
    if (widget.moduleId != null) {
      drinks = await db.query(
        'drinks',
        where: 'module_id = ?',
        whereArgs: [widget.moduleId],
        orderBy: 'name',
      );
    } else if (widget.categoryFilter == null) {
      drinks = await db.query(
        'drinks',
        // تقرير المشروبات فقط: استبعاد السجائر والشيشة والمنتجات
        where:
            "(temperature NOT IN ('cigarette', 'shisha', 'prodect') OR temperature IS NULL)",
        orderBy: 'name',
      );
    } else {
      drinks = await db.query(
        'drinks',
        where:
            'temperature IN (${List.filled(widget.categoryFilter!.length, '?').join(',')})',
        whereArgs: widget.categoryFilter,
        orderBy: 'name',
      );
    }

    final result =
        drinks.map((d) {
          final id = d['id'] as int;
          final sold = salesMap[id];
          final revenue = (sold?['revenue'] as num?)?.toDouble() ?? 0.0;
          final discountAmount =
              (sold?['discount_amount'] as num?)?.toDouble() ?? 0.0;
          final debtRevenue =
              (sold?['debt_revenue'] as num?)?.toDouble() ?? 0.0;
          final debtCollectedRevenue =
              (sold?['debt_collected_revenue'] as num?)?.toDouble() ?? 0.0;

          return {
            'id': id,
            'name': DrinkModel.displayNameFromMap(d),
            'category': d['category'],
            'unit': (d['unit'] as String?) ?? 'piece',
            'is_weighted': (d['is_weighted'] ?? 0) == 1,
            'sold_qty': (sold?['sold_qty'] as num?)?.toDouble() ?? 0.0,
            'revenue': revenue,
            'discount_amount': discountAmount,
            'net_revenue': revenue - discountAmount,
            'debt_qty': (sold?['debt_qty'] as num?)?.toDouble() ?? 0.0,
            'debt_revenue': debtRevenue,
            'debt_collected_revenue': debtCollectedRevenue,
            'remaining_qty': (d['qty'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();

    result.sort(
      (a, b) => (b['sold_qty'] as double).compareTo(a['sold_qty'] as double),
    );

    return result;
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final db = await DBHelper.database;

      final report = await getSalesReportWithStock(
        db,
        periodType: _periodType,
        date: _periodType == 'day' ? _selectedDate : null,
        month:
            _periodType == 'month'
                ? '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}'
                : null,
        shiftId: _periodType == 'shift' ? _selectedShiftId : null,
      );
      // 🆕 المحصّل فعليًا في الفترة دي بغض النظر عن الفاتورة اتعملت امتى
      final debtCollected = await getDebtCollectedInPeriod(
        db,
        periodType: _periodType,
        date: _periodType == 'day' ? _selectedDate : null,
        month:
            _periodType == 'month'
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

  // 🆕 لابل بشري للفترة المختارة حاليًا، يستخدم في التأكيد والطباعة
  String _periodLabel() {
    switch (_periodType) {
      case 'day':
        return 'يوم {v1}-{v2}-{v3}'.tr({
          'v1': _selectedDate.year,
          'v2': _selectedDate.month.toString().padLeft(2, '0'),
          'v3': _selectedDate.day.toString().padLeft(2, '0'),
        });
      case 'month':
        return 'شهر {v1}-{v2}'.tr({
          'v1': _selectedMonth.year,
          'v2': _selectedMonth.month.toString().padLeft(2, '0'),
        });
      case 'shift':
        final match = _shifts.where((s) => s['id'] == _selectedShiftId);
        if (match.isEmpty) return 'الشيفت المختار'.tr();
        return _shiftLabel(match.first);
      default:
        return 'الفترة المختارة'.tr();
    }
  }

  // 🆕 مسح كل الفواتير وبنودها الخاصة بالفترة المعروضة حاليًا فقط
  // (المبيعات بس — مفيش لمس للديون debts، حسب الاختيار).
  Future<void> _clearPeriodSales() async {
    if (_periodType == 'shift' && _selectedShiftId == null) {
      AppToast.show('اختار شيفت الأول'.tr());
      return;
    }

    final label = _periodLabel();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AppDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('تأكيد مسح المبيعات'.tr())),
              ],
            ),
            content: Text(
              ('هيتم مسح كل الفواتير وبنودها الخاصة بـ "{label}" نهائيًا من قاعدة البيانات.\n\n'
                      .tr({'label': label}) +
                  '⚠️ العملية دي لا يمكن التراجع عنها.\n'.tr() +
                  'ملحوظة: الديون (الآجل) المرتبطة بأي فاتورة هتتمسح مش هتتأثر — هتفضل موجودة لوحدها.'
                      .tr()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('مسح نهائيًا'.tr()),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    try {
      final db = await DBHelper.database;

      final invoiceIds = await _getAllInvoiceIdsInPeriodForDeletion(
        db,
        periodType: _periodType,
        date: _periodType == 'day' ? _selectedDate : null,
        month:
            _periodType == 'month'
                ? '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}'
                : null,
        shiftId: _periodType == 'shift' ? _selectedShiftId : null,
      );

      if (invoiceIds.isEmpty) {
        setState(() => _isClearing = false);
        if (!mounted) return;
        AppToast.show('لا توجد فواتير في هذه الفترة لمسحها'.tr());
        return;
      }

      final placeholders = List.filled(invoiceIds.length, '?').join(',');

      await db.rawDelete(
        'DELETE FROM invoice_items WHERE invoice_id IN ($placeholders)',
        invoiceIds,
      );
      await db.rawDelete(
        'DELETE FROM invoices WHERE id IN ($placeholders)',
        invoiceIds,
      );

      await db.rawDelete(
        'DELETE FROM invoice_items WHERE invoice_id IN ($placeholders)',
        invoiceIds,
      );

      // 🆕 امسح أي دفعات جزئية (كاش اتحصّل) مرتبطة بالفواتير دي
      // عشان "اتحصّل فعليًا (كاش)" يترجع صفر فعلاً بعد مسح الفترة
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
      AppToast.show(
        '✅ تم مسح {v1} فاتورة وبنودها'.tr({'v1': invoiceIds.length}),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show('خطأ أثناء المسح: {e}'.tr({'e': e}));
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  // 🆕 طباعة/مشاركة التقرير الحالي كـ PDF
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
      final netCollected =
          totalRevenue - totalDiscount - totalDebt + _debtCollectedInPeriod;

      pw.Widget summaryRow(String label, double value, {bool isTotal = false}) {
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
                '${value.toStringAsFixed(2)} ${Money.txt}',
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
                _ar(item['name'] as String), // <-- هنا
                style: pw.TextStyle(font: fontBold, fontSize: 8),
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    _ar(
                      'كمية: {v1}'.tr({
                        'v1': _formatQty(item, item['sold_qty'] as double),
                      }),
                    ), // <-- هنا
                    style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                  ),
                  pw.Text(
                    _ar(
                      'إيراد: {v1}'.tr({
                        'v1': (item['revenue'] as double).toStringAsFixed(2),
                      }),
                    ), // <-- هنا
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
                      _ar(
                        'خصم: {v1}'.tr({
                          'v1': (item['discount_amount'] as double)
                              .toStringAsFixed(2),
                        }),
                      ), // <-- هنا
                      style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                    ),
                    pw.Text(
                      _ar(
                        'آجل: {v1}'.tr({
                          'v1': (item['debt_revenue'] as double)
                              .toStringAsFixed(2),
                        }),
                      ), // <-- هنا
                      style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                    ),
                    pw.Text(
                      _ar(
                        'محصّل: {v1}'.tr({
                          'v1': (item['debt_collected_revenue'] as double)
                              .toStringAsFixed(2),
                        }),
                      ), // <-- هنا
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
            70 * PdfPageFormat.mm, // العرض 70مم
            3000 * PdfPageFormat.mm, // الطول مفتوح (رول)
            marginAll: 4 * PdfPageFormat.mm,
          ),
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(6),
          build:
              (context) => [
                pw.Center(
                  child: pw.Text(
                    '$placeName',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    widget.customTitle ?? 'تقرير المبيعات'.tr(),
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
                    'تاريخ الطباعة: {v1}'.tr({
                      'v1': DateTime.now().toString().substring(0, 16),
                    }),
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

                // الأصناف
                if (items.isEmpty)
                  pw.Text(
                    'لا توجد مبيعات في هذه الفترة'.tr(),
                    style: pw.TextStyle(font: fontBold, fontSize: 8),
                  )
                else
                  ...items.map((item) => itemBlock(item)),

                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 4),
                pw.Text(
                  'الملخص'.tr(),
                  style: pw.TextStyle(font: fontBold, fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                summaryRow('عدد الأصناف المباعة'.tr(), items.length.toDouble()),
                summaryRow('إجمالي الإيراد'.tr(), totalRevenue),
                summaryRow('إجمالي الخصم'.tr(), totalDiscount),
                summaryRow('آجل باقي (غير محصّل)'.tr(), totalDebt),
                summaryRow(
                  'دفعات جزئية على تربيزات (غير مضاف للصافي)'.tr(),
                  totalDebtCollectedRev,
                ),
                summaryRow(
                  'اتحصّل فعليًا من آجل قديم (كاش)'.tr(),
                  _debtCollectedInPeriod,
                ),
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

  String _formatQty(Map<String, dynamic> item, double qty) {
    final isWeighted = item['is_weighted'] as bool;
    if (!isWeighted) return qty.toInt().toString();
    return qty
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  List<Map<String, dynamic>> get _filteredReport {
    var list = _report.where((d) => (d['sold_qty'] as double) > 0).toList();

    if (_searchQuery.isNotEmpty) {
      list =
          list
              .where(
                (d) => (d['name'] as String).toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
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
