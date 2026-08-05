import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

class CcBrandLockup extends StatelessWidget {
  const CcBrandLockup({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markSize = compact ? 36.0 : 42.0;

    return Semantics(
      label: 'CampusConnect',
      header: true,
      child: ExcludeSemantics(
        child: Wrap(
          spacing: CcSpacing.sm,
          runSpacing: CcSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: markSize,
              height: markSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CcRadius.capsule),
                color: theme.colorScheme.primary,
              ),
              child: Icon(
                Icons.hub_rounded,
                size: compact ? 20 : 24,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            Text(
              'CampusConnect',
              style:
                  (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class CcIconTile extends StatelessWidget {
  const CcIconTile({
    required this.icon,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final IconData icon;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(CcRadius.control),
    ),
    child: Icon(
      icon,
      semanticLabel: semanticLabel,
      color:
          foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  );
}

class CcSectionHeader extends StatelessWidget {
  const CcSectionHeader({
    required this.title,
    this.supportingText,
    this.action,
    super.key,
  });

  final String title;
  final String? supportingText;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ccTheme =
        theme.extension<CcThemeExtension>() ??
        (theme.brightness == Brightness.dark
            ? CcThemeExtension.dark()
            : CcThemeExtension.light());
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (supportingText != null) ...[
          const SizedBox(height: CcSpacing.xxs),
          Text(
            supportingText!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ccTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
    if (action == null) return copy;

    final stack = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          copy,
          const SizedBox(height: CcSpacing.sm),
          Align(alignment: Alignment.centerLeft, child: action),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: copy),
        const SizedBox(width: CcSpacing.md),
        action!,
      ],
    );
  }
}
