// =====================================================================
// supabase_orders_service.dart
// خدمة Supabase للطلبات والمنيو
//
// في main.dart أضف:
//   await Supabase.initialize(
//     url: 'https://xmhchkutuyzqhkcybxfp.supabase.co',
//     anonKey: 'YOUR_ANON_KEY',   ← من Project Settings > API
//   );
// =====================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saytarly/core/database/db_helper.dart';
// عدّل المسار

class SupabaseOrdersService {
  static SupabaseClient get _client => Supabase.instance.client;

  // =====================================================================
  // 🔄 مزامنة المنيو من SQLite → Supabase
  // استدعيها مرة واحدة عند بداية الشيفت أو تحديث المنيو
  // =====================================================================
  static Future<void> syncMenuToSupabase() async {
    final db = await DBHelper.database;
    final drinks = await db.query(
      'drinks',
      where: "temperature NOT IN ('cigarette')",
    );

    // امسح المنيو القديم وارفع الجديد
    await _client.from('menu_drinks').delete().neq('id', 0);

    for (final drink in drinks) {
      await _client.from('menu_drinks').upsert({
        'id': drink['id'],
        'name': drink['name'],
        'price': drink['price'],
        'temperature': drink['temperature'] ?? 'normal',
      });
    }

    print('✅ Menu synced to Supabase: ${drinks.length} items');
  }

  // =====================================================================
  // 📋 جلب المنيو من Supabase (للعميل)
  // =====================================================================
  static Future<List<Map<String, dynamic>>> getMenuFromSupabase() async {
    final response = await _client.from('menu_drinks').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // =====================================================================
  // 📤 إرسال طلب جديد إلى Supabase (من العميل)
  // =====================================================================
  static Future<int> createOrderInSupabase({
    required int tableId,
    required String tableName,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    // إنشاء الطلب
    final orderResponse = await _client
        .from('orders')
        .insert({
          'table_id': tableId,
          'table_name': tableName,
          'status': 'pending',
          'note': note,
        })
        .select('id')
        .single();

    final orderId = orderResponse['id'] as int;

    // إضافة العناصر
    for (final item in items) {
      final total = (item['price'] as double) * (item['qty'] as int);
      await _client.from('order_items').insert({
        'order_id': orderId,
        'drink_id': item['drink_id'],
        'drink_name': item['drink_name'],
        'qty': item['qty'],
        'price': item['price'],
        'total': total,
      });
    }

    return orderId;
  }

  // =====================================================================
  // 📥 جلب كل الطلبات (للكاشير/الأدمن) مع عناصرها
  // =====================================================================
  static Future<List<Map<String, dynamic>>> getAllOrdersWithItems({
    String? status,
  }) async {
    var query = _client
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);

    if (status != null) {
      query = _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('status', status)
          .order('created_at', ascending: false);
    }

    final response = await query;
    final orders = List<Map<String, dynamic>>.from(response);

    // احسب الإجمالي لكل طلب
    return orders.map((order) {
      final items = List<Map<String, dynamic>>.from(order['order_items'] ?? []);
      final total =
          items.fold<double>(0, (s, i) => s + (i['total'] as num).toDouble());
      return {...order, 'items': items, 'total': total};
    }).toList();
  }

  // =====================================================================
  // ✅ قبول الطلب (كاشير) → يتحول لـ SQLite + Supabase status updated
  // =====================================================================
  static Future<void> acceptOrderFromSupabase({
    required Map<String, dynamic> order,
    required String staffName,
    required int shiftId,
  }) async {
    final orderId = order['id'] as int;
    final tableId = order['table_id'] as int;
    final items = List<Map<String, dynamic>>.from(order['order_items'] ?? []);

    // 1️⃣ شوف لو الترابيزة عندها فاتورة
    final db = await DBHelper.database;
    final tableRow = await db.query('tables',
        where: 'id = ?', whereArgs: [tableId], limit: 1);

    int? invoiceId = tableRow.isNotEmpty
        ? tableRow.first['active_invoice_id'] as int?
        : null;

    // 2️⃣ لو مفيش فاتورة → أنشئها
    if (invoiceId == null) {
      invoiceId = await DBHelper.createInvoice(
        0,
        DateTime.now().toIso8601String(),
        staffName: staffName,
        shiftId: shiftId,
      );
      await DBHelper.updateTableActiveInvoice(tableId, invoiceId);
    }

    // 3️⃣ أضف العناصر للفاتورة في SQLite
    for (final item in items) {
      final drinkId = item['drink_id'] as int;
      final qty = item['qty'] as int;
      final price = (item['price'] as num).toDouble();
      final drinkName = item['drink_name'] as String;

      await DBHelper.addInvoiceItem(invoiceId, drinkId, qty, price, drinkName);
      await DBHelper.consumeRecipe(drinkId, qty);
    }

    // 4️⃣ حدّث حالة الطلب في Supabase
    await _client.from('orders').update({
      'status': 'accepted',
      'invoice_id': invoiceId,
    }).eq('id', orderId);

    print('✅ Order $orderId accepted → Invoice $invoiceId');
  }

  // =====================================================================
  // 🚫 إلغاء الطلب
  // =====================================================================
  static Future<void> cancelOrderInSupabase(int orderId) async {
    await _client
        .from('orders')
        .update({'status': 'cancelled'}).eq('id', orderId);
  }

  // =====================================================================
  // 🔴 Realtime listener للكاشير (طلبات جديدة)
  // الاستخدام:
  //   final channel = SupabaseOrdersService.listenToNewOrders(() => _loadOrders());
  //   // عند dispose:
  //   channel.unsubscribe();
  // =====================================================================
  static RealtimeChannel listenToNewOrders(VoidCallback onNewOrder) {
    return _client
        .channel('orders_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (_) => onNewOrder(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (_) => onNewOrder(),
        )
        .subscribe();
  }

  // =====================================================================
  // 📊 إجمالي الطلبات المقبولة
  // =====================================================================
  static Future<double> getAcceptedOrdersTotal() async {
    final response = await _client
        .from('order_items')
        .select('total, orders!inner(status)')
        .eq('orders.status', 'accepted');

    final items = List<Map<String, dynamic>>.from(response);
    return items.fold<double>(0, (s, i) => s + (i['total'] as num).toDouble());
  }
}

// alias لتبسيط الاستخدام في الـ widgets
typedef VoidCallback = void Function();
