part of '../AddExpenseScreen.dart';

/// جسم شاشة المصروفات (أدمن) — نسخة الموبايل (زي ما كانت بالظبط).
extension _AdminExpensesScreenMobileBody on _AdminExpensesScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('المصروفات'.tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            tooltip: 'مسح كل المصروفات'.tr(),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AppDialog(
                  title: Text('تأكيد مسح كل المصروفات'.tr()),
                  content: Text(
                      'هل أنت متأكد أنك تريد مسح كل المصروفات؟ هذا الإجراء لا يمكن التراجع عنه.'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('إلغاء'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('تأكيد'.tr()),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await DBHelper.clearAllExpenses();
                _refresh(() {
                  _loadExpenses();
                });
                AppToast.show('تم مسح كل المصروفات'.tr());
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickDate,
                  child: Text(_showAll
                      ? 'اختيار يوم'.tr()
                      : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _refresh(() {
                      _showAll = true;
                      _selectedDate = null;
                      _loadExpenses();
                    });
                  },
                  child:  Text('عرض الكل'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ---------------- Form إضافة المصروف ----------------
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _descCtrl,
                    decoration:  InputDecoration(
                      labelText: 'وصف المصروف'.tr(),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'أدخل الوصف'.tr() : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:  InputDecoration(
                      labelText: 'المبلغ'.tr(),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'أدخل المبلغ'.tr();
                      if (double.tryParse(value) == null)
                        return 'أدخل رقم صحيح'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final desc = _descCtrl.text;
                        final amt = double.parse(_amountCtrl.text);

                        await DBHelper.addAdminExpenseAndDeduct(
                          description: desc,
                          amount: amt,
                        );

                        // إعادة تحميل المصروفات بعد الإضافة
                        _refresh(() {
                          _loadExpenses();
                        });

                        AppToast.show('تم إضافة المصروف وخصم المبلغ'.tr());

                        _descCtrl.clear();
                        _amountCtrl.clear();
                      }
                    },
                    child:  Text('حفظ المصروف'.tr()),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // ---------------- ListView عرض المصروفات ----------------
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: {v1}'.tr({'v1': snapshot.error})));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return  Center(child: Text('لا توجد مصروفات'.tr()));
                  }

                  final expenses = snapshot.data!;

                  return ListView.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          title: Text(expense['description']),
                          subtitle: Text(
                              'تمت الإضافة بواسطة: {v1}\nالتاريخ: {v2}'.tr({'v1': expense['added_by'], 'v2': formatDate(expense['date'])})),
                          trailing: Text(
                            '{v1} ج'.tr({'v1': expense['amount'].toStringAsFixed(2)}),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
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

