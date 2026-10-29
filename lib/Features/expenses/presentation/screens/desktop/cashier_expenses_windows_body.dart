part of '../cashier_expenses.dart';

/// جسم شاشة مصروفات الكاشير — نسخة الويندوز (Windows UI).
///
/// فورم داخل DesktopCard بنفس الـ controllers والـ validators، وتحته
/// قائمة مصروفات الشيفت كصفوف كروت — نفس _addExpense ونفس DB calls.
extension _CashierExpensesScreenWindowsBody on _CashierExpensesScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'مصروفات الكاشير - {v1}'.tr({'v1': widget.cashierName}),
      subtitle: 'شيفت رقم {v1} • تسجيل مصروفات الوردية'.tr({'v1': widget.shiftId}),
      maxWidth: 820,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== فورم إضافة مصروف ====================
          DesktopSectionTitle(title: 'إضافة مصروف جديد'.tr()),
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
                    validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل الوصف'.tr() : null,
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  _windowsFormField(
                    controller: _amountCtrl,
                    label: 'المبلغ'.tr(),
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل المبلغ'.tr();
                      if (double.tryParse(v) == null) return 'أدخل رقم صحيح'.tr();
                      return null;
                    },
                  ),
                   SizedBox(height: DesktopTokens.gapLg),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: DesktopButton.primary(
                      label: 'إضافة المصروف'.tr(),
                      icon: Icons.add_card_outlined,
                      onPressed: _addExpense,
                    ),
                  ),
                ],
              ),
            ),
          ),

           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== قائمة مصروفات الشيفت ====================
          DesktopSectionTitle(title: 'مصروفات الشيفت'.tr()),
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
                  title: 'لا توجد مصروفات لهذا الشيفت'.tr(),
                  message: 'أي مصروف تسجّله هنا هيتحسب على الشيفت الحالي.'.tr(),
                );
              }

              final expenses = snapshot.data!;
              final total = expenses.fold<double>(
                0,
                (sum, e) =>
                    sum + (double.tryParse('${e['amount']}') ?? 0.0),
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
                          label: 'إجمالي مصروفات الشيفت'.tr(),
                          value: '{v1} ج'.tr({'v1': total.toStringAsFixed(2)}),
                          icon: Icons.payments_outlined,
                          color: palette.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesktopTokens.gapMd),
                  for (final e in expenses) ...[
                    _windowsExpenseRow(context, e),
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
  Widget _windowsExpenseRow(BuildContext context, Map<String, dynamic> e) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

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
            color: palette.accent,
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${e['description']}',
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
                  'التاريخ: {v1}'.tr({'v1': formatDate('${e['date']}')}),
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
            '{v1} ج'.tr({'v1': e['amount']}),
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

  /// خانة إدخال بشكل سطح المكتب — نفس ستايل باقي الصفحات.
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
