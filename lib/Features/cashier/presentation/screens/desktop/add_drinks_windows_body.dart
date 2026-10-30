part of '../add_drinks.dart';

/// جسم شاشة إضافة المشروبات — نسخة الويندوز (Windows UI).
///
/// واجهة كاشير سطح مكتب كاملة: تابات الفئات بـ [DesktopSegmented]، بحث فوري،
/// شبكة منتجات عريضة بهوفر وبادج كمية، وبانل فاتورة الطلب جنبها بزرار
/// التأكيد — وكلها بنفس منطق نسخة الموبايل (`_addSingleItemToInvoice` /
/// `_confirmCartOrder`).
extension _AddDrinksScreenWindowsBody on _AddDrinksScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final cats = _visibleCategories;
    final catKeys = cats.map((c) => c['key'] as String? ?? '').toSet();
    final hasOther = drinks.any((d) => !catKeys.contains(d.temperature));

    final available = _windowsAvailableDrinks();
    final visible = _filterDrinks(
      _windowsTab == 'all'
          ? available
          : _windowsTab == 'other'
          ? available.where((d) => !catKeys.contains(d.temperature)).toList()
          : available.where((d) => d.temperature == _windowsTab).toList(),
    );

    return DesktopPageScaffold(
      title: 'إضافة مشروبات'.tr(),
      subtitle:
          ('فاتورة #{v1} • '.tr({'v1': widget.invoiceId}) +
              '{v1}'.tr({
                'v1': _isPosMode ? 'وضع الكاشير'.tr() : "وضع القائمة".tr(),
              })),
      actions: [
        DesktopToolbarIconButton(
          icon: _isPosMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
          tooltip: _isPosMode ? 'عرض كقائمة'.tr() : 'عرض كاشير'.tr(),
          onPressed: () => _refresh(() => _isPosMode = !_isPosMode),
        ),
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: () => _load(),
        ),
      ],
      headerBottom: Row(
        children: [
          if (cats.isNotEmpty || hasOther)
            DesktopSegmented<String>(
              items: [
                DesktopSegmentItem(
                  value: 'all',
                  label: 'الكل'.tr(),
                  icon: Icons.apps_rounded,
                ),
                for (final c in cats)
                  DesktopSegmentItem(
                    value: c['key'] as String? ?? '',
                    label: AppModuleCategory.displayNameFromMap(c),
                    icon: _iconForTemperature(c['key'] as String?),
                  ),
                if (hasOther)
                  DesktopSegmentItem(
                    value: 'other',
                    label: 'أخرى'.tr(),
                    icon: Icons.category_outlined,
                  ),
              ],
              value: _windowsTab,
              onChanged: (value) => _refresh(() => _windowsTab = value),
            ),
          const Spacer(),
          DesktopSearchField(
            hint: 'ابحث عن مشروب أو منتج'.tr(),
            width: 320,
            onChanged: (value) => _refresh(() => searchQuery = value),
          ),
        ],
      ),
      // وضع الكاشير بياخد ارتفاع الصفحة كامل، والقائمة بتسكرول عادي.
      scrollable: !_isPosMode,
      child:
          _isPosMode
              ? _windowsPosLayout(context, available, visible)
              : _windowsListLayout(context, visible),
    );
  }

  /// نفس استبعاد نسخة الموبايل: السجائر/الشيشة المقفولة + الأقسام المقفولة
  /// + منتجات الأقسام غير المفعّلة.
  List<DrinkModel> _windowsAvailableDrinks() {
    final disabledKeys =
        _categories
            .where((c) => (c['is_enabled'] ?? 1) != 1)
            .map((c) => c['key'] as String? ?? '')
            .toSet();

    return drinks.where((d) {
      if (d.temperature == 'cigarette' && !_cigarettesEnabled) return false;
      if (d.temperature == 'shisha' && !_shishaEnabled) return false;
      if (disabledKeys.contains(d.temperature)) return false;
      if (d.moduleId != null && !_enabledModuleIds.contains(d.moduleId)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ============================================================
  // 🖥️ وضع الكاشير (POS): شبكة منتجات + بانل فاتورة الطلب
  // ============================================================
  Widget _windowsPosLayout(
    BuildContext context,
    List<DrinkModel> available,
    List<DrinkModel> visible,
  ) {
    if (available.isEmpty) {
      return DesktopCard(
        child: DesktopEmptyState(
          icon: Icons.local_drink_outlined,
          title:
              drinks.isEmpty ? 'مفيش منتجات'.tr() : 'لا توجد أصناف متاحة'.tr(),
          message:
              drinks.isEmpty
                  ? ('ضيف منتجات من إدارة المنتجات الأول، وبعدها هتظهر هنا '
                          .tr() +
                      'جاهزة للبيع.'.tr())
                  : 'الأصناف الموجودة دلوقتي كلها مقفولة أو مش مفعّلة من الإعدادات.'
                      .tr(),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==================== شبكة المنتجات ====================
        Expanded(
          child:
              visible.isEmpty
                  ? DesktopEmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'مفيش نتائج مطابقة'.tr(),
                    message: 'جرّب تغيّر البحث أو الفئة من فوق.'.tr(),
                  )
                  : SingleChildScrollView(
                    child: DesktopResponsiveGrid(
                      minTileWidth: 172,
                      maxColumns: 8,
                      spacing: 12,
                      children: [
                        for (final d in visible)
                          _windowsProductTile(context, d),
                      ],
                    ),
                  ),
        ),
        const SizedBox(width: DesktopTokens.gapMd),

        // ==================== فاتورة الطلب ====================
        SizedBox(width: 380, child: _windowsCartPanel(context)),
      ],
    );
  }

  /// تايل منتج واحدة — أيقونة + اسم + سعر + المتاح + بادج السلة.
  Widget _windowsProductTile(BuildContext context, DrinkModel d) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final inCartQty = _cartQty[d.id] ?? 0;
    final outOfStock = d.qty <= 0;
    final selected = inCartQty > 0;
    final tint = selected ? palette.accentText : palette.accent;

    return Opacity(
      opacity: outOfStock ? 0.45 : 1,
      child: SizedBox(
        height: 148,
        child: DesktopCard(
          hover: true,
          selected: selected,
          onTap:
              outOfStock
                  ? null
                  : () {
                    final currentInCart = _cartQty[d.id!] ?? 0;
                    if (currentInCart + 1 > d.qty) {
                      _showSnack(
                        'الكمية أكبر من المتاح ({v1})'.tr({'v1': d.qty}),
                      );
                      return;
                    }
                    _incrementCart(d);
                  },
          padding: const EdgeInsets.all(DesktopTokens.gapSm + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DesktopIconBadge(
                    icon: _iconForTemperature(d.temperature),
                    color: tint,
                    size: 34,
                    radius: DesktopTokens.radiusSm,
                  ),
                  const Spacer(),
                  if (inCartQty > 0)
                    DesktopInfoChip(
                      label: '× $inCartQty',
                      icon: Icons.shopping_cart_outlined,
                      color: palette.accentText,
                      dense: true,
                    )
                  else if (outOfStock)
                    DesktopInfoChip(
                      label: 'خلص'.tr(),
                      color: palette.danger,
                      dense: true,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                d.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '{v1} ج'.tr({'v1': d.price.toStringAsFixed(0)}),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: tint,
                    ),
                  ),
                  const Spacer(),
                  if (!outOfStock)
                    Text(
                      'متاح {v1}'.tr({'v1': d.qty}),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: d.qty <= 5 ? palette.warning : palette.textMuted,
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

  /// بانل فاتورة الطلب — بنود + إجمالي + زرار التأكيد.
  Widget _windowsCartPanel(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final cartEntries = _cartQty.entries.toList();

    return DesktopCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ---- رأس البانل ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesktopTokens.gapMd),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: palette.accent,
                ),
                const SizedBox(width: DesktopTokens.gapSm),
                Text(
                  'فاتورة الطلب'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
                const Spacer(),
                DesktopInfoChip(
                  label: '{v1} صنف'.tr({'v1': cartEntries.length}),
                  dense: true,
                ),
              ],
            ),
          ),

          // ---- بنود السلة ----
          Expanded(
            child:
                cartEntries.isEmpty
                    ? DesktopEmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'السلة فاضية'.tr(),
                      message: 'دوس على أي صنف عشان تضيفه للطلب.'.tr(),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesktopTokens.gapXs,
                      ),
                      itemCount: cartEntries.length,
                      itemBuilder:
                          (_, i) => _windowsCartRow(context, cartEntries[i]),
                    ),
          ),

          // ---- الإجمالي والتأكيد ----
          Container(
            padding: const EdgeInsets.all(DesktopTokens.gapMd),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: Column(
              children: [
                if (_isLoading) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: DesktopTokens.gapSm),
                ],
                Row(
                  children: [
                    Text(
                      'الإجمالي'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_cartTotal.toStringAsFixed(2)} ${Money.txt}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: palette.accentText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesktopTokens.gapSm + 2),
                SizedBox(
                  width: double.infinity,
                  child: DesktopButton.primary(
                    label: 'تأكيد الطلب'.tr(),
                    icon: Icons.check_circle_outline,
                    onPressed:
                        (_isLoading || cartEntries.isEmpty)
                            ? null
                            : _confirmCartOrder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بند واحد في السلة — حذف / إنقاص / زيادة — بنفس منطق الموبايل.
  Widget _windowsCartRow(BuildContext context, MapEntry<int, int> entry) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final drink = drinks.firstWhere(
      (d) => d.id == entry.key,
      orElse:
          () => DrinkModel(
            id: entry.key,
            name: '؟'.tr(),
            price: 0,
            temperature: '',
          ),
    );
    final lineTotal = drink.price * entry.value;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapSm,
        vertical: DesktopTokens.gapXs,
      ),
      child: Row(
        children: [
          _windowsMiniIconButton(
            context: context,
            icon: Icons.delete_outline,
            tooltip: 'حذف من الطلب'.tr(),
            color: palette.danger,
            onTap: () => _removeFromCart(entry.key),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  drink.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  ('{v1} ج × {v2}'.tr({
                        'v1': drink.price.toStringAsFixed(2),
                        'v2': entry.value,
                      }) +
                      ' = {v1} ج'.tr({'v1': lineTotal.toStringAsFixed(2)})),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _windowsMiniIconButton(
            context: context,
            icon: Icons.remove_circle_outline,
            tooltip: 'إنقاص'.tr(),
            onTap: () => _decrementCart(entry.key),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '${entry.value}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: palette.textPrimary,
              ),
            ),
          ),
          _windowsMiniIconButton(
            context: context,
            icon: Icons.add_circle_outline,
            tooltip: 'زيادة'.tr(),
            color: palette.success,
            onTap: () {
              if (entry.value + 1 > drink.qty) {
                _showSnack(
                  'الكمية أكبر من المتاح ({v1})'.tr({'v1': drink.qty}),
                );
                return;
              }
              _incrementCart(drink);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📋 وضع القائمة: صفوف منتجات + عدّاد كمية + زرار إضافة
  // ============================================================
  Widget _windowsListLayout(BuildContext context, List<DrinkModel> visible) {
    if (drinks.isEmpty) {
      return DesktopCard(
        child: DesktopEmptyState(
          icon: Icons.local_drink_outlined,
          title: 'مفيش منتجات'.tr(),
          message:
              ('ضيف منتجات من إدارة المنتجات الأول، وبعدها هتظهر هنا '.tr() +
                  'جاهزة للإضافة على الفواتير.'.tr()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading) ...[
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: DesktopTokens.gapMd),
        ],
        DesktopSectionTitle(title: 'المنتجات'.tr(), count: visible.length),
        const SizedBox(height: DesktopTokens.gapXs),
        if (visible.isEmpty)
          DesktopCard(
            child: DesktopEmptyState(
              icon: Icons.search_off_outlined,
              title: 'مفيش نتائج مطابقة'.tr(),
              message: 'جرّب تغيّر البحث أو الفئة من فوق.'.tr(),
            ),
          )
        else
          for (final d in visible) _windowsListRow(context, d),
      ],
    );
  }

  /// صف منتج في وضع القائمة — نفس زرار «أضف» وعدّاد الكمية للموبايل.
  Widget _windowsListRow(BuildContext context, DrinkModel d) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final qty = qtyMap[d.id!] ?? 1;
    final selected = selectedDrinkId == d.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopTokens.gapSm),
      child: DesktopCard(
        hover: true,
        selected: selected,
        onTap:
            () => _refresh(() {
              selectedDrinkId = d.id == selectedDrinkId ? null : d.id;
            }),
        padding: const EdgeInsets.symmetric(
          horizontal: DesktopTokens.gapMd,
          vertical: DesktopTokens.gapSm,
        ),
        child: Row(
          children: [
            DesktopIconBadge(
              icon: _iconForTemperature(d.temperature),
              color: palette.accent,
              size: 44,
              radius: DesktopTokens.radiusMd,
            ),
            const SizedBox(width: DesktopTokens.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    d.displayName,
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
                    'المتاح: {v1} • السعر: {v2} ج'.tr({
                      'v1': d.qty,
                      'v2': d.price.toStringAsFixed(2),
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesktopTokens.gapSm),
            _windowsMiniIconButton(
              context: context,
              icon: Icons.remove_circle_outline,
              tooltip: 'إنقاص'.tr(),
              onTap:
                  qty > 1
                      ? () => _refresh(() => qtyMap[d.id!] = qty - 1)
                      : null,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                ),
              ),
            ),
            _windowsMiniIconButton(
              context: context,
              icon: Icons.add_circle_outline,
              tooltip: 'زيادة'.tr(),
              color: palette.success,
              onTap: () => _refresh(() => qtyMap[d.id!] = qty + 1),
            ),
            const SizedBox(width: DesktopTokens.gapMd),
            DesktopButton.primary(
              label: 'أضف'.tr(),
              icon: Icons.add_shopping_cart_outlined,
              onPressed: () async {
                _refresh(() => _isLoading = true);
                final ok = await _addSingleItemToInvoice(d, qty);
                await _load();
                if (!mounted) return;
                _refresh(() {
                  if (ok) qtyMap[d.id!] = 1;
                  _isLoading = false;
                });
                if (ok) _showSnack('✅ تمت الإضافة'.tr());
              },
            ),
          ],
        ),
      ),
    );
  }

  /// زرار أيقونة صغير جوه الصفوف والسلة — بهوفر وتلميح اختياري.
  Widget _windowsMiniIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
    String? tooltip,
    Color? color,
  }) {
    final palette = DesktopPalette.of(context);
    final tint =
        onTap == null
            ? palette.textMuted.withValues(alpha: 0.4)
            : (color ?? palette.textSecondary);

    Widget button = HoverBuilder(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      builder:
          (context, hovering) => GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: DesktopTokens.fast,
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    hovering && onTap != null
                        ? palette.surfaceSoft
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                border: Border.all(
                  color:
                      hovering && onTap != null
                          ? palette.border
                          : Colors.transparent,
                ),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
          ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }
}
