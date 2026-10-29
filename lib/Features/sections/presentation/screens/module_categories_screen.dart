import 'package:flutter/material.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/models/app_modules.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/module_categories_screen_mobile_body.dart';
part 'desktop/module_categories_screen_windows_body.dart';

/// القوائم الفرعية جوه القسم (زي: سخن، بارد، غازية...)
/// بتظهر كـ تابات جوه إدارة القسم وفي شاشة الكاشير
class ModuleCategoriesScreen extends StatefulWidget {
  final AppModule module;

  const ModuleCategoriesScreen({super.key, required this.module});

  @override
  State<ModuleCategoriesScreen> createState() => _ModuleCategoriesScreenState();
}

class _CategoryRow {
  final AppModuleCategory category;
  final int drinks;

  _CategoryRow(this.category, this.drinks);
}

class _ModuleCategoriesScreenState extends State<ModuleCategoriesScreen> {
  bool _loading = true;
  List<_CategoryRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await DBHelper.getCategories(moduleId: widget.module.id);
    final rows = <_CategoryRow>[];
    for (final c in cats) {
      final cat = AppModuleCategory.fromMap(c);
      final drinks = await DBHelper.countCategoryDrinks(cat.key);
      rows.add(_CategoryRow(cat, drinks));
    }
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    AppToast.show(msg, kind: error ? FeedbackKind.error : FeedbackKind.info);
  }

  Future<void> _openForm({_CategoryRow? edit}) async {
    final nameCtl = TextEditingController(text: edit?.category.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: Text(edit == null ? 'قائمة فرعية جديدة'.tr() : 'تعديل القائمة'),
        content: TextField(
          controller: nameCtl,
          autofocus: true,
          decoration:  InputDecoration(
            labelText: 'اسم القائمة (زي: سخن)'.tr(),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:  Text('حفظ'.tr()),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) {
      _snack('اكتب اسم القائمة'.tr(), error: true);
      return;
    }

    if (edit == null) {
      await DBHelper.insertCategory(
        moduleId: widget.module.id!,
        name: name,
      );
      _snack('تم إضافة القائمة ✅'.tr());
    } else {
      await DBHelper.updateCategory({
        'id': edit.category.id,
        'name': name,
      });
      _snack('تم التعديل ✅'.tr());
    }
    _load();
  }

  Future<void> _toggle(_CategoryRow row, bool value) async {
    await DBHelper.updateCategory({
      'id': row.category.id,
      'is_enabled': value ? 1 : 0,
    });
    _load();
  }

  Future<void> _delete(_CategoryRow row) async {
    if (row.drinks > 0) {
      _snack(
        ('مش هينفع تحذف «{v1}» — فيه {v2} منتج مسجل عليها. '.tr({'v1': row.category.name, 'v2': row.drinks}) + 'انقل المنتجات لقائمة تانية الأول، أو اقفلها من الزرار.'.tr()),
        error: true,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title:  Text('حذف القائمة؟'.tr()),
        content: Text('هتتحذف قائمة «{v1}» نهائيًا.'.tr({'v1': row.category.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text('حذف'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DBHelper.deleteCategory(row.category.id!);
    _snack('تم الحذف'.tr());
    _load();
  }

  Future<void> _move(int index, int delta) async {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _rows.length) return;
    final list = [..._rows];
    final tmp = list[index];
    list[index] = list[newIndex];
    list[newIndex] = tmp;
    await DBHelper.reorderCategories(
      list.map((r) => r.category.id!).toList(),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
