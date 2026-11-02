// =====================================================================
// cashier_orders_screen.dart  —  كاشير/أدمن مع Supabase Realtime
// =====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saytarly/Features/qr_menu/data/supabase_orders_service.dart'; // عدّل المسار
// عدّل المسار
import 'package:saytarly/core/database/db_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/cashier_orders_screen_supabase_mobile_body.dart';
part 'desktop/cashier_orders_screen_supabase_windows_body.dart';

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
  late TabController _tabController;
  RealtimeChannel? _realtimeChannel;
  bool _hasNewOrder = false; // للإشعار الصوتي/البصري
// في _showQrCodes غير الـ url لـ:

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
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  // ===== Realtime: طلبات جديدة فورية =====
  void _subscribeToRealtime() {
    _realtimeChannel = SupabaseOrdersService.listenToNewOrders(() async {
      await _loadOrders();
      if (mounted) {
        setState(() => _hasNewOrder = true);
        // أخفي الإشعار بعد 3 ثواني
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _hasNewOrder = false);
        });
      }
    });
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await SupabaseOrdersService.getAllOrdersWithItems();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _filteredOrders(String status) =>
      _orders.where((o) => o['status'] == status).toList();

  // ===== قبول الطلب =====
  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    try {
      await SupabaseOrdersService.acceptOrderFromSupabase(
        order: order,
        staffName: widget.staffName,
        shiftId: widget.shiftId,
      );
      _showSnack('✅ تم قبول الطلب وإضافته للفاتورة'.tr(), Colors.green);
      _loadOrders();
    } catch (e) {
      _showSnack('❌ حصل خطأ: {e}'.tr({'e': e}), Colors.red);
    }
  }

  // ===== إلغاء الطلب =====
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
      await SupabaseOrdersService.cancelOrderInSupabase(orderId);
      _showSnack('🚫 تم إلغاء الطلب'.tr(), Colors.red);
      _loadOrders();
    }
  }

  // ===== مزامنة المنيو =====
  Future<void> _syncMenu() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AppDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري مزامنة المنيو...'.tr()),
          ],
        ),
      ),
    );
    try {
      await SupabaseOrdersService.syncMenuToSupabase();
      if (!mounted) return; // الشاشة قفلت أثناء المزامنة — ما نلمس contextش
      Navigator.pop(context);
      _showSnack('✅ تم تحديث المنيو بنجاح'.tr(), Colors.green);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('❌ فشل المزامنة: {e}'.tr({'e': e}), Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
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
