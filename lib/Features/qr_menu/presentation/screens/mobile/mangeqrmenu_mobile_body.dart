part of '../mangeqrmenu.dart';

/// جسم شاشة طلبات المنيو (كاشير/أدمن) — نسخة الموبايل (زي ما كانت بالظبط).
extension _CashierOrdersScreenMobileBody on _CashierOrdersScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          title: Row(
            children: [
               Text('📦 طلبات المنيو'.tr(),
                  style: TextStyle(color: Colors.white)),
              if (pendingCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadOrders,
            ),
            if (widget.isAdmin)
              IconButton(
                icon: const Icon(Icons.qr_code, color: Colors.amber),
                tooltip: 'عرض QR كودات الترابيزات'.tr(),
                onPressed: _showQrCodes,
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: _CashierOrdersScreenState._tabs.map((t) => Tab(text: t['label']!)).toList(),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber))
            : TabBarView(
                controller: _tabController,
                children: _CashierOrdersScreenState._tabs.map((t) {
                  final orders = _filteredOrders(t['status']!);
                  if (orders.isEmpty) {
                    return _buildEmpty(t['status']!);
                  }
                  return RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: orders.length,
                      itemBuilder: (_, i) => _buildOrderCard(orders[i]),
                    ),
                  );
                }).toList(),
              ),
        // ============ ملخص الأدمن في الأسفل ============
        bottomNavigationBar: widget.isAdmin ? _buildAdminSummary() : null,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final items = order['items'] as List<Map<String, dynamic>>;
    final total = (order['total'] as double);
    final createdAt = DateTime.tryParse(order['created_at'] as String);
    final timeAgo = createdAt != null ? _timeAgo(createdAt) : '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = '🔔 جديد'.tr();
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusLabel = '✅ مقبول'.tr();
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusLabel = '🚫 ملغي'.tr();
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Container(
      margin:  EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:  Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'pending' ? Colors.orange : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Container(
            padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius:
                   BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  order['table_name'] as String,
                  style:  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                 Spacer(),
                Container(
                  padding:
                       EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 12)),
                ),
                 SizedBox(width: 8),
                Text(timeAgo,
                    style:
                         TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),

          // ===== Items =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            '${item['qty']}×',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['drink_name'] as String,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                          Text(
                            '{v1} ج'.tr({'v1': (item['total'] as num).toStringAsFixed(0)}),
                            style:  TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    )),

                // ملاحظة
                if ((order['note'] as String?)?.isNotEmpty == true) ...[
                  const Divider(color: Colors.white12),
                  Row(
                    children: [
                      const Icon(Icons.note, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order['note'] as String,
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي: {v1} ج'.tr({'v1': total.toStringAsFixed(0)}),
                      style:  TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    if (status == 'pending') ...[
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            icon: const Icon(Icons.close, size: 16),
                            label:  Text('رفض'.tr()),
                            onPressed: () => _cancelOrder(order['id'] as int),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label:  Text('قبول'.tr()),
                            onPressed: () => _acceptOrder(order),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String status) {
    final msgs = {
      'pending': ('🎉', 'مفيش طلبات جديدة دلوقتي'.tr()),
      'accepted': ('📋', 'مفيش طلبات مقبولة'.tr()),
      'cancelled': ('✅', 'مفيش طلبات ملغية'.tr()),
    };
    final m = msgs[status] ?? ('📦', '');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(m.$1, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(m.$2,
              style: const TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  // ===== ملخص الأدمن =====
  Widget _buildAdminSummary() {
    final accepted = _orders.where((o) => o['status'] == 'accepted').toList();
    final totalRevenue =
        accepted.fold<double>(0, (s, o) => s + (o['total'] as double));
    final pending = _orders.where((o) => o['status'] == 'pending').length;
    final cancelled = _orders.where((o) => o['status'] == 'cancelled').length;

    return Container(
      color: const Color(0xFF0F3460),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('🔔 جديد'.tr(), '$pending', Colors.orange),
          _summaryItem('✅ مقبول'.tr(), '${accepted.length}', Colors.green),
          _summaryItem('🚫 ملغي'.tr(), '$cancelled', Colors.red),
          _summaryItem(
              '💰 دخل'.tr(), '{v1} ج'.tr({'v1': totalRevenue.toStringAsFixed(0)}), Colors.amber),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  // ===== QR كودات الترابيزات =====
  Future<void> _showQrCodes() async {
    final db = await DBHelper.database;
    final tables = await db.query('tables');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
             Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '📱 QR كودات الترابيزات'.tr(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tables.length,
                itemBuilder: (_, i) {
                  final table = tables[i];
                  final tableId = table['id'] as int;
                  final tableName = table['name'] as String;
                  // الرابط اللي هيتحول لـ QR
                  final url =
                      'xocafe://menu?table_id=$tableId&table_name=${Uri.encodeComponent(tableName)}';

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.qr_code, color: Colors.black),
                    ),
                    title: Text(tableName,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      url,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.print, color: Colors.amber),
                      onPressed: () {
                        // هنا تضيف كود الطباعة أو QR generation
                        // مثلاً: QrPainter أو qr_flutter package
                        Navigator.pop(context);
                        AppToast.show('طباعة QR لـ {tableName}\n{url}'.tr({'tableName': tableName, 'url': url}));
                      },
                    ),
                  );
                },
              ),
            ),
            // ملاحظة الـ QR
             Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '💡 استخدم qr_flutter package لتوليد QR\nأو اطبع الـ URL واستخدم أي QR generator'.tr(),
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // وقت مضى
  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'دلوقتي'.tr();
    if (diff.inMinutes < 60) return 'منذ {v1} د'.tr({'v1': diff.inMinutes});
    return 'منذ {v1} س'.tr({'v1': diff.inHours});
  }
}
