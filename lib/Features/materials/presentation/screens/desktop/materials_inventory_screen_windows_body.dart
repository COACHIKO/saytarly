part of '../MaterialsInventoryScreen.dart';

/// جسم جرد الخامات — نسخة الويندوز (Windows UI).
///
/// نفس المنطق: مؤشرات (عدد / عجز / زيادة) + جدول صفوف بكروت، خانة
/// "الرصيد الفعلي" بنفس الـ controller والـ DB، وبنفس أزرار الطباعة
/// واعتماد الجرد وإعادة الحساب.
extension _MaterialsInventoryScreenWindowsBody
    on _MaterialsInventoryScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final shortageCount = reports.where((e) => e.isShortage).length;
    final excessCount = reports.where((e) => e.isExcess).length;

    return DesktopPageScaffold(
      title: 'جرد الخامات'.tr(),
      subtitle: 'عدد الأصناف: {v1}'.tr({'v1': reports.length}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.all_inclusive_outlined,
          tooltip: 'إعادة حساب الجرد'.tr(),
          onPressed: () => loadReport(),
        ),
        DesktopButton.ghost(
          label: 'طباعة PDF'.tr(),
          icon: Icons.picture_as_pdf_outlined,
          onPressed: () => printPdf(),
        ),
        DesktopButton.primary(
          label: 'اعتماد الجرد'.tr(),
          icon: Icons.save_outlined,
          onPressed: () => approveInventory(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات ====================
          DesktopResponsiveGrid(
            minTileWidth: 240,
            maxColumns: 3,
            children: [
              DesktopStatCard(
                label: 'عدد الخامات'.tr(),
                value: '${reports.length}',
                icon: Icons.inventory_2_outlined,
                color: palette.info,
                hint: 'الخامات المشتركة بين كل الأقسام'.tr(),
              ),
              DesktopStatCard(
                label: 'أصناف عليها عجز'.tr(),
                value: '$shortageCount',
                icon: Icons.trending_down_outlined,
                color: palette.danger,
              ),
              DesktopStatCard(
                label: 'أصناف عليها زيادة'.tr(),
                value: '$excessCount',
                icon: Icons.trending_up_outlined,
                color: palette.success,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg),

          // ==================== جدول الجرد ====================
          DesktopSectionTitle(title: 'الرصيد الفعلي'.tr(), count: reports.length),
          if (reports.isEmpty)
             DesktopEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'مفيش خامات للجرد'.tr(),
              message: 'ضيف الخامات الأول من شاشة إدارة الخامات.'.tr(),
            )
          else ...[
            _windowsTableHeader(palette),
            const SizedBox(height: DesktopTokens.gapSm),
            for (final r in reports) ...[
              _windowsReportRow(palette, r),
              const SizedBox(height: DesktopTokens.gapSm),
            ],
          ],
          const SizedBox(height: DesktopTokens.gapLg),
        ],
      ),
    );
  }

  Widget _windowsTableHeader(DesktopPalette palette) {
    final style = TextStyle(
      color: palette.textMuted,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('الخامة'.tr(), style: style)),
          Expanded(
            flex: 2,
            child: Text(
              'رصيد أول الفترة'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'المضاف'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'المستهلك'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'رصيد النظام'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'الرصيد الفعلي'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'الفرق'.tr(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowsReportRow(DesktopPalette palette, InventoryReportModel report) {
    controllers.putIfAbsent(
      report.materialId,
      () => TextEditingController(text: report.actualQty.toString()),
    );
    final controller = controllers[report.materialId]!;

    final variance = report.variance;
    final varianceColor = variance == 0
        ? palette.textMuted
        : (variance > 0 ? palette.success : palette.danger);
    final varianceLabel = variance > 0 ? '+$variance' : variance.toString();

    return DesktopCard(
      hover: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                DesktopIconBadge(
                  icon: Icons.inventory_2_outlined,
                  color: palette.info,
                  size: 34,
                ),
                const SizedBox(width: DesktopTokens.gapMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        report.materialName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الوحدة: {v1}'.tr({'v1': report.unit}),
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _windowsNum(palette, report.openingQty),
          _windowsNum(palette, report.purchasesQty),
          _windowsNum(palette, report.consumedQty),
          _windowsNum(palette, report.systemQty),
          SizedBox(
            width: 150,
            child: Center(
              child: SizedBox(
                width: 130,
                child: TextField(
                  controller: controller,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    suffixText: report.unit,
                    suffixStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.textMuted,
                    ),
                    filled: true,
                    fillColor: palette.surfaceSoft,
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesktopTokens.radiusSm),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesktopTokens.radiusSm),
                      borderSide: BorderSide(
                        color: palette.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    report.actualQty = double.tryParse(v) ?? report.systemQty;
                    _refresh(() {});
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Center(
              child: DesktopInfoChip(
                label: varianceLabel,
                color: varianceColor,
                dense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowsNum(DesktopPalette palette, double value) {
    return Expanded(
      flex: 2,
      child: Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}