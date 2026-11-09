import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/updater/device_registry.dart';

void main() {
  test('license status evaluation', () {
    final now = DateTime.utc(2026, 11, 7);

    final unlimited = DeviceLicense(
      type: DeviceLicenseType.unlimited,
    );
    expect(unlimited.statusAt(now), DeviceLicenseStatus.unlimited);
    expect(unlimited.computeExpiry(now), isNull);

    final active = DeviceLicense(
      type: DeviceLicenseType.months,
      value: 3,
      expiresAt: now.add(const Duration(days: 30)),
    );
    expect(active.statusAt(now), DeviceLicenseStatus.active);

    final expired = DeviceLicense(
      type: DeviceLicenseType.days,
      value: 30,
      expiresAt: now.subtract(const Duration(days: 1)),
    );
    expect(expired.statusAt(now), DeviceLicenseStatus.expired);

    final pending = DeviceLicense(type: DeviceLicenseType.days, value: 0);
    expect(pending.statusAt(now), DeviceLicenseStatus.pending);

    // حساب تاريخ الانتهاء
    final months = DeviceLicense(type: DeviceLicenseType.months, value: 3);
    expect(months.computeExpiry(now), DateTime.utc(2027, 2, 7));
    final years = DeviceLicense(type: DeviceLicenseType.years, value: 1);
    expect(years.computeExpiry(now), DateTime.utc(2027, 11, 7));
    final days = DeviceLicense(type: DeviceLicenseType.days, value: 10);
    expect(days.computeExpiry(now), DateTime.utc(2026, 11, 17));
  });

  test('device record JSON round-trip', () {
    final record = DeviceRecord(
      deviceCode: 'ABC123',
      pcName: 'DESKTOP-TEST',
      platform: 'windows',
      appVersion: '1.0.0.1',
      buildNumber: 2,
      license: DeviceLicense(type: DeviceLicenseType.years, value: 1),
      firstSeenAt: DateTime.utc(2026, 11, 7),
      lastSeenAt: DateTime.utc(2026, 11, 7),
    );

    final json = jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>;
    final restored = DeviceRecord.fromJson(json);

    expect(restored.deviceCode, 'ABC123');
    expect(restored.pcName, 'DESKTOP-TEST');
    expect(restored.platform, 'windows');
    expect(restored.license.type, DeviceLicenseType.years);
    expect(restored.license.value, 1);
  });
}
