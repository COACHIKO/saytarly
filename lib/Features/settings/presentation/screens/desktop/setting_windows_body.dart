part of '../setting.dart';

/// جسم شاشة الإعدادات — نسخة الويندوز (Windows UI).
///
/// نفس الأقسام بالترتيب بالظبط (المظهر العام ← منتجات إضافية ← شاشة إضافة
/// المشروبات ← شكل لوحة الأدمن ← شكل تقرير الشيفتات ← النسخ الاحتياطي
/// والبيانات ← النسخ عبر الانترنت ← مواصفات الجهاز) — بس بشكل صفحة إعدادات
/// ويندوز: مجموعات DesktopCard بعنوان قسم، وكل صف فيه أيقونة + عنوان + وصف
/// وعنصر تحكم على الطرف. نفس المتغيرات ونفس الـ callbacks بالحرف.
extension _SettingsWindowsBody on _SettingsScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DesktopPageScaffold(
      title: 'الإعدادات'.tr(),
      subtitle: 'المظهر والبيانات والنسخ الاحتياطي وخصائص الجهاز'.tr(),
      maxWidth: 980,
      actions: [
        DesktopButton.primary(
          label: 'نسخ احتياطي الآن'.tr(),
          icon: Icons.backup_outlined,
          onPressed: _backupNow,
        ),
         DesktopThemeToggle(),
      ],
      child: _loading
          ?  Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== المظهر العام ====================
                _windowsSection('المظهر العام'.tr(), [
                  _windowsSwitchRow(
                    icon: isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    iconColor: palette.accent,
                    title: 'الوضع الليلي'.tr(),
                    subtitle: isDark
                        ? 'الوضع الليلي مفعّل الآن'.tr()
                        : 'الوضع النهاري مفعّل الآن',
                    value: isDark,
                    onChanged: (_) =>
                        context.read<ThemeCubit>().toggle(),
                  ),
                ]),

                // ==================== منتجات إضافية ====================
                _windowsSection('منتجات إضافية'.tr(), [
                  _windowsSwitchRow(
                    icon: Icons.smoking_rooms_outlined,
                    iconColor: palette.warning,
                    title: 'بيع السجائر'.tr(),
                    subtitle: _cigarettesEnabled
                        ? 'مفعّل — هتظهر في شاشة البيع وإدارة المشروبات'.tr()
                        : 'متوقف — مش هتظهر في شاشة البيع',
                    value: _cigarettesEnabled,
                    onChanged: _changeCigarettesEnabled,
                  ),
                  _windowsSwitchRow(
                    icon: Icons.blur_on_rounded,
                    iconColor: palette.info,
                    title: 'بيع الشيشة'.tr(),
                    subtitle: _shishaEnabled
                        ? 'مفعّل — هتظهر في شاشة البيع وإدارة المشروبات'.tr()
                        : 'متوقف — مش هتظهر في شاشة البيع',
                    value: _shishaEnabled,
                    onChanged: _changeShishaEnabled,
                  ),
                ]),

                // ==================== شاشة إضافة المشروبات ====================
                _windowsSection('شاشة إضافة المشروبات'.tr(), [
                  _windowsOptionRow(
                    icon: Icons.view_list_rounded,
                    title: 'قائمة'.tr(),
                    subtitle: 'عرض المشروبات كقائمة عادية'.tr(),
                    selected: !_posMode,
                    onTap: () => _changeDrinksMode(false),
                  ),
                  _windowsOptionRow(
                    icon: Icons.grid_view_rounded,
                    title: 'كاشير'.tr(),
                    subtitle: 'عرض المشروبات كشبكة أزرار سريعة'.tr(),
                    selected: _posMode,
                    onTap: () => _changeDrinksMode(true),
                  ),
                ]),

                // ==================== شكل لوحة الأدمن ====================
                _windowsSection('شكل لوحة الأدمن'.tr(), [
                  for (final d in DashStyle.values)
                    _windowsOptionRow(
                      icon: _dashStyleIcon(d),
                      title: _dashStyleLabel(d),
                      selected: _dashStyle == d,
                      onTap: () => _changeDashStyle(d),
                    ),
                ]),

                // ==================== شكل تقرير الشيفتات ====================
                _windowsSection('شكل تقرير الشيفتات'.tr(), [
                  for (final d in ReportDesign.values)
                    _windowsOptionRow(
                      icon: _reportDesignIcon(d),
                      title: _reportDesignLabel(d),
                      selected: _reportDesign == d,
                      onTap: () => _changeReportDesign(d),
                    ),
                ]),

                // ==================== تخصيص النظام لنشاطك ====================
                _windowsSection('تخصيص النظام لنشاطك'.tr(), [
                  _windowsNavRow(
                    icon: Icons.currency_exchange,
                    iconColor: palette.accent,
                    title: 'العملة والطباعة'.tr(),
                    subtitle: 'رمز العملة، عرض ورق الفاتورة، اسم الطابعة'.tr(),
                    onTap: _editMoneyAndPrint,
                  ),
                  _windowsNavRow(
                    icon: Icons.receipt_long,
                    iconColor: palette.info,
                    title: 'نصوص الفاتورة'.tr(),
                    subtitle: 'جملة الشكر / تليفون / عنوان / الرقم الضريبي'.tr(),
                    onTap: _editReceiptTexts,
                  ),
                  _windowsNavRow(
                    icon: Icons.straighten,
                    title: 'وحدات الخامات'.tr(),
                    subtitle: 'عدّل قائمة الوحدات على مزاج نشاطك'.tr(),
                    onTap: _editUnits,
                  ),
                  _windowsNavRow(
                    icon: Icons.palette_outlined,
                    title: 'لون الهوية'.tr(),
                    subtitle: 'بيغيّر ألوان الثيم كلها باللون اللي تختاره'.tr(),
                    onTap: _changeBrandColor,
                  ),
                ]),

                // ==================== النسخ الاحتياطي والبيانات ====================
                _windowsSection('النسخ الاحتياطي والبيانات'.tr(), [
                  _windowsNavRow(
                    icon: Icons.backup_outlined,
                    iconColor: palette.accent,
                    title: 'نسخ احتياطي كامل'.tr(),
                    subtitle: 'حفظ نسخة من كل بيانات البرنامج'.tr(),
                    onTap: _backupNow,
                  ),
                  _windowsNavRow(
                    icon: Icons.restore_outlined,
                    iconColor: palette.info,
                    title: 'استرجاع نسخة احتياطية'.tr(),
                    subtitle: 'استبدال البيانات الحالية بنسخة محفوظة'.tr(),
                    onTap: _restoreNow,
                  ),
                  _windowsNavRow(
                    icon: Icons.delete_forever_outlined,
                    title: 'مسح كل البيانات'.tr(),
                    subtitle: 'حذف الفواتير والمصروفات وكل شيء نهائياً'.tr(),
                    onTap: _clearAllNow,
                    danger: true,
                  ),
                ]),

                // ==================== النسخ عبر الانترنت ====================
                _windowsSection('النسخ عبر الانترنت'.tr(), [
                  // 🖥️ يظهر بس على جهاز الكاشير (Windows/Linux)
                  if (Platform.isWindows || Platform.isLinux) ...[
                    FutureBuilder<List<String>>(
                      future: LanBackupServer.getLocalIps(),
                      builder: (context, snapshot) {
                        final ips = snapshot.data;
                        if (ips == null || ips.isEmpty) {
                          return _windowsSettingRow(
                            icon: Icons.wifi_off_rounded,
                            iconColor: palette.textMuted,
                            title: 'غير متصل بأي شبكة'.tr(),
                            trailing: DesktopInfoChip(
                              label: 'غير متصل'.tr(),
                              icon: Icons.wifi_off,
                              color: palette.warning,
                            ),
                          );
                        }
                        return _windowsSettingRow(
                          icon: Icons.wifi_tethering,
                          iconColor: palette.info,
                          title: 'عنوان جهاز الكاشير على الشبكة'.tr(),
                          subtitle: ips.join(' , '),
                          trailing: DesktopInfoChip(
                            label: 'متصل'.tr(),
                            icon: Icons.check,
                            color: palette.success,
                          ),
                        );
                      },
                    ),
                    _windowsNavRow(
                      icon: Icons.cloud_upload_outlined,
                      iconColor: palette.info,
                      title: 'رفع نسخة على الشبكة الآن'.tr(),
                      subtitle:
                          'تحديث النسخة المتاحة للموبايل فوراً (نفس الواي فاي)'.tr(),
                      onTap: _uploadNow,
                    ),
                    // 🆕 رفع على السيرفر (Supabase) — من أي مكان مش لازم نفس الواي فاي
                    _windowsNavRow(
                      icon: Icons.cloud_done_outlined,
                      iconColor: palette.accent,
                      title: 'رفع نسخة على السيرفر (كلاود)'.tr(),
                      subtitle: 'استخدمه عشان تقدر تسترجع من أي موبايل من أي مكان'.tr(),
                      onTap: _uploadToSupabaseNow,
                    ),
                  ],

                  // 📱 يظهر بس على الموبايل
                  if (Platform.isAndroid || Platform.isIOS) ...[
                    _windowsNavRow(
                      icon: Icons.wifi,
                      iconColor: palette.info,
                      title: 'استيراد من جهاز الكاشير'.tr(),
                      subtitle: 'لازم تكونوا على نفس شبكة الواي فاي'.tr(),
                      onTap: _importFromNetwork,
                    ),
                    // 🆕 استرجاع من السيرفر (Supabase) — من غير الحاجة لنفس الشبكة
                    _windowsNavRow(
                      icon: Icons.cloud_download_outlined,
                      iconColor: palette.accent,
                      title: 'استرجاع من السيرفر (كلاود)'.tr(),
                      subtitle: 'يجيب آخر نسخة مرفوعة من أي مكان فيه إنترنت'.tr(),
                      onTap: _restoreFromSupabaseNow,
                    ),
                  ],
                ]),

                // ==================== مواصفات الجهاز ====================
                DesktopCard(
                  padding: EdgeInsets.zero,
                  child: _windowsNavRow(
                    icon: Icons.perm_device_information_outlined,
                    iconColor: palette.info,
                    title: 'مواصفات هذا الجهاز'.tr(),
                    subtitle: 'عرض ونسخ كود التفعيل والمكونات'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeviceInfoScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// مجموعة إعدادات: عنوان قسم + كارت فيه الصفوف بينها فواصل ناعمة.
  Widget _windowsSection(String title, List<Widget> rows) {
    final palette = DesktopPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopSectionTitle(title: title),
        DesktopCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: palette.border,
                    indent: DesktopTokens.gapLg,
                    endIndent: DesktopTokens.gapLg,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: DesktopTokens.gapXl),
      ],
    );
  }

  /// صف إعداد واحد: أيقونة ملوّنة + عنوان + وصف + عنصر تحكم على الطرف.
  ///
  /// لو الصف قابل للضغط بيتلف بـ [HoverBuilder] وخلفية ناعمة وقت الهوفر.
  Widget _windowsSettingRow({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final tint = danger ? palette.danger : (iconColor ?? palette.accent);

    final row = Row(
      children: [
        DesktopIconBadge(
          icon: icon,
          color: tint,
          size: 38,
          radius: DesktopTokens.radiusSm,
        ),
        const SizedBox(width: DesktopTokens.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: danger ? palette.danger : palette.textPrimary,
                  fontSize: 14,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: DesktopTokens.gapMd),
          trailing,
        ],
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesktopTokens.gapLg,
          vertical: 14,
        ),
        child: row,
      );
    }

    return HoverBuilder(
      builder: (context, hovering) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: DesktopTokens.gapMd,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: hovering ? palette.surfaceSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          ),
          child: row,
        ),
      ),
    );
  }

  /// صف بمفتاح تبديل (Switch) — بنفس المتغير ونفس الـ callback.
  Widget _windowsSwitchRow({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _windowsSettingRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  /// صف اختيار واحد من مجموعة (زي الراديو في الموبايل) — علامة صح للمختار.
  Widget _windowsOptionRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final palette = DesktopPalette.of(context);

    return _windowsSettingRow(
      icon: icon,
      iconColor: selected ? palette.accent : palette.textMuted,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        size: 20,
        color: selected
            ? palette.accent
            : palette.textMuted.withValues(alpha: 0.7),
      ),
    );
  }

  /// صف إجرائي (نسخ احتياطي / استرجاع / فتح صفحة) — سهم "قدام" على الطرف.
  Widget _windowsNavRow({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final palette = DesktopPalette.of(context);

    return _windowsSettingRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      danger: danger,
      trailing: Icon(
        Icons.chevron_left,
        size: 20,
        color: palette.textMuted.withValues(alpha: 0.8),
      ),
    );
  }
}
