part of '../Topup.dart';

/// جسم شاشة الماكينة/الشحن — نسخة الموبايل (زي ما كانت بالظبط).
extension _TopupMobileBody on _AdminScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final totalOps = _summary['total_ops'] ?? 0;
    final totalCost = (_summary['total_received'] ?? 0).toString();
    final totalReceived = (_summary['total_cost'] ?? 0).toString();
    final totalProfit = (_summary['total_profit'] ?? 0).toString();

    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AppDialog(
                  title:  Text('تأكيد الحذف'.tr()),
                  content:  Text('هل أنت متأكد أنك تريد مسح كل العمليات؟'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child:  Text('إلغاء'.tr()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child:  Text('تأكيد'.tr()),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await DBHelper.deleteAllTransactions();
                await _reload(); // إعادة تحميل البيانات بعد المسح
                AppToast.show('تم مسح كل العمليات بنجاح'.tr());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:  Text('مسح كل العمليات'.tr()),
          ),
        ],
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 8,left:8),
        //     child: ElevatedButton(
        //       onPressed: _printReport,
        //       child: const Text("طباعة اليوم"),
        //     ),
        //   ),
        // ],
      ),
      body: Padding(
        padding:  EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title:  Text('رصيد الشحن'.tr()),
                subtitle: Text('$_balance'),
                trailing:  Icon(Icons.account_balance),
              ),
            ),
             SizedBox(height: 8),

            // فلترة التواريخ
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickFromDate,
                    child: Container(
                      padding:  EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _fromDate == null
                            ? 'من تاريخ'.tr()
                            : formatArabicDate(_fromDate!),
                      ),
                    ),
                  ),
                ),
                 SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _pickToDate,
                    child: Container(
                      padding:  EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _toDate == null
                            ? 'إلى تاريخ'.tr()
                            : formatArabicDate(_toDate!), // ← تم الإصلاح
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _loadAndApplyFilter();
                  },
                  child:  Text('تطبيق'.tr()),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _refresh(() {
                      _fromDate = null;
                      _toDate = null;
                    });
                    _loadAndApplyFilter();
                  },
                  child:  Text('مسح الفلتر'.tr()),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration:
                         InputDecoration(labelText: 'أضف رصيد للمكنة'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _addBalance, child:  Text('إضافة'.tr()))
              ],
            ),
            const SizedBox(height: 12),

             Text('تقارير المكنة'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('عدد العمليات (كُلها): {totalOps}'.tr({'totalOps': totalOps})),
                    Text('إجمالي التكلفة (خصم من المكنة): {totalCost}'.tr({'totalCost': totalCost})),
                    Text('إجمالي المستلم: {totalReceived}'.tr({'totalReceived': totalReceived})),
                    Text('إجمالي الربح: {totalProfit}'.tr({'totalProfit': totalProfit})),
                    const Divider(),
                     Text('ملخص الفلتر:'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        'عدد العمليات (المفلترة): {v1}'.tr({'v1': _filteredTransactions.length})),
                    Text(
                        'إجمالي التكلفة (المفلترة): {v1}'.tr({'v1': _totalCostFiltered.toStringAsFixed(2)})),
                    Text(
                        'إجمالي المستلم (المفلترة): {v1}'.tr({'v1': _totalReceivedFiltered.toStringAsFixed(2)})),
                    Text(
                        'إجمالي الربح (المفلترة): {v1}'.tr({'v1': _totalProfitFiltered.toStringAsFixed(2)})),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton(onPressed: _reload, child:  Text('تحديث'.tr())),

            const SizedBox(height: 12),
             Text('عرض كل العمليات'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // القائمة ضمن Expanded لتفادي overflow
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? Center(child: Text('لا توجد عمليات لعرضها'.tr()))
                  : ListView.builder(
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (_, i) {
                        final t = _filteredTransactions[i];
                        final date = DateTime.tryParse(t['date'].toString()) ??
                            DateTime.now();
                        return ListTile(
                          title: Text(
                              'التكلفة: {v1}  المستلم: {v2}'.tr({'v1': t['cost'], 'v2': t['received']})),
                          subtitle: Text(
                              'الربح: {v1} • {v2}'.tr({'v1': t['profit'], 'v2': _formattedDate(date)})),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

