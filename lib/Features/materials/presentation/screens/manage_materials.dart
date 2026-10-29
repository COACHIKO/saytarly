import 'package:saytarly/Features/materials/presentation/print/materials_print.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/Features/materials/presentation/screens/MaterialsInventoryScreen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/manage_materials_mobile_body.dart';
part 'desktop/manage_materials_windows_body.dart';

/// الخامات مخزون مشترك لكل الأقسام
class ManageMaterialsScreen extends StatefulWidget {
  const ManageMaterialsScreen({super.key});

  @override
  State<ManageMaterialsScreen> createState() => _ManageMaterialsScreenState();
}

class _ManageMaterialsScreenState extends State<ManageMaterialsScreen> {
  List<Map<String, dynamic>> materials = [];

  Future<void> load() async {
    await DBHelper.cleanupAllMaterialQuantities(); // ✅ ينضف الأول
    final db = await DBHelper.database;
    // 🆕 الخامات مشتركة — بتتعرض كلها مهما كان القسم
    materials = await db.query('raw_materials', orderBy: 'name');

    setState(() {});
  }

  Future<void> exportMaterials(BuildContext context) async {
    try {
      final db = await DBHelper.database;

      final materials = await db.query('raw_materials');

      final jsonString = jsonEncode(materials);

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ نسخة احتياطية'.tr(),
        fileName: 'Matrials_drinks.json',
      );

      if (outputPath == null) return;

      if (!outputPath.toLowerCase().endsWith('.json')) {
        outputPath = '$outputPath.json';
      }

      final file = File(outputPath);
      await file.writeAsString(jsonString);

      AppToast.show('✅ تم تصدير الخامات بنجاح'.tr());
    } catch (e) {
      AppToast.show('❌ فشل التصدير: {e}'.tr({'e': e}));
    }
  }

  Future<void> importMaterials(
    BuildContext context, {
    required bool replace,
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

      final db = await DBHelper.database;

      if (replace) {
        await db.delete('drink_recipes');
        await db.delete('raw_materials');
      }

      for (final item in data) {
        await db.insert(
          'raw_materials',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await load();

      AppToast.show('✅ تم استيراد الخامات بنجاح'.tr());
    } catch (e) {
      AppToast.show('❌ فشل الاستيراد: {e}'.tr({'e': e}));
    }
  }

  Future<void> showImportMaterialsDialog() async {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title:  Text('استيراد الخامات'.tr()),
        content:  Text(
          'هل تريد استبدال الخامات الحالية أم الإضافة عليها؟'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              importMaterials(context, replace: false);
            },
            child:  Text('إضافة'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              importMaterials(context, replace: true);
            },
            child:  Text('استبدال'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> deleteMaterial(int id) async {
    final db = await DBHelper.database;

    // حذف الخامة من كل الوصفات
    await db.delete('drink_recipes', where: 'material_id = ?', whereArgs: [id]);

    // حذف الخامة نفسها
    await db.delete('raw_materials', where: 'id = ?', whereArgs: [id]);

    await load();
  }

  // 🆕 طباعة جرد كل الخامات المسجلة
  Future<void> _printMaterialsInventory() async {
    if (materials.isEmpty) {
      AppToast.show('لا توجد خامات لطباعتها'.tr());
      return;
    }

    await printMaterialsInventoryReport(materials);
  }

  Future<void> addOrEditMaterial({Map<String, dynamic>? material}) async {
    final name = TextEditingController(text: material?['name'] ?? '');

    final qty = TextEditingController(text: material?['qty']?.toString() ?? '');

    final minQty = TextEditingController(
      text: material?['min_qty']?.toString() ?? '',
    );

    final cost = TextEditingController(
      text: material?['cost']?.toString() ?? '',
    );

    // 📐 وحدات الخامات من إعدادات النشاط — بديل القائمة الثابتة
    final units = await BusinessProfile.getUnits();
    final unitNames = [for (final u in units) u.name];
    final savedUnit = material?['unit'] as String?;
    String selectedUnit = (savedUnit != null && unitNames.contains(savedUnit))
        ? savedUnit
        : unitNames.first;

    await showDialog(
      context: context,
      builder: (_) => AppDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding:  EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:  BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
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
               Icon(Icons.inventory_2, color: Colors.white),
               SizedBox(width: 10),
              Text(
                material == null ? 'إضافة خامة'.tr() : "تعديل خامة",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration:  InputDecoration(
                    labelText: 'اسم الخامة'.tr(),
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration:  InputDecoration(
                    labelText: 'الكمية الحالية'.tr(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration:  InputDecoration(
                    labelText: 'الوحدة'.tr(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  items: [
                    for (final u in unitNames)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (v) => selectedUnit = v!,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: minQty,
                  keyboardType: TextInputType.number,
                  decoration:  InputDecoration(
                    labelText: 'الحد الأدنى'.tr(),
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  decoration:  InputDecoration(
                    labelText: 'سعر الشراء'.tr(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(15),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label:  Text('إلغاء'.tr()),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label:  Text('حفظ'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: () async {
              final db = await DBHelper.database;

              final Map<String, dynamic> data = {
                'name': name.text,
                'qty': double.tryParse(qty.text) ?? 0,
                'unit': selectedUnit,
                'min_qty': double.tryParse(minQty.text) ?? 0,
                'cost': double.tryParse(cost.text) ?? 0,
              };

              if (material == null) {
                await db.insert('raw_materials', data);
              } else {
                await db.update(
                  'raw_materials',
                  data,
                  where: 'id=?',
                  whereArgs: [material['id']],
                );
              }

              Navigator.pop(context);
              load();
            },
          ),
        ],
      ),
    );
  }

  /// بحث إدارة الخامات — واجهة الويندوز.
  String _searchQuery = '';

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

class MaterialModel {
  int? id;
  String name;
  double qty;
  String unit;
  double minQty;
  double cost;

  MaterialModel({
    this.id,
    required this.name,
    required this.qty,
    required this.unit,
    required this.minQty,
    required this.cost,
  });

  factory MaterialModel.fromMap(Map<String, dynamic> m) {
    return MaterialModel(
      id: m['id'],
      name: m['name'],
      qty: (m['qty'] as num).toDouble(),
      unit: m['unit'],
      minQty: (m['min_qty'] as num).toDouble(),
      cost: (m['cost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'qty': qty,
    'unit': unit,
    'min_qty': minQty,
    'cost': cost,
  };
}
