import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saytarly/Features/activation/data/license_manager.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/license_generator_screen_mobile_body.dart';
part 'desktop/license_generator_screen_windows_body.dart';

class LicenseGeneratorScreen extends StatefulWidget {
  const LicenseGeneratorScreen({super.key});

  @override
  State<LicenseGeneratorScreen> createState() => _LicenseGeneratorScreenState();
}

class _LicenseGeneratorScreenState extends State<LicenseGeneratorScreen> {
  final _deviceController = TextEditingController();

  int _days = 30;
  String _generatedCode = '';

  List<Map<String, dynamic>> get _durations => [
    {'label': 'يوم واحد'.tr(), 'days': 1},
    {'label': '7 أيام'.tr(), 'days': 7},
    {'label': '30 يوم'.tr(), 'days': 30},
    {'label': '90 يوم'.tr(), 'days': 90},
    {'label': '6 شهور'.tr(), 'days': 180},
    {'label': 'سنة'.tr(), 'days': 365},
    {'label': 'دائم مدى الحياة'.tr(), 'days': 36500},
  ];

  void _generate() {
    final deviceId = _deviceController.text.trim();

    if (deviceId.isEmpty) {
      AppToast.show('أدخل كود جهاز العميل أولاً'.tr());
      return;
    }

    final code = LicenseManager.generateCode(deviceId, _days);

    setState(() {
      _generatedCode = code;
    });
  }

  Future<void> _copyCode() async {
    if (_generatedCode.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _generatedCode));

    if (!mounted) return;

    AppToast.show('تم نسخ كود التفعيل'.tr());
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

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }
}
