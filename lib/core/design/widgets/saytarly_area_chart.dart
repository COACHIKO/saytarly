import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';
import 'package:saytarly/core/localization/messages.dart';

/// One point in a [SaytarlyAreaChart].
@immutable
class SaytarlyChartPoint {
  const SaytarlyChartPoint({
    required this.label,
    required this.value,
    this.tooltipLabel,
  });

  /// Short label shown on the X axis (e.g. weekday).
  final String label;

  /// Numeric value.
  final double value;

  /// Optional richer label for the hover tooltip.
  final String? tooltipLabel;
}

/// Interactive area chart with restrained grid lines, smooth curve and a
/// hover tooltip. Built in-house so the app stays dependency-light and the
/// chart inherits the exact SAYTARLY tokens.
class SaytarlyAreaChart extends StatefulWidget {
  const SaytarlyAreaChart({
    super.key,
    required this.points,
    this.height = 260,
    this.color,
    this.valueFormatter,
    this.tooltipValueFormatter,
    this.emptyLabel,
    this.showDots,
  });

  final List<SaytarlyChartPoint> points;
  final double height;
  final Color? color;
  final String Function(double value)? valueFormatter;
  final String Function(double value)? tooltipValueFormatter;
  final String? emptyLabel;
  final bool? showDots;

  @override
  State<SaytarlyAreaChart> createState() => _SaytarlyAreaChartState();
}

class _SaytarlyAreaChartState extends State<SaytarlyAreaChart> {
  static const double _leftGutter = 46;
  static const double _rightGutter = 10;
  static const double _topGutter = 12;
  static const double _bottomGutter = 28;

  int? _hoverIndex;

  Rect _plotRect(Size size) {
    return Rect.fromLTRB(
      _leftGutter,
      _topGutter,
      math.max(_leftGutter + 1, size.width - _rightGutter),
      math.max(_topGutter + 1, size.height - _bottomGutter),
    );
  }

  void _onHover(Offset localPosition, Size size) {
    if (widget.points.length < 2) return;
    final plot = _plotRect(size);
    if (!plot.inflate(16).contains(localPosition)) {
      if (_hoverIndex != null) setState(() => _hoverIndex = null);
      return;
    }
    final normalized = ((localPosition.dx - plot.left) / plot.width).clamp(
      0.0,
      1.0,
    );
    final index = (normalized * (widget.points.length - 1)).round();
    if (index != _hoverIndex) setState(() => _hoverIndex = index);
  }

  String _formatCompact(double value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      final v = value / 1000000;
      return '${v.toStringAsFixed(abs >= 10000000 ? 0 : 1)}M';
    }
    if (abs >= 1000) {
      final v = value / 1000;
      return '${v.toStringAsFixed(abs >= 10000 ? 0 : 1)}K';
    }
    return value.toStringAsFixed(abs >= 100 ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.saytarly;
    final chartColor = widget.color ?? t.brandBlue;
    final hasData = widget.points.any((p) => p.value.abs() > 0.0001);
    final emptyLabel = widget.emptyLabel ?? 'لا توجد بيانات بعد'.tr();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final size = Size(width, widget.height);
        final hover = _hoverIndex;

        return MouseRegion(
          onHover: (event) => _onHover(event.localPosition, size),
          onExit: (_) {
            if (_hoverIndex != null) setState(() => _hoverIndex = null);
          },
          child: SizedBox(
            width: width,
            height: widget.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, _) {
                      return CustomPaint(
                        painter: _AreaChartPainter(
                          points: widget.points,
                          progress: progress,
                          color: chartColor,
                          surface: t.surface,
                          border: t.border,
                          textMuted: t.textMuted,
                          hoverIndex: hover,
                          formatCompact: _formatCompact,
                          fontFamily:
                              Theme.of(
                                context,
                              ).textTheme.bodyMedium?.fontFamily,
                        ),
                      );
                    },
                  ),
                ),
                if (!hasData)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: t.surfaceSoft.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: t.border),
                          ),
                          child: Text(
                            emptyLabel,
                            style: TextStyle(
                              color: t.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hover != null && widget.points.length > 1)
                  _tooltip(context, size, hover, chartColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tooltip(BuildContext context, Size size, int index, Color color) {
    final t = context.saytarly;
    final point = widget.points[index];
    final plot = _plotRect(size);
    final maxValue = widget.points.fold<double>(
      0,
      (max, p) => math.max(max, p.value),
    );
    final axisMax = _niceCeil(maxValue * 1.08);
    final normalized = axisMax <= 0 ? 0.0 : point.value / axisMax;
    final x = plot.left + (index / (widget.points.length - 1)) * plot.width;
    final y = plot.bottom - normalized.clamp(0.0, 1.0) * plot.height;
    final value =
        widget.tooltipValueFormatter != null
            ? widget.tooltipValueFormatter!(point.value)
            : widget.valueFormatter != null
            ? widget.valueFormatter!(point.value)
            : _formatCompact(point.value);
    final label = point.tooltipLabel ?? point.label;

    const tooltipWidth = 138.0;
    final left =
        (x - tooltipWidth / 2)
            .clamp(0.0, math.max(0.0, size.width - tooltipWidth))
            .toDouble();
    final top = math.max(0.0, y - 58);

    return Positioned(
      left: left,
      top: top,
      width: tooltipWidth,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tooltipWidth,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    t.isDark
                        ? const Color(0xFF15243A)
                        : SaytarlyColors.deepNavy,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: SaytarlyShadows.floating,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(10, 5),
              painter: _TooltipTailPainter(
                color:
                    t.isDark
                        ? const Color(0xFF15243A)
                        : SaytarlyColors.deepNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _niceCeil(double value) {
    if (value <= 0) return 100;
    final magnitude =
        math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    final normalized = value / magnitude;
    final nice =
        normalized <= 1
            ? 1.0
            : normalized <= 1.5
            ? 1.5
            : normalized <= 2
            ? 2.0
            : normalized <= 2.5
            ? 2.5
            : normalized <= 3
            ? 3.0
            : normalized <= 4
            ? 4.0
            : normalized <= 5
            ? 5.0
            : 10.0;
    return nice * magnitude;
  }
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({
    required this.points,
    required this.progress,
    required this.color,
    required this.surface,
    required this.border,
    required this.textMuted,
    required this.hoverIndex,
    required this.formatCompact,
    required this.fontFamily,
  });

  final List<SaytarlyChartPoint> points;
  final double progress;
  final Color color;
  final Color surface;
  final Color border;
  final Color textMuted;
  final int? hoverIndex;
  final String Function(double value) formatCompact;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      46,
      12,
      math.max(47, size.width - 10),
      math.max(13, size.height - 28),
    );
    final maxValue = points.fold<double>(0, (max, p) => math.max(max, p.value));
    final axisMax = _SaytarlyAreaChartState._niceCeil(maxValue * 1.08);

    _paintGrid(canvas, plot, axisMax);
    if (points.isEmpty) return;

    final count = points.length;
    final stepX = count > 1 ? plot.width / (count - 1) : 0.0;

    Offset pointAt(int index) {
      final normalized = axisMax <= 0 ? 0.0 : points[index].value / axisMax;
      return Offset(
        plot.left + stepX * index,
        plot.bottom - normalized.clamp(0.0, 1.0) * plot.height,
      );
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < count; i++) {
      final prev = pointAt(i - 1);
      final cur = pointAt(i);
      final midX = (prev.dx + cur.dx) / 2;
      line.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }

    final revealWidth = plot.width * progress.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(plot.left, plot.top, revealWidth, plot.height),
    );

    if (count > 1 && maxValue > 0) {
      final area =
          Path.from(line)
            ..lineTo(pointAt(count - 1).dx, plot.bottom)
            ..lineTo(pointAt(0).dx, plot.bottom)
            ..close();
      final areaPaint =
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.015),
              ],
            ).createShader(plot);
      canvas.drawPath(area, areaPaint);
    }

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;
    canvas.drawPath(line, linePaint);

    final showDots = count <= 12;
    if (showDots) {
      for (var i = 0; i < count; i++) {
        final point = pointAt(i);
        canvas.drawCircle(
          point,
          4.2,
          Paint()
            ..style = PaintingStyle.fill
            ..color = surface,
        );
        canvas.drawCircle(
          point,
          4.2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = color,
        );
      }
    }
    canvas.restore();

    _paintXLabels(canvas, plot, pointAt);

    if (hoverIndex != null && hoverIndex! >= 0 && hoverIndex! < count) {
      final point = pointAt(hoverIndex!);
      final dashed =
          Paint()
            ..color = color.withValues(alpha: 0.32)
            ..strokeWidth = 1;
      _drawDashedLine(
        canvas,
        Offset(point.dx, plot.top),
        Offset(point.dx, plot.bottom),
        dashed,
      );
      canvas.drawCircle(
        point,
        6.5,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        point,
        4.6,
        Paint()
          ..style = PaintingStyle.fill
          ..color = surface,
      );
      canvas.drawCircle(
        point,
        4.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
    }
  }

  void _paintGrid(Canvas canvas, Rect plot, double axisMax) {
    final gridPaint =
        Paint()
          ..color = border.withValues(alpha: 0.85)
          ..strokeWidth = 1;
    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = plot.bottom - plot.height * (i / steps);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final value = axisMax * (i / steps);
      _paintText(
        canvas,
        formatCompact(value),
        Offset(0, y - 7),
        maxWidth: plot.left - 8,
        align: TextAlign.right,
        color: textMuted,
        fontSize: 10.2,
        fontWeight: FontWeight.w500,
      );
    }
  }

  void _paintXLabels(Canvas canvas, Rect plot, Offset Function(int) pointAt) {
    if (points.isEmpty) return;
    final count = points.length;
    final step = count <= 8 ? 1 : (count / 6).ceil();
    for (var i = 0; i < count; i++) {
      if (i != 0 && i != count - 1 && i % step != 0) continue;
      final point = pointAt(i);
      _paintText(
        canvas,
        points[i].label,
        Offset(point.dx - 34, plot.bottom + 8),
        maxWidth: 68,
        align: TextAlign.center,
        color: textMuted,
        fontSize: 10.2,
        fontWeight: FontWeight.w500,
        rtl: true,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required TextAlign align,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    bool rtl = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
        ),
      ),
      maxLines: 1,
      textAlign: align,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final total = (b - a).distance;
    final direction = (b - a) / total;
    var distance = 0.0;
    while (distance < total) {
      final start = a + direction * distance;
      final end = a + direction * math.min(distance + dash, total);
      canvas.drawLine(start, end, paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.surface != surface ||
        oldDelegate.border != border ||
        oldDelegate.textMuted != textMuted ||
        oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.fontFamily != fontFamily;
  }
}

class _TooltipTailPainter extends CustomPainter {
  const _TooltipTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TooltipTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
