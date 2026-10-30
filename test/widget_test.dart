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
import 'package:saytarly/core/models/app_modules.dart';
import 'package:saytarly/core/models/models.dart';

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

    test(
      'English translation falls back to Arabic text for missing entries',
      () {
        Str.setLocale(const Locale('en'));
        // Keys that are intentionally untranslated (SQL/HTML fragments) keep
        // their Arabic source in English, matching the fallback design.
        expect(
          "WHERE payment_type != 'ملغي'".tr(),
          "WHERE payment_type != 'ملغي'",
        );
        Str.setLocale(const Locale('ar'));
      },
    );

    test('tr() substitutes named placeholders', () {
      Str.setLocale(const Locale('en'));
      expect(' ({v1} عملية)'.tr({'v1': 3}), '(3 transactions)');
      expect(
        '{dayName}، {v2} {monthName} {v4} - {hour}:{minute} {ampm}'.tr({
          'dayName': 'Sun',
        }),
        'Sun, {v2} {monthName} {v4} - {hour}:{minute} {ampm}',
      );
      Str.setLocale(const Locale('ar'));
    });

    test(
      'localeResolutionCallback picks exact, then language, then default',
      () {
        expect(
          Str.localeResolutionCallback(
            const Locale('en'),
            Str.supportedLocales,
          ),
          const Locale('en'),
        );
        expect(
          Str.localeResolutionCallback(
            const Locale('en', 'GB'),
            Str.supportedLocales,
          ),
          const Locale('en'),
        );
        expect(
          Str.localeResolutionCallback(
            const Locale('fr'),
            Str.supportedLocales,
          ),
          const Locale('ar'),
        );
      },
    );
  });

  group('AppModule bilingual names', () {
    setUp(() => Str.setLocale(const Locale('ar')));
    tearDown(() => Str.setLocale(const Locale('ar')));

    test('uses the Arabic name in Arabic and falls back to English', () {
      final module = AppModule(name: 'مشروبات', nameEn: 'Drinks');
      expect(module.displayName, 'مشروبات');

      Str.setLocale(const Locale('en'));
      expect(module.displayName, 'Drinks');
    });

    test('falls back to the only available name in either language', () {
      final englishOnly = AppModule(name: '', nameEn: 'Drinks');
      expect(englishOnly.displayName, 'Drinks');

      Str.setLocale(const Locale('en'));
      expect(englishOnly.displayName, 'Drinks');

      final arabicOnly = AppModule(name: 'حلويات', nameEn: '');
      expect(arabicOnly.displayName, 'حلويات');
    });

    test('raw map helper follows the same fallback rules', () {
      final row = {'name': '', 'name_en': 'Desserts'};
      expect(AppModule.displayNameFromMap(row), 'Desserts');

      Str.setLocale(const Locale('en'));
      expect(AppModule.displayNameFromMap(row), 'Desserts');
    });
  });

  group('AppModuleCategory bilingual names', () {
    setUp(() => Str.setLocale(const Locale('ar')));
    tearDown(() => Str.setLocale(const Locale('ar')));

    test('uses the Arabic name in Arabic and English in English', () {
      final category = AppModuleCategory(
        moduleId: 1,
        name: 'شاي',
        nameEn: 'Tea',
        key: 'tea',
      );
      expect(category.displayName, 'شاي');

      Str.setLocale(const Locale('en'));
      expect(category.displayName, 'Tea');
    });

    test('falls back to the only available submenu name', () {
      final englishOnly = AppModuleCategory(
        moduleId: 1,
        name: '',
        nameEn: 'Tea',
        key: 'tea',
      );
      expect(englishOnly.displayName, 'Tea');

      Str.setLocale(const Locale('en'));
      expect(englishOnly.displayName, 'Tea');

      final arabicOnly = AppModuleCategory(
        moduleId: 1,
        name: 'قهوة',
        nameEn: '',
        key: 'coffee',
      );
      expect(arabicOnly.displayName, 'قهوة');
    });

    test('raw map helper follows the same submenu fallback rules', () {
      final row = {'name': '', 'name_en': 'Tea'};
      expect(AppModuleCategory.displayNameFromMap(row), 'Tea');

      Str.setLocale(const Locale('en'));
      expect(AppModuleCategory.displayNameFromMap(row), 'Tea');
    });
  });

  group('DrinkModel bilingual names', () {
    setUp(() => Str.setLocale(const Locale('ar')));
    tearDown(() => Str.setLocale(const Locale('ar')));

    test('uses the Arabic product name in Arabic and English in English', () {
      final drink = DrinkModel(name: 'شاي', nameEn: 'Tea', price: 20);
      expect(drink.displayName, 'شاي');
      expect(drink.matchesQuery('شا'), isTrue);

      Str.setLocale(const Locale('en'));
      expect(drink.displayName, 'Tea');
      expect(drink.matchesQuery('te'), isTrue);
    });

    test('falls back to the only available product name', () {
      final englishOnly = DrinkModel(name: '', nameEn: 'Tea', price: 20);
      expect(englishOnly.displayName, 'Tea');

      Str.setLocale(const Locale('en'));
      expect(englishOnly.displayName, 'Tea');

      final arabicOnly = DrinkModel(name: 'قهوة', price: 15);
      expect(arabicOnly.displayName, 'قهوة');
    });

    test('raw map helper follows the same product fallback rules', () {
      final row = {'name': '', 'name_en': 'Tea'};
      expect(DrinkModel.displayNameFromMap(row), 'Tea');

      Str.setLocale(const Locale('en'));
      expect(DrinkModel.displayNameFromMap(row), 'Tea');
    });
  });
}
