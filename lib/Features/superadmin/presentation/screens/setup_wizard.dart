import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/core/services/app_settings.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/Features/superadmin/presentation/screens/super_admin_dashboard.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين، ومحتوى الخطوات مشترك بينهم
// عشان التجربة تفضل واحدة على أي جهاز.
part 'shared/setup_wizard_steps.dart';
part 'mobile/setup_wizard_mobile_body.dart';
part 'desktop/setup_wizard_windows_body.dart';

/// بيانات المكان — تجربة «استوديو» من ٧ خطوات بيظهر أول ما السوبر ادمن
/// يدخل، وبعد كده بيبقى المسار الوحيد لتعديل بيانات المطعم/الكافيه:
/// الهوية → الفواتير → حساب الأدمن → الفريق → الأقسام → المراجعة.
class SetupWizardScreen extends StatefulWidget {
  final bool fromDashboard;

  /// بيتفتح تلقائي مرة واحدة بس في كل تشغيل
  static bool wasShownOnce = false;

  const SetupWizardScreen({super.key, this.fromDashboard = false});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen>
    with WidgetsBindingObserver {
  /// مفتاح المسودة في جدول app_settings — بتتخزن كـ JSON.
  static const String _draftKey = 'setup_wizard_draft';

  int _step = 0;

  bool _loading = true;
  bool _saving = false;
  bool _finished = false;

  final _nameCtl = TextEditingController();
  final _currencyCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _taxCtl = TextEditingController();
  final _thanksCtl = TextEditingController();
  final _adminUserCtl = TextEditingController();
  final _adminPassCtl = TextEditingController();
  final _staffUserCtl = TextEditingController();
  final _staffPassCtl = TextEditingController();
  final _moduleCtl = TextEditingController();

  String _businessType = 'cafe';
  int _paperMm = 75;

  String? _logoPath;
  bool _pickingLogo = false;
  bool _showAdminPass = false;
  bool _showStaffPass = false;

  /// 🎛️ تشغيلات المكان — بيتظبطوا من التهيئة بس (مش من الإعدادات).
  bool _playstationEnabled = false;
  bool _shishaEnabled = false;
  bool _cigarettesEnabled = false;

  /// دور العضو في المحرر: cashier / waiter
  String _draftRole = 'cashier';

  /// فهرس العضو اللي بيتعدل دلوقتي — null يعني إضافة جديدة.
  int? _editingMemberIndex;

  /// كل الفريق (الموجود + الجديد) في قائمة واحدة قابلة للتعديل.
  final List<_TeamDraft> _team = [];
  final List<String> _existingModules = [];

  /// حسابات الأدمن الموجودة بالفعل — بتظهر في خطوة الأدمن عشان تقدر
  /// تعدّل واحد منها من غير ما تكتب كلمة سر جديدة.
  final List<Map<String, dynamic>> _existingAdmins = [];

  /// الأقسام الجديدة اللي اختارها المستخدم في خطوة المنيو.
  final List<String> _selectedModules = [];

  /// مسودة محفوظة اتفتحت مع المستخدم في الجلسة دي.
  bool _resumedFromDraft = false;
  Timer? _draftTimer;

  /// التهيئة خلصت خلاص — ساعتها المسودات ملغية.
  bool _setupCompleted = false;

  // ============================ تحميل الحالة ============================

  Iterable<TextEditingController> get _allControllers => [
    _nameCtl,
    _currencyCtl,
    _phoneCtl,
    _addressCtl,
    _taxCtl,
    _thanksCtl,
    _adminUserCtl,
    _adminPassCtl,
    _staffUserCtl,
    _staffPassCtl,
    _moduleCtl,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final controller in _allControllers) {
      controller.addListener(_scheduleDraftSave);
    }
    _loadExisting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    // بنحفظ المسودة قبل ما الكنترولرز تتقفل — لو المستخدم قفل الشاشة
    // أو رجع، يقدر يكمّل من نفس النقطة بعدين.
    _saveDraft();
    for (final controller in _allControllers) {
      controller.removeListener(_scheduleDraftSave);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveDraft();
    }
  }

  Future<void> _loadExisting() async {
    try {
      final name = await DBHelper.getSetting(DBHelper.kBusinessNameKey) ?? '';
      final type = await BusinessProfile.getBusinessType();
      final logo = await BusinessProfile.getLogoPath();
      final symbol =
          await DBHelper.getSetting(DBHelper.kCurrencySymbolKey) ?? '';
      final phone = await DBHelper.getSetting(DBHelper.kReceiptPhoneKey) ?? '';
      final address =
          await DBHelper.getSetting(DBHelper.kReceiptAddressKey) ?? '';
      final taxId = await DBHelper.getSetting(DBHelper.kReceiptTaxIdKey) ?? '';
      final thanks = await DBHelper.getSetting(DBHelper.kReceiptThanksKey) ?? '';
      final paper = await BusinessProfile.getInvoicePaperMm();
      final setupDone = await BusinessProfile.isSetupCompleted();
      final modules = await DBHelper.getModules();
      final users = await DBHelper.getAllUsers();
      final namesById = <int, String>{
        for (final user in users)
          if ((user['id'] as num?)?.toInt() != null)
            (user['id'] as num).toInt(): (user['username'] ?? '').toString(),
      };

      // 🎛️ التشغيلات الحالية — الأساس لقيم الخطوة الأولى، والمسودة بتفوق عليها.
      final playstationNow = await BusinessProfile.isPlaystationEnabled();
      final shishaNow = await AppSettings.getShishaEnabled();
      final cigarettesNow = await AppSettings.getCigarettesEnabled();

      // 🌿 فروع التعيين الحالية — عشان نعرف المشرفين ليهم كل موظف.
      final assignmentRows = await DBHelper.getAllStaffAssignments();
      final assignmentNames = <int, List<String>>{};
      for (final row in assignmentRows) {
        final waiterId = (row['waiter_id'] as num?)?.toInt();
        final supervisorId = (row['supervisor_id'] as num?)?.toInt();
        if (waiterId == null || supervisorId == null) continue;
        assignmentNames.putIfAbsent(waiterId, () => []);
        final supName = namesById[supervisorId];
        if (supName != null && !assignmentNames[waiterId]!.contains(supName)) {
          assignmentNames[waiterId]!.add(supName);
        }
      }

      final admins =
          users
              .where((u) => (u['role'] ?? '').toString() == 'admin')
              .toList();
      final staff =
          users
              .where((u) {
                final r = (u['role'] ?? '').toString();
                return r == 'cashier' || r == 'waiter';
              })
              .toList();

      // مسودة محفوظة من جلسة سابقة — بنسترجعها فوق البيانات المحفوظة.
      Map<String, dynamic>? draft;
      final rawDraft = await DBHelper.getSetting(_draftKey);
      if (rawDraft != null && rawDraft.trim().isNotEmpty) {
        try {
          draft = Map<String, dynamic>.from(jsonDecode(rawDraft) as Map);
        } catch (_) {
          draft = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _nameCtl.text = name;
        _businessType = type;
        _logoPath = logo;
        _currencyCtl.text = symbol;
        _phoneCtl.text = phone;
        _addressCtl.text = address;
        _taxCtl.text = taxId;
        _thanksCtl.text = thanks;
        _paperMm = paper;
        _playstationEnabled = playstationNow;
        _shishaEnabled = shishaNow;
        _cigarettesEnabled = cigarettesNow;
        _existingModules
          ..clear()
          ..addAll(
            modules
                .map((m) => (m['name'] ?? '').toString().trim())
                .where((n) => n.isNotEmpty),
          );
        _existingAdmins
          ..clear()
          ..addAll(admins);
        _adminUserCtl.text =
            admins.isEmpty
                ? ''
                : (admins.first['username'] ?? '').toString();
        _team
          ..clear()
          ..addAll(
            staff.map((user) {
              final userSupervisors =
                  _supervisorNamesForUser(user, namesById, assignmentNames);
              return _TeamDraft(
                id: (user['id'] as num?)?.toInt(),
                username: (user['username'] ?? '').toString(),
                password: (user['password'] ?? '').toString(),
                role: (user['role'] ?? 'cashier').toString(),
                supervisors: userSupervisors,
              );
            }),
          );
        // المسودة بتستخدم بس وإحنا لسه في التهيئة الأولى. لو المكان
        // متظبط خلاص، بنعتمد على البيانات المحفوظة ونطنّش أي مسودة قديمة.
        if (draft != null && !setupDone) _applyDraft(draft);
        _setupCompleted = setupDone;
        _loading = false;
      });
      // مسودة قديمة اتسابت بعد ما التهيئة خلصت — مش محتاجينها.
      if (draft != null && setupDone) await _clearDraft();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============================ المسودة ============================

  /// بترجع آخر مسودة محفوظة وتكمل منها — من غير ما تلمس البيانات المحفوظة.
  void _applyDraft(Map<String, dynamic> draft) {
    String text(String key, String fallback) {
      final value = draft[key];
      return value is String ? value : fallback;
    }

    final rawStep = (draft['step'] as num?)?.toInt() ?? 0;
    _step =
        rawStep < 0
            ? 0
            : (rawStep >= _wizSteps.length ? _wizSteps.length - 1 : rawStep);

    _nameCtl.text = text('name', _nameCtl.text);
    _currencyCtl.text = text('currency', _currencyCtl.text);
    _phoneCtl.text = text('phone', _phoneCtl.text);
    _addressCtl.text = text('address', _addressCtl.text);
    _taxCtl.text = text('taxId', _taxCtl.text);
    _thanksCtl.text = text('thanks', _thanksCtl.text);
    _adminUserCtl.text = text('adminUser', _adminUserCtl.text);
    _adminPassCtl.text = text('adminPass', _adminPassCtl.text);
    _staffUserCtl.text = text('staffUser', _staffUserCtl.text);
    _staffPassCtl.text = text('staffPass', _staffPassCtl.text);
    _businessType = text('type', _businessType);
    _draftRole = text('draftRole', text('newRole', _draftRole));

    // 🎛️ التشغيلات من المسودة — على يعيدها زي ما كانت بالظبط.
    final features = draft['features'];
    if (features is Map) {
      final playstation = features['playstation'];
      final shisha = features['shisha'];
      final cigarettes = features['cigarettes'];
      if (playstation is bool) _playstationEnabled = playstation;
      if (shisha is bool) _shishaEnabled = shisha;
      if (cigarettes is bool) _cigarettesEnabled = cigarettes;
    }

    final paper = (draft['paperMm'] as num?)?.toInt();
    if (paper != null && BusinessProfile.invoicePaperOptions.contains(paper)) {
      _paperMm = paper;
    }
    final logo = draft['logoPath'];
    if (logo is String && logo.isNotEmpty && File(logo).existsSync()) {
      _logoPath = logo;
    }

    final modules = draft['modules'];
    if (modules is List) {
      _selectedModules
        ..clear()
        ..addAll(
          modules
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty && !_existingModules.contains(e)),
        );
    }

    final team = draft['team'];
    if (team is List) {
      _team.clear();
      for (final row in team) {
        if (row is! Map) continue;
        final username = (row['username'] ?? '').toString().trim();
        final password = (row['password'] ?? '').toString();
        final role = (row['role'] ?? 'cashier').toString();
        // الصيغة الجديدة قائمة مشرفين، والقديمة سلسلة مشرف واحد.
        final supervisors = <String>[];
        final rawList = row['supervisors'];
        if (rawList is List) {
          supervisors.addAll(
            rawList.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
          );
        } else if (rawList == null) {
          final legacy = (row['supervisor'] ?? '').toString().trim();
          if (legacy.isNotEmpty) supervisors.add(legacy);
        }
        if (username.isEmpty || password.isEmpty) continue;
        _team.add(
          _TeamDraft(
            id: (row['id'] as num?)?.toInt(),
            username: username,
            password: password,
            role: role,
            supervisors: supervisors,
          ),
        );
      }
    }

    _resumedFromDraft = true;
  }

  /// حفظ المسودة كـ JSON في app_settings — بتتنفذ بعد أي تعديل أو خروج.
  Future<void> _saveDraft() async {
    if (_loading || _finished || _setupCompleted) return;
    try {
      final data = <String, dynamic>{
        'savedAt': DateTime.now().toIso8601String(),
        'step': _step,
        'name': _nameCtl.text,
        'currency': _currencyCtl.text,
        'phone': _phoneCtl.text,
        'address': _addressCtl.text,
        'taxId': _taxCtl.text,
        'thanks': _thanksCtl.text,
        'adminUser': _adminUserCtl.text,
        'adminPass': _adminPassCtl.text,
        'staffUser': _staffUserCtl.text,
        'staffPass': _staffPassCtl.text,
        'type': _businessType,
        'draftRole': _draftRole,
        'features': {
          'playstation': _playstationEnabled,
          'shisha': _shishaEnabled,
          'cigarettes': _cigarettesEnabled,
        },
        'paperMm': _paperMm,
        'logoPath': _logoPath,
        'modules': List<String>.from(_selectedModules),
        'team': [
          for (final member in _team)
            {
              'id': member.id,
              'username': member.username,
              'password': member.password,
              'role': member.role,
              'supervisors': [for (final s in member.supervisors) s],
            },
        ],
      };
      await DBHelper.setSetting(_draftKey, jsonEncode(data));
    } catch (_) {
      // المسودة تحسين اختياري — أي فشل فيها ما يعطّلش التهيئة.
    }
  }

  void _scheduleDraftSave() {
    if (_loading || _finished || _setupCompleted) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), () {
      _saveDraft();
    });
  }

  Future<void> _clearDraft() async {
    _draftTimer?.cancel();
    try {
      await DBHelper.setSetting(_draftKey, '');
    } catch (_) {
      // تجاهل — مفيش مسودة تتشال أصلًا.
    }
  }

  // ============================ حسابات ============================

  /// بيرجع حساب الأدمن الموجود بنفس الاسم (مش حساس لحالة الحروف).
  Map<String, dynamic>? _findExistingAdmin(String username) {
    final lower = username.trim().toLowerCase();
    if (lower.isEmpty) return null;
    for (final admin in _existingAdmins) {
      if (((admin['username'] ?? '') as String).toLowerCase() == lower) {
        return admin;
      }
    }
    return null;
  }

  /// هل الاسم المكتوب حاليًا بيطابق حساب أدمن موجود؟
  bool get _isExistingAdmin =>
      _findExistingAdmin(_adminUserCtl.text) != null;

  /// خطوة الأدمن جاهزة؟ الحساب الموجود مش محتاج كلمة سر جديدة،
  /// إنما الحساب الجديد لازم يكون معاه كلمة سر.
  bool get _adminFormReady {
    final user = _adminUserCtl.text.trim();
    final pass = _adminPassCtl.text.trim();
    if (user.isEmpty) return false;
    if (_isExistingAdmin) return pass.isEmpty || pass.length >= 4;
    return pass.length >= 4;
  }

  int get _readiness {
    var score = 0;
    if (_nameCtl.text.trim().isNotEmpty) score += 22;
    if (_logoPath != null) score += 8;
    if (_phoneCtl.text.trim().isNotEmpty) score += 8;
    if (_addressCtl.text.trim().isNotEmpty) score += 6;
    if (_adminFormReady) score += 26;
    if (_team.isNotEmpty) score += 10;
    if (_moduleCount > 0) score += 20;
    return math.min(100, score);
  }

  int get _moduleCount => _selectedModules.length + _existingModules.length;

  int get _teamCount => _team.length;

  String get _nextLabel {
    if (_step == 0) return 'يلا نبدأ ✨'.tr();
    if (_step == _wizSteps.length - 1) return 'افتح المكان 🚀'.tr();
    return 'التالي'.tr();
  }

  int _passwordScore(String value) {
    var score = 0;
    if (value.length >= 4) score++;
    if (value.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(value) &&
        RegExp(r'[A-Za-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  void _suggestPassword() {
    const words = [
      'Latte',
      'Mocha',
      'Oasis',
      'Golden',
      'Sunset',
      'Amber',
      'Cedar',
      'Nova',
    ];
    const tails = ['!', '#', '@', '*'];
    final rnd = math.Random();
    final password =
        '${words[rnd.nextInt(words.length)]}'
        '${rnd.nextInt(90) + 10}'
        '${tails[rnd.nextInt(tails.length)]}';
    setState(() => _adminPassCtl.text = password);
  }

  /// اختيار حساب أدمن موجود للتعديل — كلمة السر بتفضل فاضية
  /// عشان تفضل زي ما هي إلا لو المستخدم كتب واحدة جديدة.
  void _selectExistingAdmin(String username) {
    _refresh(() {
      _adminUserCtl.text = username;
      _adminPassCtl.clear();
      _showAdminPass = false;
    });
  }

  /// التحويل لوضع إنشاء حساب أدمن جديد.
  void _startNewAdmin() {
    _refresh(() {
      _adminUserCtl.clear();
      _adminPassCtl.clear();
      _showAdminPass = false;
    });
  }

  // ============================ لوجو ============================

  Future<void> _pickLogo() async {
    if (_pickingLogo) return;
    setState(() => _pickingLogo = true);
    try {
      final path = await BusinessProfile.pickAndSetLogo();
      if (!mounted) return;
      if (path != null) setState(() => _logoPath = path);
      _snack('تم تحديث اللوجو ✅'.tr());
    } catch (e) {
      if (!mounted) return;
      _snack('فشل اختيار الصورة: {e}'.tr({'e': e}), error: true);
    } finally {
      if (mounted) setState(() => _pickingLogo = false);
    }
  }

  Future<void> _clearLogo() async {
    await BusinessProfile.clearLogo();
    if (!mounted) return;
    setState(() => _logoPath = null);
    _snack('رجعنا للوجو الافتراضي'.tr());
  }

  // ============================ التنقل ============================

  Future<void> _goNext() async {
    if (_saving) return;

    switch (_step) {
      case 0:
        setState(() => _step = 1);
      case 1:
        if (_nameCtl.text.trim().isEmpty) {
          _snack('اكتب اسم المكان الأول'.tr(), error: true);
          return;
        }
        setState(() => _step = 2);
      case 2:
        setState(() => _step = 3);
      case 3:
        await _validateAdminStep();
      case 4:
        setState(() => _step = 5);
      case 5:
        setState(() => _step = 6);
      default:
        await _finish();
    }
  }

  void _skipStep() {
    if (_step >= _wizSteps.length - 1) return;
    setState(() => _step++);
  }

  void _jumpTo(int step) {
    if (step < 0 || step >= _wizSteps.length) return;
    setState(() => _step = step);
  }

  Future<void> _validateAdminStep() async {
    final user = _adminUserCtl.text.trim();
    final pass = _adminPassCtl.text.trim();
    final existingAdmin = _findExistingAdmin(user);

    if (user.isEmpty) {
      _snack('اكتب اسم مستخدم الأدمن'.tr(), error: true);
      return;
    }
    if (user.toLowerCase() == 'superadmin') {
      _snack('الاسم ده محجوز للسوبر ادمن'.tr(), error: true);
      return;
    }
    // الحساب الموجود مش محتاج كلمة سر جديدة — لو اكتبت واحدة لازم تكون ٤ حروف.
    if (existingAdmin == null) {
      if (pass.length < 4) {
        _snack('كلمة السر لازم ٤ حروف على الأقل'.tr(), error: true);
        return;
      }
    } else if (pass.isNotEmpty && pass.length < 4) {
      _snack('كلمة السر لازم ٤ حروف على الأقل'.tr(), error: true);
      return;
    }
    if (existingAdmin == null) {
      final users = await DBHelper.getAllUsers();
      final taken = users.any(
        (u) =>
            ((u['username'] ?? '') as String).toLowerCase() ==
            user.toLowerCase(),
      );
      if (taken) {
        _snack('اسم المستخدم «{u}» موجود بالفعل'.tr({'u': user}), error: true);
        return;
      }
    }
    if (!mounted) return;
    setState(() => _step = 4);
  }

  // ============================ الفريق ============================

  void _resetMemberForm() {
    _editingMemberIndex = null;
    _staffUserCtl.clear();
    _staffPassCtl.clear();
    _draftRole = 'cashier';
    _showStaffPass = false;
  }

  void _startEditMember(int index) {
    final member = _team[index];
    _refresh(() {
      _editingMemberIndex = index;
      _staffUserCtl.text = member.username;
      _staffPassCtl.text = member.password;
      _draftRole = member.role;
      _showStaffPass = false;
    });
  }

  void _cancelMemberEdit() {
    _refresh(_resetMemberForm);
  }

  Future<void> _saveTeamMember() async {
    final user = _staffUserCtl.text.trim();
    final pass = _staffPassCtl.text.trim();
    final editingIndex = _editingMemberIndex;
    final editing = editingIndex == null ? null : _team[editingIndex];

    if (user.isEmpty || pass.isEmpty) {
      _snack('اكتب اسم المستخدم وكلمة المرور'.tr(), error: true);
      return;
    }
    if (pass.length < 4) {
      _snack('كلمة السر لازم 4 حروف على الأقل'.tr(), error: true);
      return;
    }

    if (editing == null || !editing.isExisting) {
      final lower = user.toLowerCase();
      if (lower == 'superadmin' ||
          lower == _adminUserCtl.text.trim().toLowerCase()) {
        _snack('الاسم ده محجوز لحساب تاني'.tr(), error: true);
        return;
      }
      final duplicate = _team.any(
        (member) => member.username.toLowerCase() == lower,
      );
      if (duplicate) {
        _snack('العضو ده مضاف بالفعل'.tr(), error: true);
        return;
      }
      final users = await DBHelper.getAllUsers();
      final taken = users.any(
        (row) => ((row['username'] ?? '') as String).toLowerCase() == lower,
      );
      if (taken) {
        _snack(
          'اسم المستخدم «{u}» موجود بالفعل'.tr({'u': user}),
          error: true,
        );
        return;
      }
    }

    if (!mounted) return;
    _refresh(() {
      if (editingIndex != null) {
        // 🌿 التفرّع مالوش هنا — تعديل عضو موجود بيسيب مشرفينه زي ما هما
        // (وبيصفّيهم لو الدور بقى كاشير)؛ إدارة المستخدمين هي اللي بتقرر.
        _team[editingIndex] = _TeamDraft(
          id: _team[editingIndex].id,
          username: user,
          password: pass,
          role: _draftRole,
          supervisors:
              _draftRole == 'waiter'
                  ? _team[editingIndex].supervisors
                  : const [],
        );
      } else {
        // عضو جديد — بلا مشرفين؛ التفرّع من إدارة المستخدمين بعد التهيئة.
        _team.add(
          _TeamDraft(username: user, password: pass, role: _draftRole),
        );
      }
      _resetMemberForm();
    });
    _snack(
      editingIndex == null
          ? 'تمت إضافة «{u}» للفريق ✅'.tr({'u': user})
          : 'تم تحديث بيانات «{u}» ✅'.tr({'u': user}),
    );
  }

  Future<int> _upsertMember(_TeamDraft member, int? supervisorId) async {
    final db = await DBHelper.database;
    final data = <String, dynamic>{
      'password': member.password,
      'role': member.role,
      'supervisor_id': supervisorId,
    };
    final existingId = member.id;
    if (existingId != null) {
      await db.update(
        'users',
        data,
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    }
    return DBHelper.insertUser({
      'username': member.username,
      'password': member.password,
      'role': member.role,
      'supervisor_id': supervisorId,
    });
  }

  Future<void> _commitTeam() async {
    final users = await DBHelper.getAllUsers();
    final ids = <String, int>{};
    for (final row in users) {
      final id = (row['id'] as num?)?.toInt();
      final name = (row['username'] ?? '').toString().trim().toLowerCase();
      if (id != null && name.isNotEmpty) ids[name] = id;
    }

    // الجذور بيتسجلوا الأول، وبعده الموظفين تعرف المشرفين ليهم.
    final pendingStaff = <_TeamDraft>[];
    for (final member in _team) {
      if (member.role == 'waiter') {
        pendingStaff.add(member);
        continue;
      }
      final id = await _upsertMember(member, null);
      ids[member.username.trim().toLowerCase()] = id;
    }

    for (final member in pendingStaff) {
      // 🌿 كل المشرفين — حسب اختيار المستخدم (يقدر يكونوا أكتر من واحد).
      final supervisorIds = <int>[];
      for (final name in member.supervisors) {
        final id = ids[name.trim().toLowerCase()];
        if (id != null && !supervisorIds.contains(id)) supervisorIds.add(id);
      }
      final primaryId = supervisorIds.isEmpty ? null : supervisorIds.first;
      final id = await _upsertMember(member, primaryId);
      ids[member.username.trim().toLowerCase()] = id;

      await DBHelper.unassignAllWaiters(id);
      for (final supervisorId in supervisorIds) {
        await DBHelper.assignWaiterToSupervisor(
          waiterId: id,
          supervisorId: supervisorId,
        );
      }
      // المشرف الأساسي يتسجل صريحًا زي إدارة المستخدمين بالظبط.
      final db = await DBHelper.database;
      await db.update(
        'users',
        {'supervisor_id': primaryId},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ============================ الأقسام ============================

  void _toggleModule(String name) {
    if (_existingModules.contains(name)) return;
    setState(() {
      if (_selectedModules.contains(name)) {
        _selectedModules.remove(name);
      } else {
        _selectedModules.add(name);
      }
    });
  }

  void _selectAllModules() {
    setState(() {
      for (final preset in _modulePresets) {
        if (!_existingModules.contains(preset.name) &&
            !_selectedModules.contains(preset.name)) {
          _selectedModules.add(preset.name);
        }
      }
    });
  }

  void _clearModules() {
    setState(_selectedModules.clear);
  }

  void _addCustomModule() {
    final name = _moduleCtl.text.trim();
    if (name.isEmpty) {
      _snack('اكتب اسم القسم'.tr(), error: true);
      return;
    }
    if (_existingModules.contains(name) || _selectedModules.contains(name)) {
      _snack('القسم «{n}» موجود بالفعل'.tr({'n': name}), error: true);
      return;
    }
    setState(() {
      _selectedModules.add(name);
      _moduleCtl.clear();
    });
  }

  // ============================ الحفظ ============================

  Future<void> _finish() async {
    if (_nameCtl.text.trim().isEmpty) {
      setState(() => _step = 1);
      _snack('اكتب اسم المكان الأول'.tr(), error: true);
      return;
    }
    if (!_adminFormReady) {
      setState(() => _step = 3);
      _snack('كمّل بيانات حساب الأدمن الأول'.tr(), error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await BusinessProfile.setPlaceName(_nameCtl.text.trim());
      await BusinessProfile.setBusinessType(_businessType);
      await BusinessProfile.setCurrencySymbol(_currencyCtl.text.trim());
      await BusinessProfile.setReceiptInfo(
        thanks:
            _thanksCtl.text.trim().isEmpty
                ? 'شكراً لزيارتكم'.tr()
                : _thanksCtl.text.trim(),
        phone: _phoneCtl.text.trim(),
        address: _addressCtl.text.trim(),
        taxId: _taxCtl.text.trim(),
      );
      await BusinessProfile.setInvoicePaperMm(_paperMm);

      // 🎛️ تشغيلات المكان — من التهيئة بس.
      await BusinessProfile.setPlaystationEnabled(_playstationEnabled);
      await AppSettings.setShishaEnabled(_shishaEnabled);
      await AppSettings.setCigarettesEnabled(_cigarettesEnabled);

      final adminUser = _adminUserCtl.text.trim();
      final adminPass = _adminPassCtl.text.trim();
      final existingAdmin = _findExistingAdmin(adminUser);
      if (existingAdmin != null) {
        // حساب موجود — بنحدّث كلمة السر بس لو المستخدم كتب واحدة جديدة.
        final adminId = (existingAdmin['id'] as num?)?.toInt();
        if (adminId != null && adminPass.isNotEmpty) {
          await DBHelper.updateUserPassword(adminId, adminPass);
        }
      } else if (adminUser.isNotEmpty) {
        await DBHelper.insertUser({
          'username': adminUser,
          'password': adminPass,
          'role': 'admin',
        });
      }

      await _commitTeam();

      for (final moduleName in _selectedModules) {
        if (_existingModules.contains(moduleName)) continue;
        var iconKey = 'category';
        var colorValue = 0xFF14B8A6;
        for (final preset in _modulePresets) {
          if (preset.name == moduleName) {
            iconKey = preset.iconKey;
            colorValue = preset.colorValue;
            break;
          }
        }
        await DBHelper.insertModule({
          'name': moduleName,
          'icon': iconKey,
          'color': colorValue,
        });
      }

      await BusinessProfile.setSetupCompleted(true);
      // خلصنا — مفيش لزمة نكمل من مسودة بعد كده.
      await _clearDraft();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _setupCompleted = true;
        _finished = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('حصلت مشكلة أثناء الحفظ: {e}'.tr({'e': e}), error: true);
    }
  }

  Future<void> _leave() async {
    if (!mounted) return;
    if (widget.fromDashboard) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
    );
  }

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (shared / mobile / windows).
  void _refresh(VoidCallback fn) {
    setState(fn);
    _scheduleDraftSave();
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

/// 🌿 أسماء المشرفين لموظف: المشرف الأساسي (supervisor_id) أولًا، وبعده
/// باقي فروع sub_staff_assignments — عشان القائمة تعكس الماسة كاملة.
List<String> _supervisorNamesForUser(
  Map<String, dynamic> user,
  Map<int, String> namesById,
  Map<int, List<String>> assignmentNames,
) {
  final id = (user['id'] as num?)?.toInt();
  final names = <String>[];
  final primaryId = (user['supervisor_id'] as num?)?.toInt();
  final primaryName = primaryId == null ? null : namesById[primaryId];
  if (primaryName != null) names.add(primaryName);
  for (final name in (id == null ? null : assignmentNames[id]) ?? const <String>[]) {
    if (!names.contains(name)) names.add(name);
  }
  return names;
}
