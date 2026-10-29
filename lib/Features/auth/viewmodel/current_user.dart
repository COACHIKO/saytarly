import 'package:saytarly/core/localization/messages.dart';
// utils/current_user.dart
class CurrentUser {
  static String? username;
  static String? role;
  static int? userId;

  static void setUser({
    required String username,
    required String role,
    required int userId,
  }) {
    CurrentUser.username = username;
    CurrentUser.role = role;
    CurrentUser.userId = userId;
  }

  static void clear() {
    username = null;
    role = null;
    userId = null;
  }

  // اسم آمن نستخدمه في أي مكان حتى لو حصل استثناء (مثلاً مفيش تسجيل دخول لأي سبب)
  static String get displayName => username ?? 'غير معروف'.tr();
}
