import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/localization/messages.dart';

/// رمز العملة — بيتحمّل مرة في أول التشغيل من إعدادات الملف التجاري،
/// وبينفع يتعاد تحميله بعد أي تعديل من شاشة الإعدادات.
///
/// الكود كله بواسطة [txt] بدل نص «ج.م» المكتوب بالكود — فالتغيير بيشتغل
/// فورًا في الشاشات والتقارير والفواتير بعد إعادة التشغيل (أو بعد [load])
/// من غير أي تعديل كود.
class Money {
  Money._();

  /// Default when the super admin has not set a custom currency symbol.
  /// Resolved at access time so it follows the current UI language.
  static String get fallback => 'ج.م'.tr();

  static String _customSymbol = '';

  /// Current symbol. A custom business symbol wins; otherwise the localized
  /// default is resolved on every read, so switching to English shows “EGP”.
  static String get symbol => _customSymbol.isEmpty ? fallback : _customSymbol;

  /// Migration alias used by older script-generated call sites.
  static String get txt => symbol;

  /// Loads the custom symbol from the business settings.
  static Future<void> load() async {
    final v = await DBHelper.getSetting(DBHelper.kCurrencySymbolKey);
    _customSymbol = (v == null || v.trim().isEmpty) ? '' : v.trim();
  }

  /// تنسيق مبلغ مع الرمز — للمواضع الجديدة بدل النصوص المكتوبة يدويًا.
  static String amount(num v) {
    final double d = v.toDouble();
    final isWhole = (d - d.roundToDouble()).abs() < 0.005;
    return '${d.toStringAsFixed(isWhole ? 0 : 2)} $symbol';
  }
}
