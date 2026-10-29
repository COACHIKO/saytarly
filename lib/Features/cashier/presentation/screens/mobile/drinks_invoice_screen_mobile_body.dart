part of '../DrinksInvoiceScreen.dart';

/// جسم شاشة مشروبات الفاتورة — نسخة الموبايل (زي ما كانت بالظبط).
extension _DrinksInvoiceScreenMobileBody on _DrinksInvoiceScreenState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مشروبات الفاتورة #{v1}'.tr({'v1': widget.invoiceId})),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'إضافة مشروب'.tr(),
            onPressed: () async {
              // ننتظر المستخدم يرجع من الشاشة
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDrinksScreen(invoiceId: widget.invoiceId),
                ),
              );

              // لو الشاشة رجعت نتيجة أو مجرد رجوع نحدث الصفحة

              _refresh(() {
                // هنا تقدر تحدث الـ items أو أي بيانات تحتاج إعادة تحميل
                _loadItems(); // مثال: دالة لإعادة جلب المشروبات
              });
            },
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد مشروبات'.tr(),
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return Card(
                            margin: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            shadowColor: Colors.black26,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      it['drink_name'],
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: qtyControllers[it['id']],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Theme.of(context).cardColor,
                                        labelText: 'كمية'.tr(),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (_) =>
                                          _updateItemQty(it['id'] as int),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '${(it['total'] as num).toDouble().toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.red.shade400,
                                    child: IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.white),
                                      onPressed: () =>
                                          _removeItem(it['id'] as int),
                                      iconSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Color(0xFF6FCF97), Colors.deepPurpleAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي'.tr(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      totalDrinksCost.toStringAsFixed(2),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}

