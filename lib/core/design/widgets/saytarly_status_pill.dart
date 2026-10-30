import 'package:flutter/material.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';

/// Semantic tone used by status pills across orders, stock and payments.
enum SaytarlyStatusTone { neutral, info, success, warning, danger, profit }

/// A compact status pill with a tone dot and optional icon.
///
/// The colour only appears when the status has meaning, keeping data-heavy
/// screens calm while still making exceptions obvious.
class SaytarlyStatusPill extends StatelessWidget {
  const SaytarlyStatusPill({
    super.key,
    required this.label,
    this.tone = SaytarlyStatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final SaytarlyStatusTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.saytarly;
    final color = switch (tone) {
      SaytarlyStatusTone.neutral => t.textSecondary,
      SaytarlyStatusTone.info => t.info,
      SaytarlyStatusTone.success => t.success,
      SaytarlyStatusTone.warning => t.warning,
      SaytarlyStatusTone.danger => t.danger,
      SaytarlyStatusTone.profit => t.profit,
    };
    final fg = t.onTint(color);

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: t.tint(color, light: 0.09, dark: 0.18),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 11 : 13, color: fg),
              SizedBox(width: dense ? 4 : 5),
            ] else ...[
              Container(
                width: dense ? 5 : 6,
                height: dense ? 5 : 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: dense ? 5 : 6),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 10.5 : 11.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
