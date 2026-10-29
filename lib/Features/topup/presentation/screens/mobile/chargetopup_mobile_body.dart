part of '../chargetopup.dart';

/// جسم شاشة شحن الرصيد (كاشير) — نسخة الموبايل (زي ما كانت بالظبط).
extension _ChargetopMobileBody on _CashierScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final profit = (double.tryParse(_receivedController.text) ?? 0) -
        (double.tryParse(_costController.text) ?? 0);
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: Text('شحن رصيد '.tr()),
        //  backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // صف بطاقات المعلومات
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    title: 'رصيد المكنة'.tr(),
                    value: '$_balance',
                    icon: Icons.account_balance_wallet,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    title: 'الربح الحالي'.tr(),
                    value: profit.toStringAsFixed(2),
                    icon: Icons.monetization_on,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // مدخلات العملية
            _inputCard(),
            const SizedBox(height: 16),
            // آخر العمليات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('آخر العمليات'.tr(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (_, i) {
                          final t = _transactions[i];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Icon(Icons.receipt_long,
                                  color: Colors.deepPurple),
                              title: Text(
                                  'التكلفة: {v1} - المستلم: {v2}'.tr({'v1': t['cost'], 'v2': t['received']})),
                              subtitle: Text(
                                  'الربح: {v1} • {v2}'.tr({'v1': t['profit'], 'v2': formatArabicDate(DateTime.parse(t['date']))})),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// تابع لبناء كروت المعلومات
  Widget _infoCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

// تابع لبناء كروت إدخال العملية
  Widget _inputCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _costController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'تكلفة العملية (المخصومة من المكنة)'.tr(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => _refresh(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _receivedController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ المستلم من الزبون'.tr(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => _refresh(() {}),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _record,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('تسجيل العملية'.tr(), style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
