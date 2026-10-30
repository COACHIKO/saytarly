// =====================================================================
// menu_screen.dart  —  واجهة العميل عبر Supabase
// =====================================================================

import 'package:flutter/material.dart';
import 'package:saytarly/Features/qr_menu/data/supabase_orders_service.dart'; // عدّل المسار
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/menu_screen_supabase_mobile_body.dart';
part 'desktop/menu_screen_supabase_windows_body.dart';

class MenuScreen extends StatefulWidget {
  final int tableId;
  final String tableName;

  const MenuScreen({Key? key, required this.tableId, required this.tableName})
    : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allDrinks = [];
  final Map<int, int> _cart = {};
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  late TabController _tabController;
  String _note = '';
  String? _error;

  static List<Map<String, Object?>> get _categories => [
    {'label': 'الكل'.tr(), 'temps': null},
    {'label': '☕ ساخن'.tr(), 'temps': 'hot'},
    {'label': '🧊 بارد'.tr(), 'temps': 'cold'},
    {'label': '🥤 عادي'.tr(), 'temps': 'normal'},
    {'label': '🛍 منتجات'.tr(), 'temps': 'prodect'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadDrinks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrinks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drinks = await SupabaseOrdersService.getMenuFromSupabase();
      setState(() {
        _allDrinks = drinks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل المنيو. تحقق من الاتصال.'.tr();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredDrinks(dynamic temps) {
    if (temps == null) return _allDrinks;
    return _allDrinks.where((d) => d['temperature'] == temps).toList();
  }

  int get _cartTotal => _cart.entries.fold(0, (sum, e) => sum + e.value);

  double get _cartPrice {
    double total = 0;
    for (final e in _cart.entries) {
      final drink = _allDrinks.firstWhere(
        (d) => d['id'] == e.key,
        orElse: () => {},
      );
      if (drink.isNotEmpty) {
        total += (drink['price'] as num).toDouble() * e.value;
      }
    }
    return total;
  }

  void _addToCart(int drinkId) =>
      setState(() => _cart[drinkId] = (_cart[drinkId] ?? 0) + 1);

  void _removeFromCart(int drinkId) {
    setState(() {
      final qty = (_cart[drinkId] ?? 0) - 1;
      if (qty <= 0) {
        _cart.remove(drinkId);
      } else {
        _cart[drinkId] = qty;
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _submitting = true);

    try {
      final items =
          _cart.entries.map((e) {
            final drink = _allDrinks.firstWhere((d) => d['id'] == e.key);
            return {
              'drink_id': e.key,
              'drink_name': drink['name'],
              'qty': e.value,
              'price': (drink['price'] as num).toDouble(),
            };
          }).toList();

      await SupabaseOrdersService.createOrderInSupabase(
        tableId: widget.tableId,
        tableName: widget.tableName,
        items: items,
        note: _note.trim().isEmpty ? null : _note.trim(),
      );

      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _submitting = false);
      AppToast.show(
        '❌ فشل إرسال الطلب، حاول مرة تانية'.tr(),
        kind: FeedbackKind.error,
      );
    }
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
