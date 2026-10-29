part of '../reports.dart';

/// جسم شاشة التقارير المفصلة — نسخة الموبايل (زي ما كانت بالظبط).
extension _ReportsScreenMobileBody on _ReportsScreenState {

  Widget _buildMobileBody(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < _ReportsScreenState._mobileBreakpoint;

    return Scaffold(
      appBar: _buildAppBar(isMobile),
      // 🆕 زرار عائم يفتح المصروفات في صفحة سفلية (بدل السكرول القديم)
      floatingActionButton: FloatingActionButton(
        onPressed: _showExpensesSheet,
        tooltip: 'المصروفات'.tr(),
        child: const Icon(Icons.receipt_long),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 10.0 : 16.0),
        child: Column(
          children: [
            _buildSummaryCards(),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: _scrollController, // 🆕
                addAutomaticKeepAlives:
                    false, // 🚀 أقل استهلاك ذاكرة مع قوائم طويلة
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  return _buildInvoiceTile(invoices[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📱 AppBar تختلف حسب المساحة:
  // - Desktop/Tablet واسع: كل الأزرار ظاهرة جنب بعض زي الأصل.
  // - Mobile: أيقونة تقويم للتاريخ + قائمة (⋮) لباقي الخيارات،
  //   عشان محدش يعمل Overflow.
  // 🆕 أيقونة العين (إظهار/إخفاء الأرقام) موجودة في النسختين.
  // ============================================================
  PreferredSizeWidget _buildAppBar(bool isMobile) {
    if (!isMobile) {
      return AppBar(
        title: Text('تقارير مفصلة'.tr()),
        actions: [
          ElevatedButton(
            child: Text('عرض كل الفواتير'.tr()),
            onPressed: _showAllInvoices,
          ),
          SizedBox(width: 20),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'الفواتير بتاريخ: {v1}'.tr({'v1': DateFormat('yyyy-MM-dd').format(_selectedDate!)}),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          SizedBox(width: 10),
          ElevatedButton(child: Text('اختر تاريخ'.tr()), onPressed: _pickDate),
          SizedBox(width: 20),
          // 🆕 أيقونة العين
          IconButton(
            icon: Icon(
              _numbersVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _toggleNumbersVisibility,
            tooltip: _numbersVisible ? 'إخفاء الأرقام'.tr() : 'إظهار الأرقام',
          ),
          IconButton(
            icon: Icon(Icons.inventory_outlined),
            onPressed: _openIncomeStats,
            tooltip: 'معلومات اكتر علي الدخل'.tr(),
          ),
          SizedBox(width: 20),
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _deleteAllInvoices,
            tooltip: 'مسح الكل'.tr(),
          ),
        ],
      );
    }

    // 📱 نسخة الموبايل
    return AppBar(
      title: Text('تقارير مفصلة'.tr(), style: TextStyle(fontSize: 17)),
      actions: [
        // 🆕 أيقونة العين
        IconButton(
          icon: Icon(_numbersVisible ? Icons.visibility : Icons.visibility_off),
          tooltip: _numbersVisible ? 'إخفاء الأرقام'.tr() : 'إظهار الأرقام',
          onPressed: _toggleNumbersVisibility,
        ),
        IconButton(
          icon: Icon(Icons.calendar_today),
          tooltip: 'اختر تاريخ'.tr(),
          onPressed: _pickDate,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'all':
                _showAllInvoices();
                break;
              case 'stats':
                _openIncomeStats();
                break;
              case 'delete':
                _deleteAllInvoices();
                break;
            }
          },
          itemBuilder: (_) => [
             PopupMenuItem(value: 'all', child: Text('عرض كل الفواتير'.tr())),
             PopupMenuItem(
              value: 'stats',
              child: Text('معلومات اكتر عن الدخل'.tr()),
            ),
             PopupMenuItem(
              value: 'delete',
              child: Text('مسح الكل'.tr(), style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
      bottom: _selectedDate != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'بتاريخ: {v1}'.tr({'v1': DateFormat('yyyy-MM-dd').format(_selectedDate!)}),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
    );
  }

  // ============================================================
  // 📊 كروت الملخص — بتحسب عدد الأعمدة وعرض كل كارت ديناميكيًا
  // حسب المساحة المتاحة فعليًا (مش MediaQuery.size.width اللي
  // بيدّي عرض الشاشة كله حتى لو الصفحة جوه Drawer أو نص الشاشة).
  // 🆕 القيم كلها بتتعرض من خلال _mask() فتتخفي لو الأرقام مقفولة.
  // ============================================================
  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount;
        if (width < 380) {
          crossAxisCount = 1;
        } else if (width < 620) {
          crossAxisCount = 2;
        } else if (width < 900) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 5;
        }

        const spacing = 8.0;
        final cardWidth =
            (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

        final cardsData = <_SummaryCardData>[
          _SummaryCardData(
            'رصيد درج الكاش'.tr(),
            _mask('${formatter.format(cashDrawerBalance)} ${Money.txt}'),
            Colors.blueAccent,
            Icons.point_of_sale,
          ),
          _SummaryCardData(
            'إجمالي الدخل'.tr(),
            _mask(formatter.format(totalIncome)),
            Colors.green,
            Icons.trending_up,
          ),
          _SummaryCardData(
            'مبيعات المنتجات'.tr(),
            _mask('${formatter.format(productSales)} ${Money.txt}'),
            Colors.teal,
            Icons.shopping_bag,
          ),
          _SummaryCardData(
            'مبيعات المشروبات'.tr(),
            _mask('${formatter.format(drinkSales)} ${Money.txt}'),
            Colors.blue,
            Icons.local_cafe,
          ),

          if (_cigarettesEnabled) // 🆕
            _SummaryCardData(
              'مبيعات السجائر'.tr(),
              _mask('${formatter.format(cigarettesSales)} ${Money.txt}'),
              Colors.brown,
              Icons.smoking_rooms,
            ),
          if (_shishaEnabled) // 🆕
            _SummaryCardData(
              'مبيعات الشيشة'.tr(),
              _mask('${formatter.format(shishaSales)} ${Money.txt}'),
              Colors.deepPurple,
              Icons.blur_on,
            ),
          _SummaryCardData(
            'دخل الأجهزة'.tr(),
            _mask('${formatter.format(deviceIncome)} ${Money.txt}'),
            Colors.indigo,
            Icons.videogame_asset,
          ),
          _SummaryCardData(
            'الديون المتبقية'.tr(),
            _mask('${formatter.format(debtTotal)} ${Money.txt}'),
            Colors.redAccent,
            Icons.warning_amber_rounded,
          ),
          _SummaryCardData(
            'المصاريف'.tr(),
            _mask(
              formatter.format(
                expenses.fold(
                  0.0,
                  (p, e) => p + ((e['amount'] ?? 0) as num).toDouble(),
                ),
              ),
            ),
            Colors.redAccent,
            Icons.money_off,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cardsData
              .map(
                (d) => _buildCard(d.title, d.value, d.color, cardWidth, d.icon),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildInvoiceTile(Map<String, dynamic> inv) {
    final start = DateTime.parse(inv['start_time']);
    final end = inv['end_time'] != null
        ? DateTime.parse(inv['end_time'])
        : null;

    final isDebt = inv['payment_type'] == 'علي الحساب';
    final isCancelled = inv['payment_type'] == 'ملغي';
    final statusColor = isCancelled
        ? Colors.grey
        : (isDebt ? Colors.red : Colors.green);
    final statusLabel = isCancelled ? 'ملغية'.tr() : (isDebt ? 'آجل'.tr() : 'مدفوعة');
    final statusIcon = isCancelled
        ? Icons.cancel
        : (isDebt ? Icons.account_balance_wallet : Icons.check_circle);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Row(
          children: [
            Text(
              'فاتورة #{v1}'.tr({'v1': inv['id']}),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '{v1}   •   الإجمالي: {v2} {v3}'.tr({'v1': DateFormat('yyyy-MM-dd HH:mm').format(start), 'v2': _mask(formatter.format(inv['total_cost'] ?? 0)), 'v3': Money.txt}),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
        // 🆕 مفيش FutureBuilder خالص — البيانات جاهزة من _load()
        children: [_buildInvoiceDetails(inv, isDebt, start, end)],
      ),
    );
  }

  // 🆕 دالة منفصلة تستخدم البيانات المحسوبة مسبقًا بدل ما تعمل query جديدة
  Widget _buildInvoiceDetails(
    Map<String, dynamic> inv,
    bool isDebt,
    DateTime start,
    DateTime? end,
  ) {
    final items = (inv['_items'] as List<Map<String, dynamic>>?) ?? [];
    final paidAmount = (inv['_paidAmount'] as double?) ?? 0.0;
    final invoiceTotal = (inv['_invoiceTotal'] as double?) ?? 0.0;
    final remaining = (inv['_remaining'] as double?) ?? 0.0;
    final discount = ((inv['discount'] ?? 0) as num).toDouble();
    final drinksCost = ((inv['drinks_cost'] ?? 0) as num).toDouble();
    final deviceCost = ((inv['device_cost'] ?? 0) as num).toDouble();
    final cigCost = ((inv['cigarettes_cost'] ?? 0) as num).toDouble();
    final shishaCost = ((inv['shisha_cost'] ?? 0) as num).toDouble();
    final productsCost = ((inv['products_cost'] ?? 0) as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inv['console_id'] != 0) ...[
          _infoRow(
            'الجهاز'.tr(),
            (inv['console_name'] ?? inv['console_id']).toString(),
          ),
          _infoRow('وقت البداية'.tr(), DateFormat('yyyy-MM-dd HH:mm').format(start)),
        ] else
          _infoRow('النوع'.tr(), 'ترابيزة'.tr()),
        _infoRow(
          'وقت الدفع'.tr(),
          end != null ? DateFormat('yyyy-MM-dd HH:mm').format(end) : 'جاري',
        ),
        const SizedBox(height: 10),
        Text(
          'الأصناف'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const Divider(height: 12),
        if (items.isEmpty)
           Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('لا توجد أصناف'.tr()),
          )
        else
          ...items.map((item) {
            double displayTotal = (item['total'] ?? 0.0).toDouble();
            if (item['drink_name'] == 'شحن رصيد' && displayTotal == 0) {
              displayTotal = inv['total_cost']?.toDouble() ?? 0.0;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '{v1}  x{v2}'.tr({'v1': item['drink_name'] ?? 'شحن رصيد'.tr(), 'v2': item['qty']}),
                    ),
                  ),
                  Text(
                    _mask(displayTotal.toStringAsFixed(2)),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 10),
        Text(
          'الحساب'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const Divider(height: 12),
        _financialRow('المشروبات'.tr(), drinksCost),
        if (productsCost > 0) _financialRow('المنتجات / مأكولات'.tr(), productsCost),
        if (cigCost > 0) _financialRow('السجائر'.tr(), cigCost),
        if (shishaCost > 0) _financialRow('الشيشة'.tr(), shishaCost),
        if (deviceCost > 0) _financialRow('تكلفة الجهاز'.tr(), deviceCost),
        if (discount > 0)
          _financialRow('الخصم'.tr(), discount, color: Colors.orange),
        const Divider(height: 12),
        _financialRow('الإجمالي'.tr(), invoiceTotal, bold: true),
        _financialRow('المدفوع'.tr(), paidAmount, color: Colors.green),
        if (isDebt && remaining > 0)
          _financialRow(
            'المتبقي (آجل)'.tr(),
            remaining,
            color: Colors.red,
            bold: true,
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 🆕 القيمة المعروضة بتتقفل من خلال _mask() لو الأرقام مخفية
  Widget _financialRow(
    String label,
    double value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _mask('${value.toStringAsFixed(2)} ${Money.txt}'),
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    String title,
    String value,
    Color color,
    double width,
    IconData icon,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(right: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

