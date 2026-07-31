import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

enum AppStatus { success, warning, danger, neutral, pending }

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.status, super.key});

  final String label;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ccTheme =
        theme.extension<CcThemeExtension>() ??
        (theme.brightness == Brightness.dark
            ? CcThemeExtension.dark()
            : CcThemeExtension.light());
    final (background, foreground, icon) = switch (status) {
      AppStatus.success => (
        ccTheme.successContainer,
        ccTheme.success,
        Icons.check_circle_outline,
      ),
      AppStatus.warning => (
        ccTheme.warningContainer,
        ccTheme.warning,
        Icons.warning_amber,
      ),
      AppStatus.danger => (
        ccTheme.dangerContainer,
        ccTheme.danger,
        Icons.error_outline,
      ),
      AppStatus.pending => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.schedule,
      ),
      AppStatus.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.info_outline,
      ),
    };
    return Semantics(
      label: 'Status: $label',
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(icon, size: 18, color: foreground),
          label: Text(label),
          labelStyle: theme.textTheme.labelMedium?.copyWith(color: foreground),
          backgroundColor: background,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
