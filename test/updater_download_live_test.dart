import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/updater/github_releases_api.dart';
import 'package:saytarly/core/updater/release_info.dart';
import 'package:saytarly/core/updater/update_config.dart';
import 'package:saytarly/core/updater/version_utils.dart';

/// اختبار مؤقت للتحقق من مسار التحديث الحقيقي:
/// جلب الريليسيز بالمصادقة ← تنزيل الـ zip بتاع windows-1.0.0.1
/// بنفس الهيدرز بتاعة التطبيق ← فك الضغط والتحقق من الـ exe.
void main() {
  test('downloads the real update zip with auth and extracts it', () async {
    if (UpdateConfig.token.trim().isEmpty) {
      markTestSkipped('no RELEASES_TOKEN configured — skipping live test');
      return;
    }
    final api = GithubReleasesApi(
      repo: UpdateConfig.repo,
      token: UpdateConfig.token,
    );

    final releases = await api.listReleases();
    GithubRelease? newest;
    for (final r in releases) {
      if (!r.tagName.startsWith('windows-')) continue;
      if (VersionUtils.isNewer(r.versionFromTag, '1.0.0.0')) {
        newest = r;
        break;
      }
    }
    expect(newest, isNotNull, reason: 'no newer windows release found');
    final asset = newest!.zipAsset;
    expect(asset, isNotNull, reason: 'release has no zip asset');
    final assetUrl = asset!.url.isNotEmpty ? asset.url : asset.browserDownloadUrl;

    final stage = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'saytarly_upd_test_${newest.tagName}',
    );
    if (stage.existsSync()) stage.deleteSync(recursive: true);
    stage.createSync(recursive: true);
    final files = Directory('${stage.path}${Platform.pathSeparator}files');
    files.createSync(recursive: true);
    final zipPath = '${stage.path}${Platform.pathSeparator}update.zip';

    // نفس كود _download بتاع التطبيق — مع هيدر المصادقة
    final dio = Dio();
    await dio.download(
      assetUrl,
      zipPath,
      options: Options(
        headers: {
          'Accept': 'application/octet-stream',
          'Authorization': 'Bearer ${UpdateConfig.token}',
        },
        followRedirects: true,
      ),
    );

    final zip = File(zipPath);
    expect(zip.existsSync(), isTrue);
    expect(zip.lengthSync(), greaterThan(1000000));

    // فك الضغط بنفس طريقة التطبيق (PowerShell Expand-Archive)
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      'Expand-Archive -Path "$zipPath" -DestinationPath "${files.path}" -Force',
    ]);
    expect(result.exitCode, 0, reason: 'Expand-Archive failed: ${result.stderr}');

    expect(File('${files.path}${Platform.pathSeparator}saytarly.exe').existsSync(), isTrue);
    expect(File('${files.path}${Platform.pathSeparator}sqlite3.dll').existsSync(), isTrue);

    stage.deleteSync(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
