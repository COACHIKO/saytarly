part of '../customers_report_screen.dart';

/// جسم تقرير العملاء الشهري — نسخة الموبايل (زي ما كانت بالظبط).
extension _CustomersReportScreenMobileBody on _CustomersReportScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير العملاء الشهري'.tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? Center(child: Text('لا توجد بيانات لهذا الشهر'.tr()))
              : ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (_, i) {
                    final c = _customers[i];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      child: ListTile(
                        title: Text(c['customer_name'] ?? 'بدون اسم'.tr()),
                        subtitle: Text('عدد الفواتير: {v1}'.tr({'v1': c['invoice_count']})),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '{v1} ج'.tr({'v1': (c['total_income'] ?? 0).toStringAsFixed(2)}),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _confirmDeleteCustomer(c['customer_name']),
                            ),
                          ],
                        ),
                        onTap: c['customer_name'] == null
                            ? null
                            : () => _showCustomerInvoices(c['customer_name']),
                      ),
                    );
                  },
                ),
    );
  }
}
