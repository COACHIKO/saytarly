library;

/// أدوات مقارنة نسخ 4 أجزاء (1.2.8 → 1.2.8.0).
class VersionUtils {
  VersionUtils._();

  /// بيشيل البادئة `windows-` أو `mobile-` من التاج ويرجع النسخة.
  static String versionFromPrefixedTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.startsWith('windows-')) {
      return trimmed.substring('windows-'.length);
    }
    if (trimmed.startsWith('mobile-')) {
      return trimmed.substring('mobile-'.length);
    }
    if (trimmed.startsWith('v')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  static List<int> _parts(String version) {
    final parts = <int>[];
    for (final chunk in version.trim().split('.')) {
      final value = int.tryParse(chunk.trim());
      if (value == null) return const [];
      parts.add(value);
    }
    while (parts.length < 4) {
      parts.add(0);
    }
    return parts.length <= 4 ? parts : parts.sublist(0, 4);
  }

  /// هل `candidate` أحدث من `current`؟ مقارنة رقمية جزء-جزء.
  static bool isNewer(String candidate, String current) {
    final a = _parts(candidate);
    final b = _parts(current);
    if (a.isEmpty || b.isEmpty) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] > b[i]) return true;
      if (a[i] < b[i]) return false;
    }
    return false;
  }
}
