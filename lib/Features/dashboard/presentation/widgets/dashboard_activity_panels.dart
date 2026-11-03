import 'package:flutter/material.dart';

import 'package:saytarly/core/design/design.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/Features/dashboard/presentation/models/dashboard_models.dart';
import 'package:saytarly/Features/dashboard/presentation/widgets/dashboard_format.dart';

/// Latest invoices with payment/status pills.
class DashboardRecentOrdersPanel extends StatelessWidget {
  const DashboardRecentOrdersPanel({
    super.key,
    required this.orders,
    required this.onViewAll,
  });

  final List<DashboardOrder> orders;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return DesktopPanel(
      title: 'أحدث الطلبات'.tr(),
      subtitle: 'آخر الفواتير المسجلة في النظام'.tr(),
      icon: Icons.receipt_long_outlined,
      iconColor: palette.accent,
      trailing: TextButton(
        onPressed: onViewAll,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('عرض الكل'.tr()),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_outward_rounded, size: 14),
          ],
        ),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child:
          orders.isEmpty
              ? _EmptyPanel(
                icon: Icons.receipt_long_outlined,
                title: 'لسه مفيش فواتير'.tr(),
                message: 'أول طلب هيظهر هنا فور تسجيله.'.tr(),
              )
              : Column(
                children: [
                  _OrderHeader(palette: palette, theme: theme),
                  for (var i = 0; i < orders.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, thickness: 1, color: palette.border),
                    _OrderRow(order: orders[i], onTap: onViewAll),
                  ],
                ],
              ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.palette, required this.theme});

  final DesktopPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: palette.textMuted,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 62, child: Text('الفاتورة'.tr(), style: style)),
          const SizedBox(width: 10),
          Expanded(flex: 5, child: Text('العميل'.tr(), style: style)),
          Expanded(flex: 2, child: Text('الوقت'.tr(), style: style)),
          SizedBox(
            width: 104,
            child: Text(
              'الإجمالي'.tr(),
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            child: Text('الحالة'.tr(), textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatefulWidget {
  const _OrderRow({required this.order, required this.onTap});

  final DashboardOrder order;
  final VoidCallback onTap;

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final status = _status(widget.order.status);
    final customer =
        widget.order.customer.trim().isEmpty
            ? 'عميل نقدي'.tr()
            : widget.order.customer.trim();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: _hover ? palette.surfaceSoft : palette.surfaceSoft.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                child: Text(
                  '#${widget.order.id}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.accentText,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.8,
                      ),
                    ),
                    if (widget.order.staff.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.order.staff,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 10.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DashboardFormat.time(widget.order.time),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ),
              SizedBox(
                width: 104,
                child: Text(
                  DashboardFormat.money(widget.order.total),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 82,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SaytarlyStatusPill(
                    label: status.$1,
                    tone: status.$2,
                    dense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, SaytarlyStatusTone) _status(DashboardOrderStatus status) {
    return switch (status) {
      DashboardOrderStatus.active => ('جارية'.tr(), SaytarlyStatusTone.info),
      DashboardOrderStatus.paid => ('مدفوعة'.tr(), SaytarlyStatusTone.success),
      DashboardOrderStatus.debt => ('آجلة'.tr(), SaytarlyStatusTone.warning),
      DashboardOrderStatus.cancelled => (
        'ملغية'.tr(),
        SaytarlyStatusTone.danger,
      ),
    };
  }
}

/// Low-stock panel with threshold progress and quick management action.
class DashboardLowStockPanel extends StatelessWidget {
  const DashboardLowStockPanel({
    super.key,
    required this.items,
    required this.count,
    required this.onManage,
  });

  final List<DashboardStockAlert> items;
  final int count;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPanel(
      title: 'تنبيهات المخزون'.tr(),
      subtitle: 'خامات وصلت لحد إعادة الطلب'.tr(),
      icon: Icons.inventory_2_outlined,
      iconColor: palette.warning,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: palette.soft(palette.warning),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${items.length} / $count',
                style: TextStyle(
                  color: palette.onSoft(palette.warning),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onManage,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('إدارة'.tr()),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_left_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
      bodyPadding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child:
          items.isEmpty
              ? _EmptyPanel(
                icon: Icons.check_circle_outline_rounded,
                title: 'المخزون في أمان'.tr(),
                message: 'كل الخامات أعلى من حد إعادة الطلب.'.tr(),
                color: palette.success,
              )
              : Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: palette.border,
                        ),
                      ),
                    _StockRow(item: items[i], onTap: onManage),
                  ],
                ],
              ),
    );
  }
}

class _StockRow extends StatefulWidget {
  const _StockRow({required this.item, required this.onTap});

  final DashboardStockAlert item;
  final VoidCallback onTap;

  @override
  State<_StockRow> createState() => _StockRowState();
}

class _StockRowState extends State<_StockRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final item = widget.item;
    final tone = item.isEmpty ? palette.danger : palette.warning;
    final level = item.level;
    final qty = DashboardFormat.number(item.quantity);
    final min = DashboardFormat.number(item.minimum);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: _hover ? palette.surfaceSoft : palette.surfaceSoft.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: palette.soft(tone),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  item.isEmpty
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: palette.onSoft(tone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$qty ${item.unit}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.onSoft(tone),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: level,
                        minHeight: 5,
                        backgroundColor: palette.surfaceSunken,
                        valueColor: AlwaysStoppedAnimation(tone),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.isEmpty
                          ? 'خلص من المخزون'.tr()
                          : 'الحد الأدنى {v1} {v2}'.tr({
                            'v1': min,
                            'v2': item.unit,
                          }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 9.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final tint = color ?? palette.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.soft(tint),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: palette.onSoft(tint)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
