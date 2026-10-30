part of '../setting.dart';

/// جسم شاشة الإعدادات — نسخة الموبايل (زي ما كانت بالظبط).
extension _SettingsMobileBody on _SettingsScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = context.watch<LocaleCubit>().state.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text('الإعدادات'.tr())),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _sectionTitle(context, 'اللغة'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          secondary: const Icon(Icons.language_rounded),
                          title: Text('العربية'.tr()),
                          subtitle: Text(
                            'واجهة عربية كاملة من اليمين لليسار'.tr(),
                          ),
                          value: 'ar',
                          groupValue: languageCode,
                          onChanged: (v) => _changeLanguage(v!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          secondary: const Icon(Icons.translate_rounded),
                          title: const Text('English'),
                          subtitle: const Text(
                            'Full English interface, left to right',
                          ),
                          value: 'en',
                          groupValue: languageCode,
                          onChanged: (v) => _changeLanguage(v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'المظهر العام'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
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
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'منتجات إضافية'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.smoking_rooms_outlined),
                          title: Text('بيع السجائر'.tr()),
                          subtitle: Text(
                            _cigarettesEnabled
                                ? 'مفعّل — هتظهر في شاشة البيع وإدارة المشروبات'
                                    .tr()
                                : 'متوقف — مش هتظهر في شاشة البيع'.tr(),
                          ),
                          value: _cigarettesEnabled,
                          onChanged: _changeCigarettesEnabled,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.blur_on_rounded),
                          title: Text('بيع الشيشة'.tr()),
                          subtitle: Text(
                            _shishaEnabled
                                ? 'مفعّل — هتظهر في شاشة البيع وإدارة المشروبات'
                                    .tr()
                                : 'متوقف — مش هتظهر في شاشة البيع'.tr(),
                          ),
                          value: _shishaEnabled,
                          onChanged: _changeShishaEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'تخصيص النظام لنشاطك'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.currency_exchange),
                          title: Text('العملة والطباعة'.tr()),
                          subtitle: Text(
                            'رمز العملة، ورق الفاتورة، اسم الطابعة'.tr(),
                          ),
                          onTap: _editMoneyAndPrint,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text('نصوص الفاتورة'.tr()),
                          subtitle: Text(
                            'جملة الشكر / تليفون / عنوان / رقم ضريبي'.tr(),
                          ),
                          onTap: _editReceiptTexts,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.straighten),
                          title: Text('وحدات الخامات'.tr()),
                          subtitle: Text(
                            'عدّل قائمة الوحدات على مزاج نشاطك'.tr(),
                          ),
                          onTap: _editUnits,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'شاشة إضافة المشروبات'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
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
                          subtitle: Text(
                            'عرض المشروبات كشبكة أزرار سريعة'.tr(),
                          ),
                          value: true,
                          groupValue: _posMode,
                          onChanged: (v) => _changeDrinksMode(v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'شكل لوحة الأدمن'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children:
                          DashStyle.values
                              .map(
                                (d) => RadioListTile<DashStyle>(
                                  secondary: Icon(_dashStyleIcon(d)),
                                  title: Text(_dashStyleLabel(d)),
                                  value: d,
                                  groupValue: _dashStyle,
                                  onChanged: (v) => _changeDashStyle(v!),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'شكل تقرير الشيفتات'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children:
                          ReportDesign.values
                              .map(
                                (d) => RadioListTile<ReportDesign>(
                                  secondary: Icon(_reportDesignIcon(d)),
                                  title: Text(_reportDesignLabel(d)),
                                  value: d,
                                  groupValue: _reportDesign,
                                  onChanged: (v) => _changeReportDesign(v!),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'النسخ الاحتياطي والبيانات'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
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
                          subtitle: Text(
                            'استبدال البيانات الحالية بنسخة محفوظة'.tr(),
                          ),
                          onTap: _restoreNow,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red.shade400,
                          ),
                          title: Text(
                            'مسح كل البيانات'.tr(),
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                          subtitle: Text(
                            'حذف الفواتير والمصروفات وكل شيء نهائياً'.tr(),
                          ),
                          onTap: _clearAllNow,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /*  _sectionTitle(context, 'النسخ عبر الشبكة'),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      // 🖥️ يظهر بس على جهاز الكاشير (Windows/Linux)
                      if (Platform.isWindows || Platform.isLinux) ...[
                        FutureBuilder<List<String>>(
                          future: LanBackupServer.getLocalIps(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const ListTile(
                                leading: Icon(Icons.wifi_off),
                                title: Text('غير متصل بأي شبكة'),
                              );
                            }
                            return ListTile(
                              leading: const Icon(Icons.wifi_tethering),
                              title:
                                  const Text('عنوان جهاز الكاشير على الشبكة'),
                              subtitle: Text(snapshot.data!.join(' , ')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        // 🆕 زرار رفع يدوي
                        ListTile(
                          leading: const Icon(Icons.cloud_upload_outlined),
                          title: const Text('رفع نسخة على الشبكة الآن'),
                          subtitle:
                              const Text('تحديث النسخة المتاحة للموبايل فوراً'),
                          onTap: _uploadNow,
                        ),
                      ],

                      // 📱 يظهر بس على الموبايل
                      if (Platform.isAndroid || Platform.isIOS)
                        ListTile(
                          leading: const Icon(Icons.wifi),
                          title: const Text('استيراد من جهاز الكاشير'),
                          subtitle:
                              const Text('لازم تكونوا على نفس شبكة الواي فاي'),
                          onTap: _importFromNetwork,
                        ),
                    ],
                  ),
                ),*/
                  _sectionTitle(context, 'النسخ عبر الانترنت'.tr()),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        // 🖥️ يظهر بس على جهاز الكاشير (Windows/Linux)
                        if (Platform.isWindows || Platform.isLinux) ...[
                          FutureBuilder<List<String>>(
                            future: LanBackupServer.getLocalIps(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return ListTile(
                                  leading: Icon(Icons.wifi_off),
                                  title: Text('غير متصل بأي شبكة'.tr()),
                                );
                              }
                              return ListTile(
                                leading: const Icon(Icons.wifi_tethering),
                                title: Text(
                                  'عنوان جهاز الكاشير على الشبكة'.tr(),
                                ),
                                subtitle: Text(snapshot.data!.join(' , ')),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.cloud_upload_outlined),
                            title: Text('رفع نسخة على الشبكة الآن'.tr()),
                            subtitle: Text(
                              'تحديث النسخة المتاحة للموبايل فوراً (نفس الواي فاي)'
                                  .tr(),
                            ),
                            onTap: _uploadNow,
                          ),
                          const Divider(height: 1),
                          // 🆕 رفع على السيرفر (Supabase) — يشتغل من أي مكان مش لازم نفس الواي فاي
                          ListTile(
                            leading: const Icon(Icons.cloud_done_outlined),
                            title: Text('رفع نسخة على السيرفر (كلاود)'.tr()),
                            subtitle: Text(
                              'استخدمه عشان تقدر تسترجع من أي موبايل من أي مكان'
                                  .tr(),
                            ),
                            onTap: _uploadToSupabaseNow,
                          ),
                        ],

                        // 📱 يظهر بس على الموبايل
                        if (Platform.isAndroid || Platform.isIOS) ...[
                          ListTile(
                            leading: const Icon(Icons.wifi),
                            title: Text('استيراد من جهاز الكاشير'.tr()),
                            subtitle: Text(
                              'لازم تكونوا على نفس شبكة الواي فاي'.tr(),
                            ),
                            onTap: _importFromNetwork,
                          ),
                          const Divider(height: 1),
                          // 🆕 استرجاع من السيرفر (Supabase) — من غير الحاجة لنفس الشبكة
                          ListTile(
                            leading: const Icon(Icons.cloud_download_outlined),
                            title: Text('استرجاع من السيرفر (كلاود)'.tr()),
                            subtitle: Text(
                              'يجيب آخر نسخة مرفوعة من أي مكان فيه إنترنت'.tr(),
                            ),
                            onTap: _restoreFromSupabaseNow,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.perm_device_information_outlined),
                    title: Text('مواصفات هذا الجهاز'.tr()),
                    subtitle: Text('عرض ونسخ كود التفعيل والمكونات'.tr()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeviceInfoScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
