// lib/Screens/admin/code_generator_screen.dart
//
// شاشة توليد أكواد التفعيل — للمهندس فقط.
// إنت تدخل كود الجهاز (اللي بيبعته العميل) وتختار المدة،
// ويطلع كود التفعيل اللي تبعته للعميل.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saytarly/Features/activation/data/license_manager.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/code_generator_screen_mobile_body.dart';
part 'desktop/code_generator_screen_windows_body.dart';

class CodeGeneratorScreen extends StatefulWidget {
  const CodeGeneratorScreen({super.key});

  @override
  State<CodeGeneratorScreen> createState() => _CodeGeneratorScreenState();
}

class _CodeGeneratorScreenState extends State<CodeGeneratorScreen> {
  // ── كلمة سر بسيطة لحماية الشاشة من المستخدم العادي ──
  static const String _adminPassword = 'eng2025';
  bool _unlocked = false;
  final _passCtrl = TextEditingController();
  bool _passError = false;

  // ── حقل كود الجهاز ──
  final _deviceIdCtrl = TextEditingController();

  // ── المدة المختارة ──
  int _selectedDays = 7;
  final _customDaysCtrl = TextEditingController(text: '7');
  bool _isLifetime = false;

  // ── النتيجة ──
  String? _generatedCode;
  bool _justCopied = false;

  // ── كود الجهاز الحالي (لملء تلقائي) ──
  String _currentDeviceId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentDevice();
  }

  Future<void> _loadCurrentDevice() async {
    try {
      final id = await DeviceFingerprint.deviceId();
      setState(() => _currentDeviceId = id);
    } catch (_) {}
  }

  void _unlock() {
    if (_passCtrl.text == _adminPassword) {
      setState(() {
        _unlocked = true;
        _passError = false;
      });
    } else {
      setState(() => _passError = true);
    }
  }

  void _generate() {
    final deviceId = _deviceIdCtrl.text.trim();
    if (deviceId.isEmpty) {
      AppToast.show('أدخل كود الجهاز أولاً'.tr());
      return;
    }

    final days = _isLifetime
        ? 36500
        : (int.tryParse(_customDaysCtrl.text) ?? _selectedDays);

    final code = LicenseManager.generateCode(deviceId, days);
    setState(() {
      _generatedCode = code;
      _justCopied = false;
    });
  }

  Future<void> _copyCode() async {
    if (_generatedCode == null) return;
    await Clipboard.setData(ClipboardData(text: _generatedCode!));
    setState(() => _justCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _justCopied = false);
  }

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

