import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/app_modules.dart';

/// صف جاهز للعرض في شاشة إدارة الأقسام: القسم + أرقامه.
class SectionModuleRow {
  final AppModule module;

  /// عدد المنتجات اللي جوه القسم.
  final int drinks;

  /// عدد القوائم الفرعية (سخن / بارد / إلخ).
  final int categories;

  const SectionModuleRow(this.module, this.drinks, this.categories);
}

/// مستودع بيانات الأقسام (app_modules) — كل التعامل مع قاعدة البيانات هنا.
class SectionsRepository {
  /// كل الأقسام، ومع كل قسم عدد المنتجات والقوائم الفرعية.
  Future<List<SectionModuleRow>> fetchModuleRows() async {
    final modules = await DBHelper.getModules();
    final rows = <SectionModuleRow>[];
    for (final m in modules) {
      final module = AppModule.fromMap(m);
      final id = module.id!;
      final drinks = await DBHelper.countModuleDrinks(id);
      final categories = (await DBHelper.getCategories(moduleId: id)).length;
      rows.add(SectionModuleRow(module, drinks, categories));
    }
    return rows;
  }

  /// إضافة قسم جديد.
  Future<void> addModule({
    required String name,
    required String icon,
    required int color,
  }) async {
    await DBHelper.insertModule({
      'name': name,
      'icon': icon,
      'color': color,
    });
  }

  /// تعديل قسم — بيبعت الحقول المطلوب تعديلها بس.
  Future<void> updateModule({
    required int id,
    String? name,
    String? icon,
    int? color,
    bool? isEnabled,
  }) async {
    await DBHelper.updateModule({
      'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isEnabled != null) 'is_enabled': isEnabled ? 1 : 0,
    });
  }

  /// حذف قسم (وبيتحذف معاه قوالبه الفرعية).
  Future<void> deleteModule(int id) => DBHelper.deleteModule(id);

  /// ترتيب الأقسام حسب الترتيب الجديد.
  Future<void> reorderModules(List<int> orderedIds) =>
      DBHelper.reorderModules(orderedIds);
}
