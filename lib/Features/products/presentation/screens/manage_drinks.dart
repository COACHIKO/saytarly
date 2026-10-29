import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/models.dart';
import 'package:saytarly/Features/materials/presentation/print/PrintStockInvoice.dart';

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:saytarly/core/services/app_settings.dart';
import 'package:saytarly/Features/products/presentation/screens/drink_recipe.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:flutter/foundation.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/manage_drinks_mobile_body.dart';
part 'desktop/manage_drinks_windows_body.dart';

class ManageDrinksScreen extends StatefulWidget {
  /// القسم اللي بنشتغل جواه (من أقسام السوبر ادمن)
  final int? moduleId;
  final String? moduleName;

  const ManageDrinksScreen({super.key, this.moduleId, this.moduleName});

  @override
  State<ManageDrinksScreen> createState() => _ManageDrinksScreenState();
}

class _ManageDrinksScreenState extends State<ManageDrinksScreen> {
  List<DrinkModel> drinks = [];

  /// القوائم الفرعية للقسم (من إعدادات السوبر ادمن)
  List<Map<String, dynamic>> _categories = [];

  bool _cigarettesEnabled = false;
  bool _shishaEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadFeatureFlags();
    _load();
  }

  Future<void> _loadFeatureFlags() async {
    final cig = await AppSettings.getCigarettesEnabled();
    final shisha = await AppSettings.getShishaEnabled();
    if (!mounted) return;
    setState(() {
      _cigarettesEnabled = cig;
      _shishaEnabled = shisha;
    });
  }

  final bool isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// القوائم الفرعية الظاهرة (مع مراعاة تشغيل/إيقاف السجائر والشيشة)
  List<Map<String, dynamic>> get _visibleCategories => _categories.where((c) {
    final key = c['key'] as String? ?? '';
    if (key == 'cigarette' && !_cigarettesEnabled) return false;
    if (key == 'shisha' && !_shishaEnabled) return false;
    return (c['is_enabled'] ?? 1) == 1;
  }).toList();

  Future<void> _load() async {
    List<Map<String, dynamic>> rows;
    List<Map<String, dynamic>> cats = [];
    if (widget.moduleId != null) {
      rows = await DBHelper.getDrinksByModule(widget.moduleId!);
      cats = await DBHelper.getCategories(moduleId: widget.moduleId!);
    } else {
      rows = await DBHelper.getAllDrinks();
    }
    if (!mounted) return;
    setState(() {
      drinks = rows.map((r) => DrinkModel.fromMap(r)).toList();
      _categories = cats;
      selectedSections = {for (var s in sections) s: false};
    });
  }

  Future<void> exportDrinks(BuildContext context) async {
    try {
      final db = await DBHelper.database;

      final drinks = await db.query('drinks');
      final recipes = await db.query('drink_recipes');
      final materials = await db.query('raw_materials');

      final backup = {
        'drinks': drinks,
        'recipes': recipes,
        'materials': materials,
      };

      final jsonString = jsonEncode(backup);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ ملف الجرد'.tr(),
        fileName: 'drinks_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      print("Saved => $outputFile");
      if (outputFile == null) return;

      if (!outputFile.toLowerCase().endsWith('.json')) {
        outputFile = '$outputFile.json';
      }

      if (outputFile == null) return;

      final file = File(outputFile);
      await file.writeAsString(jsonString);

      AppToast.show('✅ تم تصدير المشروبات والوصفات والخامات'.tr());
    } catch (e) {
      AppToast.show('❌ فشل التصدير: {e}'.tr({'e': e}));
    }
  }

  /* Future<void> exportDrinks(BuildContext context) async {
    try {
      final rows = await DBHelper.getAllDrinks();

      final data = rows
          .map((e) => {
                'name': e['name'],
                'price': e['price'],
                'qty': e['qty'],
                'temperature': e['temperature'],
              })
          .toList();

      final jsonString = jsonEncode(data);

      // اختيار مكان الحفظ
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ ملف الجرد',
        fileName: 'drinks_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile == null) return;

      final file = File(outputFile);
      await file.writeAsString(jsonString);

      AppToast.show('✅ تم تصدير البيانات بنجاح');
    } catch (e) {
      AppToast.show('❌ فشل التصدير');
    }
  }
*/
  Future<void> showImportDialog(
    BuildContext context,
    VoidCallback reload,
  ) async {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: Text('استيراد البيانات'.tr()),
        content: Text('هل تريد استبدال البيانات الحالية أم الإضافة عليها؟'.tr()),
        actions: [
          TextButton(
            child: Text('إلغاء'.tr()),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('إضافة على الموجود'.tr()),
            onPressed: () {
              Navigator.pop(context);
              importDrinks(context, replace: false, reload: reload);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('استبدال الكل'.tr()),
            onPressed: () {
              Navigator.pop(context);
              importDrinks(context, replace: true, reload: reload);
            },
          ),
        ],
      ),
    );
  }

  Future<void> importDrinks(
    BuildContext context, {
    required bool replace,
    required VoidCallback reload,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final Map<String, dynamic> data = jsonDecode(jsonString);

      final db = await DBHelper.database;

      final List drinks = data['drinks'] ?? [];
      final List recipes = data['recipes'] ?? [];
      final List materials = data['materials'] ?? [];

      if (replace) {
        await db.delete('drink_recipes');
        await db.delete('drinks');
        await db.delete('raw_materials');
      }

      // الخامات
      for (final item in materials) {
        await db.insert(
          'raw_materials',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // المشروبات
      for (final item in drinks) {
        await db.insert(
          'drinks',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // الوصفات
      for (final item in recipes) {
        await db.insert(
          'drink_recipes',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      reload();

      AppToast.show('✅ تم استيراد المشروبات والخامات والوصفات'.tr());
    } catch (e) {
      print(e);

      AppToast.show('❌ فشل الاستيراد: {e}'.tr({'e': e}));
    }
  }
  /*
  Future<void> importDrinks(
    BuildContext context, {
    required bool replace,
    required VoidCallback reload,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final List data = jsonDecode(jsonString);

      if (replace) {
        await DBHelper.clearDrinks(); // ❗ تحتاج دالة مسح
      }

      for (final item in data) {
        final name = item['name'];
        final price = (item['price'] as num).toDouble();
        final qty = item['qty'];
        final temperature = item['temperature'];

        final existing = await DBHelper.getDrinkByUnique(
          name,
          price,
          temperature,
        );

        if (existing != null) {
          // 🔹 نفس المنتج → زوّد الكمية
          final newQty = (existing.qty + qty).toInt();

          await DBHelper.updateDrinkQty(existing.id!, newQty);
        } else {
          // 🔹 منتج جديد
          await DBHelper.insertDrink(
            DrinkModel(
              name: name,
              price: price,
              qty: qty,
              temperature: temperature,
            ),
          );
        }
      }

      reload();

      AppToast.show('✅ تم الاستيراد بنجاح');
    } catch (e) {
      AppToast.show('❌ فشل الاستيراد');
    }
  }
*/

  void _showStockReport() {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: Text('تقرير الجرد'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: drinks.map((c) {
              Color qtyColor;
              if (c.qty <= 0) {
                qtyColor = Colors.grey;
              } else if (c.qty < 10) {
                qtyColor = Colors.redAccent;
              } else {
                qtyColor = Colors.green;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: qtyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: qtyColor),
                      ),
                      child: Text(
                        '${c.qty}',
                        style: TextStyle(
                          color: qtyColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'.tr()),
          ),
        ],
      ),
    );
  }

  void _showForm({DrinkModel? edit}) {
    final cats = _visibleCategories;
    if (cats.isEmpty) {
      AppToast.show('القسم ده مفيهوش قوائم فرعية — ضيفها الأول من لوحة السوبر ادمن'.tr(),);
      return;
    }

    final nameCtl = TextEditingController(text: edit?.name ?? '');
    final priceCtl = TextEditingController(
      text: edit != null ? edit.price.toString() : '',
    );
    final qtyCtl = TextEditingController(
      text: edit != null ? edit.qty.toString() : '',
    );

    final catKeys = cats.map((c) => c['key'] as String? ?? '').toSet();
    String selectedTemp =
        edit?.temperature ?? (cats.first['key'] as String? ?? '');
    // لو المنتج متسجل على تصنيف قديم مش موجود في القوائم الحالية
    final uncategorized =
        edit != null &&
        edit.temperature.isNotEmpty &&
        !catKeys.contains(edit.temperature);

    showDialog(
      context: context,
      builder: (_) => AppDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding:  EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius:  BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                edit == null ? Icons.local_cafe : Icons.edit_note,
                color: Colors.white,
              ),
               SizedBox(width: 10),
              Text(
                edit == null ? 'إضافة منتج'.tr() : "تعديل منتج",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration:  InputDecoration(
                    labelText: 'اسم المنتج'.tr(),
                    prefixIcon: Icon(Icons.local_drink),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: priceCtl,
                  keyboardType: TextInputType.number,
                  decoration:  InputDecoration(
                    labelText: 'السعر'.tr(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: qtyCtl,
                  keyboardType: TextInputType.number,
                  decoration:  InputDecoration(
                    labelText: 'الكمية المتاحة'.tr(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedTemp.isEmpty ? null : selectedTemp,
                  decoration:  InputDecoration(
                    labelText: 'القائمة الفرعية'.tr(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  borderRadius: BorderRadius.circular(15),
                  items: [
                    for (final c in cats)
                      DropdownMenuItem(
                        value: c['key'] as String? ?? '',
                        child: Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(c['name'] as String? ?? ''),
                          ],
                        ),
                      ),
                    if (uncategorized)
                      DropdownMenuItem(
                        value: edit!.temperature,
                        child:  Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.grey),
                            SizedBox(width: 10),
                            Text('غير مصنف (تصنيف قديم)'.tr()),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => selectedTemp = v ?? '',
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(15),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.close),
            label:  Text('إلغاء'.tr()),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label:  Text('حفظ'.tr()),
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 45)),
            onPressed: () async {
              final n = nameCtl.text.trim();
              final p = double.tryParse(priceCtl.text.trim()) ?? 0;
              final q = int.tryParse(qtyCtl.text.trim()) ?? 0;

              if (n.isEmpty || selectedTemp.isEmpty) {
                AppToast.show('اكتب اسم المنتج واختار القائمة'.tr());
                return;
              }

              if (edit == null) {
                await DBHelper.insertDrink(
                  DrinkModel(
                    name: n,
                    price: p,
                    qty: q,
                    temperature: selectedTemp,
                    moduleId: widget.moduleId,
                  ),
                );
              } else {
                edit.name = n;
                edit.price = p;
                edit.qty = q;
                edit.temperature = selectedTemp;
                if (widget.moduleId != null) {
                  edit.moduleId = widget.moduleId;
                }

                await DBHelper.updateDrink(edit);
              }

              Navigator.pop(context);
              _load();
            },
          ),
        ],
      ),
    );
  }

  /*  void _showForm({DrinkModel? edit}) {
    final nameCtl = TextEditingController(text: edit?.name ?? '');
    final priceCtl = TextEditingController(
      text: edit != null ? edit.price.toString() : '',
    );
    final qtyCtl = TextEditingController(
      text: edit != null ? edit.qty.toString() : '',
    );

    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: Text(edit == null ? 'إضافة مشروب' : 'تعديل مشروب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: InputDecoration(labelText: 'اسم المشروب'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: priceCtl,
              decoration: InputDecoration(labelText: 'السعر'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: qtyCtl,
              decoration: InputDecoration(labelText: 'الكمية المتاحة'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final n = nameCtl.text.trim();
              final p = double.tryParse(priceCtl.text.trim()) ?? 0;
              final q = int.tryParse(qtyCtl.text.trim()) ?? 0;

              if (edit == null) {
                await DBHelper.insertDrink(
                    DrinkModel(name: n, price: p, qty: q));
              } else {
                edit.name = n;
                edit.price = p;
                edit.qty = q;
                await DBHelper.updateDrink(edit);
              }
              Navigator.pop(context);
              _load();
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }*/
  List<String> get sections =>
      _visibleCategories.map((c) => c['key'] as String? ?? '').toList();

  // تسميات العرض بالعربي — بتيجي ديناميك من إعدادات السوبر ادمن
  Map<String, String> get sectionNames => {
    for (final c in _visibleCategories)
      (c['key'] as String? ?? ''): c['name'] as String? ?? '',
  };

  Map<String, bool> selectedSections = {};

  void _showPrintSectionDialog() {
    if (sections.isEmpty) {
      AppToast.show('مفيش قوائم فرعية في القسم ده — ضيفها من لوحة السوبر ادمن'.tr());
      return;
    }
    // إعادة تهيئة الأقسام قبل كل مرة
    selectedSections = {for (var s in sections) s: false};

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AppDialog(
          title: Text('اختر الأقسام للطباعة'.tr()),
          content: SingleChildScrollView(
            child: Column(
              children: sections.map((s) {
                return CheckboxListTile(
                  title: Text(sectionNames[s]!),
                  value: selectedSections[s],
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedSections[s] = val ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                final selected = sections
                    .where((s) => selectedSections[s] == true)
                    .toList();

                if (selected.isEmpty) {
                  AppToast.show('❌ اختر قسم واحد على الأقل'.tr());
                  return;
                }

                // تصفية المشروبات حسب الأقسام المحددة
                final drinksToPrint = drinks
                    .where((d) => selected.contains(d.temperature))
                    .toList();

                PrintStockInvoice.printStockInvoice(drinksToPrint);

                Navigator.pop(context);
              },
              child: Text('طباعة'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  /// المنتج المحدد — نفس اختيار الموبايل، وبيستخدمه الويندوز كمان.
  int? selectedDrinkId;

  /// بحث وفلتر القوائم الفرعية — واجهة الويندوز.
  String _searchQuery = '';
  String? _selectedCategoryKey;

  /// إعادة بناء الشاشة من ملفات الجسم المنفصلة (mobile / windows).
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
