part of '../AuditLogScreen.dart';

/// جسم شاشة سجل التعديلات — نسخة الويندوز (Windows UI).
///
/// نفس الفلاتر ونفس البحث ونفس الأرقام — بس بشكل سطح مكتب:
/// مؤشرات فوق، فلاتر في الهيدر، وكل تعديل في صف نضيف بالهوفر.
extension _AuditLogScreenWindowsBody on _AuditLogScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);

    return DesktopPageScaffold(
      title: widget.title ?? 'سجل التعديلات'.tr(),
      subtitle: '{v1} من {v2} تعديل'.tr({'v1': filteredLogs.length, 'v2': logs.length}),
      actions: [
        DesktopButton.primary(
          label: 'تحديث'.tr(),
          icon: Icons.refresh,
          onPressed: _loadLogs,
        ),
      ],
      headerBottom: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DesktopTokens.gapMd,
        runSpacing: DesktopTokens.gapSm,
        children: [
          DesktopSearchField(
            hint: 'ابحث باسم العميل أو الموظف أو التفاصيل...'.tr(),
            width: 320,
            onChanged: _onSearchChanged,
          ),
          DesktopSegmented<String>(
            items: [
              for (final action in _AuditLogScreenState.actionFilters)
                DesktopSegmentItem(value: action, label: action),
            ],
            value: selectedAction,
            onChanged: _onFilterChanged,
          ),
        ],
      ),
      child: isLoading
          ?  Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==================== مؤشرات سريعة ====================
                DesktopResponsiveGrid(
                  minTileWidth: 250,
                  maxColumns: 4,
                  children: [
                    DesktopStatCard(
                      label: 'تعديلات معروضة'.tr(),
                      value: '${filteredLogs.length}',
                      icon: Icons.filter_alt_outlined,
                      color: palette.accent,
                      hint: 'بعد فلتر "{selectedAction}" والبحث'.tr({'selectedAction': selectedAction}),
                    ),
                    DesktopStatCard(
                      label: 'إجمالي السجل'.tr(),
                      value: '${logs.length}',
                      icon: Icons.history,
                      color: palette.info,
                      hint: 'كل التعديلات المسجلة'.tr(),
                    ),
                  ],
                ),
                 SizedBox(height: DesktopTokens.gapLg),

                // ==================== القائمة ====================
                DesktopSectionTitle(
                  title: 'التعديلات'.tr(),
                  count: filteredLogs.length,
                ),
                if (filteredLogs.isEmpty)
                   DesktopEmptyState(
                    icon: Icons.history_toggle_off,
                    title: 'لا توجد تعديلات مسجلة'.tr(),
                    message: 'جرّب تغيير نوع الإجراء أو كلمة البحث.'.tr(),
                  )
                else
                  for (final log in filteredLogs) ...[
                    _logRow(log, palette),
                    const SizedBox(height: DesktopTokens.gapSm),
                  ],
              ],
            ),
    );
  }

  /// صف تعديل واحد — نفس بيانات الموبايل (الإجراء + التفاصيل + اللي عدّل والتاريخ).
  Widget _logRow(Map<String, dynamic> log, DesktopPalette palette) {
    final action = (log['action'] ?? '').toString();
    final details = (log['details'] ?? '').toString();
    final customerName = (log['customer_name'] ?? '').toString();
    final changedBy = (log['changed_by'] ?? 'غير معروف'.tr()).toString();
    final changedAt = _formatDate(log['changed_at']?.toString());
    final invoiceId = log['invoice_id'];
    final tint = _colorForAction(action);

    return DesktopCard(
      hover: true,
      padding:  EdgeInsets.all(DesktopTokens.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesktopIconBadge(
                icon: _iconForAction(action),
                color: tint,
                size: 42,
              ),
               SizedBox(width: DesktopTokens.gapSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.isEmpty ? 'تعديل'.tr() : action,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tint,
                        fontSize: 14.5,
                      ),
                    ),
                    if (customerName.isNotEmpty) ...[
                       SizedBox(height: 2),
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (invoiceId != null)
                DesktopInfoChip(
                  label: 'فاتورة #{invoiceId}'.tr({'invoiceId': invoiceId}),
                  icon: Icons.receipt_long_outlined,
                  color: palette.accent,
                  dense: true,
                ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: DesktopTokens.gapSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                details,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: DesktopTokens.gapSm),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: palette.textMuted),
              const SizedBox(width: DesktopTokens.gapXs),
              Text(
                changedBy,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time, size: 13, color: palette.textMuted),
              const SizedBox(width: DesktopTokens.gapXs),
              Text(
                changedAt,
                style: TextStyle(fontSize: 11.5, color: palette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
