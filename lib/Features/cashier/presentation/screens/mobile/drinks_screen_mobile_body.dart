part of '../DrinksScreen.dart';

/// جسم لوحة الترابيزات — نسخة الموبايل (زي ما كانت بالظبط).
extension _DrinksscreenDashboardMobileBody on _DrinksscreenDashboardState {

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [],
        title: Text('لوحة الموظف'.tr(), style: TextStyle(color: Colors.green)),
        elevation: 1,
        // backgroundColor: Colors.transparent, // مهم لتصبح الخلفية شفافة
        /*   flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage('assets/images/back.jpg'), // ضع مسار الصورة هنا
                fit: BoxFit.cover, // لتغطية كامل المساحة
              ),
            ),
          ),*/
        iconTheme: IconThemeData(color: Color(0xFF6FCF97)),
      ),
      body: Stack(
        children: [
          BlurryBackgroundPage(),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintStyle: const TextStyle(
                              color: Colors.white70, // أبيض (خفيف شوية)
                            ),
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: 'ابحث عن الترابيزة أو العميل...'.tr(),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF6FCF97),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: const TextStyle(
                            color:
                                Colors.white, // لون النص اللي المستخدم بيكتبه
                          ),
                          onChanged: (value) {
                            _refresh(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6FCF97),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final countCtrl = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (dialogContext) => AppDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title:  Text(
                              'عدد الترابيزات الجديدة'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: TextField(
                              controller: countCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'أدخل العدد'.tr(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  final count =
                                      int.tryParse(countCtrl.text) ?? 0;
                                  // جلب آخر ترابيزة موجودة
                                  final tables = await DBHelper.getAllTables();
                                  int lastNumber = tables.isEmpty
                                      ? 0
                                      : tables
                                            .map(
                                              (t) =>
                                                  int.tryParse(
                                                    t['name'].split(' ')[1],
                                                  ) ??
                                                  0,
                                            )
                                            .reduce((a, b) => a > b ? a : b);

                                  // إضافة الترابيزات الجديدة بعد آخر رقم موجود
                                  for (int i = 1; i <= count; i++) {
                                    await DBHelper.insertTable(
                                      'ترابيزة {v1}'.tr({'v1': lastNumber + i}),
                                    );
                                  }
                                  Navigator.pop(dialogContext);
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
                      },
                      child: Text('إضافة عدد التربيزات'.tr()),
                    ),
                    /*  SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.shopping_bag),
                  label: Text("تيك أواي"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _startTakeaway,
                ),*/

                    /*Container(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _clearAllTables,
                    icon: Icon(Icons.delete_forever),
                    label: Text('تفريغ الكل'),
                  ),
                ),*/
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 405,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: filteredTables.length,
                    itemBuilder: (_, i) {
                      final t = filteredTables[i];
                      final activeInvoice = t['active_invoice_id'];

                      return SizedBox(
                        height: 300, // الارتفاع النهائي للكارت
                        child: Card(
                          elevation: 12,
                          color: Colors.transparent,
                          shadowColor: Colors.black38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.6),
                                  Colors.deepPurple.shade50.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            padding:  EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 14,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // 🔥 يظبط التوزيع
                              children: [
                                // العنوان
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chair_alt,
                                      size: 26,
                                      color: Colors.blueGrey,
                                    ),
                                     SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        t['displayName'],
                                        overflow: TextOverflow.ellipsis,
                                        style:  TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // الحالة
                                Container(
                                  padding:  EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: activeInvoice == null
                                          ? [
                                              Colors.green.shade400,
                                              Colors.green.shade700,
                                            ]
                                          : [
                                              Colors.red.shade400,
                                              Colors.red.shade700,
                                            ],
                                    ),
                                  ),
                                  child: FittedBox(
                                    child: Text(
                                      activeInvoice == null
                                          ? '✔ متاحة'.tr()
                                          : "⛔ محجوزة",
                                      style:  TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // الأزرار
                                if (activeInvoice == null)
                                  ElevatedButton(
                                    onPressed: () => _startSession(t),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF6FCF97),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 22,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child:  Text('فتح ترابيزة'.tr()),
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _actionBtn(
                                          icon: Icons.restore,
                                          label: 'تحرير'.tr(),
                                          color: Colors.orange,
                                          onTap: () async {
                                            final ok = await _checkPassword();

                                            if (!ok) {
                                              AppToast.show('كلمة المرور غير صحيحة'.tr(),);
                                              return;
                                            }

                                            await forceCloseTable(t['id']);
                                            await _load();
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: _actionBtn(
                                          icon: Icons.payments,
                                          label: 'دفع جزئي'.tr(),
                                          color: Colors.teal,
                                          onTap: () => _partialPayment(t), // 🆕
                                        ),
                                      ),
                                      Expanded(
                                        child: _actionBtn(
                                          icon: Icons.local_drink,
                                          label: 'إضافة'.tr(),
                                          color: Colors.blue,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AddDrinksScreen(
                                                  invoiceId: activeInvoice,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: _actionBtn(
                                          icon: Icons.receipt_long,
                                          label: 'فاتورة'.tr(),
                                          color: Colors.deepPurple,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    DrinksInvoiceScreen(
                                                      invoiceId: activeInvoice,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: _actionBtn(
                                          icon: Icons.close,
                                          label: 'إنهاء'.tr(),
                                          color: Colors.red,
                                          onTap: () async {
                                            await _endSession(
                                              t,
                                            ); // 🔧 الطباعة بقت بتحصل جوه الدالة نفسها حسب اختيار المستخدم
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ نفس فكرة النسبة، لكن مع حد أدنى وأقصى يمنعوا الأيقونة/النص
        // من إنهم يبقوا صغيرين جدًا حتى لو الزرار ضيق، أو كبار أوي لو
        // الزرار واسع بشكل غير متوقع.
        final iconSize = (constraints.maxWidth * 0.32).clamp(20.0, 34.0);
        final padding = (constraints.maxWidth * 0.10).clamp(6.0, 14.0);
        final textSize = (constraints.maxWidth * 0.16).clamp(11.0, 15.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: iconSize, color: color),
              ),
            ),
            SizedBox(height: constraints.maxWidth * 0.08),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
}

