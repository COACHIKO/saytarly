import 'package:flutter/material.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';

/// The SAYTARLY app mark: a navy tile with an electric-blue "S" signal trace.
///
/// It is drawn in code (not an image) so it stays razor-sharp on every DPI,
/// works in both themes, and can be reused in the sidebar, login panel,
/// activation screens and report headers.
class SaytarlyBrandMark extends StatelessWidget {
  const SaytarlyBrandMark({
    super.key,
    this.size = 40,
    this.showGlow = false,
    this.light = false,
  });

  final double size;

  /// Adds the soft blue glow used on marketing surfaces.
  final bool showGlow;

  /// Light variant for placement on a dark navy tile.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient:
            light
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFEAF3FF)],
                )
                : SaytarlyGradients.brandMark,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              light
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow:
            showGlow
                ? [
                  ...SaytarlyShadows.blueGlow,
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: CustomPaint(painter: _SaytarlyMonogramPainter(light: light)),
      ),
    );
  }
}

class _SaytarlyMonogramPainter extends CustomPainter {
  const _SaytarlyMonogramPainter({required this.light});

  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.115
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                light
                    ? const [SaytarlyColors.deepNavy, Color(0xFF123A69)]
                    : const [Color(0xFFF8FBFF), Color(0xFFBBD9FF)],
          ).createShader(rect);

    final s =
        Path()
          ..moveTo(w * 0.755, h * 0.245)
          ..cubicTo(
            w * 0.665,
            h * 0.115,
            w * 0.335,
            h * 0.100,
            w * 0.255,
            h * 0.305,
          )
          ..cubicTo(
            w * 0.185,
            h * 0.490,
            w * 0.500,
            h * 0.475,
            w * 0.690,
            h * 0.575,
          )
          ..cubicTo(
            w * 0.880,
            h * 0.680,
            w * 0.810,
            h * 0.890,
            w * 0.575,
            h * 0.895,
          )
          ..cubicTo(
            w * 0.430,
            h * 0.900,
            w * 0.320,
            h * 0.815,
            w * 0.275,
            h * 0.690,
          );
    canvas.drawPath(s, stroke);

    // Electric-blue signal node at the start of the trace.
    final node =
        Paint()
          ..style = PaintingStyle.fill
          ..color =
              light ? SaytarlyColors.controlBlue : const Color(0xFF2E8BFF);
    canvas.drawCircle(Offset(w * 0.755, h * 0.245), w * 0.095, node);

    // Inner white spark keeps the node legible at small sizes.
    final spark =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(Offset(w * 0.755, h * 0.245), w * 0.038, spark);

    // A subtle base signal tick — the "control" in SAYTARLY.
    final tick =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.075
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF2E8BFF).withValues(alpha: 0.85);
    canvas.drawLine(
      Offset(w * 0.805, h * 0.815),
      Offset(w * 0.930, h * 0.815),
      tick,
    );
  }

  @override
  bool shouldRepaint(covariant _SaytarlyMonogramPainter oldDelegate) =>
      oldDelegate.light != light;
}

/// Brand lockup: mark + SAYTARLY wordmark + optional descriptor.
///
/// Always LTR: the wordmark is a logo, not translatable UI copy.
class SaytarlyLogo extends StatelessWidget {
  const SaytarlyLogo({
    super.key,
    this.markSize = 40,
    this.onDark = false,
    this.compact = false,
    this.showTagline = true,
    this.showGlow = false,
  });

  final double markSize;
  final bool onDark;
  final bool compact;
  final bool showTagline;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final wordColor = onDark ? Colors.white : SaytarlyColors.deepNavy;
    final taglineColor =
        onDark ? const Color(0xFF9FB0C7) : SaytarlyColors.textSecondary;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SaytarlyBrandMark(size: markSize, showGlow: showGlow, light: false),
          if (!compact) ...[
            SizedBox(width: markSize * 0.30),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAYTARLY',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: markSize * 0.43,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: markSize * 0.035,
                    color: wordColor,
                  ),
                ),
                if (showTagline) ...[
                  const SizedBox(height: 4),
                  Text(
                    'RESTAURANT & CAFÉ MANAGEMENT',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: markSize * 0.205,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: markSize * 0.018,
                      color: taglineColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
