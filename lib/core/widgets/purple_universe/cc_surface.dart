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
    final color = switch (variant) {
      CcSurfaceVariant.base => ccTheme.surface,
      CcSurfaceVariant.raised => ccTheme.raisedSurface,
      CcSurfaceVariant.glass => ccTheme.glassSurface,
      CcSurfaceVariant.outlined => Colors.transparent,
    };
    final showBorder = variant == CcSurfaceVariant.outlined;
    final shadows = switch (variant) {
      CcSurfaceVariant.base || CcSurfaceVariant.raised => ccTheme.cardShadow,
      CcSurfaceVariant.glass ||
      CcSurfaceVariant.outlined => const <BoxShadow>[],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: showBorder ? Border.all(color: ccTheme.borderSubtle) : null,
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
