import 'package:saytarly/core/localization/messages.dart';

class ConsoleModel {
  int? id;
  String name;
  double pricePerHour;
  bool isFixedPrice; // جديد
  double fixedPrice; // جديد
  double? singleMatchPrice;
  double? doubleMatchPrice;

  ConsoleModel({
    this.id,
    required this.name,
    required this.pricePerHour,
    this.isFixedPrice = false,
    this.fixedPrice = 0.0,
    this.singleMatchPrice,
    this.doubleMatchPrice,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price_per_hour': pricePerHour,
    'is_fixed_price': isFixedPrice ? 1 : 0,
    'fixed_price': fixedPrice,
    'single_match_price': singleMatchPrice,
    'double_match_price': doubleMatchPrice,
  };

  factory ConsoleModel.fromMap(Map<String, dynamic> m) => ConsoleModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    pricePerHour: (m['price_per_hour'] as num).toDouble(),
    isFixedPrice: (m['is_fixed_price'] ?? 0) == 1,
    fixedPrice: (m['fixed_price'] as num?)?.toDouble() ?? 0.0,
    singleMatchPrice: (m['single_match_price'] as num?)?.toDouble(),
    doubleMatchPrice: (m['double_match_price'] as num?)?.toDouble(),
  );
}

class DrinkModel {
  int? id;
  String name;
  String nameEn;
  double price;
  int qty;
  String temperature;
  int? moduleId;
  DrinkModel({
    this.id,
    required this.name,
    this.nameEn = '',
    required this.price,
    this.qty = 0,
    this.temperature = "normal",
    this.moduleId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'price': price,
      'qty': qty,
      'temperature': temperature,
      if (moduleId != null) 'module_id': moduleId,
    };
  }

  factory DrinkModel.fromMap(Map<String, dynamic> map) {
    return DrinkModel(
      id: map['id'],
      name: map['name'],
      nameEn: map['name_en'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      qty: map['qty'] ?? 0,
      temperature: map['temperature']?.toString() ?? "prodect",
      moduleId: map['module_id'] as int?,
    );
  }

  /// الاسم المناسب للغة الواجهة الحالية، مع fallback للاسم الآخر.
  String get displayName {
    final ar = name.trim();
    final en = nameEn.trim();
    return Str.isRtl ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
  }

  /// نفس قواعد [displayName] لصفوف قاعدة البيانات الخام.
  static String displayNameFromMap(Map<String, dynamic> m) {
    final ar = (m['name'] ?? '').toString().trim();
    final en = (m['name_en'] ?? '').toString().trim();
    return Str.isRtl ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || nameEn.toLowerCase().contains(q);
  }
}
