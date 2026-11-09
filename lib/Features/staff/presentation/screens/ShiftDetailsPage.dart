import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/models.dart';

import 'package:intl/intl.dart';

import 'package:saytarly/Features/reports/presentation/screens/AuditLogScreen.dart';
import 'package:saytarly/Features/auth/viewmodel/current_user.dart';
import 'package:saytarly/Features/playstation/presentation/print/PlaystationInvoicePrinter.dart';
import 'package:saytarly/Features/debts/presentation/print/invoice_debet_print.dart';
import 'package:saytarly/Features/cashier/presentation/print/drinks_invoice_print.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/shift_details_page_mobile_body.dart';
part 'desktop/shift_details_page_windows_body.dart';

class ShiftDetailsPage extends StatefulWidget {
  final int shiftId;
  final String staffName;
  final int staffId;
  const ShiftDetailsPage({
    Key? key,
    required this.shiftId,
    required this.staffName,
    required this.staffId,
  }) : super(key: key);

  @override
  State<ShiftDetailsPage> createState() => _ShiftDetailsPageState();
}

class _ShiftDetailsPageState extends State<ShiftDetailsPage> {
  late Future<void> _loadDataFuture;
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> debts = [];
  List<Map<String, dynamic>> transactions = [];

  // 🆕 الدفعات المحصّلة من الآجل خلال هذا الشيفت
  List<Map<String, dynamic>> debtPayments = [];
  double totalDebtCollected = 0.0;
  double totalDebtDiscount = 0.0;

  // 🆕 ملخص الأصناف والمنتجات المباعة في الشيفت
  List<Map<String, dynamic>> productsSummary = [];

  Map<int, String> consoleNames = {};
  bool canViewSummary = false;
  double totalOpenPartialCollected = 0.0; // 🆕
  static const Color paidColor = Color(0xFF2E9E64);
  static const Color debtColor = Color(0xFFE0574C);
  static const Color cancelColor = Color(0xFF9AA0A6);
  static const Color collectedColor = Color(0xFF1F8A70);

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadData();
  }

  Future<void> _reload() async {
    setState(() {
      _loadDataFuture = _loadData();
    });
    await _loadDataFuture;
  }

  double vodafoneCashTotal = 0.0;
  List<Map<String, dynamic>> vodafoneCashNotes = [];
  Future<void> _loadData() async {
    final db = await DBHelper.database;

    final invoiceRows = await DBHelper.getInvoicesByShift(widget.shiftId);
    productsSummary = await DBHelper.getShiftProductsSummary(widget.shiftId);
    final consoleRows = await db.query('consoles');
    consoleNames = {
      for (var c in consoleRows)
        (c['id'] as int): (c['name'] as String? ?? 'غير معروف'.tr()),
    };
    invoices = [];

    for (var inv in invoiceRows) {
      Map<String, dynamic> invoice = Map.from(inv);

      double paidPartial = 0.0;
      double remainingDebt = 0.0;
      final bool isOpen = invoice['end_time'] == null;

      if (invoice['payment_type'] == 'علي الحساب' ||
          invoice['payment_type'] == 'debt') {
        final debtRows = await db.query(
          'debts',
          where: 'invoice_id = ?',
          whereArgs: [invoice['id']],
        );

        if (debtRows.isNotEmpty) {
          final debtId = debtRows.first['id'];
          final debtPaymentsRows = await db.query(
            'debt_payments',
            where: 'debt_id = ?',
            whereArgs: [debtId],
          );

          paidPartial = debtPaymentsRows.fold<double>(
            0.0,
            (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
          );

          remainingDebt =
              ((invoice['total_cost'] as num?)?.toDouble() ?? 0.0) -
              paidPartial;
        } else {
          remainingDebt = (invoice['total_cost'] as num?)?.toDouble() ?? 0.0;
        }
      } else if (isOpen) {
        // 🆕 هات أي دفعة جزئية اتحصّلت والفاتورة لسه شغالة
        final partial = await DBHelper.getPartialPaymentsTotal(
          invoice['id'] as int,
        );
        paidPartial = partial;
        remainingDebt =
            0.0; // مفيش "باقي" لأن الفاتورة لسه مفتوحة ومش متحدد إجماليها
      } else {
        paidPartial = (invoice['total_cost'] as num?)?.toDouble() ?? 0.0;
      }

      invoice['paid_partial'] = paidPartial;
      invoice['remaining_debt'] = remainingDebt;
      invoice['is_open'] = isOpen;

      invoices.add(invoice);
    }

    // 💰 نصيب الشيفت ده من كل فاتورة: الباقي اللي اتحصّل وقت التسليم هنا
    // بعد خصم الدفعات الجزئية اللي اتحصّلت في شيفتات تانية (تسليم شيفت).
    final priorPartialsByInvoice = await DBHelper.getPartialsByInvoice(
      invoiceIds: invoices.map((inv) => inv['id']).whereType<int>().toList(),
      excludeShiftId: widget.shiftId,
    );
    for (final inv in invoices) {
      final type = (inv['payment_type'] ?? '').toString();
      final total = (inv['total_cost'] as num?)?.toDouble() ?? 0.0;
      final prior =
          type == 'ملغي'
              ? 0.0
              : (priorPartialsByInvoice[(inv['id'] as num).toInt()] ?? 0.0);
      if (type == 'ملغي') {
        inv['shift_paid'] = 0.0;
      } else if (type == 'علي الحساب' || type == 'debt') {
        // هيتحدّد بعدين من دفعات الآجل اللي اتحصّلت في نطاق الشيفت.
        inv['shift_paid'] = (inv['paid_partial'] as double?) ?? 0.0;
      } else {
        inv['shift_paid'] = (total - prior).clamp(0.0, double.infinity);
      }
      inv['prior_partials'] = prior;
    }
    expenses = await DBHelper.getExpensesByShift(widget.shiftId);

    transactions = await DBHelper.getTransactionsByShift(widget.shiftId);
    final rawDebts = await DBHelper.getDebtsByShift(widget.shiftId);
    debts = [];
    for (var d in rawDebts) {
      final debtMap = Map<String, dynamic>.from(d);
      final debtId = debtMap['id'] as int;
      final payments = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );
      final paid = payments.fold<double>(
        0.0,
        (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
      );
      final total = (debtMap['total_amount'] as num?)?.toDouble() ?? 0.0;
      debtMap['paid_partial'] = paid;
      debtMap['remaining_amount'] =
          (total - paid).clamp(0, double.infinity).toDouble();
      debts.add(debtMap);
    }
    final shiftRow = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [widget.shiftId],
    );
    final checkIn =
        shiftRow.isNotEmpty ? shiftRow.first['check_in'] as String? : null;
    final checkOut =
        shiftRow.isNotEmpty ? shiftRow.first['check_out'] as String? : null;

    final rangeStart = checkIn ?? DateTime.now().toIso8601String();
    final rangeEnd = checkOut ?? DateTime.now().toIso8601String();

    final currentShiftInvoiceIds =
        invoices.map((inv) => inv['id']).whereType<int>().toSet();

    final debtPaymentsRowsRaw = await db.query(
      'debt_payments',
      where: 'paid_at >= ? AND paid_at <= ?',
      whereArgs: [rangeStart, rangeEnd],
      orderBy: 'paid_at ASC',
    );

    debtPayments =
        debtPaymentsRowsRaw.where((p) {
          final invId = p['invoice_id'];
          if (invId == null) return true;
          return !currentShiftInvoiceIds.contains(invId as int);
        }).toList();

    // 💰 الآجل: نصيب الشيفت ده = الدفعات اللي اتحصّلت في نطاقه بس
    // (الدفعة الجزئية المرحّلة لدين بتفضل على شيفت التحصيل الأصلي).
    final debtPaidInRangeByInvoice = <int, double>{};
    for (final p in debtPaymentsRowsRaw) {
      final invId = p['invoice_id'];
      if (invId == null) continue;
      final id = (invId as num).toInt();
      debtPaidInRangeByInvoice[id] =
          (debtPaidInRangeByInvoice[id] ?? 0.0) +
          ((p['amount'] ?? 0) as num).toDouble();
    }
    for (final inv in invoices) {
      final type = (inv['payment_type'] ?? '').toString();
      if (type != 'علي الحساب' && type != 'debt') continue;
      inv['shift_paid'] =
          debtPaidInRangeByInvoice[(inv['id'] as num).toInt()] ?? 0.0;
    }

    totalDebtCollected = debtPayments.fold<double>(
      0.0,
      (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble(),
    );
    totalDebtDiscount = debtPayments.fold<double>(
      0.0,
      (sum, p) => sum + ((p['discount'] ?? 0) as num).toDouble(),
    );
    // 💰 كل الدفعات الجزئية اللي اتحصّلت خلال الشيفت ده — حتى لو الفاتورة
    // نفسها اتحوّلت لشيفت تاني بتسليم شيفت (الفلوس دخلت هنا). بنستبعد
    // الفواتير المتسجلة في الشيفت لأن مدفوعاتها محسوبة جوه الفواتير.
    final shiftPartialRows = await DBHelper.getShiftPartialPayments(
      widget.shiftId,
    );
    final settledShiftInvoiceIds =
        invoices
            .where((inv) => inv['end_time'] != null)
            .map((inv) => inv['id'])
            .whereType<int>()
            .toSet();
    totalOpenPartialCollected = shiftPartialRows
        .where((p) {
          final invId = p['invoice_id'];
          if (invId == null) return true;
          return !settledShiftInvoiceIds.contains((invId as num).toInt());
        })
        .fold<double>(0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());
    vodafoneCashTotal = await DBHelper.getVodafoneCashTotal(widget.shiftId);
    vodafoneCashNotes = await DBHelper.getVodafoneCashNotes(widget.shiftId);
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd – HH:mm').format(date);
    } catch (_) {
      return '-';
    }
  }

  Future<bool> _confirmCashierPassword(BuildContext context) async {
    final passController = TextEditingController();
    bool isValid = false;
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AppDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: cs.primary),
              const SizedBox(width: 8),
              Text('تأكيد كلمة المرور'.tr()),
            ],
          ),
          content: TextField(
            controller: passController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'أدخل كلمة المرور'.tr(),
              prefixIcon: Icon(Icons.key),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passController.text.trim();
                final user = await DBHelper.getUserById(widget.staffId);

                if (user != null && user['password'] == password) {
                  isValid = true;
                  Navigator.pop(ctx);
                } else {
                  AppToast.show(
                    'كلمة المرور غير صحيحة'.tr(),
                    kind: FeedbackKind.error,
                  );
                }
              },
              child: Text('تأكيد'.tr()),
            ),
          ],
        );
      },
    );

    return isValid;
  }

  void _showMessage(String text) {
    if (!mounted) return;
    AppToast.show(text);
  }

  // ---------------- 🆕 تعديل دين مستقل ----------------
  Future<void> _openEditDebt(Map<String, dynamic> debt) async {
    final debtId = debt['id'] as int;
    final invoiceId = debt['invoice_id'] as int;
    final items = await DBHelper.getDebtItems(debtId);
    if (!mounted) return;

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => _EditDebtSheet(
            debtId: debtId,
            initialCustomerName: (debt['customer_name'] ?? '').toString(),
            initialItems: items,
            invoiceId: invoiceId,
          ),
    );

    if (changed == true) {
      await _reload();
      _showMessage('✅ تم تحديث الدين'.tr());
    }
  }

  Future<double> _getDebtPaidTotal(int debtId) async {
    final db = await DBHelper.database;
    final res = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) as s FROM debt_payments WHERE debt_id = ?',
      [debtId],
    );
    return (res.first['s'] as num?)?.toDouble() ?? 0.0;
  }

  // ---------------- 🆕 إلغاء دين مستقل بالكامل ----------------
  Future<void> _handleCancelDebt(Map<String, dynamic> debt) async {
    final debtId = debt['id'] as int;

    final alreadyCollected = await _getDebtPaidTotal(
      debtId,
    ); // ⬅️ بدل transactions.where

    final confirmed = await _showCancelConfirmDialog(
      title: 'إلغاء الدين نهائيًا؟'.tr(),
      customerName: (debt['customer_name'] ?? '').toString(),
      alreadyCollected: alreadyCollected,
    );
    if (!confirmed) return;

    final ok = await _confirmCashierPassword(context);
    if (!ok) return;

    await DBHelper.cancelDebt(debtId);
    await _reload();
    _showMessage('✅ تم إلغاء الدين وإرجاع المخزون بالكامل'.tr());
  }

  // ---------------- 🆕 إلغاء فاتورة آجلة (invoice) ----------------
  Future<void> _handleCancelDebtInvoice(Map<String, dynamic> inv) async {
    final invoiceId = inv['id'] as int;

    Map<String, dynamic>? matchingDebt;
    for (final d in debts) {
      if (d['invoice_id'] == invoiceId) {
        matchingDebt = d;
        break;
      }
    }

    double alreadyCollected = 0.0;
    if (matchingDebt != null) {
      alreadyCollected = await _getDebtPaidTotal(
        matchingDebt['id'] as int,
      ); // ⬅️ بدل transactions.where
    } else {
      alreadyCollected = (inv['paid_partial'] as double?) ?? 0.0;
    }

    final confirmed = await _showCancelConfirmDialog(
      title: 'إلغاء الفاتورة الآجلة نهائيًا؟'.tr(),
      customerName: (inv['customer_name'] ?? '').toString(),
      alreadyCollected: alreadyCollected,
    );
    if (!confirmed) return;

    final ok = await _confirmCashierPassword(context);
    if (!ok) return;

    if (matchingDebt != null) {
      await DBHelper.cancelDebt(matchingDebt['id'] as int);
    } else {
      await DBHelper.cancelDebtInvoiceDirect(invoiceId);
    }

    await _reload();
    _showMessage('✅ تم إلغاء الفاتورة وإرجاع المخزون بالكامل'.tr());
  }

  Future<bool> _showCancelConfirmDialog({
    required String title,
    required String customerName,
    required double alreadyCollected,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AppDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customerName.isNotEmpty)
                  Text(
                    'العميل: {customerName}'.tr({'customerName': customerName}),
                  ),
                const SizedBox(height: 8),
                Text(
                  'هيتم إرجاع كل الأصناف للمخزون والفاتورة هتتحوّل لـ "ملغي".'
                      .tr(),
                ),
                if (alreadyCollected > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ فيه مبلغ اتحصّل سابقًا: {v1}  {v2} — الإلغاء ده هيرجّعه تلقائيًا.'
                        .tr({
                          'v1': alreadyCollected.toStringAsFixed(2),
                          'v2': Money.txt,
                        }),
                    style: TextStyle(
                      color: cs.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('تراجع'.tr()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: cs.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('إلغاء الفاتورة'.tr()),
              ),
            ],
          ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  // ---------------- 🆕 تفاصيل الفاتورة ----------------
  Future<void> _showInvoiceDetails(Map<String, dynamic> inv) async {
    final db = await DBHelper.database;
    final items = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [inv['id']],
    );

    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;

    String fmt(dynamic v) => ((v as num?) ?? 0).toDouble().toStringAsFixed(2);

    final consoleId = inv['console_id'] as int?;
    final consoleName =
        consoleId != null
            ? (consoleNames[consoleId] ?? 'غير معروف'.tr())
            : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary),
                      SizedBox(width: 8),
                      Text(
                        'تفاصيل الفاتورة'.tr(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  _detailRow(
                    'العميل'.tr(),
                    inv['customer_name'] ?? 'غير معروف'.tr(),
                  ),
                  _detailRow('نوع الدفع'.tr(), inv['payment_type'] ?? '-'),
                  if (consoleName != null &&
                      ((inv['device_cost'] ?? 0) as num).toDouble() != 0)
                    _detailRow('الجهاز'.tr(), consoleName),
                  if (consoleName != null &&
                      ((inv['device_cost'] ?? 0) as num).toDouble() != 0)
                    _detailRow('من'.tr(), formatDate(inv['start_time'])),
                  _detailRow('غلق فاتوره'.tr(), formatDate(inv['end_time'])),
                  const Divider(height: 24),
                  Text(
                    'الأصناف'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'لا توجد أصناف مسجلة'.tr(),
                        style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                      ),
                    )
                  else
                    ...items
                        .where((it) {
                          final isPlaystation =
                              it['item_type'] == 'playstation';
                          final total = ((it['total'] ?? 0) as num).toDouble();
                          return !(isPlaystation && total == 0);
                        })
                        .map((it) {
                          final name =
                              it['item_type'] == 'playstation'
                                  ? 'وقت بلايستيشن'.tr()
                                  : (it['drink_name'] ?? 'صنف'.tr());
                          final qty = it['qty'] ?? 1;
                          final total = it['total'] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text('$name  ×$qty')),
                                Text('${fmt(total)} ${Money.txt}'),
                              ],
                            ),
                          );
                        }),
                  Divider(height: 24),
                  if (((inv['device_cost'] ?? 0) as num).toDouble() != 0)
                    _detailRow(
                      'تكلفة الجهاز'.tr(),
                      '${fmt(inv['device_cost'])} ${Money.txt}',
                    ),
                  if (((inv['drinks_cost'] ?? 0) as num).toDouble() != 0)
                    _detailRow(
                      'تكلفة المشروبات'.tr(),
                      '${fmt(inv['drinks_cost'])} ${Money.txt}',
                    ),
                  if (((inv['cigarettes_cost'] ?? 0) as num).toDouble() != 0)
                    _detailRow(
                      'تكلفة السجائر'.tr(),
                      '${fmt(inv['cigarettes_cost'])} ${Money.txt}',
                    ),
                  if (((inv['shisha_cost'] ?? 0) as num).toDouble() != 0)
                    _detailRow(
                      'تكلفة الشيشة'.tr(),
                      '${fmt(inv['shisha_cost'])} ${Money.txt}',
                    ),
                  if ((inv['discount'] ?? 0) != 0)
                    _detailRow(
                      'الخصم'.tr(),
                      '${fmt(inv['discount'])} ${Money.txt}',
                    ),
                  _detailRow(
                    'الإجمالي'.tr(),
                    '${fmt(inv['total_cost'])} ${Money.txt}',
                    bold: true,
                  ),
                  if ((inv['paid_partial'] ?? 0) != 0)
                    _detailRow(
                      'مدفوع جزئيًا'.tr(),
                      '${fmt(inv['paid_partial'])} ${Money.txt}',
                    ),
                  if ((inv['remaining_debt'] ?? 0) != 0)
                    _detailRow(
                      'الباقي (آجل)'.tr(),
                      '${fmt(inv['remaining_debt'])} ${Money.txt}',
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addVodafoneCashNote() async {
    final amountCtl = TextEditingController();
    final noteCtl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AppDialog(
            title: Text('إضافة ملحوظة فودافون كاش'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'المبلغ'.tr()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtl,
                  decoration: InputDecoration(
                    labelText: 'ملحوظة (اختياري)'.tr(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtl.text.trim()) ?? 0;
                  if (amount <= 0) return;

                  await DBHelper.addVodafoneCashNote(
                    shiftId: widget.shiftId,
                    amount: amount,
                    note: noteCtl.text.trim(),
                    addedBy: CurrentUser.displayName,
                  );

                  Navigator.pop(ctx);
                  await _reload();
                },
                child: Text('حفظ'.tr()),
              ),
            ],
          ),
    );
  }
}

// ============================================================
// 🆕 Bottom sheet تعديل دين — كل التغييرات بتتجمّع محليًا وتتبعت
// لقاعدة البيانات مرة واحدة عند الحفظ (عشان لو المستخدم قفل الشيت
// من غير حفظ، مفيش حاجة اتغيرت في المخزون أو الفواتير).
// ============================================================
class _EditableDebtItem {
  final int? id; // null = صنف جديد لسه ماتسجلش
  final int? drinkId;
  String name;
  int qty;
  final int originalQty;
  final double price;

  _EditableDebtItem({
    this.id,
    this.drinkId,
    required this.name,
    required this.qty,
    required this.originalQty,
    required this.price,
  });

  double get total => price * qty;
}

class _EditDebtSheet extends StatefulWidget {
  final int debtId;
  final String initialCustomerName;
  final List<Map<String, dynamic>> initialItems;
  final int invoiceId;
  const _EditDebtSheet({
    required this.debtId,
    required this.initialCustomerName,
    required this.initialItems,
    required this.invoiceId,
  });

  @override
  State<_EditDebtSheet> createState() => _EditDebtSheetState();
}

class _EditDebtSheetState extends State<_EditDebtSheet> {
  late TextEditingController _nameController;
  late List<_EditableDebtItem> _items;
  final List<int> _removedItemIds = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCustomerName);
    _items =
        widget.initialItems.map((e) {
          final qty = (e['qty'] as num?)?.toInt() ?? 0;
          return _EditableDebtItem(
            id: e['id'] as int?,
            drinkId: e['drink_id'] as int?,
            name: (e['drink_name'] ?? '').toString(),
            qty: qty,
            originalQty: qty,
            price: (e['price'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
  }

  double get _total => _items.fold(0.0, (sum, i) => sum + i.total);
  Future<void> _pickDrinkToAdd() async {
    final drinksRows = await DBHelper.getAllDrinks();
    final drinks = drinksRows.map((r) => DrinkModel.fromMap(r)).toList();
    if (!mounted) return;

    String query = '';
    final selected = await showModalBottomSheet<DrinkModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered =
                query.isEmpty
                    ? drinks
                    : drinks.where((d) => d.matchesQuery(query)).toList();
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'ابحث عن صنف'.tr(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setSheetState(() => query = v),
                    ),
                  ),
                  Expanded(
                    child:
                        filtered.isEmpty
                            ? Center(child: Text('لا توجد نتائج'.tr()))
                            : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final d = filtered[i];
                                final outOfStock = d.qty <= 0;

                                return ListTile(
                                  enabled: !outOfStock,
                                  title: Text(
                                    d.displayName,
                                    style: TextStyle(
                                      color: outOfStock ? Colors.grey : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    outOfStock
                                        ? 'غير متوفر بالمخزون'.tr()
                                        : 'المتاح: ${d.qty}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          outOfStock
                                              ? Colors.redAccent
                                              : Colors.grey.shade600,
                                      fontWeight:
                                          outOfStock
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: Text(
                                    '{v1} ج'.tr({
                                      'v1': d.price.toStringAsFixed(2),
                                    }),
                                    style: TextStyle(
                                      color: outOfStock ? Colors.grey : null,
                                    ),
                                  ),
                                  onTap:
                                      outOfStock
                                          ? null
                                          : () => Navigator.pop(ctx, d),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && selected.id != null) {
      // 🆕 نتأكد إن الكمية المطلوبة (بعد الزيادة لو الصنف مضاف قبل كده) متجاوزتش المتاح
      final existingIndex = _items.indexWhere(
        (i) => i.drinkId == selected.id && i.id == null,
      );
      final currentQtyInList =
          existingIndex != -1 ? _items[existingIndex].qty : 0;

      if (currentQtyInList + 1 > selected.qty) {
        if (!mounted) return;
        AppToast.show(
          'الكمية المطلوبة أكبر من المتاح ({v1})'.tr({'v1': selected.qty}),
          kind: FeedbackKind.error,
        );
        return;
      }

      setState(() {
        if (existingIndex != -1) {
          _items[existingIndex].qty += 1;
        } else {
          _items.add(
            _EditableDebtItem(
              id: null,
              drinkId: selected.id,
              name: selected.displayName,
              qty: 1,
              originalQty: 0,
              price: selected.price,
            ),
          );
        }
      });

      if (!mounted) return;
      AppToast.show('✅ تمت إضافة "{v1}"'.tr({'v1': selected.displayName}));
    }
  }

  void _removeItem(_EditableDebtItem item) {
    setState(() {
      if (item.id != null) _removedItemIds.add(item.id!);
      _items.remove(item);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty && newName != widget.initialCustomerName) {
        await DBHelper.updateDebtCustomerName(widget.debtId, newName);
      }

      // 1) الأصناف المحذوفة بالكامل
      for (final itemId in _removedItemIds) {
        await DBHelper.deleteDebtItem(
          debtId: widget.debtId,
          debtItemId: itemId,
          changedBy: CurrentUser.displayName,
        );
      }

      // 2) الأصناف الموجودة واللي اتغيرت كميتها
      for (final item in _items) {
        if (item.id != null && item.qty != item.originalQty) {
          final ok = await DBHelper.updateDebtItemQty(
            debtId: widget.debtId,
            debtItemId: item.id!,
            newQty: item.qty,
            changedBy: CurrentUser.displayName,
          );
          if (!ok) {
            _showError(
              'مخزون "{v1}" مش كفاية للكمية الجديدة'.tr({'v1': item.name}),
            );
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      // 3) الأصناف الجديدة
      for (final item in _items) {
        if (item.id == null && item.drinkId != null && item.qty > 0) {
          final ok = await DBHelper.addItemToDebt(
            debtId: widget.debtId,
            drinkId: item.drinkId!,
            drinkName: item.name,
            qty: item.qty,
            price: item.price,
            changedBy: CurrentUser.displayName,
          );
          if (!ok) {
            _showError('مخزون "{v1}" مش كفاية لإضافته'.tr({'v1': item.name}));
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError('حصل خطأ: {e}'.tr({'e': e}));
      setState(() => _isSaving = false);
    }
  }

  void _showError(String text) {
    if (!mounted) return;
    AppToast.show(text, kind: FeedbackKind.error);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تعديل الدين'.tr(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'إضافة صنف'.tr(),
                      onPressed: _pickDrinkToAdd,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم العميل'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    _items.isEmpty
                        ? Center(child: Text('مفيش أصناف'.tr()))
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            // 🆕 سطور التسوية (خصم / دفعة مقدمة) للعرض فقط، بدون تعديل أو حذف
                            final isLocked =
                                item.name == 'خصم' || item.name == 'دفعة مقدمة';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isLocked ? Colors.grey.shade100 : null,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    if (isLocked)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () => _removeItem(item),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '{v1} ج × {v2} = {v3} ج'.tr({
                                              'v1': item.price.toStringAsFixed(
                                                2,
                                              ),
                                              'v2': item.qty,
                                              'v3': item.total.toStringAsFixed(
                                                2,
                                              ),
                                            }),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isLocked) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed:
                                            () => setState(() {
                                              if (item.qty > 1) item.qty--;
                                            }),
                                      ),
                                      Text('${item.qty}'),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed:
                                            () => setState(() => item.qty++),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_total.toStringAsFixed(2)} ${Money.txt}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'الإجمالي الجديد'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text('حفظ التعديلات'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
