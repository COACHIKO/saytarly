import 'package:flutter/material.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';
import 'package:saytarly/core/design/widgets/saytarly_sparkline.dart';
import 'package:saytarly/core/design/widgets/saytarly_status_pill.dart';

/// Premium KPI card used on the dashboard.
///
/// One quiet surface, one strong number, one semantic signal. The icon tint and
/// optional sparkline give context without turning the row into a rainbow.
class SaytarlyMetricCard extends StatefulWidget {
  const SaytarlyMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.trend,
    this.trendTone = SaytarlyStatusTone.success,
    this.hint,
    this.sparkline,
    this.sparklineColor,
    this.onTap,
    this.footnote,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? trend;
  final SaytarlyStatusTone trendTone;
  final String? hint;
  final List<double>? sparkline;
  final Color? sparklineColor;
  final VoidCallback? onTap;
  final Widget? footnote;

  @override
  State<SaytarlyMetricCard> createState() => _SaytarlyMetricCardState();
}

class _SaytarlyMetricCardState extends State<SaytarlyMetricCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.saytarly;
    final theme = Theme.of(context);
    final tint = widget.color ?? t.brandBlue;
    final interactive = widget.onTap != null;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hovering ? t.borderStrong : t.border),
        boxShadow: _hovering ? SaytarlyShadows.cardHover : SaytarlyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: t.tint(tint),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, size: 19, color: t.onTint(tint)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              widget.value,
              maxLines: 1,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: t.textPrimary,
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: 5),
            Text(
              widget.hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: t.textMuted,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.trend != null)
                SaytarlyStatusPill(
                  label: widget.trend!,
                  tone: widget.trendTone,
                  dense: true,
                  icon:
                      widget.trendTone == SaytarlyStatusTone.success
                          ? Icons.trending_up_rounded
                          : widget.trendTone == SaytarlyStatusTone.danger
                          ? Icons.trending_down_rounded
                          : null,
                ),
              if (widget.footnote != null) ...[
                const SizedBox(width: 8),
                Flexible(child: widget.footnote!),
              ],
              const Spacer(),
              if (widget.sparkline != null && widget.sparkline!.length > 1)
                SaytarlySparkline(
                  values: widget.sparkline!,
                  color: widget.sparklineColor ?? tint,
                  width: 72,
                  height: 26,
                  strokeWidth: 1.8,
                ),
            ],
          ),
        ],
      ),
    );

    if (!interactive) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}
