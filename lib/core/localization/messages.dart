// Lightweight runtime for the app's localization.
//
// The template uses a "source-as-key" scheme: the Arabic source text
// (normalized with {name} placeholders) is the lookup key.
//
//   Text('خطأ في الاتصال'.tr())
//
// * Arabic is the default language: a missing entry simply returns the key
//   itself (the readable Arabic source).
// * English values are hand-written in `lib/l10n/app_en.arb` and compiled
//   into `generated/app_messages.dart` by `dart run tool/l10n_extract.dart`.
// * `tr()` needs no BuildContext — it reads the current locale from [Str],
//   which is kept in sync by [LocaleCubit]; locale changes rebuild the
//   widget tree through MaterialApp, so widget text retranslates on switch.

import 'package:flutter/material.dart';

import 'generated/app_messages.dart';

/// Global locale + translation entry point (usable without a BuildContext).
class Str {
  Str._();

  /// Supported locales, Arabic first (default language of the template).
  static const List<Locale> supportedLocales = [Locale('ar'), Locale('en')];

  static Locale _locale = const Locale('ar');

  static Locale get locale => _locale;

  static bool get isRtl => _locale.languageCode == 'ar';

  /// Update the running locale. Called by [LocaleCubit] right when the
  /// language changes so string lookups never lag behind the UI rebuild.
  static void setLocale(Locale locale) {
    _locale = locale;
  }

  /// Picks the best matching supported locale (exact match, then language
  /// code, then the default Arabic).
  static Locale localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null || supportedLocales.isEmpty) {
      return supportedLocales.isNotEmpty ? supportedLocales.first : _locale;
    }
    for (final candidate in supportedLocales) {
      if (candidate.languageCode == locale.languageCode &&
          candidate.countryCode == locale.countryCode) {
        return candidate;
      }
    }
    for (final candidate in supportedLocales) {
      if (candidate.languageCode == locale.languageCode) {
        return candidate;
      }
    }
    return supportedLocales.first;
  }

  static Map<String, String> _dataFor(String languageCode) =>
      languageCode == 'en' ? kMessagesEn : kMessagesAr;

  /// Resolves the live currency marker used inside translated texts.
  ///
  /// The money layer installs the real resolver at startup; this default keeps
  /// strings readable before the first [Money] load.
  static String Function() _currencyResolver = () => !Str.isRtl ? 'EGP' : 'ج.م';

  /// Lets [Money] plug the configured business currency into translations
  /// without making the localization layer depend on the database.
  static void setCurrencyResolver(String Function() resolver) {
    _currencyResolver = resolver;
  }

  /// Standalone currency markers inside Arabic/English translations:
  /// "الإجمالي: {v1} ج" / "Total: {v1} EGP". The marker must be surrounded by
  /// whitespace or punctuation so words that merely contain "ج" stay intact.
  static final RegExp _currencyToken = RegExp(
    r'(\s)(?:ج|EGP)(?=\s|$|[،,;:!?)\]<>])',
  );

  /// Translates [key] into the current language; unknown keys fall back to
  /// Arabic, then to the key itself.
  static String tr(String key, [Map<String, Object?>? args]) =>
      _translate(key, args, localizeCurrency: true);

  static String _translate(
    String key,
    Map<String, Object?>? args, {
    required bool localizeCurrency,
  }) {
    final code = _locale.languageCode;
    var value = _dataFor(code)[key];
    if (value == null && code != 'ar') {
      value = kMessagesAr[key];
    }
    value ??= key;
    if (args != null && args.isNotEmpty) {
      value = applyArgs(value, args);
    }
    if (localizeCurrency) value = _withCurrency(value);
    return value;
  }

  /// Swaps hardcoded "ج"/"EGP" tokens for the configured business currency,
  /// so every invoice, report, dialog and printed document follows the symbol
  /// saved in settings immediately.
  static String _withCurrency(String value) {
    if (!value.contains('ج') && !value.contains('EGP')) return value;
    final symbol = _currencyResolver();
    return value.replaceAllMapped(
      _currencyToken,
      (match) => '${match[1]}$symbol',
    );
  }

  /// Substitutes `{name}` placeholders that have an entry in [args]. Literal
  /// braces without a matching argument are left untouched.
  static String applyArgs(String template, Map<String, Object?> args) {
    if (!template.contains('{') && !template.contains('}')) return template;
    final out = StringBuffer();
    int i = 0;
    while (i < template.length) {
      final ch = template[i];
      if (ch == '{') {
        final close = template.indexOf('}', i + 1);
        if (close > i + 1) {
          final name = template.substring(i + 1, close);
          if (args.containsKey(name)) {
            out.write(_valueText(args[name]));
            i = close + 1;
            continue;
          }
        }
      }
      out.write(ch);
      i++;
    }
    return out.toString();
  }

  static String _valueText(Object? value) {
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt().toString(); // 3.0 -> 3
    }
    return value?.toString() ?? '';
  }
}

/// Translation extension — the primary call pattern everywhere in the app.
extension StrTranslationX on String {
  /// Translate this Arabic source string into the current language.
  String tr([Map<String, Object?>? args]) => Str.tr(this, args);
}
