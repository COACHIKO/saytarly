import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:image/image.dart' as img;

import 'package:printing/printing.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/Features/cards/data/card_queue_service.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/print_cards_page_mobile_body.dart';
part 'desktop/print_cards_page_windows_body.dart';

class PrintCardsPage extends StatefulWidget {
  const PrintCardsPage({super.key});

  @override
  State<PrintCardsPage> createState() => _PrintCardsPageState();
}

class _PrintCardsPageState extends State<PrintCardsPage> {
  Uint8List? imageBytes; // ✅ معاينة أول صورة/صفحة بس
  Uint8List? _rawPickedBytes; // الملف الأصلي زي ما هو (صورة أو PDF)
  bool _isPdf = false;
  int _pdfPageCount = 0;

  bool isExtracting = false;
  bool isPrinting = false;

  int queueCount = 0;
  final TextEditingController _printCountCtrl = TextEditingController(
    text: '1',
  );

  /// 🆕 كروت المخزون المعروضة في شبكة الويندوز (الموبايل مش بيستخدمها).
  List<File> _queueFiles = const [];

  static const int columns = 4;
  static const int rows = 10;
  static const int totalCards = columns * rows;

  @override
  void initState() {
    super.initState();
    _refreshQueueCount();
    _loadQueueFiles();
  }

  @override
  void dispose() {
    _printCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshQueueCount() async {
    final count = await CardQueueService.getCount();
    if (!mounted) return;
    setState(() => queueCount = count);
  }

  /// 🆕 بتحمّل ملفات كروت المخزون عشان شبكة الويندوز تعرضها (عرض بس).
  Future<void> _loadQueueFiles() async {
    final files = await CardQueueService.getFilesSorted();
    if (!mounted) return;
    setState(() => _queueFiles = files);
  }

  // ============================================================
  // 📁 اختيار صورة أو PDF. لو PDF، بنحوّل أول صفحة بس للمعاينة
  // (Preview)، لكن وقت الاستخراج الفعلي بناخد كل الصفحات.
  // ============================================================
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
    );
    if (result == null) return;

    final path = result.files.single.path!;
    final bytes = File(path).readAsBytesSync();
    final isPdf = path.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      // نحوّل أول صفحة بس عشان المعاينة السريعة، ونحسب عدد الصفحات
      final pages = await Printing.raster(bytes, dpi: 150).toList();
      if (pages.isEmpty) {
        _showSnack('ملف PDF فارغ أو غير صالح'.tr(), isError: true);
        return;
      }
      final firstPagePng = await pages.first.toPng();

      setState(() {
        _rawPickedBytes = bytes;
        _isPdf = true;
        _pdfPageCount = pages.length;
        imageBytes = firstPagePng;
      });
    } else {
      setState(() {
        _rawPickedBytes = bytes;
        _isPdf = false;
        _pdfPageCount = 0;
        imageBytes = bytes;
      });
    }
  }

  // ============================================================
  // ✂️ استخراج كل الكروت من صورة واحدة (صفحة)، وحفظهم في المخزون.
  // بيرجع عدد الكروت اللي اتحفظت من الصفحة دي.
  // ============================================================
  Future<int> _extractCardsFromSinglePage(Uint8List pageBytes) async {
    final original = img.decodeImage(pageBytes);
    if (original == null) return 0;

    final rawCardWidth = (original.width / columns).floor();
    final rawCardHeight = (original.height / rows).floor();

    int savedCount = 0;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final baseX = col * rawCardWidth;
        final baseY = row * rawCardHeight;

        final region = img.copyCrop(
          original,
          x: baseX,
          y: baseY,
          width: rawCardWidth,
          height: rawCardHeight,
        );

        var enhanced = img.adjustColor(region, contrast: 1.5);

        enhanced = img.convolution(
          enhanced,
          filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
        );

        enhanced = img.grayscale(enhanced);

        final bytes = Uint8List.fromList(img.encodePng(enhanced));
        await CardQueueService.saveCard(bytes);
        savedCount++;
      }
    }

    return savedCount;
  }

  // ============================================================
  // ✂️ استخراج وحفظ — بيدعم صورة واحدة أو PDF بعدد صفحات لا نهائي.
  // لو PDF، بيلف على كل صفحة (كل صفحة = ورقة كروت مستقلة) ويستخرج
  // منها بنفس المنطق.
  // ============================================================
  Future<void> extractAndSaveCards() async {
    if (_rawPickedBytes == null) {
      _showSnack('اختر صورة أو ملف PDF أولاً'.tr(), isError: true);
      return;
    }

    setState(() => isExtracting = true);

    try {
      int totalSaved = 0;

      if (_isPdf) {
        // 🔁 نحوّل كل صفحات الـ PDF لصور بدقة كافية للطباعة (200 DPI)
        final pages = await Printing.raster(
          _rawPickedBytes!,
          dpi: 200,
        ).toList();

        for (final page in pages) {
          final pngBytes = await page.toPng();
          totalSaved += await _extractCardsFromSinglePage(pngBytes);
        }
      } else {
        totalSaved = await _extractCardsFromSinglePage(_rawPickedBytes!);
      }

      if (!mounted) return;
      setState(() => isExtracting = false);

      await _refreshQueueCount();

      if (totalSaved == 0) {
        _showSnack('لم يتم استخراج أي كروت، تأكد من الملف'.tr(), isError: true);
      } else {
        final pagesInfo = _isPdf ? ' من {_pdfPageCount} صفحة'.tr({'_pdfPageCount': _pdfPageCount}) : "";
        _showSnack('تم حفظ {totalSaved} كارت في المخزون{pagesInfo} ✅'.tr({'totalSaved': totalSaved, 'pagesInfo': pagesInfo}));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isExtracting = false);
      _showSnack('حدث خطأ أثناء الاستخراج: {e}'.tr({'e': e}), isError: true);
    }
  }

  // ============================================================
  // 🖨️ طباعة من المخزون المشترك (نفس المنطق المستخدم في زرار
  // الكاشير السريع CardQueueIconButton).
  // ============================================================
  Future<void> printFromQueue() async {
    if (queueCount == 0) {
      _showSnack('لا يوجد كروت محفوظة في المخزون'.tr(), isError: true);
      return;
    }

    int requested = int.tryParse(_printCountCtrl.text.trim()) ?? 1;
    requested = requested.clamp(1, queueCount);

    setState(() => isPrinting = true);

    try {
      final printed = await CardQueueService.printFromQueue(requested);

      if (!mounted) return;
      setState(() => isPrinting = false);
      await _refreshQueueCount();

      _showSnack('تم طباعة {printed} كارت، والمتبقي {queueCount}'.tr({'printed': printed, 'queueCount': queueCount}));
    } catch (e) {
      if (!mounted) return;
      setState(() => isPrinting = false);
      _showSnack('حدث خطأ أثناء الطباعة: {e}'.tr({'e': e}), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    AppToast.show(
      message,
      kind: isError ? FeedbackKind.error : FeedbackKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

