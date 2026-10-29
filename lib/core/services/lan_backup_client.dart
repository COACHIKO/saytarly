import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:saytarly/core/localization/messages.dart';

class LanBackupClient {
  static const int defaultPort = 8085;

  static Future<bool> ping(String ip, {int port = defaultPort}) async {
    try {
      final res = await http
          .get(Uri.parse('http://$ip:$port/ping'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200 &&
          res.body.contains('XO_CAFE_BACKUP_SERVER');
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List> fetchLatestBackup(
    String ip, {
    int port = defaultPort,
  }) async {
    final res = await http
        .get(Uri.parse('http://$ip:$port/backup'))
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 404) {
      throw Exception('لا توجد نسخة احتياطية على جهاز الكاشير بعد'.tr());
    }
    if (res.statusCode != 200) {
      throw Exception('فشل الاتصال بجهاز الكاشير'.tr());
    }
    return res.bodyBytes;
  }
}
