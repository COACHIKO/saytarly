part of '../SubStaffPage.dart';

/// جسم الموظفين الفرعيين — نسخة الويندوز (Windows UI).
///
/// صفوف بعرض كامل: اسم الموظف، سعر الساعة، والمدة/الأجرة المحسوبة لحظيًا،
/// وزرار بدء/إنهاء الشيفت بنفس منطق [_toggleShift] بالظبط.
extension _SubStaffPageWindowsBody on _SubStaffPageState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'الموظفين الفرعيين'.tr(),
      subtitle: 'شيفت #{v1} • المشرف: {v2}'.tr({'v1': widget.shiftId, 'v2': widget.cashierName}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () => _loadSubStaff(),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : editableSubStaff.isEmpty
              ?  DesktopEmptyState(
                  icon: Icons.people_outline,
                  title: 'مفيش موظفين فرعيين'.tr(),
                  message: ('الموظفين التابعين للحساب ده هيظهروا هنا، '.tr() + 'ومعاهم زراير بدء/إنهاء الشيفت وحساب الأجرة تلقائيًا.'.tr()),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DesktopSectionTitle(
                        title: 'الموظفين الفرعيين'.tr(),
                        count: editableSubStaff.length,
                      ),
                      const SizedBox(height: DesktopTokens.gapXs),
                      for (final staff in editableSubStaff)
                        _winSubStaffRow(context, palette, staff),
                    ],
                  ),
                ),
    );
  }

  /// صف موظف فرعي — نفس حسابات الموبايل (المدة والأجرة) بس بشكل سطح مكتب.
  Widget _winSubStaffRow(
    BuildContext context,
    DesktopPalette palette,
    Map<String, dynamic> staff,
  ) {
    final theme = Theme.of(context);
    final staffName = staff['username'] ?? 'غير معروف'.tr();
    final shiftStartStr = staff['shift_start'];
    final shiftEndStr = staff['shift_end'];
    final salaryPerHour = (staff['salary_per_hour'] ?? 0.0) as double;

    final isWorking = shiftStartStr != null && shiftEndStr == null;
    double workedHours = 0.0;
    double earned = 0.0;
    if (shiftStartStr != null) {
      final start = DateTime.parse(shiftStartStr);
      final end =
          shiftEndStr != null ? DateTime.parse(shiftEndStr) : DateTime.now();
      workedHours = end.difference(start).inSeconds / 3600;
      earned = workedHours * salaryPerHour;
    }

    return Padding(
      padding:  EdgeInsets.only(bottom: DesktopTokens.gapSm + 2),
      child: DesktopCard(
        hover: true,
        padding:  EdgeInsets.symmetric(
          horizontal: DesktopTokens.gapMd,
          vertical: DesktopTokens.gapSm + 2,
        ),
        child: Row(
          children: [
            DesktopIconBadge(
              icon: Icons.badge_outlined,
              color: isWorking ? palette.success : palette.textMuted,
              size: 46,
              radius: DesktopTokens.radiusMd,
            ),
             SizedBox(width: DesktopTokens.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$staffName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isWorking) ...[
                         SizedBox(width: DesktopTokens.gapSm),
                        DesktopInfoChip(
                          label: 'شغّال دلوقتي'.tr(),
                          icon: Icons.circle,
                          color: palette.success,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                   SizedBox(height: 3),
                  Text(
                    shiftStartStr != null
                        ? ('المدة: {v1} ساعة • '.tr({'v1': workedHours.toStringAsFixed(2)}) + 'الأجرة: {v1} {v2}'.tr({'v1': earned.toStringAsFixed(2), 'v2': Money.txt}))
                        : 'سعر الساعة: ${salaryPerHour.toStringAsFixed(2)} ${Money.txt}',
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
            DesktopButton.primary(
              label: isWorking ? 'إنهاء'.tr() : 'بدء',
              icon: isWorking
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_fill,
              color: isWorking ? palette.danger : palette.success,
              onPressed: () => _toggleShift(staff),
            ),
          ],
        ),
      ),
    );
  }
}
