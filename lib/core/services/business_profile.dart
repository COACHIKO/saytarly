import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/models/material_unit.dart';
import 'package:saytarly/core/localization/messages.dart';

/// الملف التجاري للنظام — بيتظبط من السوبر ادمن وبيتخزن في جدول app_settings
class BusinessProfile {
  /// الاسم الافتراضي لو مفيش اسم متسجل (للتوافق مع النظام القديم)
  static const String fallbackName = 'Hamza Cafe';

  /// اللوجو الافتراضي المدمج في الأصول — بيظهر لو السوبر ادمن ما اختارش صورة
  static const String defaultLogoAsset = 'assets/images/logo_hamza.jpeg';

  /// أنواع النشاط المسموحة
  static const Map<String, String> typeLabels = {
    'cafe': 'كافيه',
    'restaurant': 'مطعم',
    'restaurant_cafe': 'مطعم وكافيه',
    'playstation_cafe': 'بلايستيشن كافيه',
  };

  static Future<String> getPlaceName() async {
    final v = await DBHelper.getSetting(DBHelper.kBusinessNameKey);
    if (v == null || v.trim().isEmpty) return fallbackName;
    return v.trim();
  }

  static Future<void> setPlaceName(String name) async {
    await DBHelper.setSetting(DBHelper.kBusinessNameKey, name.trim());
  }

  // ===================== لوجو البراند =====================

  /// مسار صورة اللوجو المخصوصة (null أو '' يعني مفيش لوجو مخصوص).
  static Future<String?> getLogoPath() async {
    final v = await DBHelper.getSetting(DBHelper.kBusinessLogoKey);
    if (v == null || v.trim().isEmpty || !File(v.trim()).existsSync()) {
      return null;
    }
    return v.trim();
  }

  /// بايتس اللوجو: من الصورة المخصوصة لو موجودة، وإلا اللوجو الافتراضي
  /// المدمج. بيرجع null لو كل الاتنين مش موجودين.
  static Future<Uint8List?> getLogoBytes() async {
    final path = await getLogoPath();
    if (path != null) {
      try {
        return await File(path).readAsBytes();
      } catch (_) {
        // لو الملف اتشال، نكمل اللوجو الافتراضي
      }
    }
    try {
      return (await rootBundle.load(defaultLogoAsset)).buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// اختيار صورة من الجهاز (Windows/Android) وتخزينها في مجلد التطبيق
  /// وربطها باللوجو. بيرجع المسار المحفوظ أو null لو المستخدم ألغى.
  static Future<String?> pickAndSetLogo() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    final srcPath = picked?.files.single.path;
    if (srcPath == null) return null;

    final bytes = await File(srcPath).readAsBytes();

    final supportDir = await getApplicationSupportDirectory();
    final brandDir = Directory(
      '${supportDir.path}${Platform.pathSeparator}brand',
    );
    if (!brandDir.existsSync()) brandDir.createSync(recursive: true);

    // الامتداد — نحافظ عليه لو معروف، وإلا png
    var ext = srcPath.contains('.')
        ? srcPath.substring(srcPath.lastIndexOf('.')).toLowerCase()
        : '.png';
    if (ext.length > 5 || !RegExp(r'^\.\w+$').hasMatch(ext)) ext = '.png';

    final targetPath = '${brandDir.path}${Platform.pathSeparator}logo$ext';

    // نمسح أي نسخ قديمة بامتداد مختلف عشان مفيش لوجوهات قديمة اتسابت.
    for (final f in brandDir.listSync().whereType<File>()) {
      final base = f.uri.pathSegments.last.toLowerCase();
      if (base.startsWith('logo') && f.path != targetPath) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }

    await File(targetPath).writeAsBytes(bytes);
    await setLogoPath(targetPath, validate: false);
    return targetPath;
  }

  /// مسح اللوجو المخصوص — التطبيق يرجع للوجو الافتراضي.
  static Future<void> clearLogo() async {
    final path = await getLogoPath();
    if (path != null) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    await DBHelper.setSetting(DBHelper.kBusinessLogoKey, '');
  }

  static Future<void> setLogoPath(
    String path, {
    bool validate = true,
  }) async {
    final p = path.trim();
    if (validate && (p.isEmpty || !File(p).existsSync())) {
      await DBHelper.setSetting(DBHelper.kBusinessLogoKey, '');
      return;
    }
    await DBHelper.setSetting(DBHelper.kBusinessLogoKey, p);
  }

  static Future<String> getBusinessType() async {
    return await DBHelper.getSetting(DBHelper.kBusinessTypeKey) ?? 'cafe';
  }

  static Future<void> setBusinessType(String type) async {
    await DBHelper.setSetting(DBHelper.kBusinessTypeKey, type);
  }

  static String typeLabel(String type) => typeLabels[type] ?? type;

  /// نظام البلايستيشن (الأجهزة/الشاشات) مفعّل ولا لأ
  static Future<bool> isPlaystationEnabled() async {
    return await DBHelper.getSetting(DBHelper.kPlaystationEnabledKey) == '1';
  }

  static Future<void> setPlaystationEnabled(bool value) async {
    await DBHelper.setSetting(
      DBHelper.kPlaystationEnabledKey,
      value ? '1' : '0',
    );
  }

  /// خلص معالج التهيئة الأولية ولا لأ
  static Future<bool> isSetupCompleted() async {
    return await DBHelper.getSetting(DBHelper.kSetupCompletedKey) == '1';
  }

  static Future<void> setSetupCompleted(bool value) async {
    await DBHelper.setSetting(
      DBHelper.kSetupCompletedKey,
      value ? '1' : '0',
    );
  }

  // ===================== عملة الفواتير (قابلة للتعديل) =====================

  /// رمز العملة المخصوص — '' يعني «ج.م» الافتراضي.
  static Future<String> getCurrencySymbol() async =>
      await DBHelper.getSetting(DBHelper.kCurrencySymbolKey) ?? '';

  static Future<void> setCurrencySymbol(String symbol) async {
    await DBHelper.setSetting(DBHelper.kCurrencySymbolKey, symbol.trim());
  }

  // ===================== نصوص الفاتورة المخصصة =====================

  /// [thanks=شكر الختامية] ['phone','address','taxId' — اختيارية بتحط فوق الفاتورة]
  static Future<Map<String, String>> getReceiptInfo() async {
    return {
      'thanks': await DBHelper.getSetting(DBHelper.kReceiptThanksKey) ??
          'شكراً لزيارتكم'.tr(),
      'phone': await DBHelper.getSetting(DBHelper.kReceiptPhoneKey) ?? '',
      'address': await DBHelper.getSetting(DBHelper.kReceiptAddressKey) ?? '',
      'taxId': await DBHelper.getSetting(DBHelper.kReceiptTaxIdKey) ?? '',
    };
  }

  static Future<void> setReceiptInfo({
    required String thanks,
    String phone = '',
    String address = '',
    String taxId = '',
  }) async {
    await DBHelper.setSetting(DBHelper.kReceiptThanksKey, thanks.trim());
    await DBHelper.setSetting(DBHelper.kReceiptPhoneKey, phone.trim());
    await DBHelper.setSetting(DBHelper.kReceiptAddressKey, address.trim());
    await DBHelper.setSetting(DBHelper.kReceiptTaxIdKey, taxId.trim());
  }

  // ===================== ورق الفاتورة والطابعة =====================

  /// عروض الورق المسموحة (ميليمتر) — الفاتورة الحرارية.
  static const List<int> invoicePaperOptions = [58, 72, 75, 80];

  /// عرض ورق الفاتورة بالملم — الافتراضي 75 زي ما كان في الكود.
  static Future<int> getInvoicePaperMm() async {
    final raw = await DBHelper.getSetting(DBHelper.kInvoicePaperMmKey);
    final v = int.tryParse(raw ?? '') ?? 75;
    return invoicePaperOptions.contains(v) ? v : 75;
  }

  static Future<void> setInvoicePaperMm(int mm) async {
    await DBHelper.setSetting(
      DBHelper.kInvoicePaperMmKey,
      '${invoicePaperOptions.contains(mm) ? mm : 75}',
    );
  }

  /// اسم طابعة الفواتير بالظبط زي اسمها في ويندوز — '' يعني الافتراضية.
  static Future<String> getInvoicePrinterName() async =>
      await DBHelper.getSetting(DBHelper.kInvoicePrinterKey) ?? '';

  static Future<void> setInvoicePrinterName(String name) async {
    await DBHelper.setSetting(DBHelper.kInvoicePrinterKey, name.trim());
  }

  // ===================== وحدات الخامات =====================

  /// الوحدات الافتراضية — نفس القائمة القديمة المكتوبة كود + ربط التحويل.
  static List<MaterialUnit> get defaultUnits => [
    MaterialUnit(name: 'كيلو'.tr(), sub: 'جرام'.tr(), subFactor: 1000),
    MaterialUnit(name: 'لتر'.tr(), sub: 'مل'.tr(), subFactor: 1000),
    MaterialUnit(name: 'جرام'.tr()),
    MaterialUnit(name: 'مل'.tr()),
    MaterialUnit(name: 'قطعة'.tr()),
  ];

  /// قائمة وحدات الخامات — بيتظبط من السوبر ادمن عشان الأعمال المختلفة.
  static Future<List<MaterialUnit>> getUnits() async {
    final raw = await DBHelper.getSetting(DBHelper.kMaterialUnitsKey);
    if (raw == null || raw.trim().isEmpty) return defaultUnits;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => MaterialUnit.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      return list.isEmpty ? defaultUnits : list;
    } catch (_) {
      return defaultUnits;
    }
  }

  static Future<void> setUnits(List<MaterialUnit> units) async =>
      await DBHelper.setSetting(
        DBHelper.kMaterialUnitsKey,
        jsonEncode([for (final u in units) u.toMap()]),
      );
}
