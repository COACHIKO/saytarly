part of '../setting.dart';

/// جسم شاشة الإعدادات — نسخة الويندوز (Windows UI).
///
/// منظمة في تبويبات (Tabs) وكل تبويب فيه تصنيفات (Sections):
/// المظهر ← الشاشات ← النشاط ← النسخ والبيانات ← الجهاز.
/// شريط التبويبات تحت هيدر الصفحة مباشرة، والمحتوى بيتحرك بين التبويبات
/// بأنيميشن fade + slide ناعم.
extension _SettingsWindowsBody on _SettingsScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    return DesktopPageScaffold(
      title: 'الإعدادات'.tr(),
      subtitle: 'المظهر واللغة والبيانات والنسخ الاحتياطي وخصائص الجهاز'.tr(),
      maxWidth: 980,
      headerBottom: _windowsTabBar(context),
      actions: [
        DesktopButton.primary(
          label: 'نسخ احتياطي الآن'.tr(),
          icon: Icons.backup_outlined,
          onPressed: _backupNow,
        ),
        DesktopThemeToggle(),
      ],
      child:
          _loading
              ? Padding(
                padding: EdgeInsets.symmetric(vertical: 90),
                child: Center(child: CircularProgressIndicator()),
              )
              : AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_tab),
                  child: _tabContent(context),
                ),
              ),
    );
  }

  // ============================ شريط التبويبات ============================

  Widget _windowsTabBar(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _windowsTabPill(context, i),
              ],
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _tabs[_tab].description,
              key: ValueKey<int>(_tab),
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowsTabPill(BuildContext context, int index) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final tab = _tabs[index];
    final selected = _tab == index;

    return HoverBuilder(
      builder: (context, hovering) {
        final background =
            selected
                ? palette.accentSoft
                : hovering
                ? palette.surfaceSoft
                : Colors.transparent;
        final borderColor =
            selected
                ? palette.accent.withValues(alpha: 0.65)
                : hovering
                ? palette.border
                : Colors.transparent;
        return GestureDetector(
          onTap: () => _setTab(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    tab.icon,
                    key: ValueKey<bool>(selected),
                    size: 17,
                    color: selected ? palette.accent : palette.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tab.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? palette.accent : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================ محتوى التبويبات ============================

  Widget _tabContent(BuildContext context) {
    switch (_tab) {
      case 0:
        return _appearanceTab(context);
      case 1:
        return _screensTab(context);
      case 2:
        return _businessTab(context);
      case 3:
        return _backupTab(context);
      default:
        return _deviceTab(context);
    }
  }

  /// التبويب 1 — المظهر: اللغة + الوضع الليلي.
  Widget _appearanceTab(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = context.watch<LocaleCubit>().state.locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _windowsSection('اللغة'.tr(), [
          _windowsOptionRow(
            icon: Icons.language_rounded,
            title: 'العربية'.tr(),
            subtitle: 'واجهة عربية كاملة من اليمين لليسار'.tr(),
            selected: languageCode == 'ar',
            onTap: () => _changeLanguage('ar'),
          ),
          _windowsOptionRow(
            icon: Icons.translate_rounded,
            title: 'English',
            subtitle: 'Full English interface, left to right',
            selected: languageCode == 'en',
            onTap: () => _changeLanguage('en'),
          ),
        ]),
        _windowsSection('المظهر العام'.tr(), [
          _windowsSwitchRow(
            icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            iconColor: palette.accent,
            title: 'الوضع الليلي'.tr(),
            subtitle:
                isDark
                    ? 'الوضع الليلي مفعّل الآن'.tr()
                    : 'الوضع النهاري مفعّل الآن'.tr(),
            value: isDark,
            onChanged: (_) => context.read<ThemeCubit>().toggle(),
          ),
        ]),
      ],
    );
  }

  /// التبويب 2 — الشاشات: شكل شاشة المشروبات + لوحة الأدمن + تقرير الشيفتات.
  Widget _screensTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _windowsSection('شكل لوحة الأدمن'.tr(), [
          for (final d in DashStyle.values)
            _windowsOptionRow(
              icon: _dashStyleIcon(d),
              title: _dashStyleLabel(d),
              selected: _dashStyle == d,
              onTap: () => _changeDashStyle(d),
            ),
        ]),
        _windowsSection('شكل تقرير الشيفتات'.tr(), [
          for (final d in ReportDesign.values)
            _windowsOptionRow(
              icon: _reportDesignIcon(d),
              title: _reportDesignLabel(d),
              selected: _reportDesign == d,
              onTap: () => _changeReportDesign(d),
            ),
        ]),
      ],
    );
  }

  /// التبويب 3 — النشاط: العملة والطباعة + نصوص الفاتورة + وحدات الخامات.
  Widget _businessTab(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ]),
      ],
    );
  }

  /// التبويب 4 — النسخ والبيانات: نسخ/استرجاع + مزامنة الشبكة + منطقة الخطر.
  Widget _backupTab(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ]),

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
            _windowsNavRow(
              icon: Icons.cloud_done_outlined,
              iconColor: palette.accent,
              title: 'رفع نسخة على السيرفر (كلاود)'.tr(),
              subtitle:
                  'استخدمه عشان تقدر تسترجع من أي موبايل من أي مكان'.tr(),
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
            _windowsNavRow(
              icon: Icons.cloud_download_outlined,
              iconColor: palette.accent,
              title: 'استرجاع من السيرفر (كلاود)'.tr(),
              subtitle: 'يجيب آخر نسخة مرفوعة من أي مكان فيه إنترنت'.tr(),
              onTap: _restoreFromSupabaseNow,
            ),
          ],
        ]),

        _windowsDangerSection(),
      ],
    );
  }

  /// التبويب 5 — الجهاز: نسخة التطبيق + مواصفات الجهاز.
  Widget _deviceTab(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final version = Platform.isWindows
        ? VersionInfo.windowsVersion
        : VersionInfo.mobileVersion;
    final build = Platform.isWindows
        ? VersionInfo.windowsBuildNumber
        : VersionInfo.mobileBuildNumber;
    final licenseStatus = DeviceRegistry.status.value;
    final licenseRecord = DeviceRegistry.currentRecord;
    final licenseColor = switch (licenseStatus) {
      DeviceLicenseStatus.unlimited ||
      DeviceLicenseStatus.active => palette.success,
      DeviceLicenseStatus.expired ||
      DeviceLicenseStatus.blocked => palette.danger,
      DeviceLicenseStatus.pending => palette.warning,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── وضع التطبيق ──
        _windowsSection('وضع التطبيق'.tr(), [
          _windowsSettingRow(
            icon: AppMode.isOnline
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            iconColor: AppMode.isOnline ? palette.success : palette.textMuted,
            title: AppMode.isOnline ? 'Online'.tr() : 'Offline'.tr(),
            subtitle: AppMode.isOnline
                ? 'تحديثات GitHub + تسجيل الأجهزة والتراخيص'.tr()
                : 'من غير أي خدمات سحابية'.tr(),
            trailing: DesktopInfoChip(
              label: AppMode.isOnline ? 'متصل'.tr() : 'منفصل'.tr(),
              icon: AppMode.isOnline ? Icons.check : Icons.link_off,
              color: AppMode.isOnline ? palette.success : palette.textMuted,
            ),
          ),
        ]),

        // ── الترخيص (online بس) ──
        if (AppMode.isOnline) ...[
          _windowsSection('الترخيص'.tr(), [
            _windowsSettingRow(
              icon: Icons.workspace_premium_outlined,
              iconColor: licenseColor,
              title: _licenseStatusLabel(licenseStatus),
              subtitle: _licenseExpiryText(licenseRecord) ??
                  (licenseStatus == DeviceLicenseStatus.unlimited
                      ? 'مفتوح من غير تاريخ انتهاء'.tr()
                      : 'كود الجهاز بيحدد حالة الترخيص'.tr()),
              trailing: DesktopInfoChip(
                label: _licenseStatusLabel(licenseStatus),
                icon: Icons.shield_outlined,
                color: licenseColor,
              ),
            ),
            _windowsNavRow(
              icon: Icons.fingerprint_rounded,
              iconColor: palette.info,
              title: 'كود الجهاز'.tr(),
              subtitle: DeviceRegistry.deviceCode ?? '…'.tr(),
              onTap: _copyDeviceCode,
            ),
          ]),
        ],

        // ── نسخة التطبيق ──
        _windowsSection('نسخة التطبيق'.tr(), [
          _windowsSettingRow(
            icon: Icons.verified_outlined,
            iconColor: palette.success,
            title: version,
            subtitle: 'رقم البناء: {v1}'.tr({'v1': build}),
            trailing: DesktopInfoChip(
              label: 'Saytarly',
              icon: Icons.check_circle_outline,
              color: palette.success,
            ),
          ),
          if (AppMode.isOnline) ...[
            _windowsNavRow(
              icon: Icons.system_update_alt_rounded,
              iconColor: palette.accent,
              title: 'التحقق من التحديثات'.tr(),
              subtitle: 'بيدور على نسخة أحدث على GitHub Releases'.tr(),
              onTap: () => UpdateService.instance.checkManually(),
            ),
            _windowsNavRow(
              icon: Icons.history_rounded,
              iconColor: palette.warning,
              title: 'الرجوع لنسخة أقدم'.tr(),
              subtitle: 'هرجّع التطبيق لنسخة قديمة من GitHub'.tr(),
              onTap: () => UpdateService.instance.openRollback(),
            ),
          ],
        ]),
        _windowsSection('الجهاز'.tr(), [
          _windowsNavRow(
            icon: Icons.perm_device_information_outlined,
            iconColor: palette.info,
            title: 'مواصفات هذا الجهاز'.tr(),
            subtitle: 'عرض ونسخ كود التفعيل والمكونات'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceInfoScreen()),
              );
            },
          ),
        ]),
      ],
    );
  }

  /// منطقة الخطر — كارت مميز بلون تحذيري عشان الحذف يكون واضح.
  Widget _windowsDangerSection() {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: palette.danger),
            const SizedBox(width: 6),
            Text(
              'منطقة الخطر'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(DesktopTokens.radiusLg),
            border: Border.all(
              color: palette.danger.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesktopTokens.gapLg,
                  14,
                  DesktopTokens.gapLg,
                  6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الحذف نهائي ومش بيتلغى — اعمل نسخة احتياطية الأول.'
                            .tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _windowsNavRow(
                icon: Icons.delete_forever_outlined,
                title: 'مسح كل البيانات'.tr(),
                subtitle: 'حذف الفواتير والمصروفات وكل شيء نهائياً'.tr(),
                onTap: _clearAllNow,
                danger: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: DesktopTokens.gapXl),
      ],
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

    final restColor = palette.surfaceSoft.withValues(alpha: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: HoverBuilder(
        builder:
            (context, hovering) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: AnimatedContainer(
                duration: DesktopTokens.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesktopTokens.gapMd,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: hovering ? palette.surfaceSoft : restColor,
                  borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
                ),
                child: row,
              ),
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
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          key: ValueKey<bool>(selected),
          size: 20,
          color:
              selected
                  ? palette.accent
                  : palette.textMuted.withValues(alpha: 0.7),
        ),
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
