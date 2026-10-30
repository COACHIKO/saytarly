import 'package:saytarly/Features/activation/presentation/screens/license_generator_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/design/saytarly_brand.dart';
import 'package:saytarly/core/utils/money.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/widgets/BACKGROUND.dart';
import 'package:saytarly/Features/auth/presentation/screens/logout_helper.dart';
import 'package:saytarly/Features/auth/viewmodel/current_user.dart';
import 'package:saytarly/Features/dashboard/presentation/models/dashboard_models.dart';
import 'package:saytarly/Features/dashboard/presentation/widgets/dashboard_overview.dart';
import 'package:saytarly/Features/cards/presentation/screens/print_cards_page.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/app_modules.dart';
import 'package:saytarly/core/services/app_settings.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/Features/reports/presentation/screens/AuditLogScreen.dart';
import 'package:saytarly/Features/settings/presentation/screens/setting.dart';
import 'package:saytarly/Features/expenses/presentation/screens/AddExpenseScreen.dart';
import 'package:saytarly/Features/products/presentation/screens/ProductsReportScreen.dart';
import 'package:saytarly/Features/staff/presentation/screens/PendingSalariesScreen.dart';
import 'package:saytarly/Features/playstation/presentation/screens/PlaystationSalesReportScreen.dart';
import 'package:saytarly/Features/reports/presentation/screens/SaleReport.dart';
import 'package:saytarly/Features/debts/presentation/screens/customers_report_screen.dart';
import 'package:saytarly/Features/playstation/presentation/screens/manage_consoles.dart';
import 'package:saytarly/Features/products/presentation/screens/manage_drinks.dart';
import 'package:saytarly/Features/materials/presentation/screens/manage_materials.dart';
import 'package:saytarly/Features/users/presentation/screens/manage_users.dart';
import 'package:saytarly/Features/debts/presentation/screens/debts_screen.dart';
import 'package:saytarly/Features/materials/presentation/screens/materials_report.dart';
import 'package:saytarly/Features/reports/presentation/screens/reports.dart';
// 🔧 عدّل المسار لو الملف في مكان مختلف
import 'package:saytarly/Features/staff/presentation/screens/shifts_report.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/admin_mobile_body.dart';
part 'desktop/admin_windows_body.dart';

/// The 3 available dashboard looks. Add more here later if needed.
enum DashStyle { current, warmCafe, professional }

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int sessionsCount = 0;
  double incomeToday = 0;

  // 🆕 أرقام إضافية للوحة الويندوز (المقاسات نفسها اللي بتتحسب أصلاً)
  double expensesTotal = 0;
  double topupsTotal = 0;
  double debtsCollected = 0;

  // 🆕 بحث الأدوات — لوحة الويندوز
  String _searchQuery = '';

  // Which design is currently shown. Change the default here if you want
  // a specific style to open by default.
  DashStyle _style = DashStyle.current;

  // Whether the stats row (invoices count / total income) is visible.
  // Toggled from the eye icon in the AppBar.
  bool _showStats = true;

  bool _cigarettesEnabled = false;
  bool _shishaEnabled = false;

  // 🆕 أقسام المنتجات (بتتظبط من السوبر ادمن)
  List<Map<String, dynamic>> _modules = [];
  String _placeName = BusinessProfile.fallbackName;
  bool _playstationEnabled = false;

  /// Live data for the Windows dashboard overview.
  DashboardStats _dashboardStats = DashboardStats.empty();
  DashboardRange _dashboardRange = DashboardRange.week;

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  void _setDashboardRange(DashboardRange value) =>
      _refresh(() => _dashboardRange = value);

  void _setSearchQuery(String value) => _refresh(() => _searchQuery = value);

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadStyle();
    _loadFeatureFlags(); // 🆕
    _loadModulesAndProfile(); // 🆕
  }

  Future<void> _loadModulesAndProfile() async {
    final modules = await DBHelper.getModules(enabledOnly: true);
    final name = await BusinessProfile.getPlaceName();
    final ps = await BusinessProfile.isPlaystationEnabled();
    if (!mounted) return;
    setState(() {
      _modules = modules;
      _placeName = name;
      _playstationEnabled = ps;
    });
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

  Future<void> _loadStyle() async {
    final saved = await AppSettings.getAdminDashStyle();
    final match = DashStyle.values.where((d) => d.name == saved);
    if (match.isNotEmpty && mounted) {
      setState(() => _style = match.first);
    }
  }

  Future<void> _changeStyle(DashStyle value) async {
    setState(() => _style = value);
    await AppSettings.setAdminDashStyle(value.name);
  }

  Future<void> _loadStats() async {
    final db = await DBHelper.database;
    final invoices = await db.query('invoices');
    final expenses = await db.query('expenses');
    final materials = await db.query('raw_materials');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime? invoiceTime(Map<String, dynamic> row) =>
        _parseDateTime(row['end_time']) ?? _parseDateTime(row['start_time']);

    bool isCancelled(Map<String, dynamic> row) {
      final type = (row['payment_type'] ?? '').toString().trim().toLowerCase();
      return type == 'ملغي' || type == 'cancelled' || type == 'canceled';
    }

    final completedInvoices =
        invoices.where((row) {
          final end = _parseDateTime(row['end_time']);
          return end != null && !isCancelled(row);
        }).toList();

    double salesOn(DateTime day) {
      return completedInvoices.fold<double>(0, (sum, row) {
        final time = _parseDateTime(row['end_time']);
        if (!_sameDay(time, day)) return sum;
        return sum + _toDouble(row['total_cost']);
      });
    }

    double expensesOn(DateTime day) {
      return expenses.fold<double>(0, (sum, row) {
        final time = _parseDateTime(row['date']);
        if (!_sameDay(time, day)) return sum;
        return sum + _toDouble(row['amount']);
      });
    }

    final todaySales = salesOn(today);
    final yesterdaySales = salesOn(yesterday);
    final expensesToday = expensesOn(today);
    final activeOrders =
        invoices.where((row) => _parseDateTime(row['end_time']) == null).length;

    final completedToday =
        completedInvoices
            .where((row) => _sameDay(_parseDateTime(row['end_time']), today))
            .length;

    final lowStock = <DashboardStockAlert>[];
    for (final row in materials) {
      final qty = _toDouble(row['qty']);
      final min = _toDouble(row['min_qty']);
      if (qty <= min) {
        lowStock.add(
          DashboardStockAlert(
            id: (row['id'] as num?)?.toInt() ?? 0,
            name: (row['name'] ?? '').toString(),
            unit: (row['unit'] ?? '').toString(),
            quantity: qty,
            minimum: min,
          ),
        );
      }
    }
    lowStock.sort((a, b) {
      final aRatio = a.minimum <= 0 ? (a.quantity <= 0 ? 0.0 : 1.0) : a.level;
      final bRatio = b.minimum <= 0 ? (b.quantity <= 0 ? 0.0 : 1.0) : b.level;
      return aRatio.compareTo(bRatio);
    });

    final sortedInvoices = List<Map<String, dynamic>>.of(invoices)
      ..sort((a, b) {
        final aTime = invoiceTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = invoiceTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    final recentOrders =
        sortedInvoices.take(5).map((row) {
          return DashboardOrder(
            id: (row['id'] as num?)?.toInt() ?? 0,
            customer: (row['customer_name'] ?? '').toString(),
            staff: (row['staff_name'] ?? '').toString(),
            time: invoiceTime(row),
            total: _toDouble(row['total_cost']),
            status: _orderStatus(row),
          );
        }).toList();

    final weekTrend = _buildTrend(
      start: today.subtract(const Duration(days: 6)),
      days: 7,
      invoices: completedInvoices,
      expenses: expenses,
      compactLabels: true,
    );
    final monthTrend = _buildTrend(
      start: today.subtract(const Duration(days: 29)),
      days: 30,
      invoices: completedInvoices,
      expenses: expenses,
      compactLabels: false,
    );

    final dashboard = DashboardStats(
      todaySales: todaySales,
      yesterdaySales: yesterdaySales,
      netProfit: todaySales - expensesToday,
      expensesToday: expensesToday,
      activeOrders: activeOrders,
      lowStockCount: lowStock.length,
      invoicesToday: completedToday,
      weekTrend: weekTrend,
      monthTrend: monthTrend,
      recentOrders: recentOrders,
      lowStockItems: lowStock.take(5).toList(),
      lastUpdated: now,
    );

    final totalInvoiceIncome = invoices.fold<double>(0.0, (p, e) {
      final paymentType = e['payment_type'] ?? 'paid';
      if (paymentType == 'paid') {
        return p + _toDouble(e['total_cost']);
      }
      return p;
    });

    final totalExpenses = expenses.fold<double>(
      0.0,
      (p, e) => p + _toDouble(e['amount']),
    );

    final debtPayments = await db.query(
      'cash_drawer',
      where: 'type = ? AND source = ?',
      whereArgs: ['income', 'debt'],
    );
    final topups = await db.query(
      'cash_drawer',
      where: 'type = ? AND source = ?',
      whereArgs: ['income', 'topup'],
    );
    final totalTopups = topups.fold<double>(
      0.0,
      (p, e) => p + _toDouble(e['amount']),
    );
    final totalDebtPayments = debtPayments.fold<double>(
      0.0,
      (p, e) => p + _toDouble(e['amount']),
    );

    if (!mounted) return;
    setState(() {
      _dashboardStats = dashboard;
      sessionsCount = invoices.length;
      incomeToday =
          totalInvoiceIncome + totalDebtPayments + totalTopups - totalExpenses;
      expensesTotal = totalExpenses;
      topupsTotal = totalTopups;
      debtsCollected = totalDebtPayments;
    });
  }

  List<DashboardTrendPoint> _buildTrend({
    required DateTime start,
    required int days,
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> expenses,
    required bool compactLabels,
  }) {
    final salesByDay = <String, double>{};
    final expensesByDay = <String, double>{};

    for (final row in invoices) {
      final time = _parseDateTime(row['end_time']);
      if (time == null) continue;
      final key = _dayKey(time);
      salesByDay[key] = (salesByDay[key] ?? 0) + _toDouble(row['total_cost']);
    }
    for (final row in expenses) {
      final time = _parseDateTime(row['date']);
      if (time == null) continue;
      final key = _dayKey(time);
      expensesByDay[key] = (expensesByDay[key] ?? 0) + _toDouble(row['amount']);
    }

    final locale = Str.isRtl ? 'ar' : 'en';
    return List.generate(days, (index) {
      final day = start.add(Duration(days: index));
      final key = _dayKey(day);
      final label =
          compactLabels
              ? DateFormat('EEE', locale).format(day)
              : DateFormat('d/M', 'en').format(day);
      return DashboardTrendPoint(
        day: day,
        label: label,
        sales: salesByDay[key] ?? 0,
        expenses: expensesByDay[key] ?? 0,
      );
    });
  }

  DashboardOrderStatus _orderStatus(Map<String, dynamic> row) {
    if (_parseDateTime(row['end_time']) == null) {
      return DashboardOrderStatus.active;
    }
    final type = (row['payment_type'] ?? '').toString().trim().toLowerCase();
    if (type == 'ملغي' || type == 'cancelled' || type == 'canceled') {
      return DashboardOrderStatus.cancelled;
    }
    if (type == 'debt' || type == 'علي الحساب') {
      return DashboardOrderStatus.debt;
    }
    return DashboardOrderStatus.paid;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static bool _sameDay(DateTime? value, DateTime day) {
    if (value == null) return false;
    return value.year == day.year &&
        value.month == day.month &&
        value.day == day.day;
  }

  static String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AppDialog(
            title: Text('تأكيد'.tr()),
            content: Text(
              'هل تريد مسح كل البيانات (ما عدا المشروبات والأجهزة)؟'.tr(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('تأكيد'.tr()),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await DBHelper.clearAllData();

      if (!mounted) return;

      AppToast.show('تم مسح جميع البيانات بنجاح!'.tr());

      setState(() {
        sessionsCount = 0;
        incomeToday = 0;
        expensesTotal = 0;
        topupsTotal = 0;
        debtsCollected = 0;
        _dashboardStats = DashboardStats.empty(loading: false);
      });
    }
  }

  // Same action list every style pulls from, so adding/removing a section
  // only needs to happen in one place.
  //
  // 🆕 كل عنصر بقى له 'group' — الموبايل بيتجاهلها، ولوحة الويندوز بتجمّع
  // بيها الأدوات في السايد بار والأقسام.
  List<Map<String, dynamic>> get _actions => [
    {
      'title': 'التقارير'.tr(),
      'id': 'reports',
      'group': 'المتابعة'.tr(),
      'icon': Icons.bar_chart,
      'color': SaytarlyColors.warning,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportsScreen()),
          ),
    },
    {
      'title': 'الفلوس الاجله'.tr(),
      'id': 'debts',
      'group': 'المتابعة'.tr(),
      'icon': Icons.payments,
      'color': SaytarlyColors.information,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DebtsScreen()),
          ),
    },
    {
      'title': 'تقارير الشيفتات'.tr(),
      'id': 'shifts_report',
      'group': 'المتابعة'.tr(),
      'icon': Icons.schedule,
      'color': SaytarlyColors.information,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShiftsReportScreen()),
          ),
    },
    if (_playstationEnabled) ...[
      {
        'title': 'إدارة الأجهزة'.tr(),
        'id': 'consoles_manage',
        'group': 'البلايستيشن'.tr(),
        'icon': Icons.videogame_asset,
        'color': SaytarlyColors.information,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ManageConsolesScreen()),
            ),
      },
      {
        'title': 'تقرير البلايستيشن'.tr(),
        'id': 'consoles_report',
        'group': 'البلايستيشن'.tr(),
        'icon': Icons.sports_esports,
        'color': SaytarlyColors.information,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PlaystationSalesReportScreen(),
              ),
            ),
      },
    ],

    // 🆕 كروت الأقسام — كل قسم بيطلع له تلقائي: إدارة + تقرير
    // (الخامات مخزون مشترك — كارت واحد بيظهر مع أول قسم)
    if (_modules.isEmpty)
      {
        'title': 'لسه مفيش أقسام منتجات'.tr(),
        'id': 'no_modules',
        'group': 'الأقسام'.tr(),
        'icon': Icons.info_outline,
        'color': SaytarlyColors.textMuted,
        'onTap':
            () => AppToast.show(
              'السوبر ادمن لسه مضافش أقسام — من الأقسام دي بتظهر إدارة المنتجات وتقاريرها، والخامات المشتركة'
                  .tr(),
            ),
      },
    for (final m in _modules) ...[
      {
        'title': 'إدارة {v1}'.tr({'v1': AppModule.displayNameFromMap(m)}),
        'id': 'module_manage_${m['id']}',
        'group': 'الأقسام'.tr(),
        'icon': ModuleIcons.iconData(m['icon'] as String? ?? 'category'),
        'color': Color((m['color'] as num?)?.toInt() ?? 0xFF14B8A6),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ManageDrinksScreen(
                      moduleId: m['id'] as int,
                      moduleName: AppModule.displayNameFromMap(m),
                    ),
              ),
            ),
      },
      {
        'title': 'تقرير {v1}'.tr({'v1': AppModule.displayNameFromMap(m)}),
        'id': 'module_report_${m['id']}',
        'group': 'الأقسام'.tr(),
        'icon': Icons.insert_chart_outlined,
        'color': Color((m['color'] as num?)?.toInt() ?? 0xFF14B8A6),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SalesReportScreen(
                      moduleId: m['id'] as int,
                      customTitle: 'تقرير {v1}'.tr({
                        'v1': AppModule.displayNameFromMap(m),
                      }),
                    ),
              ),
            ),
      },
    ],
    // 🆕 الخامات مخزون مشترك لكل الأقسام
    if (_modules.isNotEmpty) ...[
      {
        'title': 'إدارة الخامات'.tr(),
        'id': 'materials_manage',
        'group': 'الأقسام'.tr(),
        'icon': Icons.inventory_2,
        'color': SaytarlyColors.profit,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageMaterialsScreen()),
            ),
      },
      {
        'title': 'خامات الناقصه'.tr(),
        'id': 'materials_low',
        'group': 'الأقسام'.tr(),
        'icon': Icons.local_drink,
        'color': SaytarlyColors.profit,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MaterialsReportScreen()),
            ),
      },
    ],
    {
      'title': 'تقرير المنتجات'.tr(),
      'id': 'products_report',
      'group': 'المتابعة'.tr(),
      'icon': Icons.shopping_bag_outlined,
      'color': SaytarlyColors.profit,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductsReportScreen()),
          ),
    },
    if (_cigarettesEnabled) // 🆕
      {
        'title': 'تقرير السجائر'.tr(),
        'id': 'cigarettes_report',
        'group': 'المتابعة'.tr(),
        'icon': Icons.smoking_rooms,
        'color': SaytarlyColors.warning,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SalesReportScreen(
                      categoryFilter: ['cigarette'],
                      customTitle: 'تقرير السجائر'.tr(),
                    ),
              ),
            ),
      },
    if (_shishaEnabled) // 🆕
      {
        'title': 'تقرير الشيشة'.tr(),
        'id': 'shisha_report',
        'group': 'المتابعة'.tr(),
        'icon': Icons.blur_on,
        'color': SaytarlyColors.information,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SalesReportScreen(
                      categoryFilter: ['shisha'],
                      customTitle: 'تقرير الشيشة'.tr(),
                    ),
              ),
            ),
      },

    {
      'title': 'إدارة المستخدمين'.tr(),
      'id': 'users',
      'group': 'الإدارة'.tr(),
      'icon': Icons.person,
      'color': SaytarlyColors.danger,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ManageUsersScreen()),
          ),
    },
    {
      'title': 'إضافة مصروف'.tr(),
      'id': 'expenses',
      'group': 'الإدارة'.tr(),
      'icon': Icons.attach_money,
      'color': SaytarlyColors.information,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminExpensesScreen()),
          ),
    },
    {
      'title': 'العملاء'.tr(),
      'id': 'customers',
      'group': 'الإدارة'.tr(),
      'icon': Icons.person,
      'color': SaytarlyColors.information,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CustomersReportScreen()),
          ),
    },
    {
      'title': 'كروت النت'.tr(),
      'id': 'internet_cards',
      'group': 'الإدارة'.tr(),
      'icon': Icons.sd_card,
      'color': SaytarlyColors.warning,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrintCardsPage()),
          ),
    },
    {
      'title': 'رواتب الموظفين'.tr(),
      'id': 'salaries',
      'group': 'الإدارة'.tr(),
      'icon': Icons.payments,
      'color': SaytarlyColors.information,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PendingSalariesScreen()),
          ),
    },
    {
      'title': 'سجل التعديلات'.tr(),
      'id': 'audit_log',
      'group': 'الإدارة'.tr(),
      'icon': Icons.history,
      'color': SaytarlyColors.information,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AuditLogScreen()),
          ),
    },
    {
      'title': 'الإعدادات'.tr(),
      'id': 'settings',
      'group': 'الإدارة'.tr(),
      'icon': Icons.settings,
      'color': SaytarlyColors.textSecondary,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
    },
    {
      'title': 'تفعيل'.tr(),
      'id': 'activation',
      'group': 'الإدارة'.tr(),
      'icon': Icons.settings,
      'color': SaytarlyColors.textSecondary,
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LicenseGeneratorScreen()),
          ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

// Source-as-key registration for labels composed inside the action maps.
// Keeping them in a plain list lets the extractor register the translations
// without coupling the action IDs to display text.
// ignore: unused_element
List<String> get _dashboardActionLabels => [
  'الفلوس الاجله'.tr(),
  'خامات الناقصه'.tr(),
  'كروت النت'.tr(),
  'تقرير البلايستيشن'.tr(),
];
