import 'package:flutter/material.dart';

/// شبكة متجاوبة لواجهة سطح المكتب — تحسب عدد الأعمدة حسب عرض المكان
/// المتاح، وبتوزّع العناصر بعرض متناسق حتى لو ارتفاعاتها مختلفة.
class DesktopResponsiveGrid extends StatelessWidget {
  const DesktopResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 260,
    this.maxColumns = 6,
    this.spacing = 14,
  });

  final List<Widget> children;

  /// أقل عرض مناسب للعنصر الواحد.
  final double minTileWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            ((width + spacing) / (minTileWidth + spacing)).floor().clamp(1, maxColumns);
        final tileWidth = (width - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
