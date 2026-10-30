import 'package:flutter/material.dart';

import 'package:saytarly/core/localization/messages.dart';

/// موديل قسم منتجات (زي: مشروبات، ماكولات، حلويات...)
class AppModule {
  final int? id;

  /// الاسم العربي (أو الاسم الأساسي القديم).
  final String name;

  /// الاسم الإنجليزي — اختياري، وبيستخدم في الواجهة الإنجليزية.
  final String nameEn;
  final String icon;
  final int color;
  final int sortOrder;
  final bool isEnabled;

  AppModule({
    this.id,
    required this.name,
    this.nameEn = '',
    this.icon = 'category',
    this.color = 0xFF14B8A6,
    this.sortOrder = 0,
    this.isEnabled = true,
  });

  factory AppModule.fromMap(Map<String, dynamic> m) => AppModule(
    id: m['id'] as int?,
    name: m['name'] as String? ?? '',
    nameEn: m['name_en'] as String? ?? '',
    icon: m['icon'] as String? ?? 'category',
    color: (m['color'] as num?)?.toInt() ?? 0xFF14B8A6,
    sortOrder: m['sort_order'] as int? ?? 0,
    isEnabled: (m['is_enabled'] ?? 1) == 1,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'name_en': nameEn,
    'icon': icon,
    'color': color,
    'sort_order': sortOrder,
    'is_enabled': isEnabled ? 1 : 0,
  };

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

  IconData get iconData => ModuleIcons.iconData(icon);
  Color get accentColor => Color(color);
}

/// موديل القائمة الفرعية جوه القسم (زي: سخن، بارد، غازية...)
class AppModuleCategory {
  final int? id;
  final int moduleId;

  /// الاسم العربي (أو الاسم الأساسي القديم).
  final String name;

  /// الاسم الإنجليزي — اختياري، وبيستخدم في الواجهة الإنجليزية.
  final String nameEn;
  final String key;
  final int sortOrder;
  final bool isEnabled;

  AppModuleCategory({
    this.id,
    required this.moduleId,
    required this.name,
    this.nameEn = '',
    required this.key,
    this.sortOrder = 0,
    this.isEnabled = true,
  });

  factory AppModuleCategory.fromMap(Map<String, dynamic> m) =>
      AppModuleCategory(
        id: m['id'] as int?,
        moduleId: m['module_id'] as int? ?? 0,
        name: m['name'] as String? ?? '',
        nameEn: m['name_en'] as String? ?? '',
        key: m['key'] as String? ?? '',
        sortOrder: m['sort_order'] as int? ?? 0,
        isEnabled: (m['is_enabled'] ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'module_id': moduleId,
    'name': name,
    'name_en': nameEn,
    'key': key,
    'sort_order': sortOrder,
    'is_enabled': isEnabled ? 1 : 0,
  };

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
}

/// أيقونات جاهزة يختار منها السوبر ادمن
class ModuleIcons {
  static const Map<String, IconData> presets = {
    'local_drink': Icons.local_drink,
    'local_cafe': Icons.local_cafe,
    'emoji_food_beverage': Icons.emoji_food_beverage,
    'water_drop': Icons.water_drop,
    'restaurant': Icons.restaurant,
    'fastfood': Icons.fastfood,
    'local_pizza': Icons.local_pizza,
    'ramen_dining': Icons.ramen_dining,
    'lunch_dining': Icons.lunch_dining,
    'dinner_dining': Icons.dinner_dining,
    'breakfast_dining': Icons.breakfast_dining,
    'bakery_dining': Icons.bakery_dining,
    'cake': Icons.cake,
    'icecream': Icons.icecream,
    'smoking_rooms': Icons.smoking_rooms,
    'blur_on': Icons.blur_on,
    'sports_esports': Icons.sports_esports,
    'shopping_bag': Icons.shopping_bag,
    'inventory_2': Icons.inventory_2,
    'category': Icons.category,
  };

  static IconData iconData(String key) => presets[key] ?? Icons.category;

  static String iconKey(IconData data) {
    for (final e in presets.entries) {
      if (e.value == data) return e.key;
    }
    return 'category';
  }
}

/// ألوان جاهزة يختار منها السوبر ادمن
class ModuleColors {
  static const List<int> presets = [
    0xFF14B8A6, // teal
    0xFF3B82F6, // blue
    0xFF8B5CF6, // violet
    0xFFEC4899, // pink
    0xFFF97316, // orange
    0xFFEAB308, // yellow
    0xFF22C55E, // green
    0xFFEF4444, // red
    0xFF0EA5E9, // sky
    0xFF6B7280, // grey
  ];
}
