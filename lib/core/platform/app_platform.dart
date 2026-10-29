import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// شكل الواجهة اللي المفروض تتعرض على الجهاز الحالي.
enum AppFormFactor {
  /// واجهة الموبايل — هي الشكل القديم كما هو.
  mobile,

  /// واجهة سطح المكتب (Windows UI) — سايد بار + شاشات عريضة + أدوات ماوس.
  desktop,
}

/// مسؤول عن تحديد "الشكل" المستخدم في كل شاشة.
///
/// القاعدة الأساسية:
/// - ويندوز / لينكس / ماك → [AppFormFactor.desktop] دائمًا.
/// - أندرويد / iOS / الويب → [AppFormFactor.mobile] دائمًا.
///
/// كل شاشة بتقرر في `build` بتاعها:
/// `AppPlatform.isDesktop(context) ? _buildWindowsBody() : _buildMobileBody()`
class AppPlatform {
  AppPlatform._();

  /// هل النظام الحالي نظام سطح مكتب؟
  static bool get isDesktopOS {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      // أي بيئة مفيهاش dart:io (زي بعض الاختبارات) → موبايل
      return false;
    }
  }

  /// الشكل المناسب للجهاز اللي بنرسم عليه دلوقتي.
  static AppFormFactor formFactorOf(BuildContext context) =>
      isDesktopOS ? AppFormFactor.desktop : AppFormFactor.mobile;

  /// اختصار سريع: هل نرسم واجهة الويندوز؟
  static bool isDesktop(BuildContext context) =>
      formFactorOf(context) == AppFormFactor.desktop;
}
