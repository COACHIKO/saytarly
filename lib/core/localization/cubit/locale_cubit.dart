import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../language_cache_helper.dart';
import '../messages.dart';
part 'locale_state.dart';

/// Manages the app locale. Persists the selection so cold starts restore it.
class LocaleCubit extends Cubit<ChangeLocaleState> {
  LocaleCubit() : super(ChangeLocaleState(locale: const Locale(defaultLanguageCode)));

  /// Default language of the core app: Arabic (the primary RTL audience).
  static const String defaultLanguageCode = 'ar';

  Future<void> getSavedLanguage() async {
    final String cachedLanguageCode =
        await LanguageCacheHelper().getCachedLanguageCode();
    Str.setLocale(Locale(cachedLanguageCode));
    emit(ChangeLocaleState(locale: Locale(cachedLanguageCode)));
  }

  Future<void> changeLanguage(String languageCode) async {
    Str.setLocale(Locale(languageCode));
    await LanguageCacheHelper().cacheLanguageCode(languageCode);
    emit(ChangeLocaleState(locale: Locale(languageCode)));
  }
}
