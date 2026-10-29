import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/localization/messages.dart';

class MenuServer {
  static HttpServer? _server;
  static String? localIp;

  static Future<void> start() async {
    // جيب الـ IP المحلي
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          localIp = addr.address;
          break;
        }
      }
    }

    final router = Router();

    // الصفحة الرئيسية — HTML المنيو
    router.get('/menu', (Request req) async {
      final tableId = req.url.queryParameters['table_id'] ?? '0';
      final tableName = Uri.decodeComponent(
          req.url.queryParameters['table_name'] ?? 'ترابيزة'.tr());

      // 🆕 القوائم الفرعية من أقسام السوبر ادمن
      final categories = <Map<String, dynamic>>[
        {'label': 'الكل', 'temp': null},
      ];
      try {
        final modules = await DBHelper.getModules(enabledOnly: true);
        final moduleIds = modules.map((m) => m['id'] as int).toSet();
        final cats = (await DBHelper.getCategories(enabledOnly: true))
            .where((c) => moduleIds.contains(c['module_id'] as int?))
            .where((c) => (c['key'] as String? ?? '') != 'cigarette');
         final catEmojis = {
          'hot': '☕',
          'cold': '🧊',
          'normal': '🥤',
          'prodect': '🛍',
          'cigarette': '🚬',
          'shisha': '💨',
        };
        for (final c in cats) {
          final key = c['key'] as String? ?? '';
          categories.add({
            'label': '${catEmojis[key] ?? '🍽'} ${c['name']}',
            'temp': key,
          });
        }
      } catch (_) {
        // لو حصل خطأ نعرض "الكل" بس
      }

      final html = _buildMenuHtml(
        tableId,
        tableName,
        categoriesJson: jsonEncode(categories),
      );
      return Response.ok(html,
          headers: {'Content-Type': 'text/html; charset=utf-8'});
    });

    // API: جلب المنيو
    router.get('/api/menu', (Request req) async {
      final db = await DBHelper.database;

      // 🆕 بس أصناف الأقسام المفعّلة
      final modules = await DBHelper.getModules(enabledOnly: true);
      final moduleIds = modules.map((m) => m['id'] as int).toList();

      String where;
      List<Object?> args;
      if (moduleIds.isEmpty) {
        where = "temperature NOT IN ('cigarette') AND module_id IS NULL";
        args = [];
      } else {
        final placeholders = List.filled(moduleIds.length, '?').join(',');
        where =
            "temperature NOT IN ('cigarette') AND (module_id IN ($placeholders) OR module_id IS NULL)";
        args = [...moduleIds];
      }

      final drinks = await db.query(
        'drinks',
        where: where,
        whereArgs: args,
        orderBy: 'temperature, name',
      );
      return Response.ok(
        jsonEncode(drinks),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );
    });

    // API: إرسال طلب
    router.post('/api/order', (Request req) async {
      final body = await req.readAsString();
      final data = jsonDecode(body);

      await DBHelper.createOrder(
        tableId: data['tableId'],
        tableName: data['tableName'],
        note: data['note'],
        items: List<Map<String, dynamic>>.from(data['items']),
      );

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );
    });

    _server = await io.serve(router.call, InternetAddress.anyIPv4, 8080);
    print('✅ Server: http://$localIp:8080');
  }

  static Future<void> stop() async {
    await _server?.close();
  }

  // ===== HTML المنيو =====
  static String _buildMenuHtml(
    String tableId,
    String tableName, {
    String? categoriesJson,
  }) {
    categoriesJson ??= '[{"label":"الكل","temp":null}]'.tr();
    return '\r\n<!DOCTYPE html>\r\n<html lang="ar" dir="rtl">\r\n<head>\r\n  <meta charset="UTF-8">\r\n  <meta name="viewport" content="width=device-width, initial-scale=1.0">\r\n  <title>منيو {tableName}</title>\r\n  <style>\r\n    * { margin: 0; padding: 0; box-sizing: border-box; }\r\n    body { background: #1A1A2E; color: white; font-family: Arial, sans-serif; }\r\n    \r\n    .header {\r\n      background: #16213E;\r\n      padding: 16px;\r\n      text-align: center;\r\n      position: sticky;\r\n      top: 0;\r\n      z-index: 100;\r\n      box-shadow: 0 2px 10px rgba(0,0,0,0.3);\r\n    }\r\n    .header h2 { color: #FFD700; font-size: 18px; }\r\n    .header p { color: #aaa; font-size: 13px; }\r\n\r\n    .tabs {\r\n      display: flex;\r\n      overflow-x: auto;\r\n      background: #16213E;\r\n      padding: 0 8px;\r\n      gap: 4px;\r\n      scrollbar-width: none;\r\n    }\r\n    .tab {\r\n      padding: 10px 16px;\r\n      white-space: nowrap;\r\n      cursor: pointer;\r\n      border-bottom: 2px solid transparent;\r\n      color: #aaa;\r\n      font-size: 13px;\r\n    }\r\n    .tab.active { color: #FFD700; border-bottom-color: #FFD700; }\r\n\r\n    .grid {\r\n      display: grid;\r\n      grid-template-columns: repeat(2, 1fr);\r\n      gap: 10px;\r\n      padding: 12px;\r\n    }\r\n\r\n    .card {\r\n      background: #16213E;\r\n      border-radius: 14px;\r\n      padding: 14px 10px;\r\n      text-align: center;\r\n      border: 2px solid transparent;\r\n      transition: border-color 0.2s;\r\n    }\r\n    .card.in-cart { border-color: #FFD700; }\r\n    .card .emoji { font-size: 28px; }\r\n    .card .name {\r\n      font-size: 13px;\r\n      font-weight: bold;\r\n      margin: 6px 0 4px;\r\n      min-height: 36px;\r\n      display: flex;\r\n      align-items: center;\r\n      justify-content: center;\r\n    }\r\n    .card .price { color: #FFD700; font-size: 13px; }\r\n\r\n    .add-btn {\r\n      margin-top: 8px;\r\n      background: #FFD700;\r\n      color: black;\r\n      border: none;\r\n      border-radius: 20px;\r\n      padding: 5px 18px;\r\n      font-weight: bold;\r\n      cursor: pointer;\r\n      font-size: 13px;\r\n    }\r\n    .qty-ctrl {\r\n      display: flex;\r\n      align-items: center;\r\n      justify-content: center;\r\n      gap: 12px;\r\n      margin-top: 8px;\r\n    }\r\n    .qty-btn {\r\n      width: 28px; height: 28px;\r\n      background: #FFD700;\r\n      border: none;\r\n      border-radius: 50%;\r\n      font-size: 16px;\r\n      cursor: pointer;\r\n      font-weight: bold;\r\n    }\r\n    .qty-num { font-size: 16px; font-weight: bold; }\r\n\r\n    .cart-bar {\r\n      position: fixed;\r\n      bottom: 0; left: 0; right: 0;\r\n      background: #0F3460;\r\n      padding: 12px 16px;\r\n      display: none;\r\n    }\r\n    .cart-bar.visible { display: block; }\r\n    .note-input {\r\n      width: 100%;\r\n      background: transparent;\r\n      border: none;\r\n      border-bottom: 1px solid #444;\r\n      color: white;\r\n      padding: 6px 0;\r\n      font-size: 14px;\r\n      margin-bottom: 10px;\r\n      outline: none;\r\n    }\r\n    .note-input::placeholder { color: #555; }\r\n    .cart-row {\r\n      display: flex;\r\n      align-items: center;\r\n      justify-content: space-between;\r\n    }\r\n    .cart-info { font-size: 14px; }\r\n    .cart-info span { color: white; font-weight: bold; }\r\n    .send-btn {\r\n      background: #FFD700;\r\n      color: black;\r\n      border: none;\r\n      border-radius: 12px;\r\n      padding: 10px 20px;\r\n      font-weight: bold;\r\n      font-size: 14px;\r\n      cursor: pointer;\r\n    }\r\n    .send-btn:disabled { opacity: 0.6; }\r\n\r\n    .thanks {\r\n      display: none;\r\n      text-align: center;\r\n      padding: 80px 20px;\r\n    }\r\n    .thanks .big { font-size: 80px; }\r\n    .thanks h2 { font-size: 24px; margin: 16px 0 8px; }\r\n    .thanks p { color: #aaa; }\r\n    .new-order-btn {\r\n      margin-top: 30px;\r\n      background: #FFD700;\r\n      color: black;\r\n      border: none;\r\n      border-radius: 12px;\r\n      padding: 12px 30px;\r\n      font-size: 16px;\r\n      cursor: pointer;\r\n      font-weight: bold;\r\n    }\r\n  </style>\r\n</head>\r\n<body>\r\n\r\n<div id="menu-page">\r\n  <div class="header">\r\n    <h2>📋 المنيو</h2>\r\n    <p id="table-name">{tableName}</p>\r\n  </div>\r\n\r\n  <div class="tabs" id="tabs"></div>\r\n  <div class="grid" id="grid"></div>\r\n\r\n  <div class="cart-bar" id="cart-bar">\r\n    <input class="note-input" id="note" placeholder="ملاحظة للطلب (اختياري)">\r\n    <div class="cart-row">\r\n      <div class="cart-info">\r\n        <span id="cart-count">0</span> صنف &nbsp;|&nbsp;\r\n        <span id="cart-price">0</span> ج\r\n      </div>\r\n      <button class="send-btn" id="send-btn" onclick="sendOrder()">\r\n        ➤ أرسل الطلب\r\n      </button>\r\n    </div>\r\n  </div>\r\n</div>\r\n\r\n<div class="thanks" id="thanks-page">\r\n  <div class="big">✅</div>\r\n  <h2>تم إرسال طلبك!</h2>\r\n  <p>{tableName}</p>\r\n  <p style="margin-top:8px;color:#aaa">سيتم تحضير طلبك قريباً 🎉</p>\r\n  <button class="new-order-btn" onclick="newOrder()">🔄 طلب جديد</button>\r\n</div>\r\n\r\n<script>\r\n  const TABLE_ID = {tableId};\r\n  const TABLE_NAME = \'{tableName}\';\r\n  \r\n  let allDrinks = [];\r\n  let cart = {};\r\n  let currentTab = null;\r\n\r\n  const categories = {categoriesJson};\r\n\r\n  const emojis = { hot:\'☕\', cold:\'🧊\', normal:\'🥤\', prodect:\'🛍\' };\r\n\r\n  async function loadMenu() {\r\n    try {\r\n      const res = await fetch(\'/api/menu\');\r\n      allDrinks = await res.json();\r\n      buildTabs();\r\n      renderGrid(null);\r\n    } catch(e) {\r\n      document.getElementById(\'grid\').innerHTML =\r\n        \'<p style="text-align:center;color:#aaa;grid-column:span 2;padding:40px">تعذر تحميل المنيو</p>\';\r\n    }\r\n  }\r\n\r\n  function buildTabs() {\r\n    const tabs = document.getElementById(\'tabs\');\r\n    categories.forEach((cat, i) => {\r\n      const tab = document.createElement(\'div\');\r\n      tab.className = \'tab\' + (i === 0 ? \' active\' : \'\');\r\n      tab.textContent = cat.label;\r\n      tab.onclick = () => {\r\n        document.querySelectorAll(\'.tab\').forEach(t => t.classList.remove(\'active\'));\r\n        tab.classList.add(\'active\');\r\n        currentTab = cat.temp;\r\n        renderGrid(cat.temp);\r\n      };\r\n      tabs.appendChild(tab);\r\n    });\r\n  }\r\n\r\n  function renderGrid(temp) {\r\n    const filtered = temp ? allDrinks.filter(d => d.temperature === temp) : allDrinks;\r\n    const grid = document.getElementById(\'grid\');\r\n    \r\n    if (filtered.length === 0) {\r\n      grid.innerHTML = \'<p style="text-align:center;color:#aaa;grid-column:span 2;padding:40px">لا يوجد منتجات</p>\';\r\n      return;\r\n    }\r\n\r\n    grid.innerHTML = filtered.map(d => `\r\n      <div class="card \${(cart[d.id]||0)>0?\'in-cart\':\'\'}" id="card-\${d.id}">\r\n        <div class="emoji">\${emojis[d.temperature]||\'🍹\'}</div>\r\n        <div class="name">\${d.name}</div>\r\n        <div class="price">\${d.price} ج</div>\r\n        \${(cart[d.id]||0) === 0\r\n          ? `<button class="add-btn" onclick="addToCart(\${d.id})">إضافة</button>`\r\n          : `<div class="qty-ctrl">\r\n              <button class="qty-btn" onclick="removeFromCart(\${d.id})">−</button>\r\n              <span class="qty-num">\${cart[d.id]}</span>\r\n              <button class="qty-btn" onclick="addToCart(\${d.id})">+</button>\r\n            </div>`\r\n        }\r\n      </div>\r\n    `).join(\'\');\r\n  }\r\n\r\n  function addToCart(id) {\r\n    cart[id] = (cart[id] || 0) + 1;\r\n    updateCartBar();\r\n    renderGrid(currentTab);\r\n  }\r\n\r\n  function removeFromCart(id) {\r\n    cart[id] = (cart[id] || 0) - 1;\r\n    if (cart[id] <= 0) delete cart[id];\r\n    updateCartBar();\r\n    renderGrid(currentTab);\r\n  }\r\n\r\n  function updateCartBar() {\r\n    const bar = document.getElementById(\'cart-bar\');\r\n    const ids = Object.keys(cart);\r\n    if (ids.length === 0) { bar.classList.remove(\'visible\'); return; }\r\n    bar.classList.add(\'visible\');\r\n\r\n    let total = 0, count = 0;\r\n    ids.forEach(id => {\r\n      const drink = allDrinks.find(d => d.id == id);\r\n      if (drink) { total += drink.price * cart[id]; count += cart[id]; }\r\n    });\r\n    document.getElementById(\'cart-count\').textContent = count;\r\n    document.getElementById(\'cart-price\').textContent = total.toFixed(0);\r\n  }\r\n\r\n  async function sendOrder() {\r\n    const btn = document.getElementById(\'send-btn\');\r\n    btn.disabled = true;\r\n    btn.textContent = \'جاري الإرسال...\';\r\n\r\n    const items = Object.keys(cart).map(id => {\r\n      const drink = allDrinks.find(d => d.id == id);\r\n      return { drink_id: parseInt(id), drink_name: drink.name,\r\n               qty: cart[id], price: drink.price };\r\n    });\r\n\r\n    try {\r\n      await fetch(\'/api/order\', {\r\n        method: \'POST\',\r\n        headers: { \'Content-Type\': \'application/json\' },\r\n        body: JSON.stringify({\r\n          tableId: TABLE_ID,\r\n          tableName: TABLE_NAME,\r\n          note: document.getElementById(\'note\').value,\r\n          items\r\n        })\r\n      });\r\n\r\n      document.getElementById(\'menu-page\').style.display = \'none\';\r\n      document.getElementById(\'thanks-page\').style.display = \'block\';\r\n    } catch(e) {\r\n      alert(\'فشل إرسال الطلب، حاول مرة تانية\');\r\n      btn.disabled = false;\r\n      btn.textContent = \'➤ أرسل الطلب\';\r\n    }\r\n  }\r\n\r\n  function newOrder() {\r\n    cart = {};\r\n    document.getElementById(\'note\').value = \'\';\r\n    document.getElementById(\'menu-page\').style.display = \'block\';\r\n    document.getElementById(\'thanks-page\').style.display = \'none\';\r\n    renderGrid(currentTab);\r\n  }\r\n\r\n  loadMenu();\r\n</script>\r\n</body>\r\n</html>\r\n'.tr({'tableName': tableName, 'tableId': tableId, 'categoriesJson': categoriesJson});
  }
}
