part of '../PendingSalariesScreen.dart';

/// جسم مستحقات الموظفين — نسخة الويندوز (Windows UI).
///
/// مؤشرات سريعة (مستحقين / إجمالي الصافي / إجمالي الساعات) + كشف مستحقات
/// بعرض كامل: بيانات كل موظف، زرار التفاصيل (شيت الأيام)، وزرار الصرف —
/// نفس الميثودس بالظبط (_pay و _showDetailsSheet و _formatArabicDateTime).
extension _PendingSalariesScreenWindowsBody on _PendingSalariesScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final totalNet = pending.fold<double>(
      0,
      (sum, p) => sum + (((p['total_net'] as num?) ?? 0).toDouble()),
    );
    final totalHours = pending.fold<double>(
      0,
      (sum, p) => sum + (((p['total_hours'] as num?) ?? 0).toDouble()),
    );

    return DesktopPageScaffold(
      title: 'مستحقات الموظفين'.tr(),
      subtitle: '{v1} موظف عليهم مستحقات غير مصروفة'.tr({'v1': pending.length}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () => _load(),
        ),
      ],
      child: pending.isEmpty
          ?  DesktopEmptyState(
              icon: Icons.paid_outlined,
              title: 'لا توجد مستحقات حتى الآن'.tr(),
              message: ('لما الشيفتات تسجّل ساعات وأجور، المستحقات هتظهر هنا '.tr() + 'عشان تصرفها وتتسجل كمصروف تلقائيًا.'.tr()),
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
                        label: 'موظفين مستحقين'.tr(),
                        value: '${pending.length}',
                        icon: Icons.groups_outlined,
                        color: palette.accent,
                      ),
                      DesktopStatCard(
                        label: 'إجمالي الصافي'.tr(),
                        value: totalNet.toStringAsFixed(2),
                        icon: Icons.payments_outlined,
                        color: palette.success,
                        hint: '${Money.txt}',
                      ),
                      DesktopStatCard(
                        label: 'إجمالي الساعات'.tr(),
                        value: totalHours.toStringAsFixed(2),
                        icon: Icons.schedule_outlined,
                        color: palette.info,
                        hint: 'ساعة'.tr(),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesktopTokens.gapLg),

                  DesktopSectionTitle(
                    title: 'كشف المستحقات'.tr(),
                    count: pending.length,
                  ),
                  const SizedBox(height: DesktopTokens.gapXs),

                  for (final p in pending)
                    _winPendingSalaryRow(context, palette, p),
                ],
              ),
            ),
    );
  }

  /// صف مستحقات موظف — بعرض كامل مع هوفر وأزرار التفاصيل والصرف.
  Widget _winPendingSalaryRow(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> p,
  ) {
    final theme = Theme.of(context);
    final net = (((p['total_net'] as num?) ?? 0).toDouble());

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
            DesktopIconBadge(
              icon: Icons.person_outline,
              color: palette.accent,
              size: 46,
              radius: DesktopTokens.radiusMd,
            ),
            const SizedBox(width: DesktopTokens.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${p['staff_name']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ('الساعات: {v1} • '.tr({'v1': p['total_hours']}) + 'آخر تاريخ: {v1}'.tr({'v1': _formatArabicDateTime(p['last_date'].toString())})),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            DesktopInfoChip(
              label: '${net.toStringAsFixed(2)} ${Money.txt}',
              icon: Icons.payments_outlined,
              color: palette.success,
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            DesktopToolbarIconButton(
              icon: Icons.info_outline,
              tooltip: 'تفاصيل أيام العمل'.tr(),
              onPressed: () =>
                  _showDetailsSheet(p['staff_id'], p['staff_name']),
            ),
            const SizedBox(width: DesktopTokens.gapXs),
            DesktopButton.primary(
              label: 'صرف'.tr(),
              icon: Icons.check_circle_outline,
              color: palette.success,
              onPressed: () => _pay(
                p['staff_id'],
                p['total_net'],
                p['staff_name'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
