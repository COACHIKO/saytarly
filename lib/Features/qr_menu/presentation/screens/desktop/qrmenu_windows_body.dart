part of '../qrmenu.dart';

/// جسم شاشة المنيو (العميل) — نسخة الويندوز (Windows UI).
///
/// شبكة منتجات كروت قابلة للهوفر + تابات الأقسام بـ [DesktopSegmented]،
/// وسلة الطلب بانل جانبي بنفس منطق الإضافة والملاحظة والإرسال.
extension _MenuScreenWindowsBody on _MenuScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    if (_submitted) return _windowsThanks(context);

    final palette = DesktopPalette.of(context);
    final index = _tabController.index;
    final drinks = _filteredDrinks(_categories[index]['temps']);

    return DesktopPageScaffold(
      title: 'المنيو'.tr(),
      subtitle: '{v1} • {v2} صنف'.tr({
        'v1': widget.tableName,
        'v2': _allDrinks.length,
      }),
      scrollable: false,
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث المنيو'.tr(),
          onPressed: _loadDrinks,
        ),
      ],
      headerBottom: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DesktopSegmented<int>(
            items: [
              for (var i = 0; i < _categories.length; i++)
                DesktopSegmentItem<int>(
                  value: i,
                  label: _categories[i]['label'] as String,
                ),
            ],
            value: index,
            onChanged: (i) => _refresh(() => _tabController.index = i),
          ),
        ),
      ),
      child:
          _loading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: palette.accent),
                    const SizedBox(height: DesktopTokens.gapMd),
                    Text(
                      'جاري تحميل المنيو...'.tr(),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _windowsMenuGrid(context, drinks)),
                  const SizedBox(width: DesktopTokens.gapMd),
                  SizedBox(width: 330, child: _windowsCartPanel(context)),
                ],
              ),
    );
  }

  // ===================================================================
  // شبكة المنتجات
  // ===================================================================

  Widget _windowsMenuGrid(
    BuildContext context,
    List<Map<String, dynamic>> drinks,
  ) {
    if (drinks.isEmpty) {
      return DesktopEmptyState(
        icon: Icons.local_cafe_outlined,
        title: 'لا يوجد منتجات'.tr(),
        message: 'مفيش أصناف في القسم ده دلوقتي.'.tr(),
      );
    }

    return DesktopScrollbar(
      builder:
          (c) => SingleChildScrollView(
            controller: c,
            child: DesktopResponsiveGrid(
              minTileWidth: 215,
              maxColumns: 6,
              children: [
                for (final drink in drinks) _windowsDrinkCard(context, drink),
              ],
            ),
          ),
    );
  }

  /// كارت منتج — نفس منطق الإضافة والعدّاد، بستايل سطح المكتب.
  Widget _windowsDrinkCard(BuildContext context, Map<String, dynamic> drink) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final id = drink['id'] as int;
    final qty = _cart[id] ?? 0;
    final price = (drink['price'] as num).toDouble();

    return HoverBuilder(
      builder:
          (context, hovering) => DesktopCard(
            hover: true,
            selected: qty > 0,
            padding: const EdgeInsets.all(DesktopTokens.gapMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AnimatedScale(
                      scale: hovering ? 1.08 : 1,
                      duration: DesktopTokens.fast,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: palette.soft(palette.accent),
                          borderRadius: BorderRadius.circular(
                            DesktopTokens.radiusMd,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _drinkEmoji(drink['temperature'] as String? ?? ''),
                          style: const TextStyle(fontSize: 21),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (qty > 0)
                      DesktopInfoChip(
                        label: '×$qty',
                        icon: Icons.shopping_cart_outlined,
                        color: palette.accentText,
                        dense: true,
                      ),
                  ],
                ),
                const SizedBox(height: DesktopTokens.gapSm + 2),
                Text(
                  DrinkModel.displayNameFromMap(drink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '{v1} ج'.tr({'v1': price.toStringAsFixed(0)}),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.accentText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: DesktopTokens.gapSm + 2),
                if (qty == 0)
                  SizedBox(
                    width: double.infinity,
                    child: DesktopButton.primary(
                      label: 'إضافة'.tr(),
                      icon: Icons.add,
                      onPressed: () => _addToCart(id),
                    ),
                  )
                else
                  Row(
                    children: [
                      _windowsQtyButton(
                        context,
                        icon: Icons.remove,
                        onTap: () => _removeFromCart(id),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$qty',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      _windowsQtyButton(
                        context,
                        icon: Icons.add,
                        onTap: () => _addToCart(id),
                      ),
                    ],
                  ),
              ],
            ),
          ),
    );
  }

  // ===================================================================
  // سلة الطلب (بانل جانبي)
  // ===================================================================

  Widget _windowsCartPanel(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final entries = _cart.entries.toList();

    return DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopSectionTitle(
            title: 'سلة الطلب'.tr(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: DesktopTokens.gapSm + 2),
          Expanded(
            child:
                entries.isEmpty
                    ? DesktopEmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'السلة فاضية'.tr(),
                      message: 'اختار أصناف من المنيو وهتظهر هنا.'.tr(),
                    )
                    : DesktopScrollbar(
                      builder:
                          (c) => ListView.separated(
                            controller: c,
                            padding: EdgeInsets.zero,
                            itemCount: entries.length,
                            separatorBuilder:
                                (_, _) => const SizedBox(height: 4),
                            itemBuilder:
                                (_, i) => _windowsCartRow(
                                  context,
                                  entries[i].key,
                                  entries[i].value,
                                ),
                          ),
                    ),
          ),
          const SizedBox(height: DesktopTokens.gapSm),
          TextField(
            textDirection: TextDirection.rtl,
            onChanged: (v) => _note = v,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'ملاحظة للطلب (اختياري)'.tr(),
              hintStyle: TextStyle(color: palette.textMuted, fontSize: 12.5),
              prefixIcon: Icon(
                Icons.edit_note_outlined,
                size: 18,
                color: palette.textMuted,
              ),
              filled: true,
              fillColor: palette.surfaceSoft,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                borderSide: BorderSide(color: palette.accent, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          Container(height: 1, color: palette.border),
          const SizedBox(height: DesktopTokens.gapMd),
          Row(
            children: [
              Text(
                '{_cartTotal} صنف'.tr({'_cartTotal': _cartTotal}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '{v1} ج'.tr({'v1': _cartPrice.toStringAsFixed(0)}),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          DesktopButton.primary(
            label: _submitting ? 'جاري الإرسال...'.tr() : 'أرسل الطلب',
            icon: _submitting ? null : Icons.send_outlined,
            onPressed: _submitting ? null : _submitOrder,
          ),
        ],
      ),
    );
  }

  Widget _windowsCartRow(BuildContext context, int drinkId, int qty) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final drink = _allDrinks.firstWhere(
      (d) => d['id'] == drinkId,
      orElse: () => {},
    );
    if (drink.isEmpty) return const SizedBox.shrink();

    final price = (drink['price'] as num).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DrinkModel.displayNameFromMap(drink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '{v1} ج'.tr({'v1': (price * qty).toStringAsFixed(0)}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapXs),
          _windowsQtyButton(
            context,
            icon: Icons.remove,
            onTap: () => _removeFromCart(drinkId),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                '$qty',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          _windowsQtyButton(
            context,
            icon: Icons.add,
            onTap: () => _addToCart(drinkId),
          ),
        ],
      ),
    );
  }

  /// زر صغير (زيادة/نقصان) — بهوفر ناعم يناسب سطح المكتب.
  Widget _windowsQtyButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final palette = DesktopPalette.of(context);

    return HoverBuilder(
      builder:
          (context, hovering) => GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: DesktopTokens.fast,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hovering ? palette.accent : palette.surfaceSoft,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                border: Border.all(
                  color: hovering ? palette.accent : palette.border,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: hovering ? Colors.white : palette.textSecondary,
              ),
            ),
          ),
    );
  }

  // ===================================================================
  // شاشة الشكر (بعد إرسال الطلب)
  // ===================================================================

  Widget _windowsThanks(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return DesktopPageScaffold(
      title: 'تم إرسال الطلب'.tr(),
      subtitle: widget.tableName,
      showBackButton: false,
      padding: const EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        48,
        DesktopTokens.pagePadding,
        DesktopTokens.pagePadding,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DesktopCard(
            padding: const EdgeInsets.all(DesktopTokens.gapXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: palette.soft(palette.success),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.success.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    size: 44,
                    color: palette.success,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapLg),
                Text(
                  'تم إرسال طلبك!'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapSm),
                Text(
                  widget.tableName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.accentText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapSm),
                Text(
                  'سيتم تحضير طلبك قريباً 🎉'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapXl),
                DesktopButton.primary(
                  label: 'طلب جديد'.tr(),
                  icon: Icons.refresh,
                  onPressed:
                      () => _refresh(() {
                        _cart.clear();
                        _submitted = false;
                        _note = '';
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
