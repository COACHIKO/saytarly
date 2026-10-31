import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:saytarly/core/design/saytarly_brand.dart';

/// The SAYTARLY mark — the official `logoSVG.svg` artwork.
///
/// The original SVG is a raster image wrapped in unsupported filters, so its
/// artwork has been traced into a clean vector path (the same shape) for
/// razor-sharp rendering at every DPI without the heavy raster mask.
///
/// The mark is intentionally more than a plain glyph: the S lives inside a
/// deep-navy signal tile, the original circular cut-out glows electric blue,
/// and a soft glass highlight sweeps across the surface.
class SaytarlyBrandMark extends StatelessWidget {
  const SaytarlyBrandMark({
    super.key,
    this.size = 40,
    this.showGlow = false,
    this.onDark = false,
    this.light = false,
  });

  /// Clean vector trace of `assets/images/logoSVG.svg`.
  static const String asset = 'assets/images/logoSVG.svg';

  /// Aspect ratio of the traced artwork (width / height).
  static const double artworkAspect = 1440 / 1196;

  final double size;

  /// Adds the soft blue halo used on hero surfaces.
  final bool showGlow;

  /// Places the mark on a dark/navy surface.
  final bool onDark;

  /// Light tile variant (white tile + navy mark).
  final bool light;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final radius = size * 0.28;
    final markWidth = size * 0.78;
    final markHeight = markWidth / artworkAspect;
    final markColor = light ? SaytarlyColors.deepNavy : Colors.white;

    final tileGradient =
        light
            ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFEAF3FF)],
            )
            : onDark
            ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x24FFFFFF), Color(0x08FFFFFF)],
            )
            : SaytarlyGradients.brandMark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: tileGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              light
                  ? Colors.white.withValues(alpha: 0.75)
                  : onDark
                  ? Colors.white.withValues(alpha: 0.16)
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
                    color: Colors.black.withValues(alpha: onDark ? 0.22 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Glass highlight — a diagonal sheen across the tile.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: light ? 0.28 : 0.14),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.03),
                    ],
                    stops: const [0.0, 0.52, 1.0],
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: markWidth,
                height: markHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The original S has a circular cut-out — turn it into a
                    // living electric-blue signal node.
                    Align(
                      alignment: const Alignment(0.322, 0.094),
                      child: SizedBox(
                        width: markWidth * 0.24,
                        height: markWidth * 0.24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.95),
                                    accent.withValues(alpha: 0.30),
                                    accent.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.58, 1.0],
                                ),
                              ),
                            ),
                            Container(
                              width: markWidth * 0.052,
                              height: markWidth * 0.052,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.9),
                                    blurRadius: markWidth * 0.12,
                                    spreadRadius: markWidth * 0.015,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      asset,
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                      colorFilter: ColorFilter.mode(markColor, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand lockup: the vector mark + SAYTARLY wordmark + optional descriptor.
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
    final theme = Theme.of(context);
    final wordColor = onDark ? Colors.white : SaytarlyColors.deepNavy;
    final taglineColor =
        onDark ? const Color(0xFF9FB0C7) : SaytarlyColors.textSecondary;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SaytarlyBrandMark(size: markSize, showGlow: showGlow, onDark: onDark),
          if (!compact) ...[
            SizedBox(width: markSize * 0.32),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
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
                    SizedBox(width: markSize * 0.08),
                    Container(
                      width: markSize * 0.07,
                      height: markSize * 0.07,
                      margin: EdgeInsets.only(bottom: markSize * 0.02),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.65,
                            ),
                            blurRadius: markSize * 0.16,
                          ),
                        ],
                      ),
                    ),
                  ],
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

/// Oversized, low-contrast mark used as a hero/backdrop watermark.
class SaytarlyLogoWatermark extends StatelessWidget {
  const SaytarlyLogoWatermark({
    super.key,
    this.width = 520,
    this.startColor = const Color(0x17FFFFFF),
    this.endColor = const Color(0x001677FF),
    this.rotation = 0,
  });

  final double width;
  final Color startColor;
  final Color endColor;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: rotation,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [startColor, endColor],
              ).createShader(bounds),
          child: SvgPicture.asset(
            SaytarlyBrandMark.asset,
            width: width,
            height: width / SaytarlyBrandMark.artworkAspect,
            fit: BoxFit.fill,
            excludeFromSemantics: true,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
