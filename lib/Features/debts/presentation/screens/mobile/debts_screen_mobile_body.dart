part of '../debts_screen.dart';

/// جسم شاشة الديون — نسخة الموبايل (زي ما كانت بالظبط).
extension _DebtsScreenMobileBody on _DebtsScreenState { 
  Widget _buildMobileBody(BuildContext context) {
    // 🆕 المجموع من remaining_amount بدل total_amount
    double totalAll = filteredDebts.fold(
      0,
      (sum, d) => sum + (d['remaining_amount'] as num).toDouble(),
    );

    return Scaffold(
      appBar: AppBar(
        title:  Text('الديون المسجلة'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة جرد الديون'.tr(),
            onPressed: _printDebtsInventory,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'استعادة نسخة'.tr(),
            onPressed: _restoreBackup,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'تصدير نسخة'.tr(),
            onPressed: _exportBackup,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔍 حقل البحث
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث باسم العميل...'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: _filterDebts,
            ),
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  'إجمالي الاجل'.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${formatter.format(totalAll)} ${Money.txt}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child:
                  _isLoadingDebts // 🆕
                  ? const Center(child: CircularProgressIndicator())
                  : filteredDebts.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد ديون حالياً'.tr(),
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredDebts.length,
                      itemBuilder: (_, i) {
                        final d = filteredDebts[i];
                        final date = DateTime.tryParse(d['date'].toString());
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            title: Text(
                              d['customer_name'] ?? 'غير معروف'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: date != null
                                ? Text(
                                    'التاريخ: {v1}'.tr({'v1': DateFormat('yyyy-MM-dd HH:mm').format(date)}),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  // 🆕 remaining_amount بدل total_amount
                                  '${formatter.format(d['remaining_amount'])} ${Money.txt}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.print, size: 20),
                                  tooltip: 'طباعة دين {v1}'.tr({'v1': d['customer_name']}),
                                  onPressed: () => _printSingleDebt(
                                    d['customer_name'] ?? 'غير معروف'.tr(),
                                    d['ids'],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              final ids = d['ids'];
                              final idList = ids is List
                                  ? ids.cast<int>()
                                  : [ids as int];
                              _showDebtDetails(
                                idList,
                                d['customer_name'] ?? 'غير معروف'.tr(),
                                // 🆕 remaining_amount بدل total_amount
                                (d['remaining_amount'] ?? 0).toDouble(),
                              );
                            },
                            onLongPress: () => _deleteDebt(d['id'] ?? 0),
                          ),
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

