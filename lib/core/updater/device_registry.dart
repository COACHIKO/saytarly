import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:saytarly/core/updater/app_mode.dart';
import 'package:saytarly/core/updater/github_releases_api.dart';
import 'package:saytarly/core/updater/update_config.dart';
import 'package:saytarly/core/updater/version_info.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart';
import 'package:saytarly/core/utils/app_log.dart';

/// أنواع الترخيص المدعومة.
enum DeviceLicenseType {
  days('days'),
  months('months'),
  years('years'),
  unlimited('unlimited');

  const DeviceLicenseType(this.value);
  final String value;

  static DeviceLicenseType fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return DeviceLicenseType.days;
  }
}

/// حالة ترخيص الجهاز.
enum DeviceLicenseStatus { unlimited, active, expired, pending, blocked }

/// ترخيص جهاز واحد.
class DeviceLicense {
  DeviceLicense({
    required this.type,
    this.value = 0,
    this.issuedAt,
    this.expiresAt,
  });

  final DeviceLicenseType type;
  final int value;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  factory DeviceLicense.fromJson(Map<String, dynamic> json) {
    final issued =
        json['issuedAt'] is String
            ? DateTime.tryParse(json['issuedAt'] as String)
            : null;
    final expires =
        json['expiresAt'] is String
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null;
    return DeviceLicense(
      type: DeviceLicenseType.fromValue((json['type'] ?? '').toString()),
      value: (json['value'] as num?)?.toInt() ?? 0,
      issuedAt: issued,
      expiresAt: expires,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.value,
    'value': value,
    if (issuedAt != null) 'issuedAt': issuedAt!.toUtc().toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
  };

  /// تقييم حالة الترخيص في وقت معين.
  DeviceLicenseStatus statusAt(DateTime now) {
    if (type == DeviceLicenseType.unlimited) {
      return DeviceLicenseStatus.unlimited;
    }
    final expires = expiresAt;
    if (expires == null) return DeviceLicenseStatus.pending;
    return now.isBefore(expires.toUtc())
        ? DeviceLicenseStatus.active
        : DeviceLicenseStatus.expired;
  }

  /// حساب تاريخ الانتهاء من النوع والقيمة (للاستخدام في الإدارة).
  /// بيرجع UTC دايمًا عشان يتوافق مع صيغة الـ JSON.
  DateTime? computeExpiry(DateTime from) {
    final base = from.toUtc();
    switch (type) {
      case DeviceLicenseType.days:
        return base.add(Duration(days: value));
      case DeviceLicenseType.months:
        return DateTime.utc(
          base.year,
          base.month + value,
          base.day,
          base.hour,
          base.minute,
          base.second,
          base.millisecond,
          base.microsecond,
        );
      case DeviceLicenseType.years:
        return DateTime.utc(
          base.year + value,
          base.month,
          base.day,
          base.hour,
          base.minute,
          base.second,
          base.millisecond,
          base.microsecond,
        );
      case DeviceLicenseType.unlimited:
        return null;
    }
  }
}

/// ملف بيانات جهاز واحد في الريبو — كل جهاز ليه ملف خاص بيه:
/// `devices/<deviceCode>.json`
class DeviceRecord {
  DeviceRecord({
    required this.deviceCode,
    required this.pcName,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.license,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.blocked = false,
  });

  final String deviceCode;
  String pcName;
  final String platform;
  String appVersion;
  int buildNumber;
  DeviceLicense license;
  final DateTime firstSeenAt;
  DateTime lastSeenAt;

  /// الجهاز محظور من الإدارة — التطبيق مقفول عليه مهما كان الترخيص.
  bool blocked;

  factory DeviceRecord.fromJson(Map<String, dynamic> json) {
    return DeviceRecord(
      deviceCode: (json['deviceCode'] ?? '').toString(),
      pcName: (json['pcName'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      appVersion: (json['appVersion'] ?? '').toString(),
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 0,
      license: DeviceLicense.fromJson(
        Map<String, dynamic>.from(json['license'] as Map? ?? const {}),
      ),
      firstSeenAt:
          DateTime.tryParse((json['firstSeenAt'] ?? '').toString()) ??
          DateTime.now().toUtc(),
      lastSeenAt:
          DateTime.tryParse((json['lastSeenAt'] ?? '').toString()) ??
          DateTime.now().toUtc(),
      blocked: json['blocked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceCode': deviceCode,
    'pcName': pcName,
    'platform': platform,
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'license': license.toJson(),
    'firstSeenAt': firstSeenAt.toUtc().toIso8601String(),
    'lastSeenAt': lastSeenAt.toUtc().toIso8601String(),
    'blocked': blocked,
  };
}

/// سجل الأجهزة السحابي — كل جهاز ليه ملف JSON خاص بيه في الريبو.
///
/// عند تشغيل التطبيق (release): بيقرا ملف الجهاز بتاعه، ولو مش موجود
/// بيسجّل نفسه فيه (اسم الجهاز + كود الجهاز + ترخيص مبدئي)، ولو موجود
/// بيقيّم الترخيص وبيحدّث آخر ظهور.
class DeviceRegistry {
  DeviceRegistry._();

  static final DeviceRegistry instance = DeviceRegistry._();

  bool _running = false;

  /// حالة الترخيص الحالية — بتتحدّث مع كل فحص (والـ Gate والواجهة بيسمعوها).
  static final ValueNotifier<DeviceLicenseStatus> status =
      ValueNotifier<DeviceLicenseStatus>(DeviceLicenseStatus.pending);

  /// آخر سجل للجهاز (فاضي لو لسه متسجلش).
  static DeviceRecord? currentRecord;

  /// كود الجهاز — بيتحسب مرة واحدة عند أول فحص.
  static String? deviceCode;

  /// اسم الجهاز (PC name).
  static String? pcName;

  static String _pcName() {
    final env = Platform.environment['COMPUTERNAME'];
    if (env != null && env.trim().isNotEmpty) return env.trim();
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'unknown';
    }
  }

  String get _platformName => Platform.isWindows ? 'windows' : 'android';

  /// فحص كامل: بيسجّل الجهاز لو جديد، بيقيّم الترخيص، وبيحدّث آخر ظهور.
  /// بيرجع نتيجة جاهزة للعرض (حالة + سجل + كود/اسم الجهاز).
  Future<LicenseResult> checkLicense() async {
    if (_running) {
      return LicenseResult(
        status: status.value,
        record: currentRecord,
        deviceCode: deviceCode ?? '',
        pcName: pcName ?? _pcName(),
      );
    }
    _running = true;
    try {
      if (AppMode.isOffline) {
        return const LicenseResult(
          status: DeviceLicenseStatus.unlimited,
          record: null,
          deviceCode: '',
          pcName: '',
        );
      }
      if (UpdateConfig.repo.trim().isEmpty ||
          UpdateConfig.token.trim().isEmpty) {
        AppLog.write('DeviceRegistry: no repo/token configured.');
        return const LicenseResult(
          status: DeviceLicenseStatus.pending,
          record: null,
          deviceCode: '',
          pcName: '',
        );
      }

      final api = GithubReleasesApi(
        repo: UpdateConfig.repo,
        token: UpdateConfig.token,
      );
      final code = await DeviceFingerprint.deviceId();
      deviceCode = code;
      final pc = _pcName();
      pcName = pc;
      if (code.isEmpty) {
        AppLog.write('DeviceRegistry: could not compute device code.');
        return LicenseResult(
          status: DeviceLicenseStatus.pending,
          record: null,
          deviceCode: '',
          pcName: pc,
        );
      }

      final path = 'devices/$code.json';
      final now = DateTime.now().toUtc();
      final version =
          Platform.isWindows
              ? VersionInfo.windowsVersion
              : VersionInfo.mobileVersion;
      final build =
          Platform.isWindows
              ? VersionInfo.windowsBuildNumber
              : VersionInfo.mobileBuildNumber;

      final fetch = await api.getDeviceFile(path);
      DeviceRecord record;
      if (!fetch.found) {
        // ── أول تشغيل: نسجّل الجهاز بترخيص مبدئي (pending) ──
        record = DeviceRecord(
          deviceCode: code,
          pcName: pc,
          platform: _platformName,
          appVersion: version,
          buildNumber: build,
          license: DeviceLicense(type: DeviceLicenseType.days, value: 0),
          firstSeenAt: now,
          lastSeenAt: now,
        );
        await api.putDeviceFile(
          path: path,
          content: const JsonEncoder.withIndent('  ').convert(record.toJson()),
          message: 'Register device: $pc',
        );
        AppLog.write('DeviceRegistry: registered $pc ($code).');
      } else {
        // ── الجهاز مسجل: قيّم الترخيص وحدّث آخر ظهور ──
        record = DeviceRecord.fromJson(
          jsonDecode(fetch.content) as Map<String, dynamic>,
        );
        record
          ..pcName = pc
          ..appVersion = version
          ..buildNumber = build
          ..lastSeenAt = now;
        await api.putDeviceFile(
          path: path,
          content: const JsonEncoder.withIndent('  ').convert(record.toJson()),
          sha: fetch.sha,
          message: 'Device heartbeat: $pc',
        );
      }

      currentRecord = record;
      // الحظر أولوية على أي ترخيص — الجهاز المحظور مقفول عليه دايمًا.
      final licenseStatus = record.blocked
          ? DeviceLicenseStatus.blocked
          : record.license.statusAt(now);
      status.value = licenseStatus;
      AppLog.write(
        'DeviceRegistry: $pc ($code) — license status: ${licenseStatus.name}',
      );
      return LicenseResult(
        status: licenseStatus,
        record: record,
        deviceCode: code,
        pcName: pc,
      );
    } catch (error) {
      AppLog.write('DeviceRegistry error: $error');
      return LicenseResult(
        status: status.value,
        record: currentRecord,
        deviceCode: deviceCode ?? '',
        pcName: pcName ?? _pcName(),
      );
    } finally {
      _running = false;
    }
  }

  /// تسجيل صامت (بعد ما التطبيق يكون فاتح) — بيحدّث آخر ظهور بس.
  Future<void> ensureRegistered() async {
    if (kDebugMode || AppMode.isOffline) return;
    await checkLicense();
  }
}

/// نتيجة فحص الترخيص — بتتستخدم في الـ Gate والشاشات.
class LicenseResult {
  const LicenseResult({
    required this.status,
    required this.record,
    required this.deviceCode,
    required this.pcName,
  });

  final DeviceLicenseStatus status;
  final DeviceRecord? record;
  final String deviceCode;
  final String pcName;

  bool get isAllowed =>
      status == DeviceLicenseStatus.active ||
      status == DeviceLicenseStatus.unlimited;
}

/// المراقب الدوري — بيعيد فحص الترخيص كل 5 دقايق (online بس)،
/// ولو الترخيص انتهى/اتلغى بيقفل التطبيق ويرجع للـ Gate.
class LicenseWatcher {
  LicenseWatcher._();

  static final LicenseWatcher instance = LicenseWatcher._();

  Timer? _timer;
  bool _checking = false;

  static const Duration interval = Duration(minutes: 5);

  /// يبدأ المراقبة — بيتنادى بعد ما التطبيق يفتح في الوضع الأونلاين.
  void start() {
    if (AppMode.isOffline) return;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => checkNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// فحص فوري (بيستخدمه المؤقت).
  Future<void> checkNow() async {
    if (_checking || AppMode.isOffline) return;
    _checking = true;
    try {
      final result = await DeviceRegistry.instance.checkLicense();
      if (!result.isAllowed) {
        AppLog.write(
          'LicenseWatcher: license ${result.status.name} — locking the app.',
        );
        final handler = onLock;
        if (handler != null) handler();
      }
    } catch (error) {
      AppLog.write('LicenseWatcher error: $error');
    } finally {
      _checking = false;
    }
  }

  /// اللي بيقفل التطبيق ويرجع للـ Gate — بيتسجل من license_gate.dart.
  static void Function()? onLock;
}
