// Template tests for the hand-rolled localization runtime.
//
// The app uses a "source-as-key" scheme: Arabic source text (with {name}
// placeholders) is the lookup key; English values live in lib/l10n/app_en.arb
// and are compiled into generated/app_messages.dart by
// `dart run tool/l10n_extract.dart`. These tests exercise the runtime without
// building the full app widget tree (main() runs DB migrations and an
// activation gate, which is out of scope for unit tests).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/localization/messages.dart';

void main() {
  group('Str', () {
    test('defaults to Arabic first in supportedLocales', () {
      expect(Str.supportedLocales.first.languageCode, 'ar');
    });

    test('Arabic locale returns the Arabic source as-is', () {
      Str.setLocale(const Locale('ar'));
      expect('نظام إدارة الكافيه'.tr(), 'نظام إدارة الكافيه');
    });

    test('unknown keys fall back to themselves', () {
      Str.setLocale(const Locale('ar'));
      const unknown = 'مفتاح غير موجود نهائيًا';
      expect(unknown.tr(), unknown);
    });

    test('English locale translates known keys', () {
      Str.setLocale(const Locale('en'));
      expect('وضع الكاشير'.tr(), 'Cashier mode');
      Str.setLocale(const Locale('ar'));
      expect('وضع الكاشير'.tr(), 'وضع الكاشير');
    });

    test('English translation falls back to Arabic text for missing entries',
        () {
      Str.setLocale(const Locale('en'));
      // Keys that are intentionally untranslated (SQL/HTML fragments) keep
      // their Arabic source in English, matching the fallback design.
      expect("WHERE payment_type != 'ملغي'".tr(),
          "WHERE payment_type != 'ملغي'");
      Str.setLocale(const Locale('ar'));
    });

    test('tr() substitutes named placeholders', () {
      Str.setLocale(const Locale('en'));
      expect(' ({v1} عملية)'.tr({'v1': 3}), '(3 transactions)');
      expect(
        '{dayName}، {v2} {monthName} {v4} - {hour}:{minute} {ampm}'
            .tr({'dayName': 'Sun'}),
        'Sun, {v2} {monthName} {v4} - {hour}:{minute} {ampm}',
      );
      Str.setLocale(const Locale('ar'));
    });

    test('localeResolutionCallback picks exact, then language, then default',
        () {
      expect(
        Str.localeResolutionCallback(
            const Locale('en'), Str.supportedLocales),
        const Locale('en'),
      );
      expect(
        Str.localeResolutionCallback(
            const Locale('en', 'GB'), Str.supportedLocales),
        const Locale('en'),
      );
      expect(
        Str.localeResolutionCallback(
            const Locale('fr'), Str.supportedLocales),
        const Locale('ar'),
      );
    });
  });
}
