part of '../manage_drinks.dart';

/// جسم إدارة المنتجات — نسخة الويندوز (Windows UI).
///
/// شريط قوائم فرعية (Segmented) + شبكة منتجات بكروت hover، وكل إجراء
/// بيستخدم نفس الـ callbacks بتاعة الموبايل (إضافة / تعديل / حذف / وصفة /
/// زيادة كمية / تصدير / استيراد / طباعة).
extension _ManageDrinksScreenWindowsBody on _ManageDrinksScreenState {
  static const String _windowsAllKey = '__all__';
  static const String _windowsOtherKey = '__other__';

  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final cats = _visibleCategories;
    final catKeys = cats.map((c) => c['key'] as String? ?? '').toSet();
    final uncategorized = drinks
        .where((d) => !catKeys.contains(d.temperature))
        .toList();
    final hasOther = uncategorized.isNotEmpty;

    // الفلتر المختار — لو القسم اتقفل من السوبر ادمن بنرجع لـ "الكل".
    var selected = _selectedCategoryKey;
    if (selected != null &&
        selected != _windowsAllKey &&
        selected != _windowsOtherKey &&
        !catKeys.contains(selected)) {
      selected = null;
    }

    final query = _searchQuery.trim().toLowerCase();
    List<DrinkModel> visible;
    if (selected == null || selected == _windowsAllKey) {
      visible = drinks;
    } else if (selected == _windowsOtherKey) {
      visible = uncategorized;
    } else {
      visible = drinks.where((d) => d.temperature == selected).toList();
    }
    if (query.isNotEmpty) {
      visible = visible
          .where((d) => d.name.toLowerCase().contains(query))
          .toList();
    }

    final lowStockCount = drinks.where((d) => d.qty > 0 && d.qty < 10).length;
    final outOfStockCount = drinks.where((d) => d.qty <= 0).length;

    return DesktopPageScaffold(
      title: widget.moduleName != null
          ? 'إدارة {v1}'.tr({'v1': widget.moduleName})
          : 'إدارة المشروبات',
      subtitle: '{v1} قائمة فرعية • {v2} منتج'.tr({'v1': cats.length, 'v2': drinks.length}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.upload_outlined,
          tooltip: 'نسخة احتياطية'.tr(),
          onPressed: () => exportDrinks(context),
        ),
        DesktopToolbarIconButton(
          icon: Icons.download_outlined,
          tooltip: 'استعادة نسخة'.tr(),
          onPressed: () => showImportDialog(context, _load),
        ),
        DesktopToolbarIconButton(
          icon: Icons.print_outlined,
          tooltip: 'طباعة حسب القسم'.tr(),
          onPressed: _showPrintSectionDialog,
        ),
        DesktopButton.primary(
          label: 'إضافة منتج'.tr(),
          icon: Icons.add,
          onPressed: _showForm,
        ),
      ],
      headerBottom: Row(
        children: [
          if (cats.isNotEmpty)
            DesktopSegmented<String>(
              items: [
                DesktopSegmentItem<String>(
                  value: _windowsAllKey,
                  label: 'الكل'.tr(),
                  icon: Icons.apps_rounded,
                ),
                for (final c in cats)
                  DesktopSegmentItem<String>(
                    value: c['key'] as String? ?? '',
                    label: c['name'] as String? ?? '',
                  ),
                if (hasOther)
                  DesktopSegmentItem<String>(
                    value: _windowsOtherKey,
                    label: 'أخرى'.tr(),
                    icon: Icons.help_outline,
                  ),
              ],
              value: selected ?? _windowsAllKey,
              onChanged: (v) => _refresh(
                () => _selectedCategoryKey = v == _windowsAllKey ? null : v,
              ),
            ),
          const Spacer(),
          DesktopSearchField(
            hint: 'ابحث عن منتج...'.tr(),
            onChanged: (v) => _refresh(() => _searchQuery = v),
          ),
        ],
      ),
      child: cats.isEmpty
          ? _windowsEmptyCategoriesNote()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopResponsiveGrid(
                  minTileWidth: 240,
                  maxColumns: 3,
                  children: [
                    DesktopStatCard(
                      label: 'إجمالي المنتجات'.tr(),
                      value: '${drinks.length}',
                      icon: Icons.local_cafe_outlined,
                      color: palette.accent,
                      hint: widget.moduleName,
                    ),
                    DesktopStatCard(
                      label: 'مخزون قليل (أقل من 10)'.tr(),
                      value: '$lowStockCount',
                      icon: Icons.warning_amber_rounded,
                      color: palette.warning,
                    ),
                    DesktopStatCard(
                      label: 'نفد من المخزون'.tr(),
                      value: '$outOfStockCount',
                      icon: Icons.remove_shopping_cart_outlined,
                      color: palette.danger,
                    ),
                  ],
                ),
                const SizedBox(height: DesktopTokens.gapLg),
                if (visible.isEmpty)
                  DesktopEmptyState(
                    icon: Icons.search_off,
                    title: 'لا توجد منتجات هنا'.tr(),
                    message: query.isNotEmpty
                        ? 'جرّب كلمة بحث تانية أو اختار قائمة فرعية تانية.'.tr()
                        : 'ضيف أول منتج للقائمة دي.',
                    action: DesktopButton.primary(
                      label: 'إضافة منتج'.tr(),
                      icon: Icons.add,
                      onPressed: _showForm,
                    ),
                  )
                else
                  DesktopResponsiveGrid(
                    minTileWidth: 260,
                    maxColumns: 5,
                    children: [
                      for (final c in visible)
                        _windowsDrinkCard(
                          context,
                          palette,
                          c,
                          _sectionLabel(c),
                        ),
                    ],
                  ),
                const SizedBox(height: DesktopTokens.gapLg),
              ],
            ),
    );
  }

  /// اسم القائمة الفرعية بالعربي — نفس sectionNames بتاعة الموبايل.
  String _sectionLabel(DrinkModel c) {
    final name = sectionNames[c.temperature] ?? c.temperature;
    return name.isEmpty ? 'أخرى'.tr() : name;
  }

  /// كارت منتج — اسم / سعر / قائمة فرعية + إجراءات سريعة بنفس منطق الموبايل.
  Widget _windowsDrinkCard(
    BuildContext context,
    DesktopPalette palette,
    DrinkModel c,
    String sectionLabel,
  ) {
    final theme = Theme.of(context);
    final qtyColor = c.qty <= 0
        ? palette.textMuted
        : (c.qty < 10 ? palette.danger : palette.success);

    return DesktopCard(
      hover: true,
      selected: selectedDrinkId == c.id,
      onTap: () => _refresh(() {
        selectedDrinkId = selectedDrinkId == c.id ? null : c.id;
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DesktopIconBadge(
                icon: Icons.local_cafe_outlined,
                color: palette.accent,
              ),
              const SizedBox(width: DesktopTokens.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sectionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              DesktopInfoChip(
                label: '${c.qty}',
                icon: c.qty <= 0 ? Icons.block : Icons.inventory_2_outlined,
                color: qtyColor,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          Row(
            children: [
              Text(
                '${c.price.toStringAsFixed(2)} ${Money.txt}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: palette.accentText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _windowsIconAction(
                icon: Icons.restaurant_menu_outlined,
                tooltip: 'الوصفة'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DrinkRecipeScreen(drinkId: c.id!),
                  ),
                ),
              ),
              _windowsIconAction(
                icon: Icons.add_circle_outline,
                tooltip: 'زيادة الكمية'.tr(),
                onTap: () => _windowsAddQtyDialog(c),
              ),
              _windowsIconAction(
                icon: Icons.edit_outlined,
                tooltip: 'تعديل'.tr(),
                onTap: () => _showForm(edit: c),
              ),
              _windowsIconAction(
                icon: Icons.delete_outline,
                tooltip: 'حذف'.tr(),
                color: palette.danger,
                onTap: () async {
                  await DBHelper.deleteDrink(c.id!);
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// نفس ديالوج "زيادة الكمية" بتاع الموبايل — بنفس الـ DB call.
  Future<void> _windowsAddQtyDialog(DrinkModel c) async {
    final qtyController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AppDialog(
        title:  Text('زيادة الكمية'.tr()),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration:  InputDecoration(
            labelText: 'ادخل العدد'.tr(),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final addedQty = int.tryParse(qtyController.text.trim());
              if (addedQty != null && addedQty > 0) {
                final newQty = c.qty + addedQty;
                await DBHelper.updateDrinkQty(c.id!, newQty);
                _load();
              }
              navigator.pop();
            },
            child:  Text('تأكيد'.tr()),
          ),
        ],
      ),
    );
  }

  /// القسم لسه مفيهوش قوائم فرعية — نفس رسالة الموبايل.
  Widget _windowsEmptyCategoriesNote() {
    return  DesktopEmptyState(
      icon: Icons.category_outlined,
      title: 'القسم ده لسه مفيهوش قوائم فرعية (زي: سخن/بارد)'.tr(),
      message: ('روح للوحة السوبر ادمن → أقسام المنتجات → افتح القسم '.tr() + 'وضيف القوائم.'.tr()),
    );
  }

  /// زرار أيقونة صغير مناسب لجوّه الكروت — بهوفر ناعم.
  Widget _windowsIconAction({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: HoverBuilder(
        builder: (context, hovering) {
          final palette = DesktopPalette.of(context);
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: DesktopTokens.fast,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: hovering ? palette.surfaceSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm - 2),
                border: Border.all(
                  color: hovering ? palette.border : Colors.transparent,
                ),
              ),
              child: Icon(icon, size: 16, color: color ?? palette.textSecondary),
            ),
          );
        },
      ),
    );
  }
}
