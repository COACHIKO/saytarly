part of '../manage_consoles.dart';

/// جسم شاشة إدارة الأجهزة — نسخة الويندوز (Windows UI).
///
/// نفس الشاشة ونفس المنطق: صف لكل جهاز بكارت عليه هوفر + اختيار بالضغط،
/// وأزرار تعديل/حذف على الطرف، وزرار "إضافة جهاز" في هيدر الصفحة — كلها
/// بتفتح نفس الـ dialogs ([_showForm]) وبتحذف بنفس [DBHelper] calls.
extension _ManageConsolesScreenWindowsBody on _ManageConsolesScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'إدارة الأجهزة'.tr(),
      subtitle: '{v1} جهاز — اضغط على أي جهاز لتحديده'.tr({'v1': consoles.length}),
      actions: [
        DesktopButton.primary(
          label: 'إضافة جهاز'.tr(),
          icon: Icons.add,
          onPressed: () => _showForm(),
        ),
      ],
      child: consoles.isEmpty
          ? DesktopEmptyState(
              icon: Icons.videogame_asset_off_outlined,
              title: 'مفيش أجهزة مضافة'.tr(),
              message:
                  'ضيف أول جهاز بلايستيشن وحدّد سعر الساعة أو سعر الماتش الثابت.'.tr(),
              action: DesktopButton.primary(
                label: 'إضافة جهاز'.tr(),
                icon: Icons.add,
                onPressed: () => _showForm(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopSectionTitle(title: 'الأجهزة'.tr(), count: consoles.length),
                for (final c in consoles) _mcConsoleRow(context, palette, c),
              ],
            ),
    );
  }

  /// صف جهاز — نفس بيانات صف الموبايل + أزرار تعديل/حذف بنفس الـ callbacks.
  Widget _mcConsoleRow(
    BuildContext context,
    DesktopPalette palette,
    ConsoleModel c,
  ) {
    final theme = Theme.of(context);
    final isSelected = c.id == selectedConsoleId;

    return DesktopCard(
      hover: true,
      selected: isSelected,
      margin: const EdgeInsets.only(bottom: DesktopTokens.gapSm + 2),
      onTap: () {
        _refresh(() {
          if (selectedConsoleId == c.id) {
            selectedConsoleId = null; // إلغاء الاختيار لو ضغط مرة ثانية
          } else {
            selectedConsoleId = c.id;
          }
        });
      },
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.sports_esports_outlined,
            color: isSelected ? palette.accent : palette.info,
            size: 44,
            radius: DesktopTokens.radiusMd,
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'سعر الساعة: {v1}'.tr({'v1': c.pricePerHour.toStringAsFixed(2)}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (c.isFixedPrice)
            DesktopInfoChip(
              label: 'سعر ثابت: {v1}'.tr({'v1': c.fixedPrice.toStringAsFixed(2)}),
              icon: Icons.attach_money,
              color: palette.warning,
            ),
          if (isSelected) ...[
            const SizedBox(width: DesktopTokens.gapSm),
            DesktopInfoChip(
              label: 'محدد'.tr(),
              icon: Icons.check_circle_outline,
              color: palette.accent,
              dense: true,
            ),
          ],
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopToolbarIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'تعديل الجهاز'.tr(),
            onPressed: () => _showForm(edit: c),
          ),
          DesktopToolbarIconButton(
            icon: Icons.delete_outline,
            tooltip: 'حذف الجهاز'.tr(),
            onPressed: () async {
              await DBHelper.deleteConsole(c.id!);
              _load();
            },
          ),
        ],
      ),
    );
  }
}
