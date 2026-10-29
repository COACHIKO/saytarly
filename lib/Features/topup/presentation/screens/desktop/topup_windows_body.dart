part of '../Topup.dart';

/// جسم شاشة ماكينة الشحن — نسخة الويندوز (Windows UI).
///
/// مؤشرات (KPI) + كارت فلترة واضافة رصيد بمبالغ سريعة، ونفس الميثودس
/// بالظبط (‏_reload / _addBalance / _loadAndApplyFilter / _pick*Date).
extension _TopupWindowsBody on _AdminScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    // نفس قراءات الموبايل من _summary بالحرف
    final totalOps = _summary['total_ops'] ?? 0;
    final totalCost = (_summary['total_received'] ?? 0).toString();
    final totalReceived = (_summary['total_cost'] ?? 0).toString();
    final totalProfit = (_summary['total_profit'] ?? 0).toString();

    return DesktopPageScaffold(
      title: 'ماكينة الشحن'.tr(),
      subtitle: 'رصيد الشحن: {_balance} ج • {v2} عملية ضمن الفلتر'.tr({'_balance': _balance, 'v2': _filteredTransactions.length}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: _reload,
        ),
        DesktopButton.ghost(
          label: 'مسح كل العمليات'.tr(),
          icon: Icons.delete_forever_outlined,
          color: palette.danger,
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AppDialog(
                title:  Text('تأكيد الحذف'.tr()),
                content:  Text('هل أنت متأكد أنك تريد مسح كل العمليات؟'.tr()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child:  Text('إلغاء'.tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child:  Text('تأكيد'.tr()),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await DBHelper.deleteAllTransactions();
              await _reload(); // إعادة تحميل البيانات بعد المسح
              AppToast.show('تم مسح كل العمليات بنجاح'.tr());
            }
          },
        ),
      ],
      headerBottom: Row(
        children: [
          DesktopInfoChip(
            label: _fromDate == null
                ? 'من: البداية'.tr()
                : 'من: ${formatArabicDate(_fromDate!)}',
            icon: Icons.event_outlined,
            color: palette.info,
          ),
           SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label:
                _toDate == null ? 'إلى: النهاية'.tr() : 'إلى: ${formatArabicDate(_toDate!)}',
            icon: Icons.event_available_outlined,
            color: palette.info,
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          DesktopInfoChip(
            label: 'عمليات الفلتر: {v1}'.tr({'v1': _filteredTransactions.length}),
            icon: Icons.filter_alt_outlined,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== مؤشرات سريعة ====================
          DesktopResponsiveGrid(
            minTileWidth: 235,
            maxColumns: 5,
            children: [
              DesktopStatCard(
                label: 'رصيد الشحن'.tr(),
                value: '$_balance',
                icon: Icons.account_balance_wallet_outlined,
                color: palette.info,
                hint: 'الرصيد الحالي للمكنة'.tr(),
              ),
              DesktopStatCard(
                label: 'عمليات الفلتر'.tr(),
                value: '${_filteredTransactions.length}',
                icon: Icons.receipt_long_outlined,
                color: palette.accent,
              ),
              DesktopStatCard(
                label: 'تكلفة الفلتر'.tr(),
                value: _totalCostFiltered.toStringAsFixed(2),
                icon: Icons.money_off_outlined,
                color: palette.warning,
              ),
              DesktopStatCard(
                label: 'مستلم الفلتر'.tr(),
                value: _totalReceivedFiltered.toStringAsFixed(2),
                icon: Icons.payments_outlined,
                color: palette.info,
              ),
              DesktopStatCard(
                label: 'ربح الفلتر'.tr(),
                value: _totalProfitFiltered.toStringAsFixed(2),
                icon: Icons.trending_up,
                color: palette.success,
              ),
            ],
          ),
           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== فلترة + إضافة رصيد ====================
          DesktopCard(
            padding:  EdgeInsets.all(DesktopTokens.gapLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopSectionTitle(title: 'فلترة بالتاريخ'.tr()),
                Row(
                  children: [
                    DesktopButton.ghost(
                      label: _fromDate == null
                          ? 'من تاريخ'.tr()
                          : formatArabicDate(_fromDate!),
                      icon: Icons.event_outlined,
                      onPressed: _pickFromDate,
                    ),
                     SizedBox(width: DesktopTokens.gapSm),
                    DesktopButton.ghost(
                      label: _toDate == null
                          ? 'إلى تاريخ'.tr()
                          : formatArabicDate(_toDate!),
                      icon: Icons.event_available_outlined,
                      onPressed: _pickToDate,
                    ),
                    const SizedBox(width: DesktopTokens.gapSm),
                    DesktopButton.primary(
                      label: 'تطبيق'.tr(),
                      icon: Icons.check_circle_outline,
                      onPressed: _loadAndApplyFilter,
                    ),
                    const SizedBox(width: DesktopTokens.gapSm),
                    DesktopButton.ghost(
                      label: 'مسح الفلتر'.tr(),
                      icon: Icons.filter_alt_off_outlined,
                      onPressed: () {
                        _refresh(() {
                          _fromDate = null;
                          _toDate = null;
                        });
                        _loadAndApplyFilter();
                      },
                    ),
                  ],
                ),
                 SizedBox(height: DesktopTokens.gapLg),
                 Divider(height: 1),
                 SizedBox(height: DesktopTokens.gapLg),
                DesktopSectionTitle(title: 'إضافة رصيد للمكنة'.tr()),
                Row(
                  children: [
                    SizedBox(
                      width: 340,
                      child: TextField(
                        controller: _addController,
                        keyboardType:  TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'أضف رصيد للمكنة'.tr(),
                          hintStyle: TextStyle(
                            color: palette.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.add_card_outlined,
                            size: 20,
                            color: palette.textMuted,
                          ),
                          filled: true,
                          fillColor: palette.surfaceSoft,
                          isDense: true,
                          contentPadding:  EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DesktopTokens.radiusMd),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DesktopTokens.radiusMd),
                            borderSide:
                                BorderSide(color: palette.accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                     SizedBox(width: DesktopTokens.gapSm),
                    DesktopButton.primary(
                      label: 'إضافة'.tr(),
                      icon: Icons.add,
                      onPressed: _addBalance,
                    ),
                  ],
                ),
                 SizedBox(height: DesktopTokens.gapMd),
                Wrap(
                  spacing: DesktopTokens.gapSm,
                  runSpacing: DesktopTokens.gapSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'مبالغ سريعة:'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final amount in const [50.0, 100.0, 200.0, 500.0, 1000.0])
                      _windowsQuickAmountChip(context, amount),
                  ],
                ),
              ],
            ),
          ),

           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== ملخص كُلها (نفس بيانات الموبايل) ====================
          DesktopSectionTitle(title: 'تقارير المكنة'.tr()),
          DesktopCard(
            color: palette.accentSoft,
            borderColor: palette.accent.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(DesktopTokens.gapLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopResponsiveGrid(
                  minTileWidth: 260,
                  maxColumns: 2,
                  children: [
                    DesktopMiniStat(
                      label: 'عدد العمليات (كُلها)'.tr(),
                      value: '$totalOps',
                      icon: Icons.receipt_long_outlined,
                      color: palette.accent,
                    ),
                    DesktopMiniStat(
                      label: 'إجمالي التكلفة (خصم من المكنة)'.tr(),
                      value: totalCost,
                      icon: Icons.money_off_outlined,
                      color: palette.warning,
                    ),
                    DesktopMiniStat(
                      label: 'إجمالي المستلم'.tr(),
                      value: totalReceived,
                      icon: Icons.payments_outlined,
                      color: palette.info,
                    ),
                    DesktopMiniStat(
                      label: 'إجمالي الربح'.tr(),
                      value: totalProfit,
                      icon: Icons.trending_up,
                      color: palette.success,
                    ),
                  ],
                ),
                const SizedBox(height: DesktopTokens.gapMd),
                const Divider(height: 1),
                const SizedBox(height: DesktopTokens.gapSm),
                Text(
                  'ملخص الفلتر:'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: DesktopTokens.gapXs),
                Text(
                  'عدد العمليات (المفلترة): {v1}'.tr({'v1': _filteredTransactions.length}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                Text(
                  'إجمالي التكلفة (المفلترة): {v1}'.tr({'v1': _totalCostFiltered.toStringAsFixed(2)}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                Text(
                  'إجمالي المستلم (المفلترة): {v1}'.tr({'v1': _totalReceivedFiltered.toStringAsFixed(2)}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                Text(
                  'إجمالي الربح (المفلترة): {v1}'.tr({'v1': _totalProfitFiltered.toStringAsFixed(2)}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),

           SizedBox(height: DesktopTokens.gapLg + 4),

          // ==================== كل العمليات ====================
          DesktopSectionTitle(
            title: 'عرض كل العمليات'.tr(),
            count: _filteredTransactions.length,
          ),
          if (_filteredTransactions.isEmpty)
            DesktopEmptyState(
              icon: Icons.inbox_outlined,
              title: 'لا توجد عمليات لعرضها'.tr(),
              message: _fromDate == null && _toDate == null
                  ? 'لسه مفيش عمليات شحن مسجّلة على المكنة.'.tr()
                  : 'مفيش عمليات في الفترة المختارة — جرّب تمسح الفلتر.',
            )
          else
            for (final t in _filteredTransactions) ...[
              _windowsTransactionRow(context, t),
              const SizedBox(height: DesktopTokens.gapSm + 2),
            ],
        ],
      ),
    );
  }

  /// شيب مبلغ سريع — شكله [DesktopInfoChip] وقابل للضغط، وبيستخدم
  /// نفس [_addBalance] بالظبط (بيكتب المبلغ في الخانة وبينادي عليها).
  Widget _windowsQuickAmountChip(BuildContext context, double amount) {
    final palette = DesktopPalette.of(context);

    return HoverBuilder(
      builder: (context, hovering) => GestureDetector(
        onTap: () {
          _addController.text = amount.toStringAsFixed(0);
          _addBalance();
        },
        child: AnimatedScale(
          duration: DesktopTokens.fast,
          scale: hovering ? 1.05 : 1,
          child: DesktopInfoChip(
            label: '{v1} ج'.tr({'v1': amount.toStringAsFixed(0)}),
            icon: Icons.add,
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
    final date = DateTime.tryParse(t['date'].toString()) ?? DateTime.now();

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
            color: palette.info,
          ),
          const SizedBox(width: DesktopTokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'التكلفة: {v1}  المستلم: {v2}'.tr({'v1': t['cost'], 'v2': t['received']}),
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
                  'الربح: {v1} • {v2}'.tr({'v1': t['profit'], 'v2': _formattedDate(date)}),
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
}
