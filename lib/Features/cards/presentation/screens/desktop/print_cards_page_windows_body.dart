part of '../print_cards_page.dart';

/// جسم شاشة طباعة كروت الإنترنت — نسخة الويندوز (Windows UI).
///
/// نفس المنطق بالظبط — مفيش أي تغيير في [CardQueueService]: اختيار صورة/PDF،
/// استخراج وحفظ، وطباعة من المخزون بنفس الميثودس. الشكل بس هو اللي اتغيّر:
/// مؤشرات سريعة + معاينة الورقة بتكبير + كارت الطباعة + شبكة كروت المخزون
/// بالهوفر (عرض للكروت المحفوظة عن طريق [CardQueueService.getFilesSorted]).
extension _PrintCardsPageWindowsBody on _PrintCardsPageState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final canPick = !isExtracting && !isPrinting;
    final canExtract = imageBytes != null && !isExtracting && !isPrinting;
    final canPrint = queueCount > 0 && !isPrinting && !isExtracting;

    return DesktopPageScaffold(
      title: 'طباعة كروت الإنترنت'.tr(),
      subtitle: '{v1} كارت لكل صفحة • شبكة {v2} × {v3}'.tr({
        'v1': _PrintCardsPageState.totalCards,
        'v2': _PrintCardsPageState.columns,
        'v3': _PrintCardsPageState.rows,
      }),
      actions: [
        DesktopButton.ghost(
          label: 'اختيار صورة أو PDF'.tr(),
          icon: Icons.image_outlined,
          onPressed: canPick ? pickImage : null,
        ),
        DesktopButton.primary(
          label: isExtracting ? 'جارٍ الاستخراج...'.tr() : 'استخراج وحفظ'.tr(),
          icon: Icons.save_alt,
          onPressed:
              canExtract
                  ? () async {
                    await extractAndSaveCards();
                    await _loadQueueFiles();
                  }
                  : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات سريعة ====================
          DesktopResponsiveGrid(
            minTileWidth: 225,
            maxColumns: 4,
            children: [
              DesktopStatCard(
                label: 'المخزون المتاح'.tr(),
                value: '{queueCount} كارت'.tr({'queueCount': queueCount}),
                icon: Icons.inventory_2_outlined,
                color: palette.success,
              ),
              DesktopStatCard(
                label: 'كروت لكل صفحة مصدر'.tr(),
                value: '${_PrintCardsPageState.totalCards}',
                icon: Icons.grid_view_rounded,
                color: palette.accent,
              ),
              DesktopStatCard(
                label: 'شبكة الورقة'.tr(),
                value:
                    '${_PrintCardsPageState.columns} × ${_PrintCardsPageState.rows}',
                icon: Icons.table_chart_outlined,
                color: palette.info,
              ),
              DesktopStatCard(
                label: 'الملف المختار'.tr(),
                value:
                    imageBytes == null
                        ? 'مفيش ملف'.tr()
                        : (_isPdf
                            ? 'PDF • {_pdfPageCount} صفحة'.tr({
                              '_pdfPageCount': _pdfPageCount,
                            })
                            : 'صورة'.tr()),
                icon:
                    imageBytes == null
                        ? Icons.upload_file_outlined
                        : (_isPdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined),
                color: palette.warning,
              ),
            ],
          ),

          SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== معاينة الورقة ====================
          DesktopSectionTitle(title: 'معاينة ورقة الكروت'.tr()),
          DesktopCard(
            padding: EdgeInsets.all(DesktopTokens.gapSm),
            child: SizedBox(
              width: double.infinity,
              height: 420,
              child:
                  imageBytes == null
                      ? DesktopEmptyState(
                        icon: Icons.add_photo_alternate_outlined,
                        title: 'اختر صورة ورقة الكروت'.tr(),
                        message: '{v1} كارت في شبكة {v2} × {v3}'.tr({
                          'v1': _PrintCardsPageState.totalCards,
                          'v2': _PrintCardsPageState.columns,
                          'v3': _PrintCardsPageState.rows,
                        }),
                        action: DesktopButton.primary(
                          label: 'اختيار صورة أو PDF'.tr(),
                          icon: Icons.image_outlined,
                          onPressed: canPick ? pickImage : null,
                        ),
                      )
                      : Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  DesktopTokens.radiusMd,
                                ),
                                child: Image.memory(
                                  imageBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: DesktopInfoChip(
                              label:
                                  _isPdf
                                      ? 'PDF جاهز • {_pdfPageCount} صفحة'.tr({
                                        '_pdfPageCount': _pdfPageCount,
                                      })
                                      : 'الصورة جاهزة',
                              icon: Icons.check_circle_outline,
                              color: palette.success,
                            ),
                          ),
                        ],
                      ),
            ),
          ),

          SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== الطباعة من المخزون ====================
          DesktopSectionTitle(
            title: 'الطباعة من المخزون'.tr(),
            count: queueCount,
          ),
          DesktopCard(
            child: Row(
              children: [
                Icon(Icons.print_rounded, size: 20, color: palette.accentText),
                const SizedBox(width: DesktopTokens.gapSm),
                Text(
                  'عدد الكروت:'.tr(),
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: DesktopTokens.gapSm),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _printCountCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    enabled: !isPrinting && queueCount > 0,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: palette.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          DesktopTokens.radiusSm,
                        ),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          DesktopTokens.radiusSm,
                        ),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          DesktopTokens.radiusSm,
                        ),
                        borderSide: BorderSide(color: palette.accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesktopTokens.gapMd),
                DesktopButton.primary(
                  label: isPrinting ? 'جارٍ الطباعة...'.tr() : 'طباعة',
                  icon: Icons.print_rounded,
                  onPressed:
                      canPrint
                          ? () async {
                            await printFromQueue();
                            await _loadQueueFiles();
                          }
                          : null,
                ),
                const Spacer(),
                DesktopInfoChip(
                  label: 'المتاح: {queueCount} كارت'.tr({
                    'queueCount': queueCount,
                  }),
                  icon: Icons.inventory_2_outlined,
                  color: palette.success,
                ),
              ],
            ),
          ),

          SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== شبكة كروت المخزون ====================
          DesktopSectionTitle(title: 'كروت المخزون'.tr(), count: queueCount),
          if (_queueFiles.isEmpty)
            DesktopEmptyState(
              icon: Icons.inbox_outlined,
              title: 'المخزون فاضي'.tr(),
              message:
                  'اختر صورة ورقة كروت واستخرجها — الكروت هتتحفظ هنا وتقدر تطبع منها في أي وقت.'
                      .tr(),
            )
          else
            DesktopResponsiveGrid(
              minTileWidth: 150,
              maxColumns: 8,
              children: [
                for (final file in _queueFiles)
                  _pcCardTile(context, palette, file),
              ],
            ),
        ],
      ),
    );
  }

  /// كارت صغير لكرت محفوظ في المخزون — بهوفر وحدود ناعمة.
  Widget _pcCardTile(BuildContext context, DesktopPalette palette, File file) {
    return DesktopCard(
      hover: true,
      padding: const EdgeInsets.all(DesktopTokens.gapXs),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
          child: Container(
            color: palette.surfaceSoft,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, _, _) => Icon(
                    Icons.broken_image_outlined,
                    color: palette.textMuted,
                    size: 22,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
