import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

enum CcAmbientTone { immersive, calm, quiet }

/// Shared visual contract for the CampusConnect aurora world.
///
/// Aesthetic: cinematic campus utility, not a marketing mockup.
/// Palette: deep ink or pearl foundations with one violet-to-cyan light field.
/// Depth: opaque task surfaces above atmospheric, non-interactive lighting.
/// Typography: the platform sans with editorial scale only in hero moments.
/// Motion: static by default; state motion remains short and reduced-motion safe.
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
    final primaryAlpha = (isDark ? 0.50 : 0.28) * strength;
    final secondaryAlpha = (isDark ? 0.30 : 0.34) * strength;

    _drawGlow(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.08),
      radius: size.longestSide * 0.58,
      color: primary.withValues(alpha: primaryAlpha),
    );
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.08, size.height * 0.84),
      radius: size.longestSide * 0.48,
      color: secondary.withValues(alpha: secondaryAlpha),
    );

    if (tone != CcAmbientTone.quiet) {
      final ribbon = Path()
        ..moveTo(-size.width * 0.10, size.height * 0.70)
        ..cubicTo(
          size.width * 0.20,
          size.height * 0.52,
          size.width * 0.36,
          size.height * 0.78,
          size.width * 0.62,
          size.height * 0.56,
        )
        ..cubicTo(
          size.width * 0.80,
          size.height * 0.42,
          size.width * 0.94,
          size.height * 0.49,
          size.width * 1.10,
          size.height * 0.34,
        );
      final ribbonBounds = Rect.fromLTWH(
        0,
        size.height * 0.30,
        size.width,
        size.height * 0.50,
      );
      canvas.drawPath(
        ribbon,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tone == CcAmbientTone.immersive ? 1.4 : 1
          ..shader = LinearGradient(
            colors: [
              secondary.withValues(alpha: 0),
              secondary.withValues(alpha: 0.32 * strength),
              primary.withValues(alpha: 0.44 * strength),
              primary.withValues(alpha: 0),
            ],
          ).createShader(ribbonBounds),
      );
    }
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
