import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/audit_log_screen_mobile_body.dart';
part 'desktop/audit_log_screen_windows_body.dart';

// ============================================================
// شاشة سجل التعديلات — بتعرض كل تعديل حصل على الفواتير/الديون
// (تعديل كمية، حذف صنف، إضافة صنف، خصم) مع اسم اللي عدّل والتاريخ.
// ============================================================
class AuditLogScreen extends StatefulWidget {
  // لو اتبعت invoiceId، الشاشة هتعرض سجل الفاتورة دي بس.
  // لو اتسابت فاضية، هتعرض كل السجل.
  final int? invoiceId;
  final String? title;

  const AuditLogScreen({super.key, this.invoiceId, this.title});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> logs = [];
  List<Map<String, dynamic>> filteredLogs = [];
  bool isLoading = true;
  String searchQuery = '';

  // فلترة حسب نوع الإجراء
  String selectedAction = 'الكل'.tr();
  static List<String> get actionFilters => [
    'الكل',
    'تعديل كمية'.tr(),
    'حذف صنف'.tr(),
    'إضافة صنف'.tr(),
    'خصم'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => isLoading = true);

    final data = await DBHelper.getAuditLog(invoiceId: widget.invoiceId);

    setState(() {
      logs = data;
      _applyFilters();
      isLoading = false;
    });
  }

  void _applyFilters() {
    filteredLogs = logs.where((log) {
      final matchesAction =
          selectedAction == 'الكل' || log['action'] == selectedAction;

      final matchesSearch = searchQuery.isEmpty ||
          (log['customer_name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          (log['changed_by'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          (log['details'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      return matchesAction && matchesSearch;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      _applyFilters();
    });
  }

  void _onFilterChanged(String action) {
    setState(() {
      selectedAction = action;
      _applyFilters();
    });
  }

  String _formatDate(String? raw) {
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed == null) return 'غير محدد'.tr();
    return DateFormat('yyyy-MM-dd  •  hh:mm a', 'ar').format(parsed);
  }

  IconData _iconForAction(String? action) {
    switch (action) {
      case 'تعديل كمية':
        return Icons.edit_note;
      case 'حذف صنف':
        return Icons.delete_outline;
      case 'إضافة صنف':
        return Icons.add_circle_outline;
      case 'خصم':
        return Icons.percent;
      default:
        return Icons.history;
    }
  }

  Color _colorForAction(String? action) {
    switch (action) {
      case 'تعديل كمية':
        return Colors.blue;
      case 'حذف صنف':
        return Colors.red;
      case 'إضافة صنف':
        return Colors.green;
      case 'خصم':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

