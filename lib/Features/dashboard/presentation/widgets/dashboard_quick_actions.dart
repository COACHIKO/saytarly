import 'package:flutter/material.dart';

import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/Features/dashboard/presentation/models/dashboard_models.dart';

/// Curated daily actions shown above the full module directory.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key, required this.actions});

  final List<DashboardQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopSectionTitle(
          title: 'وصول سريع'.tr(),
          subtitle: 'المهام اليومية في نقرة واحدة'.tr(),
          padding: const EdgeInsets.only(bottom: DesktopTokens.gapMd),
        ),
        DesktopResponsiveGrid(
          minTileWidth: 250,
          maxColumns: 3,
          spacing: 12,
          children: [
            for (final action in actions)
              DesktopActionTile(
                title: action.label,
                subtitle: action.subtitle,
                icon: action.icon,
                color: action.color,
                onTap: action.onTap,
                compact: true,
              ),
          ],
        ),
      ],
    );
  }
}
