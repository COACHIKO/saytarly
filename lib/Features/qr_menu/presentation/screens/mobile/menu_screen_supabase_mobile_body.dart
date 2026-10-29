part of '../menu_screen_supabase.dart';

/// جسم شاشة المنيو عبر Supabase — نسخة الموبايل (زي ما كانت بالظبط).
extension _MenuScreenMobileBody on _MenuScreenState {
  Widget _buildMobileBody(BuildContext context) {
    if (_submitted) return _buildThanksScreen();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text('📋 المنيو'.tr(),
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              Text(widget.tableName,
                  style: const TextStyle(color: Colors.amber, fontSize: 13)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54),
              onPressed: _loadDrinks,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: _MenuScreenState._categories
                .map((c) => Tab(text: c['label'] as String))
                .toList(),
          ),
        ),
        body: _loading
            ?  Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 16),
                    Text('جاري تحميل المنيو...'.tr(),
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('😔', style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 15)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black),
                          icon: const Icon(Icons.refresh),
                          label:  Text('إعادة المحاولة'.tr()),
                          onPressed: _loadDrinks,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: _MenuScreenState._categories.map((c) {
                            final drinks = _filteredDrinks(c['temps']);
                            if (drinks.isEmpty) {
                              return  Center(
                                child: Text('لا يوجد منتجات'.tr(),
                                    style:
                                        TextStyle(color: Colors.white54)),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.05,
                              ),
                              itemCount: drinks.length,
                              itemBuilder: (_, i) =>
                                  _buildDrinkCard(drinks[i]),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_cart.isNotEmpty) _buildCartBar(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDrinkCard(Map<String, dynamic> drink) {
    final id = drink['id'] as int;
    final qty = _cart[id] ?? 0;
    final price = (drink['price'] as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qty > 0 ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_drinkEmoji(drink['temperature'] as String? ?? ''),
              style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              drink['name'] as String,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text('{v1} ج'.tr({'v1': price.toStringAsFixed(0)}),
              style:  TextStyle(color: Colors.amber, fontSize: 13)),
           SizedBox(height: 8),
          if (qty == 0)
            GestureDetector(
              onTap: () => _addToCart(id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child:  Text('إضافة'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleBtn(Icons.remove, () => _removeFromCart(id)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('$qty',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                _circleBtn(Icons.add, () => _addToCart(id)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration:
            const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Colors.black),
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      color: const Color(0xFF0F3460),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration:  InputDecoration(
              hintText: 'ملاحظة للطلب (اختياري)'.tr(),
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber)),
            ),
            onChanged: (v) => _note = v,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '{_cartTotal} صنف'.tr({'_cartTotal': _cartTotal}),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    '{v1} ج'.tr({'v1': _cartPrice.toStringAsFixed(0)}),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitting ? null : _submitOrder,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'جاري الإرسال...'.tr() : 'أرسل الطلب'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThanksScreen() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✅', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
               Text('تم إرسال طلبك!'.tr(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(widget.tableName,
                  style:
                      const TextStyle(color: Colors.amber, fontSize: 18)),
              const SizedBox(height: 8),
               Text('سيتم تحضير طلبك قريباً 🎉'.tr(),
                  style:
                      TextStyle(color: Colors.white54, fontSize: 15)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black),
                icon: const Icon(Icons.refresh),
                label:  Text('طلب جديد'.tr()),
                onPressed: () => _refresh(() {
                  _cart.clear();
                  _submitted = false;
                  _note = '';
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _drinkEmoji(String temp) {
    switch (temp) {
      case 'hot':
        return '☕';
      case 'cold':
        return '🧊';
      case 'normal':
        return '🥤';
      case 'prodect':
        return '🛍';
      default:
        return '🍹';
    }
  }
}
