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

  /// الافتراضي لو السوبر ادمن ما حددش رمز عملة.
  static String get fallback => 'ج.م'.tr();

  /// الرمز الحالي المستخدم في التطبيق.
  static String symbol = fallback;

  /// وسيط ترحيل — بنفس الاسم اللي بيستخدمه سكريبت الترحيل `${Money.txt}`.
  static String get txt => symbol;

  /// تحميل الرمز من قاعدة البيانات — بيتنادى في main() وبعد الحفظ من الإعدادات.
  static Future<void> load() async {
    final v = await DBHelper.getSetting(DBHelper.kCurrencySymbolKey);
    symbol = (v == null || v.trim().isEmpty) ? fallback : v.trim();
  }

  /// تنسيق مبلغ مع الرمز — للمواضع الجديدة بدل النصوص المكتوبة يدويًا.
  static String amount(num v) {
    final double d = v.toDouble();
    final isWhole = (d - d.roundToDouble()).abs() < 0.005;
    return '${d.toStringAsFixed(isWhole ? 0 : 2)} $symbol';
  }
}
