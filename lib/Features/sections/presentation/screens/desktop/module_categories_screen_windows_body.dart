part of '../module_categories_screen.dart';

/// جسم شاشة القوائم الفرعية — نسخة الويندوز (Windows UI).
///
/// صفوف بعرض كامل مع هوفر: أيقونة القسم + اسم القائمة + عدد المنتجات +
/// أزرار الترتيب والتفعيل وأوامر التعديل/الحذف.
extension _ModuleCategoriesWindowsBody on _ModuleCategoriesScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final m = widget.module;
    final palette = DesktopPalette.of(context);
    final totalDrinks = _rows.fold<int>(0, (sum, r) => sum + r.drinks);

    return DesktopPageScaffold(
      title: 'قوائم قسم «{v1}»'.tr({'v1': m.displayName}),
      subtitle:
          ('{v1} قائمة فرعية • {totalDrinks} منتج — '.tr({
                'v1': _rows.length,
                'totalDrinks': totalDrinks,
              }) +
              'دي اللي بتظهر كـ تابات في إدارة القسم والكاشير'.tr()),
      titleLeading: DesktopIconBadge(
        icon: m.iconData,
        color: m.accentColor,
        size: 42,
        radius: DesktopTokens.radiusMd,
      ),
      actions: [
        DesktopButton.primary(
          label: 'قائمة جديدة'.tr(),
          icon: Icons.add,
          onPressed: () => _openForm(),
        ),
      ],
      scrollable: false,
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
              ? DesktopEmptyState(
                icon: Icons.playlist_add,
                title: 'لسه مفيش قوائم فرعية في القسم ده'.tr(),
                message:
                    ('ضيف قوائم زي «سخن / بارد / غازية» — '.tr() +
                        'وهتظهر كـ تابات جوه إدارة القسم وشاشة الكاشير.'.tr()),
                action: DesktopButton.primary(
                  label: 'قائمة جديدة'.tr(),
                  icon: Icons.add,
                  onPressed: () => _openForm(),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================== مؤشرات سريعة ====================
                    DesktopResponsiveGrid(
                      minTileWidth: 240,
                      children: [
                        DesktopStatCard(
                          label: 'القوائم الفرعية'.tr(),
                          value: '${_rows.length}',
                          icon: Icons.playlist_play,
                          color: m.accentColor,
                        ),
                        DesktopStatCard(
                          label: 'قوائم مفعّلة'.tr(),
                          value:
                              '${_rows.where((r) => r.category.isEnabled).length}',
                          icon: Icons.toggle_on_outlined,
                          color: palette.success,
                        ),
                        DesktopStatCard(
                          label: 'إجمالي المنتجات'.tr(),
                          value: '$totalDrinks',
                          icon: Icons.local_cafe_outlined,
                          color: palette.info,
                        ),
                      ],
                    ),
                    SizedBox(height: DesktopTokens.gapLg),

                    DesktopSectionTitle(
                      title: 'القوائم الفرعية'.tr(),
                      count: _rows.length,
                    ),
                    const SizedBox(height: DesktopTokens.gapXs),

                    for (var i = 0; i < _rows.length; i++)
                      _windowsCategoryRow(context, _rows[i], i),
                  ],
                ),
              ),
    );
  }

  Widget _windowsCategoryRow(
    BuildContext context,
    _CategoryRow row,
    int index,
  ) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final m = widget.module;
    final c = row.category;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopTokens.gapSm + 2),
      child: DesktopCard(
        hover: true,
        padding: const EdgeInsets.symmetric(
          horizontal: DesktopTokens.gapMd,
          vertical: DesktopTokens.gapSm + 2,
        ),
        child: Row(
          children: [
            // أول حرف من اسم القائمة — بنفس فكرة الموبايل
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: m.accentColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(
                c.displayName.trim().isEmpty
                    ? '•'
                    : c.displayName.characters.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: DesktopTokens.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!c.isEnabled) ...[
                        const SizedBox(width: DesktopTokens.gapSm),
                        DesktopInfoChip(
                          label: 'مقفولة'.tr(),
                          icon: Icons.visibility_off_outlined,
                          color: palette.warning,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '{v1} منتج'.tr({'v1': row.drinks}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: DesktopTokens.gapSm),
            DesktopToolbarIconButton(
              icon: Icons.arrow_upward_rounded,
              tooltip: 'تحريك لفوق'.tr(),
              onPressed: index == 0 ? null : () => _move(index, -1),
            ),
            DesktopToolbarIconButton(
              icon: Icons.arrow_downward_rounded,
              tooltip: 'تحريك لتحت'.tr(),
              onPressed:
                  index == _rows.length - 1 ? null : () => _move(index, 1),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            Switch(value: c.isEnabled, onChanged: (v) => _toggle(row, v)),
            PopupMenuButton<String>(
              tooltip: 'أوامر القائمة'.tr(),
              icon: Icon(Icons.more_vert, size: 20, color: palette.textMuted),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    _openForm(edit: row);
                    break;
                  case 'up':
                    _move(index, -1);
                    break;
                  case 'down':
                    _move(index, 1);
                    break;
                  case 'delete':
                    _delete(row);
                    break;
                }
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('تعديل الاسم'.tr()),
                    ),
                    PopupMenuItem(value: 'up', child: Text('تحريك لفوق'.tr())),
                    PopupMenuItem(
                      value: 'down',
                      child: Text('تحريك لتحت'.tr()),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'delete', child: Text('حذف'.tr())),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}
