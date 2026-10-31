import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/Features/auth/presentation/screens/login.dart';
import 'package:saytarly/core/localization/messages.dart';

/// 🚪 تسجيل الخروج المشترك — من أي دور (كاشير / أدمن / سوبر أدمن):
/// دايلوج تأكيد ثم خروج كامل لشاشة اللوجين مع تصفير الستاك كله.
///
/// الشيفت المفتوح يفضل فاتح باسم صاحبه — الكاشير يرجع بنفس حسابه
/// بيكمل شيفته فورًا، ودخول كاشير تاني محجوز لحد ما شيفت القديم يقفل
/// أو يتسلم (تسليم الشيفت) — أما الأدمن والسوبر أدمن بيدخلوا عادي.
class LogoutHelper {
  LogoutHelper._();

  /// [openShiftNote] — تحذير اختياري يظهر للمستخدم اللي عليه شيفت مفتوح.
  static Future<void> confirmAndLogout(
    BuildContext context, {
    String? openShiftNote,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlg) => AppDialog(
        title:  Text('🚪 تسجيل خروج'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('هترجع لشاشة تسجيل الدخول.'.tr()),
            if (openShiftNote != null) ...[
              const SizedBox(height: 8),
              Text(
                openShiftNote,
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlg, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlg, true),
            child:  Text('تسجيل خروج'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (context.mounted) {
      // Root navigator: a page inside the desktop shell must leave the whole
      // workspace when logging out, not only the nested content navigator.
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }
}
