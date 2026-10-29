// lib/Screens/activation_screen.dart
//
// شاشة تفعيل البرنامج — تظهر لأول مرة أو عند انتهاء الترخيص.
// العميل يرى كود جهازه ويدخل كود التفعيل الذي يرسله له المهندس.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/Features/activation/data/license_manager.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/activation_screen_mobile_body.dart';
part 'desktop/activation_screen_windows_body.dart';

class ActivationScreen extends StatefulWidget {
  /// يُستدعى بعد تفعيل ناجح لإعادة تشغيل التطبيق
  final VoidCallback onActivated;

  /// هل الرخصة منتهية (true) أم لم تُفعَّل قط (false)
  final bool isExpired;

  const ActivationScreen({
    super.key,
    required this.onActivated,
    this.isExpired = false,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  String _deviceId = '';
  bool _loadingId = true;

  final _codeCtrl = TextEditingController();
  bool _activating = false;
  String? _errorMsg;
  String? _successMsg;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    try {
      final id = await DeviceFingerprint.deviceId();
      setState(() {
        _deviceId = id;
        _loadingId = false;
      });
    } catch (_) {
      setState(() {
        _deviceId = 'تعذّر قراءة بصمة الجهاز'.tr();
        _loadingId = false;
      });
    }
  }

  Future<void> _activate() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMsg = 'أدخل كود التفعيل أولاً'.tr());
      return;
    }

    setState(() {
      _activating = true;
      _errorMsg = null;
      _successMsg = null;
    });

    final info = LicenseManager.verifyCode(_deviceId, code);

    if (info.status == LicenseStatus.invalid) {
      setState(() {
        _errorMsg = 'كود التفعيل غير صحيح — تأكد من الكود وحاول مرة ثانية'.tr();
        _activating = false;
      });
      return;
    }

    if (info.status == LicenseStatus.expired) {
      setState(() {
        _errorMsg = 'كود التفعيل منتهي الصلاحية — تواصل مع المهندس للتجديد'.tr();
        _activating = false;
      });
      return;
    }

    // حفظ الرخصة
    await LicenseManager.saveLicense(_deviceId, code);

    final msg = info.isLifetime
        ? '✅ تم التفعيل بنجاح — رخصة دائمة مدى الحياة'.tr()
        : '✅ تم التفعيل — ${LicenseManager.formatRemaining(info.expiresAt!)}';

    setState(() {
      _successMsg = msg;
      _activating = false;
    });

    await Future.delayed(const Duration(seconds: 2));
    widget.onActivated();
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

