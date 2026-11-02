part of '../StaffSalaryScreen.dart';

/// جسم صرف مرتبات الموظفين — نسخة الويندوز (Windows UI).
///
/// مؤشرات الشهر الحالي + صفوف الموظفين بعرض كامل: المستحق بالشهر، زرار
/// تاريخ الصرف (نفس الدايالوج)، وزرار صرف بنفس فحصة "اتصرف مسبقًا".
extension _StaffSalaryScreenWindowsBody on _StaffSalaryScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final total = staff.fold<double>(
      0,
      (sum, u) => sum + (((u['net'] as num?) ?? 0).toDouble()),
    );

    return DesktopPageScaffold(
      title: 'صرف مرتبات الموظفين'.tr(),
      subtitle: 'شهر {month} • {v2} موظف'.tr({
        'month': month,
        'v2': staff.length,
      }),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () => loadStaff(),
        ),
      ],
      child:
          staff.isEmpty
              ? DesktopEmptyState(
                icon: Icons.badge_outlined,
                title: 'مفيش موظفين بصلاحيات ستاف'.tr(),
                message:
                    ('ضيف موظفين الستاف الأول من إدارة المستخدمين، '.tr() +
                        'وبعدين مرتباتهم هتظهر هنا للصرف.'.tr()),
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
                          label: 'موظفين الشهر'.tr(),
                          value: '${staff.length}',
                          icon: Icons.groups_outlined,
                          color: palette.accent,
                        ),
                        DesktopStatCard(
                          label: 'إجمالي المستحق'.tr(),
                          value: total.toStringAsFixed(2),
                          icon: Icons.payments_outlined,
                          color: palette.success,
                          hint: '{v1} — شهر {month}'.tr({
                            'v1': Money.txt,
                            'month': month,
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesktopTokens.gapLg),

                    DesktopSectionTitle(
                      title: 'المرتبات'.tr(),
                      count: staff.length,
                    ),
                    const SizedBox(height: DesktopTokens.gapXs),

                    for (final u in staff) _winSalaryRow(context, palette, u),
                  ],
                ),
              ),
    );
  }

  /// صف مرتب موظف — بعرض كامل: الاسم + المستحق + تاريخ الصرف + زرار الصرف.
  Widget _winSalaryRow(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> u,
  ) {
    final theme = Theme.of(context);
    final net = (((u['net'] as num?) ?? 0).toDouble());

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
              color: net > 0 ? palette.accent : palette.textMuted,
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
                    '${u['username']}',
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
                    'مستحق الشهر الحالي: {v1} {v2}'.tr({
                      'v1': net.toStringAsFixed(2),
                      'v2': Money.txt,
                    }),
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
              label: net > 0 ? 'لسه متصرفش'.tr() : 'اتصرف'.tr(),
              icon:
                  net > 0
                      ? Icons.hourglass_bottom_outlined
                      : Icons.check_circle_outline,
              color: net > 0 ? palette.warning : palette.success,
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            DesktopToolbarIconButton(
              icon: Icons.history,
              tooltip: 'تاريخ الصرف'.tr(),
              onPressed: () async {
                final hist = await _history(u['id']);
                if (!context.mounted) return; // الشاشة قفلت — ما نلمس contextش
                showDialog(
                  context: context,
                  builder:
                      (dialogContext) => AppDialog(
                        title: Text(
                          'تاريخ الصرف - {v1}'.tr({'v1': u['username']}),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children:
                                hist.map((h) {
                                  return ListTile(
                                    title: Text(
                                      'شهر: {v1}'.tr({'v1': h['month']}),
                                    ),
                                    subtitle: Text(
                                      'تاريخ: {v1}'.tr({'v1': h['paid_at']}),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('إغلاق'.tr()),
                          ),
                        ],
                      ),
                );
              },
            ),
            const SizedBox(width: DesktopTokens.gapXs),
            DesktopButton.primary(
              label: 'صرف'.tr(),
              icon: Icons.check_circle_outline,
              color: palette.success,
              onPressed: () async {
                final already = await DBHelper.isSalaryPaid(u['id'], month);
                if (already) {
                  AppToast.show('تم صرف هذا الشهر مسبقًا'.tr());
                  return;
                }
                await _pay(u['id']);
              },
            ),
          ],
        ),
      ),
    );
  }
}
