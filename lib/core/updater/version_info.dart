// GENERATED FILE — rewritten by tool/release.ps1 before every build.
// Do not edit by hand.
//
/// نسخة التطبيق الحالية اللي بتتظبط من .env وقت البناء.
class VersionInfo {
  VersionInfo._();

  /// نسخة الموبايل (Android) — بتتقارن بـ tags اللي بتبدأ بـ mobile-.
  static const String mobileVersion = '1.0.0';

  /// رقم بناء الموبايل (= Android versionCode).
  static const int mobileBuildNumber = 1;

  /// نسخة الويندوز (4 أجزاء) — بتتقارن بـ tags اللي بتبدأ بـ windows-.
  static const String windowsVersion = '1.0.0.0';

  /// رقم بناء الويندوز (بيستخدم كرابع جزء في خصائص الملف).
  static const int windowsBuildNumber = 1;
}