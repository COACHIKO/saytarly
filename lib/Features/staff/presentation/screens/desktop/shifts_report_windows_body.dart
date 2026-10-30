part of '../shifts_report.dart';

/// جسم تقارير الشيفتات — نسخة الويندوز (Windows UI).
///
/// نفس البيانات ونفس الـ state: صف مؤشرات (KPI)، الفلاتر فوق (نفس الـ
/// callbacks)، وكل شيفت في كارت قابل للهوفر بيودّي لنفس الـ bottom sheets
/// الموجودة بالظبط.
extension _ShiftsReportWindowsBody on _ShiftsReportScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: 'تقارير الشيفتات'.tr(),
      subtitle: '{v1} من {v2} شيفت'.tr({
        'v1': shifts.length,
        'v2': _rawShifts.length,
      }),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث البيانات'.tr(),
          onPressed: () => _loadShifts(),
        ),
        DesktopButton.primary(
          label: 'اختر تاريخ'.tr(),
          icon: Icons.calendar_month_outlined,
          onPressed: () => _windowsPickDate(context),
        ),
      ],
      headerBottom: Wrap(
        spacing: DesktopTokens.gapSm,
        runSpacing: DesktopTokens.gapSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DesktopButton.ghost(
            label: 'ملخص اليوم'.tr(),
            icon: Icons.summarize_outlined,
            onPressed: _generateDailySummary,
          ),
          DesktopButton.ghost(
            label: 'عرض الكل'.tr(),
            icon: Icons.list_alt_outlined,
            onPressed: () {
              _refresh(() => _selectedDate = null);
              _loadShifts();
            },
          ),
          if (_selectedDate != null)
            DesktopInfoChip(
              label: 'التاريخ: {v1}'.tr({
                'v1': formatArabicDate(_selectedDate!),
              }),
              icon: Icons.event_outlined,
              color: palette.accentText,
            ),
          if (_design != ReportDesign.classic)
            DesktopInfoChip(
              label: 'شكل الموبايل: {v1}'.tr({'v1': _designLabel(_design)}),
              icon: _designIcon(_design),
              color: palette.textSecondary,
            ),
        ],
      ),
      child:
          _isLoading
              ? const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _windowsStats(context),
                  const SizedBox(height: DesktopTokens.gapLg),
                  DesktopSectionTitle(
                    title: 'الشيفتات'.tr(),
                    count: shifts.length,
                  ),
                  if (shifts.isEmpty)
                    DesktopEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'مفيش بيانات شيفتات'.tr(),
                      message: 'مفيش شيفتات مسجلة في الفترة المحددة'.tr(),
                    )
                  else
                    ...shifts.map((s) => _windowsShiftCard(context, s)),
                  if (_loadedCount < _rawShifts.length)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: DesktopTokens.gapSm,
                        bottom: DesktopTokens.gapLg,
                      ),
                      child: Center(
                        child:
                            _isLoadingMore
                                ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                                : DesktopButton.ghost(
                                  label: 'تحميل المزيد'.tr(),
                                  icon: Icons.expand_more,
                                  onPressed: () => _loadMoreShifts(),
                                ),
                      ),
                    ),
                ],
              ),
    );
  }

  /// اختيار تاريخ للفلترة — نفس منطق الموبايل بالظبط.
  Future<void> _windowsPickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _refresh(() => _selectedDate = picked);
      _loadShifts(date: picked);
    }
  }

  /// مجموع أي حقل رقمي على الشيفتات المعروضة.
  double _windowsSum(String key) {
    return shifts.fold<double>(
      0.0,
      (sum, s) => sum + (((s[key] ?? 0) as num)).toDouble(),
    );
  }

  /// صف المؤشرات (KPI) — كل أرقام الفترة المعروضة في نظرة واحدة.
  Widget _windowsStats(BuildContext context) {
    final palette = DesktopPalette.of(context);

    final paid = _windowsSum('paid');
    final debt = _windowsSum('debt');
    final collected = _windowsSum('debt_collected');
    final expenses = _windowsSum('expenses');
    final vodafone = _windowsSum('vodafone_cash_total');
    final netCash = paid + collected - expenses;

    return DesktopResponsiveGrid(
      minTileWidth: 230,
      maxColumns: 6,
      children: [
        DesktopStatCard(
          label: 'إجمالي المدفوع'.tr(),
          value: '${formatter.format(paid)} ${Money.txt}',
          icon: Icons.check_circle_outline,
          color: palette.success,
          hint: '{v1} شيفت معروض'.tr({'v1': shifts.length}),
        ),
        DesktopStatCard(
          label: 'إجمالي الآجل'.tr(),
          value: '${formatter.format(debt)} ${Money.txt}',
          icon: Icons.account_balance_wallet_outlined,
          color: palette.danger,
          hint: 'اللي لسه على العملاء'.tr(),
        ),
        DesktopStatCard(
          label: 'محصّل من الآجل'.tr(),
          value: '${formatter.format(collected)} ${Money.txt}',
          icon: Icons.price_check,
          color: palette.info,
          hint: '{v1} عملية تحصيل'.tr({
            'v1': _windowsSum('debt_collected_count').toInt(),
          }),
        ),
        DesktopStatCard(
          label: 'المصروفات'.tr(),
          value: '${formatter.format(expenses)} ${Money.txt}',
          icon: Icons.money_off_outlined,
          color: palette.warning,
          hint: 'مصروفات الشيفتات'.tr(),
        ),
        DesktopStatCard(
          label: 'فودافون كاش'.tr(),
          value: '${formatter.format(vodafone)} ${Money.txt}',
          icon: Icons.phone_android_outlined,
          color: palette.accent,
          hint: 'معلومة فقط'.tr(),
        ),
        DesktopStatCard(
          label: 'صافي الكاش'.tr(),
          value: '${formatter.format(netCash)} ${Money.txt}',
          icon: Icons.savings_outlined,
          color: netCash >= 0 ? palette.success : palette.danger,
          hint: 'المدفوع + المحصّل - المصروفات'.tr(),
        ),
      ],
    );
  }

  /// كارت شيفت واحد — سطر ملخص + مؤشرات صغيرة + أزرار تفاصيل بنفس
  /// الـ sheets القديمة + زرار مسح بيانات الشيفت.
  Widget _windowsShiftCard(BuildContext context, Map<String, dynamic> s) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    final bool isSummary = s['check_in'] == null;

    final debtDetails =
        ((s['debt_collected_details'] as List?)
            ?.cast<Map<String, dynamic>>()) ??
        [];
    final paidInvoiceDetails =
        ((s['paid_details'] as List?)?.cast<Map<String, dynamic>>()) ?? [];
    final debtInvoiceDetails =
        ((s['debt_details'] as List?)?.cast<Map<String, dynamic>>()) ?? [];
    final salesDetailsList =
        ((s['sales_details'] as List?)?.cast<Map<String, dynamic>>()) ?? [];
    final expensesDetailsList =
        ((s['expenses_details'] as List?)?.cast<Map<String, dynamic>>()) ?? [];
    final vodafoneNotes =
        ((s['vodafone_cash_notes'] as List?)?.cast<Map<String, dynamic>>()) ??
        [];

    final paid = ((s['paid'] ?? 0) as num).toDouble();
    final debt = ((s['debt'] ?? 0) as num).toDouble();
    final collected = ((s['debt_collected'] ?? 0) as num).toDouble();
    final expenses = ((s['expenses'] ?? 0) as num).toDouble();
    final totalSalesWithCharge =
        ((s['total_sales'] ?? 0) as num).toDouble() +
        ((s['charge_in'] ?? 0) as num).toDouble() -
        expenses;
    final paidPlusCollected = paid + collected;
    final paidPlusCollectedCash = paidPlusCollected - expenses;
    final discount = (s['debt_collected_discount'] ?? 0) as num;
    final collectedCount = (s['debt_collected_count'] ?? 0) as num;

    final deleteButton = DesktopToolbarIconButton(
      icon: Icons.delete_outline,
      tooltip: 'مسح بيانات الشيفت'.tr(),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (_) => AppDialog(
                title: Text('تأكيد المسح'.tr()),
                content: Text('هل تريد مسح كل بيانات هذا الشيفت؟'.tr()),
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

        if (!(confirmed ?? false)) return;
        // نفس حماية الموبايل: شيفت من غير ID مينفعش يتمسح.
        if (s['id'] == null) return;

        await DBHelper.clearShiftData(
          s['id'] as int,
          s['staff_name'] as String,
          DateTime.parse(s['check_in']),
          s['check_out'] != null ? DateTime.parse(s['check_out']) : null,
        );
        await _loadShifts();
        AppToast.show('تم مسح بيانات الشيفت بالكامل'.tr());
      },
    );

    return DesktopCard(
      margin: EdgeInsets.only(bottom: DesktopTokens.gapMd),
      padding: EdgeInsets.all(DesktopTokens.gapMd),
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------- رأس الكارت ----------------
          Row(
            children: [
              DesktopIconBadge(
                icon: isSummary ? Icons.groups_outlined : Icons.person_outline,
                color: isSummary ? palette.accent : palette.info,
              ),
              SizedBox(width: DesktopTokens.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s['staff_name']?.toString() ?? 'غير معروف'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      _windowsShiftSubtitle(s, isSummary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSummary)
                DesktopInfoChip(
                  label: 'ملخص يومي'.tr(),
                  icon: Icons.summarize_outlined,
                  color: palette.accentText,
                )
              else
                DesktopInfoChip(
                  label:
                      s['check_out'] == null
                          ? 'شيفت مفتوح'.tr()
                          : 'شيفت مقفول'.tr(),
                  icon:
                      s['check_out'] == null
                          ? Icons.play_circle_outline
                          : Icons.task_alt,
                  color:
                      s['check_out'] == null
                          ? palette.warning
                          : palette.success,
                ),
              const SizedBox(width: DesktopTokens.gapSm),
              deleteButton,
            ],
          ),
          Divider(height: DesktopTokens.gapLg, color: palette.border),

          // ---------------- المؤشرات ----------------
          DesktopResponsiveGrid(
            minTileWidth: 180,
            maxColumns: 6,
            spacing: DesktopTokens.gapSm,
            children: [
              DesktopMiniStat(
                label: 'المدفوع'.tr(),
                value: formatter.format(paid),
                icon: Icons.check_circle_outline,
                color: palette.success,
              ),
              DesktopMiniStat(
                label: 'الآجل'.tr(),
                value: formatter.format(debt),
                icon: Icons.schedule_outlined,
                color: palette.danger,
              ),
              DesktopMiniStat(
                label: 'محصّل من الآجل'.tr(),
                value: formatter.format(collected),
                icon: Icons.price_check,
                color: palette.info,
              ),
              DesktopMiniStat(
                label: 'المصروفات'.tr(),
                value: formatter.format(expenses),
                icon: Icons.money_off_outlined,
                color: palette.warning,
              ),
              DesktopMiniStat(
                label: 'فودافون كاش'.tr(),
                value: formatter.format(
                  ((s['vodafone_cash_total'] ?? 0) as num).toDouble(),
                ),
                icon: Icons.phone_android_outlined,
                color: palette.accent,
              ),
              if (!isSummary)
                DesktopMiniStat(
                  label: 'إجمالي المبيعات'.tr(),
                  value: formatter.format(totalSalesWithCharge),
                  icon: Icons.point_of_sale_outlined,
                  color: palette.info,
                ),
            ],
          ),

          if (isSummary || collectedCount > 0) ...[
            const SizedBox(height: DesktopTokens.gapSm + 2),
            Wrap(
              spacing: DesktopTokens.gapSm,
              runSpacing: DesktopTokens.gapSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DesktopInfoChip(
                  label: 'المدفوع + المحصّل: {v1} {v2}'.tr({
                    'v1': formatter.format(paidPlusCollected),
                    'v2': Money.txt,
                  }),
                  icon: Icons.emoji_events_outlined,
                  color: palette.accentText,
                ),
                if (collectedCount > 0)
                  DesktopInfoChip(
                    label:
                        ('{collectedCount} عملية تحصيل'.tr({
                              'collectedCount': collectedCount,
                            }) +
                            '{v1}'.tr({
                              'v1':
                                  discount > 0
                                      ? ' • خصم {v1}'.tr({
                                        'v1': formatter.format(discount),
                                      })
                                      : '',
                            })),
                    icon: Icons.check_circle_outline,
                    color: palette.info,
                  ),
                if (isSummary)
                  DesktopInfoChip(
                    label: '{v1} ساعة • {v2} شيفت'.tr({
                      'v1': ((s['total_hours'] ?? 0) as num).toStringAsFixed(2),
                      'v2': s['count'],
                    }),
                    icon: Icons.access_time,
                    color: palette.textSecondary,
                  ),
                if (!isSummary)
                  DesktopInfoChip(
                    label: 'صافي الكاش: {v1} {v2}'.tr({
                      'v1': formatter.format(paidPlusCollectedCash),
                      'v2': Money.txt,
                    }),
                    icon: Icons.savings_outlined,
                    color:
                        paidPlusCollectedCash >= 0
                            ? palette.success
                            : palette.danger,
                  ),
              ],
            ),
          ],

          const SizedBox(height: DesktopTokens.gapSm + 2),
          Divider(height: DesktopTokens.gapSm, color: palette.border),
          const SizedBox(height: DesktopTokens.gapSm),

          // ---------------- أزرار التفاصيل (نفس الـ sheets القديمة) ----------------
          Wrap(
            spacing: DesktopTokens.gapSm,
            runSpacing: DesktopTokens.gapSm,
            children: [
              DesktopButton.ghost(
                label: 'تفاصيل المدفوع'.tr(),
                icon: Icons.check_circle_outline,
                color: palette.success,
                onPressed:
                    () => _showDetailsSheet(
                      title: 'تفاصيل المدفوع'.tr(),
                      items: paidInvoiceDetails,
                      nameOf:
                          (m) =>
                              (m['customer_name'] ?? 'غير معروف'.tr())
                                  .toString(),
                      subtitleOf: (m) => _orderSubtitle(m),
                      amountOf: (m) => ((m['amount'] ?? 0) as num).toDouble(),
                      color: Colors.green[700]!,
                      icon: Icons.check_circle_outline,
                    ),
              ),
              DesktopButton.ghost(
                label: 'تفاصيل الآجل'.tr(),
                icon: Icons.account_balance_wallet_outlined,
                color: palette.danger,
                onPressed:
                    () => _showDetailsSheet(
                      title: 'تفاصيل الآجل'.tr(),
                      items: debtInvoiceDetails,
                      nameOf:
                          (m) =>
                              (m['customer_name'] ?? 'غير معروف'.tr())
                                  .toString(),
                      subtitleOf: (m) => _orderSubtitle(m),
                      amountOf: (m) => ((m['amount'] ?? 0) as num).toDouble(),
                      color: Colors.red[700]!,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
              ),
              DesktopButton.ghost(
                label: 'محصّل من الآجل'.tr(),
                icon: Icons.price_check,
                color: palette.info,
                onPressed: () => _showDebtCollectedDetails(debtDetails),
              ),
              DesktopButton.ghost(
                label: 'تفاصيل المصروفات'.tr(),
                icon: Icons.money_off_outlined,
                color: palette.warning,
                onPressed:
                    () => _showDetailsSheet(
                      title: 'تفاصيل المصروفات'.tr(),
                      items: expensesDetailsList,
                      nameOf:
                          (m) => (m['description'] ?? 'مصروف'.tr()).toString(),
                      subtitleOf:
                          (m) => 'بواسطة: {v1} - {v2}'.tr({
                            'v1': m['added_by'] ?? '-',
                            'v2': _formatDateSafe(m['date']),
                          }),
                      amountOf: (m) => ((m['amount'] ?? 0) as num).toDouble(),
                      color: Colors.orange[800]!,
                      icon: Icons.money_off,
                    ),
              ),
              DesktopButton.ghost(
                label: 'تفاصيل فودافون كاش'.tr(),
                icon: Icons.phone_android_outlined,
                color: palette.accent,
                onPressed:
                    () => _showDetailsSheet(
                      title: 'تفاصيل فودافون كاش'.tr(),
                      items: vodafoneNotes,
                      nameOf:
                          (m) =>
                              (m['note'] as String?)?.trim().isNotEmpty == true
                                  ? m['note']
                                  : 'فودافون كاش',
                      subtitleOf:
                          (m) => 'بواسطة: {v1} - {v2}'.tr({
                            'v1': m['added_by'] ?? '-',
                            'v2': _formatDateSafe(m['created_at']),
                          }),
                      amountOf: (m) => ((m['amount'] ?? 0) as num).toDouble(),
                      color: Colors.pink[700]!,
                      icon: Icons.phone_android,
                    ),
              ),
              if (!isSummary)
                DesktopButton.ghost(
                  label: 'تفاصيل إجمالي المبيعات'.tr(),
                  icon: Icons.point_of_sale_outlined,
                  color: palette.info,
                  onPressed:
                      () => _showDetailsSheet(
                        title: 'تفاصيل إجمالي المبيعات'.tr(),
                        items: salesDetailsList,
                        nameOf:
                            (m) =>
                                (m['customer_name'] ?? 'غير معروف'.tr())
                                    .toString(),
                        subtitleOf:
                            (m) => _orderSubtitle(
                              m,
                              notePrefix: (m['note'] ?? '').toString(),
                            ),
                        amountOf: (m) => ((m['amount'] ?? 0) as num).toDouble(),
                        color: Colors.blue[700]!,
                        icon: Icons.point_of_sale,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// السطر الصغير تحت اسم الموظف (تواريخ الشيفت أو ملخص اليوم).
  String _windowsShiftSubtitle(Map<String, dynamic> s, bool isSummary) {
    if (isSummary) {
      return 'ملخص يومي — {v1} شيفت'.tr({'v1': s['count']});
    }
    final parts = <String>[];
    if (s['shift_date'] != null) {
      parts.add('📅 ${formatArabicDate(DateTime.parse(s['shift_date']))}');
    }
    if (s['check_in'] != null) {
      parts.add(
        '🕐 بدأ: {v1}'.tr({
          'v1': formatArabicDate(DateTime.parse(s['check_in'])),
        }),
      );
    }
    if (s['check_out'] != null) {
      parts.add(
        '🕓 انتهى: {v1}'.tr({
          'v1': formatArabicDate(DateTime.parse(s['check_out'])),
        }),
      );
    }
    parts.add(
      '⏱️ {v1} ساعة'.tr({'v1': s['total_hours']?.toStringAsFixed(2) ?? 0}),
    );
    return parts.join('  |  ');
  }
}
