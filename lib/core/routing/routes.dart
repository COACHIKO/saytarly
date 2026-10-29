/// Route names shared between the router and feature screens.
///
/// Feature apps define their screens here following the `/<name>` pattern.
class Routes {
  static const String splash = '/';
  static const String activation = '/activation';
  static const String login = '/login';
  static const String home = '/home';
  static const String qrMenu = '/qrMenu';

  /// لوحة الأدمن — شاشة الدخول بتوجّه لها بالاسم (pushReplacementNamed)
  /// بعد نجاح تسجيل الدخول بدور admin.
  static const String admin = '/admin';
}
