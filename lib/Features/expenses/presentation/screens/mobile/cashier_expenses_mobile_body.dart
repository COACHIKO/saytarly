part of '../cashier_expenses.dart';

/// جسم شاشة مصروفات الكاشير — نسخة الموبايل (زي ما كانت بالظبط).
extension _CashierExpensesScreenMobileBody on _CashierExpensesScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: Text('مصروفات الكاشير - {v1}'.tr({'v1': widget.cashierName})),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // كروت المعلومات
            /*     Row(
              children: [

                SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _expensesFuture,
                    builder: (context, snapshot) {
                      int count = 0;
                      if (snapshot.hasData) {
                        count = snapshot.data!.length;
                      }
                      return _infoCard(
                        title: "عدد المصروفات",
                        value: count.toString(),
                        icon: Icons.money_off,
                        color: Colors.orange,
                      );
                    },
                  ),
                ),

              ],
            ),*/
            SizedBox(height: 16),
            // إدخال مصروف جديد
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descCtrl,
                        decoration: InputDecoration(
                          labelText: 'وصف المصروف'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'أدخل الوصف'.tr() : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'المبلغ'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل المبلغ'.tr();
                          if (double.tryParse(v) == null)
                            return 'أدخل رقم صحيح'.tr();
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _addExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6FCF97),
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('إضافة المصروف'.tr(),
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // قائمة المصروفات
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: {v1}'.tr({'v1': snapshot.error})));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('لا توجد مصروفات لهذا الشيفت'.tr()));
                  }

                  final expenses = snapshot.data!;
                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final e = expenses[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(Icons.receipt_long,
                              color:  Color(0xFF6FCF97)),
                          title: Text(e['description']),
                          subtitle: Text('التاريخ: {v1}'.tr({'v1': formatDate(e['date'])})),
                          trailing: Text('{v1} ج'.tr({'v1': e['amount']}),
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
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
