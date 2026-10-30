part of '../add_drinks.dart';

/// جسم شاشة إضافة المشروبات — نسخة الموبايل (زي ما كانت بالظبط).
extension _AddDrinksScreenMobileBody on _AddDrinksScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final cats = _visibleCategories;
    final catKeys = cats.map((c) => c['key'] as String? ?? '').toSet();
    final hasOther = drinks.any((d) => !catKeys.contains(d.temperature));
    final tabCount = cats.length + (hasOther ? 1 : 0);

    return DefaultTabController(
      length: tabCount == 0 ? 1 : tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إضافة مشروبات'.tr()),
          actions: [
            // 🆕 زرار التبديل بين التصميمين
            IconButton(
              tooltip: _isPosMode ? 'عرض كقائمة'.tr() : 'عرض كاشير'.tr(),
              icon: Icon(
                _isPosMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
              onPressed: () {
                _refresh(() {
                  _isPosMode = !_isPosMode;
                });
              },
            ),
          ],
          bottom:
              _isPosMode || tabCount == 0
                  ? null
                  : TabBar(
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    indicatorColor: Colors.transparent,
                    indicatorWeight: 0,
                    indicatorPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Color(0xFF6FCF97),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    isScrollable: tabCount > 4,
                    tabs: [
                      for (final c in cats)
                        Tab(text: AppModuleCategory.displayNameFromMap(c)),
                      if (hasOther) Tab(text: 'أخرى'.tr()),
                    ],
                  ),
        ),
        body:
            _isPosMode
                ? _buildPosModeBody()
                : _buildListModeBody(), // ✅ مباشرة، مش _buildListModeWrapper
      ),
    );
  }

  Widget _buildListModeBody() {
    final cats = _visibleCategories;
    final catKeys = cats.map((c) => c['key'] as String? ?? '').toSet();
    final otherDrinks = _filterDrinks(
      drinks.where((d) => !catKeys.contains(d.temperature)).toList(),
    );
    final hasOther = otherDrinks.isNotEmpty;
    final tabCount = cats.length + (hasOther ? 1 : 0);

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'ابحث عن مشروب أو منتج'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _refresh(() => searchQuery = value),
              ),
            ),
            Expanded(
              child:
                  tabCount == 0
                      ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            ('لسه مفيش أقسام منتجات.\n'.tr() +
                                'كلم السوبر ادمن يضيف الأقسام والقوائم من لوحته.'
                                    .tr()),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : TabBarView(
                        children: [
                          for (final c in cats)
                            _buildDrinkList(
                              _filterDrinks(
                                drinks
                                    .where(
                                      (d) =>
                                          d.temperature ==
                                          (c['key'] as String? ?? ''),
                                    )
                                    .toList(),
                              ),
                            ),
                          if (hasOther) _buildDrinkList(otherDrinks),
                        ],
                      ),
            ),
          ],
        );
  }

  Map<String, List<DrinkModel>> _groupDrinks(List<DrinkModel> list) {
    final Map<String, List<DrinkModel>> groups = {};
    for (final d in list) {
      final key = d.displayName.trim().split(' ').first;
      groups.putIfAbsent(key, () => []).add(d);
    }
    return groups;
  }

  Widget _buildDrinkList(List<DrinkModel> drinkList) {
    if (drinkList.isEmpty) {
      return Center(child: Text('لا توجد مشروبات'.tr()));
    }

    final groups = _groupDrinks(drinkList);
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final key = keys[i];
        final group = groups[key]!;

        if (group.length == 1) {
          return _buildDrinkCard(group.first);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              key,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '{v1} أنواع'.tr({'v1': group.length}),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            leading: const Icon(Icons.local_cafe, color: Colors.brown),
            children:
                group.map((d) => _buildDrinkCard(d, isChild: true)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDrinkCard(DrinkModel d, {bool isChild = false}) {
    final qty = qtyMap[d.id!] ?? 1;
    final cardColor =
        d.id == selectedDrinkId
            ? Colors.deepPurple.shade100
            : Theme.of(context).cardColor;

    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: isChild ? 8 : 16),
      elevation: isChild ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _refresh(() {
            selectedDrinkId = d.id == selectedDrinkId ? null : d.id;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '{v1} (المتاح: {v2})'.tr({
                        'v1': d.displayName,
                        'v2': d.qty,
                      }),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'السعر: {v1} ج'.tr({'v1': d.price.toStringAsFixed(2)}),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (qty > 1) _refresh(() => qtyMap[d.id!] = qty - 1);
                    },
                  ),
                  Text(qty.toString(), style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _refresh(() => qtyMap[d.id!] = qty + 1),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
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
                    child: Text('أضف'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosModeBody() {
    // استبعاد السجائر والشيشة إذا كانت غير مفعلة في الإعدادات
    // + استبعاد أصناف الأقسام/القوائم المقفولة
    final disabledKeys =
        _categories
            .where((c) => (c['is_enabled'] ?? 1) != 1)
            .map((c) => c['key'] as String? ?? '')
            .toSet();
    final availableDrinks =
        drinks.where((d) {
          if (d.temperature == 'cigarette' && !_cigarettesEnabled) return false;
          if (d.temperature == 'shisha' && !_shishaEnabled) return false;
          if (disabledKeys.contains(d.temperature)) return false;
          if (d.moduleId != null && !_enabledModuleIds.contains(d.moduleId)) {
            return false;
          }
          return true;
        }).toList();

    // لو "الكل" مختارة، اعرض الأصناف المتاحة فقط بدون السجائر والشيشة المغلقة
    final categoryDrinks = _filterDrinks(
      _selectedCategory == 'all'
          ? availableDrinks
          : availableDrinks
              .where((d) => d.temperature == _selectedCategory)
              .toList(),
    );

    return Row(
      children: [
        _buildCategoryRail(),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'ابحث عن مشروب أو منتج'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _refresh(() => searchQuery = value),
                ),
              ),
              Expanded(
                child:
                    categoryDrinks.isEmpty
                        ? Center(child: Text('لا توجد أصناف'.tr()))
                        : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 120,
                                mainAxisExtent: 120,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                              ),
                          itemCount: categoryDrinks.length,
                          itemBuilder:
                              (_, i) => _buildPosItemCard(categoryDrinks[i]),
                        ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 300, child: _buildCartPanel()),
      ],
    );
  }

  Widget _buildCategoryRail() {
    return SizedBox(
      width: 76,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children:
              _categoryLabels.entries.map((entry) {
                final selected = _selectedCategory == entry.key;
                final icon =
                    _categoryIcons[entry.key] ?? Icons.local_drink_rounded;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Tooltip(
                    // 🆕 يلف الزرار كله
                    message:
                        entry.value, // 🆕 النص اللي هيظهر عند الوقوف بالماوس
                    waitDuration: const Duration(
                      milliseconds: 400,
                    ), // 🆕 يظهر بسرعة معقولة
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap:
                            () => _refresh(() => _selectedCategory = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? const Color(0xFF6FCF97)
                                    : Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                size: 24,
                                color:
                                    selected ? Colors.white : Colors.grey[600],
                              ),
                              /*  const SizedBox(height: 6),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                          ),*/
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildPosItemCard(DrinkModel d) {
    final inCartQty = _cartQty[d.id] ?? 0;
    final outOfStock = d.qty <= 0;
    final selected = inCartQty > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Opacity(
          opacity: outOfStock ? 0.45 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF6FCF97) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(selected ? 0.15 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أيقونة داخل دائرة خفيفة
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? Colors.white.withOpacity(0.25)
                                  : const Color(0xFF6FCF97).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForTemperature(d.temperature),
                          size: 18,
                          color:
                              selected ? Colors.white : const Color(0xFF6FCF97),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        d.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color:
                              selected ? Colors.white : const Color(0xFF1A2233),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '{v1} ج'.tr({'v1': d.price.toStringAsFixed(0)}),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color:
                                  selected
                                      ? Colors.white
                                      : const Color(0xFF6FCF97),
                            ),
                          ),
                          const Spacer(),
                          if (!outOfStock)
                            Text(
                              '${d.qty}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    selected
                                        ? Colors.white.withOpacity(0.85)
                                        : (d.qty <= 5
                                            ? Colors.orange[700]
                                            : Colors.grey[500]),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // بادج الكمية في السلة
                if (inCartQty > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$inCartQty',
                        style: const TextStyle(
                          color: Color(0xFF6FCF97),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // شريط "غير متوفر"
                if (outOfStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'خلص'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    final cartEntries = _cartQty.entries.toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF6FCF97).withOpacity(0.15),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF6FCF97),
                ),
                const SizedBox(width: 8),
                Text(
                  'فاتورة الطلب'.tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '{v1} صنف'.tr({'v1': cartEntries.length}),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                cartEntries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'السلة فاضية'.tr(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'دوس على أي صنف عشان تضيفه'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: cartEntries.length,
                      itemBuilder: (_, i) {
                        final entry = cartEntries[i];
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
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _removeFromCart(entry.key),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      drink.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '{v1} ج × {v2} = {v3} ج'.tr({
                                        'v1': drink.price.toStringAsFixed(2),
                                        'v2': entry.value,
                                        'v3': lineTotal.toStringAsFixed(2),
                                      }),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () => _decrementCart(entry.key),
                              ),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (entry.value + 1 > drink.qty) {
                                    _showSnack(
                                      'الكمية أكبر من المتاح ({v1})'.tr({
                                        'v1': drink.qty,
                                      }),
                                    );
                                    return;
                                  }
                                  _incrementCart(drink);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_cartTotal.toStringAsFixed(2)} ${Money.txt}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6FCF97),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FCF97),
                    ),
                    onPressed:
                        (_isLoading || cartEntries.isEmpty)
                            ? null
                            : _confirmCartOrder,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              'تأكيد الطلب'.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
