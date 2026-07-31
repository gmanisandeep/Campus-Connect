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
    final markSize = compact ? 36.0 : 44.0;

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
                borderRadius: BorderRadius.circular(CcRadius.control),
                border: Border.all(color: context.ccTheme.borderActive),
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
              ),
              child: Icon(
                Icons.hub_rounded,
                size: compact ? 20 : 24,
                color: theme.colorScheme.primary,
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
  const CcIconTile({required this.icon, this.semanticLabel, super.key});

  final IconData icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(CcRadius.control),
    ),
    child: Icon(
      icon,
      semanticLabel: semanticLabel,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  );
}
