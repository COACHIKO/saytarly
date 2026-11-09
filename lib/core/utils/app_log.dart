import 'dart:io';

/// سجل ملف بسيط للتشخيص — مشترك بين التطبيق والمحدّث الذاتي.
/// الملف: %APPDATA%\Saytarly\saytarly.log
class AppLog {
  AppLog._();

  static void write(String message) {
    try {
      final base =
          Platform.environment['APPDATA'] ??
          Platform.environment['HOME'] ??
          '.';
      final file = File(
        '$base${Platform.pathSeparator}Saytarly${Platform.pathSeparator}saytarly.log',
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // التسجيل اختياري — مش بيوقف التشغيل.
    }
  }
}
