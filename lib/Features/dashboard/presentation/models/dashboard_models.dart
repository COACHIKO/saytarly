import 'package:flutter/material.dart';

/// Time window used by the sales performance chart.
enum DashboardRange {
  week(7),
  month(30);

  const DashboardRange(this.days);
  final int days;
}

/// Order/payment state used by the recent-orders table.
enum DashboardOrderStatus { active, paid, debt, cancelled }

/// One day in the sales trend.
@immutable
class DashboardTrendPoint {
  const DashboardTrendPoint({
    required this.day,
    required this.label,
    required this.sales,
    required this.expenses,
  });

  final DateTime day;
  final String label;
  final double sales;
  final double expenses;

  double get profit => sales - expenses;
}

/// A compact recent-order row.
@immutable
class DashboardOrder {
  const DashboardOrder({
    required this.id,
    required this.customer,
    required this.staff,
    required this.time,
    required this.total,
    required this.status,
  });

  final int id;
  final String customer;
  final String staff;
  final DateTime? time;
  final double total;
  final DashboardOrderStatus status;
}

/// A low-stock item with enough detail for a progress row.
@immutable
class DashboardStockAlert {
  const DashboardStockAlert({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minimum,
  });

  final int id;
  final String name;
  final String unit;
  final double quantity;
  final double minimum;

  bool get isEmpty => quantity <= 0;

  /// 0..1 fill ratio relative to the minimum threshold.
  double get level {
    if (minimum <= 0) return 1;
    return (quantity / minimum).clamp(0.0, 1.0);
  }
}

/// Quick action exposed by the dashboard.
@immutable
class DashboardQuickAction {
  const DashboardQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
}

/// Everything the dashboard overview needs, already computed by the screen.
@immutable
class DashboardStats {
  const DashboardStats({
    required this.todaySales,
    required this.yesterdaySales,
    required this.netProfit,
    required this.expensesToday,
    required this.activeOrders,
    required this.lowStockCount,
    required this.invoicesToday,
    required this.weekTrend,
    required this.monthTrend,
    required this.recentOrders,
    required this.lowStockItems,
    this.isLoading = false,
    this.lastUpdated,
  });

  final double todaySales;
  final double yesterdaySales;
  final double netProfit;
  final double expensesToday;
  final int activeOrders;
  final int lowStockCount;
  final int invoicesToday;
  final List<DashboardTrendPoint> weekTrend;
  final List<DashboardTrendPoint> monthTrend;
  final List<DashboardOrder> recentOrders;
  final List<DashboardStockAlert> lowStockItems;
  final bool isLoading;
  final DateTime? lastUpdated;

  List<DashboardTrendPoint> trendFor(DashboardRange range) =>
      range == DashboardRange.week ? weekTrend : monthTrend;

  double? get salesChangePercent {
    if (yesterdaySales.abs() < 0.005) return null;
    return ((todaySales - yesterdaySales) / yesterdaySales) * 100;
  }

  double get averageTicket =>
      invoicesToday <= 0 ? 0 : todaySales / invoicesToday;

  double get profitMargin {
    if (todaySales.abs() < 0.005) return 0;
    return (netProfit / todaySales).clamp(-1.0, 1.0);
  }

  static DashboardStats empty({bool loading = true}) {
    return DashboardStats(
      todaySales: 0,
      yesterdaySales: 0,
      netProfit: 0,
      expensesToday: 0,
      activeOrders: 0,
      lowStockCount: 0,
      invoicesToday: 0,
      weekTrend: const [],
      monthTrend: const [],
      recentOrders: const [],
      lowStockItems: const [],
      isLoading: loading,
    );
  }
}
