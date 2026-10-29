part of '../chargetopup.dart';

/// جسم شاشة شحن الرصيد (كاشير) — نسخة الويندوز (Windows UI).
///
/// مؤشرات (رصيد المكنة / الربح الحالي) + كارت الفورم بمبالغ سريعة —
/// نفس الـ controllers ونفس _record بالظبط.
extension _ChargetopWindowsBody on _CashierScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    // نفس حساب الموبايل للربح الحالي (من الخانتين مباشرة)
    final profit = (double.tryParse(_receivedController.text) ?? 0) -
        (double.tryParse(_costController.text) ?? 0);

    return DesktopPageScaffold(
      title: 'شحن رصيد'.tr(),
      subtitle: 'شيفت رقم {v1} • تسجيل عملية شحن للزبون'.tr({'v1': widget.shiftId}),
      maxWidth: 980,
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: _reload,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات سريعة ====================
          DesktopResponsiveGrid(
            minTileWidth: 240,
            maxColumns: 3,
            children: [
              DesktopStatCard(
                label: 'رصيد المكنة'.tr(),
                value: '$_balance',
                icon: Icons.account_balance_wallet_outlined,
                color: palette.info,
                hint: 'الرصيد الحالي قبل الخصم'.tr(),
              ),
              DesktopStatCard(
                label: 'الربح الحالي'.tr(),
                value: profit.toStringAsFixed(2),
                icon: Icons.monetization_on_outlined,
                color: profit >= 0 ? palette.success : palette.danger,
                hint: 'المستلم - التكلفة'.tr(),
              ),
              DesktopStatCard(
                label: 'عدد العمليات'.tr(),
                value: '${_transactions.length}',
                icon: Icons.receipt_long_outlined,
                color: palette.accent,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== فورم العملية ====================
          DesktopSectionTitle(title: 'عملية شحن جديدة'.tr()),
          DesktopCard(
            padding: const EdgeInsets.all(DesktopTokens.gapLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _windowsField(
                  controller: _costController,
                  label: 'تكلفة العملية (المخصومة من المكنة)'.tr(),
                  icon: Icons.money_off_outlined,
                ),
                const SizedBox(height: DesktopTokens.gapMd),
                _windowsField(
                  controller: _receivedController,
                  label: 'المبلغ المستلم من الزبون'.tr(),
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: DesktopTokens.gapMd),
                Wrap(
                  spacing: DesktopTokens.gapSm,
                  runSpacing: DesktopTokens.gapSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'المستلم سريع:'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final amount in const [10.0, 20.0, 50.0, 100.0, 200.0])
                      _windowsQuickChip(context, amount),
                    DesktopInfoChip(
                      label: 'الربح: {v1} ج'.tr({'v1': profit.toStringAsFixed(2)}),
                      icon: profit >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: profit >= 0 ? palette.success : palette.danger,
                    ),
                  ],
                ),
                 SizedBox(height: DesktopTokens.gapLg),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DesktopButton.primary(
                    label: _loading ? 'جاري التسجيل...'.tr() : 'تسجيل العملية',
                    icon: _loading ? null : Icons.point_of_sale_outlined,
                    onPressed: _loading ? null : _record,
                  ),
                ),
              ],
            ),
          ),

           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== آخر العمليات ====================
          DesktopSectionTitle(
            title: 'آخر العمليات'.tr(),
            count: _transactions.length,
          ),
          if (_transactions.isEmpty)
            DesktopEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد عمليات'.tr(),
              message: 'أي عملية شحن تسجّلها هتظهر هنا فورًا.'.tr(),
            )
          else
            for (final t in _transactions) ...[
              _windowsTransactionRow(context, t),
              const SizedBox(height: DesktopTokens.gapSm + 2),
            ],
        ],
      ),
    );
  }

  /// شيب مبلغ سريع — شكله [DesktopInfoChip] وقابل للضغط، بيكتب المبلغ في
  /// نفس الخانة اللي [_record] بيقرأ منها وبيحدّث الربح الحالي.
  Widget _windowsQuickChip(BuildContext context, double amount) {
    final palette = DesktopPalette.of(context);

    return HoverBuilder(
      builder: (context, hovering) => GestureDetector(
        onTap: () {
          _receivedController.text = amount.toStringAsFixed(0);
          _refresh(() {}); // زي onChanged بتاع الموبايل بالظبط
        },
        child: AnimatedScale(
          duration: DesktopTokens.fast,
          scale: hovering ? 1.05 : 1,
          child: DesktopInfoChip(
            label: '{v1} ج'.tr({'v1': amount.toStringAsFixed(0)}),
            icon: Icons.bolt_outlined,
            color: hovering ? palette.accent : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  /// صف عملية شحن واحدة — نفس بيانات الموبايل بشكل كارت سطح مكتب.
  Widget _windowsTransactionRow(BuildContext context, Map<String, dynamic> t) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final date = DateTime.tryParse('${t['date']}') ?? DateTime.now();

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
                  'التكلفة: {v1} - المستلم: {v2}'.tr({'v1': t['cost'], 'v2': t['received']}),
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
                  'الربح: {v1} • {v2}'.tr({'v1': t['profit'], 'v2': formatArabicDate(date)}),
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
          DesktopInfoChip(
            label: 'ربح: {v1}'.tr({'v1': t['profit']}),
            icon: Icons.trending_up,
            color: palette.success,
            dense: true,
          ),
        ],
      ),
    );
  }

  /// خانة إدخال بشكل سطح المكتب — بنفس ستايل باقي الصفحات، وبتنادي
  /// نفس _refresh اللي الموبايل بيستخدمها لتحديث الربح الحالي.
  Widget _windowsField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final palette = DesktopPalette.of(context);

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _refresh(() {}),
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
      ),
    );
  }
}
