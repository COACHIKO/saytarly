import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:image/image.dart' as img;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';

/// خدمة مشتركة لإدارة "مخزون" كروت الإنترنت المحفوظة (كملفات PNG)،
/// عشان أي شاشة في التطبيق (صفحة الطباعة، شاشة الكاشير...) تقدر
/// تعرض العدد المتبقي وتطبع منه بنفس المنطق، من غير تكرار كود.
class CardQueueService {
  static Future<Directory> getQueueDir() async {
    final baseDir = await getApplicationSupportDirectory();
    final queueDir = Directory(p.join(baseDir.path, 'card_queue'));
    if (!await queueDir.exists()) {
      await queueDir.create(recursive: true);
    }
    return queueDir;
  }

  /// كل ملفات الكروت المحفوظة، مرتبة من الأقدم للأحدث (بترتيب الاسم
  /// التسلسلي)، عشان الطباعة تاخد الأقدم أولًا دايمًا.
  static Future<List<File>> getFilesSorted() async {
    final dir = await getQueueDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .toList();
    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return files;
  }

  static Future<int> getCount() async {
    final files = await getFilesSorted();
    return files.length;
  }

  static Future<int> _nextIndex() async {
    final files = await getFilesSorted();
    if (files.isEmpty) return 1;
    final lastName = p.basenameWithoutExtension(files.last.path);
    final lastNum = int.tryParse(lastName.split('_').last) ?? files.length;
    return lastNum + 1;
  }

  /// يحفظ كارت واحد (بايتات PNG جاهزة) في المخزون بترقيم تسلسلي.
  static Future<void> saveCard(Uint8List pngBytes) async {
    final dir = await getQueueDir();
    final idx = await _nextIndex();
    final fileName = 'card_${idx.toString().padLeft(6, '0')}.png';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(pngBytes);
  }

  /// يطبع أقدم [count] كارت من المخزون، ويمسحهم من المخزون بعد
  /// نجاح الطباعة فقط (لو حصل خطأ أو المستخدم قفل نافذة الطباعة،
  /// الكروت بتفضل محفوظة). بيرجع عدد الكروت اللي اتطبعت فعليًا.
  static Future<int> printFromQueue(int count) async {
    final files = await getFilesSorted();
    if (files.isEmpty) return 0;

    final requested = count.clamp(1, files.length);
    final selected = files.take(requested).toList();

    final pdf = pw.Document();

    for (final file in selected) {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      final memoryImage = pw.MemoryImage(bytes);

      const double printWidthMm = 70;
      final double printHeightMm =
          printWidthMm * (decoded.height / decoded.width);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            printWidthMm * PdfPageFormat.mm,
            printHeightMm * PdfPageFormat.mm,
            marginAll: 0,
          ),
          build: (context) => pw.Image(memoryImage, fit: pw.BoxFit.contain),
        ),
      );
    }

    await Printing.layoutPdf(
      usePrinterSettings: true,
      onLayout: (_) async => pdf.save(),
    );

    for (final file in selected) {
      if (await file.exists()) {
        await file.delete();
      }
    }

    return selected.length;
  }
}
