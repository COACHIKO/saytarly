import 'package:flutter/material.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/app_modules.dart';
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/core/services/app_settings.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/add_drinks_mobile_body.dart';
part 'desktop/add_drinks_windows_body.dart';

class AddDrinksScreen extends StatefulWidget {
  final int invoiceId;
  AddDrinksScreen({required this.invoiceId});

  @override
  State<AddDrinksScreen> createState() => _AddDrinksScreenState();
}

class _AddDrinksScreenState extends State<AddDrinksScreen> {
  List<DrinkModel> drinks = [];
  Map<int, int> qtyMap = {}; // لتخزين كمية كل مشروب قبل الإضافة (وضع القائمة)
  String searchQuery = '';
  bool _isLoading = false;

  // 🆕 التحكم في نوع التصميم
  bool _isPosMode = false;

  // 🆕 سلة الطلب (وضع الكاشير) — drinkId -> qty
  final Map<int, int> _cartQty = {};

  // 🆕 الفئة المختارة في وضع الكاشير
  String _selectedCategory = 'all'; // 🆕 بدل 'hot'

  int? selectedDrinkId;

  bool _cigarettesEnabled = false;
  bool _shishaEnabled = false;

  // 🆕 القوائم الفرعية (من أقسام السوبر ادمن)
  List<Map<String, dynamic>> _categories = [];
  Set<int> _enabledModuleIds = {};

  List<Map<String, dynamic>> get _visibleCategories =>
      _categories.where((c) {
        final key = c['key'] as String? ?? '';
        if (key == 'cigarette' && !_cigarettesEnabled) return false;
        if (key == 'shisha' && !_shishaEnabled) return false;
        return true;
      }).toList();

  // 🆕 تبويب الفئات — لوحة الويندوز
  String _windowsTab = 'all';

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _load();
    _loadDefaultMode();
    _loadFeatureFlags(); // 🆕
  }

  Future<void> _loadFeatureFlags() async {
    final cig = await AppSettings.getCigarettesEnabled();
    final shisha = await AppSettings.getShishaEnabled();
    if (!mounted) return;
    setState(() {
      _cigarettesEnabled = cig;
      _shishaEnabled = shisha;
    });
  }

  // 🆕 يقرأ الوضع الافتراضي المحفوظ من الأدمن ويطبقه
  Future<void> _loadDefaultMode() async {
    final savedMode = await AppSettings.getDrinksScreenPosMode();
    if (!mounted) return;
    setState(() => _isPosMode = savedMode);
  }

  Future<void> _load() async {
    final rows = await DBHelper.getAllDrinks();
    final modules = await DBHelper.getModules(enabledOnly: true);
    final moduleIds = modules.map((m) => m['id'] as int).toSet();
    final cats =
        (await DBHelper.getCategories(
          enabledOnly: true,
        )).where((c) => moduleIds.contains(c['module_id'] as int?)).toList();
    if (!mounted) return;
    setState(() {
      drinks = rows.map((r) => DrinkModel.fromMap(r)).toList();
      _categories = cats;
      _enabledModuleIds = moduleIds;
      for (var d in drinks) qtyMap[d.id!] = 1;
    });
  }

  List<DrinkModel> _filterDrinks(List<DrinkModel> list) {
    if (searchQuery.isEmpty) return list;
    return list.where((d) => d.matchesQuery(searchQuery)).toList();
  }

  // ============================================================
  // 🆕 منطق مشترك: إضافة صنف واحد للفاتورة فعليًا (يستخدمه الوضعين)
  // بيرجع true لو نجح، وبيعرض رسالة خطأ لو فشل.
  // ============================================================
  Future<bool> _addSingleItemToInvoice(DrinkModel d, int qty) async {
    final db = await DBHelper.database;
    final stockData = await db.query(
      'drinks',
      columns: ['qty'],
      where: 'id = ?',
      whereArgs: [d.id],
    );

    if (stockData.isEmpty) {
      _showSnack('المشروب غير موجود'.tr());
      return false;
    }

    final currentStock = stockData.first['qty'] as int;
    if (qty > currentStock) {
      _showSnack(
        'الكمية ({qty}) أكبر من المتاح ({currentStock}) لـ {v3}'.tr({
          'qty': qty,
          'currentStock': currentStock,
          'v3': d.displayName,
        }),
      );
      return false;
    }

    final canMake = await DBHelper.canConsumeRecipe(d.id!, qty);
    if (!canMake) {
      _showSnack('لا توجد خامات كافية لـ {v1}'.tr({'v1': d.displayName}));
      return false;
    }

    await DBHelper.addInvoiceItem(
      widget.invoiceId,
      d.id!,
      qty,
      d.price,
      d.displayName,
    );
    await DBHelper.consumeRecipe(d.id!, qty);
    await DBHelper.updateInvoiceDrinksCost(widget.invoiceId);
    await db.update(
      'drinks',
      {'qty': currentStock - qty},
      where: 'id = ?',
      whereArgs: [d.id],
    );
    return true;
  }

  void _showSnack(String text) {
    if (!mounted) return;
    AppToast.show(text);
  }

  // ============================================================
  // 🆕 وضع الكاشير: إضافة/إنقاص صنف في السلة المؤقتة
  // ============================================================
  void _incrementCart(DrinkModel d) {
    setState(() {
      _cartQty[d.id!] = (_cartQty[d.id!] ?? 0) + 1;
    });
  }

  void _decrementCart(int drinkId) {
    setState(() {
      final current = _cartQty[drinkId] ?? 0;
      if (current <= 1) {
        _cartQty.remove(drinkId);
      } else {
        _cartQty[drinkId] = current - 1;
      }
    });
  }

  void _removeFromCart(int drinkId) {
    setState(() => _cartQty.remove(drinkId));
  }

  double get _cartTotal {
    double total = 0;
    _cartQty.forEach((id, qty) {
      final drink = drinks.firstWhere(
        (d) => d.id == id,
        orElse: () => DrinkModel(id: id, name: '', price: 0, temperature: ''),
      );
      total += drink.price * qty;
    });
    return total;
  }

  // 🆕 تأكيد الطلب بالكامل — بيضيف كل أصناف السلة للفاتورة
  Future<void> _confirmCartOrder() async {
    if (_cartQty.isEmpty) {
      _showSnack('السلة فاضية'.tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      // نسخة ثابتة من السلة عشان نلف عليها بأمان
      final entries = Map<int, int>.from(_cartQty);
      int successCount = 0;

      for (final entry in entries.entries) {
        final drink = drinks.firstWhere(
          (d) => d.id == entry.key,
          orElse:
              () => DrinkModel(
                id: entry.key,
                name: '',
                price: 0,
                temperature: '',
              ),
        );
        if (drink.displayName.isEmpty) continue;

        final ok = await _addSingleItemToInvoice(drink, entry.value);
        if (ok) {
          successCount++;
          setState(() => _cartQty.remove(entry.key));
        }
      }

      await _load();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (successCount > 0) {
        _showSnack(
          '✅ تمت إضافة {successCount} صنف للفاتورة'.tr({
            'successCount': successCount,
          }),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('خطأ: {e}'.tr({'e': e}));
    }
  }

  // ============================================================
  // 📋 الوضع الأصلي (List + Tabs) — لازم يتلف بـ DefaultTabController
  // ============================================================
  /*
  Widget _buildListModeWrapper() {
    return DefaultTabController(
      length: 4,
      child: _buildListModeBody(),
    );
  }
*/

  // ============================================================
  // 🖥️ وضع الكاشير (POS): شبكة أيقونات + فاتورة الطلب في السايد
  // ============================================================
  Map<String, String> get _categoryLabels => {
    'all': 'الكل'.tr(),
    for (final c in _visibleCategories)
      (c['key'] as String? ?? ''): AppModuleCategory.displayNameFromMap(c),
  };
  IconData _iconForTemperature(String? temp) {
    switch (temp) {
      case 'hot':
        return Icons.local_cafe;
      case 'cold':
        return Icons.ac_unit;
      case 'normal':
        return Icons.bubble_chart;
      case 'prodect':
        return Icons.shopping_bag;
      case 'cigarette':
        return Icons.smoking_rooms;
      case 'shisha':
        return Icons.blur_on;
      default:
        return Icons.local_drink;
    }
  }

  // ============================================================
  // 🆕 رايل عمودي للفئات — أيقونة فوق واسم تحتها، مرصوصين فوق بعض
  // ============================================================
  Map<String, IconData> get _categoryIcons => {
    'all': Icons.apps_rounded,
    for (final c in _visibleCategories)
      (c['key'] as String? ?? ''): _iconForTemperature(c['key'] as String?),
  };

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
