// GENERATED FILE — rewritten by tool/release.ps1 before every build.
// Do not edit by hand.
//
/// وضع التطبيق — بيتاخد من .env (APP_MODE) وقت البناء.
///
/// online  = التحديثات من GitHub + تسجيل الأجهزة والتراخيص.
/// offline = من غير أي خدمات سحابية (مفيش تحديثات ولا تسجيل أجهزة).
class AppMode {
  AppMode._();

  static const String mode = 'online';

  static const bool isOnline = true;
  static const bool isOffline = false;
}