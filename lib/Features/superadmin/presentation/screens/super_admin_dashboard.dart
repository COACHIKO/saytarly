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
import 'package:saytarly/Features/superadmin/presentation/screens/business_profile_screen.dart';
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
    final productsCount =
        (products.first['c'] as num?)?.toInt() ?? 0;

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
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SetupWizardScreen(fromDashboard: true),
          ),
        );
        _load();
      });
    }
  }

  Future<void> _changePassword() async {
    final oldCtl = TextEditingController();
    final newCtl = TextEditingController();
    final confirmCtl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title:  Text('تغيير كلمة سر السوبر ادمن'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtl,
              obscureText: true,
              decoration:  InputDecoration(labelText: 'كلمة السر الحالية'.tr()),
            ),
            TextField(
              controller: newCtl,
              obscureText: true,
              decoration:  InputDecoration(labelText: 'كلمة السر الجديدة'.tr()),
            ),
            TextField(
              controller: confirmCtl,
              obscureText: true,
              decoration:  InputDecoration(labelText: 'تأكيد كلمة السر'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:  Text('حفظ'.tr()),
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
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  List<Map<String, dynamic>> get _actions => [
    {
      'title': 'الملف التجاري',
      'subtitle': '$_placeName • $_typeLabel',
      'group': 'التخصيص',
      'icon': Icons.storefront,
      'color': Colors.teal,
      'onTap': () => _push(const BusinessProfileScreen()),
    },
    {
      'title': 'أقسام المنتجات',
      'subtitle': '$_modulesCount قسم • $_productsCount منتج',
      'group': 'التخصيص',
      'icon': Icons.category,
      'color': const Color(0xFF14B8A6),
      'onTap': () => _push(const ModulesManagerScreen()),
    },
    {
      'title': 'معالج التهيئة',
      'subtitle': _setupCompleted
          ? 'إعادة تشغيل خطوات التهيئة'.tr()
          : '⚠️ لسه فيه خطوات تهيئة مطلوبة',
      'group': 'التخصيص',
      'icon': Icons.rocket_launch,
      'color': Colors.deepPurple,
      'onTap': () => _push(const SetupWizardScreen(fromDashboard: true)),
    },
    {
      'title': 'إدارة المستخدمين',
      'subtitle': 'حسابات الأدمن والستاف',
      'group': 'الإدارة',
      'icon': Icons.manage_accounts,
      'color': Colors.red,
      'onTap': () => _push(ManageUsersScreen()),
    },
    {
      'title': 'لوحة الأدمن',
      'subtitle': 'شوف النظام بعين الأدمن',
      'group': 'الإدارة',
      'icon': Icons.dashboard,
      'color': Colors.indigo,
      'onTap': () => _push(AdminDashboard()),
    },
    {
      'title': 'الإعدادات',
      'subtitle': 'المظهر • النسخ الاحتياطي • الخصائص',
      'group': 'الإدارة',
      'icon': Icons.settings,
      'color': Colors.blueGrey,
      'onTap': () => _push(const SettingsScreen()),
    },
    {
      'title': 'التفعيل',
      'subtitle': 'توليد كود تفعيل للجهاز',
      'group': 'الإدارة',
      'icon': Icons.key,
      'color': Colors.amber,
      'onTap': () => _push(const LicenseGeneratorScreen()),
    },
    {
      'title': 'تغيير كلمة السر',
      'subtitle': 'كلمة سر حساب السوبر ادمن',
      'group': 'الإدارة',
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
