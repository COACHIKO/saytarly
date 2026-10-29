part of '../invoice_screen.dart';

/// جسم شاشة الفاتورة — نسخة الموبايل (زي ما كانت بالظبط).
extension _InvoiceScreenMobileBody on _InvoiceScreenState {

  Widget _buildMobileBody(BuildContext context) {
    if (invoice == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final start = invoice!['start_time'] != null
        ? DateTime.parse(invoice!['start_time'])
        : null;

    final end = invoice!['end_time'] != null
        ? DateTime.parse(invoice!['end_time'])
        : null;

    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('الفاتورة #{v1}'.tr({'v1': invoice!['id']})),
        centerTitle: true,
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
                _load(); // مثال: دالة لإعادة جلب المشروبات
              });
            },
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ▦ معلومات الجهاز
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الجهاز:'.tr(),
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${invoice!['console_id']}',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.deepPurple.shade300)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('بداية الوقت:'.tr()),
                          Text(start != null ? df.format(start) : '-'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('نهاية :'.tr()),
                          Text(end != null ? df.format(end) : '-'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 14),

              // ▦ عنوان المشروبات
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'المشروبات'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              SizedBox(height: 10),

              // ▦ قائمة المشروبات
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      shadowColor: Colors.black26,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            // اسم المشروب
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it['drink_name'],
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade300),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'السعر: {v1}'.tr({'v1': it['drink_price'].toStringAsFixed(2)}),
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[700]),
                                  )
                                ],
                              ),
                            ),

                            SizedBox(width: 10),

                            // الكمية
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: qtyControllers[it['id']],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  fillColor: Theme.of(context).cardColor,
                                  isDense: true,
                                  labelText: 'عدد'.tr(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onChanged: (_) => _updateItemQty(it['id']),
                              ),
                            ),

                            SizedBox(width: 12),

                            // المجموع
                            Text(
                              '${(it['total'] as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700]),
                            ),

                            SizedBox(width: 12),

                            // زرار الحذف
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.red.shade400,
                              child: IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.white, size: 18),
                                onPressed: () => _removeItem(it['id'] as int),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 12),

              // ▦ الإجمالي
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                margin: EdgeInsets.symmetric(horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      _totalRow('تكلفة الجهاز:'.tr(),
                          (invoice!['device_cost'] ?? 0).toStringAsFixed(2)),
                      _totalRow(
                          'تكلفة المشروبات:'.tr(),
                          items
                              .fold(0.0, (a, b) => a + (b['total'] as num))
                              .toStringAsFixed(2)),
                      Divider(thickness: 1.2, color: Colors.grey[300]),
                      _totalRow(
                        'الإجمالي النهائي:'.tr(),
                        totalCost.toStringAsFixed(2),
                        bold: true,
                        big: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _totalRow(String t, String v, {bool bold = false, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t,
              style: TextStyle(
                fontSize: big ? 17 : 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(v,
              style: TextStyle(
                fontSize: big ? 17 : 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}

