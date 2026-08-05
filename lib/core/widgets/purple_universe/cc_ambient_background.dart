import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

enum CcAmbientTone { immersive, calm, quiet }

/// A quiet native foundation with one optional brand wash near the top edge.
class CcAmbientBackground extends StatelessWidget {
  const CcAmbientBackground({
    required this.child,
    this.tone = CcAmbientTone.calm,
    super.key,
  });

  final Widget child;
  final CcAmbientTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ccTheme = context.ccTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _CcAuroraPainter(
                  baseGradient: ccTheme.backgroundGradient,
                  primary: ccTheme.glowPrimary,
                  secondary: ccTheme.glowCyan,
                  isDark: theme.brightness == Brightness.dark,
                  tone: tone,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CcAuroraPainter extends CustomPainter {
  const _CcAuroraPainter({
    required this.baseGradient,
    required this.primary,
    required this.secondary,
    required this.isDark,
    required this.tone,
  });

  final LinearGradient baseGradient;
  final Color primary;
  final Color secondary;
  final bool isDark;
  final CcAmbientTone tone;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()..shader = baseGradient.createShader(bounds),
    );

    final strength = switch (tone) {
      CcAmbientTone.immersive => 1.0,
      CcAmbientTone.calm => 0.68,
      CcAmbientTone.quiet => 0.34,
    };
    if (tone == CcAmbientTone.quiet) return;

    final primaryAlpha = (isDark ? 0.18 : 0.12) * strength;

    _drawGlow(
      canvas,
      center: Offset(size.width * 0.72, -size.height * 0.10),
      radius: size.longestSide * 0.42,
      color: primary.withValues(alpha: primaryAlpha),
    );
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final glowBounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 1],
        ).createShader(glowBounds),
    );
  }

  @override
  bool shouldRepaint(covariant _CcAuroraPainter oldDelegate) =>
      oldDelegate.baseGradient != baseGradient ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.isDark != isDark ||
      oldDelegate.tone != tone;
}
