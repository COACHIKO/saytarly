part of '../DrinksInvoiceScreen.dart';

/// جسم شاشة مشروبات الفاتورة — نسخة الويندوز (Windows UI).
///
/// جدول أصناف عريض بعرض الصفحة: اسم المشروب + خانة الكمية (نفس
/// `_updateItemQty` اللي بيعدّل المخزون) + الإجمالي + زرار حذف،
/// وفي الآخر كارت إجمالي الفاتورة.
extension _DrinksInvoiceScreenWindowsBody on _DrinksInvoiceScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return DesktopPageScaffold(
      title: 'مشروبات الفاتورة #{v1}'.tr({'v1': widget.invoiceId}),
      subtitle: ('{v1} صنف • أي تعديل في الكمية يتحدّث '.tr({'v1': items.length}) + 'في المخزون فورًا'.tr()),
      actions: [
        DesktopButton.primary(
          label: 'إضافة مشروب'.tr(),
          icon: Icons.add,
          onPressed: () => _windowsAddDrinks(context),
        ),
      ],
      child: items.isEmpty
          ? DesktopCard(
              child: DesktopEmptyState(
                icon: Icons.local_drink_outlined,
                title: 'لا توجد مشروبات'.tr(),
                message: ('الفاتورة لسه مفيهاش أصناف — ابدأ بإضافة مشروب '.tr() + 'وهيتحسب هنا فورًا.'.tr()),
                action: DesktopButton.primary(
                  label: 'إضافة مشروب'.tr(),
                  icon: Icons.add,
                  onPressed: () => _windowsAddDrinks(context),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== مؤشرات سريعة ====================
                DesktopResponsiveGrid(
                  minTileWidth: 240,
                  maxColumns: 3,
                  children: [
                    DesktopStatCard(
                      label: 'عدد الأصناف'.tr(),
                      value: '${items.length}',
                      icon: Icons.list_alt_rounded,
                      color: palette.accent,
                    ),
                    DesktopStatCard(
                      label: 'إجمالي المشروبات'.tr(),
                      value: '${totalDrinksCost.toStringAsFixed(2)} ${Money.txt}',
                      icon: Icons.payments_outlined,
                      color: palette.success,
                    ),
                    DesktopStatCard(
                      label: 'متوسط سعر الصنف'.tr(),
                      value:
                          '${(totalDrinksCost / (items.isEmpty ? 1 : items.length)).toStringAsFixed(2)} ${Money.txt}',
                      icon: Icons.calculate_outlined,
                      color: palette.info,
                    ),
                  ],
                ),
                 SizedBox(height: DesktopTokens.gapLg),

                // ==================== الأصناف ====================
                DesktopSectionTitle(title: 'الأصناف'.tr(), count: items.length),
                 SizedBox(height: DesktopTokens.gapXs),
                for (final it in items) _windowsItemRow(context, it),

                 SizedBox(height: DesktopTokens.gapMd),

                // ==================== الإجمالي ====================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesktopTokens.gapLg),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(DesktopTokens.radiusLg),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      DesktopIconBadge(
                        icon: Icons.receipt_long_outlined,
                        color: palette.accentText,
                        size: 46,
                        radius: DesktopTokens.radiusMd,
                      ),
                      const SizedBox(width: DesktopTokens.gapMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'إجمالي الفاتورة'.tr(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '{v1} صنف • شامل كل المشروبات'.tr({'v1': items.length}),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${totalDrinksCost.toStringAsFixed(2)} ${Money.txt}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.accentText,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// صف صنف واحد — خانة كمية (بتنادي `_updateItemQty`) + الإجمالي + حذف.
  Widget _windowsItemRow(BuildContext context, Map<String, dynamic> it) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final itemId = it['id'] as int;
    final qty = (it['qty'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
      child: DesktopCard(
        padding: const EdgeInsets.symmetric(
          horizontal: DesktopTokens.gapMd,
          vertical: DesktopTokens.gapSm + 2,
        ),
        child: Row(
          children: [
            DesktopIconBadge(
              icon: Icons.local_drink_outlined,
              color: palette.accent,
              size: 42,
              radius: DesktopTokens.radiusSm,
            ),
            const SizedBox(width: DesktopTokens.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${it['drink_name']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'الكمية الحالية: {qty}'.tr({'qty': qty}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            SizedBox(
              width: 96,
              height: 42,
              child: TextField(
                controller: qtyControllers[itemId],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: palette.surfaceSoft,
                  isDense: true,
                  labelText: 'كمية'.tr(),
                  labelStyle: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12.5,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
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
                    borderSide: BorderSide(color: palette.accent, width: 1.4),
                  ),
                ),
                onChanged: (_) => _updateItemQty(itemId),
              ),
            ),
            const SizedBox(width: DesktopTokens.gapMd),
            SizedBox(
              width: 130,
              child: Text(
                '${(it['total'] as num).toDouble().toStringAsFixed(2)} ${Money.txt}',
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.success,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            _windowsDeleteButton(
              context: context,
              onTap: () => _removeItem(itemId),
            ),
          ],
        ),
      ),
    );
  }

  /// زرار حذف الصنف — دائري بلمسة حمراء + تلميح.
  Widget _windowsDeleteButton({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final palette = DesktopPalette.of(context);

    return HoverBuilder(
      builder: (context, hovering) => Tooltip(
        message: 'حذف المشروب وإرجاع الكمية للمخزون'.tr(),
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: DesktopTokens.fast,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hovering
                  ? palette.danger.withValues(alpha: 0.16)
                  : palette.soft(palette.danger),
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.danger.withValues(alpha: hovering ? 0.5 : 0.25),
              ),
            ),
            child: Icon(
              Icons.delete_outline,
              size: 19,
              color: palette.danger,
            ),
          ),
        ),
      ),
    );
  }

  /// فتح شاشة إضافة المشروبات ثم تحديث الأصناف — زي زر الموبايل بالظبط.
  Future<void> _windowsAddDrinks(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDrinksScreen(invoiceId: widget.invoiceId),
      ),
    );

    if (!mounted) return;
    _refresh(() {
      // هنا تقدر تحدث الـ items أو أي بيانات تحتاج إعادة تحميل
      _loadItems(); // مثال: دالة لإعادة جلب المشروبات
    });
  }
}
