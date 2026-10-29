import 'package:saytarly/Features/activation/presentation/screens/license_generator_screen.dart';
import 'package:flutter/material.dart';
import 'package:saytarly/core/utils/money.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/widgets/BACKGROUND.dart';
import 'package:saytarly/Features/auth/presentation/screens/logout_helper.dart';
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

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

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

    final totalInvoiceIncome = invoices.fold<double>(0.0, (p, e) {
      final paymentType = e['payment_type'] ?? 'paid';
      if (paymentType == 'paid') {
        return p + ((e['total_cost'] ?? 0) as num).toDouble();
      }
      return p;
    });

    final expenses = await db.query('expenses');
    final totalExpenses = expenses.fold<double>(
      0.0,
      (p, e) => p + ((e['amount'] ?? 0) as num).toDouble(),
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
      (p, e) => p + ((e['amount'] ?? 0) as num).toDouble(),
    );

    final totalDebtPayments = debtPayments.fold<double>(
      0.0,
      (p, e) => p + ((e['amount'] ?? 0) as num).toDouble(),
    );

    if (!mounted) return;

    setState(() {
      sessionsCount = invoices.length;
      incomeToday =
          totalInvoiceIncome + totalDebtPayments + totalTopups - totalExpenses;
      expensesTotal = totalExpenses;
      topupsTotal = totalTopups;
      debtsCollected = totalDebtPayments;
    });
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title:  Text('تأكيد'.tr()),
        content:  Text(
          'هل تريد مسح كل البيانات (ما عدا المشروبات والأجهزة)؟'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text('تأكيد'.tr()),
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
      'title': 'التقارير',
      'group': 'المتابعة',
      'icon': Icons.bar_chart,
      'color': Colors.amber,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportsScreen()),
      ),
    },
    {
      'title': 'الفلوس الاجله',
      'group': 'المتابعة',
      'icon': Icons.payments,
      'color': Colors.indigo,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DebtsScreen()),
      ),
    },
    {
      'title': 'تقارير الشيفتات',
      'group': 'المتابعة',
      'icon': Icons.schedule,
      'color': Colors.indigo,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShiftsReportScreen()),
      ),
    },
    if (_playstationEnabled) ...[
      {
        'title': 'إدارة الأجهزة',
        'group': 'البلايستيشن',
        'icon': Icons.videogame_asset,
        'color': Colors.blue,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ManageConsolesScreen()),
        ),
      },
      {
        'title': 'تقرير البلايستيشن',
        'group': 'البلايستيشن',
        'icon': Icons.sports_esports,
        'color': Colors.indigo,
        'onTap': () => Navigator.push(
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
        'title': 'لسه مفيش أقسام منتجات',
        'group': 'الأقسام',
        'icon': Icons.info_outline,
        'color': Colors.grey,
        'onTap': () => AppToast.show('السوبر ادمن لسه مضافش أقسام — من الأقسام دي بتظهر إدارة المنتجات وتقاريرها، والخامات المشتركة'.tr(),),
      },
    for (final m in _modules) ...[
      {
        'title': 'إدارة ${m['name']}',
        'group': 'الأقسام',
        'icon': ModuleIcons.iconData(m['icon'] as String? ?? 'category'),
        'color': Color((m['color'] as num?)?.toInt() ?? 0xFF14B8A6),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManageDrinksScreen(
              moduleId: m['id'] as int,
              moduleName: m['name'] as String? ?? '',
            ),
          ),
        ),
      },
      {
        'title': 'تقرير ${m['name']}',
        'group': 'الأقسام',
        'icon': Icons.insert_chart_outlined,
        'color': Color((m['color'] as num?)?.toInt() ?? 0xFF14B8A6),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SalesReportScreen(
              moduleId: m['id'] as int,
              customTitle: 'تقرير {v1}'.tr({'v1': m['name']}),
            ),
          ),
        ),
      },
    ],
    // 🆕 الخامات مخزون مشترك لكل الأقسام
    if (_modules.isNotEmpty) ...[
      {
        'title': 'إدارة الخامات',
        'group': 'الأقسام',
        'icon': Icons.inventory_2,
        'color': Colors.teal,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageMaterialsScreen()),
        ),
      },
      {
        'title': 'خامات الناقصه',
        'group': 'الأقسام',
        'icon': Icons.local_drink,
        'color': Colors.teal,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MaterialsReportScreen()),
        ),
      },
    ],
    {
      'title': 'تقرير المنتجات',
      'group': 'المتابعة',
      'icon': Icons.shopping_bag_outlined,
      'color': Colors.teal,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductsReportScreen()),
      ),
    },
    if (_cigarettesEnabled) // 🆕
      {
        'title': 'تقرير السجائر',
        'group': 'المتابعة',
        'icon': Icons.smoking_rooms,
        'color': Colors.brown,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>  SalesReportScreen(
              categoryFilter: ['cigarette'],
              customTitle: 'تقرير السجائر'.tr(),
            ),
          ),
        ),
      },
    if (_shishaEnabled) // 🆕
      {
        'title': 'تقرير الشيشة',
        'group': 'المتابعة',
        'icon': Icons.blur_on,
        'color': Colors.deepPurple,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>  SalesReportScreen(
              categoryFilter: ['shisha'],
              customTitle: 'تقرير الشيشة'.tr(),
            ),
          ),
        ),
      },

    {
      'title': 'إدارة المستخدمين',
      'group': 'الإدارة',
      'icon': Icons.person,
      'color': Colors.red,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ManageUsersScreen()),
      ),
    },
    {
      'title': 'إضافة مصروف',
      'group': 'الإدارة',
      'icon': Icons.attach_money,
      'color': Colors.indigo,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminExpensesScreen()),
      ),
    },
    {
      'title': 'العملاء',
      'group': 'الإدارة',
      'icon': Icons.person,
      'color': Colors.indigo,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomersReportScreen()),
      ),
    },
    {
      'title': 'كروت النت',
      'group': 'الإدارة',
      'icon': Icons.sd_card,
      'color': Colors.amber,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PrintCardsPage()),
      ),
    },
    {
      'title': 'رواتب الموظفين',
      'group': 'الإدارة',
      'icon': Icons.payments,
      'color': Colors.indigo,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PendingSalariesScreen()),
      ),
    },
    {
      'title': 'سجل التعديلات',
      'group': 'الإدارة',
      'icon': Icons.history,
      'color': Colors.indigoAccent,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuditLogScreen()),
      ),
    },
    {
      'title': 'الإعدادات',
      'group': 'الإدارة',
      'icon': Icons.settings,
      'color': Colors.blueGrey,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    },
    {
      'title': 'تفعيل',
      'group': 'الإدارة',
      'icon': Icons.settings,
      'color': Colors.blueGrey,
      'onTap': () => Navigator.push(
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
