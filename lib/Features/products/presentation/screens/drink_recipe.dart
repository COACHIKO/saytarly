import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/drink_recipe_mobile_body.dart';
part 'desktop/drink_recipe_windows_body.dart';

class DrinkRecipeScreen extends StatefulWidget {
  final int drinkId;

  const DrinkRecipeScreen({super.key, required this.drinkId});

  @override
  State<DrinkRecipeScreen> createState() => _DrinkRecipeScreenState();
}

class _DrinkRecipeScreenState extends State<DrinkRecipeScreen> {
  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> recipeItems = [];

  @override
  void initState() {
    super.initState();
    loadMaterials();
    loadRecipe();
  }

  Future<void> loadMaterials() async {
    final db = await DBHelper.database;

    final rows = await db.query('raw_materials', orderBy: 'name');

    if (!mounted) return;
    setState(() {
      materials = rows;
    });
  }

  Future<void> loadRecipe() async {
    final db = await DBHelper.database;

    final rows = await db.rawQuery(
      '''
      SELECT
      dr.id,
      dr.qty,
      rm.name,
      rm.unit
      FROM drink_recipes dr
      INNER JOIN raw_materials rm
      ON rm.id = dr.material_id
      WHERE dr.drink_id = ?
    ''',
      [widget.drinkId],
    );

    if (!mounted) return;
    setState(() {
      recipeItems = rows;
    });
  }

  Future<void> deleteRecipeItem(int id) async {
    final db = await DBHelper.database;

    await db.delete('drink_recipes', where: 'id=?', whereArgs: [id]);

    loadRecipe();
  }

  Future<void> addRecipeMaterial(
    int materialId,
    String materialName,
    String baseUnit,
  ) async {
    final qtyCtl = TextEditingController();

    String selectedUnit =
        baseUnit == "كيلو"
            ? 'جرام'.tr()
            : baseUnit == "لتر"
            ? 'ملي'.tr()
            : "قطعة";

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return AppDialog(
                title: Text(
                  'إضافة {materialName}'.tr({'materialName': materialName}),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: qtyCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'الكمية المستخدمة'.tr(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      items: [
                        if (baseUnit == "كيلو")
                          DropdownMenuItem(
                            value: 'جرام'.tr(),
                            child: Text('جرام'.tr()),
                          ),
                        if (baseUnit == "كيلو")
                          DropdownMenuItem(
                            value: 'كيلو'.tr(),
                            child: Text('كيلو'.tr()),
                          ),
                        if (baseUnit == "لتر")
                          DropdownMenuItem(
                            value: 'ملي'.tr(),
                            child: Text('ملي'.tr()),
                          ),
                        if (baseUnit == "لتر")
                          DropdownMenuItem(
                            value: 'لتر'.tr(),
                            child: Text('لتر'.tr()),
                          ),
                        if (baseUnit == "قطعة")
                          DropdownMenuItem(
                            value: 'قطعة'.tr(),
                            child: Text('قطعة'.tr()),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          selectedUnit = v!;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      double qty = double.tryParse(qtyCtl.text.trim()) ?? 0;

                      if (qty <= 0) return;

                      // تحويل للوحدة الأساسية للمخزون
                      if (baseUnit == "كيلو" && selectedUnit == "جرام") {
                        qty = qty / 1000;
                      }

                      if (baseUnit == "لتر" && selectedUnit == "ملي") {
                        qty = qty / 1000;
                      }

                      // ✅ تقريب النتيجة لـ 6 خانات عشرية عشان نتخلص من غبار القسمة
                      qty = double.parse(qty.toStringAsFixed(6));
                      final db = await DBHelper.database;

                      await db.insert('drink_recipes', {
                        'drink_id': widget.drinkId,
                        'material_id': materialId,
                        'qty': qty,
                      });

                      Navigator.pop(context);
                      loadRecipe();
                    },
                    child: Text('حفظ'.tr()),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
