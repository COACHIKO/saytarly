part of '../invoice_screen.dart';

/// جسم شاشة الفاتورة — نسخة الويندوز (Windows UI).
///
/// صفحة تقرير على شكل سطح مكتب: صف مؤشرات (جهاز / مشروبات / إجمالي / أصناف)،
/// جدول الأصناف بعرض الصفحة مع خانة الكمية وزرار الحذف، وكارت بيانات الفاتورة
/// والإجماليات على الجنب — نفس `_updateItemQty` و`_removeItem` بالظبط.
extension _InvoiceScreenWindowsBody on _InvoiceScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    // نفس منطق نسخة الموبايل: استنى لحد ما الفاتورة تحمّل.
    if (invoice == null) {
      return DesktopPageScaffold(
        title: 'الفاتورة #{v1}'.tr({'v1': widget.invoiceId}),
        subtitle: 'بيتم تحميل بيانات الفاتورة...'.tr(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final start = invoice!['start_time'] != null
        ? DateTime.parse(invoice!['start_time'])
        : null;

    final end = invoice!['end_time'] != null
        ? DateTime.parse(invoice!['end_time'])
        : null;

    final df = DateFormat('yyyy-MM-dd HH:mm');

    final deviceCost = (invoice!['device_cost'] ?? 0).toDouble();
    final drinksCost = items.fold(
      0.0,
      (sum, it) => sum + (it['total'] as num).toDouble(),
    );

    return DesktopPageScaffold(
      title: 'الفاتورة #{v1}'.tr({'v1': invoice!['id']}),
      subtitle: ('من {v1} '.tr({'v1': start != null ? df.format(start) : "-"}) + 'إلى {v1}'.tr({'v1': end != null ? df.format(end) : "-"})),
      actions: [
        DesktopButton.primary(
          label: 'إضافة مشروب'.tr(),
          icon: Icons.add,
          onPressed: () => _windowsAddDrinks(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات سريعة ====================
          DesktopResponsiveGrid(
            minTileWidth: 240,
            maxColumns: 4,
            children: [
              DesktopStatCard(
                label: 'تكلفة الجهاز'.tr(),
                value: '${deviceCost.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.sports_esports_outlined,
                color: palette.info,
              ),
              DesktopStatCard(
                label: 'تكلفة المشروبات'.tr(),
                value: '${drinksCost.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.local_drink_outlined,
                color: palette.accent,
              ),
              DesktopStatCard(
                label: 'الإجمالي النهائي'.tr(),
                value: '${totalCost.toStringAsFixed(2)} ${Money.txt}',
                icon: Icons.payments_outlined,
                color: palette.success,
              ),
              DesktopStatCard(
                label: 'عدد الأصناف'.tr(),
                value: '${items.length}',
                icon: Icons.list_alt_rounded,
                color: palette.warning,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== أصناف الفاتورة ====================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesktopSectionTitle(
                      title: 'المشروبات'.tr(),
                      count: items.length,
                      trailing: DesktopButton.ghost(
                        label: 'إضافة مشروب'.tr(),
                        icon: Icons.add,
                        onPressed: () => _windowsAddDrinks(context),
                      ),
                    ),
                    const SizedBox(height: DesktopTokens.gapXs),
                    if (items.isEmpty)
                      DesktopCard(
                        child: DesktopEmptyState(
                          icon: Icons.local_drink_outlined,
                          title: 'مفيش مشروبات على الفاتورة'.tr(),
                          message: ('ضيف مشروبات من زرار «إضافة مشروب» فوق '.tr() + 'وهتظهر هنا مع الإجماليات.'.tr()),
                          action: DesktopButton.primary(
                            label: 'إضافة مشروب'.tr(),
                            icon: Icons.add,
                            onPressed: () => _windowsAddDrinks(context),
                          ),
                        ),
                      )
                    else
                      for (final it in items) _windowsItemRow(context, it),
                  ],
                ),
              ),
               SizedBox(width: DesktopTokens.gapLg),

              // ==================== بيانات الفاتورة + الإجماليات ====================
              SizedBox(
                width: 340,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesktopCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           DesktopSectionTitle(title: 'بيانات الفاتورة'.tr()),
                          _windowsInfoRow(
                            context,
                            'الجهاز'.tr(),
                            '${invoice!['console_id']}',
                          ),
                          _windowsInfoRow(
                            context,
                            'بداية الوقت'.tr(),
                            start != null ? df.format(start) : '-',
                          ),
                          _windowsInfoRow(
                            context,
                            'نهاية الوقت'.tr(),
                            end != null ? df.format(end) : '-',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesktopTokens.gapMd),
                    _windowsTotalsCard(context, palette, deviceCost, drinksCost),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// صف صنف واحد — الكمية بتتنادى على `_updateItemQty` زي الموبايل.
  Widget _windowsItemRow(BuildContext context, Map<String, dynamic> it) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final itemId = it['id'] as int;

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
                    'السعر: {v1} ج'.tr({'v1': it['drink_price'].toStringAsFixed(2)}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            SizedBox(
              width: 92,
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
                  labelText: 'عدد'.tr(),
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
              width: 120,
              child: Text(
                '${(it['total'] as num).toStringAsFixed(2)} ${Money.txt}',
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

  /// سطر بيانات (تسمية + قيمة) جوه كارت بيانات الفاتورة.
  Widget _windowsInfoRow(BuildContext context, String label, String value) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesktopTokens.gapXs),
      child: Row(
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// كارت الإجماليات — نفس أرقام `_totalRow` في نسخة الموبايل.
  Widget _windowsTotalsCard(
    BuildContext context,
    DesktopPalette palette,
    double deviceCost,
    double drinksCost,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesktopTokens.gapLg),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusLg),
        border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: palette.accentText),
              const SizedBox(width: DesktopTokens.gapSm),
              Text(
                'الإجماليات'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapSm + 2),
          _windowsTotalRow(context, 'تكلفة الجهاز:'.tr(), deviceCost),
          _windowsTotalRow(context, 'تكلفة المشروبات:'.tr(), drinksCost),
          Divider(color: palette.accent.withValues(alpha: 0.25), height: 22),
          Row(
            children: [
              Text(
                'الإجمالي النهائي:'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${totalCost.toStringAsFixed(2)} ${Money.txt}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.accentText,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowsTotalRow(BuildContext context, String label, double value) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${value.toStringAsFixed(2)} ${Money.txt}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

  /// فتح شاشة إضافة المشروبات ثم إعادة تحميل الفاتورة — زي زر الموبايل.
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
      _load(); // مثال: دالة لإعادة جلب المشروبات
    });
  }
}
