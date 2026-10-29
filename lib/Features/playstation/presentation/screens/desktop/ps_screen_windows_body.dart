part of '../PS_Screen.dart';

/// جسم شاشة أجهزة البلايستيشن — نسخة الويندوز (Windows UI).
///
/// شبكة أجهزة متجاوبة بكروت عليها هوفر، حالة كل جهاز (متاح / مشغول /
/// متوقف مؤقتًا) بألوان اللوحة، ونفس زراير الجلسة بالظبط (بدء، مشروبات،
/// إيقاف/استئناف، إنهاء، فاتورة) — نفس الميثودس ونفس المنطق.
extension _PsScreenWindowsBody on _StaffDashboardState {
  Widget _buildWindowsBody(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final activeMap = _activeMap();
    final busyCount = consoles.where((c) => activeMap[c.id] != null).length;

    return DesktopPageScaffold(
      title: 'أجهزة البلايستيشن'.tr(),
      subtitle:
          '{v1} جهاز • {busyCount} مشغول • {v3} متاح'.tr({'v1': consoles.length, 'busyCount': busyCount, 'v3': consoles.length - busyCount}),
      actions: [
        DesktopToolbarIconButton(
          icon: Icons.refresh,
          tooltip: 'تحديث'.tr(),
          onPressed: _load,
        ),
      ],
      child: consoles.isEmpty
          ? DesktopEmptyState(
              icon: Icons.sports_esports_outlined,
              title: 'مفيش أجهزة مضافة'.tr(),
              message:
                  'ضيف أجهزة البلايستيشن من شاشة "إدارة الأجهزة" عشان تبدأ الجلسات.'.tr(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopSectionTitle(title: 'الأجهزة'.tr(), count: consoles.length),
                DesktopResponsiveGrid(
                  minTileWidth: 310,
                  maxColumns: 4,
                  children: [
                    for (final c in consoles)
                      _psConsoleCard(context, palette, c, activeMap[c.id]),
                  ],
                ),
              ],
            ),
    );
  }

  /// كارت الجهاز — نفس معلومات كارت الموبايل بس بشكل سطح مكتب.
  Widget _psConsoleCard(
    BuildContext context,
    DesktopPalette palette,
    ConsoleModel c,
    Map<String, dynamic>? active,
  ) {
    final theme = Theme.of(context);
    final isPaused = active != null && active['paused_at'] != null;
    final isBusy = active != null;

    final statusColor = isPaused
        ? palette.warning
        : (isBusy ? palette.danger : palette.success);
    final statusLabel = isPaused ? 'متوقف مؤقتًا'.tr() : (isBusy ? 'مشغول'.tr() : 'متاح');

    final restBorder = isBusy
        ? palette.accent.withValues(alpha: 0.55)
        : palette.border;

    return HoverBuilder(
      cursor: SystemMouseCursors.basic,
      builder: (context, hovering) => DesktopCard(
        hover: true,
        selected: isBusy,
        borderColor: hovering ? palette.borderStrong : restBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ░░ اسم الجهاز + السعر + الحالة ░░
            Row(
              children: [
                DesktopIconBadge(
                  icon: Icons.sports_esports,
                  color: statusColor,
                  size: 46,
                  radius: DesktopTokens.radiusMd,
                ),
                const SizedBox(width: DesktopTokens.gapMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary,
                          fontSize: 16.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.isFixedPrice
                            ? '{v1} / سعر ماتش'.tr({'v1': c.fixedPrice.toStringAsFixed(2)})
                            : '${c.pricePerHour.toStringAsFixed(2)} / ساعة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesktopTokens.gapSm),
                DesktopInfoChip(
                  label: statusLabel,
                  icon: Icons.circle,
                  color: statusColor,
                ),
              ],
            ),

            // ░░ شارة "متوقف مؤقتًا" ░░
            if (isPaused) ...[
              const SizedBox(height: DesktopTokens.gapMd),
              DesktopInfoChip(
                label: 'الجلسة متوقفة مؤقتًا'.tr(),
                icon: Icons.pause_circle_filled,
                color: palette.warning,
              ),
            ],

            const SizedBox(height: DesktopTokens.gapLg),

            // ░░ الحالة والأزرار ░░
            if (!isBusy)
              SizedBox(
                width: double.infinity,
                child: DesktopButton.primary(
                  label: 'ابدأ جلسة'.tr(),
                  icon: Icons.play_arrow_rounded,
                  color: palette.success,
                  onPressed: () => _startSession(c),
                ),
              )
            else
              Wrap(
                spacing: DesktopTokens.gapSm,
                runSpacing: DesktopTokens.gapSm,
                children: [
                  _psActionBtn(
                    icon: Icons.local_drink_outlined,
                    label: 'مشروبات'.tr(),
                    color: palette.info,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddDrinksScreen(invoiceId: active['id']),
                        ),
                      );
                    },
                  ),

                  // ⏸️ / ▶️ إيقاف واستئناف الوقت — غير متاح للجلسات ذات
                  // السعر الثابت لأن وقتها مش بيتحسب أصلًا.
                  if (!c.isFixedPrice)
                    (!isPaused
                        ? _psActionBtn(
                            icon: Icons.pause_circle_filled,
                            label: 'إيقاف'.tr(),
                            color: palette.warning,
                            onTap: () async {
                              await DBHelper.pauseInvoice(active['id']);
                              await _load();
                            },
                          )
                        : _psActionBtn(
                            icon: Icons.play_circle_fill,
                            label: 'استئناف'.tr(),
                            color: palette.success,
                            onTap: () async {
                              await DBHelper.resumeInvoice(active['id']);
                              await _load();
                            },
                          )),

                  _psActionBtn(
                    icon: Icons.stop_circle_outlined,
                    label: 'إنهاء'.tr(),
                    color: palette.danger,
                    onTap: () => _endSession(active, c),
                  ),
                  _psActionBtn(
                    icon: Icons.receipt_long_outlined,
                    label: 'فاتورة'.tr(),
                    color: palette.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InvoiceScreen(invoiceId: active['id']),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// زر إجراء صغير جوه كارت الجهاز — بهوفر ناعم زي باقي أدوات الويندوز.
  Widget _psActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);

    return HoverBuilder(
      builder: (context, hovering) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DesktopTokens.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: hovering ? palette.soft(color) : palette.surfaceSoft,
            borderRadius: BorderRadius.circular(DesktopTokens.radiusSm),
            border: Border.all(
              color: hovering ? color.withValues(alpha: 0.55) : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: hovering ? color : palette.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
