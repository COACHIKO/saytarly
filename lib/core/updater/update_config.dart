// GENERATED FILE — rewritten by tool/release.ps1 before every build.
// Do not edit by hand.
//
/// إعدادات الاتصال بريبو التحديثات على GitHub.
///
/// القيم بتتاخد من ملف .env وقت البناء (RELEASES_REPO و RELEASES_TOKEN).
class UpdateConfig {
  UpdateConfig._();

  /// المستودع بصيغة owner/repo.
  static const String repo = 'COACHIKO/saytarly_releases';

  /// Personal Access Token للوصول للريبو الخاص.
  /// ⚠️ القيمة الحقيقية بتتكتب هنا وقت البناء من `.env` (tool/release.ps1)
  /// — ملف .env مش بيتدفع على Git عشان التوكن ما يتسربش.
  static const String token = '';

  /// اسم ملف الـ zip اللي بيستخدمه التحديث الذاتي على ويندوز.
  static const String windowsAssetName = 'saytarly_windows';
}