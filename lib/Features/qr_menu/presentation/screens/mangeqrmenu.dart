// =====================================================================
// cashier_orders_screen.dart
// شاشة الكاشير + الأدمن لإدارة طلبات المنيو
//
// الاستدعاء:
//   CashierOrdersScreen(
//     staffName: widget.staffName,
//     shiftId: widget.shiftId,
//     isAdmin: false,   // true للأدمن
//   )
// =====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/mangeqrmenu_mobile_body.dart';
part 'desktop/mangeqrmenu_windows_body.dart';

// عدّل المسار

class CashierOrdersScreen extends StatefulWidget {
  final String staffName;
  final int shiftId;
  final bool isAdmin;

  const CashierOrdersScreen({
    Key? key,
    required this.staffName,
    required this.shiftId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<CashierOrdersScreen> createState() => _CashierOrdersScreenState();
}

class _CashierOrdersScreenState extends State<CashierOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  Timer? _timer;
  late TabController _tabController;

  static const _tabs = [
    {'label': '🔔 جديد', 'status': 'pending'},
    {'label': '✅ مقبول', 'status': 'accepted'},
    {'label': '🚫 ملغي', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
    // تحديث تلقائي كل 10 ثواني
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    /* await DBHelper.createOrdersTables();*/
    final orders = await DBHelper.getAllOrders();

    // جلب عناصر كل طلب
    final enriched = <Map<String, dynamic>>[];
    for (final order in orders) {
      final items = await DBHelper.getOrderItems(order['id'] as int);
      final total =
          items.fold<double>(0, (s, i) => s + (i['total'] as num).toDouble());
      enriched.add({...order, 'items': items, 'total': total});
    }

    if (mounted) {
      setState(() {
        _orders = enriched;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredOrders(String status) =>
      _orders.where((o) => o['status'] == status).toList();

  // ===================== قبول الطلب =====================
  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final orderId = order['id'] as int;
    final tableId = order['table_id'] as int;

    // نشوف لو الترابيزة عندها فاتورة مفتوحة
    final db = await DBHelper.database;
    final tableRow = await db.query('tables',
        where: 'id = ?', whereArgs: [tableId], limit: 1);

    int? invoiceId;
    if (tableRow.isNotEmpty) {
      invoiceId = tableRow.first['active_invoice_id'] as int?;
    }

    // لو مفيش فاتورة → أنشئها
    if (invoiceId == null) {
      invoiceId = await DBHelper.createInvoice(
        0,
        DateTime.now().toIso8601String(),
        staffName: widget.staffName,
        shiftId: widget.shiftId,
      );
      // ربط الترابيزة بالفاتورة
      await DBHelper.updateTableActiveInvoice(tableId, invoiceId);
    }

    await DBHelper.acceptOrder(
      orderId: orderId,
      invoiceId: invoiceId,
      staffName: widget.staffName,
      shiftId: widget.shiftId,
    );

    _showSnack('✅ تم قبول الطلب وإضافته للفاتورة'.tr(), Colors.green);
    _loadOrders();
  }

  // ===================== رفض الطلب =====================
  Future<void> _cancelOrder(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title:  Text('إلغاء الطلب'.tr()),
        content:  Text('هل تريد إلغاء هذا الطلب؟'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:  Text('لا'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:  Text('إلغاء الطلب'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DBHelper.cancelOrder(orderId);
      _showSnack('🚫 تم إلغاء الطلب'.tr(), Colors.red);
      _loadOrders();
    }
  }

  void _showSnack(String msg, Color color) {
    AppToast.show(msg);
  }

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
