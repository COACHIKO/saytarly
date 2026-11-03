part of '../manage_materials.dart';

/// جسم إدارة الخامات — نسخة الويندوز (Windows UI).
///
/// مؤشرات (إجمالي / ناقص / متوفر) + بحث + جدول خامات بكروت hover،
/// وكل إجراء بيستخدم نفس الـ callbacks بتاعة الموبايل (إضافة / تعديل /
/// حذف / طباعة / تصدير / استيراد / الاستهلاك).
extension _ManageMaterialsScreenWindowsBody on _ManageMaterialsScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final query = _searchQuery.trim().toLowerCase();
    final visible =
        query.isEmpty
            ? materials
            : materials
                .where(
                  (m) => (m['name'] as String? ?? '').toLowerCase().contains(
                    query,
                  ),
                )
                .toList();

    final totalMaterials = materials.length;
    final lowStockCount =
        materials.where((e) {
          return (e['qty'] as num) <= (e['min_qty'] as num);
        }).length;
    final availableCount = totalMaterials - lowStockCount;

    return DesktopPageScaffold(
      title: 'إدارة الخامات'.tr(),
      subtitle: 'إجمالي الأصناف: {totalMaterials}'.tr({
        'totalMaterials': totalMaterials,
      }),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () async {
            await load(); // ✅ التنظيف بقى جواها تلقائيًا
            if (!mounted) return;
            AppToast.show('✅ تم تحديث البيانات'.tr());
          },
        ),
        DesktopToolbarIconButton(
          icon: Icons.print_outlined,
          tooltip: 'طباعة جرد الخامات'.tr(),
          onPressed: _printMaterialsInventory,
        ),
        DesktopToolbarIconButton(
          icon: Icons.upload_outlined,
          tooltip: 'نسخة احتياطية'.tr(),
          onPressed: () => exportMaterials(context),
        ),
        DesktopToolbarIconButton(
          icon: Icons.download_outlined,
          tooltip: 'استعادة نسخة'.tr(),
          onPressed: showImportMaterialsDialog,
        ),
        DesktopToolbarIconButton(
          icon: Icons.coffee_maker,
          tooltip: 'الاستهلاك'.tr(),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MaterialsInventoryScreen()),
            );
            load();
          },
        ),
        DesktopButton.primary(
          label: 'إضافة خامة'.tr(),
          icon: Icons.add,
          onPressed: () => addOrEditMaterial(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات ====================
          DesktopResponsiveGrid(
            minTileWidth: 220,
            maxColumns: 3,
            children: [
              DesktopStatCard(
                label: 'إجمالي الخامات'.tr(),
                value: '$totalMaterials',
                icon: Icons.inventory_2_outlined,
                color: palette.info,
                hint: 'خامات مشتركة بين كل الأقسام'.tr(),
              ),
              DesktopStatCard(
                label: 'خامات ناقصة'.tr(),
                value: '$lowStockCount',
                icon: Icons.warning_amber_rounded,
                color: palette.danger,
                hint: 'وصلت للحد الأدنى أو أقل'.tr(),
              ),
              DesktopStatCard(
                label: 'خامات متوفرة'.tr(),
                value: '$availableCount',
                icon: Icons.check_circle_outline,
                color: palette.success,
                hint: 'فوق الحد الأدنى'.tr(),
              ),
            ],
          ),
          SizedBox(height: DesktopTokens.gapLg),

          // ==================== قائمة الخامات ====================
          DesktopSectionTitle(
            title: 'كل الخامات'.tr(),
            count: visible.length,
            trailing: DesktopSearchField(
              hint: 'ابحث باسم الخامة...'.tr(),
              onChanged: (v) => _refresh(() => _searchQuery = v),
            ),
          ),
          if (materials.isEmpty)
            DesktopEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'مفيش خامات مسجلة'.tr(),
              message: 'ضيف أول خامة عشان تبدأ تتابع المخزون.'.tr(),
              action: DesktopButton.primary(
                label: 'إضافة خامة'.tr(),
                icon: Icons.add,
                onPressed: () => addOrEditMaterial(),
              ),
            )
          else if (visible.isEmpty)
            DesktopEmptyState(
              icon: Icons.search_off,
              title: 'مفيش نتائج للبحث'.tr(),
              message: 'جرّب اسم تاني أو امسح كلمة البحث.'.tr(),
            )
          else ...[
            _windowsTableHeader(palette),
            const SizedBox(height: DesktopTokens.gapSm),
            for (final m in visible) ...[
              _windowsMaterialRow(palette, m),
              const SizedBox(height: DesktopTokens.gapSm),
            ],
          ],
          const SizedBox(height: DesktopTokens.gapLg),
        ],
      ),
    );
  }

  /// رأس جدول الخامات — أعمدة موحّدة مع صفوف البيانات.
  Widget _windowsTableHeader(DesktopPalette palette) {
    final style = TextStyle(
      color: palette.textMuted,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('الخامة'.tr(), style: style)),
          Expanded(
            flex: 2,
            child: Text(
              'الكمية الحالية'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'الحد الأدنى'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              'الحالة'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              'إجراءات'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  /// صف خامة واحد — كارت بالهوفر بنفس بيانات الموبايل.
  Widget _windowsMaterialRow(
    DesktopPalette palette,
    Map<String, dynamic> material,
  ) {
    final name = material['name'] as String? ?? '';
    final unit = material['unit'] as String? ?? '';
    final qty = (material['qty'] as num).toDouble();
    final minQty = (material['min_qty'] as num).toDouble();
    final cost = (material['cost'] as num?)?.toDouble() ?? 0;
    final lowStock = qty <= minQty;

    return DesktopCard(
      hover: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                DesktopIconBadge(
                  icon: lowStock ? Icons.warning : Icons.inventory_2_outlined,
                  color: lowStock ? palette.danger : palette.info,
                  size: 36,
                ),
                const SizedBox(width: DesktopTokens.gapMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (cost > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'سعر الشراء: {v1}'.tr({
                            'v1': cost.toStringAsFixed(2),
                          }),
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_windowsNum(qty)} $unit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _windowsNum(minQty),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.textMuted,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Center(
              child: DesktopInfoChip(
                label: lowStock ? 'ناقص'.tr() : 'متوفر'.tr(),
                icon:
                    lowStock
                        ? Icons.trending_down_outlined
                        : Icons.check_circle_outline,
                color: lowStock ? palette.danger : palette.success,
                dense: true,
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _windowsIconAction(
                    icon: Icons.edit_outlined,
                    tooltip: 'تعديل'.tr(),
                    color: palette.info,
                    onTap: () => addOrEditMaterial(material: material),
                  ),
                  const SizedBox(width: 4),
                  _windowsIconAction(
                    icon: Icons.delete_outline,
                    tooltip: 'حذف'.tr(),
                    color: palette.danger,
                    onTap: () => _windowsConfirmDelete(material),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// تأكيد حذف الخامة — نفس نص ورسالة الموبايل بالظبط.
  Future<void> _windowsConfirmDelete(Map<String, dynamic> material) async {
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AppDialog(
            title: Text('تأكيد الحذف'.tr()),
            content: Text(
              'سيتم حذف الخامة من المخزون ومن جميع الوصفات المرتبطة بها'.tr(),
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(false),
                child: Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                onPressed: () => navigator.pop(true),
                child: Text('حذف'.tr()),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await deleteMaterial(material['id']);
    }
  }

  /// زرار أيقونة صغير بهوفر ناعم — لعمليات الصف الواحد.
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
                color: hovering
                    ? palette.surfaceSoft
                    : palette.surfaceSoft.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                border: Border.all(
                  color: hovering
                      ? palette.border
                      : palette.border.withValues(alpha: 0),
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

  /// رقم مرتّب — من غير كسور زيادة عن اللزوم.
  String _windowsNum(num value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
}
