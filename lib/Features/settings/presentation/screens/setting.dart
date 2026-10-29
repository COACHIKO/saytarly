import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/services/backup_helper.dart';
import 'package:saytarly/Features/settings/presentation/screens/device_info_screen.dart';
import 'package:saytarly/core/services/lan_backup_client.dart';
import 'package:saytarly/core/services/lan_backup_server.dart';
import 'package:saytarly/core/services/app_settings.dart';
import 'package:saytarly/core/models/material_unit.dart';
import 'package:saytarly/core/services/business_profile.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/utils/theme/cubit/accent_color_cubit.dart';
import 'package:saytarly/core/utils/theme/cubit/theme_cubit.dart';
import 'package:saytarly/Features/dashboard/presentation/screens/admin.dart';
import 'package:saytarly/Features/staff/presentation/screens/shifts_report.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/setting_mobile_body.dart';
part 'desktop/setting_windows_body.dart';

/// شاشة إعدادات موحّدة: الوضع الليلي/النهاري + شكل شاشة المشروبات.
/// أي إعداد جديد تضيفه بعدين (زي شكل لوحة الأدمن أو شكل تقرير الشيفتات)
/// يتحط هنا كقسم جديد بنفس الطريقة.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _posMode = false;
  DashStyle _dashStyle = DashStyle.current;
  ReportDesign _reportDesign = ReportDesign.classic;
  bool _loading = true;
  bool _cigarettesEnabled = false;
  bool _shishaEnabled = false;
  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final pos = await AppSettings.getDrinksScreenPosMode();
    final savedDashStyle = await AppSettings.getAdminDashStyle();
    final savedReportDesign = await AppSettings.getShiftsReportDesign();
    final cig = await AppSettings.getCigarettesEnabled();
    final shisha = await AppSettings.getShishaEnabled();

    final matchedDashStyle = DashStyle.values.where(
      (d) => d.name == savedDashStyle,
    );
    final matchedReportDesign = ReportDesign.values.where(
      (d) => d.name == savedReportDesign,
    );

    if (!mounted) return;
    setState(() {
      _posMode = pos;
      if (matchedDashStyle.isNotEmpty) _dashStyle = matchedDashStyle.first;
      if (matchedReportDesign.isNotEmpty) {
        _reportDesign = matchedReportDesign.first;
      }
      _cigarettesEnabled = cig;
      _shishaEnabled = shisha;
      _loading = false;
    });
  }

  Future<void> _changeCigarettesEnabled(bool value) async {
    setState(() => _cigarettesEnabled = value);
    await AppSettings.setCigarettesEnabled(value);
    if (!mounted) return;
    AppToast.show(value ? '✅ تم تفعيل بيع السجائر'.tr() : '✅ تم إيقاف بيع السجائر',);
  }

  Future<void> _changeShishaEnabled(bool value) async {
    setState(() => _shishaEnabled = value);
    await AppSettings.setShishaEnabled(value);
    if (!mounted) return;
    AppToast.show(value ? '✅ تم تفعيل بيع الشيشة'.tr() : '✅ تم إيقاف بيع الشيشة',);
  }

  Future<void> _backupNow() async {
    try {
      final path = await BackupHelper.backupDatabase();
      if (!mounted || path == null) return;
      AppToast.show('✅ تم حفظ نسخة احتياطية في:\n{path}'.tr({'path': path}));
    } catch (e) {
      if (!mounted) return;
      AppToast.show('❌ فشل النسخ الاحتياطي: {e}'.tr({'e': e}));
    }
  }

  Future<String?> _askRestorePassword() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AppDialog(
              title:  Text('كلمة سر الاسترجاع'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    'من فضلك أدخل كلمة السر لاسترجاع النسخة الاحتياطية.'.tr(),
                  ),
                   SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration:  InputDecoration(labelText: 'كلمة السر'.tr()),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child:  Text('إلغاء'.tr()),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      setDialogState(() => errorText = 'اكتب كلمة السر'.tr());
                      return;
                    }
                    Navigator.pop(ctx, controller.text);
                  },
                  child:  Text('تأكيد'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _restoreNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title:  Text('استرجاع نسخة احتياطية'.tr()),
        content:  Text(
          'سيتم استبدال كل البيانات الحالية بالكامل، ولا يمكن التراجع عن هذه الخطوة. متابعة؟'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text('إلغاء'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text('متابعة'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final password = await _askRestorePassword();
    if (password == null) return; // العميل لغى

    try {
      final done = await BackupHelper.restoreDatabase(password);
      if (!mounted || !done) return;
      AppToast.show('✅ تم استرجاع النسخة بنجاح، يفضل إعادة تشغيل البرنامج'.tr());
    } catch (e) {
      if (!mounted) return;
      AppToast.show('❌ فشل الاسترجاع: {e}'.tr({'e': e}));
    }
  }

  Future<String?> _askPassword({
    required String title,
    bool confirm = false,
  }) async {
    final pass1 = TextEditingController();
    final pass2 = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AppDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pass1,
                    obscureText: true,
                    decoration:  InputDecoration(labelText: 'كلمة السر'.tr()),
                  ),
                  if (confirm) ...[
                     SizedBox(height: 8),
                    TextField(
                      controller: pass2,
                      obscureText: true,
                      decoration:  InputDecoration(
                        labelText: 'تأكيد كلمة السر'.tr(),
                      ),
                    ),
                  ],
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child:  Text('إلغاء'.tr()),
                ),
                FilledButton(
                  onPressed: () {
                    if (pass1.text.trim().isEmpty) {
                      setDialogState(() => errorText = 'اكتب كلمة السر'.tr());
                      return;
                    }
                    if (confirm && pass1.text != pass2.text) {
                      setDialogState(
                        () => errorText = 'كلمتا السر غير متطابقتين'.tr(),
                      );
                      return;
                    }
                    Navigator.pop(ctx, pass1.text);
                  },
                  child:  Text('متابعة'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _clearAllNow() async {
    bool clearDebts = true; // هل نمسح حسابات الآجل (الديون) كمان؟

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AppDialog(
              title:  Text('مسح كل البيانات'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'سيتم حذف كل الفواتير والمصروفات والشيفتات والكاش نهائياً ولا يمكن التراجع. ينصح بعمل نسخة احتياطية قبل المتابعة.'.tr(),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title:  Text('مسح حسابات الآجل (الديون) أيضاً'.tr()),
                    value: clearDebts,
                    onChanged: (v) =>
                        setDialogState(() => clearDebts = v ?? true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child:  Text('إلغاء'.tr()),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child:  Text('مسح نهائياً'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;

    try {
      await BackupHelper.clearAllData(clearDebts: clearDebts);
      if (!mounted) return;
      AppToast.show('✅ تم مسح البيانات بنجاح'.tr());
    } catch (e, stackTrace) {
      // 🆕 طباعة تفصيلية كاملة للخطأ
      debugPrint('❌❌❌ فشل مسح البيانات ❌❌❌');
      debugPrint('نوع الخطأ: ${e.runtimeType}');
      debugPrint('تفاصيل الخطأ: $e');
      debugPrint('Stack trace:\n$stackTrace');

      if (!mounted) return;
      AppToast.show('❌ حصل خطأ أثناء المسح: {e}'.tr({'e': e}));
    }
  }

  Future<void> _importFromNetwork() async {
    final ipController = TextEditingController();

    final ip = await showDialog<String>(
      context: context,
      builder: (ctx) => AppDialog(
        title:  Text('استيراد من جهاز الكاشير'.tr()),
        content: TextField(
          controller: ipController,
          decoration:  InputDecoration(
            labelText: 'عنوان IP بتاع جهاز الكاشير'.tr(),
            hintText: 'مثال: 192.168.1.5'.tr(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child:  Text('إلغاء'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ipController.text.trim()),
            child:  Text('متابعة'.tr()),
          ),
        ],
      ),
    );
    if (ip == null || ip.isEmpty) return;


    final ok = await LanBackupClient.ping(ip);
    if (!ok) {
      AppToast.show('❌ مش لاقي جهاز الكاشير — تأكد إنكم على نفس الواي فاي والعنوان صحيح'.tr(),);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title:  Text('استيراد نسخة من الكاشير'.tr()),
        content:  Text(
          'سيتم استبدال كل بيانات هذا الجهاز الحالية. متابعة؟'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text('إلغاء'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text('متابعة'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final password = await _askRestorePassword(); // موجودة عندك بالفعل
    if (password == null) return;

    try {
      final bytes = await LanBackupClient.fetchLatestBackup(ip);
      await BackupHelper.restoreFromNetworkBytes(bytes, password);
      if (!mounted) return;
      AppToast.show('✅ تم استيراد النسخة من الكاشير بنجاح'.tr());
    } catch (e) {
      if (!mounted) return;
      AppToast.show('❌ فشل الاستيراد: {e}'.tr({'e': e}));
    }
  }

  Future<void> _uploadNow() async {
    try {
      await BackupHelper.saveAutoBackupSnapshot();
      if (!mounted) return;
      AppToast.show('✅ تم رفع نسخة محدّثة على الشبكة — الموبايل يقدر يستوردها الآن'.tr(),);
    } catch (e) {
      if (!mounted) return;
      AppToast.show('❌ فشل رفع النسخة: {e}'.tr({'e': e}));
    }
  }

  Future<void> _changeDrinksMode(bool value) async {
    setState(() => _posMode = value);
    await AppSettings.setDrinksScreenPosMode(value);

    if (!mounted) return;
    AppToast.show(value ? '✅ تم اختيار وضع الكاشير'.tr() : '✅ تم اختيار وضع القائمة',);
  }

  Future<void> _changeDashStyle(DashStyle value) async {
    setState(() => _dashStyle = value);
    await AppSettings.setAdminDashStyle(value.name);
  }

  Future<void> _changeReportDesign(ReportDesign value) async {
    setState(() => _reportDesign = value);
    await AppSettings.setShiftsReportDesign(value.name);
  }

  Future<void> _uploadToSupabaseNow() async {

    // 🆕 نعرض مؤشر تحميل بسيط طول ما بيرفع
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('جاري الرفع على السيرفر...'.tr())),
          ],
        ),
      ),
    );

    try {
      await BackupHelper.uploadBackupToSupabase();
      if (!mounted) return;
      Navigator.pop(context); // يقفل الـ dialog
      AppToast.show('✅ تم رفع النسخة على السيرفر بنجاح'.tr());
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AppToast.show('❌ فشل الرفع: {e}'.tr({'e': e}));
    }
  }

  Future<void> _restoreFromSupabaseNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title:  Text('استرجاع نسخة من السيرفر'.tr()),
        content:  Text(
          'سيتم استبدال كل بيانات هذا الجهاز الحالية بآخر نسخة مرفوعة على السيرفر. متابعة؟'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text('إلغاء'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text('متابعة'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final password = await _askRestorePassword();
    if (password == null) return;


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('جاري التحميل والاسترجاع...'.tr())),
          ],
        ),
      ),
    );

    try {
      // 🆕 طباعة تشخيصية قبل المحاولة
      debugPrint('🔍 بدء الاسترجاع من Supabase...');

      final ok = await BackupHelper.restoreFromSupabase(password);
      if (!mounted) return;
      Navigator.pop(context);
      if (ok) {
        debugPrint('✅ الاسترجاع نجح');
        AppToast.show('✅ تم استرجاع النسخة من السيرفر بنجاح، يفضل إعادة تشغيل البرنامج'.tr(),);
      }
    } catch (e, stackTrace) {
      // 🆕 طباعة تفصيلية كاملة للخطأ
      debugPrint('❌❌❌ فشل الاسترجاع ❌❌❌');
      debugPrint('نوع الخطأ: ${e.runtimeType}');
      debugPrint('تفاصيل الخطأ: $e');
      debugPrint('Stack trace:\n$stackTrace');

      if (!mounted) return;
      Navigator.pop(context);
      AppToast.show('❌ فشل الاسترجاع: {e}'.tr({'e': e}));
    }
  }

  // ================== تخصيص النظام — الهوية والعملة والطباعة والوحدات ==================

  /// 💰 + 🖨️ رمز العملة وعرض ورق الفاتورة واسم الطابعة.
  Future<void> _editMoneyAndPrint() async {
    final symbolCtrl = TextEditingController(
      text: await BusinessProfile.getCurrencySymbol(),
    );
    final printerCtrl = TextEditingController(
      text: await BusinessProfile.getInvoicePrinterName(),
    );
    var paperMm = await BusinessProfile.getInvoicePaperMm();
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AppDialog(
          title:  Row(
            children: [
              Icon(Icons.currency_exchange),
              SizedBox(width: 8),
              Text('العملة والطباعة'.tr()),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: symbolCtrl,
                  maxLength: 6,
                  decoration:  InputDecoration(
                    labelText: 'رمز العملة'.tr(),
                    helperText: 'مثال: ج.م / د.إ / SAR — فاضي يعني افتراضي (ج.م)'.tr(),
                    prefixIcon: Icon(Icons.payments_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                 Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('عرض ورق الفاتورة'.tr()),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final mm in BusinessProfile.invoicePaperOptions)
                      ChoiceChip(
                        label: Text('{mm} مم'.tr({'mm': mm})),
                        selected: paperMm == mm,
                        onSelected: (_) => setDlg(() => paperMm = mm),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: printerCtrl,
                  decoration:  InputDecoration(
                    labelText: 'اسم طابعة الفواتير'.tr(),
                    helperText:
                        'بالظبط زي اسمها في «الأجهزة والطابعات» بويندوز — فاضي يعني الافتراضية'.tr(),
                    prefixIcon: Icon(Icons.print),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:  Text('إلغاء'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:  Text('حفظ'.tr()),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    await BusinessProfile.setCurrencySymbol(symbolCtrl.text.trim());
    await BusinessProfile.setInvoicePrinterName(printerCtrl.text);
    await BusinessProfile.setInvoicePaperMm(paperMm);
    await Money.load(); // تحديث الرمز العام فورًا
    if (!mounted) return;
    AppToast.show('✅ تم حفظ إعدادات العملة والطباعة'.tr());
  }

  /// 🧾 نصوص رأس وقولبة الفاتورة (شكرًا/تليفون/عنوان/رقم ضريبي).
  Future<void> _editReceiptTexts() async {
    final info = await BusinessProfile.getReceiptInfo();
    final thanksCtrl = TextEditingController(text: info['thanks']);
    final phoneCtrl = TextEditingController(text: info['phone']);
    final addressCtrl = TextEditingController(text: info['address']);
    final taxIdCtrl = TextEditingController(text: info['taxId']);
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title:  Row(
          children: [
            Icon(Icons.receipt_long),
            SizedBox(width: 8),
            Text('نصوص الفاتورة'.tr()),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: thanksCtrl,
                decoration:  InputDecoration(
                  labelText: 'جملة الشكر'.tr(),
                  helperText: 'بيظهر آخر الفاتورة — فاضي يعني بيتشال'.tr(),
                  prefixIcon: Icon(Icons.waving_hand_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:  InputDecoration(
                  labelText: 'تليفون (اختياري)'.tr(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration:  InputDecoration(
                  labelText: 'العنوان (اختياري)'.tr(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: taxIdCtrl,
                decoration:  InputDecoration(
                  labelText: 'الرقم الضريبي (اختياري)'.tr(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text('إلغاء'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text('حفظ'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await BusinessProfile.setReceiptInfo(
      thanks: thanksCtrl.text,
      phone: phoneCtrl.text,
      address: addressCtrl.text,
      taxId: taxIdCtrl.text,
    );
    if (!mounted) return;
    AppToast.show('✅ تم حفظ نصوص الفاتورة — هتظهر في الطباعة من دلوقتي'.tr());
  }

  /// 📐 محرر وحدات الخامات (اسم + وحدة جزئية + عامل التحويل).
  Future<void> _editUnits() async {
    final units = await BusinessProfile.getUnits();
    final nameCtrls = [
      for (final u in units) TextEditingController(text: u.name),
    ];
    final subCtrls = [
      for (final u in units) TextEditingController(text: u.sub ?? ''),
    ];
    final factorCtrls = [
      for (final u in units)
        TextEditingController(
          text: (u.subFactor == null) ? '' : u.subFactor!.toStringAsFixed(0),
        ),
    ];
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AppDialog(
          title:  Row(
            children: [
              Icon(Icons.straighten),
              SizedBox(width: 8),
              Text('وحدات الخامات'.tr()),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  'الوحدة الجزئية للعرض الدقيق (كيلو ← جرام ×1000). سيبها فاضية لو الوحدة بسيطة زي «قطعة».'.tr(),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < nameCtrls.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nameCtrls[i],
                                    decoration:  InputDecoration(
                                      labelText: 'الوحدة'.tr(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: subCtrls[i],
                                    decoration:  InputDecoration(
                                      labelText: 'الجزئية'.tr(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 64,
                                  child: TextField(
                                    controller: factorCtrls[i],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: '×',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'حذف'.tr(),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => setDlg(() {
                                    nameCtrls.removeAt(i);
                                    subCtrls.removeAt(i);
                                    factorCtrls.removeAt(i);
                                  }),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setDlg(() {
                    nameCtrls.add(TextEditingController());
                    subCtrls.add(TextEditingController());
                    factorCtrls.add(TextEditingController());
                  }),
                  icon: const Icon(Icons.add_circle_outline),
                  label:  Text('إضافة وحدة'.tr()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:  Text('إلغاء'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:  Text('حفظ'.tr()),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final saved = <MaterialUnit>[];
    for (var i = 0; i < nameCtrls.length; i++) {
      final name = nameCtrls[i].text.trim();
      if (name.isEmpty || saved.any((u) => u.name == name)) {
        continue; // نتجاهل الفاضي والمكرر
      }
      final sub = subCtrls[i].text.trim();
      final factor = double.tryParse(factorCtrls[i].text.trim());
      saved.add(MaterialUnit(
        name: name,
        sub: sub.isEmpty ? null : sub,
        subFactor: (sub.isEmpty || factor == null) ? null : factor,
      ));
    }
    if (saved.isEmpty) {
      AppToast.show('⚠️ لازم تسيب وحدة واحدة صالحة على الأقل'.tr());
      return;
    }
    await BusinessProfile.setUnits(saved);
    if (!mounted) return;
    AppToast.show('✅ تم حفظ وحدات الخامات'.tr());
  }

  /// 🎨 لون الهوية — بيعاد بناء الثيم فورًا (لايت/دارك).
  static const List<Color> _brandSwatches = [
    Color(0xFF3A7BD5), // أزرق الكوبالة (افتراضي الدارك الحالي)
    Color(0xFF6FCF97), // أخضر اللايت الحالي
    Color(0xFF14B8A6),
    Color(0xFF00B894),
    Color(0xFFF59E0B),
    Color(0xFFE17055),
    Color(0xFFE356A8),
    Color(0xFF8E44AD),
    Color(0xFF636EFA),
    Color(0xFF2E86DE),
    Color(0xFF7F8C8D),
    Color(0xFF333333),
  ];

  Future<void> _changeBrandColor() async {
    final current = context.read<AccentColorCubit>().state.toARGB32();
    if (!mounted) return;

    final action = await showDialog<String?>(
      context: context,
      builder: (ctx) => AppDialog(
        title:  Row(
          children: [
            Icon(Icons.palette_outlined),
            SizedBox(width: 8),
            Text('لون الهوية'.tr()),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text('بيغير ألوان الأزرار والسويتشات وأغلفة ويندوز كلها.'.tr()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _brandSwatches)
                    InkWell(
                      onTap: () => Navigator.pop(ctx, 'set:${c.toARGB32()}'),
                      customBorder:  CircleBorder(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: (c.toARGB32() == current)
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, 'reset'),
                icon: const Icon(Icons.undo),
                label:  Text('رجوع للون الافتراضي'.tr()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child:  Text('إغلاق'.tr()),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (action == 'reset') {
      await context.read<AccentColorCubit>().setAccentColorIndex(0);
      AppToast.show('✅ تم الرجوع للون الافتراضي'.tr());
      return;
    }
    if (action != null && action.startsWith('set:')) {
      final swatchColor = Color(int.tryParse(action.substring(4)) ?? 0);
      await context.read<AccentColorCubit>().setAccentColor(swatchColor);
      AppToast.show('✅ تم تطبيق لون الهوية'.tr());
    }
  }

  String _dashStyleLabel(DashStyle d) {
    switch (d) {
      case DashStyle.current:
        return 'التصميم الحالي'.tr();
      case DashStyle.warmCafe:
        return 'كافيه دافئ'.tr();
      case DashStyle.professional:
        return 'لوحة احترافية'.tr();
    }
  }

  IconData _dashStyleIcon(DashStyle d) {
    switch (d) {
      case DashStyle.current:
        return Icons.dashboard_customize_outlined;
      case DashStyle.warmCafe:
        return Icons.local_cafe_outlined;
      case DashStyle.professional:
        return Icons.dashboard_outlined;
    }
  }

  String _reportDesignLabel(ReportDesign d) {
    switch (d) {
      case ReportDesign.classic:
        return 'كلاسيكي'.tr();
      case ReportDesign.cards:
        return 'كروت'.tr();
      case ReportDesign.minimal:
        return 'بسيط'.tr();
      case ReportDesign.full:
        return 'لوحة كاملة'.tr();
    }
  }

  IconData _reportDesignIcon(ReportDesign d) {
    switch (d) {
      case ReportDesign.classic:
        return Icons.view_agenda_outlined;
      case ReportDesign.cards:
        return Icons.dashboard_customize_outlined;
      case ReportDesign.minimal:
        return Icons.view_list_outlined;
      case ReportDesign.full:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

