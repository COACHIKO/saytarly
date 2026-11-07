import 'package:flutter/foundation.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/localization/messages.dart';

/// رمز العملة — بيتحمّل مرة في أول التشغيل من إعدادات الملف التجاري،
/// وبيتحدّث فورًا بعد أي تعديل من الإعدادات أو معالج التهيئة.
///
/// الكود كله بواسطة [txt] بدل نص «ج.م» المكتوب بالكود — فالتغيير بيشتغل
/// فورًا في الشاشات والتقارير والفواتير من غير إعادة تشغيل.
class Money {
  Money._();

  /// Default when the super admin has not set a custom currency symbol.
  /// Resolved at access time so it follows the current UI language.
  /// (The Arabic literal sits in the ternary's else branch so the l10n
  /// extractor never wraps it with `.tr()` — that would recurse into [symbol].)
  static String get fallback => !Str.isRtl ? 'EGP' : 'ج.م';

  static String _customSymbol = '';

  /// بيتغيّر كل ما رمز العملة يتحدّث — الشاشات المفتوحة بتسمع عليه
  /// وبتعيد رسم نفسها فورًا.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// بيسجّل مزوّد العملة في طبقة الترجمة عشان أي نص فيه «ج» أو «EGP»
  /// يتعرض بالرمز الحالي تلقائيًا. النداء آمن ومتكرر.
  static void _installResolver() {
    Str.setCurrencyResolver(() => Money.symbol);
  }

  /// Current symbol. A custom business symbol wins; otherwise the localized
  /// default is resolved on every read, so switching to English shows “EGP”.
  static String get symbol => _customSymbol.isEmpty ? fallback : _customSymbol;

  /// Migration alias used by older script-generated call sites.
  static String get txt => symbol;

  /// Loads the custom symbol from the business settings.
  static Future<void> load() async {
    _installResolver();
    final v = await DBHelper.getSetting(DBHelper.kCurrencySymbolKey);
    setCustomSymbol(v ?? '');
  }

  /// Updates the in-memory symbol immediately (after saving the setting) and
  /// notifies every listener so open screens refresh without a restart.
  static void setCustomSymbol(String value) {
    _installResolver();
    final next = value.trim();
    if (next == _customSymbol) return;
    _customSymbol = next;
    changes.value++;
  }

  /// تنسيق مبلغ مع الرمز — للمواضع الجديدة بدل النصوص المكتوبة يدويًا.
  static String amount(num v) {
    final double d = v.toDouble();
    final isWhole = (d - d.roundToDouble()).abs() < 0.005;
    return '${d.toStringAsFixed(isWhole ? 0 : 2)} $symbol';
  }
}
