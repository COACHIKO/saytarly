part of '../SubStaffScreen.dart';

/// جسم الموظفين الفرعيين (إدارة) — نسخة الويندوز (Windows UI).
///
/// صفوف بعرض كامل: الاسم، الراتب بالساعة، حالات بدء/انتهاء العمل، وزرار
/// بدء/إنهاء بنفس منطق [_buildShiftButton]، وزرار تعديل يفتح نفس الفورم.
extension _SubStaffScreenWindowsBody on _SubStaffScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'الموظفين الفرعيين'.tr(),
      subtitle: '{v1} موظف تابع — إدارة الراتب والشيفتات'.tr({
        'v1': subStaff.length,
      }),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () => _loadSubStaff(),
        ),
        DesktopButton.primary(
          label: 'إضافة موظف فرعي'.tr(),
          icon: Icons.person_add_alt,
          onPressed: () => _showForm(),
        ),
      ],
      child:
          subStaff.isEmpty
              ? DesktopEmptyState(
                icon: Icons.people_outline,
                title: 'مفيش موظفين فرعيين'.tr(),
                message:
                    ('ضيف موظفين تابعين للمشرف ده وحدد راتب الساعة '.tr() +
                        'وساعات العمل اليومية.'.tr()),
                action: DesktopButton.primary(
                  label: 'إضافة موظف فرعي'.tr(),
                  icon: Icons.person_add_alt,
                  onPressed: () => _showForm(),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesktopSectionTitle(
                      title: 'الموظفين الفرعيين'.tr(),
                      count: subStaff.length,
                    ),
                    const SizedBox(height: DesktopTokens.gapXs),
                    for (final u in subStaff)
                      _winSubStaffManagementRow(context, palette, u),
                  ],
                ),
              ),
    );
  }

  /// صف موظف فرعي — نفس بيانات الموبايل (الراتب + بداية/نهاية الشيفت).
  Widget _winSubStaffManagementRow(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> u,
  ) {
    final theme = Theme.of(context);
    final isWorking = u['shift_start'] != null && u['shift_end'] == null;

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
              color: isWorking ? palette.success : palette.accent,
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
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: DesktopTokens.gapSm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        ('الراتب بالساعة: '.tr() +
                            '{v1}'.tr({
                              'v1': u['salary_per_hour'] ?? 'غير محدد'.tr(),
                            })),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (u['shift_start'] != null)
                        DesktopInfoChip(
                          label:
                              ('بدأت العمل: '.tr() +
                                  '${DateFormat('HH:mm').format(DateTime.parse(u['shift_start']))}'),
                          icon: Icons.play_arrow_rounded,
                          color: palette.success,
                          dense: true,
                        ),
                      if (u['shift_end'] != null)
                        DesktopInfoChip(
                          label:
                              ('انتهت: '.tr() +
                                  '${DateFormat('HH:mm').format(DateTime.parse(u['shift_end']))}'),
                          icon: Icons.stop_rounded,
                          color: palette.textMuted,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            DesktopToolbarIconButton(
              icon: Icons.link_off,
              tooltip: 'إزالة من الشيفت'.tr(),
              onPressed: () => _removeSubStaff(u),
            ),
            const SizedBox(width: DesktopTokens.gapXs),
            DesktopToolbarIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'تعديل بيانات الموظف'.tr(),
              onPressed: () => _showForm(edit: u),
            ),
            const SizedBox(width: DesktopTokens.gapXs),
            DesktopButton.primary(
              label: isWorking ? 'إنهاء'.tr() : 'بدء'.tr(),
              icon:
                  isWorking
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_fill,
              color: isWorking ? palette.danger : palette.success,
              onPressed: () async {
                final now = DateTime.now();
                if (!isWorking) {
                  await DBHelper.startStaffShift(u['id'], now);
                } else {
                  await DBHelper.endStaffShift(u['id'], now);
                }
                _loadSubStaff();
              },
            ),
          ],
        ),
      ),
    );
  }
}
