import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

enum CcMessageTone { info, success, warning, danger }

class CcInlineMessage extends StatelessWidget {
  const CcInlineMessage({
    required this.message,
    this.tone = CcMessageTone.info,
    this.liveRegion = false,
    super.key,
  });

  final String message;
  final CcMessageTone tone;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final ccTheme = context.ccTheme;
    final (background, foreground, icon) = switch (tone) {
      CcMessageTone.info => (
        ccTheme.infoContainer,
        ccTheme.info,
        Icons.info_outline_rounded,
      ),
      CcMessageTone.success => (
        ccTheme.successContainer,
        ccTheme.success,
        Icons.check_circle_outline_rounded,
      ),
      CcMessageTone.warning => (
        ccTheme.warningContainer,
        ccTheme.warning,
        Icons.warning_amber_rounded,
      ),
      CcMessageTone.danger => (
        ccTheme.dangerContainer,
        ccTheme.danger,
        Icons.error_outline_rounded,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Container(
        padding: const EdgeInsets.all(CcSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(CcRadius.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: CcSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
