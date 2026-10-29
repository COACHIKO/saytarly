import 'package:flutter/material.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/Features/cashier/presentation/screens/add_drinks.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/drinks_invoice_screen_mobile_body.dart';
part 'desktop/drinks_invoice_screen_windows_body.dart';

class DrinksInvoiceScreen extends StatefulWidget {
  final int invoiceId;
  DrinksInvoiceScreen({required this.invoiceId});

  @override
  State<DrinksInvoiceScreen> createState() => _DrinksInvoiceScreenState();
}

class _DrinksInvoiceScreenState extends State<DrinksInvoiceScreen> {
  List<Map<String, dynamic>> items = [];
  double totalDrinksCost = 0;
  final Map<int, TextEditingController> qtyControllers = {};

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    qtyControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadItems() async {
    final its = await DBHelper.getItemsForInvoice(widget.invoiceId);
    items = its.map((e) => Map<String, dynamic>.from(e)).toList();

    totalDrinksCost = items.fold(
      0,
      (sum, it) => sum + (it['total'] as num).toDouble(),
    );

    // إنشاء الـ controllers مرة واحدة فقط
    qtyControllers.clear();
    for (var it in items) {
      qtyControllers[it['id'] as int] = TextEditingController(
        text: it['qty'].toString(),
      );
    }

    setState(() {});
  }

  void _updateItemQty(int itemId) async {
    final db = await DBHelper.database;
    final controller = qtyControllers[itemId]!;

    int newQty = int.tryParse(controller.text) ?? 1;
    if (newQty < 1) newQty = 1;

    // 🟢 جلب بيانات العنصر القديمة
    final oldItemData = await db.query(
      'invoice_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    if (oldItemData.isEmpty) return;

    final oldQty = oldItemData.first['qty'] as int;
    final drinkId = oldItemData.first['drink_id'] as int;

    // 🟢 جلب المخزون الحالي
    final drinkData = await db.query(
      'drinks',
      columns: ['qty'],
      where: 'id = ?',
      whereArgs: [drinkId],
    );

    if (drinkData.isEmpty) return;

    final currentStock = drinkData.first['qty'] as int;

    // 🟡 حساب الفرق
    final diff = newQty - oldQty;

    // 🟢 لو زاد الكمية => خصم من المخزون
    if (diff > 0) {
      if (diff > currentStock) {
        AppToast.show('الكمية المطلوبة ({v1}) أكبر من المتاحة ({v2})'.tr({'v1': newQty, 'v2': currentStock + oldQty}));
        // نرجع القيمة القديمة في TextField
        controller.text = oldQty.toString();
        return;
      }
      await db.update(
        'drinks',
        {'qty': currentStock - diff},
        where: 'id = ?',
        whereArgs: [drinkId],
      );
      await DBHelper.consumeRecipe(
        drinkId,
        diff,
      );
    }

    // 🟢 لو قل الكمية => رجّع الفرق للمخزون
    else if (diff < 0) {
      await db.update(
        'drinks',
        {'qty': currentStock + (-diff)}, // diff بالسالب
        where: 'id = ?',
        whereArgs: [drinkId],
      );
      await DBHelper.restoreRecipe(
        drinkId,
        -diff,
      );
    }

    // 🟢 تحديث الكمية في الفاتورة
    final price = (oldItemData.first['total'] as num) / oldQty;
    final newTotal = price * newQty;

    await DBHelper.updateInvoiceItemQty(itemId, newQty, newTotal);

    // 🟢 تحديث الواجهة
    final index = items.indexWhere((it) => it['id'] == itemId);
    if (index != -1) {
      setState(() {
        items[index]['qty'] = newQty;
        items[index]['total'] = newTotal;
        totalDrinksCost = items.fold(
          0,
          (sum, it) => sum + (it['total'] as num).toDouble(),
        );
      });
    }

    AppToast.show('✅ تم تعديل الكمية وتحديث المخزون'.tr());
  }

  void _removeItem(int itemId) async {
    // 🟢 أولاً: جلب بيانات العنصر قبل الحذف
    final db = await DBHelper.database;
    final itemData = await db.query(
      'invoice_items', // اسم جدول العناصر
      where: 'id = ?',
      whereArgs: [itemId],
    );

    if (itemData.isEmpty) return;

    final drinkId = itemData.first['drink_id'] as int;
    final qty = itemData.first['qty'] as int;

    // 🟢 جلب الكمية الحالية في المخزون
    final drinkData = await db.query(
      'drinks',
      columns: ['qty'],
      where: 'id = ?',
      whereArgs: [drinkId],
    );

    if (drinkData.isNotEmpty) {
      final currentStock = drinkData.first['qty'] as int;
      final newStock = currentStock + qty;

      // 🟢 تحديث المخزون بعد الإرجاع
      await db.update(
        'drinks',
        {'qty': newStock},
        where: 'id = ?',
        whereArgs: [drinkId],
      );
      await DBHelper.restoreRecipe(
        drinkId,
        qty,
      );
    }

    // 🟢 حذف العنصر من الفاتورة
    await DBHelper.deleteInvoiceItem(itemId);

    // 🟢 تحديث الواجهة
    setState(() {
      items.removeWhere((it) => it['id'] == itemId);
      qtyControllers[itemId]?.dispose();
      qtyControllers.remove(itemId);
      totalDrinksCost = items.fold(
        0,
        (sum, it) => sum + (it['total'] as num).toDouble(),
      );
    });

    // 🟢 إعلام المستخدم
    AppToast.show('✅ تم حذف المشروب وإرجاع الكمية للمخزون'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

