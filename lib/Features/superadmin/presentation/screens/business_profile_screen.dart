import 'dart:io';

import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/business_profile_screen_mobile_body.dart';
part 'desktop/business_profile_screen_windows_body.dart';

/// تعديل الملف التجاري: اسم المكان + نوع النشاط + تفعيل البلايستيشن
class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _nameCtl = TextEditingController();
  String _type = 'cafe';
  bool _playstation = false;
  bool _loading = true;
  bool _saving = false;

  /// 🖼️ مسار لوجو البراند المخصوص — null يعني اللوجو الافتراضي المدمج.
  String? _logoPath;
  bool _pickingLogo = false;

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await BusinessProfile.getPlaceName();
    final type = await BusinessProfile.getBusinessType();
    final ps = await BusinessProfile.isPlaystationEnabled();
    final logo = await BusinessProfile.getLogoPath();
    if (!mounted) return;
    setState(() {
      _nameCtl.text = name;
      _type = type;
      _playstation = ps;
      _logoPath = logo;
      _loading = false;
    });
  }

  /// 🖼️ اختيار صورة اللوجو من الجهاز — بتتخزن في مجلد التطبيق فورًا
  /// (متستناش زرار الحفظ عشان ما يتوهش الاختيار لو المستخدم قفل الشاشة).
  Future<void> _pickLogo() async {
    if (_pickingLogo) return;
    setState(() => _pickingLogo = true);
    try {
      final path = await BusinessProfile.pickAndSetLogo();
      if (!mounted) return;
      if (path != null) {
        setState(() => _logoPath = path);
        AppToast.show('تم تحديث اللوجو ✅'.tr());
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show('فشل اختيار الصورة: {e}'.tr({'e': e}), kind: FeedbackKind.error);
    } finally {
      if (mounted) setState(() => _pickingLogo = false);
    }
  }

  /// 🖼️ إزالة اللوجو المخصوص — بيرجع اللوجو الافتراضي المدمج.
  Future<void> _clearLogo() async {
    await BusinessProfile.clearLogo();
    if (!mounted) return;
    setState(() => _logoPath = null);
    AppToast.show('راجع اللوجو الافتراضي ✅'.tr());
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtl.text.trim().isEmpty) {
      AppToast.show('اكتب اسم المكان'.tr(), kind: FeedbackKind.error);
      return;
    }
    setState(() => _saving = true);
    await BusinessProfile.setPlaceName(_nameCtl.text.trim());
    await BusinessProfile.setBusinessType(_type);
    await BusinessProfile.setPlaystationEnabled(_playstation);
    if (!mounted) return;
    AppToast.show('تم حفظ الملف التجاري ✅'.tr());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
