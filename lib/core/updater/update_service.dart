import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:saytarly/core/desktop/widgets/desktop_feedback.dart';
import 'package:saytarly/core/desktop/windows_tray.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/core/routing/app_router.dart';
import 'package:saytarly/core/updater/app_mode.dart';
import 'package:saytarly/core/updater/github_releases_api.dart';
import 'package:saytarly/core/updater/release_info.dart';
import 'package:saytarly/core/updater/update_config.dart';
import 'package:saytarly/core/updater/update_dialog.dart';
import 'package:saytarly/core/updater/version_info.dart';
import 'package:saytarly/core/updater/version_utils.dart';
import 'package:saytarly/core/utils/app_log.dart';

/// التحديث الذاتي — بيفحص GitHub Releases عند تشغيل التطبيق.
///
/// ويندوز: بينزّل الـ zip بتاع النسخة الجديدة، بيفكّه، وبعدها بيقفل
/// التطبيق ويستبدل الملفات ويفتح تاني تلقائيًا.
/// موبايل (Android): بيفتح رابط التحميل في المتصفح.
class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  bool _running = false;
  bool _prompted = false;

  bool get isWindows => !kIsWeb && Platform.isWindows;

  /// بينادى بعد أول فريم في [main]. شغال في نسخ الـ release وفي الوضع
  /// الأونلاين بس — الأوفلاين مفيهوش أي خدمات GitHub.
  Future<void> checkOnStartup() async {
    if (kDebugMode || AppMode.isOffline) return;
    if (_running || _prompted) return;
    await _check(showUpToDateMessage: false);
  }

  /// فحص يدوي من شاشة الإعدادات — دايمًا بيظهر نتيجة (محدث / تحديث متاح).
  Future<void> checkManually() async {
    if (AppMode.isOffline) {
      AppToast.show('غير متاح في الوضع الأوفلاين'.tr());
      return;
    }
    AppToast.show('جارٍ التحقق من التحديثات…'.tr());
    await _check(showUpToDateMessage: true);
  }

  /// الرجوع لنسخة أقدم من GitHub Releases (Rollback).
  /// بيعرض قايمة النسخ الأقدم ويطبق اللي المستخدم يختاره بنفس مسار التحديث.
  Future<void> openRollback() async {
    if (AppMode.isOffline) {
      AppToast.show('غير متاح في الوضع الأوفلاين'.tr());
      return;
    }
    if (UpdateConfig.repo.trim().isEmpty || UpdateConfig.token.trim().isEmpty) {
      AppLog.write('Rollback: no repo/token configured — skipping.');
      AppToast.show(
        'التحديث الذاتي غير مفعّل — كمل بيانات الريبو والتوكن'.tr(),
      );
      return;
    }
    final context = NavigationService.instance.appContext;
    if (context == null || !context.mounted) return;
    try {
      AppLog.write('Rollback: fetching older releases.');
      final api = GithubReleasesApi(
        repo: UpdateConfig.repo,
        token: UpdateConfig.token,
      );
      final releases = await api.listReleases();
      final prefix = isWindows ? 'windows-' : 'mobile-';
      final current = _currentVersion();
      final older =
          releases.where((release) {
            if (!release.tagName.startsWith(prefix)) return false;
            // النسخة الأقدم = الحالية أحدث منها
            return VersionUtils.isNewer(current, release.versionFromTag);
          }).toList();

      if (older.isEmpty) {
        AppToast.show('مفيش نسخ أقدم متاحة'.tr());
        return;
      }

      final selected = await showRollbackPrompt(
        context: context,
        currentVersion: current,
        releases: older,
      );
      if (selected == null || !context.mounted) return;

      if (!isWindows) {
        if (selected.htmlUrl.isNotEmpty) {
          await launchUrl(
            Uri.parse(selected.htmlUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        return;
      }

      AppToast.show(
        'بيتم تنزيل النسخة {v1}…'.tr({'v1': selected.versionFromTag}),
      );
      AppLog.write('Rollback: applying ${selected.tagName}.');
      await _runUpdate(selected);
    } catch (error) {
      debugPrint('Rollback notice: $error');
      AppLog.write('Rollback error: $error');
      if (context.mounted) {
        AppToast.show('حصلت مشكلة أثناء الرجوع للنسخة الأقدم.'.tr());
      }
    }
  }

  Future<void> _check({required bool showUpToDateMessage}) async {
    if (_running) return;
    if (UpdateConfig.repo.trim().isEmpty || UpdateConfig.token.trim().isEmpty) {
      debugPrint('Updater: no repo/token configured — skipping.');
      AppLog.write('Updater: no repo/token configured — skipping.');
      AppToast.show(
        'التحديث الذاتي غير مفعّل — كمل بيانات الريبو والتوكن'.tr(),
      );
      return;
    }
    _running = true;
    try {
      AppLog.write('Updater: checking releases from ${UpdateConfig.repo}');
      final api = GithubReleasesApi(
        repo: UpdateConfig.repo,
        token: UpdateConfig.token,
      );
      final releases = await api.listReleases();
      final newer = _findNewerRelease(releases);
      if (newer == null) {
        AppLog.write('Updater: no newer release (current $_currentVersion())');
        if (showUpToDateMessage) {
          AppToast.show('أنت على أحدث نسخة ✓'.tr(), kind: FeedbackKind.success);
        }
        return;
      }

      AppLog.write(
        'Updater: newer release ${newer.tagName} found — prompting user.',
      );
      final context = NavigationService.instance.appContext;
      if (context == null || !context.mounted) return;
      _prompted = true;

      // وضع التحديث الصامت — للاختبار أو الأجهزة اللي بتتحدّث لوحدها.
      if (Platform.environment['SAYTARLY_AUTO_UPDATE'] == '1') {
        AppLog.write(
          'Updater: SAYTARLY_AUTO_UPDATE=1 — installing without prompt.',
        );
        await _runUpdate(newer);
        return;
      }

      final wantsUpdate =
          await showUpdatePrompt(
            context: context,
            currentVersion: _currentVersion(),
            release: newer,
          ) ??
          false;
      if (wantsUpdate) await _runUpdate(newer);
    } catch (error) {
      debugPrint('Updater check notice: $error');
      AppLog.write('Updater check error: $error');
      if (showUpToDateMessage) {
        AppToast.show('حصلت مشكلة أثناء التحقق من التحديثات.'.tr());
      }
    } finally {
      _running = false;
    }
  }

  String _currentVersion() =>
      isWindows ? VersionInfo.windowsVersion : VersionInfo.mobileVersion;

  /// أول ريليس (الأحدث) تاجه `windows-`/`mobile-` ونسخته أحدث من الحالية.
  GithubRelease? _findNewerRelease(List<GithubRelease> releases) {
    final prefix = isWindows ? 'windows-' : 'mobile-';
    final current = _currentVersion();
    for (final release in releases) {
      if (!release.tagName.startsWith(prefix)) continue;
      if (VersionUtils.isNewer(release.versionFromTag, current)) {
        return release;
      }
    }
    return null;
  }

  Future<void> _runUpdate(GithubRelease release) async {
    final context = NavigationService.instance.appContext;

    // ── موبايل: فتح رابط التحميل في المتصفح ──
    if (!isWindows) {
      if (release.htmlUrl.isNotEmpty) {
        await launchUrl(
          Uri.parse(release.htmlUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      return;
    }

    final asset = release.zipAsset;
    Future<void> openInBrowser() async {
      if (release.htmlUrl.isNotEmpty) {
        await launchUrl(
          Uri.parse(release.htmlUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }

    if (asset == null ||
        (asset.url.isEmpty && asset.browserDownloadUrl.isEmpty)) {
      if (context != null && context.mounted) {
        await showUpdaterMessage(
          context,
          'مفيش ملف تحديث في الريليس — هيفتح رابط التحميل في المتصفح.'.tr(),
        );
      }
      await openInBrowser();
      return;
    }

    if (!await _canWriteToAppDir()) {
      if (context != null && context.mounted) {
        await showUpdaterMessage(
          context,
          'مفيش صلاحية كتابة في مجلد التطبيق — هيفتح رابط التحميل في المتصفح.'
              .tr(),
        );
      }
      await openInBrowser();
      return;
    }

    final progress = ValueNotifier<double>(0);
    if (context != null && context.mounted) {
      unawaited(showDownloadProgress(context, progress));
    }

    try {
      final stageDir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'saytarly_update_${release.tagName}',
      );
      if (stageDir.existsSync()) stageDir.deleteSync(recursive: true);
      stageDir.createSync(recursive: true);
      final filesDir = Directory(
        '${stageDir.path}${Platform.pathSeparator}files',
      );
      filesDir.createSync(recursive: true);

      final zipPath = '${stageDir.path}${Platform.pathSeparator}update.zip';
      // الرابط الأساسي هو asset.url (الـ API) — عشان الريبو الخاص.
      final downloadUrl =
          asset.url.isNotEmpty ? asset.url : asset.browserDownloadUrl;
      await _download(downloadUrl, zipPath, (value) => progress.value = value);
      progress.value = 1;

      await _extractZip(zipPath, filesDir.path);
      AppLog.write('Updater: zip extracted into ${filesDir.path}');
      final scriptPath = _writeApplyScript(stageDir, filesDir);
      _launchApplyScript(scriptPath, filesDir);
      AppLog.write('Updater: apply script launched — closing the app.');

      // قفل التطبيق: الأول نحاول الطريقة النضيفة (تدمير النافذة وإزالة
      // أيقونة التراي)، وبعدين exit(0) كضمانة — السكريبت هيستنى البروسيس
      // يقفل وبعدها يستبدل الملفات ويفتح النسخة الجديدة.
      try {
        await WindowsTray.instance.exitApp();
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
      AppLog.write('Updater: forcing app exit for the update.');
      exit(0);
    } catch (error) {
      debugPrint('Updater install notice: $error');
      AppLog.write('Updater install error: $error');
      progress.value = 0;
      if (context != null && context.mounted) {
        await showUpdaterMessage(
          context,
          'حصلت مشكلة أثناء تنزيل التحديث — جرب تاني بعد شوية.'.tr(),
        );
      }
    }
  }

  Future<bool> _canWriteToAppDir() async {
    try {
      final dir = File(Platform.resolvedExecutable).parent;
      final probe = File(
        '${dir.path}${Platform.pathSeparator}.saytarly_write_probe',
      );
      await probe.writeAsString('x');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _download(
    String url,
    String savePath,
    void Function(double) onProgress,
  ) async {
    final dio = Dio();
    AppLog.write('Updater: downloading $url');
    await dio.download(
      url,
      savePath,
      options: Options(
        headers: {
          'Accept': 'application/octet-stream',
          // أصول الريبو الخاص بتتطلب مصادقة حتى للتحميل
          if (UpdateConfig.token.isNotEmpty)
            'Authorization': 'Bearer ${UpdateConfig.token}',
        },
        followRedirects: true,
      ),
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    AppLog.write('Updater: download finished -> $savePath');
  }

  Future<void> _extractZip(String zipPath, String destination) async {
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      "Expand-Archive -Path \"$zipPath\" -DestinationPath \"$destination\" -Force",
    ]);
    if (result.exitCode != 0) {
      throw Exception('Expand-Archive failed: ${result.stderr}');
    }
  }

  /// سكريبت PowerShell بيستنى التطبيق يقفل وبعدين بيستبدل الملفات
  /// ويفتح النسخة الجديدة.
  String _writeApplyScript(Directory stageDir, Directory filesDir) {
    final scriptPath =
        '${stageDir.path}${Platform.pathSeparator}apply_update.ps1';
    final script = r'''
param(
  [int]$AppPid,
  [string]$AppDir,
  [string]$StageDir,
  [string]$ExeName
)
$ErrorActionPreference = "SilentlyContinue"
function Write-UpdateLog([string]$Message) {
  try {
    $logPath = Join-Path $env:APPDATA "Saytarly\saytarly.log"
    Add-Content -Path $logPath -Value ("{0} Updater: {1}" -f (Get-Date -Format o), $Message)
  } catch {}
}
Write-UpdateLog "apply script started (pid=$AppPid)"
Start-Sleep -Seconds 3
if (Get-Process -Id $AppPid -ErrorAction SilentlyContinue) {
  Write-UpdateLog "waiting for app to exit"
  Wait-Process -Id $AppPid
}
Write-UpdateLog "copying new files from $StageDir into $AppDir"
robocopy "$StageDir" "$AppDir" /E /IS /IT /R:2 /W:2 | Out-Null
Write-UpdateLog "copy finished (exit=$LASTEXITCODE)"
Start-Sleep -Seconds 1
$exePath = Join-Path $AppDir $ExeName
if (Test-Path $exePath) {
  Write-UpdateLog "launching $exePath"
  Start-Process -FilePath $exePath
} else {
  Write-UpdateLog "ERROR: $exePath not found after copy"
}
Remove-Item (Split-Path -Parent $StageDir) -Recurse -Force
''';
    File(scriptPath).writeAsStringSync(script);
    return scriptPath;
  }

  void _launchApplyScript(String scriptPath, Directory filesDir) {
    final exe = Platform.resolvedExecutable;
    final appDir = File(exe).parent.path;
    final exeName = exe.split(Platform.pathSeparator).last;
    // بنطلق السكريبت من خلال `cmd start` — عشان يفضل شغال بعد ما التطبيق
    // يقفل (Process.start العادي بتاع دارت بيتقتل مع الأب في بعض أنظمة الويندوز).
    Process.start('cmd.exe', [
      '/c',
      'start',
      '""',
      '/min',
      'powershell.exe',
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      scriptPath,
      '-AppPid',
      '$pid',
      '-AppDir',
      appDir,
      '-StageDir',
      filesDir.path,
      '-ExeName',
      exeName,
    ]);
  }
}
