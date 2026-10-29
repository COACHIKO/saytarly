import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/localization/messages.dart';

class BackupHelper {
  static const String _backupPassword = '2010';
  static const String _magic = 'XOCFBK1';

  // 🆕 اسم الـ bucket على Supabase
  static const String _bucketName = 'backups';

  // 🆕 هنا حاطط اسم ثابت للملف على السيرفر (آخر نسخة بس بتتفوق فوق اللي قبلها)
  // ممكن تغيّره لو عايز تحتفظ بأكتر من نسخة (شوف الملاحظة تحت)
  static const String _remoteFileName = 'latest_backup.xocb';

  static Future<String> _dbPath() async {
    return p.join(await getDatabasesPath(), 'xo_cafe57.db');
  }

  static Future<String> _autoBackupPath() async {
    final base = await getDatabasesPath();
    final dir = Directory(p.join(base, 'auto_backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return p.join(dir.path, 'latest.xocb');
  }

  static enc.Key _deriveKey(String password, List<int> salt) {
    final bytes = <int>[...utf8.encode(password), ...salt];
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 🆕 رفع النسخة الاحتياطية الحالية على Supabase Storage
  static Future<void> uploadBackupToSupabase({
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('جاري تجهيز النسخة...'.tr());
    final bytes = await _buildEncryptedBackupBytes();

    onStatus?.call('جاري الرفع على السيرفر...'.tr());
    final storage = Supabase.instance.client.storage.from(_bucketName);

    try {
      await storage.uploadBinary(
        _remoteFileName,
        bytes,
        fileOptions: const FileOptions(
          upsert: true, // 🆕 يستبدل النسخة القديمة بدل ما يرفض الرفع
          contentType: 'application/octet-stream',
        ),
      );
      onStatus?.call('✅ تم الرفع بنجاح'.tr());
    } on StorageException catch (e) {
      onStatus?.call('❌ فشل الرفع: {v1}'.tr({'v1': e.message}));
      rethrow;
    }
  }

  /// 🆕 تحميل واسترجاع النسخة من Supabase Storage (يستخدمها الموبايل)
  static Future<bool> restoreFromSupabase(
    String enteredPassword, {
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('جاري التحميل من السيرفر...'.tr());
    final storage = Supabase.instance.client.storage.from(_bucketName);

    Uint8List bytes;
    try {
      bytes = await storage.download(_remoteFileName);
    } on StorageException catch (e) {
      onStatus?.call('❌ فشل التحميل: {v1}'.tr({'v1': e.message}));
      rethrow;
    }

    onStatus?.call('جاري فك التشفير والاسترجاع...'.tr());
    final ok = await _decryptAndInstall(bytes, enteredPassword);
    if (ok) onStatus?.call('✅ تم الاسترجاع بنجاح'.tr());
    return ok;
  }

  static Future<Uint8List> _buildEncryptedBackupBytes() async {
    final dbFile = File(await _dbPath());
    if (!await dbFile.exists()) {
      throw Exception('قاعدة البيانات غير موجودة'.tr());
    }

    await DBHelper.closeDB();
    List<int> rawBytes;
    try {
      rawBytes = await dbFile.readAsBytes();
    } finally {
      await DBHelper.initDB();
    }

    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final iv = enc.IV.fromSecureRandom(16);
    final key = _deriveKey(_backupPassword, salt);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(rawBytes, iv: iv);

    final output = BytesBuilder()
      ..add(utf8.encode(_magic))
      ..add(salt)
      ..add(iv.bytes)
      ..add(encrypted.bytes);

    return Uint8List.fromList(output.toBytes());
  }

  /// نسخ احتياطي يدوي — بيفتح نافذة اختيار مكان الحفظ
  static Future<String?> backupDatabase() async {
    final bytes = await _buildEncryptedBackupBytes();

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final suggestedName = 'Hamza_cafe_backup_$timestamp.xocb';

    String? savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية'.tr(),
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: ['xocb'],
    );

    if (savePath != null) {
      if (!savePath.toLowerCase().endsWith('.xocb')) {
        savePath = '$savePath.xocb';
      }
      await File(savePath).writeAsBytes(bytes);
    }

    return savePath;
  }

  /// 🆕 بيتنفذ تلقائياً بعد قفل أي شيفت
  static Future<void> saveAutoBackupSnapshot() async {
    try {
      final bytes = await _buildEncryptedBackupBytes();
      final path = await _autoBackupPath();
      await File(path).writeAsBytes(bytes);
      print('✅ تم حفظ نسخة تلقائية بعد قفل الشيفت');
    } catch (e) {
      print('⚠️ فشل حفظ النسخة التلقائية: $e');
    }
  }

  /// 🆕 بيقرأ آخر نسخة تلقائية (يستخدمها سيرفر الشبكة)
  static Future<Uint8List?> getLatestAutoBackupBytes() async {
    try {
      final path = await _autoBackupPath();
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _decryptAndInstall(
    Uint8List bytes,
    String enteredPassword,
  ) async {
    if (enteredPassword != _backupPassword) {
      throw Exception('كلمة السر غير صحيحة'.tr());
    }

    final magicBytes = utf8.encode(_magic);
    if (bytes.length < magicBytes.length + 32 ||
        !_bytesEqual(bytes.sublist(0, magicBytes.length), magicBytes)) {
      throw Exception('الملف ده مش نسخة احتياطية صالحة'.tr());
    }

    int offset = magicBytes.length;
    final salt = bytes.sublist(offset, offset + 16);
    offset += 16;
    final ivBytes = bytes.sublist(offset, offset + 16);
    offset += 16;
    final cipherBytes = bytes.sublist(offset);

    final key = _deriveKey(_backupPassword, salt);
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    List<int> decrypted;
    try {
      decrypted = encrypter.decryptBytes(
        enc.Encrypted(Uint8List.fromList(cipherBytes)),
        iv: iv,
      );
    } catch (_) {
      throw Exception('الملف تالف أو غير صالح'.tr());
    }

    final header = utf8.decode(
      decrypted.take(16).toList(),
      allowMalformed: true,
    );
    if (!header.startsWith('SQLite format 3')) {
      throw Exception('الملف تالف أو غير صالح'.tr());
    }

    final dbPath = await _dbPath();
    await DBHelper.closeDB();
    await File(dbPath).writeAsBytes(decrypted);
    await DBHelper.initDB();

    return true;
  }

  /// استرجاع يدوي من ملف على الجهاز
  static Future<bool> restoreDatabase(String enteredPassword) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملف النسخة الاحتياطية'.tr(),
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return false;

    final bytes = await File(result.files.single.path!).readAsBytes();
    return _decryptAndInstall(bytes, enteredPassword);
  }

  /// 🆕 استرجاع من بايتات جايالة عبر الشبكة
  static Future<bool> restoreFromNetworkBytes(
    Uint8List bytes,
    String enteredPassword,
  ) async {
    return _decryptAndInstall(bytes, enteredPassword);
  }

  /// مسح كل البيانات
  static Future<void> clearAllData({required bool clearDebts}) async {
    final db = await DBHelper.database;

    await db.transaction((txn) async {
      await txn.delete('invoices');
      await txn.delete('invoice_items');
      await txn.delete('invoice_drinks');
      await txn.delete('orders');
      await txn.delete('order_items');
      await txn.delete('cash_drawer');
      await txn.delete('expenses');
      await txn.delete('transactions');
      await txn.delete('vodafone_cash_notes');
      await txn.delete('material_transactions');
      await txn.delete('material_inventory_history');
      await txn.delete('stock_movements');
      await txn.delete('shifts');
      await txn.delete('staff_shifts');
      await txn.delete('payrolls');
      await txn.delete('salaries');
      await txn.delete('staff_due_salaries');
      await txn.delete('audit_log');
      await txn.update('machine_balance', {'balance': 0.0});
      await txn.delete('machine_balance_logs');
      await txn.delete('customers');

      if (clearDebts) {
        await txn.delete('debt_payments');
        await txn.delete('debt_items');
        await txn.delete('debts');
      }
    });

    await db.insert('customers', {'name': 'AdminCash', 'balance': 0});
  }
}
