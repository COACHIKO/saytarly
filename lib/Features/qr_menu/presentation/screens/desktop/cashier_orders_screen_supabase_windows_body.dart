part of '../cashier_orders_screen_supabase.dart';

/// جسم شاشة طلبات المنيو عبر Supabase — نسخة الويندوز (Windows UI).
///
/// - تابات الحالة بـ [DesktopSegmented] ونفس الـ TabController.
/// - كل طلب كارت قابل للهوفر بنفس أزرار القبول/الرفض وبانر "طلب جديد وصل".
/// - ملخص الأدمن بانل جانبي (KPIs) بدل الشريط السفلي.
extension _CashierOrdersScreenWindowsBody on _CashierOrdersScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final tabs = _CashierOrdersScreenState._tabs;
    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;
    final status = tabs[_tabController.index]['status']!;
    final orders = _filteredOrders(status);

    return DesktopPageScaffold(
      title: 'طلبات المنيو'.tr(),
      subtitle: '{v1} • {v2} طلب'.tr({'v1': widget.staffName, 'v2': _orders.length}),
      scrollable: false,
      actions: [
        if (widget.isAdmin) ...[
          DesktopToolbarIconButton(
            icon: Icons.sync,
            tooltip: 'مزامنة المنيو مع Supabase'.tr(),
            onPressed: _syncMenu,
          ),
          DesktopToolbarIconButton(
            icon: Icons.qr_code_2_outlined,
            tooltip: 'QR كودات الترابيزات'.tr(),
            onPressed: _showQrCodes,
          ),
        ],
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث الطلبات'.tr(),
          onPressed: _loadOrders,
          badgeCount: pendingCount,
        ),
      ],
      headerBottom: _windowsTabs(context),
      child: _loading
          ? Center(child: CircularProgressIndicator(color: palette.accent))
          : Column(
              children: [
                if (_hasNewOrder) ...[
                  _windowsNewOrderBanner(context),
                  const SizedBox(height: DesktopTokens.gapMd),
                ],
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _windowsOrdersList(context, status, orders),
                      ),
                      if (widget.isAdmin) ...[
                        const SizedBox(width: DesktopTokens.gapMd),
                        SizedBox(width: 300, child: _windowsAdminPanel(context)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// بانر "طلب جديد وصل" — نفس إشعار الموبايل بس بستايل سطح المكتب.
  Widget _windowsNewOrderBanner(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.soft(palette.warning),
        borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
        border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 18,
            color: palette.warning,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Text(
              '🔔 طلب جديد وصل!'.tr(),
              style: TextStyle(
                color: palette.warning,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// صف التابات (جديد / مقبول / ملغي) بنفس الـ controller + عدّاد الجديد.
  Widget _windowsTabs(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final tabs = _CashierOrdersScreenState._tabs;
    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;

    return Row(
      children: [
        DesktopSegmented<int>(
          items: [
            for (var i = 0; i < tabs.length; i++)
              DesktopSegmentItem<int>(
                value: i,
                label:
                    '${_statusLabel(tabs[i]['status']!)} '
                    '(${_filteredOrders(tabs[i]['status']!).length})',
                icon: _statusIcon(tabs[i]['status']!),
              ),
          ],
          value: _tabController.index,
          onChanged: (index) => _refresh(() => _tabController.index = index),
        ),
        const Spacer(),
        if (pendingCount > 0)
          DesktopInfoChip(
            label: '{pendingCount} طلب مستني'.tr({'pendingCount': pendingCount}),
            icon: Icons.notifications_active_outlined,
            color: palette.warning,
          ),
      ],
    );
  }

  /// قائمة الطلبات للتاب الحالي — سكرول داخلي مع Scrollbar سطح المكتب.
  Widget _windowsOrdersList(
    BuildContext context,
    String status,
    List<Map<String, dynamic>> orders,
  ) {
    if (orders.isEmpty) return _windowsEmptyState(status);

    return DesktopScrollbar(
      builder: (c) => ListView.separated(
        controller: c,
        padding: EdgeInsets.zero,
        itemCount: orders.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: DesktopTokens.gapSm + 2),
        itemBuilder: (_, i) => _windowsOrderCard(context, orders[i]),
      ),
    );
  }

  Widget _windowsOrderCard(BuildContext context, Map<String, dynamic> order) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final status = order['status'] as String;
    final items = order['items'] as List<Map<String, dynamic>>;
    final total = (order['total'] as double);
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final timeAgo = createdAt != null ? _timeAgo(createdAt) : '';
    final tint = _statusColor(palette, status);
    final note = order['note'] as String?;

    return DesktopCard(
      hover: true,
      borderColor:
          status == 'pending' ? palette.warning.withValues(alpha: 0.55) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== رأس الطلب: الترابيزة + الحالة + الوقت =====
          Row(
            children: [
              DesktopIconBadge(
                icon: Icons.table_restaurant_outlined,
                color: tint,
                size: 38,
              ),
               SizedBox(width: DesktopTokens.gapSm + 2),
              Expanded(
                child: Text(
                  order['table_name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              DesktopInfoChip(
                label: _statusLabel(status),
                icon: _statusIcon(status),
                color: tint,
              ),
              if (timeAgo.isNotEmpty) ...[
                 SizedBox(width: DesktopTokens.gapSm),
                Text(
                  timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
           SizedBox(height: DesktopTokens.gapSm + 2),
          Container(height: 1, color: palette.border),
           SizedBox(height: DesktopTokens.gapSm),

          // ===== الأصناف =====
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item['qty']}×',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesktopTokens.gapSm),
                  Expanded(
                    child: Text(
                      item['drink_name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Text(
                    '{v1} ج'.tr({'v1': (item['total'] as num).toStringAsFixed(0)}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

          // ===== ملاحظة الطلب =====
          if (note != null && note.isNotEmpty) ...[
             SizedBox(height: DesktopTokens.gapSm),
            Container(
              width: double.infinity,
              padding:  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: palette.soft(palette.warning),
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                border: Border.all(
                  color: palette.warning.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 15,
                    color: palette.warning,
                  ),
                   SizedBox(width: DesktopTokens.gapXs),
                  Expanded(
                    child: Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

           SizedBox(height: DesktopTokens.gapSm),
          Container(height: 1, color: palette.border),
           SizedBox(height: DesktopTokens.gapSm + 2),

          // ===== الإجمالي + إجراءات القبول/الرفض =====
          Row(
            children: [
              Text(
                'الإجمالي'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: DesktopTokens.gapXs),
              Text(
                '{v1} ج'.tr({'v1': total.toStringAsFixed(0)}),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
               Spacer(),
              if (status == 'pending') ...[
                DesktopButton.ghost(
                  label: 'رفض'.tr(),
                  icon: Icons.close,
                  color: palette.danger,
                  onPressed: () => _cancelOrder(order['id'] as int),
                ),
                const SizedBox(width: DesktopTokens.gapSm),
                DesktopButton.primary(
                  label: 'قبول'.tr(),
                  icon: Icons.check,
                  color: palette.success,
                  onPressed: () => _acceptOrder(order),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowsEmptyState(String status) {
    switch (status) {
      case 'accepted':
        return  DesktopEmptyState(
          icon: Icons.check_circle_outline,
          title: 'مفيش طلبات مقبولة'.tr(),
          message: 'الطلبات اللي بتتقبل من الكاشير هتظهر هنا.'.tr(),
        );
      case 'cancelled':
        return  DesktopEmptyState(
          icon: Icons.cancel_outlined,
          title: 'مفيش طلبات ملغية'.tr(),
          message: 'كل الطلبات اللي اتلغت هتظهر هنا.'.tr(),
        );
      default:
        return  DesktopEmptyState(
          icon: Icons.notifications_none,
          title: 'مفيش طلبات جديدة دلوقتي'.tr(),
          message: 'أول ما يجي طلب جديد هيظهر هنا فوراً.'.tr(),
        );
    }
  }

  /// ملخص الأدمن — نفس أرقام الشريط السفلي في الموبايل بس كبانل جانبي.
  Widget _windowsAdminPanel(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final accepted = _orders.where((o) => o['status'] == 'accepted').toList();
    final totalRevenue = accepted.fold<double>(
      0,
      (s, o) => s + (o['total'] as double),
    );
    final pending = _orders.where((o) => o['status'] == 'pending').length;
    final cancelled = _orders.where((o) => o['status'] == 'cancelled').length;

    return DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           DesktopSectionTitle(
            title: 'ملخص الطلبات'.tr(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: DesktopTokens.gapSm + 2),
          DesktopMiniStat(
            label: 'طلبات جديدة'.tr(),
            value: '$pending',
            icon: Icons.notifications_active_outlined,
            color: palette.warning,
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          DesktopMiniStat(
            label: 'طلبات مقبولة'.tr(),
            value: '${accepted.length}',
            icon: Icons.check_circle_outline,
            color: palette.success,
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          DesktopMiniStat(
            label: 'طلبات ملغية'.tr(),
            value: '$cancelled',
            icon: Icons.cancel_outlined,
            color: palette.danger,
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          DesktopMiniStat(
            label: 'دخل الطلبات المقبولة'.tr(),
            value: '{v1} ج'.tr({'v1': totalRevenue.toStringAsFixed(0)}),
            icon: Icons.payments_outlined,
            color: palette.accent,
          ),
          const Spacer(),
          DesktopButton.ghost(
            label: 'تحديث الأرقام'.tr(),
            icon: Icons.refresh,
            onPressed: _loadOrders,
          ),
        ],
      ),
    );
  }

  /// لون الحالة — من لوحة ألوان سطح المكتب.
  Color _statusColor(DesktopPalette palette, String status) {
    switch (status) {
      case 'pending':
        return palette.warning;
      case 'accepted':
        return palette.success;
      case 'cancelled':
        return palette.danger;
      default:
        return palette.textMuted;
    }
  }

  /// أيقونة الحالة.
  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.notifications_active_outlined;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  /// اسم الحالة بالعربي.
  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'جديد'.tr();
      case 'accepted':
        return 'مقبول'.tr();
      case 'cancelled':
        return 'ملغي'.tr();
      default:
        return status;
    }
  }
}
