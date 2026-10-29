part of '../manage_drinks.dart';

/// جسم إدارة المنتجات — نسخة الموبايل (زي ما كانت بالظبط).
extension _ManageDrinksScreenMobileBody on _ManageDrinksScreenState {

  Widget _buildMobileBody(BuildContext context) {
    final cats = _visibleCategories;
    final catKeys = cats.map((c) => c['key'] as String? ?? '').toSet();
    final uncategorized = drinks
        .where((d) => !catKeys.contains(d.temperature))
        .toList();
    final hasOther = uncategorized.isNotEmpty;
    final tabCount = cats.length + (hasOther ? 1 : 0);

    return DefaultTabController(
      length: tabCount == 0 ? 1 : tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.moduleName != null
                ? 'إدارة {v1}'.tr({'v1': widget.moduleName})
                : 'إدارة المشروبات',
          ),
          bottom: tabCount == 0
              ? null
              : TabBar(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  indicatorColor: Colors.transparent,
                  indicatorWeight: 0,
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Color(0xFF6FCF97),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  isScrollable: tabCount > 4,
                  tabs: [
                    for (final c in cats) Tab(text: c['name'] as String? ?? ''),
                    if (hasOther)  Tab(text: 'أخرى'.tr()),
                  ],
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.upload, size: isMobile ? 22 : 18),
              tooltip: 'نسخة احتياطية'.tr(),
              onPressed: () => exportDrinks(context),
            ),

            IconButton(
              icon: Icon(Icons.download, size: isMobile ? 22 : 18),
              tooltip: 'استعادة نسخة'.tr(),
              onPressed: () => showImportDialog(context, _load),
            ),

            IconButton(
              icon: Icon(Icons.print, size: isMobile ? 22 : 18),
              tooltip: 'طباعة حسب القسم'.tr(),
              onPressed: _showPrintSectionDialog,
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 8),
              child: TextButton.icon(
                onPressed: _showForm,
                icon: Icon(Icons.add, size: isMobile ? 20 : 18),
                label: Text(
                  'إضافة'.tr(),
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 6,
                    vertical: isMobile ? 8 : 4,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: tabCount == 0
            ? _buildEmptyCategoriesHint()
            : TabBarView(
                children: [
                  for (final c in cats)
                    _buildDrinkList(
                      drinks
                          .where(
                            (d) =>
                                d.temperature == (c['key'] as String? ?? ''),
                          )
                          .toList(),
                    ),
                  if (hasOther) _buildDrinkList(uncategorized),
                ],
              ),
      ),
    );
  }

  /// القسم لسه مفيهوش قوائم فرعية
  Widget _buildEmptyCategoriesHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  [
            Icon(Icons.category_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 14),
            Text(
              ('القسم ده لسه مفيهوش قوائم فرعية (زي: سخن/بارد).\n'.tr() + 'روح للوحة السوبر ادمن → أقسام المنتجات → افتح القسم وضيف القوائم.'.tr()),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDrinkList(List<DrinkModel> drinkList) {
    if (drinkList.isEmpty) {
      return Center(child: Text('لا توجد مشروبات في هذا القسم'.tr()));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: drinkList.length,
        itemBuilder: (_, i) {
          final c = drinkList[i];

          // ✅ تحديد إذا العنصر محدد
          final isSelected = c.id == selectedDrinkId;
          final bgColor = isSelected
              ? Colors.deepPurple.shade100
              : Theme.of(context).cardColor;

          Color qtyColor;
          if (c.qty <= 0) {
            qtyColor = Colors.grey;
          } else if (c.qty < 10) {
            qtyColor = Colors.red;
          } else if (c.qty < 20) {
            qtyColor = Colors.green;
          } else {
            qtyColor = Colors.green;
          }

          return Card(
            color: bgColor, // 🎯 هنا نغير لون الخلفية
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              textColor: qtyColor,
              title: Text(c.name),
              subtitle: Text('السعر: {v1} | الكمية: {v2}'.tr({'v1': c.price, 'v2': c.qty})),
              onTap: () {
                _refresh(() {
                  if (selectedDrinkId == c.id) {
                    selectedDrinkId = null; // إلغاء الاختيار لو ضغت مرة ثانية
                  } else {
                    selectedDrinkId = c.id;
                  }
                });
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restaurant_menu),
                    tooltip: 'الوصفة'.tr(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DrinkRecipeScreen(drinkId: c.id!),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.green),
                    tooltip: 'زيادة الكمية'.tr(),
                    onPressed: () {
                      final qtyController = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (_) => AppDialog(
                          title: Text('زيادة الكمية'.tr()),
                          content: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'ادخل العدد'.tr(),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('إلغاء'.tr()),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final addedQty = int.tryParse(
                                  qtyController.text.trim(),
                                );
                                if (addedQty != null && addedQty > 0) {
                                  final newQty = (c.qty ?? 0) + addedQty;
                                  await DBHelper.updateDrinkQty(c.id!, newQty);
                                  _load();
                                }
                                Navigator.pop(context);
                              },
                              child: Text('تأكيد'.tr()),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showForm(edit: c),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await DBHelper.deleteDrink(c.id!);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

