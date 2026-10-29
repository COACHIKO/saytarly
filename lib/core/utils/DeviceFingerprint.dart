import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
//
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';

class DeviceFingerprint {
  static Future<String> _run(String command, List<String> args) async {
    try {
      final result = await Process.run(command, args);

      if (result.exitCode != 0) return "";

      return result.stdout.toString().trim();
    } catch (_) {
      return "";
    }
  }

  static Future<String> cpuId() async {
    final output = await _run('wmic', ['cpu', 'get', 'ProcessorId']);

    final lines = output
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return lines.length > 1 ? lines[1] : "";
  }

  static Future<String> motherboardId() async {
    final output = await _run('wmic', ['baseboard', 'get', 'serialnumber']);

    final lines = output
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return lines.length > 1 ? lines[1] : "";
  }

  static Future<String> diskId() async {
    final output = await _run('wmic', ['diskdrive', 'get', 'serialnumber']);

    final lines = output
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return lines.length > 1 ? lines[1] : "";
  }

  static Future<String> deviceId() async {
    if (Platform.isAndroid) {
      final androidIdPlugin = const AndroidId();
      final id = await androidIdPlugin.getId(); // ANDROID_ID الحقيقي
      final raw = 'android|${id ?? ""}';
      return sha256.convert(utf8.encode(raw)).toString().toUpperCase();
    }

    final cpu = await cpuId();
    final board = await motherboardId();
    final disk = await diskId();
    final raw = '$cpu|$board|$disk';
    return sha256.convert(utf8.encode(raw)).toString().toUpperCase();
  }
}
