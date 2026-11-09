part of '../setting.dart';

/// جسم شاشة الإعدادات — نسخة الموبايل.
///
/// نفس تبويبات الويندوز (المظهر ← الشاشات ← النشاط ← النسخ والبيانات ←
/// الجهاز) في شريط تبويبات أفقي قابل للتمرير، والمحتوى بيتحرك بأنيميشن
/// fade + slide ناعم.
extension _SettingsMobileBody on _SettingsScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الإعدادات'.tr())),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _mobileTabBar(context),
                  Expanded(
                    child: AnimatedSwitcher(
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
                  ),
                ],
              ),
    );
  }

  // ============================ شريط التبويبات ============================

  Widget _mobileTabBar(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _mobileTabPill(context, i),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _tabs[_tab].description,
                key: ValueKey<int>(_tab),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileTabPill(BuildContext context, int index) {
    final theme = Theme.of(context);
    final tab = _tabs[index];
    final selected = _tab == index;
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => _setTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 16,
              color: selected ? primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              tab.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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

  Widget _appearanceTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = context.watch<LocaleCubit>().state.locale.languageCode;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionTitle(context, 'اللغة'.tr()),
        _mobileCard([
          RadioListTile<String>(
            secondary: const Icon(Icons.language_rounded),
            title: Text('العربية'.tr()),
            subtitle: Text('واجهة عربية كاملة من اليمين لليسار'.tr()),
            value: 'ar',
            groupValue: languageCode,
            onChanged: (v) => _changeLanguage(v!),
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            secondary: const Icon(Icons.translate_rounded),
            title: const Text('English'),
            subtitle: const Text('Full English interface, left to right'),
            value: 'en',
            groupValue: languageCode,
            onChanged: (v) => _changeLanguage(v!),
          ),
        ]),
        _sectionTitle(context, 'المظهر العام'.tr()),
        _mobileCard([
          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            ),
            title: Text('الوضع الليلي'.tr()),
            subtitle: Text(
              isDark
                  ? 'الوضع الليلي مفعّل الآن'.tr()
                  : 'الوضع النهاري مفعّل الآن'.tr(),
            ),
            value: isDark,
            onChanged: (_) => context.read<ThemeCubit>().toggle(),
          ),
        ]),
      ],
    );
  }

  Widget _screensTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionTitle(context, 'شاشة إضافة المشروبات'.tr()),
        _mobileCard([
          RadioListTile<bool>(
            secondary: const Icon(Icons.view_list_rounded),
            title: Text('قائمة'.tr()),
            subtitle: Text('عرض المشروبات كقائمة عادية'.tr()),
            value: false,
            groupValue: _posMode,
            onChanged: (v) => _changeDrinksMode(v!),
          ),
          const Divider(height: 1),
          RadioListTile<bool>(
            secondary: const Icon(Icons.grid_view_rounded),
            title: Text('كاشير'.tr()),
            subtitle: Text('عرض المشروبات كشبكة أزرار سريعة'.tr()),
            value: true,
            groupValue: _posMode,
            onChanged: (v) => _changeDrinksMode(v!),
          ),
        ]),
        _sectionTitle(context, 'شكل لوحة الأدمن'.tr()),
        _mobileCard([
          for (final d in DashStyle.values) ...[
            RadioListTile<DashStyle>(
              secondary: Icon(_dashStyleIcon(d)),
              title: Text(_dashStyleLabel(d)),
              value: d,
              groupValue: _dashStyle,
              onChanged: (v) => _changeDashStyle(v!),
            ),
            if (d != DashStyle.values.last) const Divider(height: 1),
          ],
        ]),
        _sectionTitle(context, 'شكل تقرير الشيفتات'.tr()),
        _mobileCard([
          for (final d in ReportDesign.values) ...[
            RadioListTile<ReportDesign>(
              secondary: Icon(_reportDesignIcon(d)),
              title: Text(_reportDesignLabel(d)),
              value: d,
              groupValue: _reportDesign,
              onChanged: (v) => _changeReportDesign(v!),
            ),
            if (d != ReportDesign.values.last) const Divider(height: 1),
          ],
        ]),
      ],
    );
  }

  Widget _businessTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionTitle(context, 'تخصيص النظام لنشاطك'.tr()),
        _mobileCard([
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text('العملة والطباعة'.tr()),
            subtitle: Text('رمز العملة، ورق الفاتورة، اسم الطابعة'.tr()),
            onTap: _editMoneyAndPrint,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('نصوص الفاتورة'.tr()),
            subtitle: Text('جملة الشكر / تليفون / عنوان / رقم ضريبي'.tr()),
            onTap: _editReceiptTexts,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: Text('وحدات الخامات'.tr()),
            subtitle: Text('عدّل قائمة الوحدات على مزاج نشاطك'.tr()),
            onTap: _editUnits,
          ),
        ]),
      ],
    );
  }

  Widget _backupTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionTitle(context, 'النسخ الاحتياطي والبيانات'.tr()),
        _mobileCard([
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text('نسخ احتياطي كامل'.tr()),
            subtitle: Text('حفظ نسخة من كل بيانات البرنامج'.tr()),
            onTap: _backupNow,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: Text('استرجاع نسخة احتياطية'.tr()),
            subtitle: Text('استبدال البيانات الحالية بنسخة محفوظة'.tr()),
            onTap: _restoreNow,
          ),
        ]),
        _sectionTitle(context, 'النسخ عبر الانترنت'.tr()),
        _mobileCard([
          // 🖥️ يظهر بس على جهاز الكاشير (Windows/Linux)
          if (Platform.isWindows || Platform.isLinux) ...[
            FutureBuilder<List<String>>(
              future: LanBackupServer.getLocalIps(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return ListTile(
                    leading: const Icon(Icons.wifi_off),
                    title: Text('غير متصل بأي شبكة'.tr()),
                  );
                }
                return ListTile(
                  leading: const Icon(Icons.wifi_tethering),
                  title: Text('عنوان جهاز الكاشير على الشبكة'.tr()),
                  subtitle: Text(snapshot.data!.join(' , ')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text('رفع نسخة على الشبكة الآن'.tr()),
              subtitle: Text(
                'تحديث النسخة المتاحة للموبايل فوراً (نفس الواي فاي)'.tr(),
              ),
              onTap: _uploadNow,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_done_outlined),
              title: Text('رفع نسخة على السيرفر (كلاود)'.tr()),
              subtitle: Text(
                'استخدمه عشان تقدر تسترجع من أي موبايل من أي مكان'.tr(),
              ),
              onTap: _uploadToSupabaseNow,
            ),
          ],

          // 📱 يظهر بس على الموبايل
          if (Platform.isAndroid || Platform.isIOS) ...[
            ListTile(
              leading: const Icon(Icons.wifi),
              title: Text('استيراد من جهاز الكاشير'.tr()),
              subtitle: Text('لازم تكونوا على نفس شبكة الواي فاي'.tr()),
              onTap: _importFromNetwork,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text('استرجاع من السيرفر (كلاود)'.tr()),
              subtitle: Text('يجيب آخر نسخة مرفوعة من أي مكان فيه إنترنت'.tr()),
              onTap: _restoreFromSupabaseNow,
            ),
          ],
        ]),
        _sectionTitle(
          context,
          'منطقة الخطر'.tr(),
          color: theme.colorScheme.error,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'الحذف نهائي ومش بيتلغى — اعمل نسخة احتياطية الأول.'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'مسح كل البيانات'.tr(),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: Text(
                  'حذف الفواتير والمصروفات وكل شيء نهائياً'.tr(),
                ),
                onTap: _clearAllNow,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deviceTab(BuildContext context) {
    final theme = Theme.of(context);
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
      DeviceLicenseStatus.active => Colors.green.shade400,
      DeviceLicenseStatus.expired ||
      DeviceLicenseStatus.blocked => theme.colorScheme.error,
      DeviceLicenseStatus.pending => Colors.amber.shade600,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── وضع التطبيق ──
        _sectionTitle(context, 'وضع التطبيق'.tr()),
        _mobileCard([
          ListTile(
            leading: Icon(
              AppMode.isOnline
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: AppMode.isOnline
                  ? Colors.green.shade400
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(AppMode.isOnline ? 'Online'.tr() : 'Offline'.tr()),
            subtitle: Text(
              AppMode.isOnline
                  ? 'تحديثات GitHub + تسجيل الأجهزة والتراخيص'.tr()
                  : 'من غير أي خدمات سحابية'.tr(),
            ),
            trailing: Icon(
              AppMode.isOnline ? Icons.check_circle : Icons.link_off,
              color: AppMode.isOnline
                  ? Colors.green.shade400
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ]),

        // ── الترخيص (online بس) ──
        if (AppMode.isOnline) ...[
          _sectionTitle(context, 'الترخيص'.tr()),
          _mobileCard([
            ListTile(
              leading: Icon(Icons.workspace_premium_outlined, color: licenseColor),
              title: Text(_licenseStatusLabel(licenseStatus)),
              subtitle: Text(
                _licenseExpiryText(licenseRecord) ??
                    (licenseStatus == DeviceLicenseStatus.unlimited
                        ? 'مفتوح من غير تاريخ انتهاء'.tr()
                        : 'كود الجهاز بيحدد حالة الترخيص'.tr()),
              ),
              trailing: Text(
                _licenseStatusLabel(licenseStatus),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: licenseColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.fingerprint_rounded, color: theme.colorScheme.primary),
              title: Text('كود الجهاز'.tr()),
              subtitle: Text(DeviceRegistry.deviceCode ?? '…'.tr()),
              onTap: _copyDeviceCode,
            ),
          ]),
        ],

        // ── نسخة التطبيق ──
        _sectionTitle(context, 'نسخة التطبيق'.tr()),
        _mobileCard([
          ListTile(
            leading: Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
            title: Text(version),
            subtitle: Text('رقم البناء: {v1}'.tr({'v1': build})),
            trailing: Text(
              'Saytarly',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (AppMode.isOnline) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.system_update_alt_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text('التحقق من التحديثات'.tr()),
              subtitle: Text('بيدور على نسخة أحدث على GitHub Releases'.tr()),
              onTap: () => UpdateService.instance.checkManually(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.history_rounded,
                color: theme.colorScheme.tertiary,
              ),
              title: Text('الرجوع لنسخة أقدم'.tr()),
              subtitle: Text('هرجّع التطبيق لنسخة قديمة من GitHub'.tr()),
              onTap: () => UpdateService.instance.openRollback(),
            ),
          ],
        ]),
        _sectionTitle(context, 'الجهاز'.tr()),
        _mobileCard([
          ListTile(
            leading: const Icon(Icons.perm_device_information_outlined),
            title: Text('مواصفات هذا الجهاز'.tr()),
            subtitle: Text('عرض ونسخ كود التفعيل والمكونات'.tr()),
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

  // ============================ عناصر مساعدة ============================

  Widget _mobileCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
