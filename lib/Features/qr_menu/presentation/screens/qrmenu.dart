// =====================================================================
// menu_screen.dart  —  واجهة العميل (QR Menu)
// فتحها من QR Code اللي بيحتوي على:
//   /menu?table_id=3&table_name=ترابيزة%203
//
// مثال الاستدعاء من QR:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => MenuScreen(tableId: 3, tableName: 'ترابيزة 3'),
//   ));
// =====================================================================

import 'package:flutter/material.dart';

import 'package:saytarly/core/database/db_helper.dart';
// عدّل المسار
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/qrmenu_mobile_body.dart';
part 'desktop/qrmenu_windows_body.dart';

class MenuScreen extends StatefulWidget {
  final int tableId;
  final String tableName;

  const MenuScreen({
    Key? key,
    required this.tableId,
    required this.tableName,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allDrinks = [];
  final Map<int, int> _cart = {}; // drinkId → qty
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  late TabController _tabController;
  String _note = '';

  // فئات العرض — بتتحمّل من أقسام السوبر ادمن
  List<Map<String, dynamic>> _categories = [
    {'label': 'الكل', 'temps': null},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadCategories();
    _loadDrinks();
  }

  /// تحميل القوائم الفرعية من أقسام السوبر ادمن
  Future<void> _loadCategories() async {
    try {
      final modules = await DBHelper.getModules(enabledOnly: true);
      final moduleIds = modules.map((m) => m['id'] as int).toSet();
      final cats = (await DBHelper.getCategories(enabledOnly: true))
          .where((c) => moduleIds.contains(c['module_id'] as int?))
          .where((c) => (c['key'] as String? ?? '') != 'cigarette')
          .toList();

      final list = <Map<String, dynamic>>[
        {'label': 'الكل', 'temps': null},
        for (final c in cats)
          {
            'label':
                '${_emojiForCategory(c['key'] as String? ?? '')} ${c['name']}',
            'temps': c['key'],
          },
      ];

      if (!mounted) return;
      _tabController.dispose();
      setState(() {
        _categories = list;
        _tabController = TabController(length: _categories.length, vsync: this);
      });
    } catch (_) {
      // لو حصل خطأ نسيب تاب "الكل" زي ما هو
    }
  }

  String _emojiForCategory(String key) {
    switch (key) {
      case 'hot':
        return '☕';
      case 'cold':
        return '🧊';
      case 'normal':
        return '🥤';
      case 'prodect':
        return '🛍';
      case 'cigarette':
        return '🚬';
      case 'shisha':
        return '💨';
      default:
        return '🍽';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrinks() async {
    final response = await http.get(
      Uri.parse('http://192.168.100.5:5000/menu'),
    );

    final drinks = List<Map<String, dynamic>>.from(jsonDecode(response.body));

    setState(() {
      _allDrinks = drinks;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _filteredDrinks(dynamic temps) {
    if (temps == null) return _allDrinks;
    return _allDrinks.where((d) => d['temperature'] == temps).toList();
  }

  int get _cartTotal => _cart.entries.fold(0, (sum, e) => sum + e.value);

  double get _cartPrice {
    double total = 0;
    for (final e in _cart.entries) {
      final drink =
          _allDrinks.firstWhere((d) => d['id'] == e.key, orElse: () => {});
      if (drink.isNotEmpty) {
        total += (drink['price'] as num).toDouble() * e.value;
      }
    }
    return total;
  }

  void _addToCart(int drinkId) {
    setState(() => _cart[drinkId] = (_cart[drinkId] ?? 0) + 1);
  }

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

    final items = _cart.entries.map((e) {
      final drink = _allDrinks.firstWhere((d) => d['id'] == e.key);
      return {
        'drink_id': e.key,
        'drink_name': drink['name'],
        'qty': e.value,
        'price': (drink['price'] as num).toDouble(),
      };
    }).toList();
    await http.post(
      Uri.parse('http://192.168.100.5:5000/order'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tableId': widget.tableId,
        'tableName': widget.tableName,
        'note': _note,
        'items': items,
      }),
    );
    setState(() {
      _submitting = false;
      _submitted = true;
    });
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
