import 'package:flutter/material.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';

/// ديالوج واحد لاختيار عميل أو إضافة عميل جديد — بيتستخدم في كل شاشات
/// الدفع الآجل (الترابيزات، البلايستيشن، التيك أواي، الشحن).
///
/// المشاكل اللي بيحلها:
///  * كان بيقرأ أسماء العملاء من جدول الديون بس، فالعملاء المسجّلين
///    (أو اللي ليهم فواتير) ما كانوش بيظهروا.
///  * كان فيه خانتين (عميل جديد + بحث) واللي بيتكتب في خانة البحث
///    كان ممكن ما يتسجلش خالص لو ما اخترتش من الاقتراحات —
///    دلوقتي اللي مكتوب في الخانة هو اللي بيتحفظ.
///  * العميل الجديد بيتسجل في جدول العملاء، فيظهر تاني المرة الجاية.
Future<String?> showCustomerPickerDialog(
  BuildContext context, {
  String title = 'تسجيل الدين',
  String? initialName,
}) async {
  final customers = await DBHelper.getAllCustomerNames();
  if (!context.mounted) return null;

  return showDialog<String>(
    context: context,
    builder:
        (_) => CustomerPickerDialog(
          title: title,
          customers: customers,
          initialName: initialName,
        ),
  );
}

class CustomerPickerDialog extends StatefulWidget {
  const CustomerPickerDialog({
    super.key,
    required this.title,
    required this.customers,
    this.initialName,
  });

  final String title;
  final List<String> customers;
  final String? initialName;

  @override
  State<CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<CustomerPickerDialog> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _query = _controller.text.trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _query.toLowerCase();
    if (q.isEmpty) return widget.customers;
    return widget.customers
        .where((name) => name.toLowerCase().contains(q))
        .toList();
  }

  void _select(String name) {
    setState(() {
      _controller.text = name;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: name.length),
      );
      _query = name;
    });
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await DBHelper.addCustomer(name);
    if (!mounted) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final canSave = _controller.text.trim().isNotEmpty;

    return AppDialog(
      title: Text(widget.title.tr()),
      icon: Icons.person_search_outlined,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() => _query = value.trim()),
              onSubmitted: (_) {
                if (_controller.text.trim().isNotEmpty) _save();
              },
              decoration: InputDecoration(
                labelText: 'اسم العميل'.tr(),
                hintText: 'اكتب اسم عميل جديد أو اختر من القائمة'.tr(),
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            if (widget.customers.isEmpty)
              Text(
                'مفيش عملاء مسجلين — اكتب اسم العميل الجديد فوق.'
                    .tr(),
                style: theme.textTheme.bodySmall,
              )
            else ...[
              Text(
                'العملاء المسجلين'.tr(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child:
                    filtered.isEmpty
                        ? Text(
                          'مفيش عميل بالاسم ده — هيتحفظ كعميل جديد.'.tr(),
                          style: theme.textTheme.bodySmall,
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final name = filtered[index];
                            final selected =
                                _controller.text.trim().toLowerCase() ==
                                name.toLowerCase();
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              leading: Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.person_outline,
                                color:
                                    selected
                                        ? theme.colorScheme.primary
                                        : null,
                                size: 20,
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight:
                                      selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                ),
                              ),
                              onTap: () => _select(name),
                            );
                          },
                        ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء'.tr()),
        ),
        ElevatedButton(
          onPressed: canSave ? _save : null,
          child: Text('حفظ'.tr()),
        ),
      ],
    );
  }
}
