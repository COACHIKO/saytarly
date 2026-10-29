import 'package:shared_preferences/shared_preferences.dart';

/// Persists the selected language code so cold starts restore the locale.
class LanguageCacheHelper {
  static const String _key = 'LOCALE';

  Future<void> cacheLanguageCode(String languageCode) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(_key, languageCode);
  }

  Future<String> getCachedLanguageCode() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(_key) ?? 'ar';
  }
}
