// lib/server/license_manager.dart
//
// نظام ترخيص محلي بالكامل — بدون Supabase.
//
// الفكرة:
//   • البرنامج يعرض "كود الجهاز" (Device Hash).
//   • المهندس يدخل هذا الكود في صفحة الجنيريتور، يختار المدة،
//     وينتج "كود التفعيل" (activation code).
//   • العميل يكتب كود التفعيل في البرنامج — يتم التحقق محلياً 100%.
//
// هيكل كود التفعيل (20 رمز):
//   [4 رمز مدة] [12 رمز HMAC] [4 رمز مجموع تحقق]
//   عرض للمستخدم: XXXX-XXXX-XXXX-XXXX-XXXX (مع شرطات)
//
// مثال: A1B2-3C4D-5E6F-7A8B-C9D0

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/localization/messages.dart';

// =================== SECRET KEY ===================
// غيّرها لحاجة سرية خاصة بيك — لا تشاركها مع حد
const String _kSecret = 'CafeHamzaXO@2025!EngWaled#Secret';
// ==================================================

// تاريخ مرجعي ثابت (1 يناير 2025)
final DateTime _kEpoch = DateTime(2025, 1, 1);

// أيام خاصة بـ "دائم مدى الحياة"
const int _kLifetimeDays = 36500; // ~100 سنة

enum LicenseStatus {
  active,   // مفعّل وسارٍ
  expired,  // منتهي — يطلب كود تجديد
  none,     // ما فيش كود أصلاً
  invalid,  // الكود مش صح
}

class LicenseInfo {
  final LicenseStatus status;
  final DateTime? expiresAt;
  final bool isLifetime;

  const LicenseInfo({
    required this.status,
    this.expiresAt,
    this.isLifetime = false,
  });
}

class LicenseManager {
  // ──────────────────────────────────────────────────────────
  // 1. توليد كود التفعيل (يستخدمه المهندس فقط)
  // ──────────────────────────────────────────────────────────

  /// [deviceId] : الهاش الخاص بالجهاز (كما يظهر على شاشة التفعيل)
  /// [days]     : مدة الصلاحية بالأيام (استخدم [_kLifetimeDays] للدائم)
  static String generateCode(String deviceId, int days) {
    // مدة بالأيام من الـ epoch (4 hex digits → max 65535 يوم ≈ 179 سنة)
    final expiryDays = days.clamp(1, 65535);
    final expiryHex =
        expiryDays.toRadixString(16).padLeft(4, '0').toUpperCase();

    // HMAC-SHA256(secret, deviceId + "|" + expiryHex)
    final msg = '$deviceId|$expiryHex';
    final hmac = Hmac(sha256, utf8.encode(_kSecret));
    final digest = hmac.convert(utf8.encode(msg)).toString().toUpperCase();

    // نأخذ أول 12 رمز من الـ HMAC كـ signature
    final sig = digest.substring(0, 12);

    // مجموع تحقق بسيط (4 رمز آخرين من الـ HMAC)
    final check = digest.substring(12, 16);

    // نجمع الـ 20 رمز ونضيف شرطات كل 4
    final raw = expiryHex + sig + check; // 4+12+4 = 20
    return _insertDashes(raw); // XXXX-XXXX-XXXX-XXXX-XXXX
  }

  /// وسيلة مساعدة: كود للدائم مدى الحياة
  static String generateLifetimeCode(String deviceId) =>
      generateCode(deviceId, _kLifetimeDays);

  // ──────────────────────────────────────────────────────────
  // 2. التحقق من كود التفعيل
  // ──────────────────────────────────────────────────────────

  /// [deviceId] : الهاش الخاص بالجهاز الحالي
  /// [code]     : الكود الذي أدخله العميل (مع أو بدون شرطات)
  static LicenseInfo verifyCode(String deviceId, String code) {
    final raw = code.replaceAll('-', '').trim().toUpperCase();

    if (raw.length != 20) {
      return const LicenseInfo(status: LicenseStatus.invalid);
    }

    final expiryHex = raw.substring(0, 4);
    final sig = raw.substring(4, 16);
    final check = raw.substring(16, 20);

    // تحقق من مجموع التحقق
    final msg = '$deviceId|$expiryHex';
    final hmac = Hmac(sha256, utf8.encode(_kSecret));
    final digest = hmac.convert(utf8.encode(msg)).toString().toUpperCase();
    final expectedSig = digest.substring(0, 12);
    final expectedCheck = digest.substring(12, 16);

    if (sig != expectedSig || check != expectedCheck) {
      return const LicenseInfo(status: LicenseStatus.invalid);
    }

    // احسب تاريخ الانتهاء
    final expiryDays = int.tryParse(expiryHex, radix: 16) ?? 0;
    final expiresAt = _kEpoch.add(Duration(days: expiryDays));
    final isLifetime = expiryDays >= _kLifetimeDays;

    if (!isLifetime && DateTime.now().isAfter(expiresAt)) {
      return LicenseInfo(
        status: LicenseStatus.expired,
        expiresAt: expiresAt,
        isLifetime: false,
      );
    }

    return LicenseInfo(
      status: LicenseStatus.active,
      expiresAt: expiresAt,
      isLifetime: isLifetime,
    );
  }

  // ──────────────────────────────────────────────────────────
  // 3. حفظ وقراءة الرخصة من SQLite المحلي
  // ──────────────────────────────────────────────────────────

  /// يحفظ كود التفعيل في قاعدة البيانات المحلية
  static Future<void> saveLicense(String deviceId, String code) async {
    final info = verifyCode(deviceId, code);
    if (info.status == LicenseStatus.invalid) return;

    final db = await DBHelper.database;
    await db.delete('remote_activation', where: 'device_hash = ?', whereArgs: [deviceId]);
    await db.insert('remote_activation', {
      'device_hash': deviceId,
      'status': info.status == LicenseStatus.active ? 'approved' : 'expired',
      'license_type': info.isLifetime ? 'lifetime' : 'demo',
      'expires_at': info.expiresAt?.toIso8601String(),
      'activation_code': code.replaceAll('-', '').toUpperCase(),
      'last_checked_at': DateTime.now().toIso8601String(),
    });
  }

  /// يقرأ حالة الرخصة من SQLite ويعيد التحقق منها
  static Future<LicenseInfo> loadAndCheckLicense(String deviceId) async {
    try {
      final db = await DBHelper.database;
      final rows = await db.query(
        'remote_activation',
        where: 'device_hash = ?',
        whereArgs: [deviceId],
        limit: 1,
      );

      if (rows.isEmpty) return const LicenseInfo(status: LicenseStatus.none);

      final row = rows.first;
      final savedCode = row['activation_code'] as String?;
      if (savedCode == null || savedCode.isEmpty) {
        return const LicenseInfo(status: LicenseStatus.none);
      }

      // أعد التحقق من الكود مع device ID الحالي (لحماية من نسخ الـ DB)
      return verifyCode(deviceId, savedCode);
    } catch (_) {
      return const LicenseInfo(status: LicenseStatus.none);
    }
  }

  /// يمسح الرخصة (عند تغيير الجهاز مثلاً)
  static Future<void> clearLicense(String deviceId) async {
    final db = await DBHelper.database;
    await db.delete('remote_activation', where: 'device_hash = ?', whereArgs: [deviceId]);
  }

  // ──────────────────────────────────────────────────────────
  // 4. مساعدات
  // ──────────────────────────────────────────────────────────

  static String _insertDashes(String raw) {
    // XXXX-XXXX-XXXX-XXXX-XXXX (20 رمز, 4 شرطات)
    return '${raw.substring(0, 4)}-${raw.substring(4, 8)}-'
        '${raw.substring(8, 12)}-${raw.substring(12, 16)}-'
        '${raw.substring(16, 20)}';
  }

  /// تنسيق يعرض المدة المتبقية بشكل مفهوم
  static String formatRemaining(DateTime expiresAt, {bool isLifetime = false}) {
    if (isLifetime) return 'دائم مدى الحياة'.tr();
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inDays > 0) return 'متبقي {v1} يوم'.tr({'v1': remaining.inDays});
    if (remaining.inHours > 0) return 'متبقي {v1} ساعة'.tr({'v1': remaining.inHours});
    return 'منتهي'.tr();
  }
}
