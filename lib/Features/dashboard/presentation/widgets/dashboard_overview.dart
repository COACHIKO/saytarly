import 'package:flutter/material.dart';

import 'package:saytarly/core/design/design.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/Features/dashboard/presentation/models/dashboard_models.dart';
import 'package:saytarly/Features/dashboard/presentation/widgets/dashboard_activity_panels.dart';
import 'package:saytarly/Features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:saytarly/Features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:saytarly/Features/dashboard/presentation/widgets/dashboard_sales_panel.dart';

/// The dashboard overview composition.
///
/// Pure presentation: the screen supplies real data and callbacks, this widget
/// handles the responsive SaaS layout.
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({
    super.key,
    required this.stats,
    required this.range,
    required this.onRangeChanged,
    required this.quickActions,
    required this.onViewOrders,
    required this.onManageStock,
    required this.onOpenReports,
  });

  final DashboardStats stats;
  final DashboardRange range;
  final ValueChanged<DashboardRange> onRangeChanged;
  final List<DashboardQuickAction> quickActions;
  final VoidCallback onViewOrders;
  final VoidCallback onManageStock;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKpis(context),
            const SizedBox(height: DesktopTokens.gapLg),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: DashboardSalesPanel(
                      stats: stats,
                      range: range,
                      onRangeChanged: onRangeChanged,
                    ),
                  ),
                  const SizedBox(width: DesktopTokens.gapMd),
                  SizedBox(
                    width: 344,
                    child: DashboardSummaryPanel(
                      stats: stats,
                      onOpenReports: onOpenReports,
                      onManageStock: onManageStock,
                    ),
                  ),
                ],
              )
            else ...[
              DashboardSalesPanel(
                stats: stats,
                range: range,
                onRangeChanged: onRangeChanged,
              ),
              const SizedBox(height: DesktopTokens.gapMd),
              DashboardSummaryPanel(
                stats: stats,
                onOpenReports: onOpenReports,
                onManageStock: onManageStock,
              ),
            ],
            const SizedBox(height: DesktopTokens.gapLg),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: DashboardRecentOrdersPanel(
                      orders: stats.recentOrders,
                      onViewAll: onViewOrders,
                    ),
                  ),
                  const SizedBox(width: DesktopTokens.gapMd),
                  Expanded(
                    flex: 2,
                    child: DashboardLowStockPanel(
                      items: stats.lowStockItems,
                      count: stats.lowStockCount,
                      onManage: onManageStock,
                    ),
                  ),
                ],
              )
            else ...[
              DashboardRecentOrdersPanel(
                orders: stats.recentOrders,
                onViewAll: onViewOrders,
              ),
              const SizedBox(height: DesktopTokens.gapMd),
              DashboardLowStockPanel(
                items: stats.lowStockItems,
                count: stats.lowStockCount,
                onManage: onManageStock,
              ),
            ],
            const SizedBox(height: DesktopTokens.gapLg + 4),
            DashboardQuickActions(actions: quickActions),
          ],
        );
      },
    );
  }

  Widget _buildKpis(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final salesChange = stats.salesChangePercent;
    final weekSales = stats.weekTrend.map((p) => p.sales).toList();
    final weekProfit = stats.weekTrend.map((p) => p.profit).toList();
    final loading = stats.isLoading;

    return DesktopResponsiveGrid(
      minTileWidth: 240,
      maxColumns: 4,
      spacing: DesktopTokens.gapMd,
      children: [
        SaytarlyMetricCard(
          label: 'مبيعات اليوم'.tr(),
          value: loading ? '—' : DashboardFormat.money(stats.todaySales),
          icon: Icons.payments_outlined,
          color: palette.accent,
          hint:
              loading
                  ? 'جارٍ تحميل الأرقام'.tr()
                  : 'عدد الفواتير {v1}'.tr({'v1': stats.invoicesToday}),
          trend:
              salesChange == null
                  ? null
                  : DashboardFormat.signedPercent(salesChange),
          trendTone:
              (salesChange ?? 0) >= 0
                  ? SaytarlyStatusTone.success
                  : SaytarlyStatusTone.danger,
          sparkline: weekSales.isEmpty ? null : weekSales,
          sparklineColor: palette.accent,
        ),
        SaytarlyMetricCard(
          label: 'الطلبات النشطة'.tr(),
          value: loading ? '—' : '${stats.activeOrders}',
          icon: Icons.timer_outlined,
          color: palette.info,
          hint: 'طلبات مفتوحة الآن'.tr(),
          footnote: SaytarlyStatusPill(
            label: 'مباشر'.tr(),
            tone: SaytarlyStatusTone.info,
            dense: true,
          ),
        ),
        SaytarlyMetricCard(
          label: 'نواقص المخزون'.tr(),
          value: loading ? '—' : '${stats.lowStockCount}',
          icon: Icons.inventory_2_outlined,
          color: palette.warning,
          hint: 'تحت حد إعادة الطلب'.tr(),
          trend: stats.lowStockCount > 0 ? 'يحتاج انتباه'.tr() : null,
          trendTone: SaytarlyStatusTone.warning,
          onTap: onManageStock,
        ),
        SaytarlyMetricCard(
          label: 'صافي الربح'.tr(),
          value: loading ? '—' : DashboardFormat.money(stats.netProfit),
          icon: Icons.savings_outlined,
          color: stats.netProfit >= 0 ? palette.profit : palette.danger,
          hint: 'بعد خصم المصروفات'.tr(),
          footnote: Text(
            'هامش {v1}'.tr({
              'v1': DashboardFormat.percent(
                (stats.profitMargin * 100).clamp(-999, 999),
              ),
            }),
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          sparkline: weekProfit.isEmpty ? null : weekProfit,
          sparklineColor:
              stats.netProfit >= 0 ? palette.profit : palette.danger,
        ),
      ],
    );
  }
}
