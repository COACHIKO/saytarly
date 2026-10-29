part of '../materials_report.dart';

/// جسم الخامات الناقصة — نسخة الويندوز (Windows UI).
///
/// نفس المنطق: عرض الخامات اللي كميتها وصلت للحد الأدنى أو أقل،
/// بنفس الـ load من الـ State.
extension _MaterialsReportScreenWindowsBody on _MaterialsReportScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'الخامات الناقصة'.tr(),
      subtitle: 'متابعة الخامات اللي وصلت للحد الأدنى'.tr(),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () => load(),
        ),
      ],
      child: data.isEmpty
          ? DesktopEmptyState(
              icon: Icons.check_circle_outline,
              title: 'مفيش خامات ناقصة'.tr(),
              message: 'كل الخامات فوق الحد الأدنى — المخزون سليم.'.tr(),
              action: DesktopButton.ghost(
                label: 'تحديث'.tr(),
                icon: Icons.refresh,
                onPressed: () => load(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== المؤشر ====================
                DesktopResponsiveGrid(
                  minTileWidth: 240,
                  maxColumns: 3,
                  children: [
                    DesktopStatCard(
                      label: 'عدد الخامات الناقصة'.tr(),
                      value: '${data.length}',
                      icon: Icons.warning_amber_rounded,
                      color: palette.danger,
                      hint: 'كمية أقل من أو تساوي الحد الأدنى'.tr(),
                    ),
                  ],
                ),
                 SizedBox(height: DesktopTokens.gapLg),

                // ==================== قائمة النواقص ====================
                DesktopSectionTitle(
                  title: 'تفاصيل النواقص'.tr(),
                  count: data.length,
                ),
                for (final m in data) ...[
                  _windowsShortageRow(palette, m),
                  const SizedBox(height: DesktopTokens.gapSm),
                ],
                const SizedBox(height: DesktopTokens.gapLg),
              ],
            ),
    );
  }

  /// صف خامة ناقصة — شارة تحذير + الاسم + المتبقي + شيب "ناقص".
  Widget _windowsShortageRow(
    DesktopPalette palette,
    Map<String, dynamic> material,
  ) {
    final name = material['name'] as String? ?? '';
    final unit = material['unit'] as String? ?? '';

    return DesktopCard(
      hover: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.warning_amber_rounded,
            color: palette.danger,
            size: 38,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المتبقي {v1} {unit} • الحد الأدنى {v3}'.tr({'v1': material['qty'], 'unit': unit, 'v3': material['min_qty']}),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: 'ناقص'.tr(),
            icon: Icons.trending_down_outlined,
            color: palette.danger,
          ),
        ],
      ),
    );
  }
}
