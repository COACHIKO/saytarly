import 'package:flutter/material.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:intl/intl.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/customers_report_screen_mobile_body.dart';
part 'desktop/customers_report_screen_windows_body.dart';

class CustomersReportScreen extends StatefulWidget {
  const CustomersReportScreen({Key? key}) : super(key: key);

  @override
  State<CustomersReportScreen> createState() => _CustomersReportScreenState();
}

class _CustomersReportScreenState extends State<CustomersReportScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;
  String _month = DateFormat('yyyy-MM').format(DateTime.now()); // الشهر الحالي

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    final result = await DBHelper.getMonthlyCustomerTotals(_month);
    if (!mounted) return;
    setState(() {
      _customers = result;
      _loading = false;
    });
  }

  Future<void> _showCustomerInvoices(String name) async {
    final invoices =
        await DBHelper.getCustomerInvoicesWithDetails(name, _month);

    if (!mounted) return; // الشاشة قفلت أثناء التحميل — ما نلمس contextش
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: Text('فواتير {name} في {_month}'.tr({'name': name, '_month': _month})),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: invoices.isEmpty
              ? Center(child: Text('لا توجد فواتير لهذا العميل'.tr()))
              : ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (_, i) {
                    final inv = invoices[i];
                    String formattedDate = '';
                    if (inv['start_time'] != null) {
                      final date = DateTime.parse(inv['start_time']);
                      formattedDate =
                          DateFormat('EEEE، d MMMM yyyy - HH:mm'.tr(), 'ar')
                              .format(date);
                    }

                    final drinks = inv['drinks'] as List<dynamic>? ?? [];
                    final total = (inv['total_cost'] ?? 0).toStringAsFixed(2);
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        title: Text('فاتورة #{v1} - {total} ج'.tr({'v1': inv['id'], 'total': total})),
                        subtitle: Text('التاريخ: {formattedDate}'.tr({'formattedDate': formattedDate})),
                        children: [
                          // 🎮 قسم الجلسة (الجهاز)
                          if (inv['session'] != null &&
                              inv['session']['console_name'] != null &&
                              inv['session']['console_name'] != 'غير معروف' &&
                              (inv['session']['device_cost'] ?? 0) > 0)
                            Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🎮 تفاصيل الجهاز'.tr(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey[800],
                                            fontSize: 15)),
                                    SizedBox(height: 4),
                                    Text('الجهاز: {v1}'.tr({'v1': inv['console_name']})),
                                    Text(
                                        'وقت البدء: {v1}'.tr({'v1': inv['session']['start_time'] ?? ''})),
                                    Text(
                                        'وقت الانتهاء: {v1}'.tr({'v1': inv['session']['end_time'] ?? 'لم ينته بعد'.tr()})),
                                    Text(
                                        'تكلفة الجهاز: {v1} ج'.tr({'v1': inv['session']['device_cost']})),
                                  ],
                                ),
                              ),
                            ),

                          // ☕ قسم المشروبات
                          Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('☕ المشروبات'.tr(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                          fontSize: 15)),
                                  SizedBox(height: 4),
                                  if (drinks.isEmpty)
                                    Text('لا توجد مشروبات'.tr())
                                  else
                                    ...drinks.map((d) {
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                            d['name'] ?? 'مشروب غير معروف'.tr()),
                                        trailing: Text(
                                            '{v1} × {v2} ج'.tr({'v1': d['qty'], 'v2': d['total']})),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCustomer(String? customerName) async {
    if (customerName == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: Text('تأكيد الحذف'.tr()),
        content: Text(
            'هل أنت متأكد من مسح كل فواتير العميل "{customerName}" لهذا الشهر؟'.tr({'customerName': customerName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DBHelper.deleteCustomerInvoices(customerName, _month);
      await _loadCustomers(); // إعادة تحميل البيانات بعد الحذف
    }
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
