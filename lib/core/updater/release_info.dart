import 'package:saytarly/core/updater/version_utils.dart';

/// أصل الريليس اللي رجع من GitHub API.
class ReleaseAsset {
  const ReleaseAsset({
    required this.id,
    required this.name,
    required this.url,
    required this.browserDownloadUrl,
    required this.size,
  });

  final int id;
  final String name;

  /// رابط API المباشر للتحميل (مهم للريبوهات الخاصة — الرابط دا بيدي 302
  /// لرابط موقّع، إنما browser_download_url بيدّي 404 من غير كوكيز المتصفح).
  final String url;
  final String browserDownloadUrl;

  /// حجم الملف بالبايت (0 لو مش معروف).
  final int size;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: (json['name'] ?? '').toString(),
    url: (json['url'] ?? '').toString(),
    browserDownloadUrl: (json['browser_download_url'] ?? '').toString(),
    size: (json['size'] as num?)?.toInt() ?? 0,
  );
}

class GithubRelease {
  const GithubRelease({
    required this.id,
    required this.tagName,
    required this.name,
    required this.notes,
    required this.htmlUrl,
    required this.assets,
    this.publishedAt,
  });

  final int id;
  final String tagName;
  final String name;
  final String notes;
  final String htmlUrl;
  final List<ReleaseAsset> assets;

  /// تاريخ النشر (بيرجع من الـ API).
  final DateTime? publishedAt;

  factory GithubRelease.fromJson(Map<String, dynamic> json) => GithubRelease(
    id: (json['id'] as num?)?.toInt() ?? 0,
    tagName: (json['tag_name'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    notes: (json['body'] ?? '').toString(),
    htmlUrl: (json['html_url'] ?? '').toString(),
    assets: [
      for (final asset in (json['assets'] as List? ?? const []))
        ReleaseAsset.fromJson(Map<String, dynamic>.from(asset as Map)),
    ],
    publishedAt:
        json['published_at'] is String
            ? DateTime.tryParse(json['published_at'] as String)
            : null,
  );

  /// أول أصل بـ zip في الريليس (ملف تحديث الويندوز).
  ReleaseAsset? get zipAsset {
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.zip')) return asset;
    }
    return null;
  }

  /// النسخة اللي التاج بيشير ليها لو التاج بصيغة `windows-<version>` أو
  /// `mobile-<version>` — بيرجع النص الأصلي لو الشكل مختلف.
  String get versionFromTag => VersionUtils.versionFromPrefixedTag(tagName);
}
