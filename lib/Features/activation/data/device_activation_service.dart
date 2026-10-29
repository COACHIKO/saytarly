// lib/services/device_activation_service.dart
//
// المسؤول عن: تسجيل طلب تفعيل جديد، التحقق من الحالة (approved/pending/...)
// أونلاين من Supabase، والرجوع لكاش محلي (SQLite) لو مفيش نت — لفترة سماح محددة.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart';

enum ActivationStatus {
  approved, // مفعّل، شغّل البرنامج عادي
  offlineGrace, // مفعّل بس مفيش نت من فترة، لسه في فترة السماح
  pending, // في انتظار موافقة المهندس
  blocked, // مرفوض / تم إلغاء التفعيل / انتهت فترة السماح بدون نت
}

class DeviceActivationService {
  /// عدد الأيام اللي ممكن يشتغل فيها البرنامج أوفلاين بعد آخر تأكيد "approved"
  static const int graceDays = 5;

  /// أيام سماح إضافية (بعد الـ grace) لو لسه مفيش نت، بعدها يقفل لحد ما يتأكد أونلاين
  static const int hardOfflineLimitDays = 10;

  static Future<ActivationStatus> checkStatus() async {
    final hash = await DeviceFingerprint.deviceId();

    try {
      final supa = Supabase.instance.client;

      final rows = await supa
          .from('device_activations')
          .select()
          .eq('device_hash', hash)
          .limit(1);

      if (rows.isEmpty) {
        // أول مرة الجهاز ده يحاول يفتح البرنامج -> سجل طلب pending
        await supa.from('device_activations').insert({
          'device_hash': hash,
          'status': 'pending',
        });
        await _cache(hash, 'pending');
        return ActivationStatus.pending;
      }

      final status = rows.first['status'] as String;
      final licenseType = (rows.first['license_type'] as String?) ?? 'lifetime';
      final expiresAtStr = rows.first['expires_at'] as String?;
      final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

      // لو الترخيص ديمو وانتهت مدته -> حظر فوري
      if (status == 'approved' && licenseType == 'demo' && expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        await _cache(hash, 'blocked', licenseType: licenseType, expiresAt: expiresAtStr);
        return ActivationStatus.blocked;
      }

      await _cache(hash, status, licenseType: licenseType, expiresAt: expiresAtStr);

      switch (status) {
        case 'approved':
          return ActivationStatus.approved;
        case 'pending':
          return ActivationStatus.pending;
        default: // rejected / revoked
          return ActivationStatus.blocked;
      }
    } catch (_) {
      // مفيش نت أو Supabase مش متاح -> نرجع لآخر حالة متخزنة محليًا
      return await _checkOfflineCache(hash);
    }
  }

  static Future<void> _cache(
    String hash,
    String status, {
    String licenseType = 'lifetime',
    String? expiresAt,
  }) async {
    try {
      final db = await DBHelper.database;
      await db.delete(
        'remote_activation',
        where: 'device_hash = ?',
        whereArgs: [hash],
      );
      await db.insert('remote_activation', {
        'device_hash': hash,
        'status': status,
        'license_type': licenseType,
        'expires_at': expiresAt,
        'last_checked_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // لو فشل الكاش المحلي مش نهاية العالم، هيحاول أونلاين تاني بعدين
    }
  }

  static Future<ActivationStatus> _checkOfflineCache(String hash) async {
    try {
      final db = await DBHelper.database;
      final rows = await db.query(
        'remote_activation',
        where: 'device_hash = ?',
        whereArgs: [hash],
        limit: 1,
      );

      if (rows.isEmpty) return ActivationStatus.blocked; // لازم نت أول مرة

      final row = rows.first;
      if (row['status'] != 'approved') return ActivationStatus.blocked;

      final licenseType = (row['license_type'] as String?) ?? 'lifetime';
      final expiresAtStr = row['expires_at'] as String?;
      final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

      // في فترة الديمو التجريبية: لازم نت دائم عشان صاحب السيستم يقدر يقفل عليه في أي وقت
      // ولا يتم التلاعب بالوقت أو فصل النت لتخطي المدة التجريبية
      if (licenseType == 'demo') {
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          return ActivationStatus.blocked;
        }
        // نسخة تجريبية بدون نت -> تقفل حتى يتم الاتصال بالإنترنت
        return ActivationStatus.blocked;
      }

      // إذا كان ترخيص شراء دائم (lifetime):
      final lastChecked = DateTime.tryParse(
        row['last_checked_at'] as String? ?? '',
      );
      if (lastChecked == null) return ActivationStatus.blocked;

      final daysSince = DateTime.now().difference(lastChecked).inDays;

      if (daysSince <= graceDays) {
        return ActivationStatus.approved;
      } else if (daysSince <= hardOfflineLimitDays) {
        return ActivationStatus.offlineGrace;
      } else {
        return ActivationStatus.blocked;
      }
    } catch (_) {
      return ActivationStatus.blocked;
    }
  }

  // ===== دوال الأدمن (تحتاج تسجيل دخول Authenticated بسبب RLS) =====

  static Future<void> approveDevice(
    String deviceHash, {
    String licenseType = 'lifetime',
    DateTime? expiresAt,
  }) async {
    final supa = Supabase.instance.client;
    final Map<String, dynamic> updateData = {
      'status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
      'license_type': licenseType,
      'expires_at': expiresAt?.toIso8601String(),
    };
    await supa
        .from('device_activations')
        .update(updateData)
        .eq('device_hash', deviceHash);
  }

  static Future<void> rejectDevice(String deviceHash) async {
    final supa = Supabase.instance.client;
    await supa
        .from('device_activations')
        .update({'status': 'rejected'})
        .eq('device_hash', deviceHash);
  }

  static Future<void> revokeDevice(String deviceHash) async {
    final supa = Supabase.instance.client;
    await supa
        .from('device_activations')
        .update({'status': 'revoked'})
        .eq('device_hash', deviceHash);
  }

  /// حظر جهاز بالكود مباشرة حتى لو لسه ما بعتش أي طلب تفعيل
  /// (مفيد لو عايز تمنع جهاز معين مسبقًا).
  static Future<void> blockDeviceByHash(String deviceHash) async {
    final supa = Supabase.instance.client;
    final hash = deviceHash.trim();
    if (hash.isEmpty) return;

    final existing = await supa
        .from('device_activations')
        .select()
        .eq('device_hash', hash)
        .limit(1);

    if (existing.isEmpty) {
      await supa.from('device_activations').insert({
        'device_hash': hash,
        'status': 'revoked',
      });
    } else {
      await supa
          .from('device_activations')
          .update({'status': 'revoked'})
          .eq('device_hash', hash);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllRequests() async {
    final supa = Supabase.instance.client;
    final rows = await supa
        .from('device_activations')
        .select()
        .order('requested_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
