import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/widgets/BACKGROUND.dart';
import 'package:saytarly/Features/auth/presentation/screens/logout_helper.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/Features/dashboard/presentation/screens/admin.dart';
import 'package:saytarly/Features/users/presentation/screens/manage_users.dart';
import 'package:saytarly/Features/activation/presentation/screens/license_generator_screen.dart';
import 'package:saytarly/Features/auth/viewmodel/current_user.dart';
import 'package:saytarly/Features/settings/presentation/screens/setting.dart';
import 'package:saytarly/Features/sections/presentation/screens/modules_manager_screen.dart';
import 'package:saytarly/Features/superadmin/presentation/screens/setup_wizard.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/super_admin_dashboard_mobile_body.dart';
part 'desktop/super_admin_dashboard_windows_body.dart';

/// لوحة السوبر ادمن — مركز التحكم الكامل في تخصيص النظام
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  String _placeName = '...';
  String _typeLabel = '';
  int _modulesCount = 0;
  int _productsCount = 0;
  bool _setupCompleted = true;
  bool _wizardOpened = false;

  /// Navigator الخاص بهيكل الويندوز — بيخلي كل الشاشات تفتح جنب السايد بار.
  final GlobalKey<NavigatorState> _shellNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await BusinessProfile.getPlaceName();
    final type = await BusinessProfile.getBusinessType();
    final setup = await BusinessProfile.isSetupCompleted();
    final modules = await DBHelper.getModules();
    final db = await DBHelper.database;
    final products = await db.rawQuery('SELECT COUNT(*) AS c FROM drinks');
    final productsCount = (products.first['c'] as num?)?.toInt() ?? 0;

    if (!mounted) return;
    setState(() {
      _placeName = name;
      _typeLabel = BusinessProfile.typeLabel(type);
      _setupCompleted = setup;
      _modulesCount = modules.length;
      _productsCount = productsCount;
    });

    // أول مرة: افتح معالج التهيئة تلقائي
    if (!setup && !_wizardOpened && !SetupWizardScreen.wasShownOnce) {
      _wizardOpened = true;
      SetupWizardScreen.wasShownOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _push(const SetupWizardScreen(fromDashboard: true));
      });
    }
  }

  Future<void> _changePassword() async {
    final oldCtl = TextEditingController();
    final newCtl = TextEditingController();
    final confirmCtl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AppDialog(
            title: Text('تغيير كلمة سر السوبر ادمن'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldCtl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة السر الحالية'.tr(),
                  ),
                ),
                TextField(
                  controller: newCtl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة السر الجديدة'.tr(),
                  ),
                ),
                TextField(
                  controller: confirmCtl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة السر'.tr(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('حفظ'.tr()),
              ),
            ],
          ),
    );

    if (ok != true || !mounted) return;

    final userId = CurrentUser.userId;
    if (userId == null) return;
    final user = await DBHelper.getUserById(userId);
    if (user == null || user['password'] != oldCtl.text.trim()) {
      _snack('كلمة السر الحالية غير صحيحة'.tr(), error: true);
      return;
    }
    if (newCtl.text.trim().isEmpty ||
        newCtl.text.trim() != confirmCtl.text.trim()) {
      _snack('كلمة السر الجديدة غير متطابقة'.tr(), error: true);
      return;
    }
    await DBHelper.updateUserPassword(userId, newCtl.text.trim());
    _snack('تم تغيير كلمة السر ✅'.tr());
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    AppToast.show(msg, kind: error ? FeedbackKind.error : FeedbackKind.info);
  }

  Future<void> _push(Widget screen) async {
    final route = MaterialPageRoute<void>(builder: (_) => screen);
    final shellNavigator = _shellNavKey.currentState;
    if (shellNavigator != null) {
      await shellNavigator.push(route);
    } else {
      await Navigator.push(context, route);
    }
    _load();
  }

  List<Map<String, dynamic>> get _actions => [
    {
      'title': 'أقسام المنتجات'.tr(),
      'subtitle': '{v1} قسم • {v2} منتج'.tr({
        'v1': _modulesCount,
        'v2': _productsCount,
      }),
      'group': 'التخصيص'.tr(),
      'icon': Icons.category,
      'color': const Color(0xFF14B8A6),
      'page': (BuildContext _) => const ModulesManagerScreen(),
      'onTap': () => _push(const ModulesManagerScreen()),
    },
    {
      'title': 'بيانات المكان'.tr(),
      'subtitle':
          _setupCompleted
              ? '{_placeName} • {_typeLabel} — عدّل أي حاجة'.tr({'_placeName': _placeName, '_typeLabel': _typeLabel})
              : '⚠️ كمّل بيانات المكان الأول'.tr(),
      'group': 'التخصيص'.tr(),
      'icon': Icons.storefront,
      'color': Colors.deepPurple,
      'page': (BuildContext _) => const SetupWizardScreen(fromDashboard: true),
      'onTap': () => _push(const SetupWizardScreen(fromDashboard: true)),
    },
    {
      'title': 'إدارة المستخدمين'.tr(),
      'subtitle': 'حسابات الأدمن والستاف'.tr(),
      'group': 'الإدارة'.tr(),
      'icon': Icons.manage_accounts,
      'color': Colors.red,
      'page': (BuildContext _) => ManageUsersScreen(),
      'onTap': () => _push(ManageUsersScreen()),
    },
    {
      'title': 'لوحة الأدمن'.tr(),
      'subtitle': 'شوف النظام بعين الأدمن'.tr(),
      'group': 'الإدارة'.tr(),
      'icon': Icons.dashboard,
      'color': Colors.indigo,
      // Switching to the admin workspace means entering a different shell,
      // so this one intentionally opens on the root navigator.
      'onTap':
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboard()),
          ),
    },
    {
      'title': 'الإعدادات'.tr(),
      'subtitle': 'المظهر • النسخ الاحتياطي • الخصائص'.tr(),
      'group': 'الإدارة'.tr(),
      'icon': Icons.settings,
      'color': Colors.blueGrey,
      'page': (BuildContext _) => const SettingsScreen(),
      'onTap': () => _push(const SettingsScreen()),
    },
    {
      'title': 'التفعيل'.tr(),
      'subtitle': 'توليد كود تفعيل للجهاز'.tr(),
      'group': 'الإدارة'.tr(),
      'icon': Icons.key,
      'color': Colors.amber,
      'page': (BuildContext _) => const LicenseGeneratorScreen(),
      'onTap': () => _push(const LicenseGeneratorScreen()),
    },
    {
      'title': 'تغيير كلمة السر'.tr(),
      'subtitle': 'كلمة سر حساب السوبر ادمن'.tr(),
      'group': 'الإدارة'.tr(),
      'icon': Icons.lock,
      'color': Colors.orange,
      'onTap': _changePassword,
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
