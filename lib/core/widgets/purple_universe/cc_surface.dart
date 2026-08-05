import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

enum CcSurfaceVariant { base, raised, glass, outlined }

class CcSurface extends StatelessWidget {
  const CcSurface({
    required this.child,
    this.variant = CcSurfaceVariant.base,
    this.padding = const EdgeInsets.all(CcSpacing.lg),
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final CcSurfaceVariant variant;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final ccTheme = context.ccTheme;
    final radius = borderRadius ?? BorderRadius.circular(CcRadius.card);
    final isGlass = variant == CcSurfaceVariant.glass;
    final color = switch (variant) {
      CcSurfaceVariant.base => ccTheme.surface,
      CcSurfaceVariant.raised => ccTheme.raisedSurface,
      CcSurfaceVariant.glass => null,
      CcSurfaceVariant.outlined => Colors.transparent,
    };
    final gradient = isGlass
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                ccTheme.glowCyan.withValues(alpha: 0.09),
                ccTheme.glassSurface,
              ),
              Color.alphaBlend(
                ccTheme.glowPrimary.withValues(alpha: 0.05),
                ccTheme.glassSurface,
              ),
              ccTheme.glassSurface,
            ],
            stops: const [0, 0.42, 1],
          )
        : null;
    final showBorder = variant != CcSurfaceVariant.raised;
    final borderColor = isGlass
        ? Color.alphaBlend(
            ccTheme.borderActive.withValues(alpha: 0.22),
            ccTheme.borderSubtle,
          )
        : ccTheme.borderSubtle;
    final shadows = variant == CcSurfaceVariant.raised || isGlass
        ? ccTheme.cardShadow
        : const <BoxShadow>[];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: radius,
        border: showBorder ? Border.all(color: borderColor) : null,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: Material(
          color: Colors.transparent,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
