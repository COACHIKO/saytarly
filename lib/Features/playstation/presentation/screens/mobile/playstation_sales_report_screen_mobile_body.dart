part of '../PlaystationSalesReportScreen.dart';

/// جسم شاشة تقرير مبيعات البلايستيشن — نسخة الموبايل (زي ما كانت بالظبط).
extension _PlaystationSalesReportScreenMobileBody on _PlaystationSalesReportScreenState {

  Widget _buildMobileBody(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color accent = cs.secondary;
    final Color debtColor = cs.error;
    final Color collectedColor = cs.secondary;
    final Color bg = theme.scaffoldBackgroundColor;
    final Color surface = cs.surface;
    final Color surfaceAlt =
        Color.alphaBlend(cs.primary.withOpacity(0.06), surface);
    final Color border = cs.onSurface == Colors.white.withOpacity(0.01)
        ? Colors.black
        : cs.onSurface.withOpacity(0.1);
    final Color textPrimary =
        cs.onSurface == Colors.white70 ? Colors.white : cs.onSurface;
    final Color textSecondary =
        cs.onSurface == Colors.white70 ? Colors.white : cs.onSurface;

    final totalRevenue = _report.fold<double>(
      0,
      (sum, item) => sum + (item['revenue'] as double),
    );
    final totalDiscount = _report.fold<double>(
        0, (sum, item) => sum + (item['discount_amount'] as double));
    final totalDebt = _report.fold<double>(
        0, (sum, item) => sum + (item['debt_revenue'] as double));
    final netCollected =
        totalRevenue - totalDiscount - totalDebt + _debtCollectedInPeriod;
    final activeConsolesCount =
        _report.where((d) => (d['sessions_count'] as int) > 0).length;
    final totalHours = _report.fold<double>(
        0, (sum, item) => sum + (item['hours_played'] as double));
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title:  Text('تقرير مبيعات البلايستيشن'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'طباعة PDF'.tr(),
            onPressed: _isLoading ? null : _printReportPdf,
          ),
          IconButton(
            icon: _isClearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.red),
                  )
                : const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'مسح مبيعات الفترة المعروضة'.tr(),
            onPressed: _isClearing ? null : _clearPeriodSales,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        color: accent,
        backgroundColor: surface,
        child: CustomScrollView(
          slivers: [
            // ---------- شريط الفلاتر ----------
            SliverToBoxAdapter(
              child: Container(
                color: surface,
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                        flex: 4,
                        child: _buildPeriodSelector(
                            cs, surfaceAlt, accent, textSecondary, bg)),
                    const SizedBox(width: 8),
                    Expanded(
                        flex: 5,
                        child: _buildPeriodPicker(
                            surfaceAlt, accent, textPrimary, textSecondary)),
                  ],
                ),
              ),
            ),

            // ---------- شريط الإحصائيات ----------
            SliverToBoxAdapter(
              child: Container(
                color: surface,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _netCard(netCollected, accent, bg, textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        children: [
                          _miniStat(
                              'إيراد'.tr(),
                              totalRevenue,
                              _PlaystationSalesReportScreenState.revenueColor,
                              Icons.payments_rounded,
                              surfaceAlt,
                              textSecondary),
                          const SizedBox(height: 6),
                          _miniStat(
                              'خصم'.tr(),
                              totalDiscount,
                              _PlaystationSalesReportScreenState.discountColor,
                              Icons.discount_rounded,
                              surfaceAlt,
                              textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        children: [
                          _miniStat(
                              'آجل باقي'.tr(),
                              totalDebt,
                              debtColor,
                              Icons.schedule_rounded,
                              surfaceAlt,
                              textSecondary),
                          const SizedBox(height: 6),
                          _miniStat(
                              'اتحصّل فعليًا (كاش)'.tr(),
                              _debtCollectedInPeriod,
                              collectedColor,
                              Icons.account_balance_wallet_rounded,
                              surfaceAlt,
                              textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- بحث ----------
            SliverToBoxAdapter(
              child: Container(
                color: surface,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن جهاز'.tr(),
                            hintStyle:
                                TextStyle(color: textSecondary, fontSize: 13),
                            prefixIcon: Icon(Icons.search,
                                size: 18, color: textSecondary),
                            filled: true,
                            fillColor: surfaceAlt,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) => _refresh(() => _searchQuery = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '{activeConsolesCount} جهاز • {v2}'.tr({'activeConsolesCount': activeConsolesCount, 'v2': _formatHours(totalHours)}),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(height: 1, color: border),
            ),

            // ---------- رأس الجدول ----------
            SliverToBoxAdapter(
              child: Container(
                color: surfaceAlt,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text('الجهاز'.tr(),
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('جلسات'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('ساعات'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('الإيراد'.tr(),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- القائمة ----------
            if (_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              )
            else if (_filteredReport.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(textSecondary),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _itemRow(
                    _filteredReport[i],
                    i.isEven,
                    surface,
                    bg,
                    border,
                    textPrimary,
                    textSecondary,
                    debtColor,
                  ),
                  childCount: _filteredReport.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }

  // ---------------- Period selector ----------------
  Widget _buildPeriodSelector(ColorScheme cs, Color surfaceAlt, Color accent,
      Color textSecondary, Color bg) {
    final options =  [
      ('day', 'يومي'.tr()),
      ('month', 'شهري'.tr()),
      ('shift', 'شيفت'.tr()),
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: surfaceAlt,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: options.map((o) {
          final selected = _periodType == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _refresh(() => _periodType = o.$1);
                _loadReport();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    color: selected ? bg : textSecondary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodPicker(
      Color surfaceAlt, Color accent, Color textPrimary, Color textSecondary) {
    Widget pill(
        {required IconData icon, required String label, VoidCallback? onTap}) {
      return InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: surfaceAlt,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (_periodType) {
      case 'day':
        return pill(
          icon: Icons.calendar_today_rounded,
          label:
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          onTap: _pickDate,
        );
      case 'month':
        return pill(
          icon: Icons.calendar_month_rounded,
          label:
              '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
          onTap: _pickMonth,
        );
      case 'shift':
        if (_shifts.isEmpty) {
          return Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: surfaceAlt,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text('لا توجد شيفتات'.tr(),
                style: TextStyle(color: textSecondary, fontSize: 12)),
          );
        }
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: surfaceAlt,
            borderRadius: BorderRadius.circular(9),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedShiftId,
              dropdownColor: surfaceAlt,
              icon: Icon(Icons.expand_more_rounded, color: accent, size: 18),
              items: _shifts
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text(
                        _shiftLabel(s),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                _refresh(() => _selectedShiftId = v);
                _loadReport();
              },
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------- Net card ----------------
  Widget _netCard(double value, Color accent, Color bg, Color textSecondary) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  size: 14, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'الصافي المتوقع'.tr(),
                  style: TextStyle(fontSize: 14, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(2)} ${Money.txt}',
            style: TextStyle(
              color: accent,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Mini stat ----------------
  Widget _miniStat(String label, double value, Color color, IconData icon,
      Color surfaceAlt, Color textSecondary) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Empty state ----------------
  Widget _emptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_esports_outlined, color: textSecondary, size: 34),
          const SizedBox(height: 8),
          Text('لا توجد جلسات بلايستيشن في هذه الفترة'.tr(),
              style: TextStyle(color: textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }

  // ---------------- Item row ----------------
  Widget _itemRow(
    Map<String, dynamic> item,
    bool isEven,
    Color surface,
    Color bg,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color debtColor,
  ) {
    final sessions = item['sessions_count'] as int;
    final hours = item['hours_played'] as double;
    final revenue = item['revenue'] as double;
    final discountAmount = item['discount_amount'] as double;
    final debtRevenue = item['debt_revenue'] as double;
    final debtCollected = item['debt_collected_revenue'] as double;
    final hasExtra =
        discountAmount > 0 || debtRevenue > 0.01 || debtCollected > 0.01;

    return Container(
      color: isEven ? surface : bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    item['name'] as String,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$sessions',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _PlaystationSalesReportScreenState.revenueColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatHours(hours),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    revenue.toStringAsFixed(2),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasExtra)
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 12, bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (discountAmount > 0)
                    _tag('خصم {v1}'.tr({'v1': discountAmount.toStringAsFixed(2)}),
                        _PlaystationSalesReportScreenState.discountColor),
                  if (debtRevenue > 0.01)
                    _tag('آجل {v1}'.tr({'v1': debtRevenue.toStringAsFixed(2)}), debtColor),
                  if (debtCollected > 0.01)
                    _tag('اتحصّل {v1}'.tr({'v1': debtCollected.toStringAsFixed(2)}),
                        debtColor.withOpacity(0.7)),
                ],
              ),
            ),
          Container(height: 1, color: border),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

