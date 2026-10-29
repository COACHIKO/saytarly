part of '../AuditLogScreen.dart';

/// جسم سجل التعديلات — نسخة الموبايل (زي ما كانت بالظبط).
extension _AuditLogScreenMobileBody on _AuditLogScreenState {

  Widget _buildMobileBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'سجل التعديلات'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث'.tr(),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 حقل البحث
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم العميل أو الموظف أو التفاصيل...'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                // 🏷️ فلتر نوع الإجراء
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _AuditLogScreenState.actionFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final action = _AuditLogScreenState.actionFilters[i];
                      final selected = action == selectedAction;
                      return ChoiceChip(
                        label: Text(action),
                        selected: selected,
                        onSelected: (_) => _onFilterChanged(action),
                        selectedColor: cs.primary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: selected ? cs.primary : null,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // 📋 عدد النتائج
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '{v1} تعديل'.tr({'v1': filteredLogs.length}),
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                Expanded(
                  child: filteredLogs.isEmpty
                      ? _emptyState(cs)
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredLogs.length,
                          itemBuilder: (_, i) => _logCard(filteredLogs[i], cs),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off,
              size: 56, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'لا توجد تعديلات مسجلة'.tr(),
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard(Map<String, dynamic> log, ColorScheme cs) {
    final action = (log['action'] ?? '').toString();
    final details = (log['details'] ?? '').toString();
    final customerName = (log['customer_name'] ?? '').toString();
    final changedBy = (log['changed_by'] ?? 'غير معروف'.tr()).toString();
    final changedAt = _formatDate(log['changed_at']?.toString());
    final invoiceId = log['invoice_id'];
    final color = _colorForAction(action);

    return Card(
      margin:  EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.35), width: 1),
      ),
      child: Padding(
        padding:  EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(_iconForAction(action), color: color, size: 18),
                ),
                 SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.isEmpty ? 'تعديل'.tr() : action,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                      if (customerName.isNotEmpty)
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cs.onSurface.withOpacity(0.65),
                          ),
                        ),
                    ],
                  ),
                ),
                if (invoiceId != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'فاتورة #{invoiceId}'.tr({'invoiceId': invoiceId}),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  details,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.85),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: cs.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  changedBy,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time,
                    size: 13, color: cs.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  changedAt,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

