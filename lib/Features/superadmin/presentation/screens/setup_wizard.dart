import 'package:flutter/material.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/Features/superadmin/presentation/screens/super_admin_dashboard.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/setup_wizard_mobile_body.dart';
part 'desktop/setup_wizard_windows_body.dart';

/// معالج التهيئة الأولية — بيظهر أول ما السوبر ادمن يدخل
/// الخطوات: اسم المكان ونوع النشاط → حساب الأدمن → حساب الستاف (اختياري) → أول الأقسام
class SetupWizardScreen extends StatefulWidget {
  final bool fromDashboard;

  /// بيتفتح تلقائي مرة واحدة بس في كل تشغيل
  static bool wasShownOnce = false;

  const SetupWizardScreen({super.key, this.fromDashboard = false});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;

  final _nameCtl = TextEditingController();
  final _adminUserCtl = TextEditingController();
  final _adminPassCtl = TextEditingController();
  final _staffUserCtl = TextEditingController();
  final _staffPassCtl = TextEditingController();
  final _moduleCtl = TextEditingController();

  String _businessType = 'cafe';
  bool _playstation = false;

  bool _saving = false;
  final List<String> _addedModules = [];

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void dispose() {
    _nameCtl.dispose();
    _adminUserCtl.dispose();
    _adminPassCtl.dispose();
    _staffUserCtl.dispose();
    _staffPassCtl.dispose();
    _moduleCtl.dispose();
    super.dispose();
  }

  // ============================ منطق ============================

  Future<bool> _createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.isEmpty || p.isEmpty) {
      _snack('اكتب اسم المستخدم وكلمة المرور'.tr(), error: true);
      return false;
    }
    if (u.toLowerCase() == 'superadmin') {
      _snack('الاسم ده محجوز للسوبر ادمن'.tr(), error: true);
      return false;
    }
    final users = await DBHelper.getAllUsers();
    if (users.any((x) => (x['username'] as String).toLowerCase() == u.toLowerCase())) {
      _snack('اسم المستخدم «{u}» موجود بالفعل'.tr({'u': u}), error: true);
      return false;
    }
    await DBHelper.insertUser({'username': u, 'password': p, 'role': role});
    return true;
  }

  Future<void> _addModuleFromField() async {
    final name = _moduleCtl.text.trim();
    if (name.isEmpty) {
      _snack('اكتب اسم القسم الأول'.tr(), error: true);
      return;
    }
    await DBHelper.insertModule({'name': name});
    _moduleCtl.clear();
    setState(() => _addedModules.add(name));
    _snack('تم إضافة قسم «{name}»'.tr({'name': name}));
  }

  /// زرار «التالي / إنشاء / ابدأ العمل» — نفس منطق الزرار الأصلي بالحرف.
  Future<void> _goNext() async {
    if (_step == 0) {
      if (_nameCtl.text.trim().isEmpty) {
        _snack('اكتب اسم المكان الأول'.tr(), error: true);
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      setState(() => _saving = true);
      final ok = await _createUser(
        username: _adminUserCtl.text,
        password: _adminPassCtl.text,
        role: 'admin',
      );
      setState(() => _saving = false);
      if (ok) {
        _snack('تم إنشاء حساب الأدمن ✅'.tr());
        setState(() => _step = 2);
      }
      return;
    }
    if (_step == 2) {
      final u = _staffUserCtl.text.trim();
      final p = _staffPassCtl.text.trim();
      if (u.isEmpty && p.isEmpty) {
        setState(() => _step = 3);
        return;
      }
      setState(() => _saving = true);
      final ok = await _createUser(
        username: u,
        password: p,
        role: 'cashier',
      );
      setState(() => _saving = false);
      if (ok) {
        _snack('تم إنشاء حساب الستاف ✅'.tr());
        setState(() => _step = 3);
      }
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_nameCtl.text.trim().isEmpty) {
      setState(() => _step = 0);
      _snack('اكتب اسم المكان الأول'.tr(), error: true);
      return;
    }
    setState(() => _saving = true);
    await BusinessProfile.setPlaceName(_nameCtl.text.trim());
    await BusinessProfile.setBusinessType(_businessType);
    await BusinessProfile.setPlaystationEnabled(_playstation);
    await BusinessProfile.setSetupCompleted(true);
    if (!mounted) return;
    if (widget.fromDashboard) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
      );
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    AppToast.show(msg, kind: error ? FeedbackKind.error : FeedbackKind.info);
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
