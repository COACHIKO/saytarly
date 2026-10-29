/// وحدة قياس خامة — بيتظبط من السوبر ادمن إما كوحدة مستقلة (قطعة)
/// أو وحدة أساسية ليها وحدة جزئية للعرض الدقيق (كيلو ← جرام ×1000).
class MaterialUnit {
  const MaterialUnit({
    required this.name,
    this.sub,
    this.subFactor,
  });

  /// اسم الوحدة كما يظهر في القوائم ويُخزن على الخامات.
  final String name;

  /// وحدة الجزئية للعرض (جرام / مل) — null لو الوحدة بسيطة بدون جزئيات.
  final String? sub;

  /// عامل التحويل: 1 من الوحدة الأصلية = factor من وحدة الجزئية.
  final double? subFactor;

  Map<String, dynamic> toMap() => {
        'name': name,
        'sub': sub,
        'factor': subFactor,
      };

  factory MaterialUnit.fromMap(Map<String, dynamic> m) => MaterialUnit(
        name: (m['name'] ?? '').toString(),
        sub: m['sub'] == null ? null : m['sub'].toString(),
        subFactor:
            m['factor'] == null ? null : (m['factor'] as num).toDouble(),
      );

  bool get hasSub =>
      sub != null && sub!.trim().isNotEmpty && (subFactor ?? 0) > 0;
}
