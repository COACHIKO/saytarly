part of '../AddExpenseScreen.dart';

/// جسم شاشة المصروفات (أدمن) — نسخة الويندوز (Windows UI).
///
/// فورم الإضافة جوه DesktopCard بنفس الـ controllers والـ validators،
/// وتحته قائمة المصروفات كصفوف قابلة للهوفر — نفس الـ callbacks بالظبط.
extension _AdminExpensesScreenWindowsBody on _AdminExpensesScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'المصروفات'.tr(),
      subtitle: 'إضافة مصروف ومتابعة مصروفات الفترة'.tr(),
      maxWidth: 820,
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث البيانات'.tr(),
          onPressed: () => _refresh(() {
            _loadExpenses();
          }),
        ),
        DesktopButton.ghost(
          label: 'مسح كل المصروفات'.tr(),
          icon: Icons.delete_forever_outlined,
          color: palette.danger,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== فلتر التاريخ ====================
          Row(
            children: [
              DesktopButton.ghost(
                label: _showAll
                    ? 'اختيار يوم'.tr()
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                icon: Icons.calendar_month_outlined,
                onPressed: _pickDate,
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              DesktopButton.primary(
                label: 'عرض الكل'.tr(),
                icon: Icons.list_alt_outlined,
                onPressed: () {
                  _refresh(() {
                    _showAll = true;
                    _selectedDate = null;
                    _loadExpenses();
                  });
                },
              ),
              const SizedBox(width: DesktopTokens.gapSm),
              DesktopInfoChip(
                label: _showAll
                    ? 'كل المصروفات'.tr()
                    : 'مصروفات يوم ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                icon: _showAll
                    ? Icons.all_inclusive_outlined
                    : Icons.filter_alt_outlined,
                color: palette.info,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg),

          // ==================== فورم الإضافة ====================
          DesktopSectionTitle(title: 'إضافة مصروف'.tr()),
          DesktopCard(
            padding: const EdgeInsets.all(DesktopTokens.gapLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _windowsFormField(
                    controller: _descCtrl,
                    label: 'وصف المصروف'.tr(),
                    icon: Icons.notes_outlined,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'أدخل الوصف'.tr() : null,
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  _windowsFormField(
                    controller: _amountCtrl,
                    label: 'المبلغ'.tr(),
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'أدخل المبلغ'.tr();
                      if (double.tryParse(value) == null) {
                        return 'أدخل رقم صحيح'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: DesktopTokens.gapLg),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: DesktopButton.primary(
                      label: 'حفظ المصروف'.tr(),
                      icon: Icons.save_outlined,
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
                    ),
                  ),
                ],
              ),
            ),
          ),

           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== قائمة المصروفات ====================
          DesktopSectionTitle(title: 'المصروفات المسجّلة'.tr()),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _expensesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(DesktopTokens.gapXl),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(DesktopTokens.gapLg),
                  child: Text(
                    'حدث خطأ: {v1}'.tr({'v1': snapshot.error}),
                    style: TextStyle(color: palette.danger),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return DesktopEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'لا توجد مصروفات'.tr(),
                  message: _showAll
                      ? 'لسه مفيش أي مصروفات مسجّلة.'.tr()
                      : 'مفيش مصروفات في اليوم المختار.',
                );
              }

              final expenses = snapshot.data!;
              final total = expenses.fold<double>(
                0,
                (sum, e) => sum + (((e['amount'] ?? 0) as num).toDouble()),
              );

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DesktopMiniStat(
                          label: 'عدد المصروفات'.tr(),
                          value: '${expenses.length}',
                          icon: Icons.receipt_long_outlined,
                          color: palette.info,
                        ),
                      ),
                      const SizedBox(width: DesktopTokens.gapSm),
                      Expanded(
                        child: DesktopMiniStat(
                          label: 'إجمالي المصروفات'.tr(),
                          value: '{v1} ج'.tr({'v1': total.toStringAsFixed(2)}),
                          icon: Icons.payments_outlined,
                          color: palette.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  for (final expense in expenses) ...[
                    _windowsExpenseRow(context, expense),
                    const SizedBox(height: DesktopTokens.gapSm + 2),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// صف مصروف واحد — نفس بيانات الموبايل بشكل كارت سطح مكتب.
  Widget _windowsExpenseRow(BuildContext context, Map<String, dynamic> exp) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final amount = ((exp['amount'] ?? 0) as num).toDouble();

    return DesktopCard(
      hover: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      child: Row(
        children: [
          DesktopIconBadge(
            icon: Icons.receipt_long_outlined,
            color: palette.danger,
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${exp['description']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تمت الإضافة بواسطة: {v1} • {v2}'.tr({'v1': exp['added_by'], 'v2': formatDate(exp['date'])}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Text(
            '{v1} ج'.tr({'v1': amount.toStringAsFixed(2)}),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.danger,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  /// خانة إدخال بشكل سطح المكتب — بنفس الستايل الموحّد لباقي الصفحات.
  Widget _windowsFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final palette = DesktopPalette.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.textMuted, fontSize: 13.5),
        floatingLabelStyle: TextStyle(color: palette.accentText),
        prefixIcon: Icon(icon, size: 20, color: palette.textMuted),
        filled: true,
        fillColor: palette.surfaceSoft,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
          borderSide: BorderSide(color: palette.danger, width: 1.5),
        ),
      ),
    );
  }
}
