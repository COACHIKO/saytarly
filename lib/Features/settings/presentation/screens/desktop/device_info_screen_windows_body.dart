part of '../device_info_screen.dart';

/// جسم شاشة مواصفات الجهاز — نسخة الويندوز (Windows UI).
///
/// نفس الصفوف ونفس منطق النسخ بالحرف — بس بشكل كارت سطح مكتب:
/// عمود للعنوان + عمود للقيمة (قابلة للتحديد) + زرار نسخ لكل صف،
/// وزرار "نسخ التقرير الكامل" في هيدر الصفحة.
extension _DeviceInfoWindowsBody on _DeviceInfoScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'مواصفات هذا الجهاز'.tr(),
      subtitle: 'كود التفعيل ومكونات الجهاز — جاهزة للنسخ والإرسال'.tr(),
      maxWidth: 860,
      actions: [
        DesktopButton.primary(
          label: 'نسخ التقرير الكامل'.tr(),
          icon: Icons.copy_all,
          onPressed: _loading
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: _fullReport));
                  AppToast.show('تم نسخ كل المواصفات — جاهزة للإرسال'.tr());
                },
        ),
      ],
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // نفس ملاحظة الموبايل — بس بشكل بانر ناعم.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesktopTokens.gapMd,
                    vertical: DesktopTokens.gapMd - 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.soft(palette.info),
                    borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
                    border: Border.all(
                      color: palette.info.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: palette.info),
                      const SizedBox(width: DesktopTokens.gapSm),
                      Expanded(
                        child: Text(
                          'ابعت الكود ده كامل للمهندس عند التفعيل أو لو حصلت مشكلة بعد تغيير قطعة في الجهاز.'.tr(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: palette.textSecondary,
                                fontSize: 12.5,
                                height: 1.6,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapLg),
                DesktopSectionTitle(title: 'بيانات الجهاز'.tr()),
                DesktopCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _windowsInfoRow(
                        'كود الجهاز الكامل (المستخدم في القفل)'.tr(),
                        _hash,
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: palette.border,
                        indent: DesktopTokens.gapLg,
                        endIndent: DesktopTokens.gapLg,
                      ),
                      _windowsInfoRow('CPU ID', _cpu),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: palette.border,
                        indent: DesktopTokens.gapLg,
                        endIndent: DesktopTokens.gapLg,
                      ),
                      _windowsInfoRow('Motherboard ID', _board),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: palette.border,
                        indent: DesktopTokens.gapLg,
                        endIndent: DesktopTokens.gapLg,
                      ),
                      _windowsInfoRow('Disk ID', _disk),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// صف معلومة واحدة: عنوان + قيمة قابلة للتحديد + زرار نسخ.
  Widget _windowsInfoRow(String label, String value) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapLg,
        vertical: DesktopTokens.gapMd - 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.textSecondary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: palette.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopToolbarIconButton(
            icon: Icons.copy_rounded,
            tooltip: 'نسخ'.tr(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              AppToast.show('تم النسخ'.tr());
            },
          ),
        ],
      ),
    );
  }
}
