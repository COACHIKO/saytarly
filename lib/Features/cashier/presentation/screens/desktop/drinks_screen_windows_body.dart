part of '../DrinksScreen.dart';

/// جسم لوحة الترابيزات — نسخة الويندوز (Windows UI).
///
/// بورد كاشير كامل: مؤشرات سريعة + فلتر حالة المفروزة بـ [DesktopSegmented]
/// + شبكة ترابيزات عريضة بهوفر وأوامر جاهزة (فتح / تحرير / دفع جزئي /
/// إضافة / فاتورة / إنهاء) — بنفس منطق نسخة الموبايل بالحرف.
extension _DrinksscreenDashboardWindowsBody on _DrinksscreenDashboardState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final available = tables.where((t) => t['active_invoice_id'] == null).length;
    final busy = tables.length - available;

    var visible = filteredTables;
    if (_tableFilter == 'available') {
      visible = visible.where((t) => t['active_invoice_id'] == null).toList();
    } else if (_tableFilter == 'busy') {
      visible = visible.where((t) => t['active_invoice_id'] != null).toList();
    }

    return DesktopPageScaffold(
      title: 'لوحة الترابيزات'.tr(),
      subtitle: '{v1} • متابعة الجلسات المفتوحة على الترابيزات'.tr({'v1': widget.staffName}),
      actions: [
        DesktopSearchField(
          hint: 'ابحث عن الترابيزة أو العميل...'.tr(),
          onChanged: (value) =>
              _refresh(() => _searchQuery = value.toLowerCase()),
        ),
        DesktopButton.primary(
          label: 'إضافة عدد التربيزات'.tr(),
          icon: Icons.add_box_outlined,
          onPressed: () => _windowsAddTables(context),
        ),
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: _load,
        ),
      ],
      headerBottom: Row(
        children: [
          DesktopSegmented<String>(
            items:  [
              DesktopSegmentItem(
                value: 'all',
                label: 'الكل'.tr(),
                icon: Icons.table_restaurant_outlined,
              ),
              DesktopSegmentItem(
                value: 'available',
                label: 'متاحة'.tr(),
                icon: Icons.check_circle_outline,
              ),
              DesktopSegmentItem(
                value: 'busy',
                label: 'محجوزة'.tr(),
                icon: Icons.timer_outlined,
              ),
            ],
            value: _tableFilter,
            onChanged: (value) => _refresh(() => _tableFilter = value),
          ),
          const Spacer(),
          DesktopInfoChip(
            label: 'متاحة {available}'.tr({'available': available}),
            icon: Icons.check_circle_outline,
            color: palette.success,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: 'محجوزة {busy}'.tr({'busy': busy}),
            icon: Icons.timer_outlined,
            color: palette.danger,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات سريعة ====================
          DesktopResponsiveGrid(
            minTileWidth: 240,
            maxColumns: 3,
            children: [
              DesktopStatCard(
                label: 'إجمالي الترابيزات'.tr(),
                value: '${tables.length}',
                icon: Icons.table_restaurant_outlined,
                color: palette.accent,
              ),
              DesktopStatCard(
                label: 'ترابيزات متاحة'.tr(),
                value: '$available',
                icon: Icons.check_circle_outline,
                color: palette.success,
                hint: 'جاهزة لبدء جلسة جديدة'.tr(),
              ),
              DesktopStatCard(
                label: 'ترابيزات محجوزة'.tr(),
                value: '$busy',
                icon: Icons.timer_outlined,
                color: palette.danger,
                hint: 'عليها فواتير مفتوحة'.tr(),
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg),

          // ==================== الترابيزات ====================
          DesktopSectionTitle(title: 'الترابيزات'.tr(), count: visible.length),
          const SizedBox(height: DesktopTokens.gapXs),

          if (tables.isEmpty)
            DesktopCard(
              child: DesktopEmptyState(
                icon: Icons.table_restaurant_outlined,
                title: 'لسه مفيش ترابيزات'.tr(),
                message: ('ابدأ بإضافة عدد الترابيزات وابعت الطلبات عليها '.tr() + '— وكل ترابيزة هتعرض حالتها وجلساتها هنا.'.tr()),
                action: DesktopButton.primary(
                  label: 'إضافة عدد التربيزات'.tr(),
                  icon: Icons.add_box_outlined,
                  onPressed: () => _windowsAddTables(context),
                ),
              ),
            )
          else if (visible.isEmpty)
            DesktopCard(
              child: DesktopEmptyState(
                icon: Icons.search_off_outlined,
                title: 'مفيش نتائج مطابقة'.tr(),
                message: 'جرّب تغيّر البحث أو فلتر الحالة من فوق.'.tr(),
              ),
            )
          else
            DesktopResponsiveGrid(
              minTileWidth: 320,
              maxColumns: 4,
              children: [
                for (final t in visible) _windowsTableCard(context, t),
              ],
            ),
        ],
      ),
    );
  }

  /// كارت ترابيزة واحد — حالة + أوامر جاهزة بنفس callbacks الموبايل.
  Widget _windowsTableCard(BuildContext context, Map<String, dynamic> t) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final activeInvoice = t['active_invoice_id'];
    final busy = activeInvoice != null;

    return SizedBox(
      height: 198,
      child: DesktopCard(
        hover: true,
        selected: busy,
        onTap: busy ? null : () => _startSession(t),
        padding: const EdgeInsets.all(DesktopTokens.gapMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- رأس الكارت: الترابيزة + الحالة ----
            Row(
              children: [
                DesktopIconBadge(
                  icon: Icons.chair_alt,
                  color: busy ? palette.danger : palette.success,
                  size: 42,
                  radius: DesktopTokens.radiusMd,
                ),
                const SizedBox(width: DesktopTokens.gapSm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${t['displayName']}',
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
                        busy
                            ? 'فاتورة #{activeInvoice}'.tr({'activeInvoice': activeInvoice})
                            : 'جاهزة لبدء جلسة جديدة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesktopTokens.gapXs),
                DesktopInfoChip(
                  label: busy ? 'محجوزة'.tr() : 'متاحة',
                  icon: busy ? Icons.timer_outlined : Icons.check_circle_outline,
                  color: busy ? palette.danger : palette.success,
                  dense: true,
                ),
                if (!busy)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.chevron_left,
                      size: 18,
                      color: palette.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const Spacer(),

            // ---- الأوامر ----
            if (!busy)
              SizedBox(
                width: double.infinity,
                child: DesktopButton.primary(
                  label: 'فتح ترابيزة'.tr(),
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => _startSession(t),
                ),
              )
            else
              Wrap(
                spacing: DesktopTokens.gapXs + 2,
                runSpacing: DesktopTokens.gapXs,
                children: [
                  _windowsTileAction(
                    context: context,
                    icon: Icons.restore,
                    label: 'تحرير'.tr(),
                    color: palette.warning,
                    onTap: () async {
                      final ok = await _checkPassword();

                      if (!ok) {
                        if (!context.mounted) return;
                        AppToast.show('كلمة المرور غير صحيحة'.tr());
                        return;
                      }

                      await forceCloseTable(t['id'] as int);
                      await _load();
                    },
                  ),
                  _windowsTileAction(
                    context: context,
                    icon: Icons.payments_outlined,
                    label: 'دفع جزئي'.tr(),
                    color: palette.info,
                    onTap: () => _partialPayment(t),
                  ),
                  _windowsTileAction(
                    context: context,
                    icon: Icons.local_drink_outlined,
                    label: 'إضافة'.tr(),
                    color: palette.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddDrinksScreen(invoiceId: activeInvoice),
                        ),
                      );
                    },
                  ),
                  _windowsTileAction(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: 'فاتورة'.tr(),
                    color: palette.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DrinksInvoiceScreen(
                            invoiceId: activeInvoice,
                          ),
                        ),
                      );
                    },
                  ),
                  _windowsTileAction(
                    context: context,
                    icon: Icons.close_rounded,
                    label: 'إنهاء'.tr(),
                    color: palette.danger,
                    onTap: () async {
                      await _endSession(t);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// زرار إجراء صغير داخل كارت الترابيزة — أيقونة + وصف بهوفر ملوّن.
  Widget _windowsTileAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return HoverBuilder(
      builder: (context, hovering) {
        final palette = DesktopPalette.of(context);

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: DesktopTokens.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: hovering ? palette.soft(color) : palette.surfaceSoft,
              borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
              border: Border.all(
                color: hovering
                    ? color.withValues(alpha: 0.5)
                    : palette.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// نافذة إضافة عدد الترابيزات — نفس منطق نسخة الموبايل بالحرف.
  Future<void> _windowsAddTables(BuildContext context) async {
    final countCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:  Text(
          'عدد الترابيزات الجديدة'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: countCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'أدخل العدد'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:  Text('إلغاء'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(countCtrl.text) ?? 0;
              // جلب آخر ترابيزة موجودة
              final allTables = await DBHelper.getAllTables();
              int lastNumber = allTables.isEmpty
                  ? 0
                  : allTables
                        .map(
                          (t) => int.tryParse(t['name'].split(' ')[1]) ?? 0,
                        )
                        .reduce((a, b) => a > b ? a : b);

              // إضافة الترابيزات الجديدة بعد آخر رقم موجود
              for (int i = 1; i <= count; i++) {
                await DBHelper.insertTable('ترابيزة {v1}'.tr({'v1': lastNumber + i}));
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _refresh(() {
                _load();
              });
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:  Text('إضافة'.tr()),
          ),
        ],
      ),
    );
  }
}
