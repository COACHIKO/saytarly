import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop_tokens.dart';
import 'package:saytarly/core/desktop/widgets/desktop_card.dart';
import 'package:saytarly/core/design/widgets/saytarly_sparkline.dart';

/// KPI card used on the cashier and super-admin dashboards.
class DesktopStatCard extends StatelessWidget {
  const DesktopStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.hint,
    this.trend,
    this.trendUp = true,
    this.sparkline,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  /// Small line under the value (e.g. "vs. yesterday").
  final String? hint;

  /// Small delta next to the value (e.g. "+12%").
  final String? trend;
  final bool trendUp;
  final List<double>? sparkline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final tint = color ?? palette.accent;
    final deltaColor = trendUp ? palette.success : palette.danger;

    return DesktopCard(
      hover: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DesktopIconBadge(icon: icon, color: tint, size: 38),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.soft(deltaColor),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: palette.onSoft(deltaColor),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.onSoft(deltaColor),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesktopTokens.gapMd),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 26,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (sparkline != null && sparkline!.length > 1) ...[
                  const SizedBox(width: 8),
                  SaytarlySparkline(
                    values: sparkline!,
                    color: tint,
                    width: 58,
                    height: 22,
                    strokeWidth: 1.7,
                  ),
                ],
              ],
            ),
          ] else if (sparkline != null && sparkline!.length > 1) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SaytarlySparkline(
                values: sparkline!,
                color: tint,
                width: 58,
                height: 22,
                strokeWidth: 1.7,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact inline stat used inside cards.
class DesktopMiniStat extends StatelessWidget {
  const DesktopMiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = DesktopPalette.of(context);
    final theme = Theme.of(context);
    final tint = color ?? palette.accent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.gapMd,
        vertical: DesktopTokens.gapSm + 2,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(DesktopTokens.radiusMd),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.onSoft(tint)),
          const SizedBox(width: DesktopTokens.gapSm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: DesktopTokens.gapSm),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
