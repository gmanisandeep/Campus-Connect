import 'package:flutter/material.dart';

enum AppStatus { success, warning, danger, neutral, pending }

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.status, super.key});

  final String label;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, icon) = switch (status) {
      AppStatus.success => (
        scheme.primaryContainer,
        Icons.check_circle_outline,
      ),
      AppStatus.warning => (scheme.tertiaryContainer, Icons.warning_amber),
      AppStatus.danger => (scheme.errorContainer, Icons.error_outline),
      AppStatus.pending => (scheme.secondaryContainer, Icons.schedule),
      AppStatus.neutral => (scheme.surfaceContainerHighest, Icons.info_outline),
    };
    return Semantics(
      label: 'Status: $label',
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        backgroundColor: color,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
