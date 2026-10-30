import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saytarly/core/design/saytarly_brand.dart';

/// A tiny trend sparkline used inside KPI cards.
///
/// Deliberately minimal: no axes, no labels, just the shape of the last few
/// values. It reads as a quiet signal, not another chart to decode.
class SaytarlySparkline extends StatelessWidget {
  const SaytarlySparkline({
    super.key,
    required this.values,
    this.color,
    this.width = 82,
    this.height = 30,
    this.fill = true,
    this.strokeWidth = 2,
  });

  final List<double> values;
  final Color? color;
  final double width;
  final double height;
  final bool fill;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.saytarly;
    final tint = color ?? t.brandBlue;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: tint,
          fill: fill,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.fill,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final bool fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = (max - min).abs() < 0.001 ? 1.0 : max - min;
    final pad = strokeWidth + 1;
    final plotHeight = size.height - pad * 2;
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final normalized = (values[i] - min) / range;
      return Offset(dx * i, pad + plotHeight - normalized * plotHeight);
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final prev = pointAt(i - 1);
      final cur = pointAt(i);
      final midX = (prev.dx + cur.dx) / 2;
      line.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }

    if (fill) {
      final area =
          Path.from(line)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close();
      final fillPaint =
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.01),
              ],
            ).createShader(Offset.zero & size);
      canvas.drawPath(area, fillPaint);
    }

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;
    canvas.drawPath(line, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.fill != fill ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
