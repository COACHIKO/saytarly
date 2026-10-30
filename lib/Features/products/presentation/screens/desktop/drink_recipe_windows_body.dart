part of '../drink_recipe.dart';

/// جسم وصفة المشروب — نسخة الويندوز (Windows UI).
///
/// نفس المنطق: الوصفة الحالية + الخامات المتاحة، وبنفس الـ callbacks
/// (إضافة خامة للوصفة / حذف بند من الوصفة / إعادة تحميل).
extension _DrinkRecipeScreenWindowsBody on _DrinkRecipeScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'وصفة المشروب'.tr(),
      subtitle:
          ('الخامات المستخدمة: {v1} • '.tr({'v1': recipeItems.length}) +
              'الخامات المتاحة: {v1}'.tr({'v1': materials.length})),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () {
            loadMaterials();
            loadRecipe();
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== الوصفة الحالية ====================
          DesktopSectionTitle(
            title: 'الوصفة الحالية'.tr(),
            count: recipeItems.length,
          ),
          if (recipeItems.isEmpty)
            DesktopEmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: 'لا توجد خامات مضافة لهذا المشروب'.tr(),
              message: 'اختار خامة من "الخامات المتاحة" تحت وحدد الكمية.'.tr(),
            )
          else
            DesktopCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < recipeItems.length; i++) ...[
                    if (i > 0)
                      Divider(
                        color: palette.border,
                        height: DesktopTokens.gapLg,
                      ),
                    _windowsRecipeRow(palette, recipeItems[i]),
                  ],
                ],
              ),
            ),
          SizedBox(height: DesktopTokens.gapXl),

          // ==================== الخامات المتاحة ====================
          DesktopSectionTitle(
            title: 'الخامات المتاحة'.tr(),
            count: materials.length,
          ),
          if (materials.isEmpty)
            DesktopEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'مفيش خامات مسجلة'.tr(),
              message: 'ضيف الخامات الأول من شاشة إدارة الخامات.'.tr(),
            )
          else
            DesktopResponsiveGrid(
              minTileWidth: 250,
              maxColumns: 4,
              children: [
                for (final m in materials) _windowsMaterialCard(palette, m),
              ],
            ),
        ],
      ),
    );
  }

  /// صف بند في الوصفة — اسم + كمية/وحدة + حذف.
  Widget _windowsRecipeRow(DesktopPalette palette, Map<String, dynamic> item) {
    return Row(
      children: [
        DesktopIconBadge(
          icon: Icons.check_circle_outline,
          color: palette.success,
          size: 36,
        ),
        const SizedBox(width: DesktopTokens.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['name'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item['qty']} ${item['unit']}',
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
            ],
          ),
        ),
        _windowsIconAction(
          icon: Icons.delete_outline,
          tooltip: 'حذف من الوصفة'.tr(),
          color: palette.danger,
          onTap: () => deleteRecipeItem(item['id']),
        ),
      ],
    );
  }

  /// كارت خامة متاحة — الاسم + المخزون + زرار إضافة.
  Widget _windowsMaterialCard(DesktopPalette palette, Map<String, dynamic> m) {
    return DesktopCard(
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DesktopIconBadge(
                icon: Icons.inventory_2_outlined,
                color: palette.info,
                size: 38,
              ),
              const SizedBox(width: DesktopTokens.gapMd),
              Expanded(
                child: Text(
                  m['name'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          Text(
            'المخزون: {v1} {v2}'.tr({'v1': m['qty'], 'v2': m['unit']}),
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DesktopButton.primary(
              label: 'إضافة'.tr(),
              icon: Icons.add,
              onPressed: () => addRecipeMaterial(m['id'], m['name'], m['unit']),
            ),
          ),
        ],
      ),
    );
  }

  /// زرار أيقونة صغير بهوفر ناعم.
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hovering ? palette.surfaceSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                border: Border.all(
                  color: hovering ? palette.border : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                size: 17,
                color: color ?? palette.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}
