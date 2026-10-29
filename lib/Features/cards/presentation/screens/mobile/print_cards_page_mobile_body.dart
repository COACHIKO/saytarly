part of '../print_cards_page.dart';

/// جسم شاشة طباعة كروت الإنترنت — نسخة الموبايل (زي ما كانت بالظبط).
extension _PrintCardsPageMobileBody on _PrintCardsPageState {

  Widget _buildMobileBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title:  Text('طباعة كروت الإنترنت'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              // 📌 بطاقة معلومات الشبكة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: scheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '{v1} كارت لكل صفحة مصدر'.tr({'v1': _PrintCardsPageState.totalCards}),
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            '{v1} أعمدة × {v2} صف'.tr({'v1': _PrintCardsPageState.columns, 'v2': _PrintCardsPageState.rows}),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: scheme.primary.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 📦 بطاقة المخزون
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.secondary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: scheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'المخزون: {queueCount} كارت متاح'.tr({'queueCount': queueCount}),
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

               SizedBox(height: 16),

              // 🖼️ منطقة عرض الصورة
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: imageBytes == null
                          ? scheme.outline.withOpacity(0.3)
                          : scheme.secondary,
                      width: imageBytes == null ? 1 : 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageBytes == null
                      ? _buildEmptyState(scheme, textTheme)
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4,
                                child: Image.memory(
                                  imageBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: _buildBadge(scheme, 'الصورة جاهزة'.tr()),
                            ),
                          ],
                        ),
                ),
              ),

               SizedBox(height: 16),

              // 🔘 اختيار صورة + استخراج وحفظ
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: (isExtracting || isPrinting)
                            ? null
                            : pickImage,
                        icon:  Icon(Icons.image_outlined, size: 18),
                        label:  Text(
                          'اختيار صورة'.tr(),
                          style: TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(
                            color: scheme.primary.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                   SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            (imageBytes != null && !isExtracting && !isPrinting)
                            ? extractAndSaveCards
                            : null,
                        icon: isExtracting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_alt, size: 18),
                        label: Text(
                          isExtracting ? 'جارٍ الاستخراج...'.tr() : "استخراج وحفظ",
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: scheme.outline.withOpacity(0.2)),
              const SizedBox(height: 12),

              // 🖨️ قسم الطباعة من المخزون
              Row(
                children: [
                  Text(
                    'عدد الكروت:'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    height: 44,
                    child: TextField(
                      controller: _printCountCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      enabled: !isPrinting && queueCount > 0,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed:
                            (queueCount > 0 && !isPrinting && !isExtracting)
                            ? printFromQueue
                            : null,
                        icon: isPrinting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.print_rounded, size: 20),
                        label: Text(
                          isPrinting ? 'جارٍ الطباعة...'.tr() : "طباعة",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 44,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'اختر صورة ورقة الكروت'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '{v1} كارت في شبكة {v2} × {v3}'.tr({'v1': _PrintCardsPageState.totalCards, 'v2': _PrintCardsPageState.columns, 'v3': _PrintCardsPageState.rows}),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ColorScheme scheme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: scheme.onPrimary, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

