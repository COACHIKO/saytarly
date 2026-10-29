import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات عامة للتطبيق بتتخزن محليًا وتفضل بعد إعادة التشغيل
class AppSettings {
  static const String _keyDrinksScreenPosMode = 'drinks_screen_pos_mode';

  /// يرجع true لو الوضع الافتراضي "كاشير"، false لو "قائمة"
  /// لو مفيش قيمة محفوظة، بيرجع false (قائمة) كافتراضي
  static Future<bool> getDrinksScreenPosMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDrinksScreenPosMode) ?? false;
  }

  static const String _kCigarettesEnabled = 'cigarettes_enabled';
  static const String _kShishaEnabled = 'shisha_enabled';
  static const String _kShishaCigarettesEnabled = 'shisha_cigarettes_enabled';

  /// إعداد إظهار السجائر
  static Future<bool> getCigarettesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCigarettesEnabled) ?? false;
  }

  static Future<void> setCigarettesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCigarettesEnabled, value);
  }

  /// إعداد إظهار الشيشة
  static Future<bool> getShishaEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShishaEnabled) ?? false;
  }

  static Future<void> setShishaEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShishaEnabled, value);
  }

  /// للتوافق مع الكود القديم: يرجع true لو أي من السجائر أو الشيشة مفعلة
  static Future<bool> getShishaCigarettesEnabled() async {
    final cig = await getCigarettesEnabled();
    final shisha = await getShishaEnabled();
    return cig || shisha;
  }

  static Future<void> setShishaCigarettesEnabled(bool value) async {
    await setCigarettesEnabled(value);
    await setShishaEnabled(value);
  }

  /// يحفظ اختيار الأدمن للوضع الافتراضي
  static Future<void> setDrinksScreenPosMode(bool isPosMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDrinksScreenPosMode, isPosMode);
  } // 📌 ضيف الدوال دي جوه كلاس AppSettings الموجود عندك في app_settings.dart
  // (نفس أسلوب getDrinksScreenPosMode / setDrinksScreenPosMode بالظبط)

  // ---- شكل لوحة الأدمن ----
  static const _kAdminDashStyle = 'admin_dash_style';

  static Future<String> getAdminDashStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAdminDashStyle) ?? 'current';
  }

  static Future<void> setAdminDashStyle(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAdminDashStyle, value);
  }

  // ---- شكل تقرير الشيفتات ----
  static const _kShiftsReportDesign = 'shifts_report_design';

  static Future<String> getShiftsReportDesign() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShiftsReportDesign) ?? 'classic';
  }

  static Future<void> setShiftsReportDesign(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShiftsReportDesign, value);
  }
}
