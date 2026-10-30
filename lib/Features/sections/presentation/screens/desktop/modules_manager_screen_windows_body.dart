part of '../modules_manager_screen.dart';

/// جسم شاشة أقسام المنتجات — نسخة الويندوز (Windows UI).
///
/// مؤشرات سريعة (أقسام / مفعّلة / منتجات) + قائمة أقسام بعرض كامل مع
/// هوفر وأزرار ترتيب وتفعيل وأوامر (تعديل / ترتيب / حذف).
extension _ModulesManagerWindowsBody on _ModulesManagerView {
  Widget _buildWindowsBody(BuildContext context) {
    final viewModel = context.watch<ModulesManagerCubit>();
    final rows = viewModel.state.rows;
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'أقسام المنتجات'.tr(),
      subtitle:
          ('كل قسم بيظهر له تلقائي في لوحة الأدمن: إدارة + تقرير '.tr() +
              '• الخامات مخزون مشترك لكله'.tr()),
      actions: [
        DesktopButton.primary(
          label: 'قسم جديد'.tr(),
          icon: Icons.add,
          onPressed: () => _openForm(context),
        ),
      ],
      scrollable: false,
      child:
          viewModel.state.loading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
              ? DesktopEmptyState(
                icon: Icons.category_outlined,
                title: 'لسه مفيش أقسام'.tr(),
                message:
                    ('ابدأ اعمل قسم زي «مشروبات» أو «ماكولات» — '.tr() +
                        'وهيطلع له تلقائي في لوحة الأدمن: إدارة + تقرير.'.tr()),
                action: DesktopButton.primary(
                  label: 'قسم جديد'.tr(),
                  icon: Icons.add,
                  onPressed: () => _openForm(context),
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
                          label: 'إجمالي الأقسام'.tr(),
                          value: '${rows.length}',
                          icon: Icons.category_outlined,
                          color: palette.accent,
                        ),
                        DesktopStatCard(
                          label: 'أقسام مفعّلة'.tr(),
                          value:
                              '${rows.where((r) => r.module.isEnabled).length}',
                          icon: Icons.toggle_on_outlined,
                          color: palette.success,
                        ),
                        DesktopStatCard(
                          label: 'إجمالي المنتجات'.tr(),
                          value:
                              '${rows.fold<int>(0, (sum, r) => sum + r.drinks)}',
                          icon: Icons.local_cafe_outlined,
                          color: palette.info,
                          hint: 'عبر كل الأقسام'.tr(),
                        ),
                      ],
                    ),
                    SizedBox(height: DesktopTokens.gapLg),

                    // ==================== ملاحظة إرشادية ====================
                    _windowsHintCard(context, palette),
                    SizedBox(height: DesktopTokens.gapLg),

                    DesktopSectionTitle(
                      title: 'الأقسام'.tr(),
                      count: rows.length,
                    ),
                    const SizedBox(height: DesktopTokens.gapXs),

                    // ==================== قائمة الأقسام ====================
                    for (var i = 0; i < rows.length; i++)
                      _windowsModuleRow(context, viewModel, rows[i], i),
                  ],
                ),
              ),
    );
  }

  Widget _windowsHintCard(BuildContext context, DesktopPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 17, color: palette.accentText),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Text(
              ('كل قسم بيظهر له تلقائي في لوحة الأدمن: إدارة القسم + تقرير القسم. '
                      .tr() +
                  'اضغط على أي قسم عشان تضيف جواه قوائم فرعية (سخن / بارد / إلخ).'
                      .tr()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.accentText,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowsModuleRow(
    BuildContext context,
    ModulesManagerCubit viewModel,
    SectionModuleRow row,
    int index,
  ) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final m = row.module;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopTokens.gapSm + 2),
      child: DesktopCard(
        hover: true,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModuleCategoriesScreen(module: m),
            ),
          );
          viewModel.load();
        },
        padding: const EdgeInsets.symmetric(
          horizontal: DesktopTokens.gapMd,
          vertical: DesktopTokens.gapSm + 2,
        ),
        child: Row(
          children: [
            DesktopIconBadge(
              icon: m.iconData,
              color: m.accentColor,
              size: 46,
              radius: DesktopTokens.radiusMd,
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
                          m.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!m.isEnabled) ...[
                        const SizedBox(width: DesktopTokens.gapSm),
                        DesktopInfoChip(
                          label: 'مقفول'.tr(),
                          icon: Icons.visibility_off_outlined,
                          color: palette.warning,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '{v1} منتج • {v2} قائمة فرعية'.tr({
                      'v1': row.drinks,
                      'v2': row.categories,
                    }),
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
              onPressed: index == 0 ? null : () => viewModel.move(index, -1),
            ),
            DesktopToolbarIconButton(
              icon: Icons.arrow_downward_rounded,
              tooltip: 'تحريك لتحت'.tr(),
              onPressed:
                  index == rowsIndexOf(viewModel)
                      ? null
                      : () => viewModel.move(index, 1),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            Switch(
              value: m.isEnabled,
              onChanged: (v) => viewModel.toggleModule(row, v),
            ),
            PopupMenuButton<String>(
              tooltip: 'أوامر القسم'.tr(),
              icon: Icon(Icons.more_vert, size: 20, color: palette.textMuted),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    _openForm(context, edit: row);
                    break;
                  case 'up':
                    viewModel.move(index, -1);
                    break;
                  case 'down':
                    viewModel.move(index, 1);
                    break;
                  case 'delete':
                    _delete(context, row);
                    break;
                }
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(value: 'edit', child: Text('تعديل'.tr())),
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

  /// آخر index في القائمة (عشان نعطّل زر «لتحت» عند آخر قسم).
  int rowsIndexOf(ModulesManagerCubit viewModel) =>
      viewModel.state.rows.length - 1;
}
