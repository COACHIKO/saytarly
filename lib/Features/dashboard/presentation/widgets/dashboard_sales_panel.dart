import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:saytarly/core/design/design.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/Features/dashboard/presentation/models/dashboard_models.dart';
import 'package:saytarly/Features/dashboard/presentation/widgets/dashboard_format.dart';

/// Sales performance card: the visual centre of the dashboard.
class DashboardSalesPanel extends StatelessWidget {
  const DashboardSalesPanel({
    super.key,
    required this.stats,
    required this.range,
    required this.onRangeChanged,
  });

  final DashboardStats stats;
  final DashboardRange range;
  final ValueChanged<DashboardRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final trend = stats.trendFor(range);
    final dateLocale = Str.isRtl ? 'ar' : 'en';
    final points = [
      for (final p in trend)
        SaytarlyChartPoint(
          label: range == DashboardRange.week
              ? DateFormat('EEE', dateLocale).format(p.day)
              : DateFormat('d/M', 'en').format(p.day),
          value: p.sales,
          tooltipLabel:
              '${DateFormat('EEE', dateLocale).format(p.day)} • ${DashboardFormat.date(p.day)}',
        ),
    ];
    final total = trend.fold<double>(0, (sum, p) => sum + p.sales);
    final change = _comparison(stats, range);

    return DesktopPanel(
      title: 'أداء المبيعات'.tr(),
      subtitle:
          range == DashboardRange.week
              ? 'إجمالي المبيعات خلال آخر 7 أيام'.tr()
              : 'إجمالي المبيعات خلال آخر 30 يوم'.tr(),
      icon: Icons.show_chart_rounded,
      iconColor: palette.accent,
      trailing: DesktopSegmented<DashboardRange>(
        items: [
          DesktopSegmentItem(
            value: DashboardRange.week,
            label: '7 أيام'.tr(),
            icon: Icons.calendar_view_week_outlined,
          ),
          DesktopSegmentItem(
            value: DashboardRange.month,
            label: '30 يوم'.tr(),
            icon: Icons.calendar_month_outlined,
          ),
        ],
        value: range,
        onChanged: onRangeChanged,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        DashboardFormat.money(total),
                        maxLines: 1,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (change != null)
                          SaytarlyStatusPill(
                            label: 'مقارنة بالأسبوع السابق {v1}'.tr({
                              'v1': DashboardFormat.signedPercent(change),
                            }),
                            tone:
                                change >= 0
                                    ? SaytarlyStatusTone.success
                                    : SaytarlyStatusTone.danger,
                            dense: true,
                            icon:
                                change >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                          )
                        else
                          Text(
                            range == DashboardRange.week
                                ? 'آخر 7 أيام'.tr()
                                : 'آخر 30 يوم'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesktopTokens.gapMd),
              _Legend(color: palette.accent, label: 'المبيعات'.tr()),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapLg),
          SaytarlyAreaChart(
            points: points,
            height: 256,
            color: palette.accent,
            emptyLabel: 'لا توجد مبيعات مسجلة بعد'.tr(),
            tooltipValueFormatter: DashboardFormat.money,
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: palette.textMuted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'مرّر على الرسم لعرض قيمة كل يوم.'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 10.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double? _comparison(DashboardStats stats, DashboardRange range) {
    if (range != DashboardRange.week) return null;
    if (stats.weekTrend.isEmpty || stats.monthTrend.length < 14) return null;
    final previous = stats.monthTrend
        .sublist(stats.monthTrend.length - 14, stats.monthTrend.length - 7)
        .fold<double>(0, (sum, p) => sum + p.sales);
    if (previous.abs() < 0.005) return null;
    final current = stats.weekTrend.fold<double>(0, (sum, p) => sum + p.sales);
    return ((current - previous) / previous) * 100;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily operating summary: money in, money out, margin and four quick facts.
class DashboardSummaryPanel extends StatelessWidget {
  const DashboardSummaryPanel({
    super.key,
    required this.stats,
    required this.onOpenReports,
    required this.onManageStock,
  });

  final DashboardStats stats;
  final VoidCallback onOpenReports;
  final VoidCallback onManageStock;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final profitPositive = stats.netProfit >= 0;
    final profitColor = profitPositive ? palette.profit : palette.danger;
    final margin = stats.profitMargin.clamp(0.0, 1.0);

    return DesktopPanel(
      title: 'ملخص اليوم'.tr(),
      subtitle: 'أرقام مباشرة من الصندوق'.tr(),
      icon: Icons.pie_chart_outline_rounded,
      iconColor: palette.profit,
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: 'إجمالي المبيعات'.tr(),
            value: DashboardFormat.money(stats.todaySales),
            icon: Icons.south_west_rounded,
            color: palette.accent,
          ),
          const SizedBox(height: 11),
          _SummaryRow(
            label: 'المصروفات'.tr(),
            value: DashboardFormat.money(stats.expensesToday),
            icon: Icons.north_east_rounded,
            color: palette.warning,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: palette.border),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صافي الربح'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        DashboardFormat.money(stats.netProfit),
                        maxLines: 1,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SaytarlyStatusPill(
                label: 'هامش {v1}'.tr({
                  'v1': DashboardFormat.percent(
                    (stats.profitMargin * 100).clamp(-999, 999),
                  ),
                }),
                tone:
                    profitPositive
                        ? SaytarlyStatusTone.profit
                        : SaytarlyStatusTone.danger,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: margin,
              minHeight: 7,
              backgroundColor: palette.surfaceSunken,
              valueColor: AlwaysStoppedAnimation(profitColor),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: _MiniFact(
                      label: 'طلبات نشطة'.tr(),
                      value: '${stats.activeOrders}',
                      icon: Icons.timer_outlined,
                      color: palette.info,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _MiniFact(
                      label: 'فواتير اليوم'.tr(),
                      value: '${stats.invoicesToday}',
                      icon: Icons.receipt_long_outlined,
                      color: palette.accent,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _MiniFact(
                      label: 'متوسط الفاتورة'.tr(),
                      value: DashboardFormat.compactMoney(stats.averageTicket),
                      icon: Icons.payments_outlined,
                      color: palette.profit,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _MiniFact(
                      label: 'نواقص المخزون'.tr(),
                      value: '${stats.lowStockCount}',
                      icon: Icons.inventory_2_outlined,
                      color: palette.warning,
                      onTap: onManageStock,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenReports,
              icon: const Icon(Icons.arrow_outward_rounded, size: 16),
              label: Text('فتح التقارير التفصيلية'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: palette.soft(color),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: palette.onSoft(color)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MiniFact extends StatefulWidget {
  const _MiniFact({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_MiniFact> createState() => _MiniFactState();
}

class _MiniFactState extends State<_MiniFact> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return MouseRegion(
      cursor:
          widget.onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hover ? palette.surfaceSoft : palette.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? palette.borderStrong : palette.border,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: palette.onSoft(widget.color)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.label,
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
