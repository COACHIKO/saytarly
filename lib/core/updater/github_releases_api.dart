import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:saytarly/core/updater/release_info.dart';

/// عميل GitHub Releases API — بيقرا الريليسيز من ريبو التحديثات،
/// وكمان بيقرا/يكتب ملفات الأجهزة من الـ Contents API.
class GithubReleasesApi {
  GithubReleasesApi({required this.repo, this.token = ''});

  final String repo;
  final String token;

  Dio _dio() {
    final options = BaseOptions(
      baseUrl: 'https://api.github.com',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'saytarly-updater',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    return Dio(options);
  }

  /// بيرجع آخر 30 ريليس — من الأحدث للأقدم.
  Future<List<GithubRelease>> listReleases() async {
    final response = await _dio().get<dynamic>(
      '/repos/$repo/releases',
      queryParameters: {'per_page': 30},
    );
    final list = response.data as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        GithubRelease.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// أول ريليس تاجه بيبدأ بـ `prefix` (مثل `windows-` أو `mobile-`).
  Future<GithubRelease?> latestWithTagPrefix(String prefix) async {
    final releases = await listReleases();
    for (final release in releases) {
      if (release.tagName.startsWith(prefix)) return release;
    }
    return null;
  }

  // ===================== ملفات الأجهزة (Contents API) =====================

  /// بيجيب محتوى ملف من الريبو — `found=false` لو الملف مش موجود.
  Future<DeviceFileFetch> getDeviceFile(String path) async {
    try {
      final response = await _dio().get<dynamic>('/repos/$repo/contents/$path');
      final json = Map<String, dynamic>.from(response.data as Map);
      final base64 = (json['content'] ?? '').toString();
      final normalized = base64.replaceAll('\n', '').replaceAll('\r', '');
      return DeviceFileFetch(
        found: true,
        content: utf8.decode(base64Decode(normalized)),
        sha: (json['sha'] ?? '').toString(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const DeviceFileFetch(found: false, content: '', sha: '');
      }
      rethrow;
    }
  }

  /// ينشئ أو يحدّث ملف في الريبو — `sha` مطلوب للتحديث، null للإنشاء.
  Future<void> putDeviceFile({
    required String path,
    required String content,
    String? sha,
    required String message,
  }) async {
    final payload = <String, dynamic>{
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      if (sha != null && sha.isNotEmpty) 'sha': sha,
    };
    await _dio().put<dynamic>('/repos/$repo/contents/$path', data: payload);
  }

  /// يمسح ملف من الريبو (بيستخدم في الإدارة).
  Future<void> deleteDeviceFile(String path, String sha) async {
    await _dio().delete<dynamic>(
      '/repos/$repo/contents/$path',
      data: {'message': 'Delete $path', 'sha': sha},
    );
  }
}

/// نتيجة قراءة ملف جهاز من الريبو.
class DeviceFileFetch {
  const DeviceFileFetch({
    required this.found,
    required this.content,
    required this.sha,
  });

  final bool found;
  final String content;
  final String sha;
}

