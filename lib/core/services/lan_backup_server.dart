import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:saytarly/core/services/backup_helper.dart';
import 'package:saytarly/core/localization/messages.dart';

class LanBackupServer {
  static HttpServer? _server;
  static const int port = 8085;

  static bool get isRunning => _server != null;

  static Future<void> start() async {
    if (!Platform.isWindows && !Platform.isLinux) {
      print(
          '⚠️ سيرفر النسخ الاحتياطي لا يعمل إلا على أجهزة الكاشير (Windows/Linux)');
      return;
    }
    if (_server != null) return;

    final router = Router();

    router.get('/ping', (Request req) {
      return Response.ok('XO_CAFE_BACKUP_SERVER');
    });

    router.get('/backup', (Request req) async {
      final bytes = await BackupHelper.getLatestAutoBackupBytes();
      if (bytes == null) {
        return Response.notFound('لا توجد نسخة احتياطية بعد على هذا الجهاز'.tr());
      }
      return Response.ok(
        bytes,
        headers: {'content-type': 'application/octet-stream'},
      );
    });

    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      print('✅ سيرفر النسخ الاحتياطي شغال على البورت $port');
    } catch (e) {
      print('❌ فشل تشغيل سيرفر الشبكة: $e');
    }
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static Future<List<String>> getLocalIps() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    return interfaces
        .expand((i) => i.addresses)
        .map((a) => a.address)
        .where((ip) => !ip.startsWith('169.254'))
        .toList();
  }
}
